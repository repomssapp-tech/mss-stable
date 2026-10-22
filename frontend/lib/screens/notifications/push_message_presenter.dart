import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notification_item_dto.dart';
import '../../services/account/app_session.dart';
import '../../services/haptics/haptics_service.dart';
import '../../services/notifications/local_notification_service.dart';
import '../../services/notifications/notifications_api_service.dart';
import '../../services/notifications/push_models.dart';
import '../notifications_screen.dart';

/// Navigator and messenger of the app's one MaterialApp, so a push can be shown
/// or opened from outside the widget tree.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final AppRouteObserver appRouteObserver = AppRouteObserver();

/// Notes when the app has left its splash screen. The splash always replaces
/// itself, so the first replace or push marks the real app being on screen; a
/// notification opened from a cold start waits for that.
class AppRouteObserver extends NavigatorObserver {
  bool shellReached = false;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      shellReached = true;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) shellReached = true;
  }
}

/// Shows an incoming push to the user: a phone notification with haptics while
/// the app is open, or the notification's details when one is tapped.
///
/// The push itself holds only an inbox id. The text shown always comes from the
/// authenticated inbox, and only after checking that the account that received
/// the push is still the one signed in.
class PushMessagePresenter {
  PushMessagePresenter({
    required this.observer,
    required Future<void> Function() refreshInbox,
    NotificationsApiService? api,
  }) : _refreshInbox = refreshInbox,
       _api = api ?? NotificationsApiService();

  final AppRouteObserver observer;
  final Future<void> Function() _refreshInbox;
  final NotificationsApiService _api;

  static const Duration _shellWait = Duration(seconds: 20);
  static const Duration _shellPoll = Duration(milliseconds: 300);

  bool _stillOwner(String ownerId) => AppSession.instance.userId == ownerId;

  /// Inbox ids already presented, so the same broadcast reaching the app over
  /// both FCM and the live stream buzzes and shows only once.
  final Set<String> _presented = {};

  /// A push arrived while the app is open: refresh the inbox, buzz, and show
  /// it in the phone's notification shade (a banner if that is unavailable).
  Future<void> showForeground(PushMessage message, String ownerId) async {
    try {
      if (!_presented.add(message.notificationId)) return;
      await _refreshInbox();
      final item = await _findInInbox(message.notificationId);
      if (item == null || !_stillOwner(ownerId)) return;
      unawaited(HapticsService.instance.notification());
      final shown = await LocalNotificationService.instance.show(
        notificationId: item.id,
        title: item.title,
        body: item.message,
      );
      if (!shown) _showBanner(item, ownerId);
    } catch (e) {
      debugPrint('[Push] foreground presentation failed: $e');
    }
  }

  void _showBanner(NotificationItemDto item, String ownerId) {
    final messenger = appMessengerKey.currentState;
    final context = appNavigatorKey.currentContext;
    if (messenger == null || context == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          action: SnackBarAction(
            label: l10n.viewDetails,
            onPressed: () => unawaited(_openItem(item.id, ownerId)),
          ),
        ),
      );
  }

  /// The user opened a notification from FCM: show its details.
  Future<void> open(PushMessage message, String ownerId) =>
      _openItem(message.notificationId, ownerId);

  /// The user tapped a notification this app put in the shade.
  Future<void> openById(String notificationId) async {
    final owner = AppSession.instance.userId;
    if (owner == null) return;
    await _openItem(notificationId.toLowerCase(), owner);
  }

  /// Refreshes the inbox, then opens the inbox with [id]'s details on top. If
  /// the item is gone (deleted, or a different account), only the inbox opens.
  Future<void> _openItem(String id, String ownerId) async {
    NotificationItemDto? item;
    try {
      await _refreshInbox();
      item = await _findInInbox(id);
    } catch (e) {
      debugPrint('[Push] inbox refresh on open failed: $e');
    }
    final deadline = DateTime.now().add(_shellWait);
    while (!observer.shellReached || appNavigatorKey.currentState == null) {
      if (DateTime.now().isAfter(deadline)) return;
      await Future<void>.delayed(_shellPoll);
    }
    if (!_stillOwner(ownerId)) return;
    final navigator = appNavigatorKey.currentState!;
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
    );
    if (item != null) {
      final map = item.toUiMap();
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationDetailScreen(item: map),
          ),
        ),
      );
    }
  }

  /// The inbox item for [id], read with the signed-in account's credentials.
  Future<NotificationItemDto?> _findInInbox(String id) async {
    final page = await _api.getNotifications(limit: 20);
    for (final item in page.items) {
      if (item.id.toLowerCase() == id) return item;
    }
    return null;
  }
}
