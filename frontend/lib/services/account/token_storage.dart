import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage manager for opaque OAuth/session tokens and server user identity.
///
/// Follows security recommendations from MSS API handoff:
/// - Tokens are opaque strings, never logged or serialized to analytics.
/// - Access tokens have short TTL (typically 900s), refresh tokens are rotated.
/// - Clear all tokens and identities on logout or refresh expiration.
class TokenStorage {
  TokenStorage([SharedPreferences? prefs]) : _prefs = prefs;
  static TokenStorage? _instance;
  static TokenStorage get instance => _instance ??= TokenStorage();
  @visibleForTesting
  static set testInstance(TokenStorage? storage) => _instance = storage;

  static const String _kAccessToken = 'mss_auth_access_token';
  static const String _kRefreshToken = 'mss_auth_refresh_token';
  static const String _kTokenType = 'mss_auth_token_type';
  static const String _kExpiresAt = 'mss_auth_expires_at';
  static const String _kUserId = 'mss_auth_user_id';
  static const String _kUserEmail = 'mss_auth_user_email';
  static const String _kUserName = 'mss_auth_user_name';
  static const String _kUserPicture = 'mss_auth_user_picture';

  SharedPreferences? _prefs;

  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );

  /// Fires after tokens or the stored user change (sign-in, rotation, sign-out).
  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves or rotates access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String tokenType = 'Bearer',
    int? expiresIn,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
    await prefs.setString(_kTokenType, tokenType);
    if (expiresIn != null) {
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      await prefs.setInt(_kExpiresAt, expiresAt.millisecondsSinceEpoch);
    }
    _notify();
  }

  /// Retrieves the current opaque access token.
  Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kAccessToken);
  }

  /// Retrieves the latest refresh token.
  Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kRefreshToken);
  }

  /// Retrieves token type ('Bearer').
  Future<String> getTokenType() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kTokenType) ?? 'Bearer';
  }

  /// Checks if token expiry is known and in the past.
  Future<bool> isAccessTokenExpired() async {
    final prefs = await _getPrefs();
    final expiresAtMs = prefs.getInt(_kExpiresAt);
    if (expiresAtMs == null) return false;
    // Buffer by 30 seconds to refresh ahead of actual boundary
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(seconds: 30)),
    );
  }

  /// Persists server user payload from exchange/login.
  Future<void> saveUser({
    required String id,
    required String email,
    String? name,
    String? pictureUrl,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(_kUserId, id);
    await prefs.setString(_kUserEmail, email);
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_kUserName, name);
    } else {
      await prefs.remove(_kUserName);
    }
    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      await prefs.setString(_kUserPicture, pictureUrl);
    } else {
      await prefs.remove(_kUserPicture);
    }
    _notify();
  }

  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserId);
  }

  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserEmail);
  }

  Future<String?> getUserName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserName);
  }

  Future<String?> getUserPictureUrl() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kUserPicture);
  }

  /// Returns cached user identity if available.
  Future<StoredUser?> getUser() async {
    final id = await getUserId();
    final email = await getUserEmail();
    if (id == null || email == null) return null;
    return StoredUser(
      id: id,
      email: email,
      name: await getUserName(),
      pictureUrl: await getUserPictureUrl(),
    );
  }

  /// Alias for clearing all stored credentials.
  Future<void> clearTokens() => clear();

  /// Checks whether an authenticated session exists.
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all token credentials and cached server user identity.
  Future<void> clear() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kRefreshToken);
      await prefs.remove(_kTokenType);
      await prefs.remove(_kExpiresAt);
      await prefs.remove(_kUserId);
      await prefs.remove(_kUserEmail);
      await prefs.remove(_kUserName);
      await prefs.remove(_kUserPicture);
    } catch (e) {
      debugPrint('[TokenStorage] Error clearing tokens: $e');
    }
    _notify();
  }
}

/// Lightweight representation of stored user identity.
class StoredUser {
  final String id;
  final String email;
  final String? name;
  final String? pictureUrl;

  const StoredUser({
    required this.id,
    required this.email,
    this.name,
    this.pictureUrl,
  });
}
