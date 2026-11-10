import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../account/token_storage.dart';

/// Whether an administrator has locked the app, and the message they left.
@immutable
class AppLockState {
  const AppLockState({required this.locked, this.message});

  static const AppLockState unlocked = AppLockState(locked: false);

  final bool locked;

  /// The administrator's note for the locked screen; null when none was set.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is AppLockState &&
      other.locked == locked &&
      other.message == message;

  @override
  int get hashCode => Object.hash(locked, message);
}

/// Administrator app lock.
///
/// The real lock is on the server: while it is on, the MSS API refuses every
/// request from anyone but an admin (423 APP_LOCKED), sign-in, sign-out and
/// token refresh included, so a modified app gets nothing from it. This
/// service is the app's side of it:
///
/// * it asks the public `GET /v1/app/status` on start, on resume and on a
///   timer, and every API answer of 423 APP_LOCKED (from any request) locks
///   the app at once;
/// * the locked state is kept in the encrypted Keystore, so a restart, or
///   turning the network off, does not reopen the app: only the server saying
///   "unlocked" does;
/// * [AppLockGate] puts nothing but the locked screen on the screen while it
///   is locked; the rest of the app is not built at all.
class AppLockService extends ValueNotifier<AppLockState> {
  AppLockService({SecretStore? store, http.Client? client, String? statusUrl})
    : _store = store ?? KeystoreSecretStore(),
      _client = client ?? http.Client(),
      _statusUrl = statusUrl,
      super(AppLockState.unlocked);

  static AppLockService instance = AppLockService();

  static const String _storeKey = 'mss_app_lock_v1';
  static const String lockedCode = 'APP_LOCKED';

  /// How often the server is asked while the app is in use, and while locked
  /// (so the app opens by itself soon after the administrator unlocks it).
  static const Duration checkEvery = Duration(seconds: 60);
  static const Duration checkWhileLockedEvery = Duration(seconds: 15);

  final SecretStore _store;
  final http.Client _client;
  final String? _statusUrl;
  Future<void>? _inFlight;

  bool get isLocked => value.locked;

  /// Restores the last known state before the first frame. A phone that was
  /// locked stays locked until the server says otherwise.
  Future<void> hydrate() async {
    try {
      final raw = await _store.read(_storeKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is Map && data['locked'] == true) {
        value = AppLockState(
          locked: true,
          message: _cleanMessage(data['message']),
        );
      }
    } catch (e) {
      debugPrint('[AppLock] could not read the saved lock state: $e');
    }
  }

  /// Asks the server. Concurrent calls share one request. When the server
  /// cannot be reached the current state is kept.
  Future<void> check() => _inFlight ??= _check().whenComplete(() {
    _inFlight = null;
  });

  Future<void> _check() async {
    try {
      final response = await _client
          .get(
            Uri.parse(_statusUrl ?? '${AppConfig.apiV1Url}/app/status'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 423) {
        await _apply(AppLockState(locked: true, message: _messageOf(response)));
        return;
      }
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! Map || data['locked'] is! bool) return;
      await _apply(
        data['locked'] == true
            ? AppLockState(
                locked: true,
                message: _cleanMessage(data['message']),
              )
            : AppLockState.unlocked,
      );
    } catch (e) {
      debugPrint('[AppLock] status check failed; keeping current state: $e');
    }
  }

  /// Called by the API client whenever the server answers 423 APP_LOCKED.
  void reportLocked({String? message}) {
    unawaited(
      _apply(AppLockState(locked: true, message: _cleanMessage(message))),
    );
  }

  /// True when [statusCode] and [errorCode] are the server's lock answer.
  static bool isLockResponse(int statusCode, String? errorCode) =>
      statusCode == 423 && (errorCode == null || errorCode == lockedCode);

  Future<void> _apply(AppLockState next) async {
    // Keep the administrator's message when a later 423 carries none.
    if (next.locked && next.message == null && value.locked) {
      next = AppLockState(locked: true, message: value.message);
    }
    final changed = next != value;
    value = next;
    if (!changed) return;
    try {
      if (next.locked) {
        await _store.write(
          _storeKey,
          jsonEncode({'locked': true, 'message': next.message}),
        );
      } else {
        await _store.delete(_storeKey);
      }
    } catch (e) {
      debugPrint('[AppLock] could not save the lock state: $e');
    }
  }

  static String? _messageOf(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['details'] is Map) {
        return _cleanMessage((body['details'] as Map)['message']);
      }
    } catch (_) {}
    return null;
  }

  static String? _cleanMessage(Object? raw) {
    if (raw is! String) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;
    return text.length > 500 ? text.substring(0, 500) : text;
  }

  @visibleForTesting
  void debugSet(AppLockState state) => value = state;
}
