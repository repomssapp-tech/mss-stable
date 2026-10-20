import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_models.dart';

/// Runs in its own isolate when a push arrives while the app is not running.
///
/// The server sends a generic notification message, which Android shows by
/// itself, so there is nothing to do here beyond keeping Firebase ready for a
/// future data message. Kept top-level and annotated so the engine can find it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Initialises Firebase from `android/app/google-services.json`.
///
/// Returns false instead of throwing when the platform has no Firebase
/// configuration (desktop, tests, a build without the config file): the app
/// then simply runs without push.
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    return true;
  } catch (e) {
    debugPrint('[Push] Firebase unavailable, push disabled: $e');
    return false;
  }
}

/// [PushMessagingGateway] over firebase_messaging.
class FirebasePushGateway implements PushMessagingGateway {
  FirebasePushGateway({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  static bool _allowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  @override
  Future<bool> requestPermission() async =>
      _allowed((await _messaging.requestPermission()).authorizationStatus);

  @override
  Future<bool> hasPermission() async => _allowed(
    (await _messaging.getNotificationSettings()).authorizationStatus,
  );

  // The MSS backend sends through FCM HTTP v1 to a registration *token*, which
  // is what getToken / onTokenRefresh still return. The newer register() /
  // onRegistered pair yields a Firebase Installation ID for direct send, which
  // the backend's push-devices contract does not accept.
  @override
  // ignore: deprecated_member_use
  Future<String?> getToken() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_parse).where((m) => m != null).cast();

  @override
  Stream<PushMessage> get onOpenedFromBackground => FirebaseMessaging
      .onMessageOpenedApp
      .map(_parse)
      .where((m) => m != null)
      .cast();

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _parse(message);
  }

  PushMessage? _parse(RemoteMessage message) =>
      PushMessage.fromData(message.data);
}
