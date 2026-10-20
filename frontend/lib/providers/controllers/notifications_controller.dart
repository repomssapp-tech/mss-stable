import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../services/network/debouncer.dart';
import '../../services/network/foreground_poller.dart';
import '../../services/network/request_manager.dart';
import '../../services/notifications/notifications_api_service.dart';
import '../../services/notifications/sse_event_service.dart';

/// Owns the in-app notifications inbox backed by the MSS REST API
/// ([NotificationsApiService]).
///
/// How it keeps the number of requests low:
///
/// * **Reads come from the local list.** Showing the inbox never fetches. The
///   list is refreshed by a poll every [pollInterval] of ACTIVE use, when the
///   app returns to the foreground or the network comes back, and after the
///   user's own changes. Every refresh goes through [RequestManager] with a
///   [freshFor] window, so a list loaded a minute ago is reused.
/// * **Writes are batched.** Marking items read or deleting them updates the
///   screen at once, but the request goes out [writeDelay] later, merged with
///   anything else the user did meanwhile (one request, not one per tap). The
///   pending batch is sent immediately when the app goes to the background.
/// * **A rejected write is not kept.** After every batch the inbox is reloaded,
///   so an item the server did not change shows its real state again.
class NotificationsController extends ChangeNotifier {
  NotificationsController({
    NotificationsApiService? apiService,
    SseEventService? sseService,
    RequestManager? requests,
    Duration writeDelay = const Duration(milliseconds: 1500),
    ForegroundPoller? poller,
  }) : _apiService = apiService ?? NotificationsApiService(),
       _sseService = sseService ?? SseEventService(),
       _requests = requests ?? RequestManager.instance,
       _writes = Debouncer(writeDelay) {
    _poller =
        poller ??
        ForegroundPoller(
          interval: pollInterval,
          task: refresh,
          onResume: refresh,
          onReconnect: refresh,
          observeLifecycle: false,
        );
  }

  /// A list loaded within this window is reused instead of fetched again.
  static const Duration freshFor = Duration(minutes: 2);

  /// Active-use poll period.
  static const Duration pollInterval = Duration(minutes: 5);

  static const String _requestKey = 'notifications';

  final NotificationsApiService _apiService;
  final SseEventService _sseService;
  final RequestManager _requests;
  final Debouncer _writes;
  late final ForegroundPoller _poller;

  List<Map<String, dynamic>> _notificationsList = [];
  String? _subscribedUserId;
  String? _nextCursor;
  int? _serverUnreadCount;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  final Set<String> _pendingRead = {};
  final Set<String> _pendingDelete = {};
  bool _pendingReadAll = false;
  bool _pendingDeleteAll = false;

  List<Map<String, dynamic>> get notifications => _notificationsList;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextCursor != null;

  /// All unread notifications of the account, as counted by the server; falls
  /// back to the loaded list until the first response arrives.
  int get unreadCount =>
      _serverUnreadCount ??
      _notificationsList.where((n) => n['read'] != true).length;

  /// Starts following [userId]'s inbox: loads it once and polls while the app
  /// is in use.
  void subscribe(String userId) {
    if (_subscribedUserId == userId) return;
    _subscribedUserId = userId;
    _poller.start();
    unawaited(
      _sseService.startListening(
        onRefetchNeeded: () => refresh(force: true),
      ),
    );
    unawaited(refresh(force: true));
  }

  /// The app's lifecycle events, forwarded by the one observer in AppProvider.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _poller.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) unawaited(flushPending());
  }

  /// Reloads the first page unless a recent load is still fresh.
  /// [force] is for the user's own actions; it still respects offline and a
  /// server Retry-After.
  Future<void> refresh({bool force = false}) async {
    if (_subscribedUserId == null) return;
    await _requests.run<void>(
      _requestKey,
      _load,
      minInterval: freshFor,
      force: force,
    );
  }

  Future<void> _load() async {
    _isLoading = true;
    try {
      final page = await _apiService.getNotifications(limit: 50);
      _notificationsList = page.items.map((dto) => dto.toUiMap()).toList();
      _nextCursor = page.nextCursor;
      _serverUnreadCount = page.unreadCount;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page, de-duplicating by id.
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore || _subscribedUserId == null) return;
    _isLoadingMore = true;
    try {
      final page = await _apiService.getNotifications(
        limit: 50,
        cursor: cursor,
      );
      final known = {for (final n in _notificationsList) n['id']};
      _notificationsList = [
        ..._notificationsList,
        for (final dto in page.items)
          if (!known.contains(dto.id)) dto.toUiMap(),
      ];
      _nextCursor = page.nextCursor;
      _serverUnreadCount = page.unreadCount;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationsController] loadMore error: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  void unsubscribe() {
    _sseService.stopListening();
    _subscribedUserId = null;
    _nextCursor = null;
    _poller.stop();
    _writes.cancel();
    _pendingRead.clear();
    _pendingDelete.clear();
    _pendingReadAll = false;
    _pendingDeleteAll = false;
  }

  /// Full reset for sign-out or account switch: nothing may carry over.
  void reset() {
    unsubscribe();
    unawaited(_sseService.clearCursor());
    _notificationsList = [];
    _serverUnreadCount = null;
    _requests.invalidate(_requestKey);
  }

  // ── user changes: instant on screen, one batched request later ─────────

  Future<void> markNotificationRead(String id) => markNotificationsRead([id]);

  Future<void> markNotificationsRead(List<String> ids) async {
    _markLocalRead((n) => ids.contains(n['id']));
    _pendingRead.addAll(ids);
    _scheduleWrite();
  }

  Future<void> markAllNotificationsRead() async {
    _markLocalRead((_) => true);
    _pendingReadAll = true;
    _scheduleWrite();
  }

  Future<void> deleteNotifications(List<String> ids) async {
    _notificationsList.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();
    _pendingRead.removeAll(ids);
    _pendingDelete.addAll(ids);
    _scheduleWrite();
  }

  /// Deletes the owner's whole inbox on the server. The caller must have shown
  /// an explicit confirmation; this is permanent and spans every page.
  Future<void> deleteAllNotifications() async {
    _notificationsList = [];
    notifyListeners();
    _pendingRead.clear();
    _pendingDelete.clear();
    _pendingDeleteAll = true;
    _scheduleWrite();
  }

  void _markLocalRead(bool Function(Map<String, dynamic> n) matches) {
    for (final n in _notificationsList) {
      if (matches(n)) n['read'] = true;
    }
    notifyListeners();
  }

  void _scheduleWrite() => _writes.run(flushPending);

  /// Sends everything the user changed since the last batch, in as few
  /// requests as possible, then reloads the inbox once.
  Future<void> flushPending() async {
    _writes.cancel();
    final deleteAll = _pendingDeleteAll;
    final readAll = _pendingReadAll;
    final deletes = _pendingDelete.toList();
    final reads = _pendingRead.toList();
    if (!deleteAll && !readAll && deletes.isEmpty && reads.isEmpty) return;
    _pendingDeleteAll = false;
    _pendingReadAll = false;
    _pendingDelete.clear();
    _pendingRead.clear();

    try {
      if (deleteAll) {
        await _apiService.deleteAll();
      } else {
        if (deletes.isNotEmpty) {
          await _apiService.deleteNotifications(deletes);
        }
        if (readAll) {
          await _apiService.markAllAsRead();
        } else if (reads.isNotEmpty) {
          await _apiService.markManyAsRead(reads);
        }
      }
    } catch (e) {
      debugPrint('[NotificationsController] write failed: $e');
    }
    // Reconcile with what the server really holds (also undoes a rejected change).
    await refresh(force: true);
  }

  @override
  void dispose() {
    _sseService.stopListening();
    _poller.stop();
    _writes.cancel();
    super.dispose();
  }
}
