import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../network/connectivity_service.dart';
import 'app_session.dart';
import 'rest_auth_service.dart';

class AuthService {
  /// Written the moment a Google sign-in launches the external browser, and
  /// cleared once auth resolves. The provider redirect frequently cold-starts
  /// the app (the OS kills it while the browser is foregrounded), so an
  /// in-memory flag wouldn't survive; this persisted marker lets startup code
  /// know a PKCE exchange is still in flight and must not be torn down.
  static const _oauthPendingKey = 'oauth_pending_since';

  /// Past this age a pending marker is treated as an abandoned attempt.
  static const _oauthPendingTtl = Duration(minutes: 2);

  /// Used only before an online-only sign-in. Core catalog use never waits on
  /// this check.
  static Future<bool> canReachAuthenticationService({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // The phone itself says there is no network: no request is needed.
    if (!ConnectivityService.instance.isOnline) return false;
    final ownsClient = httpClient == null;
    final activeClient = httpClient ?? http.Client();
    try {
      final uri = Uri.tryParse('${AppConfig.apiV1Url}/health');
      if (uri == null) return false;
      final res = await activeClient.get(uri).timeout(timeout);
      return res.statusCode >= 200 && res.statusCode < 400;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } catch (e) {
      debugPrint('[AuthService] canReachAuthenticationService failed: $e');
      return false;
    } finally {
      if (ownsClient) activeClient.close();
    }
  }

  static const googleRedirectUrl = 'com.inschemes.app://login-callback/';

  /// The signed-in account, or null.
  static AuthUser? get currentUser => AppSession.instance.currentUser;

  static bool get isSignedIn => AppSession.instance.isSignedIn;

  static Future<bool> signInWithGoogle() async {
    try {
      await _markOAuthPending();
      final authUrl = await RestAuthService.instance.startGoogleLogin();
      final uri = Uri.parse(authUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not launch Google authentication browser.');
      }
      return true;
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
    try {
      await RestAuthService.instance.logout();
    } catch (e) {
      debugPrint('[AuthService] Rest logout warning: $e');
    }
  }
}
