import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide haptic feedback with a single on/off setting (Settings >
/// Haptic feedback). On by default.
///
/// * [tap] — a light tick on every tap anywhere in the app
///   ([HapticTouchLayer] calls it).
/// * [notification] — a stronger pulse when a notification arrives while the
///   app is open.
///
/// The system notification itself also vibrates through its Android channel;
/// that follows the phone's own notification settings, not this switch.
class HapticsService {
  HapticsService._();
  static final HapticsService instance = HapticsService._();

  static const String _prefKey = 'haptics_enabled';

  /// Whether haptics are on. Listen to update a switch.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  bool _loaded = false;

  /// Reads the saved setting. Safe to call more than once.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefKey) ?? true;
    } catch (e) {
      debugPrint('[Haptics] could not read setting: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    if (value) await HapticFeedback.selectionClick();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (e) {
      debugPrint('[Haptics] could not save setting: $e');
    }
  }

  /// Light tick for a tap.
  Future<void> tap() async {
    if (!enabled.value) return;
    await HapticFeedback.lightImpact();
  }

  /// Stronger pulse for an incoming notification.
  Future<void> notification() async {
    if (!enabled.value) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }
}
