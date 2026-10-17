import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/notifications/notifications_api_service.dart';
import '../app_state_seed_data.dart';

/// Owns the in-app notifications list, its REST API integration via
/// [NotificationsApiService], optional Supabase realtime subscription fallback,
/// and optimistic mutations for read/delete operations.
class NotificationsController extends ChangeNotifier {
  NotificationsController({NotificationsApiService? apiService})
      : _apiService = apiService ?? NotificationsApiService();

  final NotificationsApiService _apiService;

  // Notifications state (temporary seed; replaced by the REST fetch or stream).
  List<Map<String, dynamic>> _notificationsList = kSeedNotifications
      .map((m) => Map<String, dynamic>.of(m))
      .toList();

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  String? _subscribedUserId;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notificationsList;
  bool get isLoading => _isLoading;
  int get unreadCount => _notificationsList.where((n) => n['read'] != true).length;

  /// Fetches recent notifications from the REST backend.
  Future<void> fetchNotifications({bool refresh = false}) async {
    _isLoading = true;
    if (refresh) notifyListeners();

    try {
      final response = await _apiService.getNotifications(page: 1, limit: 50);
      if (response.notifications.isNotEmpty) {
        _notificationsList = response.notifications
            .map((dto) => dto.toUiMap())
            .toList();
      }
    } catch (e) {
      debugPrint('[NotificationsController] fetchNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribe(String userId) {
    if (_subscription != null && _subscribedUserId == userId) {
      return;
    }
    _subscribedUserId = userId;

    // Trigger initial REST fetch
    fetchNotifications();

    // Supabase realtime fallback (if client is configured and available)
    try {
      _subscription?.cancel();
      _subscription = Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (data) async {
              if (data.isEmpty) {
                _notificationsList = [];
                notifyListeners();
                return;
              }

              final sortedData = List<Map<String, dynamic>>.from(data);
              sortedData.sort((a, b) {
                final aTime =
                    DateTime.tryParse(a['created_at'] ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bTime =
                    DateTime.tryParse(b['created_at'] ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

              _notificationsList = sortedData.map((n) {
                final createdAt =
                    DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
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

                final type = n['notification_type'] ?? 'updates';

                final Map<String, dynamic> mapped = {
                  'id': n['id'].toString(),
                  'title': n['title'] ?? '',
                  'body': n['message'] ?? '',
                  'timeAgoCount': timeAgoCount,
                  'timeAgoUnit': timeAgoUnit,
                  'read': n['is_read'] ?? false,
                  'category': type,
                  'created_at': n['created_at'],
                };

                if (type == 'new_schemes') {
                  mapped['tag'] = n['title'].toString().contains('Vidyalaxmi')
                      ? 'Education'
                      : 'Skill Development';
                  mapped['isNew'] = true;
                } else if (type == 'reminders') {
                  mapped['deadline'] = n['title'].toString().contains('Matric')
                      ? '31 May 2026'
                      : '15 Jun 2026';
                  mapped['daysLeftCount'] =
                      n['title'].toString().contains('Matric') ? 5 : 20;
                } else if (type == 'updates') {
                  mapped['iconType'] = n['title'].toString().contains('Ayushman')
                      ? 'emblem'
                      : 'bank';
                } else if (type == 'profile') {
                  mapped['progress'] = 70;
                }

                return mapped;
              }).toList();

              notifyListeners();
            },
            onError: (err) {
              debugPrint(
                '[NotificationsController] Real-time subscription warning: $err',
              );
            },
          );
    } catch (e) {
      debugPrint('[NotificationsController] Supabase realtime unavailable: $e');
    }
  }

  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _subscribedUserId = null;
  }

  /// Full reset for auth sign-out: drop subscription and empty list.
  void reset() {
    unsubscribe();
    _notificationsList = [];
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notificationsList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notificationsList[index]['read'] = true;
      notifyListeners();
    }
    try {
      await _apiService.updateNotificationStatus(id, isRead: true);
    } catch (e) {
      debugPrint('[NotificationsController] Error marking notification read via REST: $e');
      // Fallback to Supabase if available
      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', id);
      } catch (_) {}
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (var n in _notificationsList) {
      n['read'] = true;
    }
    notifyListeners();

    try {
      await _apiService.markAllAsRead();
    } catch (e) {
      debugPrint('[NotificationsController] Error marking all read via REST: $e');
      final userId = _subscribedUserId;
      if (userId == null) return;
      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId);
      } catch (_) {}
    }
  }

  Future<void> deleteAllNotifications() async {
    final ids = _notificationsList.map((n) => n['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    _notificationsList.clear();
    notifyListeners();

    try {
      if (ids.isNotEmpty) {
        await _apiService.deleteNotifications(ids);
      }
    } catch (e) {
      debugPrint('[NotificationsController] Error deleting all via REST: $e');
      final userId = _subscribedUserId;
      if (userId == null) return;
      try {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('user_id', userId);
      } catch (_) {}
    }
  }

  Future<void> deleteNotifications(List<String> ids) async {
    _notificationsList.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();

    try {
      await _apiService.deleteNotifications(ids);
    } catch (e) {
      debugPrint('[NotificationsController] Error deleting notifications via REST: $e');
      try {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .inFilter('id', ids);
      } catch (_) {}
    }
  }

  Future<void> markNotificationsRead(List<String> ids) async {
    for (var n in _notificationsList) {
      if (ids.contains(n['id'])) {
        n['read'] = true;
      }
    }
    notifyListeners();

    try {
      await _apiService.markManyAsRead(ids);
    } catch (e) {
      debugPrint('[NotificationsController] Error marking read via REST: $e');
      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .inFilter('id', ids);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
