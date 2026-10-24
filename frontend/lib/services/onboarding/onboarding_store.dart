import 'package:shared_preferences/shared_preferences.dart';

/// Whether this install has finished the first-launch onboarding pages.
class OnboardingStore {
  const OnboardingStore();

  static const String seenKey = 'onboarding_v2_seen';

  Future<bool> isSeen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(seenKey) ?? false;
    } catch (_) {
      // Unreadable storage: don't trap the user in onboarding.
      return true;
    }
  }

  Future<void> markSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(seenKey, true);
    } catch (_) {}
  }
}
