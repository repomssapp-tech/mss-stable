import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state_seed_data.dart';

/// Owns the in-app notifications list, its Supabase realtime subscription
/// (the `notifications` table, filtered by `user_id`), and the read/delete
/// mutations that write back to that table.
///
/// Extracted from `AppProvider` (frontend refactor C1.4, slice 5) and used
/// behind the `AppProvider` facade: `AppProvider` forwards this controller's
/// `notifyListeners`, so every existing consumer keeps calling
/// `provider.notifications` / `provider.markNotificationRead(...)` unchanged.
///
/// The list starts as a deep copy of [kSeedNotifications] (so the shared seed
/// is never mutated by in-place `read` toggles); the realtime stream replaces
/// it wholesale on its first emission. Every mutator notifies exactly once, as
/// the pre-split code did.
///
/// [subscribe] is idempotent per user id — re-subscribing tears down the
/// socket and replays a full-table fetch, so the guard matters. [unsubscribe]
/// and [reset] are deliberately silent: their `AppProvider` call sites (the
/// auth `signedOut` branch, `deleteAccount`, `dispose`) each already emit an
/// `AppProvider` notification, so the observable notify topology is unchanged.
class NotificationsController extends ChangeNotifier {
  // Notifications state (temporary seed; replaced by the Supabase stream).
  // Seed content lives in app_state_seed_data.dart; deep-copied here so the
  // shared seed is never mutated by in-place `read` toggles.
  List<Map<String, dynamic>> _notificationsList = kSeedNotifications
      .map((m) => Map<String, dynamic>.of(m))
      .toList();

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  // Guards against redundant re-subscription (see [subscribe]).
  String? _subscribedUserId;

  List<Map<String, dynamic>> get notifications => _notificationsList;

  void subscribe(String userId) {
    if (_subscription != null && _subscribedUserId == userId) {
      return;
    }
    _subscribedUserId = userId;
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
              // Store a structured (count, unit) pair; the notifications screen
              // formats it via parameterized ARB keys so it renders in ta too.
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
              '[AppProvider] Real-time notifications subscription error: $err',
            );
          },
        );
  }

  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _subscribedUserId = null;
  }

  /// Full reset for the auth `signedOut` branch: drop the subscription and
  /// empty the list. Silent — the caller notifies.
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
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('[AppProvider] Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (var n in _notificationsList) {
      n['read'] = true;
    }
    notifyListeners();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AppProvider] Error marking all notifications read: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    _notificationsList.clear();
    notifyListeners();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AppProvider] Error deleting all notifications: $e');
    }
  }

  Future<void> deleteNotifications(List<String> ids) async {
    _notificationsList.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('[AppProvider] Error deleting notifications: $e');
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
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('[AppProvider] Error marking notifications read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
