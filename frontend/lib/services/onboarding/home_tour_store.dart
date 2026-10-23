import 'package:shared_preferences/shared_preferences.dart';

/// How a user's home tour ended. Both outcomes mean it is not shown again.
enum HomeTourOutcome { completed, skipped }

/// Remembers, per signed-in account, that the first-time home tour is done.
///
/// The key carries the account id, so logging out and back in (or another
/// account on the same phone) never resets or borrows another account's state,
/// and it survives app restarts.
class HomeTourStore {
  const HomeTourStore();

  /// Bump the suffix to show a new version of the tour to everyone again.
  static String keyFor(String userId) => 'home_tour_v1_$userId';

  Future<bool> isDone(String userId) async {
    if (userId.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyFor(userId)) != null;
  }

  Future<HomeTourOutcome?> outcome(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(keyFor(userId))) {
      'completed' => HomeTourOutcome.completed,
      'skipped' => HomeTourOutcome.skipped,
      _ => null,
    };
  }

  Future<void> record(String userId, HomeTourOutcome outcome) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFor(userId), outcome.name);
  }
}
