import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/onboarding_api_dto.dart';
import '../../models/user_profile.dart';
import '../../models/user_profile_api_dto.dart';
import '../../services/account/onboarding_api_service.dart';
import '../../services/account/profile_api_service.dart';
import '../../services/account/token_storage.dart';
import '../../services/catalog/scheme_repository.dart';

/// Pushes a [UserProfile] to MSS REST Backend (`/v1/me/profile/draft` and
/// `/v1/me/onboarding`), with fallback/mirror to Supabase.
Future<void> syncProfileToSupabase(
  UserProfile profileToSync, {
  required bool isLoggedIn,
}) async {
  if (!isLoggedIn) {
    throw StateError('Sign in is required before saving profile data.');
  }

  // 1. Sync to MSS REST Backend if user has an active REST session/token
  final accessToken = await TokenStorage.instance.getAccessToken();
  if (accessToken != null && accessToken.isNotEmpty) {
    try {
      final patchPayload = ProfileAggregate.buildPatchPayload(current: profileToSync);
      if (patchPayload.isNotEmpty) {
        await ProfileApiService.instance.saveDraft(patchPayload);
      }

      if (profileToSync.profileCompleted) {
        final profileMap = <String, dynamic>{
          'applicant_type': profileToSync.employmentStatus.isNotEmpty
              ? profileToSync.employmentStatus
              : 'individual',
          'name': profileToSync.name,
          'email': profileToSync.email,
          if (profileToSync.mobile.isNotEmpty) 'phone': profileToSync.mobile,
          if (profileToSync.dob != null)
            'dob': profileToSync.dob!.toIso8601String().split('T')[0],
          if (profileToSync.gender.isNotEmpty) 'gender': profileToSync.gender,
          if (profileToSync.state.isNotEmpty) 'state': profileToSync.state,
          if (profileToSync.district.isNotEmpty) 'district': profileToSync.district,
          if (profileToSync.pinCode.isNotEmpty) 'pincode': profileToSync.pinCode,
        };

        final businessDto = (profileToSync.existingBusiness || profileToSync.businessStage.isNotEmpty)
            ? BusinessProfileDto(
                profileName: '${profileToSync.name.isNotEmpty ? profileToSync.name : "User"} Business',
                industry: profileToSync.businessIndustry.isNotEmpty ? profileToSync.businessIndustry : 'General',
                applicantType: profileToSync.employmentStatus.isNotEmpty ? profileToSync.employmentStatus : 'individual',
                businessStage: profileToSync.businessStage.isNotEmpty ? profileToSync.businessStage : 'Idea',
                businessRegistered: profileToSync.existingBusiness,
                fundingRequiredAmount: profileToSync.fundingRequired,
                registrationNumbers: profileToSync.registrationNumbers,
                isFirstGenerationEntrepreneur: profileToSync.firstGenGraduate,
              )
            : null;

        final submission = OnboardingSubmissionDto(
          profile: profileMap,
          business: businessDto,
          legalAcceptances: const [],
        );
        await OnboardingApiService.instance.submitOnboarding(submission);
      }
      debugPrint('[AppProvider] MSS REST profile sync completed.');
    } catch (e) {
      debugPrint('[AppProvider] MSS REST profile sync warning: $e');
    }
  }

  // 2. Supabase fallback/mirror
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (accessToken != null && accessToken.isNotEmpty) {
        return; // Already synced via REST API
      }
      throw StateError('Your session expired. Please sign in again.');
    }

  final effectiveEmail = profileToSync.email.trim().isNotEmpty
      ? profileToSync.email.trim()
      : (user.email != null && user.email!.trim().isNotEmpty
          ? user.email!.trim()
          : '${user.id}@mss.app');
  final effectiveName = profileToSync.name.trim().isNotEmpty
      ? profileToSync.name.trim()
      : (user.userMetadata?['full_name']?.toString().trim().isNotEmpty == true
          ? user.userMetadata!['full_name'].toString().trim()
          : (user.userMetadata?['name']?.toString().trim().isNotEmpty == true
              ? user.userMetadata!['name'].toString().trim()
              : 'User'));

  final cloudProfile = profileToSync.copyWith(
    googleUserId: user.id,
    email: effectiveEmail,
    name: effectiveName,
  );
  debugPrint('[AppProvider] Syncing profile to Supabase...');
  // Keep the completion flag false until every related cloud write succeeds.
  // The initial upsert also guarantees the startup_profiles foreign-key
  // parent exists for first-time users.
  final stagedProfile = cloudProfile.profileCompleted
      ? cloudProfile.copyWith(profileCompleted: false)
      : cloudProfile;
  await SchemeRepository.instance.createProfile(stagedProfile);

  // Sync startup_profiles table so the collected applicant/business fields
  // are committed in the same submission before the UI moves forward.
  final existingStartups = await Supabase.instance.client
      .from('startup_profiles')
      .select('id')
      .eq('user_id', user.id)
      .limit(1);

  // Only touch startup_profiles when the user has actually given business
  // data -- no more writing 'Technology' / 'Idea' / 'Student' placeholders
  // that then round-trip back as if they were real answers. Exclude students
  // who do not run an existing venture.
  final isStudentWithoutBusiness =
      cloudProfile.employmentStatus.trim().toLowerCase() == 'student' &&
      !cloudProfile.existingBusiness &&
      cloudProfile.fundingRequired <= 0 &&
      cloudProfile.registrationNumbers.trim().isEmpty;

  final hasBusinessData = !isStudentWithoutBusiness &&
      (cloudProfile.businessIndustry.trim().isNotEmpty ||
          cloudProfile.businessStage.trim().isNotEmpty ||
          cloudProfile.existingBusiness ||
          cloudProfile.fundingRequired > 0 ||
          cloudProfile.registrationNumbers.trim().isNotEmpty);

  if (hasBusinessData) {
    const allowedStages = {
      'Idea',
      'Prototype',
      'Registered',
      'Operational',
      'Expansion',
    };
    final rawStage = cloudProfile.businessStage.trim();
    final sanitizedStage = allowedStages.contains(rawStage)
        ? rawStage
        : (cloudProfile.existingBusiness ? 'Operational' : 'Idea');

    final Map<String, dynamic> startupData = {
      'user_id': user.id,
      'profile_name': '${cloudProfile.name.isNotEmpty ? cloudProfile.name : "User"} Business',
      'industry': cloudProfile.businessIndustry.trim().isNotEmpty
          ? cloudProfile.businessIndustry
          : 'General',
      'applicant_type': cloudProfile.employmentStatus.trim().isNotEmpty
          ? cloudProfile.employmentStatus
          : 'Individual',
      'business_stage': sanitizedStage,
      'business_registered': cloudProfile.existingBusiness,
      'funding_required_amount': cloudProfile.fundingRequired,
      'registration_numbers': cloudProfile.registrationNumbers,
      'is_first_generation_entrepreneur': cloudProfile.firstGenGraduate,
      'is_active': true,
    };
    if (existingStartups.isNotEmpty) {
      startupData['id'] = existingStartups.first['id'];
    }
    await Supabase.instance.client.from('startup_profiles').upsert(startupData);
  }

  if (cloudProfile.profileCompleted) {
    await SchemeRepository.instance.createProfile(cloudProfile);
  }
  debugPrint('[AppProvider] Supabase profile sync completed.');
  } catch (e) {
    debugPrint('[AppProvider] Supabase profile sync warning: $e');
  }
}
