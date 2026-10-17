import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/controllers/notifications_controller.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/notifications/notifications_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('NotificationsApiService', () {
    test('getNotifications parses list response and maps to UI correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/me/notifications');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '20');
        expect(request.headers['authorization'], 'Bearer test-access-token');

        return http.Response(
          jsonEncode({
            'notifications': [
              {
                'id': 'notif-1',
                'user_id': 'user-123',
                'type': 'SCHEME_UPDATE',
                'title': 'New subsidy scheme added',
                'body': 'Tamil Nadu MSME capital subsidy 2026 is now open.',
                'data': {'scheme_id': 'tn-msme-cap-2026', 'tag': 'Capital Subsidy'},
                'is_read': false,
                'read_at': null,
                'created_at': '2026-10-15T10:00:00.000Z',
              },
            ],
            'total': 1,
            'unread_count': 1,
            'page': 1,
            'limit': 20,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final response = await service.getNotifications();

      expect(response.total, 1);
      expect(response.unreadCount, 1);
      expect(response.notifications.length, 1);

      final notif = response.notifications.first;
      expect(notif.id, 'notif-1');
      expect(notif.type, 'SCHEME_UPDATE');
      expect(notif.isRead, false);

      final uiMap = notif.toUiMap();
      expect(uiMap['id'], 'notif-1');
      expect(uiMap['category'], 'new_schemes');
      expect(uiMap['tag'], 'Capital Subsidy');
      expect(uiMap['isNew'], true);
    });

    test('updateNotificationStatus sends PATCH /v1/me/notifications/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/v1/me/notifications/notif-1');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['is_read'], true);

        return http.Response(
          jsonEncode({
            'id': 'notif-1',
            'user_id': 'user-123',
            'type': 'updates',
            'title': 'Updated',
            'body': 'Read confirmed',
            'is_read': true,
            'created_at': '2026-10-15T10:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final item = await service.updateNotificationStatus('notif-1', isRead: true);

      expect(item.id, 'notif-1');
      expect(item.isRead, true);
    });

    test('markManyAsRead sends PATCH /v1/me/notifications/read', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/v1/me/notifications/read');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['notification_ids'], ['id-1', 'id-2']);

        return http.Response(
          jsonEncode({'updated_count': 2}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final count = await service.markManyAsRead(['id-1', 'id-2']);

      expect(count, 2);
    });

    test('markAllAsRead sends POST /v1/me/notifications/read-all', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/me/notifications/read-all');

        return http.Response(
          jsonEncode({'updated_count': 5}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final count = await service.markAllAsRead();

      expect(count, 5);
    });

    test('deleteNotifications sends POST /v1/me/notifications/delete', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/me/notifications/delete');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['notification_ids'], ['del-1', 'del-2']);

        return http.Response(
          jsonEncode({'deleted_count': 2}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final count = await service.deleteNotifications(['del-1', 'del-2']);

      expect(count, 2);
    });

    test('getUnreadCount sends GET /v1/me/notifications/unread-count', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/me/notifications/unread-count');

        return http.Response(
          jsonEncode({'unread_count': 7}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final count = await service.getUnreadCount();

      expect(count, 7);
    });
  });

  group('NotificationsController', () {
    test('optimistically marks as read and deletes', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'updated_count': 1, 'deleted_count': 1}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = NotificationsApiService(client: apiClient);
      final controller = NotificationsController(apiService: service);

      expect(controller.notifications.isNotEmpty, true);
      final firstId = controller.notifications.first['id'].toString();

      await controller.markNotificationRead(firstId);
      expect(controller.notifications.first['read'], true);

      await controller.deleteNotifications([firstId]);
      expect(controller.notifications.any((n) => n['id'] == firstId), false);
    });
  });
}
