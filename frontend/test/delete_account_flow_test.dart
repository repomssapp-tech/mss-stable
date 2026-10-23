// Deleting the account: the service deletes it and then asks the server whether
// it is really gone, and the deleting screen walks through the steps, shows a
// refusal with a way forward, and opens the login screen when it is done.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/regular_mode/settings/delete_account_screen.dart';
import 'package:frontend/services/account/account_api_service.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server for [AccountApiService]: the DELETE answer and the answer to the
/// follow-up GET /v1/me.
AccountApiService _service({
  required http.Response Function() onDelete,
  required http.Response Function() onMe,
  List<String>? log,
}) {
  final backend = MockClient((request) async {
    log?.add('${request.method} ${request.url.path}');
    if (request.method == 'DELETE') return onDelete();
    return onMe();
  });
  return AccountApiService(
    apiClient: ApiClient(
      baseUrl: 'https://mssapi.msmeschemes.org/v1',
      httpClient: backend,
    ),
  );
}

http.Response _error(int status, String code) =>
    http.Response(jsonEncode({'error': code, 'message': code}), status);

class _FakeProvider extends AppProvider {
  _FakeProvider(this.outcomes);

  /// One outcome per call of [requestAccountDeletion].
  final List<AccountDeletionOutcome> outcomes;
  int requests = 0;
  int completed = 0;
  int loggedOut = 0;

  @override
  Future<AccountDeletionOutcome> requestAccountDeletion({
    VoidCallback? onVerifying,
  }) async {
    final outcome = outcomes[requests.clamp(0, outcomes.length - 1)];
    requests++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    onVerifying?.call();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return outcome;
  }

  @override
  Future<void> completeAccountDeletion() async {
    completed++;
  }

  @override
  Future<void> logout(BuildContext context) async {
    loggedOut++;
  }
}

Widget _app(_FakeProvider provider, {Locale locale = const Locale('en')}) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

AppLocalizations _l(String code) => lookupAppLocalizations(Locale(code));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AccountApiService.deleteAndVerify', () {
    test('deleted: the delete succeeds and the server no longer knows the '
        'account', () async {
      final log = <String>[];
      final service = _service(
        log: log,
        onDelete: () => http.Response('', 204),
        onMe: () => _error(401, 'UNAUTHENTICATED'),
      );
      expect(
        await service.deleteAndVerify(verifyDelay: Duration.zero),
        AccountDeletionOutcome.deleted,
      );
      expect(log.first, 'DELETE /v1/me');
      expect(log[1], 'GET /v1/me');
    });

    test('notVerified: the server still answers for the account', () async {
      final service = _service(
        onDelete: () => http.Response('', 204),
        onMe: () => http.Response(
          jsonEncode({
            'user': {'id': 'u'},
          }),
          200,
        ),
      );
      expect(
        await service.deleteAndVerify(verifyDelay: Duration.zero),
        AccountDeletionOutcome.notVerified,
      );
    });

    test('a 404 for the account also counts as gone', () async {
      final service = _service(
        onDelete: () => http.Response('', 204),
        onMe: () => _error(404, 'NOT_FOUND'),
      );
      expect(
        await service.deleteAndVerify(verifyDelay: Duration.zero),
        AccountDeletionOutcome.deleted,
      );
    });

    test('an unreadable check is retried, then trusts the 204', () async {
      var checks = 0;
      final service = _service(
        onDelete: () => http.Response('', 204),
        onMe: () {
          checks++;
          return _error(500, 'SERVER_ERROR');
        },
      );
      expect(
        await service.deleteAndVerify(verifyDelay: Duration.zero),
        AccountDeletionOutcome.deleted,
      );
      expect(checks, 3);
    });

    test('a session that is too old must sign in again', () async {
      var checked = false;
      final service = _service(
        onDelete: () => _error(403, 'REAUTHENTICATION_REQUIRED'),
        onMe: () {
          checked = true;
          return http.Response('', 200);
        },
      );
      expect(
        await service.deleteAndVerify(verifyDelay: Duration.zero),
        AccountDeletionOutcome.reauthRequired,
      );
      expect(checked, isFalse, reason: 'nothing was deleted, nothing to check');
    });

    test('rate limit, outage and a dead connection are told apart', () async {
      expect(
        await _service(
          onDelete: () => _error(429, 'ACCOUNT_DELETION_RATE_LIMITED'),
          onMe: () => http.Response('', 200),
        ).deleteAndVerify(),
        AccountDeletionOutcome.rateLimited,
      );
      expect(
        await _service(
          onDelete: () => _error(503, 'ACCOUNT_DELETION_UNAVAILABLE'),
          onMe: () => http.Response('', 200),
        ).deleteAndVerify(),
        AccountDeletionOutcome.unavailable,
      );
      final offline = AccountApiService(
        apiClient: ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org/v1',
          httpClient: MockClient((_) async => throw Exception('no network')),
        ),
      );
      expect(await offline.deleteAndVerify(), AccountDeletionOutcome.offline);
    });
  });

  group('DeleteAccountScreen', () {
    testWidgets('walks through the steps, then opens the login screen', (
      tester,
    ) async {
      AccountApiService.instance.lastPurgeAfter = DateTime(2026, 11, 22);
      addTearDown(() => AccountApiService.instance.lastPurgeAfter = null);
      final provider = _FakeProvider([AccountDeletionOutcome.deleted]);
      await tester.pumpWidget(_app(provider));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();

      final l = _l('en');
      expect(find.text(l.deleteAccountScreenTitle), findsOneWidget);
      expect(find.text(l.deleteAccountStepRemoving), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(l.deleteAccountStepVerifying), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(provider.completed, 1);
      expect(find.text(l.deleteAccountDone), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      // The data is kept for 30 days; the user acknowledges before leaving.
      expect(find.text(l.accountDeletedTitle), findsOneWidget);
      expect(find.textContaining('until Nov 22, 2026'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      await tester.tap(find.text(l.ok));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DeleteAccountScreen), findsNothing);
    });

    testWidgets('cannot be left while it runs', (tester) async {
      final provider = _FakeProvider([AccountDeletionOutcome.deleted]);
      await tester.pumpWidget(_app(provider));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('a refusal changes nothing, explains why and can be retried', (
      tester,
    ) async {
      final provider = _FakeProvider([
        AccountDeletionOutcome.offline,
        AccountDeletionOutcome.deleted,
      ]);
      await tester.pumpWidget(_app(provider));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      final l = _l('en');
      expect(find.text(l.deleteAccountFailedTitle), findsOneWidget);
      expect(find.text(l.deleteAccountErrOffline), findsOneWidget);
      expect(provider.completed, 0);

      await tester.tap(find.text(l.deleteAccountRetry));
      await tester.pump();
      expect(find.text(l.deleteAccountScreenTitle), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(provider.requests, 2);
      expect(provider.completed, 1);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.ok));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Back to settings leaves after a refusal', (tester) async {
      final provider = _FakeProvider([AccountDeletionOutcome.rateLimited]);
      await tester.pumpWidget(_app(provider));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      final l = _l('en');
      expect(find.text(l.deleteAccountErrRateLimited), findsOneWidget);
      await tester.tap(find.text(l.deleteAccountBack));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('an old session is offered a sign out to sign in again', (
      tester,
    ) async {
      final provider = _FakeProvider([AccountDeletionOutcome.reauthRequired]);
      await tester.pumpWidget(_app(provider));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      final l = _l('en');
      expect(find.text(l.deleteAccountErrReauth), findsOneWidget);
      expect(find.text(l.deleteAccountRetry), findsNothing);
      await tester.tap(find.text(l.deleteAccountSignOutAgain));
      await tester.pump();
      expect(provider.loggedOut, 1);
    });

    for (final code in ['en', 'hi', 'ta']) {
      testWidgets('shows its text in the app language ($code)', (tester) async {
        final provider = _FakeProvider([AccountDeletionOutcome.notVerified]);
        await tester.pumpWidget(_app(provider, locale: Locale(code)));
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump();
        final l = _l(code);
        expect(find.text(l.deleteAccountScreenTitle), findsOneWidget);
        expect(find.text(l.deleteAccountStepVerifying), findsOneWidget);
        expect(find.text(l.deleteAccountKeepOpen), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump();
        expect(find.text(l.deleteAccountFailedTitle), findsOneWidget);
        expect(find.text(l.deleteAccountErrNotVerified), findsOneWidget);
        expect(find.text(l.deleteAccountRetry), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
