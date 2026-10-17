import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenStorage', () {
    test('saves and retrieves tokens and user profile', () async {
      final storage = TokenStorage.instance;
      await storage.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_123',
        expiresIn: 900,
      );

      expect(await storage.getAccessToken(), 'access_123');
      expect(await storage.getRefreshToken(), 'refresh_123');
      expect(await storage.hasSession(), isTrue);
      expect(await storage.isAccessTokenExpired(), isFalse);

      await storage.saveUser(
        id: 'user_uuid_1',
        email: 'tester@example.com',
        name: 'Tester User',
      );

      expect(await storage.getUserId(), 'user_uuid_1');
      expect(await storage.getUserEmail(), 'tester@example.com');
      expect(await storage.getUserName(), 'Tester User');

      await storage.clear();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserId(), isNull);
      expect(await storage.hasSession(), isFalse);
    });
  });

  group('ApiClient', () {
    test('sends GET with Authorization header when authenticated', () async {
      await TokenStorage.instance.saveTokens(
        accessToken: 'valid_token',
        refreshToken: 'valid_refresh',
      );

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/me');
        expect(request.headers['Authorization'], 'Bearer valid_token');
        expect(request.headers['Accept'], 'application/json');

        return http.Response(
          jsonEncode({
            'user': {'id': 'user_1', 'email': 'a@b.com'}
          }),
          200,
          headers: {'content-type': 'application/json', 'etag': '"prof-1"'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );

      final response = await client.get('/me');
      expect(response.statusCode, 200);
      expect(response.etag, '"prof-1"');
      expect(response.data['user']['id'], 'user_1');
    });

    test('handles 204 No Content gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 204);
      });

      final client = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );

      final response = await client.post('/auth/logout');
      expect(response.statusCode, 204);
      expect(response.data, isNull);
    });

    test('single-flight refresh on 401 retries original request', () async {
      await TokenStorage.instance.saveTokens(
        accessToken: 'stale_token',
        refreshToken: 'valid_refresh',
      );

      int protectedCallCount = 0;
      int refreshCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/v1/auth/refresh') {
          refreshCallCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refresh_token'], 'valid_refresh');
          return http.Response(
            jsonEncode({
              'access_token': 'new_token',
              'refresh_token': 'new_refresh',
              'expires_in': 900,
            }),
            200,
          );
        }

        if (request.url.path == '/v1/me/profile') {
          protectedCallCount++;
          if (request.headers['Authorization'] == 'Bearer stale_token') {
            return http.Response(jsonEncode({'error': 'UNAUTHORIZED'}), 401);
          }
          if (request.headers['Authorization'] == 'Bearer new_token') {
            return http.Response(
              jsonEncode({'id': 'u1', 'name': 'Refreshed User'}),
              200,
              headers: {'etag': '"profile-2"'},
            );
          }
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );

      // Fire 2 concurrent requests to verify single-flight refresh mutex
      final results = await Future.wait([
        client.get('/me/profile'),
        client.get('/me/profile'),
      ]);

      expect(refreshCallCount, 1, reason: 'Only one refresh flight must occur');
      expect(protectedCallCount, 4, reason: '2 initial 401s + 2 retried calls');
      expect(results[0].statusCode, 200);
      expect(results[1].statusCode, 200);
      expect(await TokenStorage.instance.getAccessToken(), 'new_token');
    });

    test('refresh failure triggers onSessionExpired and clears tokens', () async {
      await TokenStorage.instance.saveTokens(
        accessToken: 'bad_token',
        refreshToken: 'dead_refresh',
      );

      bool sessionExpiredCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/v1/auth/refresh') {
          return http.Response(jsonEncode({'error': 'INVALID_REFRESH_TOKEN'}), 401);
        }
        return http.Response(jsonEncode({'error': 'UNAUTHORIZED'}), 401);
      });

      final client = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
        onSessionExpired: () => sessionExpiredCalled = true,
      );

      expect(
        () => client.get('/me/profile'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      await Future.delayed(Duration.zero);
      expect(sessionExpiredCalled, isTrue);
      expect(await TokenStorage.instance.getAccessToken(), isNull);
    });

    test('decodes structured error fields and 429 Retry-After', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'PROFILE_VERSION_CONFLICT',
            'message': 'Stale ETag version',
            'details': [{'field': 'version', 'current': 3}],
          }),
          412,
          headers: {'retry-after': '5', 'x-request-id': 'req_abc'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );

      try {
        await client.patch('/me/profile', body: {'name': 'Test'});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 412);
        expect(e.errorCode, 'PROFILE_VERSION_CONFLICT');
        expect(e.isStaleVersion, isTrue);
        expect(e.retryAfterSeconds, 5);
        expect(e.requestId, 'req_abc');
        expect(e.details, isNotEmpty);
      }
    });

    test('getBytes streams binary data and checks size', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          Uint8List.fromList([1, 2, 3, 4, 5]),
          200,
          headers: {'content-type': 'application/gzip', 'etag': '"hash"'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );

      final response = await client.getBytes('/catalog/releases/1.0.0/bundle');
      expect(response.statusCode, 200);
      expect(response.data.length, 5);
      expect(response.etag, '"hash"');

      // Test size cap violation
      expect(
        () => client.getBytes('/catalog/releases/1.0.0/bundle', maxByteSize: 3),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 413)),
      );
    });
  });
}
