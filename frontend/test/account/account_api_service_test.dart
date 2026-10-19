import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/account/account_api_service.dart';
import 'package:frontend/services/account/support_ticket_service.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokens;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokens = TokenStorage(await SharedPreferences.getInstance());
    await tokens.saveTokens(accessToken: 'tok', refreshToken: 'ref');
  });

  AccountApiService serviceFor(
    Future<http.Response> Function(http.Request) h,
  ) => AccountApiService(
    apiClient: ApiClient(
      baseUrl: 'https://api.msmeschemes.org',
      httpClient: MockClient(h),
      tokenStorage: tokens,
    ),
  );

  group('delete account', () {
    test(
      'sends DELETE /v1/me with the bearer and no body or content type',
      () async {
        late http.Request seen;
        final service = serviceFor((r) async {
          seen = r;
          return http.Response('', 204);
        });

        await service.deleteAccount();

        expect(seen.method, 'DELETE');
        expect(seen.url.path, '/v1/me');
        expect(seen.url.query, isEmpty);
        expect(seen.body, isEmpty);
        expect(seen.headers['authorization'], 'Bearer tok');
        expect(seen.headers.containsKey('content-type'), isFalse);
      },
    );

    test('a refusal throws, so local data is never cleared', () async {
      final service = serviceFor(
        (_) async => _json({'error': 'REAUTHENTICATION_REQUIRED'}, 403),
      );

      await expectLater(
        service.deleteAccount(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'REAUTHENTICATION_REQUIRED',
          ),
        ),
      );
    });

    test('each refusal gets its own message', () {
      String message(String code) => AccountApiService.deletionRefusalMessage(
        ApiException(statusCode: 403, errorCode: code, message: ''),
      );

      expect(message('REAUTHENTICATION_REQUIRED'), contains('sign in again'));
      expect(message('ACCOUNT_DELETION_RATE_LIMITED'), contains('wait'));
      expect(message('ACCOUNT_DELETION_UNAVAILABLE'), contains('unavailable'));
      expect(
        AccountApiService.deletionRefusalMessage(StateError('offline')),
        contains('internet connection'),
      );
      for (final code in [
        'REAUTHENTICATION_REQUIRED',
        'ACCOUNT_DELETION_RATE_LIMITED',
        'ACCOUNT_DELETION_UNAVAILABLE',
      ]) {
        expect(message(code), contains('Nothing was changed'));
      }
    });
  });

  group('support tickets', () {
    final payload = {
      'category': 'General Inquiry',
      'contact_email': 'a@example.com',
      'description': 'Please help with this example issue.',
    };

    test(
      'a signed-in user sends the bearer and an Idempotency-Key, no guest header',
      () async {
        late http.Request seen;
        final service = serviceFor((r) async {
          seen = r;
          return _json({'id': 'x', 'status': 'open', 'created_at': 'now'}, 201);
        });

        await service.createSupportTicket(
          payload,
          idempotencyKey: 'key-1',
          signedIn: true,
        );

        expect(seen.url.path, '/v1/support-tickets');
        expect(seen.headers['authorization'], 'Bearer tok');
        expect(seen.headers['Idempotency-Key'], 'key-1');
        expect(seen.headers.containsKey('X-Support-Guest'), isFalse);
        expect(jsonDecode(seen.body), payload);
      },
    );

    test(
      'a guest gets a support session, and only the guest identity is sent',
      () async {
        final seen = <http.Request>[];
        final service = serviceFor((r) async {
          seen.add(r);
          if (r.url.path.endsWith('guest-session')) {
            return _json({
              'guest_token': 'guest-abc',
              'expires_at': DateTime.now()
                  .add(const Duration(hours: 24))
                  .toUtc()
                  .toIso8601String(),
            }, 201);
          }
          return _json({'id': 'x', 'status': 'open', 'created_at': 'now'}, 201);
        });

        await service.createSupportTicket(
          payload,
          idempotencyKey: 'key-2',
          signedIn: false,
        );
        await service.createSupportTicket(
          payload,
          idempotencyKey: 'key-3',
          signedIn: false,
        );

        final sessions = seen.where(
          (r) => r.url.path.endsWith('guest-session'),
        );
        expect(sessions.length, 1, reason: 'the guest token is reused');
        expect(jsonDecode(sessions.single.body), isEmpty);
        final tickets = seen.where((r) => r.url.path == '/v1/support-tickets');
        for (final ticket in tickets) {
          expect(ticket.headers['X-Support-Guest'], 'guest-abc');
          expect(ticket.headers.containsKey('authorization'), isFalse);
        }
      },
    );

    test('a rejected guest token is replaced once', () async {
      var sessions = 0;
      var rejected = false;
      final service = serviceFor((r) async {
        if (r.url.path.endsWith('guest-session')) {
          sessions++;
          return _json({
            'guest_token': 'guest-$sessions',
            'expires_at': DateTime.now()
                .add(const Duration(hours: 24))
                .toUtc()
                .toIso8601String(),
          }, 201);
        }
        if (!rejected) {
          rejected = true;
          return _json({'error': 'INVALID_SUPPORT_GUEST'}, 401);
        }
        return _json({'id': 'x', 'status': 'open', 'created_at': 'now'}, 201);
      });

      await service.createSupportTicket(
        payload,
        idempotencyKey: 'key-4',
        signedIn: false,
      );

      expect(sessions, 2);
    });
  });

  group('SupportTicketService', () {
    test(
      'only the four server categories are used; anything else is a prefixed General Inquiry',
      () {
        expect(SupportTicketService.apiCategories, {
          'General Inquiry',
          'Eligibility Matcher Bug',
          'Wrong Scheme Details',
          'Feature Request',
        });
      },
    );
  });
}
