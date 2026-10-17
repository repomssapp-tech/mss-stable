/// Feature flag and configuration for the Beta Tester Password Gate.
///
/// When [isBetaModeEnabled] is true, users must supply the correct beta
/// password before accessing the application. Once successfully verified,
/// their device persists the unlock state locally.
///
/// To decommission the beta gate before public launch:
/// Set [isBetaModeEnabled] to `false` or delete `lib/services/beta_gate/`
/// and `lib/screens/beta_gate_screen.dart` when beta testing concludes.
const bool isBetaModeEnabled = false;

/// SharedPreferences key that tracks whether this device has unlocked beta access.
const String kBetaUnlockedKey = 'hasUnlockedBeta';

/// SharedPreferences key for the specific password string that was unlocked.
/// If the database password changes in Supabase, this is compared and invalidated.
const String kBetaUnlockedPasswordKey = 'unlocked_beta_password';
