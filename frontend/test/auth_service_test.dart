import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  test('Google OAuth returns through the package-specific app link', () {
    final redirect = Uri.parse(AuthService.googleRedirectUrl);

    expect(redirect.scheme, 'com.inschemes.app');
    expect(redirect.host, 'login-callback');
    expect(redirect.path, '/');
  });

  group('canReachAuthenticationService', () {
    test('returns true when the auth health endpoint responds', () async {
      final client = MockClient((request) async {
        return http.Response('ok', 200);
      });

      final reachable = await AuthService.canReachAuthenticationService(
        httpClient: client,
      );
      expect(reachable, isTrue);
    });

    test('returns false on a connection failure (offline)', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Failed host lookup');
      });

      final reachable = await AuthService.canReachAuthenticationService(
        httpClient: client,
      );
      expect(reachable, isFalse);
    });

    test('returns false on a timeout', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 10));
        return http.Response('ok', 200);
      });

      final reachable = await AuthService.canReachAuthenticationService(
        httpClient: client,
      );
      expect(reachable, isFalse);
    }, timeout: const Timeout(Duration(seconds: 8)));
  });
}
