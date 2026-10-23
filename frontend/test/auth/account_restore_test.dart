import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/account/account_pending_deletion.dart';
import 'package:frontend/services/account/rest_auth_service.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:frontend/widgets/common/account_deletion_dialogs.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _restoreToken = 'rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _pendingDeletion() => _json({
  'error': 'ACCOUNT_PENDING_DELETION',
  'details': {
    'restore_token': _restoreToken,
    'expires_in': 600,
    'deleted_at': '2026-10-23T09:00:00.000Z',
    'purge_after': '2026-11-22T09:00:00.000Z',
  },
}, 403);

RestAuthService _service(Future<http.Response> Function(http.Request) h) =>
    RestAuthService(
      apiClient: ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org/v1',
        httpClient: MockClient(h),
      ),
    );

Widget _host(Widget Function(BuildContext) builder) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Builder(builder: builder)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('signing in to a deleted account', () {
    test(
      'Google exchange throws AccountPendingDeletion and saves no tokens',
      () async {
        await TokenStorage.instance.savePkceVerifier(
          'my_saved_verifier_123456789012345678901234567890',
        );
        final service = _service((_) async => _pendingDeletion());

        await expectLater(
          service.exchangeCode('one_time_app_code'),
          throwsA(
            isA<AccountPendingDeletion>()
                .having((e) => e.restoreToken, 'restoreToken', _restoreToken)
                .having(
                  (e) => e.purgeAfter,
                  'purgeAfter',
                  DateTime.utc(2026, 11, 22, 9).toLocal(),
                ),
          ),
        );
        expect(await TokenStorage.instance.getAccessToken(), isNull);
        expect(await TokenStorage.instance.readPkceVerifier(), isNull);
      },
    );

    test('password login throws AccountPendingDeletion', () async {
      final service = _service((_) async => _pendingDeletion());

      await expectLater(
        service.loginWithPassword(email: 'qa@example.com', password: 'x'),
        throwsA(isA<AccountPendingDeletion>()),
      );
    });

    test('other sign-in failures are unchanged', () async {
      final service = _service(
        (_) async => _json({'error': 'INVALID_CREDENTIALS'}, 401),
      );

      await expectLater(
        service.loginWithPassword(email: 'qa@example.com', password: 'x'),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'restoreAccount sends only the restore token and saves the session',
      () async {
        late Map<String, dynamic> sent;
        final service = _service((request) async {
          expect(request.url.path, '/v1/auth/restore');
          expect(request.headers.containsKey('authorization'), isFalse);
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({
            'access_token': 'restored_acc',
            'refresh_token': 'restored_ref',
            'token_type': 'Bearer',
            'expires_in': 900,
            'user': {'id': 'user_1', 'email': 'u@example.com', 'name': 'U'},
            'is_profile_complete': true,
            'missing_fields': <String>[],
          });
        });

        final user = await service.restoreAccount(_restoreToken);

        expect(sent, {'restore_token': _restoreToken});
        expect(user.id, 'user_1');
        expect(await TokenStorage.instance.getAccessToken(), 'restored_acc');
      },
    );

    test('fromError ignores other errors and a missing token', () {
      expect(
        AccountPendingDeletion.fromError(
          const ApiException(statusCode: 401, errorCode: 'X', message: ''),
        ),
        isNull,
      );
      expect(
        AccountPendingDeletion.fromError(
          const ApiException(
            statusCode: 403,
            errorCode: 'ACCOUNT_PENDING_DELETION',
            message: '',
            fields: {},
          ),
        ),
        isNull,
      );
    });
  });

  group('dialogs', () {
    final pending = AccountPendingDeletion(
      restoreToken: _restoreToken,
      purgeAfter: DateTime(2026, 11, 22),
    );

    testWidgets('restore prompt returns true on Reactivate', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async =>
                result = await confirmAccountRestore(context, pending),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Reactivate your account?'), findsOneWidget);
      expect(find.textContaining('Nov 22, 2026'), findsOneWidget);
      await tester.tap(find.text('Reactivate'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('restore prompt returns false on Not now', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async =>
                result = await confirmAccountRestore(context, pending),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('deleted dialog says data is kept for 30 days until the date', (
      tester,
    ) async {
      var closed = false;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async {
              await showAccountDeletedDialog(context, DateTime(2026, 11, 22));
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Account deleted'), findsOneWidget);
      expect(
        find.textContaining(
          'will not be deleted for 30 days (until Nov 22, 2026)',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });
  });
}
