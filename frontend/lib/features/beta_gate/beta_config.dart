/// Feature flag and configuration for the Beta Tester Password Gate.
///
/// When [isBetaModeEnabled] is true, users must supply the correct beta
/// password before accessing the application. Once successfully verified,
/// their device persists the unlock state locally.
///
/// Set [isBetaModeEnabled] to `false` or delete the `lib/features/beta_gate/`
/// directory when beta testing concludes.
const bool isBetaModeEnabled = true;

/// SharedPreferences key that tracks whether this device has unlocked beta access.
const String kBetaUnlockedKey = 'hasUnlockedBeta';
