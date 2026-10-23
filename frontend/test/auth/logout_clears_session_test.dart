// After a logout nothing may bring the session back: not a delete that fails
// halfway, and not a token refresh that was already in flight when the user
// signed out (its rotated tokens used to be written back, so the app was still
// signed in after it was killed and reopened).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A secret store that can refuse to delete some keys.
class _FlakySecrets implements SecretStore {
  final Map<String, String> values = {};
  final Set<String> undeletable;
  _FlakySecrets({this.undeletable = const {}});

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async {
    if (undeletable.contains(key)) throw StateError('keystore error on $key');
    values.remove(key);
  }
}

Future<TokenStorage> _storage(_FlakySecrets secrets) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = TokenStorage(prefs, secrets);
  await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clear removes the session', () async {
    final storage = await _storage(_FlakySecrets());
    expect(await storage.hasSession(), isTrue);
    await storage.clear();
    expect(await storage.hasSession(), isFalse);
    expect(await storage.getRefreshToken(), isNull);
  });

  test('a delete that fails does not leave the session behind', () async {
    final secrets = _FlakySecrets(undeletable: {'mss_auth_access_token'});
    final storage = await _storage(secrets);
    await storage.clear();
    // The token could not be deleted, so it was blanked: no session on the
    // next start, and the refresh token (a different key) is gone too.
    expect(await storage.hasSession(), isFalse);
    expect(await storage.getRefreshToken(), isNull);
  });

  test('a refresh that finishes after sign-out saves nothing', () async {
    final storage = await _storage(_FlakySecrets());
    final refreshReply = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        return refreshReply.future;
      }
      return http.Response(jsonEncode({'error': 'UNAUTHENTICATED'}), 401);
    });
    final api = ApiClient(
      baseUrl: 'https://mssapi.msmeschemes.org/v1',
      httpClient: client,
      tokenStorage: storage,
    );

    // A request meets a 401 and starts a token refresh...
    final request = api.get('/me').then<Object?>((r) => r, onError: (e) => e);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // ...the user signs out while it is on its way...
    await storage.clear();

    // ...and the server's answer then arrives with rotated tokens.
    refreshReply.complete(
      http.Response(
        jsonEncode({
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'token_type': 'Bearer',
          'expires_in': 900,
        }),
        200,
      ),
    );
    await request;

    expect(await storage.hasSession(), isFalse);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
  });

  test(
    'a refresh with no sign-out in between still saves the new tokens',
    () async {
      final storage = await _storage(_FlakySecrets());
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'access_token': 'access-2',
              'refresh_token': 'refresh-2',
              'token_type': 'Bearer',
              'expires_in': 900,
            }),
            200,
          );
        }
        if (request.headers['Authorization'] == 'Bearer access-2') {
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        return http.Response(jsonEncode({'error': 'UNAUTHENTICATED'}), 401);
      });
      final api = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org/v1',
        httpClient: client,
        tokenStorage: storage,
      );
      await api.get('/me');
      expect(await storage.getAccessToken(), 'access-2');
      expect(await storage.getRefreshToken(), 'refresh-2');
    },
  );
}
