import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// What the app keeps from a push message.
///
/// The server's push is generic: a short "new update" notification plus the
/// inbox UUID in `data.notification_id`. Content shown to the user is always
/// fetched from the authenticated inbox, never taken from the push itself.
class PushMessage {
  const PushMessage({required this.notificationId});

  final String notificationId;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// True when [value] is a UUID.
  static bool isUuid(String value) => _uuid.hasMatch(value);

  /// Reads `notification_id` from an FCM data payload; null when it is missing
  /// or not a UUID (so a malformed push can never reach an API path).
  static PushMessage? fromData(Map<String, dynamic> data) {
    final id = data['notification_id']?.toString().trim();
    if (id == null || !isUuid(id)) return null;
    return PushMessage(notificationId: id.toLowerCase());
  }
}

/// The platform messaging SDK, behind an interface so the registration logic
/// can be tested without Firebase.
abstract class PushMessagingGateway {
  /// Asks for the OS notification permission; true when notifications may show.
  Future<bool> requestPermission();

  /// Whether the OS permission is already granted (no prompt).
  Future<bool> hasPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  /// A push that arrived while the app is open.
  Stream<PushMessage> get onForegroundMessage;

  /// The user tapped a notification while the app was in the background.
  Stream<PushMessage> get onOpenedFromBackground;

  /// The notification that launched the app from a closed state, if any.
  Future<PushMessage?> getInitialMessage();
}

/// A random id for this app installation, kept across launches. It is the
/// installation id of `PUT /v1/me/push-devices/:id`, not a user id.
class PushInstallationStore {
  PushInstallationStore({Random? random}) : _random = random ?? Random.secure();

  static const String _key = 'push_installation_uuid';
  final Random _random;

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && PushMessage.isUuid(existing)) return existing;
    final created = _newUuidV4();
    await prefs.setString(_key, created);
    return created;
  }

  String _newUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    String hex(int from, int to) => bytes
        .sublist(from, to)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
