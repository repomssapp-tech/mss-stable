import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';

/// Account-level calls that sit outside the profile API.
class AccountApiService {
  AccountApiService({ApiClient? apiClient}) : _apiClient = apiClient;

  static AccountApiService? _instance;
  static AccountApiService get instance => _instance ??= AccountApiService();

  final ApiClient? _apiClient;

  ApiClient get _client => _apiClient ?? ApiClient.instance;

  /// Deletes the signed-in account (`DELETE /v1/me`).
  ///
  /// The server freezes the account, signs it out everywhere and keeps its data
  /// for 30 days; signing in again during that time offers to reactivate it.
  /// Returns when the data will be permanently removed (`purge_after`), or null
  /// from an older server that deletes at once (204, no body).
  ///
  /// The server requires that the session was authenticated within the last
  /// 5 minutes (a token refresh does not count) and answers
  /// `403 REAUTHENTICATION_REQUIRED` otherwise. It throws on every failure, so
  /// callers never clear local data unless the server confirmed the deletion.
  /// No body and no query are sent.
  Future<DateTime?> deleteAccount() async {
    final response = await _client.delete('/v1/me');
    final data = response.data;
    if (data is! Map) return null;
    return DateTime.tryParse(data['purge_after']?.toString() ?? '')?.toLocal();
  }

  /// What to tell the user when [deleteAccount] failed with [error]. Nothing was
  /// deleted in any of these cases.
  static String deletionRefusalMessage(Object error) {
    if (error is ApiException) {
      switch (error.errorCode) {
        case 'REAUTHENTICATION_REQUIRED':
          return 'For your security, sign in again and then delete your '
              'account within 5 minutes. Nothing was changed.';
        case 'ACCOUNT_DELETION_RATE_LIMITED':
          return 'Too many attempts. Please wait a minute and try again. '
              'Nothing was changed.';
        case 'ACCOUNT_DELETION_UNAVAILABLE':
          return 'Account deletion is temporarily unavailable. Please try '
              'again later. Nothing was changed.';
      }
    }
    return 'Account deletion needs an internet connection. Nothing was changed.';
  }

  // ── support tickets ─────────────────────────────────────────────────────

  String? _guestToken;
  DateTime? _guestExpiresAt;

  /// Files a support ticket (`POST /v1/support-tickets`, 201; a replay of the
  /// same key and payload answers 200 with the same receipt).
  ///
  /// A signed-in user is identified by the bearer token. Otherwise a 24-hour
  /// support-only guest token is used (`X-Support-Guest`); the two identities
  /// are never sent together. [idempotencyKey] must be reused when the same
  /// submission is retried after an uncertain failure.
  Future<void> createSupportTicket(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
    required bool signedIn,
  }) async {
    if (signedIn) {
      await _client.post(
        '/v1/support-tickets',
        body: payload,
        headers: {'Idempotency-Key': idempotencyKey},
      );
      return;
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _supportGuestToken();
      try {
        await _client.post(
          '/v1/support-tickets',
          body: payload,
          requiresAuth: false,
          headers: {
            'Idempotency-Key': idempotencyKey,
            'X-Support-Guest': token,
          },
        );
        return;
      } on ApiException catch (e) {
        final guestRejected =
            e.errorCode == 'INVALID_SUPPORT_GUEST' ||
            e.errorCode == 'SUPPORT_GUEST_REQUIRED';
        if (!guestRejected || attempt == 1) rethrow;
        _guestToken = null; // expired or revoked: fetch a fresh one, once
      }
    }
  }

  Future<String> _supportGuestToken() async {
    final token = _guestToken;
    final expires = _guestExpiresAt;
    if (token != null &&
        expires != null &&
        expires.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return token;
    }
    final response = await _client.post(
      '/v1/support-tickets/guest-session',
      body: const <String, dynamic>{},
      requiresAuth: false,
    );
    final data = response.data;
    final fresh = data is Map ? data['guest_token']?.toString() : null;
    if (fresh == null || fresh.isEmpty) {
      throw const ApiException(
        statusCode: 502,
        errorCode: 'INVALID_RESPONSE',
        message: 'The support service returned no guest token.',
      );
    }
    _guestToken = fresh;
    _guestExpiresAt =
        DateTime.tryParse(
          data is Map ? data['expires_at']?.toString() ?? '' : '',
        ) ??
        DateTime.now().add(const Duration(hours: 1));
    return fresh;
  }

  @visibleForTesting
  void forgetGuestSession() {
    _guestToken = null;
    _guestExpiresAt = null;
  }
}
