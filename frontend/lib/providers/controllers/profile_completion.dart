import '../../models/user_profile.dart';

/// Pure profile-completion scoring, extracted from `AppProvider`
/// (frontend refactor, decomposition follow-up). Both functions are stateless
/// and operate only on the [UserProfile] passed in — no `AppProvider` field
/// access, so they carry zero coupling risk.
///
/// Onboarding collects age (persisted as `dob`), not a photo. A profile photo
/// is optional and never requested in the onboarding flow, so it is
/// deliberately excluded from the checks below — including it capped
/// completion at ~95% forever for anyone who never set one.
int calculateProfileCompletionPercentage(UserProfile profile) {
  final List<bool> checks = [];

  // Personal Info (5)
  checks.add(profile.name.trim().isNotEmpty);
  checks.add(profile.mobile.trim().isNotEmpty);
  checks.add(profile.email.trim().isNotEmpty);
  checks.add(profile.dob != null);
  checks.add(profile.gender.trim().isNotEmpty);

  // Address Info (6)
  checks.add(profile.house.trim().isNotEmpty);
  checks.add(profile.area.trim().isNotEmpty);
  checks.add(profile.city.trim().isNotEmpty);
  checks.add(profile.district.trim().isNotEmpty);
  checks.add(profile.state.trim().isNotEmpty);
  checks.add(profile.pinCode.trim().isNotEmpty);

  // Role / Employment (1)
  checks.add(profile.employmentStatus.trim().isNotEmpty);

  // Eligibility & Social (Step 4) (4)
  checks.add(
    profile.qualification.trim().isNotEmpty ||
        profile.educationLevel.trim().isNotEmpty,
  );
  checks.add(profile.community.trim().isNotEmpty);
  checks.add(profile.disability == 'Yes' || profile.disability == 'No');

  // Eligibility Booleans (Income, Veteran, First Gen)
  // Counted as filled if they completed Step 4
  final completedStep4 =
      profile.qualification.trim().isNotEmpty ||
      profile.educationLevel.trim().isNotEmpty;
  checks.add(completedStep4);

  // Preferences (2)
  checks.add(profile.language.trim().isNotEmpty);
  checks.add(profile.navigationMode.trim().isNotEmpty);

  // Business (conditional)
  if (profile.existingBusiness) {
    checks.add(profile.businessStage.trim().isNotEmpty);
    checks.add(profile.businessIndustry.trim().isNotEmpty);
  }

  final total = checks.length;
  final filled = checks.where((c) => c).length;

  return total == 0 ? 0 : ((filled / total) * 100).round();
}

List<String> calculateMissingProfileSections(UserProfile profile) {
  final missing = <String>[];

  // Check Basic Details
  if (profile.name.trim().isEmpty ||
      profile.mobile.trim().isEmpty ||
      profile.email.trim().isEmpty ||
      profile.dob == null ||
      profile.gender.trim().isEmpty) {
    missing.add('Basic Details');
  }

  // Address
  if (profile.house.trim().isEmpty ||
      profile.area.trim().isEmpty ||
      profile.state.trim().isEmpty ||
      profile.district.trim().isEmpty ||
      profile.city.trim().isEmpty ||
      profile.pinCode.trim().isEmpty) {
    missing.add('Address Details');
  }

  if (profile.employmentStatus.trim().isEmpty) missing.add('Employment');

  // Eligibility
  if ((profile.qualification.trim().isEmpty &&
          profile.educationLevel.trim().isEmpty) ||
      profile.community.trim().isEmpty ||
      (profile.disability != 'Yes' && profile.disability != 'No')) {
    missing.add('Eligibility');
  }

  if (profile.existingBusiness) {
    if (profile.businessStage.trim().isEmpty ||
        profile.businessIndustry.trim().isEmpty) {
      missing.add('Business Details');
    }
  }
  return missing;
}
