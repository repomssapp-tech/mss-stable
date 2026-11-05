import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/notification_item_dto.dart';
import 'package:frontend/providers/controllers/notifications_controller.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/request_manager.dart';
import 'package:frontend/services/notifications/notifications_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _id1 = '11111111-1111-4111-8111-111111111111';
const _id2 = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> _item(String id, {bool read = false, String? type}) => {
  'id': id,
  'title': 'Profile reminder',
  'message': 'Review your saved profile details.',
  'notification_type': type ?? 'profile',
  'is_read': read,
  'created_at': '2026-10-16T12:00:00.123456Z',
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokenStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tokenStorage = TokenStorage(prefs);
    await tokenStorage.saveTokens(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
    );
  });

  NotificationsApiService serviceFor(
    Future<http.Response> Function(http.Request) handler,
  ) => NotificationsApiService(
    client: ApiClient(
      baseUrl: 'https://mssapi.msmeschemes.org',
      httpClient: MockClient(handler),
      tokenStorage: tokenStorage,
    ),
  );

  group('NotificationsApiService', () {
    test(
      'lists a page with cursor, filters and the server unread count',
      () async {
        final service = serviceFor((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/me/notifications');
          expect(request.url.queryParameters, {
            'category': 'updates',
            'is_read': 'false',
            'limit': '20',
            'cursor': 'abc',
          });
          expect(request.headers['authorization'], 'Bearer test-access-token');
          return _json({
            'items': [_item(_id1)],
            'next_cursor': 'next-page',
            'unread_count': 3,
          });
        });

        final page = await service.getNotifications(
          category: 'updates',
          isRead: false,
          cursor: 'abc',
        );

        expect(page.items.single.id, _id1);
        expect(page.nextCursor, 'next-page');
        expect(page.unreadCount, 3);
      },
    );

    test('an empty inbox is a valid page', () async {
      final service = serviceFor(
        (_) async =>
            _json({'items': [], 'next_cursor': null, 'unread_count': 0}),
      );

      final page = await service.getNotifications();

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
      expect(page.unreadCount, 0);
    });

    test('maps an item without inventing deadlines, tags or progress', () {
      final dto = NotificationItemDto.fromJson(_item(_id1, type: 'reminders'));
      final ui = dto.toUiMap(now: DateTime.utc(2026, 10, 16, 14));

      expect(ui['id'], _id1);
      expect(ui['body'], 'Review your saved profile details.');
      expect(ui['category'], 'reminders');
      expect(ui['read'], false);
      expect(ui['timeAgoUnit'], 'h');
      expect(ui['timeAgoCount'], 1);
      for (final invented in [
        'deadline',
        'daysLeftCount',
        'tag',
        'progress',
        'iconType',
        'isNew',
      ]) {
        expect(ui.containsKey(invented), isFalse, reason: invented);
      }
    });

    test('markRead sends PATCH /:id {is_read:true}', () async {
      final service = serviceFor((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/v1/me/notifications/$_id1');
        expect(jsonDecode(request.body), {'is_read': true});
        return _json({'updated': 1});
      });

      expect(await service.markRead(_id1), 1);
    });

    test('markManyAsRead sends {ids} and de-duplicates', () async {
      final service = serviceFor((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/v1/me/notifications/read');
        expect(jsonDecode(request.body), {
          'ids': [_id1, _id2],
        });
        return _json({'updated': 2});
      });

      expect(await service.markManyAsRead([_id1, _id2, _id1]), 2);
    });

    test('selections over 100 are split into batches', () async {
      final bodies = <List<dynamic>>[];
      final service = serviceFor((request) async {
        bodies.add((jsonDecode(request.body) as Map)['ids'] as List);
        return _json({'deleted': bodies.last.length});
      });
      final ids = [for (var i = 0; i < 250; i++) 'id-$i'];

      expect(await service.deleteNotifications(ids), 250);
      expect(bodies.map((b) => b.length), [100, 100, 50]);
    });

    test('markAllAsRead posts {} to /read-all', () async {
      final service = serviceFor((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/me/notifications/read-all');
        expect(jsonDecode(request.body), isEmpty);
        return _json({'updated': 5});
      });

      expect(await service.markAllAsRead(), 5);
    });

    test('deleteAll sends {all:true}; delete sends {ids}', () async {
      final bodies = <Object?>[];
      final service = serviceFor((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/me/notifications/delete');
        bodies.add(jsonDecode(request.body));
        return _json({'deleted': 4});
      });

      expect(await service.deleteAll(), 4);
      expect(await service.deleteNotifications([_id1]), 4);
      expect(bodies, [
        {'all': true},
        {
          'ids': [_id1],
        },
      ]);
    });

    test('getUnreadCount reads unread_count', () async {
      final service = serviceFor((request) async {
        expect(request.url.path, '/v1/me/notifications/unread-count');
        return _json({'unread_count': 7});
      });

      expect(await service.getUnreadCount(), 7);
    });
  });

  group('NotificationsController', () {
    late DateTime now;
    late RequestManager requests;

    setUp(() {
      now = DateTime.utc(2026, 10, 18, 12);
      requests = RequestManager(clock: () => now);
    });

    NotificationsController controllerFor(
      Future<http.Response> Function(http.Request) handler,
    ) => NotificationsController(
      apiService: serviceFor(handler),
      requests: requests,
      writeDelay: const Duration(milliseconds: 20),
    );

    test('starts empty and only loads once subscribed to an account', () async {
      var requestsMade = 0;
      final controller = controllerFor((_) async {
        requestsMade++;
        return _json({'items': [], 'next_cursor': null, 'unread_count': 0});
      });

      expect(controller.notifications, isEmpty);
      await controller.refresh();
      expect(requestsMade, 0);
    });

    test(
      'a list loaded two minutes ago is reused, not fetched again',
      () async {
        var gets = 0;
        final controller = controllerFor((request) async {
          gets++;
          return _json({
            'items': [_item(_id1)],
            'next_cursor': null,
            'unread_count': 1,
          });
        });
        controller.subscribe('user-1');
        await controller.refresh(force: true);
        final afterLoad = gets;

        await controller.refresh(); // opening the screen / app resume
        now = now.add(const Duration(seconds: 119));
        await controller.refresh();
        expect(gets, afterLoad, reason: 'still fresh');

        now = now.add(const Duration(seconds: 2));
        await controller.refresh();
        expect(gets, afterLoad + 1);
        controller.unsubscribe();
      },
    );

    test('a burst of read taps becomes one request', () async {
      final writes = <String>[];
      final controller = controllerFor((request) async {
        if (request.method == 'GET') {
          return _json({
            'items': [_item(_id1), _item(_id2)],
            'next_cursor': null,
            'unread_count': 2,
          });
        }
        writes.add('${request.method} ${request.url.path} ${request.body}');
        return _json({'updated': 2});
      });
      controller.subscribe('user-1');
      await controller.refresh(force: true);

      await controller.markNotificationRead(_id1);
      await controller.markNotificationRead(_id2);
      // Instant on screen, nothing sent yet.
      expect(controller.notifications.every((n) => n['read'] == true), isTrue);
      expect(writes, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(writes.length, 1);
      expect(writes.single, contains('/v1/me/notifications/read'));
      expect(jsonDecode(writes.single.split(' ').last), {
        'ids': [_id1, _id2],
      });
      controller.unsubscribe();
    });

    test('deleted items are not also marked read', () async {
      final writes = <String>[];
      final controller = controllerFor((request) async {
        if (request.method == 'GET') {
          return _json({
            'items': [_item(_id1), _item(_id2)],
            'next_cursor': null,
            'unread_count': 2,
          });
        }
        writes.add(request.url.path);
        return _json({'deleted': 1, 'updated': 1});
      });
      controller.subscribe('user-1');
      await controller.refresh(force: true);

      await controller.markNotificationRead(_id1);
      await controller.deleteNotifications([_id1]);
      await controller.flushPending();

      expect(writes, ['/v1/me/notifications/delete']);
      controller.unsubscribe();
    });

    test('reads, deletes and reloads from the server', () async {
      var inbox = [_item(_id1), _item(_id2)];
      final controller = controllerFor((request) async {
        if (request.method == 'GET') {
          return _json({
            'items': inbox,
            'next_cursor': null,
            'unread_count': inbox.where((n) => n['is_read'] != true).length,
          });
        }
        if (request.url.path.endsWith('/delete')) {
          final ids = (jsonDecode(request.body) as Map)['ids'] as List;
          inbox = inbox.where((n) => !ids.contains(n['id'])).toList();
          return _json({'deleted': ids.length});
        }
        final ids = (jsonDecode(request.body) as Map)['ids'] as List;
        inbox = [
          for (final n in inbox)
            ids.contains(n['id']) ? {...n, 'is_read': true} : n,
        ];
        return _json({'updated': ids.length});
      });

      controller.subscribe('user-1');
      await controller.refresh(force: true);
      expect(controller.notifications.length, 2);
      expect(controller.unreadCount, 2);

      await controller.markNotificationRead(_id1);
      await controller.flushPending();
      expect(controller.unreadCount, 1);

      await controller.deleteNotifications([_id1]);
      await controller.flushPending();
      expect(controller.notifications.map((n) => n['id']), [_id2]);
      controller.unsubscribe();
    });

    test(
      'an opened item stays read during a failed write and after restart',
      () async {
        var serverRead = false;
        var failWrite = true;
        Future<http.Response> respond(http.Request request) async {
          if (request.method == 'GET') {
            return _json({
              'items': [_item(_id1, read: serverRead)],
              'next_cursor': null,
              'unread_count': serverRead ? 0 : 1,
            });
          }
          expect(jsonDecode(request.body), {
            'ids': [_id1],
          });
          if (failWrite) return _json({'error': 'INTERNAL_ERROR'}, 500);
          serverRead = true;
          return _json({'updated': 1});
        }

        final first = controllerFor(respond)..subscribe('user-1');
        await first.refresh(force: true);
        await first.markNotificationRead(_id1);
        expect(first.unreadCount, 0);
        await first.flushPending();
        expect(first.readSyncPending, isTrue);
        await first.refresh(force: true);
        expect(first.notifications.single['read'], isTrue);
        expect(first.unreadCount, 0);
        first.dispose();

        failWrite = false;
        final restarted = controllerFor(respond)..subscribe('user-1');
        addTearDown(restarted.dispose);
        await restarted.refresh(force: true);
        expect(restarted.notifications.single['read'], isTrue);
        expect(restarted.unreadCount, 0);
        await restarted.flushPending();
        expect(serverRead, isTrue);
        expect(restarted.readSyncPending, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('notifications.pendingRead.user-1'),
          isEmpty,
        );
      },
    );

    test(
      'a stale refresh cannot undo a read while the PATCH is in flight',
      () async {
        final started = Completer<void>();
        final release = Completer<void>();
        var serverRead = false;
        final controller = controllerFor((request) async {
          if (request.method == 'GET') {
            return _json({
              'items': [_item(_id1, read: serverRead)],
              'next_cursor': null,
              'unread_count': serverRead ? 0 : 1,
            });
          }
          started.complete();
          await release.future;
          serverRead = true;
          return _json({'updated': 1});
        })..subscribe('user-1');
        addTearDown(controller.dispose);
        await controller.refresh(force: true);
        await controller.markNotificationRead(_id1);
        final pending = controller.flushPending();
        await started.future;
        await controller.refresh(force: true);
        expect(controller.notifications.single['read'], isTrue);
        expect(controller.unreadCount, 0);
        release.complete();
        await pending;
        expect(controller.notifications.single['read'], isTrue);
      },
    );

    test('going to the background sends the pending batch at once', () async {
      var writes = 0;
      final controller = NotificationsController(
        apiService: serviceFor((request) async {
          if (request.method != 'GET') writes++;
          return _json({
            'items': [_item(_id1)],
            'next_cursor': null,
            'unread_count': 1,
          });
        }),
        requests: requests,
        writeDelay: const Duration(minutes: 5),
      );
      controller.subscribe('user-1');
      await controller.refresh(force: true);
      await controller.markNotificationRead(_id1);
      expect(writes, 0);

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(writes, 1);
      controller.unsubscribe();
    });

    test('reset forgets the account', () async {
      final controller = controllerFor(
        (_) async => _json({
          'items': [_item(_id1)],
          'next_cursor': 'more',
          'unread_count': 1,
        }),
      );
      controller.subscribe('user-1');
      await controller.refresh(force: true);
      expect(controller.hasMore, isTrue);

      controller.reset();

      expect(controller.notifications, isEmpty);
      expect(controller.hasMore, isFalse);
      expect(controller.unreadCount, 0);
    });
  });
}
