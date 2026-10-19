import 'dart:async';

import 'package:flutter/foundation.dart';

import 'rest_auth_service.dart';
import 'token_storage.dart';

enum AuthChange { signedIn, signedOut }

/// Synchronous view of the signed-in account.
///
/// The MSS backend session lives in [TokenStorage], which is asynchronous. UI
/// and providers need to ask "who is signed in?" without awaiting, so this keeps
/// an in-memory copy, filled by [hydrate] at startup and kept current from
/// [TokenStorage.changes] (sign-in, token rotation, sign-out).
class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  AuthUser? _user;
  bool _hasTokens = false;
  StreamSubscription<void>? _subscription;
  TokenStorage? _storage;
  final StreamController<AuthChange> _events =
      StreamController<AuthChange>.broadcast(sync: true);

  /// Signed-in account, or null when signed out.
  AuthUser? get currentUser => _hasTokens ? _user : null;

  bool get isSignedIn => _hasTokens && _user != null;

  String? get userId => currentUser?.id;

  String? get email => currentUser?.email;

  /// Sign-in and sign-out transitions after [hydrate].
  Stream<AuthChange> get changes => _events.stream;

  /// Loads the stored session and starts following changes. Safe to call more
  /// than once; a later call re-reads storage.
  Future<void> hydrate({TokenStorage? storage}) async {
    final next = storage ?? _storage ?? TokenStorage.instance;
    if (!identical(next, _storage)) {
      await _subscription?.cancel();
      _storage = next;
      _subscription = next.changes.listen((_) => unawaited(_reload()));
    }
    await _reload(announce: false);
  }

  Future<void> _reload({bool announce = true}) async {
    final storage = _storage ?? TokenStorage.instance;
    final wasSignedIn = isSignedIn;
    try {
      _hasTokens = await storage.hasSession();
      final stored = _hasTokens ? await storage.getUser() : null;
      _user = stored == null
          ? null
          : AuthUser(
              id: stored.id,
              email: stored.email,
              name: stored.name ?? '',
              pictureUrl: stored.pictureUrl,
            );
    } catch (e) {
      debugPrint('[AppSession] reload failed: $e');
      _hasTokens = false;
      _user = null;
    }
    if (!announce) return;
    if (isSignedIn && !wasSignedIn) {
      _events.add(AuthChange.signedIn);
    } else if (!isSignedIn && wasSignedIn) {
      _events.add(AuthChange.signedOut);
    }
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    await _subscription?.cancel();
    _subscription = null;
    _storage = null;
    _user = null;
    _hasTokens = false;
  }
}
