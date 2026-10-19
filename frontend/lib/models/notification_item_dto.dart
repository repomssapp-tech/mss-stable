/// One inbox item from `GET /v1/me/notifications`.
///
/// Fields are exactly those of the API: `id`, `title`, `message`,
/// `notification_type` (new_schemes | reminders | updates | profile), `is_read`
/// and `created_at`. The server sends no deadline, progress, tag or scheme
/// reference, so none are invented here.
class NotificationItemDto {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItemDto({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  static const Set<String> categories = {
    'new_schemes',
    'reminders',
    'updates',
    'profile',
  };

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    final type = json['notification_type']?.toString() ?? 'updates';
    return NotificationItemDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notificationType: categories.contains(type) ? type : 'updates',
      isRead: json['is_read'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'notification_type': notificationType,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  /// Maps the item to the notification map shape the UI screens read.
  /// The relative time is derived on the device from `created_at`.
  Map<String, dynamic> toUiMap({DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(createdAt);
    int? timeAgoCount;
    String timeAgoUnit = 'now';
    if (difference.inDays > 0) {
      timeAgoCount = difference.inDays;
      timeAgoUnit = 'd';
    } else if (difference.inHours > 0) {
      timeAgoCount = difference.inHours;
      timeAgoUnit = 'h';
    } else if (difference.inMinutes > 0) {
      timeAgoCount = difference.inMinutes;
      timeAgoUnit = 'm';
    }

    return {
      'id': id,
      'title': title,
      'body': message,
      'timeAgoCount': timeAgoCount,
      'timeAgoUnit': timeAgoUnit,
      'read': isRead,
      'category': notificationType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// One page of `GET /v1/me/notifications`.
///
/// [unreadCount] counts every unread notification of the owner, independent of
/// the filters and of how many pages were loaded. [nextCursor] is opaque.
class NotificationsPage {
  final List<NotificationItemDto> items;
  final String? nextCursor;
  final int unreadCount;

  const NotificationsPage({
    required this.items,
    required this.nextCursor,
    required this.unreadCount,
  });

  static const NotificationsPage empty = NotificationsPage(
    items: [],
    nextCursor: null,
    unreadCount: 0,
  );

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?) ?? const [];
    final cursor = json['next_cursor'];
    return NotificationsPage(
      items: list
          .whereType<Map<String, dynamic>>()
          .map(NotificationItemDto.fromJson)
          .toList(),
      nextCursor: cursor is String && cursor.isNotEmpty ? cursor : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
