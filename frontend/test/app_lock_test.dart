import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/security/app_lock_service.dart';
import 'package:frontend/utils/app_languages.dart';
import 'package:frontend/widgets/common/app_lock_gate.dart';

class _MemoryStore implements SecretStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// A status endpoint whose answer the test changes.
class _Server {
  int status = 200;
  Map<String, Object?> body = {'locked': false, 'message': null};
  bool reachable = true;
  int calls = 0;

  MockClient get client => MockClient((request) async {
    calls++;
    if (!reachable) throw http.ClientException('offline');
    expect(request.url.path, '/v1/app/status');
    expect(request.headers.containsKey('Authorization'), isFalse);
    return http.Response(jsonEncode(body), status);
  });
}

AppLockService _service(_Server server, _MemoryStore store) => AppLockService(
  store: store,
  client: server.client,
  statusUrl: 'https://api.example.invalid/v1/app/status',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockService', () {
    test('follows the server and remembers a lock across restarts', () async {
      final server = _Server(), store = _MemoryStore();
      final lock = _service(server, store);
      await lock.check();
      expect(lock.isLocked, isFalse);

      server.body = {'locked': true, 'message': 'Back on Monday'};
      await lock.check();
      expect(
        lock.value,
        const AppLockState(locked: true, message: 'Back on Monday'),
      );

      // A restart with no network stays locked.
      server.reachable = false;
      final restarted = _service(server, store);
      await restarted.hydrate();
      await restarted.check();
      expect(restarted.value.locked, isTrue);
      expect(restarted.value.message, 'Back on Monday');

      // Only the server saying "unlocked" opens it again.
      server
        ..reachable = true
        ..body = {'locked': false, 'message': null};
      await restarted.check();
      expect(restarted.isLocked, isFalse);
      expect(store.values, isEmpty);
    });

    test(
      'a 423 from any request locks at once and keeps the message',
      () async {
        final server = _Server(), store = _MemoryStore();
        final lock = _service(server, store);
        lock.reportLocked(message: 'Maintenance');
        expect(lock.isLocked, isTrue);
        lock.reportLocked();
        expect(lock.value.message, 'Maintenance');

        server
          ..status = 423
          ..body = {
            'error': 'APP_LOCKED',
            'details': {'message': 'Audit in progress'},
          };
        await lock.check();
        expect(lock.value.message, 'Audit in progress');
      },
    );

    test('a garbled answer never unlocks', () async {
      final server = _Server(), store = _MemoryStore();
      final lock = _service(server, store)..reportLocked();
      server.body = {'locked': 'no'};
      await lock.check();
      expect(lock.isLocked, isTrue);
      server.status = 500;
      await lock.check();
      expect(lock.isLocked, isTrue);
    });

    test('recognises only the server lock answer', () {
      expect(AppLockService.isLockResponse(423, 'APP_LOCKED'), isTrue);
      expect(AppLockService.isLockResponse(423, null), isTrue);
      expect(AppLockService.isLockResponse(423, 'OTHER'), isFalse);
      expect(AppLockService.isLockResponse(403, 'APP_LOCKED'), isFalse);
    });
  });

  testWidgets('while locked only the locked screen is built', (tester) async {
    final server = _Server()..body = {'locked': true, 'message': 'Call 1800'};
    final lock = _service(server, _MemoryStore());
    var appBuilt = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppLockGate(service: lock, child: child!),
        home: Builder(
          builder: (_) {
            appBuilt++;
            return const Text('APP HOME');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.appLockedTitle), findsOneWidget);
    expect(find.text('Call 1800'), findsOneWidget);
    // Not hidden behind a cover: the app is not in the tree at all.
    expect(find.text('APP HOME'), findsNothing);

    server.body = {'locked': false, 'message': null};
    await tester.tap(find.text(l10n.appLockedCheckAgain));
    await tester.pumpAndSettle();
    expect(find.text('APP HOME'), findsOneWidget);
    expect(appBuilt, greaterThan(0));
  });

  testWidgets('the locked screen is translated into Tamil, Hindi and Marathi', (
    tester,
  ) async {
    for (final code in ['ta', 'hi', 'mr']) {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.appLockedTitle, isNot(en.appLockedTitle), reason: code);
      expect(l10n.appLockedBody, isNot(en.appLockedBody), reason: code);
    }
  });

  test('the app is offered in English, Tamil, Hindi and Marathi only', () {
    expect(appLanguages, ['en', 'ta', 'hi', 'mr']);
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      {'en', 'ta', 'hi', 'mr'},
    );
    expect(appLanguageOrEnglish('mr-IN'), 'mr');
    expect(appLanguageOrEnglish('bn'), 'en');
    expect(appLanguageOrEnglish('hi-IN'), 'hi');
  });

  test('a locked refresh keeps the session and reports the lock', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStorage(await SharedPreferences.getInstance());
    await tokens.saveTokens(accessToken: 'old', refreshToken: 'ref');
    final previous = AppLockService.instance;
    AppLockService.instance = AppLockService(
      store: _MemoryStore(),
      client: MockClient((_) async => http.Response('{}', 500)),
    );
    var expired = false;
    final locked = jsonEncode({
      'error': 'APP_LOCKED',
      'details': {'message': 'Locked for audit'},
    });
    final client = ApiClient(
      baseUrl: 'https://api.example.invalid/v1',
      tokenStorage: tokens,
      onSessionExpired: () => expired = true,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(locked, 423);
        }
        return http.Response('{"error":"UNAUTHORIZED"}', 401);
      }),
    );
    try {
      await expectLater(
        client.get('/me/profile'),
        throwsA(
          isA<ApiException>().having((e) => e.isAppLocked, 'locked', isTrue),
        ),
      );
      expect(expired, isFalse);
      expect(await tokens.getRefreshToken(), 'ref');
      expect(AppLockService.instance.isLocked, isTrue);
      expect(AppLockService.instance.value.message, 'Locked for audit');

      // Any request answered 423 locks the app too.
      AppLockService.instance.debugSet(AppLockState.unlocked);
      final direct = ApiClient(
        baseUrl: 'https://api.example.invalid/v1',
        tokenStorage: tokens,
        httpClient: MockClient((_) async => http.Response(locked, 423)),
      );
      await expectLater(direct.get('/schemes'), throwsA(isA<ApiException>()));
      expect(AppLockService.instance.isLocked, isTrue);
    } finally {
      AppLockService.instance = previous;
    }
  });
}
