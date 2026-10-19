import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/pending_endpoints.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'beta_config.dart';

/// Service responsible for validating beta tester access passwords with the
/// backend and maintaining the local unlock state on the device.
///
/// The password is checked on the server (`POST /beta-gate/verify`, an assumed
/// route listed in [PendingEndpoints]); it is never downloaded to the device.
class BetaGateService {
  final ApiClient? _client;

  BetaGateService({ApiClient? client}) : _client = client;

  static ApiClient _resolve(ApiClient? client) => client ?? ApiClient.instance;

  /// Asks the server whether [password] is currently valid.
  /// Returns null when the server cannot be reached or does not answer.
  static Future<bool?> _serverAccepts(
    String password, {
    ApiClient? client,
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    try {
      final response = await _resolve(client)
          .post(
            PendingEndpoints.betaGateVerify,
            body: {'password': password},
            requiresAuth: false,
          )
          .timeout(timeout);
      final data = response.data;
      if (data is Map && data['unlocked'] is bool) {
        return data['unlocked'] as bool;
      }
      return null;
    } on ApiException catch (e) {
      // A rejected password is a definite "no"; anything else is "unknown".
      return e.statusCode == 401 || e.statusCode == 403 ? false : null;
    } catch (_) {
      return null;
    }
  }

  /// Checks local storage to see if this device has unlocked beta access.
  ///
  /// If an active internet connection is available, the saved password is
  /// re-checked on the server. If it is no longer accepted (the password was
  /// changed), the local unlock state is invalidated and `false` is returned so
  /// the user must enter the new password. Offline, the earlier unlock is
  /// trusted.
  static Future<bool> hasUnlockedBeta({ApiClient? client}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUnlocked = prefs.getBool(kBetaUnlockedKey) ?? false;
      final savedPassword = prefs.getString(kBetaUnlockedPasswordKey);

      if (!isUnlocked && (savedPassword == null || savedPassword.isEmpty)) {
        return false;
      }

      if (savedPassword != null && savedPassword.isNotEmpty) {
        final accepted = await _serverAccepts(savedPassword, client: client);
        if (accepted == false) {
          debugPrint('[BetaGateService] Password changed. Relocking gate.');
          await resetBetaLock();
          return false;
        }
        if (accepted == null) {
          debugPrint('[BetaGateService] Offline; trusting previous unlock.');
        }
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

  /// Verifies [userInput] with the server.
  ///
  /// If the password is accepted, persists the unlock state along with the
  /// password and returns `true`. Otherwise, returns `false`.
  Future<bool> verifyPassword(String userInput) async {
    final trimmedInput = userInput.trim();
    if (trimmedInput.isEmpty) {
      return false;
    }

    final accepted = await _serverAccepts(
      trimmedInput,
      client: _client,
      timeout: const Duration(seconds: 8),
    );
    if (accepted == true) {
      await setUnlocked(true, password: trimmedInput);
      return true;
    }
    if (accepted == null) {
      debugPrint('[BetaGateService] Could not reach the server to verify.');
    }
    return false;
  }
}
