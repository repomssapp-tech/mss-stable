import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../providers/app_state_provider.dart';
import 'auth_service.dart';
import 'rest_auth_service.dart';

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
    if (uri.scheme == 'com.inschemes.app' && uri.host == 'login-callback') {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null && error.isNotEmpty) {
        debugPrint('[DeepLinkService] OAuth provider returned error: $error');
        await AuthService.clearOAuthPending();
        return;
      }

      if (code != null && code.isNotEmpty) {
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
        } catch (e) {
          debugPrint('[DeepLinkService] Code exchange failed: $e');
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
