import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/services/account/rest_auth_service.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RestAuthService', () {
    test('startGoogleLogin generates verifier and calls /auth/google/start', () async {
      String? capturedChallenge;
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/auth/google/start');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        capturedChallenge = body['code_challenge'];
        expect(body['redirect_uri'], 'com.inschemes.app://login-callback');

        return http.Response(
          jsonEncode({
            'authorization_url': 'https://accounts.google.com/o/oauth2/auth?test=1',
            'expires_in': 300,
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final authService = RestAuthService(apiClient: apiClient);

      final authUrl = await authService.startGoogleLogin();
      expect(authUrl, 'https://accounts.google.com/o/oauth2/auth?test=1');
      expect(capturedChallenge, isNotNull);

      // Verifier should be saved in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedVerifier = prefs.getString('mss_pkce_code_verifier');
      expect(savedVerifier, isNotNull);
      expect(savedVerifier!.length, 64);
    });

    test('exchangeCode sends code and original verifier then saves session', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mss_pkce_code_verifier', 'my_saved_verifier_123456789012345678901234567890');

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/auth/google/exchange');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['code'], 'one_time_app_code');
        expect(body['redirect_uri'], 'com.inschemes.app://login-callback');
        expect(body['code_verifier'], 'my_saved_verifier_123456789012345678901234567890');

        return http.Response(
          jsonEncode({
            'access_token': 'new_acc_token',
            'refresh_token': 'new_ref_token',
            'token_type': 'Bearer',
            'expires_in': 900,
            'user': {
              'id': 'user_uuid_100',
              'email': 'roger@example.com',
              'name': 'Roger Chris',
              'picture_url': 'https://example.com/pic.jpg',
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final authService = RestAuthService(apiClient: apiClient);

      final user = await authService.exchangeCode('one_time_app_code');
      expect(user.id, 'user_uuid_100');
      expect(user.email, 'roger@example.com');
      expect(user.name, 'Roger Chris');

      // Tokens must be in TokenStorage
      expect(await TokenStorage.instance.getAccessToken(), 'new_acc_token');
      expect(await TokenStorage.instance.getRefreshToken(), 'new_ref_token');
      expect(await TokenStorage.instance.getUserId(), 'user_uuid_100');

      // Temporary verifier must be cleaned up
      expect(prefs.getString('mss_pkce_code_verifier'), isNull);
    });

    test('loginWithPassword authenticates and persists tokens', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/auth/password/login');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'qa@example.com');
        expect(body['password'], 'secretpass123456');

        return http.Response(
          jsonEncode({
            'access_token': 'qa_acc_token',
            'refresh_token': 'qa_ref_token',
            'token_type': 'Bearer',
            'expires_in': 900,
            'user': {
              'id': 'qa_user_id',
              'email': 'qa@example.com',
              'name': 'QA Tester',
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final authService = RestAuthService(apiClient: apiClient);

      final user = await authService.loginWithPassword(
        email: 'qa@example.com',
        password: 'secretpass123456',
      );

      expect(user.id, 'qa_user_id');
      expect(await TokenStorage.instance.getAccessToken(), 'qa_acc_token');
    });

    test('getCurrentUser parses /v1/me and stores user', () async {
      await TokenStorage.instance.saveTokens(
        accessToken: 'valid_tok',
        refreshToken: 'valid_ref',
      );

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/me');
        return http.Response(
          jsonEncode({
            'user': {
              'id': 'server_u_id',
              'email': 'user@msme.in',
              'name': 'MSME User',
            }
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final authService = RestAuthService(apiClient: apiClient);

      final user = await authService.getCurrentUser();
      expect(user?.id, 'server_u_id');
      expect(user?.email, 'user@msme.in');
      expect(await TokenStorage.instance.getUserId(), 'server_u_id');
    });

    test('logout revokes session and clears TokenStorage', () async {
      await TokenStorage.instance.saveTokens(
        accessToken: 'tok_to_clear',
        refreshToken: 'ref_to_clear',
      );

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/auth/logout');
        return http.Response('', 204);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final authService = RestAuthService(apiClient: apiClient);

      await authService.logout();
      expect(await TokenStorage.instance.hasSession(), isFalse);
    });

    test('getSessions and deleteSession manage active sessions', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/v1/me/sessions') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'sess_1',
                  'authenticated_at': '2026-10-16T08:00:00.000Z',
                  'expires_at': '2026-11-15T08:00:00.000Z',
                  'current': true,
                },
                {
                  'id': 'sess_2',
                  'authenticated_at': '2026-10-15T08:00:00.000Z',
                  'expires_at': '2026-11-14T08:00:00.000Z',
                  'current': false,
                }
              ]
            }),
            200,
          );
        }

        if (request.method == 'DELETE' && request.url.path == '/v1/me/sessions/sess_2') {
          return http.Response('', 204);
        }

        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final authService = RestAuthService(apiClient: apiClient);

      final sessions = await authService.getSessions();
      expect(sessions.length, 2);
      expect(sessions[0].id, 'sess_1');
      expect(sessions[0].current, isTrue);

      await authService.deleteSession('sess_2');
    });
  });
}
