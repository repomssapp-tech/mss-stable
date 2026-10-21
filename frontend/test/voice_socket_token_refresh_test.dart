import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'parallel voice socket starts share one rotating refresh token',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = TokenStorage(await SharedPreferences.getInstance());
      await storage.saveTokens(
        accessToken: 'old',
        refreshToken: 'one-use-refresh',
        expiresIn: -1,
      );
      final response = Completer<http.Response>();
      var refreshes = 0;
      final client = ApiClient(
        baseUrl: 'https://api.example.invalid/v1',
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v1/auth/refresh');
          refreshes++;
          return response.future;
        }),
      );
      final first = client.validAccessToken(),
          second = client.validAccessToken();
      await pumpEventQueue();
      expect(refreshes, 1);
      response.complete(
        http.Response(
          '{"access_token":"new","refresh_token":"rotated","expires_in":900}',
          200,
        ),
      );
      expect(await Future.wait([first, second]), ['new', 'new']);
      expect(await storage.getRefreshToken(), 'rotated');
    },
  );
}
