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
  /// [tour] names the tour: empty for the home tour (its keys predate the
  /// name), `saarthi` for the Saarthi-mode tour.
  const HomeTourStore({this.tour = ''});

  final String tour;

  /// Bump the version in this prefix to show a new tour to everyone again.
  static const String keyPrefix = 'home_tour_v1_';

  String get _base => tour.isEmpty ? keyPrefix : '$keyPrefix${tour}_';

  /// The record for anyone on this phone, including a guest.
  String get deviceKey => '${_base}device';

  String keyFor(String userId) => '$_base$userId';

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
