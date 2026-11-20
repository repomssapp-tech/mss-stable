import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../config/edition.dart';
import '../../providers/app_state_provider.dart';
import 'account_pending_deletion.dart';
import 'auth_service.dart';
import 'rest_auth_service.dart';
import 'sign_in_progress.dart';
import '../security/app_lock_service.dart';

/// Captures deep links and exchanges incoming authorization codes for REST sessions.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  void initialize(AppProvider provider) {
    if (_initialized) return;
    _initialized = true;

    // 1. Listen for background/foreground deep link arrivals
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, provider),
      onError: (err) =>
          debugPrint('[DeepLinkService] URI stream warning: $err'),
    );

    // 2. Handle cold start deep link if app was launched via URL
    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null) {
            _handleUri(uri, provider);
          }
        })
        .catchError((err) {
          debugPrint('[DeepLinkService] getInitialLink warning: $err');
        });
  }

  Future<void> _handleUri(Uri uri, AppProvider provider) async {
    // Never log the query: the OAuth callback carries a one-time code (#131).
    debugPrint(
      '[DeepLinkService] Received deep link: ${uri.scheme}://${uri.host}${uri.path}',
    );
    if (uri.scheme == kAppId && uri.host == 'login-callback') {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      // The server refused the sign-in: the administrator locked the app.
      if (error == 'app_locked') {
        AppLockService.instance.reportLocked();
        unawaited(AppLockService.instance.check());
      }
      if (error != null && error.isNotEmpty) {
        debugPrint('[DeepLinkService] OAuth provider returned error: $error');
        await AuthService.clearOAuthPending();
        SignInProgress.instance.finish();
        return;
      }

      if (code != null && code.isNotEmpty) {
        // The login screen shows a loading overlay until this finishes.
        SignInProgress.instance.completing();
        debugPrint(
          '[DeepLinkService] Exchanging auth code with REST backend...',
        );
        try {
          await RestAuthService.instance.exchangeCode(code);
          await AuthService.clearOAuthPending();
          await provider.checkSessionAndFetchProfile();
          debugPrint(
            '[DeepLinkService] Code exchange succeeded, profile loaded.',
          );
        } on AccountPendingDeletion catch (pending) {
          // The account was deleted within 30 days: ask before reactivating.
          await AuthService.clearOAuthPending();
          SignInProgress.instance.finish();
          await provider.offerAccountRestore(pending);
        } catch (e) {
          debugPrint('[DeepLinkService] Code exchange failed: $e');
          // Say so instead of silently showing the login screen again.
          await AuthService.clearOAuthPending();
          provider.reportSignInFailed();
        } finally {
          SignInProgress.instance.finish();
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
