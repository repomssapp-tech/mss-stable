import '../../models/notification_item_dto.dart';
import '../network/api_client.dart';

/// Service adapter for MSS REST Notifications API (`/v1/me/notifications`).
class NotificationsApiService {
  NotificationsApiService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// Fetches paginated notifications list.
  Future<NotificationsListResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _client.get(
      '/v1/me/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (unreadOnly) 'unread_only': true,
      },
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return NotificationsListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    return const NotificationsListResponse(
      notifications: [],
      total: 0,
      unreadCount: 0,
      page: 1,
      limit: 20,
    );
  }

  /// Marks a single notification as read or unread.
  Future<NotificationItemDto> updateNotificationStatus(
    String id, {
    bool isRead = true,
  }) async {
    final response = await _client.patch(
      '/v1/me/notifications/$id',
      body: {'is_read': isRead},
      requiresAuth: true,
    );

    return NotificationItemDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Marks multiple notifications as read.
  Future<int> markManyAsRead(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final response = await _client.patch(
      '/v1/me/notifications/read',
      body: {'notification_ids': ids},
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return (response.data['updated_count'] as num?)?.toInt() ?? ids.length;
    }
    return ids.length;
  }

  /// Marks all unread notifications as read.
  Future<int> markAllAsRead() async {
    final response = await _client.post(
      '/v1/me/notifications/read-all',
      body: {},
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return (response.data['updated_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// Bulk deletes notifications by ID.
  Future<int> deleteNotifications(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final response = await _client.post(
      '/v1/me/notifications/delete',
      body: {'notification_ids': ids},
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return (response.data['deleted_count'] as num?)?.toInt() ?? ids.length;
    }
    return ids.length;
  }

  /// Fast unread counter for badge without fetching full list.
  Future<int> getUnreadCount() async {
    final response = await _client.get(
      '/v1/me/notifications/unread-count',
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return (response.data['unread_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
