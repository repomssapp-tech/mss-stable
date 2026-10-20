import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../account/app_session.dart';
import '../network/api_exception.dart';
import 'push_devices_api_service.dart';
import 'push_models.dart';

/// Keeps this phone registered for push notifications of the signed-in account
/// and hands incoming pushes to the app.
///
/// * **Permission** is asked once per run, after sign-in. A refusal never blocks
///   login or the in-app inbox; registration simply does not happen until the
///   permission is granted (checked again whenever the app is resumed).
/// * **Registration** (`PUT /v1/me/push-devices/:id`) happens after sign-in, when
///   the FCM token rotates, and when the account changed since the last one.
///   Every step re-checks that the same account is still signed in, so a
///   registration started for one account is never sent under another's bearer.
/// * **Sign-out** drops pending work and local registration state; the server
///   removes the session's registrations itself on logout.
/// * **Messages** carry only an inbox id. They are de-duplicated and passed on
///   only while an account is signed in; what to show is fetched with that
///   account's own credentials by whoever handles them.
class PushNotificationService {
  PushNotificationService({
    required PushMessagingGateway gateway,
    PushDevicesApiService? api,
    PushInstallationStore? installation,
    AppSession? session,
  }) : _gateway = gateway,
       _api = api ?? PushDevicesApiService(),
       _installation = installation ?? PushInstallationStore(),
       _session = session ?? AppSession.instance;

  final PushMessagingGateway _gateway;
  final PushDevicesApiService _api;
  final PushInstallationStore _installation;
  final AppSession _session;

  /// A push arrived while the app is open. [ownerId] is the signed-in account.
  void Function(PushMessage message, String ownerId)? onForegroundMessage;

  /// The user opened a notification (from the background or a cold start).
  void Function(PushMessage message, String ownerId)? onOpenedMessage;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final LinkedHashSet<String> _seenForeground = LinkedHashSet();
  final LinkedHashSet<String> _seenOpened = LinkedHashSet();
  static const int _seenLimit = 50;

  bool _started = false;
  bool _permissionAsked = false;
  int _generation = 0;
  String? _registeredOwner;
  String? _registeredToken;

  /// Starts following sign-in, token refresh and incoming messages.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscriptions
      ..add(_session.changes.listen(_onAuthChange))
      ..add(_gateway.onTokenRefresh.listen(_onTokenRefresh))
      ..add(
        _gateway.onForegroundMessage.listen((m) => _deliver(m, opened: false)),
      )
      ..add(
        _gateway.onOpenedFromBackground.listen(
          (m) => _deliver(m, opened: true),
        ),
      );
    if (_session.isSignedIn) unawaited(syncRegistration());
    final initial = await _gateway.getInitialMessage();
    if (initial != null) _deliver(initial, opened: true);
  }

  Future<void> dispose() async {
    _generation++;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _started = false;
  }

  /// Call when the app returns to the foreground: picks up a permission granted
  /// in system settings, a failed earlier registration, or an account change.
  Future<void> onAppResumed() async {
    if (_session.isSignedIn) await syncRegistration();
  }

  void _onAuthChange(AuthChange change) {
    _generation++;
    _registeredOwner = null;
    _registeredToken = null;
    _seenForeground.clear();
    _seenOpened.clear();
    if (change == AuthChange.signedIn) unawaited(syncRegistration());
  }

  bool _isCurrent(String owner, int generation) =>
      generation == _generation && _session.userId == owner;

  /// Makes sure the signed-in account has this phone's current token on the
  /// server. Safe to call repeatedly; it does nothing when already in sync.
  Future<void> syncRegistration() async {
    final owner = _session.userId;
    if (owner == null) return;
    final generation = _generation;
    try {
      var granted = await _gateway.hasPermission();
      if (!granted && !_permissionAsked) {
        _permissionAsked = true;
        granted = await _gateway.requestPermission();
      }
      if (!_isCurrent(owner, generation)) return;
      if (!granted) {
        await _unregisterIfRegistered(owner, generation);
        return;
      }
      final token = await _gateway.getToken();
      if (token == null || !_isCurrent(owner, generation)) return;
      await _register(owner, generation, token);
    } catch (e) {
      debugPrint('[Push] registration check failed: $e');
    }
  }

  void _onTokenRefresh(String token) {
    final owner = _session.userId;
    if (owner == null) return;
    final generation = _generation;
    unawaited(() async {
      try {
        if (!await _gateway.hasPermission()) return;
        await _register(owner, generation, token);
      } catch (e) {
        debugPrint('[Push] token refresh registration failed: $e');
      }
    }());
  }

  Future<void> _register(String owner, int generation, String token) async {
    if (_registeredOwner == owner && _registeredToken == token) return;
    final installationId = await _installation.getOrCreate();
    // The bearer is attached when the request is sent, so check the account
    // one last time immediately before.
    if (!_isCurrent(owner, generation)) return;
    try {
      await _api.register(installationId: installationId, token: token);
      if (!_isCurrent(owner, generation)) return;
      _registeredOwner = owner;
      _registeredToken = token;
    } on ApiException catch (e) {
      // 409 limit/conflict, 503 push not configured, 429 rate limit: nothing
      // useful to do until the next trigger; never retried in a loop.
      debugPrint('[Push] register rejected: ${e.statusCode} ${e.errorCode}');
    }
  }

  Future<void> _unregisterIfRegistered(String owner, int generation) async {
    if (_registeredOwner != owner) return;
    final installationId = await _installation.getOrCreate();
    if (!_isCurrent(owner, generation)) return;
    try {
      await _api.unregister(installationId);
      _registeredOwner = null;
      _registeredToken = null;
    } on ApiException catch (e) {
      debugPrint('[Push] unregister rejected: ${e.statusCode} ${e.errorCode}');
    }
  }

  /// Hands a message on once per notification id, and only while signed in.
  void _deliver(PushMessage message, {required bool opened}) {
    final owner = _session.userId;
    if (owner == null) return;
    final seen = opened ? _seenOpened : _seenForeground;
    if (!_remember(seen, message.notificationId)) return;
    (opened ? onOpenedMessage : onForegroundMessage)?.call(message, owner);
  }

  bool _remember(LinkedHashSet<String> seen, String id) {
    if (!seen.add(id)) return false;
    if (seen.length > _seenLimit) seen.remove(seen.first);
    return true;
  }
}
