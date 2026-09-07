import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'beta_config.dart';

/// Service responsible for validating beta tester access passwords against
/// Supabase and maintaining the local unlock state on the device.
class BetaGateService {
  final SupabaseClient? _client;

  BetaGateService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Checks local storage to see if this device has already unlocked beta access.
  static Future<bool> hasUnlockedBeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kBetaUnlockedKey) ?? false;
    } catch (e) {
      debugPrint('[BetaGateService] Failed to read beta unlock status: $e');
      return false;
    }
  }

  /// Sets the unlocked status in local storage.
  static Future<bool> setUnlocked(bool unlocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(kBetaUnlockedKey, unlocked);
    } catch (e) {
      debugPrint('[BetaGateService] Failed to persist beta unlock status: $e');
      return false;
    }
  }

  /// Resets beta lock status back to locked (useful for testing and QA).
  static Future<void> resetBetaLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kBetaUnlockedKey);
    } catch (e) {
      debugPrint('[BetaGateService] Failed to reset beta unlock status: $e');
    }
  }

  /// Verifies [userInput] against the `beta_password` stored in Supabase `beta_gate_config`.
  ///
  /// Queries Supabase:
  /// `supabase.from('beta_gate_config').select('beta_password').maybeSingle()`
  ///
  /// Safely handles network errors, timeouts, empty tables, or null responses.
  /// If the password matches, persists `hasUnlockedBeta = true` and returns `true`.
  /// Otherwise, returns `false`.
  Future<bool> verifyPassword(String userInput) async {
    final trimmedInput = userInput.trim();
    if (trimmedInput.isEmpty) {
      return false;
    }

    try {
      final response = await _supabase
          .from('beta_gate_config')
          .select('beta_password')
          .maybeSingle();

      if (response == null) {
        debugPrint(
          '[BetaGateService] Warning: beta_gate_config table is empty or inaccessible.',
        );
        return false;
      }

      final dbPassword = response['beta_password']?.toString().trim();
      if (dbPassword != null && dbPassword == trimmedInput) {
        await setUnlocked(true);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[BetaGateService] Error during password verification: $e');
      return false;
    }
  }
}
