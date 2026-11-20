// Guest mode (DEV 1 task 1.5): routing, the persisted flag, the login entry
// and the "Sign in to use this" gate.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/regular_mode/home/home_header_section.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/services/account/session_cache_service.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';
import 'package:frontend/widgets/common/sign_in_required_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Marks that the constructor's _loadState() reached its tail.
class _RecordingSyncService extends SchemeCatalogSyncService {
  int calls = 0;

  @override
  Future<CatalogSyncResult> syncIfNeeded({bool force = false}) async {
    calls++;
    return const CatalogSyncResult(CatalogSyncOutcome.unchanged);
  }
}

Future<void> _until(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Widget _host(AppProvider provider, Widget child) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('resolveStartupDestination', () {
    test('a guest is routed like a signed-in user, never to login', () {
      expect(
        resolveStartupDestination(
          hasSession: false,
          hasCachedLanguage: true,
          profileCompleted: true,
          isGuest: true,
        ),
        StartupDestination.home,
      );
      expect(
        resolveStartupDestination(
          hasSession: false,
          hasCachedLanguage: true,
          profileCompleted: false,
          isGuest: true,
        ),
        StartupDestination.navigationMode,
      );
    });

    test('without the flag, signed-out routing is unchanged', () {
      expect(
        resolveStartupDestination(
          hasSession: false,
          hasCachedLanguage: true,
          profileCompleted: true,
        ),
        StartupDestination.login,
      );
    });
  });

  group('AppProvider guest flag', () {
    test('continueAsGuest sets and persists the flag', () async {
      final sync = _RecordingSyncService();
      final provider = AppProvider(catalogSyncService: sync);
      await _until(() => sync.calls > 0);
      expect(provider.isGuest, isFalse);

      await provider.continueAsGuest();

      expect(provider.isGuest, isTrue);
      expect(await SessionCacheService.instance.getIsGuest(), isTrue);
    });

    test('a stored flag survives an app restart (kill and reopen)', () async {
      SharedPreferences.setMockInitialValues({'isGuest': true});
      final sync = _RecordingSyncService();
      final provider = AppProvider(catalogSyncService: sync);
      await _until(() => sync.calls > 0);

      expect(provider.isGuest, isTrue);
    });

    test('a signed-in user is never a guest', () async {
      final sync = _RecordingSyncService();
      final provider = AppProvider(catalogSyncService: sync);
      await _until(() => sync.calls > 0);
      await provider.continueAsGuest();

      provider.setLoggedInForTesting(true);

      expect(provider.isGuest, isFalse);
    });

    test('continueAsGuest is ignored while signed in', () async {
      final sync = _RecordingSyncService();
      final provider = AppProvider(catalogSyncService: sync);
      await _until(() => sync.calls > 0);
      provider.setLoggedInForTesting(true);

      await provider.continueAsGuest();

      expect(await SessionCacheService.instance.getIsGuest(), isFalse);
    });

    test('the upload marker is kept apart from the guest flag', () async {
      final cache = SessionCacheService.instance;
      await cache.saveGuestUploadPending(true);
      expect(await cache.getGuestUploadPending(), isTrue);
      expect(await cache.getIsGuest(), isFalse);

      await cache.saveGuestUploadPending(false);
      expect(await cache.getGuestUploadPending(), isFalse);
    });

    test('clearSession (sign-out) leaves no stale guest flag', () async {
      final cache = SessionCacheService.instance;
      await cache.saveIsGuest(true);
      await cache.saveGuestUploadPending(true);

      await cache.clearSession();

      expect(await cache.getIsGuest(), isFalse);
      expect(await cache.getGuestUploadPending(), isFalse);
    });
  });

  group('login screen', () {
    testWidgets('Continue as guest waits for Terms and Privacy', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      final guest = find.byKey(const ValueKey('login-continue-as-guest'));
      expect(guest, findsOneWidget);
      expect(find.text('Continue as guest'), findsOneWidget);
      expect(tester.widget<TextButton>(guest).onPressed, isNull);
    });
  });

  group('requireAccount', () {
    /// Taps a button that calls [requireAccount]; the returned getter reads
    /// its result once the gate has finished.
    Future<bool? Function()> tapGate(
      WidgetTester tester,
      AppProvider provider,
    ) async {
      bool? allowed;
      await tester.pumpWidget(
        _host(
          provider,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => allowed = await requireAccount(context),
              child: const Text('save'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();
      return () => allowed;
    }

    testWidgets('a guest sees the sign-in sheet and the action is blocked', (
      tester,
    ) async {
      final provider = AppProvider();
      await provider.continueAsGuest();

      final result = await tapGate(tester, provider);

      expect(find.text('Sign in to use this'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(result(), isFalse);
      expect(find.text('Sign in to use this'), findsNothing);
    });

    testWidgets('a signed-in user goes straight through', (tester) async {
      final provider = AppProvider()..setLoggedInForTesting(true);

      final result = await tapGate(tester, provider);

      expect(result(), isTrue);
      expect(find.text('Sign in to use this'), findsNothing);
    });
  });

  group('HomeHeaderSection', () {
    for (final guest in [true, false]) {
      testWidgets('renders the greeting for isGuest=$guest', (tester) async {
        final provider = AppProvider();
        if (guest) {
          await provider.continueAsGuest();
        } else {
          provider.setLoggedInForTesting(true);
        }
        await tester.pumpWidget(
          _host(
            provider,
            SingleChildScrollView(
              child: HomeHeaderSection(
                provider: provider,
                onNotificationTap: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(provider.isGuest, guest);
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      });
    }
  });
}
