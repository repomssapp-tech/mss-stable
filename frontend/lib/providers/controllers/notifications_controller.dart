import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/network/api_exception.dart';
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
/// * **Opened items stay read.** Account-scoped pending reads survive a restart
///   and overlay server snapshots until their write succeeds.
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
          task: _retryAndRefresh,
          onResume: _retryAndRefresh,
          onReconnect: _retryAndRefresh,
          observeLifecycle: false,
        );
  }

  /// A list loaded within this window is reused instead of fetched again.
  static const Duration freshFor = Duration(minutes: 2);

  /// Active-use poll period.
  static const Duration pollInterval = Duration(minutes: 5);

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
  int _accountGeneration = 0;
  int _writeRevision = 0;
  int _loadedRevision = 0;
  Future<void>? _restoringReads;
  bool _flushing = false;
  bool _readSyncFailed = false;
  Timer? _retry;

  final Set<String> _pendingRead = {};
  final Set<String> _pendingDelete = {};
  bool _pendingReadAll = false;
  bool _pendingDeleteAll = false;

  List<Map<String, dynamic>> get notifications {
    if (_pendingRead.isEmpty &&
        _pendingDelete.isEmpty &&
        !_pendingReadAll &&
        !_pendingDeleteAll) {
      return _notificationsList;
    }
    return [
      for (final item in _notificationsList)
        if (!_pendingDeleteAll && !_pendingDelete.contains(item['id']))
          if (_pendingReadAll || _pendingRead.contains(item['id']))
            {...item, 'read': true}
          else
            item,
    ];
  }

  bool get isLoading => _isLoading;
  bool get hasMore => _nextCursor != null;
  bool get readSyncPending =>
      _readSyncFailed && (_pendingRead.isNotEmpty || _pendingReadAll);

  /// Overlay pending reads on the most recent server count. An opened item
  /// from a push may sit beyond the first loaded page.
  int get unreadCount {
    if (_pendingReadAll || _pendingDeleteAll) return 0;
    final count = _serverUnreadCount;
    if (count == null) {
      return notifications.where((n) => n['read'] != true).length;
    }
    final alreadyRead = {
      for (final n in _notificationsList)
        if (n['read'] == true) n['id'],
    };
    final hidden = {
      ..._pendingRead,
      ..._pendingDelete,
    }.where((id) => !alreadyRead.contains(id)).length;
    return (count - hidden).clamp(0, count);
  }

  String _readKey(String owner) => 'notifications.pendingRead.$owner';
  String _requestKey(String owner) => 'notifications:$owner';

  Future<void> _restoreReads(String owner, int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (generation != _accountGeneration) return;
      _pendingRead.addAll(prefs.getStringList(_readKey(owner)) ?? const []);
      if (_pendingRead.isNotEmpty) _scheduleWrite();
    } catch (e) {
      debugPrint(
        '[NotificationsController] Could not restore pending reads: $e',
      );
    }
  }

  Future<void> _persistReads(String owner) async {
    final reads = _pendingRead.toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey(owner), reads);
    } catch (e) {
      debugPrint('[NotificationsController] Could not save pending reads: $e');
    }
  }

  Future<void> _retryAndRefresh() async {
    await flushPending();
    await refresh();
  }

  /// Starts following [userId]'s inbox: loads it once and polls while the app
  /// is in use.
  void subscribe(String userId) {
    if (_subscribedUserId == userId) return;
    unsubscribe();
    _notificationsList = [];
    _serverUnreadCount = null;
    _subscribedUserId = userId;
    _restoringReads = _restoreReads(userId, _accountGeneration);
    _poller.start();
    unawaited(
      _sseService.startListening(onRefetchNeeded: () => refresh(force: true)),
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
    final owner = _subscribedUserId;
    if (owner == null) return;
    final generation = _accountGeneration;
    await _restoringReads;
    if (generation != _accountGeneration) return;
    final outcome = await _requests.run<void>(
      _requestKey(owner),
      () => _load(generation),
      minInterval: freshFor,
      force: force,
    );
    // RequestManager may have shared a request that started before the write.
    if (outcome.ran &&
        generation == _accountGeneration &&
        _loadedRevision != _writeRevision) {
      await _requests.run<void>(
        _requestKey(owner),
        () => _load(generation),
        force: true,
      );
    }
  }

  Future<void> _load(int generation) async {
    final revision = _writeRevision;
    _isLoading = true;
    try {
      final page = await _apiService.getNotifications(limit: 50);
      if (generation != _accountGeneration || revision != _writeRevision) {
        return;
      }
      _notificationsList = page.items.map((dto) => dto.toUiMap()).toList();
      _nextCursor = page.nextCursor;
      _serverUnreadCount = page.unreadCount;
      _loadedRevision = revision;
    } finally {
      if (generation == _accountGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Appends the next page, de-duplicating by id.
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore || _subscribedUserId == null) return;
    final generation = _accountGeneration;
    final revision = _writeRevision;
    _isLoadingMore = true;
    try {
      final page = await _apiService.getNotifications(
        limit: 50,
        cursor: cursor,
      );
      if (generation != _accountGeneration || revision != _writeRevision) {
        return;
      }
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
      if (generation == _accountGeneration) _isLoadingMore = false;
    }
  }

  void unsubscribe() {
    _sseService.stopListening();
    final owner = _subscribedUserId;
    if (owner != null) _requests.invalidate(_requestKey(owner));
    _accountGeneration++;
    _subscribedUserId = null;
    _restoringReads = null;
    _isLoading = false;
    _isLoadingMore = false;
    _flushing = false;
    _readSyncFailed = false;
    _retry?.cancel();
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
  }

  // ── user changes: instant on screen, one batched request later ─────────

  Future<void> markNotificationRead(String id) => markNotificationsRead([id]);

  Future<void> markNotificationsRead(List<String> ids) async {
    final owner = _subscribedUserId;
    if (owner == null) return;
    final generation = _accountGeneration;
    await _restoringReads;
    if (generation != _accountGeneration) return;
    final knownRead = {
      for (final n in _notificationsList)
        if (n['read'] == true) n['id'],
    };
    _pendingRead.addAll(
      ids.where(
        (id) =>
            id.isNotEmpty &&
            !knownRead.contains(id) &&
            !_pendingDelete.contains(id),
      ),
    );
    notifyListeners();
    _scheduleWrite();
    await _persistReads(owner);
  }

  Future<void> markAllNotificationsRead() async {
    if (_subscribedUserId == null) return;
    _pendingReadAll = true;
    notifyListeners();
    _scheduleWrite();
  }

  Future<void> deleteNotifications(List<String> ids) async {
    _pendingDelete.addAll(ids);
    notifyListeners();
    _scheduleWrite();
  }

  /// Deletes the owner's whole inbox on the server after confirmation.
  Future<void> deleteAllNotifications() async {
    _pendingDeleteAll = true;
    notifyListeners();
    _scheduleWrite();
  }

  void _scheduleWrite() => _writes.run(flushPending);

  /// Sends a batch without dropping its local read overlay while it is in
  /// flight. Retrying is safe because the server's mutations are idempotent.
  Future<void> flushPending() async {
    final owner = _subscribedUserId;
    if (owner == null || _flushing) return;
    final generation = _accountGeneration;
    await _restoringReads;
    if (generation != _accountGeneration || _flushing) return;
    _writes.cancel();
    _retry?.cancel();
    final deleteAll = _pendingDeleteAll;
    final readAll = _pendingReadAll;
    final deletes = _pendingDelete.toList();
    final reads = _pendingRead.toList();
    final toRead = reads.where((id) => !deletes.contains(id)).toList();
    if (!deleteAll && !readAll && deletes.isEmpty && reads.isEmpty) return;

    _flushing = true;
    var failed = false;
    try {
      if (deleteAll) {
        await _apiService.deleteAll();
        if (generation != _accountGeneration) return;
      } else {
        if (deletes.isNotEmpty) await _apiService.deleteNotifications(deletes);
        if (generation != _accountGeneration) return;
        if (readAll) {
          await _apiService.markAllAsRead();
        } else if (toRead.isNotEmpty) {
          await _apiService.markManyAsRead(toRead);
        }
        if (generation != _accountGeneration) return;
      }
      final count = _serverUnreadCount;
      final readIds = {
        for (final n in _notificationsList)
          if (n['read'] == true) n['id'],
      };
      final changed = {
        ...deletes,
        ...toRead,
      }.where((id) => !readIds.contains(id)).length;
      _notificationsList = [
        for (final n in _notificationsList)
          if (!deleteAll && !deletes.contains(n['id']))
            if (readAll || toRead.contains(n['id']))
              {...n, 'read': true}
            else
              n,
      ];
      if (count != null) {
        _serverUnreadCount = deleteAll || readAll
            ? 0
            : (count - changed).clamp(0, count);
      }
      _pendingRead.removeAll(reads);
      _pendingDelete.removeAll(deletes);
      if (deleteAll) _pendingDeleteAll = false;
      if (readAll) _pendingReadAll = false;
      _readSyncFailed = false;
      _writeRevision++;
      notifyListeners();
      await _persistReads(owner);
      if (generation == _accountGeneration) await refresh(force: true);
    } catch (e) {
      if (generation != _accountGeneration) return;
      // A failed delete-all must never be retried against future arrivals.
      _pendingDelete.removeAll(deletes);
      if (deleteAll) _pendingDeleteAll = false;
      if (readAll) _pendingReadAll = false;
      failed = reads.isNotEmpty;
      _readSyncFailed = failed;
      notifyListeners();
      debugPrint('[NotificationsController] write failed: $e');
      final retryAfter = e is ApiException ? e.retryAfterSeconds ?? 0 : 0;
      if (failed) {
        _retry = Timer(
          Duration(seconds: retryAfter < 30 ? 30 : retryAfter),
          () {
            unawaited(flushPending());
          },
        );
      }
      if (deleteAll || deletes.isNotEmpty || readAll) {
        await refresh(force: true);
      }
    } finally {
      if (generation == _accountGeneration) {
        _flushing = false;
        if (!failed &&
            (_pendingRead.isNotEmpty ||
                _pendingDelete.isNotEmpty ||
                _pendingReadAll ||
                _pendingDeleteAll)) {
          _scheduleWrite();
        }
      }
    }
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
