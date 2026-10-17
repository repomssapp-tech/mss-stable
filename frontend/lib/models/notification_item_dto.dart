/// DTO for REST notification responses from `/v1/me/notifications`.
class NotificationItemDto {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItemDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    return NotificationItemDto(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type']?.toString() ?? json['notification_type']?.toString() ?? 'updates',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      isRead: json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString())?.toUtc() : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'title': title,
    'body': body,
    'data': data,
    'is_read': isRead,
    if (readAt != null) 'read_at': readAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  /// Maps REST DTO to the legacy notification map shape expected by UI screens.
  Map<String, dynamic> toUiMap() {
    final difference = DateTime.now().difference(createdAt);
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

    // Normalize type to match category filters (new_schemes, reminders, updates, profile)
    String category = 'updates';
    final lowerType = type.toLowerCase();
    if (lowerType.contains('scheme') || lowerType == 'new_schemes') {
      category = 'new_schemes';
    } else if (lowerType.contains('reminder') ||
        lowerType.contains('deadline') ||
        lowerType == 'reminders') {
      category = 'reminders';
    } else if (lowerType.contains('profile')) {
      category = 'profile';
    }

    final Map<String, dynamic> map = {
      'id': id,
      'title': title,
      'body': body,
      'timeAgoCount': timeAgoCount,
      'timeAgoUnit': timeAgoUnit,
      'read': isRead,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };

    if (category == 'new_schemes') {
      map['tag'] = data['tag'] ??
          (title.contains('Vidyalaxmi') ? 'Education' : 'Skill Development');
      map['isNew'] = true;
    } else if (category == 'reminders') {
      map['deadline'] = data['deadline'] ??
          (title.contains('Matric') ? '31 May 2026' : '15 Jun 2026');
      map['daysLeftCount'] = data['days_left'] ?? (title.contains('Matric') ? 5 : 20);
    } else if (category == 'updates') {
      map['iconType'] = data['icon_type'] ??
          (title.contains('Ayushman') ? 'emblem' : 'bank');
    } else if (category == 'profile') {
      map['progress'] = data['progress'] ?? 70;
    }

    return map;
  }
}

/// Paginated list response for `GET /v1/me/notifications`.
class NotificationsListResponse {
  final List<NotificationItemDto> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final int limit;

  const NotificationsListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.limit,
  });

  factory NotificationsListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['notifications'] as List<dynamic>?) ?? [];
    return NotificationsListResponse(
      notifications: list
          .whereType<Map<String, dynamic>>()
          .map((item) => NotificationItemDto.fromJson(item))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }
}
