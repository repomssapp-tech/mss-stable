import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/account/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Google OAuth returns through the package-specific app link', () {
    final redirect = Uri.parse(AuthService.googleRedirectUrl);

    expect(redirect.scheme, 'com.inschemes.app');
    expect(redirect.host, 'login-callback');
    expect(redirect.path, '/');
  });

  group('OAuth pending marker', () {
    test('absent by default', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AuthService.isOAuthPending(), isFalse);
    });

    test('a fresh marker reads as pending', () async {
      SharedPreferences.setMockInitialValues({
        'oauth_pending_since': DateTime.now().millisecondsSinceEpoch,
      });
      expect(await AuthService.isOAuthPending(), isTrue);
    });

    test('a marker older than the TTL is stale and gets cleared', () async {
      final old = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'oauth_pending_since': old});

      expect(await AuthService.isOAuthPending(), isFalse);
      // Side effect: the stale key is removed.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('oauth_pending_since'), isNull);
    });

    test('clearOAuthPending removes a live marker', () async {
      SharedPreferences.setMockInitialValues({
        'oauth_pending_since': DateTime.now().millisecondsSinceEpoch,
      });
      await AuthService.clearOAuthPending();
      expect(await AuthService.isOAuthPending(), isFalse);
    });
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
