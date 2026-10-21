import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the access and refresh tokens live. Production uses the Android
/// Keystore / iOS Keychain; tests inject a plain in-memory store.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Encrypted at rest (issue #131: tokens used to sit in plain SharedPreferences).
class KeystoreSecretStore implements SecretStore {
  KeystoreSecretStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Unencrypted store backed by SharedPreferences, for tests only.
class PrefsSecretStore implements SecretStore {
  PrefsSecretStore(this._prefs);
  final SharedPreferences _prefs;
  @override
  Future<String?> read(String key) async => _prefs.getString(key);
  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> delete(String key) => _prefs.remove(key);
}

/// Storage manager for opaque OAuth/session tokens and server user identity.
///
/// Follows security recommendations from MSS API handoff:
/// - Tokens are opaque strings, never logged or serialized to analytics.
/// - Access tokens have short TTL (typically 900s), refresh tokens are rotated.
/// - Clear all tokens and identities on logout or refresh expiration.
class TokenStorage {
  TokenStorage([SharedPreferences? prefs, SecretStore? secrets])
    : _prefs = prefs,
      _secrets =
          secrets ??
          (prefs != null ? PrefsSecretStore(prefs) : KeystoreSecretStore());
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
  static const String _kPkceVerifier = 'mss_pkce_code_verifier';

  SharedPreferences? _prefs;
  final SecretStore _secrets;

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
    await _secrets.write(_kAccessToken, accessToken);
    await _secrets.write(_kRefreshToken, refreshToken);
    await prefs.setString(_kTokenType, tokenType);
    if (expiresIn != null) {
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      await prefs.setInt(_kExpiresAt, expiresAt.millisecondsSinceEpoch);
    }
    _notify();
  }

  /// Reads a token from the secret store, moving a legacy plain-text copy
  /// (app <= 1.3.0) into it on first read so existing sessions survive.
  Future<String?> _readSecret(String key) async {
    final value = await _secrets.read(key);
    if (value != null) return value;
    final prefs = await _getPrefs();
    if (_secrets is PrefsSecretStore) return null;
    final legacy = prefs.getString(key);
    if (legacy == null) return null;
    await _secrets.write(key, legacy);
    await prefs.remove(key);
    return legacy;
  }

  /// Retrieves the current opaque access token.
  Future<String?> getAccessToken() => _readSecret(_kAccessToken);

  /// Retrieves the latest refresh token.
  Future<String?> getRefreshToken() => _readSecret(_kRefreshToken);

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
    // The email is personal data: encrypted like the tokens (SEC-02).
    await _secrets.write(_kUserEmail, email);
    // Drop a legacy plain copy (a test PrefsSecretStore shares that slot).
    if (_secrets is! PrefsSecretStore) await prefs.remove(_kUserEmail);
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

  Future<String?> getUserEmail() => _readSecret(_kUserEmail);

  /// The PKCE code_verifier kept across the browser round trip, encrypted
  /// (SEC-02). Deleted as soon as the code exchange finishes.
  Future<void> savePkceVerifier(String verifier) =>
      _secrets.write(_kPkceVerifier, verifier);

  Future<String?> readPkceVerifier() => _secrets.read(_kPkceVerifier);

  Future<void> deletePkceVerifier() => _secrets.delete(_kPkceVerifier);

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
      await _secrets.delete(_kAccessToken);
      await _secrets.delete(_kRefreshToken);
      await _secrets.delete(_kUserEmail);
      await _secrets.delete(_kPkceVerifier);
      // Legacy plain-text copies from app <= 1.3.0.
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
