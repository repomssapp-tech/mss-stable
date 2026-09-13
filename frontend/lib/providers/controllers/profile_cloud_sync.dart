import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/catalog/scheme_repository.dart';

/// Pushes a [UserProfile] to Supabase (`profiles` + conditionally
/// `startup_profiles`), extracted from `AppProvider` (frontend refactor,
/// decomposition follow-up). Takes the current auth state as a parameter
/// rather than reading `AppProvider` fields directly, so it carries no
/// coupling beyond the Supabase client and [SchemeRepository].
Future<void> syncProfileToSupabase(
  UserProfile profileToSync, {
  required bool isLoggedIn,
}) async {
  if (!isLoggedIn) {
    throw StateError('Sign in is required before saving profile data.');
  }
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    throw StateError('Your session expired. Please sign in again.');
  }

  final cloudProfile = profileToSync.copyWith(googleUserId: user.id);
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
  // that then round-trip back as if they were real answers.
  final hasBusinessData =
      cloudProfile.businessIndustry.trim().isNotEmpty ||
      cloudProfile.businessStage.trim().isNotEmpty ||
      cloudProfile.existingBusiness ||
      cloudProfile.fundingRequired > 0 ||
      cloudProfile.registrationNumbers.trim().isNotEmpty;

  if (hasBusinessData) {
    final Map<String, dynamic> startupData = {
      'user_id': user.id,
      'profile_name': '${cloudProfile.name} Business',
      'industry': cloudProfile.businessIndustry.trim().isNotEmpty
          ? cloudProfile.businessIndustry
          : 'Unspecified',
      'applicant_type': cloudProfile.employmentStatus.trim().isNotEmpty
          ? cloudProfile.employmentStatus
          : 'Unspecified',
      'business_stage': cloudProfile.businessStage.trim().isNotEmpty
          ? cloudProfile.businessStage
          : 'Unspecified',
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
}
