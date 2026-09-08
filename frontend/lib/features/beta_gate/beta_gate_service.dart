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

  /// Checks local storage to see if this device has unlocked beta access.
  ///
  /// If an active internet connection is available, it queries Supabase to ensure
  /// the table's `beta_password` has not changed. If the password in the database
  /// was updated, the local unlock state is automatically invalidated and `false`
  /// is returned so the user is required to enter the new password.
  static Future<bool> hasUnlockedBeta({SupabaseClient? client}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUnlocked = prefs.getBool(kBetaUnlockedKey) ?? false;
      final savedPassword = prefs.getString(kBetaUnlockedPasswordKey);

      if (!isUnlocked && (savedPassword == null || savedPassword.isEmpty)) {
        return false;
      }

      // Check against current database value if online
      try {
        final supabaseClient = client ?? Supabase.instance.client;
        final response = await supabaseClient
            .from('beta_gate_config')
            .select('beta_password')
            .limit(1)
            .maybeSingle()
            .timeout(const Duration(milliseconds: 2500));

        if (response != null) {
          final currentDbPassword =
              response['beta_password']?.toString().trim();

          if (currentDbPassword != null && currentDbPassword.isNotEmpty) {
            // If the admin changed the password in the database, relock the app
            if (savedPassword != null && savedPassword.isNotEmpty) {
              if (currentDbPassword != savedPassword) {
                debugPrint(
                  '[BetaGateService] Database password changed. Relocking gate.',
                );
                await resetBetaLock();
                return false;
              }
            } else {
              // Legacy unlock without saved password string: update or re-verify
              await prefs.setString(
                kBetaUnlockedPasswordKey,
                currentDbPassword,
              );
            }
          }
        }
      } catch (netErr) {
        // Offline or request timeout: trust previously unlocked session
        debugPrint(
          '[BetaGateService] Offline or timeout during password sync: $netErr',
        );
      }

      return true;
    } catch (e) {
      debugPrint('[BetaGateService] Failed to read beta unlock status: $e');
      return false;
    }
  }

  /// Sets the unlocked status in local storage.
  static Future<bool> setUnlocked(bool unlocked, {String? password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kBetaUnlockedKey, unlocked);
      if (unlocked && password != null && password.isNotEmpty) {
        await prefs.setString(kBetaUnlockedPasswordKey, password);
      } else if (!unlocked) {
        await prefs.remove(kBetaUnlockedPasswordKey);
      }
      return true;
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
      await prefs.remove(kBetaUnlockedPasswordKey);
    } catch (e) {
      debugPrint('[BetaGateService] Failed to reset beta unlock status: $e');
    }
  }

  /// Verifies [userInput] against the `beta_password` stored in Supabase `beta_gate_config`.
  ///
  /// Queries Supabase dynamically:
  /// `supabase.from('beta_gate_config').select('beta_password').limit(1).maybeSingle()`
  ///
  /// If the password matches, persists the unlock state along with the current
  /// password and returns `true`.
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
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint(
          '[BetaGateService] Warning: beta_gate_config table is empty or inaccessible.',
        );
        return false;
      }

      final dbPassword = response['beta_password']?.toString().trim();
      if (dbPassword != null && dbPassword == trimmedInput) {
        await setUnlocked(true, password: dbPassword);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[BetaGateService] Error during password verification: $e');
      return false;
    }
  }
}
