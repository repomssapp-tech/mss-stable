import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/notifications/push_device_service.dart';
import 'package:frontend/services/notifications/sse_event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokenStorage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenStorage = TokenStorage(prefs);
    await tokenStorage.saveTokens(
      accessToken: 'test-push-bearer-123',
      refreshToken: 'test-push-refresh-123',
    );
  });

  group('PushDeviceService', () {
    test('getOrCreateDeviceId returns stable UUIDv4', () async {
      final service = PushDeviceService(prefs: prefs);
      final id1 = await service.getOrCreateDeviceId();
      final id2 = await service.getOrCreateDeviceId();

      expect(id1.isNotEmpty, true);
      expect(id1, id2);
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(id1), true);
    });

    test('registerDevice sends PUT /v1/me/push-devices/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path.startsWith('/v1/me/push-devices/'), true);
        expect(request.headers['authorization'], 'Bearer test-push-bearer-123');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'sample-fcm-device-token-12345');
        expect(body['platform'], 'android');

        return http.Response(
          jsonEncode({
            'id': 'device-uuid-1',
            'platform': 'android',
            'created_at': '2026-10-18T00:00:00.000Z',
            'updated_at': '2026-10-18T00:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = PushDeviceService(client: apiClient, prefs: prefs);
      final registered = await service.registerDevice(
        token: 'sample-fcm-device-token-12345',
        platform: 'android',
      );

      expect(registered.id, 'device-uuid-1');
      expect(registered.platform, 'android');
    });

    test('getRegisteredDevices decodes items list', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/me/push-devices');

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'device-1',
                'platform': 'android',
                'created_at': '2026-10-18T00:00:00.000Z',
                'updated_at': '2026-10-18T00:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = PushDeviceService(client: apiClient, prefs: prefs);
      final devices = await service.getRegisteredDevices();

      expect(devices.length, 1);
      expect(devices.first.id, 'device-1');
    });

    test('unregisterDevice sends DELETE /v1/me/push-devices/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/v1/me/push-devices/device-1');
        return http.Response('', 204);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final service = PushDeviceService(client: apiClient, prefs: prefs);
      await expectLater(service.unregisterDevice(deviceId: 'device-1'), completes);
    });
  });

  group('SseEventService', () {
    test('clearCursor removes persisted event cursor', () async {
      await prefs.setString('mss_sse_last_event_id', 'cursor-123');
      final sseService = SseEventService(tokenStorage: tokenStorage);

      await sseService.clearCursor();
      expect(prefs.getString('mss_sse_last_event_id'), null);
    });

    test('stopListening cleanly halts without error', () {
      final sseService = SseEventService(tokenStorage: tokenStorage);
      sseService.stopListening();
      expect(sseService.isActive, false);
    });
  });
}
