import 'dart:async';

import '../../screens/notifications/push_message_presenter.dart';
import '../../services/notifications/local_notification_service.dart';
import '../../services/notifications/push_models.dart';
import '../../services/notifications/push_notification_service.dart';

/// Wires push notifications into the app: the [PushNotificationService] that
/// registers this phone, and the [PushMessagePresenter] that shows what comes
/// in. Created only when the platform has a messaging SDK ([gateway] given).
class PushController {
  PushController({
    required PushMessagingGateway gateway,
    required Future<void> Function() refreshInbox,
  }) : _service = PushNotificationService(gateway: gateway),
       _presenter = PushMessagePresenter(
         observer: appRouteObserver,
         refreshInbox: refreshInbox,
       ) {
    _service.onForegroundMessage = (m, owner) =>
        unawaited(_presenter.showForeground(m, owner));
    _service.onOpenedMessage = (m, owner) =>
        unawaited(_presenter.open(m, owner));
    final local = LocalNotificationService.instance;
    local.onOpen = (id) => unawaited(_presenter.openById(id));
    final launchId = local.takeLaunchPayload();
    if (launchId != null) unawaited(_presenter.openById(launchId));
  }

  final PushNotificationService _service;
  final PushMessagePresenter _presenter;

  Future<void> start() => _service.start();

  /// The app returned to the foreground.
  Future<void> onAppResumed() => _service.onAppResumed();

  Future<void> dispose() => _service.dispose();
}
