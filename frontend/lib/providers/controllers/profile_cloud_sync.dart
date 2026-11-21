import 'package:flutter/foundation.dart';

import '../../models/onboarding_api_dto.dart';
import '../../models/user_profile.dart';
import '../../services/account/app_session.dart';
import '../../services/account/onboarding_api_service.dart';
import '../../services/account/profile_api_service.dart';

/// Pushes a [UserProfile] to MSS REST Backend (`/v1/me/profile/draft` and
/// `/v1/me/onboarding`).
///
/// Throws when the server does not accept the write, so a required onboarding
/// save is never reported as done after a failure.
Future<void> syncProfileToServer(
  UserProfile profileToSync, {
  required bool isLoggedIn,
  bool requireOnboardingCompletion = false,
}) async {
  if (!isLoggedIn) {
    throw StateError('Sign in is required before saving profile data.');
  }

  if (!AppSession.instance.isSignedIn) {
    throw StateError('Your session expired. Please sign in again.');
  }

  // Compared with the server's current profile inside the write queue, so
  // only real changes are sent and writes never share an ETag.
  await ProfileApiService.instance.saveProfileChanges(profileToSync);

  if (profileToSync.profileCompleted) {
    // The server completes onboarding only with the acceptance of all four
    // current legal documents; without them the profile fields saved above are
    // all that is sent.
    // The sign-in agreement (Terms of Use, Privacy Policy) may not have been
    // turned into a recorded consent yet (the server's documents were
    // unreachable or not configured at sign-in): try once more. The data-use
    // page counts as accepted now that the profile is complete. A failure here
    // reaches the caller like any other server write.
    await LegalConsentStore.recordFromLoginAgreement(
      OnboardingApiService.instance,
    );
    await LegalConsentStore.recordFromProfileCompletion(
      OnboardingApiService.instance,
    );
    if (!await LegalConsentStore.isComplete()) {
      if (requireOnboardingCompletion) {
        throw StateError('Onboarding requires recorded consent.');
      }
      debugPrint('[AppProvider] Onboarding not sent: consent not recorded.');
      return;
    }
    final acceptances = await LegalConsentStore.accepted();
    final profileMap = buildOnboardingProfile(profileToSync);
    final missing = missingOnboardingFields(profileMap);
    if (missing.isNotEmpty) {
      if (requireOnboardingCompletion) {
        throw StateError(
          'Onboarding is missing required fields: ${missing.join(', ')}.',
        );
      }
      debugPrint(
        '[AppProvider] Onboarding not sent: missing ${missing.join(', ')}.',
      );
      return;
    }

    final businessDto = buildOnboardingBusiness(
      profileToSync,
      profileMap['applicant_type'] as String,
    );

    final submission = OnboardingSubmissionDto(
      profile: profileMap,
      business: businessDto,
      legalAcceptances: acceptances,
    );
    await OnboardingApiService.instance.submitOnboarding(submission);
  }
  debugPrint('[AppProvider] Profile sync completed.');
}

/// Writable `profile` object for `PUT /v1/me/onboarding`. `email` is not
/// writable, `phone` must be exactly 10 digits and `pincode` exactly 6.
Map<String, dynamic> buildOnboardingProfile(UserProfile p) {
  String tenDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  String text(String v) => v.trim();
  return <String, dynamic>{
    'name': text(p.name),
    'dob': p.dob?.toIso8601String().split('T')[0],
    'gender': text(p.gender),
    'phone': tenDigits(p.mobile),
    'state': text(p.state),
    'district': text(p.district),
    'city': text(p.city),
    'house': text(p.house),
    'pincode': p.pinCode.replaceAll(RegExp(r'\D'), ''),
    'applicant_type': p.employmentStatus.trim().isNotEmpty
        ? p.employmentStatus.trim()
        : 'Individual',
    'education_level': text(p.educationLevel),
    'community': text(p.community),
    'annual_income': p.annualIncome,
  };
}

/// Required onboarding keys that are empty or malformed in [profile].
List<String> missingOnboardingFields(Map<String, dynamic> profile) {
  final missing = <String>[
    for (final entry in profile.entries)
      if (entry.key != 'annual_income' &&
          (entry.value == null || '${entry.value}'.isEmpty))
        entry.key,
  ];
  if ('${profile['phone']}'.length != 10 && !missing.contains('phone')) {
    missing.add('phone');
  }
  if ('${profile['pincode']}'.length != 6 && !missing.contains('pincode')) {
    missing.add('pincode');
  }
  return missing;
}

/// Business section, or null when none applies. An active student venture with
/// no registration, funding or registration numbers is rejected by the server
/// (`business.STUDENT_WITHOUT_VENTURE`), so it is left out.
BusinessProfileDto? buildOnboardingBusiness(
  UserProfile p,
  String applicantType,
) {
  if (!p.existingBusiness && p.businessStage.isEmpty) return null;
  if (applicantType.toLowerCase() == 'student' &&
      !p.existingBusiness &&
      p.fundingRequired == 0 &&
      p.registrationNumbers.trim().isEmpty) {
    return null;
  }
  final name = p.name.isNotEmpty ? p.name : 'User';
  return BusinessProfileDto(
    profileName: '$name Business',
    industry: p.businessIndustry.isNotEmpty ? p.businessIndustry : 'General',
    applicantType: applicantType,
    businessStage: p.businessStage.isNotEmpty ? p.businessStage : 'Idea',
    businessRegistered: p.existingBusiness,
    fundingRequiredAmount: p.fundingRequired,
    registrationNumbers: p.registrationNumbers,
    isFirstGenerationEntrepreneur: p.firstGenGraduate,
  );
}
