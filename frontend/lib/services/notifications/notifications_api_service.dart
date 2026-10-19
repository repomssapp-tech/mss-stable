import '../../models/notification_item_dto.dart';
import '../network/api_client.dart';

/// Client for the MSS notifications API (`/v1/me/notifications`).
///
/// The owner comes from the bearer token; no user id is ever sent. Writes use
/// the documented bodies: exactly one of `{ids: [...]}` (1..100 UUIDs) or
/// `{all: true}`.
class NotificationsApiService {
  NotificationsApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const int maxIdsPerRequest = 100;
  static const String _base = '/v1/me/notifications';

  /// Lists a page of the inbox, newest first.
  ///
  /// [cursor] must be the exact `next_cursor` of the previous page with the same
  /// filters; start a fresh first page when a filter changes.
  Future<NotificationsPage> getNotifications({
    String? category,
    bool? isRead,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      _base,
      queryParameters: {
        'category': ?category,
        if (isRead != null) 'is_read': isRead.toString(),
        'limit': limit.clamp(1, 50),
        'cursor': ?cursor,
      },
    );
    final data = response.data;
    return data is Map<String, dynamic>
        ? NotificationsPage.fromJson(data)
        : NotificationsPage.empty;
  }

  /// Marks one notification read. Returns how many rows changed (0 if it was
  /// already read or is not the caller's).
  Future<int> markRead(String id) async {
    final response = await _client.patch('$_base/$id', body: {'is_read': true});
    return _count(response.data, 'updated');
  }

  /// Marks the given notifications read, in batches of at most 100.
  Future<int> markManyAsRead(List<String> ids) => _inBatches(ids, (
    batch,
  ) async {
    final response = await _client.patch('$_base/read', body: {'ids': batch});
    return _count(response.data, 'updated');
  });

  /// Marks every notification of the owner read.
  Future<int> markAllAsRead() async {
    final response = await _client.post('$_base/read-all', body: const {});
    return _count(response.data, 'updated');
  }

  /// Permanently deletes the given notifications, in batches of at most 100.
  Future<int> deleteNotifications(List<String> ids) => _inBatches(ids, (
    batch,
  ) async {
    final response = await _client.post('$_base/delete', body: {'ids': batch});
    return _count(response.data, 'deleted');
  });

  /// Permanently deletes the owner's entire inbox, across pages and
  /// categories. Callers must have an explicit user confirmation.
  Future<int> deleteAll() async {
    final response = await _client.post('$_base/delete', body: {'all': true});
    return _count(response.data, 'deleted');
  }

  /// Unread badge count (all categories).
  Future<int> getUnreadCount() async {
    final response = await _client.get('$_base/unread-count');
    return _count(response.data, 'unread_count');
  }

  int _count(dynamic data, String key) =>
      data is Map<String, dynamic> ? (data[key] as num?)?.toInt() ?? 0 : 0;

  /// Batches are not atomic: an error stops at the failing batch.
  Future<int> _inBatches(
    List<String> ids,
    Future<int> Function(List<String> batch) send,
  ) async {
    final unique = ids.toSet().toList();
    var total = 0;
    for (var i = 0; i < unique.length; i += maxIdsPerRequest) {
      final end = (i + maxIdsPerRequest).clamp(0, unique.length);
      total += await send(unique.sublist(i, end));
    }
    return total;
  }
}
