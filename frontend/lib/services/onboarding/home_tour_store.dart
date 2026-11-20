import 'package:shared_preferences/shared_preferences.dart';

/// How a user's home tour ended. Both outcomes mean it is not shown again.
enum HomeTourOutcome { completed, skipped }

/// Remembers that the first-time home tour is done, for the account and for
/// this phone.
///
/// The tour is shown once: the first time anyone, guest or signed-in, reaches
/// home on this phone. A per-account record (key carries the account id) and a
/// device record are both kept, and both survive sign-out
/// (`SessionCacheService.clearSession` keeps every [keyPrefix] key), so
/// signing out and back in, or a guest signing in, never shows it again.
class HomeTourStore {
  const HomeTourStore();

  /// Bump the version in this prefix to show a new tour to everyone again.
  static const String keyPrefix = 'home_tour_v1_';

  /// The record for anyone on this phone, including a guest.
  static const String deviceKey = '${keyPrefix}device';

  static String keyFor(String userId) => '$keyPrefix$userId';

  /// Done on this phone, or by this account on another phone.
  Future<bool> isDone(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(deviceKey) != null) return true;
    if (userId == null || userId.isEmpty) return false;
    return prefs.getString(keyFor(userId)) != null;
  }

  Future<HomeTourOutcome?> outcome(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = (userId == null || userId.isEmpty)
        ? prefs.getString(deviceKey)
        : prefs.getString(keyFor(userId)) ?? prefs.getString(deviceKey);
    return switch (value) {
      'completed' => HomeTourOutcome.completed,
      'skipped' => HomeTourOutcome.skipped,
      _ => null,
    };
  }

  Future<void> record(String? userId, HomeTourOutcome outcome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(deviceKey, outcome.name);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(keyFor(userId), outcome.name);
    }
  }
}
