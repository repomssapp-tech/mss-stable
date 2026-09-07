import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class AuthService {
  static final client = Supabase.instance.client;

  /// Written the moment a Google sign-in launches the external browser, and
  /// cleared once auth resolves. The provider redirect frequently cold-starts
  /// the app (the OS kills it while the browser is foregrounded), so an
  /// in-memory flag wouldn't survive; this persisted marker lets startup code
  /// know a PKCE exchange is still in flight and must not be torn down.
  static const _oauthPendingKey = 'oauth_pending_since';

  /// Past this age a pending marker is treated as an abandoned attempt.
  static const _oauthPendingTtl = Duration(minutes: 2);

  static String get _supabaseUrl => AppConfig.supabaseUrl;

  /// Used only before an online-only sign-in. Core catalog use never waits on
  /// this check.
  static Future<bool> canReachAuthenticationService({
    http.Client? httpClient,
  }) async {
    final ownsClient = httpClient == null;
    final activeClient = httpClient ?? http.Client();
    try {
      final response = await activeClient
          .get(Uri.parse('$_supabaseUrl/auth/v1/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode > 0;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } finally {
      if (ownsClient) activeClient.close();
    }
  }

  static const googleRedirectUrl = 'com.inschemes.app://login-callback/';

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static Future<bool> signInWithGoogle() async {
    try {
      await _markOAuthPending();
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: googleRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes: 'openid email profile',
      );
    } catch (e) {
      await clearOAuthPending();
      debugPrint('[AuthService] Unable to start Google OAuth: $e');
      rethrow;
    }
  }

  static Future<void> _markOAuthPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _oauthPendingKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // A missing marker only costs the startup grace period; never block
      // sign-in over it.
    }
  }

  /// True while a Google sign-in was started within [_oauthPendingTtl] and has
  /// not yet resolved. A stale marker is cleared as a side effect.
  static Future<bool> isOAuthPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startedMs = prefs.getInt(_oauthPendingKey);
      if (startedMs == null) return false;
      final age = DateTime.now().millisecondsSinceEpoch - startedMs;
      if (age < 0 || age > _oauthPendingTtl.inMilliseconds) {
        await prefs.remove(_oauthPendingKey);
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearOAuthPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_oauthPendingKey);
    } catch (_) {}
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
