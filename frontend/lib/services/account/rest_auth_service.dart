import 'dart:async';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'pkce_helper.dart';
import 'token_storage.dart';

/// Authenticated user identity returned by the MSS backend.
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? pictureUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.pictureUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      pictureUrl: json['picture_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'picture_url': pictureUrl,
  };
}

/// Active session device record from GET /v1/me/sessions.
class UserSession {
  final String id;
  final DateTime authenticatedAt;
  final DateTime expiresAt;
  final bool current;

  const UserSession({
    required this.id,
    required this.authenticatedAt,
    required this.expiresAt,
    required this.current,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id']?.toString() ?? '',
      authenticatedAt:
          DateTime.tryParse(json['authenticated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      current: json['current'] == true,
    );
  }
}

/// Service implementing MSS Backend REST Authentication & Session Management.
class RestAuthService {
  static RestAuthService? _instance;
  static RestAuthService get instance => _instance ??= RestAuthService();
  @visibleForTesting
  static set testInstance(RestAuthService? service) => _instance = service;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  RestAuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage.instance;

  /// Starts Google PKCE OAuth flow:
  /// 1. Generates RFC 7636 code_verifier and code_challenge.
  /// 2. Persists verifier locally across the browser roundtrip.
  /// 3. Calls POST /v1/auth/google/start with only the challenge. The redirect
  ///    back to the app (com.inschemes.app://login-callback/) is configured on
  ///    the server, never sent by the client.
  /// 4. Returns authorization_url to be opened in the system browser.
  Future<String> startGoogleLogin() async {
    final verifier = PkceHelper.generateCodeVerifier();
    final challenge = PkceHelper.generateCodeChallenge(verifier);

    // Save verifier locally for the post-redirect exchange
    await _tokenStorage.savePkceVerifier(verifier);

    final response = await _apiClient.post(
      '/auth/google/start',
      body: {'code_challenge': challenge},
      requiresAuth: false,
    );

    final data = response.data as Map<String, dynamic>;
    final authUrl = data['authorization_url']?.toString();
    if (authUrl == null || authUrl.isEmpty) {
      throw StateError(
        'Missing authorization_url in response from /auth/google/start',
      );
    }
    return authUrl;
  }

  /// Exchanges the one-time app code received from the deep-link redirect
  /// (valid 60 seconds, one use) with the saved code_verifier via
  /// POST /v1/auth/exchange.
  Future<AuthUser> exchangeCode(String code) async {
    final verifier = await _tokenStorage.readPkceVerifier();
    if (verifier == null || verifier.isEmpty) {
      throw StateError(
        'No pending PKCE code_verifier found. Please initiate login again.',
      );
    }

    try {
      final response = await _apiClient.post(
        '/auth/exchange',
        body: {'code': code.trim(), 'code_verifier': verifier},
        requiresAuth: false,
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token']?.toString() ?? '';
      final refreshToken = data['refresh_token']?.toString() ?? '';
      final expiresIn = (data['expires_in'] as num?)?.toInt();
      final tokenType = data['token_type']?.toString() ?? 'Bearer';

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
        expiresIn: expiresIn,
      );

      final userData = data['user'] as Map<String, dynamic>? ?? {};
      final user = AuthUser.fromJson(userData);
      await _tokenStorage.saveUser(
        id: user.id,
        email: user.email,
        name: user.name,
        pictureUrl: user.pictureUrl,
      );

      return user;
    } finally {
      await _tokenStorage.deletePkceVerifier();
    }
  }

  /// Optional local password login (for QA and developer identities).
  Future<AuthUser> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/password/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
      requiresAuth: false,
    );

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final tokenType = data['token_type']?.toString() ?? 'Bearer';

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
    );

    final userData = data['user'] as Map<String, dynamic>? ?? {};
    final user = AuthUser.fromJson(userData);
    await _tokenStorage.saveUser(
      id: user.id,
      email: user.email,
      name: user.name,
      pictureUrl: user.pictureUrl,
    );

    return user;
  }

  /// Fetches current user profile identity from GET /v1/me.
  Future<AuthUser?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/me');
      if (response.data is Map<String, dynamic>) {
        final userData = response.data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final user = AuthUser.fromJson(userData);
          await _tokenStorage.saveUser(
            id: user.id,
            email: user.email,
            name: user.name,
            pictureUrl: user.pictureUrl,
          );
          return user;
        }
      }
    } catch (e) {
      debugPrint('[RestAuthService] getCurrentUser failed: $e');
    }
    return null;
  }

  /// Asks the server whether the stored session is still valid.
  ///
  /// `true` = accepted, `false` = the server rejected it (deleted/disabled
  /// account or revoked session; local credentials are cleared by the client's
  /// refresh handling), `null` = could not tell (offline, timeout, 5xx), in
  /// which case the cached session should be trusted.
  Future<bool?> validateSession({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      await _apiClient.get('/me').timeout(timeout);
      return true;
    } on TimeoutException {
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
        return false;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Revokes the current session and clears local credentials.
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      debugPrint(
        '[RestAuthService] Remote logout failed (clearing locally): $e',
      );
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Revokes all active sessions for this account across all devices.
  Future<void> logoutAll() async {
    try {
      await _apiClient.post('/auth/logout-all');
    } catch (e) {
      debugPrint(
        '[RestAuthService] Remote logout-all failed (clearing locally): $e',
      );
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Returns list of active sessions for this user.
  Future<List<UserSession>> getSessions() async {
    final response = await _apiClient.get('/me/sessions');
    final data = response.data as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(UserSession.fromJson)
        .toList();
  }

  /// Terminates a specific session by its UUID.
  Future<void> deleteSession(String sessionId) async {
    await _apiClient.delete('/me/sessions/$sessionId');
  }

  /// Checks if password login is enabled on this account.
  Future<bool> hasPassword() async {
    final response = await _apiClient.get('/me/password');
    final data = response.data as Map<String, dynamic>?;
    return data?['password_enabled'] == true;
  }

  /// Sets or updates local password.
  Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    final payload = <String, dynamic>{'password': newPassword};
    if (currentPassword != null && currentPassword.isNotEmpty) {
      payload['current_password'] = currentPassword;
    }
    await _apiClient.put('/me/password', body: payload);
    // Setting/updating password revokes existing sessions per spec
    await _tokenStorage.clear();
  }

  /// Removes local password from account.
  Future<void> deletePassword(String currentPassword) async {
    await _apiClient.delete(
      '/me/password',
      body: {'current_password': currentPassword},
    );
    await _tokenStorage.clear();
  }
}
