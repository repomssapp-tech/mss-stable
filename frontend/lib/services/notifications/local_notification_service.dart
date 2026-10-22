import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows MSS notifications in the phone's notification shade.
///
/// Admin broadcasts (`POST /admin/notifications`) reach the phone as an FCM push
/// that carries only the inbox id. While the app is closed Android shows that
/// push itself, on the [channelId] channel set in AndroidManifest.xml. While the
/// app is open, [PushMessagePresenter] fetches the real title and message from
/// the inbox and calls [show], so the user still gets a heads-up notification
/// (with sound and vibration) instead of only an in-app banner.
///
/// Tapping a notification shown here calls [onOpen] with the inbox id.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  /// Also referenced by `com.google.firebase.messaging.default_notification_channel_id`.
  static const String channelId = 'mss_updates';
  static const String _channelName = 'MSS updates';
  static const String _channelDescription =
      'Scheme announcements and updates from MSS';
  static const String _icon = '@drawable/ic_stat_mss';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Called with the inbox id when the user taps a notification.
  void Function(String notificationId)? onOpen;

  bool _ready = false;
  bool get isReady => _ready;

  String? _launchId;

  /// The inbox id of the notification that launched the app, once: later
  /// calls return null so it is opened only one time.
  String? takeLaunchPayload() {
    final id = _launchId;
    _launchId = null;
    return id;
  }

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Creates the channel and starts listening for taps. Returns the inbox id
  /// of the notification that launched the app, if any.
  Future<String?> init() async {
    if (!_supported || _ready) return null;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id != null && id.isNotEmpty) onOpen?.call(id);
        },
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          enableVibration: true,
        ),
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final id = launch?.notificationResponse?.payload;
        if (id != null && id.isNotEmpty) _launchId = id;
        return _launchId;
      }
    } catch (e) {
      debugPrint('[LocalNotifications] init failed: $e');
    }
    return null;
  }

  /// Stable Android id for an inbox UUID, so a duplicate push (FCM + SSE)
  /// replaces the same notification instead of stacking a second one.
  static int idFor(String notificationId) =>
      notificationId.toLowerCase().hashCode & 0x7fffffff;

  /// Shows [title] / [body] as a heads-up notification. False when local
  /// notifications are unavailable, so the caller can fall back to a banner.
  Future<bool> show({
    required String notificationId,
    required String title,
    required String body,
  }) async {
    if (!_ready) return false;
    try {
      await _plugin.show(
        id: idFor(notificationId),
        title: title,
        body: body,
        payload: notificationId,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
            styleInformation: BigTextStyleInformation(body),
            category: AndroidNotificationCategory.message,
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[LocalNotifications] show failed: $e');
      return false;
    }
  }
}
