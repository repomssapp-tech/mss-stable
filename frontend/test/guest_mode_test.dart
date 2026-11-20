// Guest mode (DEV 1 task 1.5): routing, the persisted flag, the login entry
// and the "Sign in to use this" gate.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/account/onboarding_api_service.dart'
    show LegalConsentStore;
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/screens/profile/guest_profile_view.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/regular_mode/home/guest_state_schemes.dart';
import 'package:frontend/screens/regular_mode/home_screen.dart';
import 'package:frontend/screens/regular_mode/saved_schemes_screen.dart';
import 'package:frontend/screens/regular_mode/search/search_filter_strip.dart';
import 'package:frontend/screens/regular_mode/settings_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/services/account/session_cache_service.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';
import 'package:frontend/services/onboarding/home_tour_store.dart';
import 'package:frontend/services/onboarding/onboarding_store.dart';
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
    test('a guest goes straight home: no login, no profile onboarding', () {
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
        StartupDestination.home,
      );
    });

    test('a session wins over the guest flag', () {
      expect(
        resolveStartupDestination(
          hasSession: true,
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
      expect(
        tester.widget<ButtonStyleButton>(guest).onPressed,
        isNull,
      );
    });
  });

  group('login consent from guest mode', () {
    Future<OutlinedButton> googleButton(
      WidgetTester tester,
      AppProvider provider,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('login-continue-with-google')),
      );
    }

    testWidgets('a guest who agreed is not asked to agree again', (
      tester,
    ) async {
      final provider = AppProvider();
      await LegalConsentStore.markLoginAgreement();
      await provider.continueAsGuest();

      final google = await googleButton(tester, provider);

      expect(google.onPressed, isNotNull);
      expect(
        find.text(
          'Please review the Terms of Use and Privacy Policy before continuing.',
        ),
        findsNothing,
      );
    });

    testWidgets('a signed-out user must agree again', (tester) async {
      final provider = AppProvider();
      await LegalConsentStore.markLoginAgreement();

      final google = await googleButton(tester, provider);

      expect(google.onPressed, isNull);
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

  group('guest home: top schemes for the state', () {
    Scheme scheme(String id, {bool national = false, String added = ''}) =>
        Scheme(
          id: id,
          name: id,
          appliesNationally: national,
          stateCodes: national ? const [] : const ['IN-MH'],
          addedOn: added,
        );

    test('guestStateFor: entered state first, then the app language', () {
      expect(
        guestStateFor(profileState: 'Tamil Nadu', language: 'mr'),
        'Tamil Nadu',
      );
      expect(guestStateFor(profileState: '', language: 'mr'), 'Maharashtra');
      expect(guestStateFor(profileState: '', language: 'ta'), 'Tamil Nadu');
      expect(guestStateFor(profileState: '', language: 'en'), '');
    });

    test('state schemes first, newest first, national fills the row', () {
      final picks = pickGuestStateSchemes(
        all: [
          scheme('central-old', national: true, added: '2025-01-01'),
          scheme('mh-old', added: '2025-02-01'),
          scheme('mh-new', added: '2026-03-01'),
          scheme('central-new', national: true, added: '2026-01-01'),
        ],
        state: 'Maharashtra',
        limit: 3,
      );
      expect(picks.map((s) => s.id), ['mh-new', 'mh-old', 'central-new']);
    });

    test('no state: newest national schemes only', () {
      final picks = pickGuestStateSchemes(
        all: [
          scheme('mh', added: '2026-05-01'),
          scheme('central', national: true, added: '2026-01-01'),
        ],
        state: '',
      );
      expect(picks.map((s) => s.id), ['central']);
    });

    testWidgets('a guest sees "Top schemes in …", not "Recommended for you"', (
      tester,
    ) async {
      final provider = AppProvider()
        ..setAllSchemesForTesting([scheme('mh', added: '2026-05-01')]);
      await provider.continueAsGuest();
      await provider.updateProfile(
        provider.profile.copyWith(state: 'Maharashtra'),
      );

      await tester.pumpWidget(
        _host(
          provider,
          SingleChildScrollView(
            child: HomeRecommendedSection(provider: provider),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Top schemes in Maharashtra'), findsOneWidget);
      expect(find.text('Recommended for you'), findsNothing);
    });
  });

  group('guest Profile tab', () {
    testWidgets('shows Pending, 0% and Sign in instead of the profile', (
      tester,
    ) async {
      final provider = AppProvider();
      await provider.continueAsGuest();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GuestProfileView), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Profile incomplete'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('guest-profile-sign-in')),
        findsOneWidget,
      );
      expect(find.byType(ProfileUserInfoCard), findsNothing);
      expect(find.byType(ProfileLogoutCard), findsNothing);
    });

    testWidgets('a signed-in user keeps the normal profile', (tester) async {
      final provider = AppProvider()..setLoggedInForTesting(true);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GuestProfileView), findsNothing);
      expect(find.byType(ProfileUserInfoCard), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('a guest stays on home; it is not sent to login', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      await provider.continueAsGuest();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      // The completion card is shown at 0% for a guest.
      expect(find.text('Profile incomplete'), findsOneWidget);
    });

    testWidgets('signed out and not a guest: sent to login', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('guest surfaces without an account', () {
    Widget app(AppProvider provider, Widget home) =>
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        );

    testWidgets('Settings: Sign in, no logout or account rows', (tester) async {
      final provider = AppProvider();
      await provider.continueAsGuest();

      await tester.pumpWidget(app(provider, const SettingsScreen()));
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('settings-guest-sign-in'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.text('Logout', skipOffstage: false), findsNothing);
      expect(find.text('Delete account', skipOffstage: false), findsNothing);
      expect(find.text('Signed-in devices', skipOffstage: false), findsNothing);
      expect(
        find.text('Saarthi voice settings', skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('Settings: a signed-in user keeps Logout', (tester) async {
      final provider = AppProvider()..setLoggedInForTesting(true);

      await tester.pumpWidget(app(provider, const SettingsScreen()));
      await tester.pump();

      expect(find.text('Logout', skipOffstage: false), findsOneWidget);
      expect(find.text('Delete account', skipOffstage: false), findsOneWidget);
    });

    testWidgets('Search: no For me filter or best-match sort for a guest', (
      tester,
    ) async {
      Widget strip({required bool showForMe}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SearchFilterStrip(
            facetCount: 0,
            isForMeActive: false,
            sortBy: 'Relevance',
            onOpenFilterPanel: () {},
            onToggleForMe: () {},
            onSortChanged: (_) {},
            showForMe: showForMe,
          ),
        ),
      );

      await tester.pumpWidget(strip(showForMe: false));
      expect(find.text('For me'), findsNothing);

      await tester.pumpWidget(strip(showForMe: true));
      expect(find.text('For me'), findsOneWidget);
    });

    testWidgets('Saved: a guest is asked to sign in, not to discover', (
      tester,
    ) async {
      final provider = AppProvider();
      await provider.continueAsGuest();

      await tester.pumpWidget(
        app(provider, const Scaffold(body: SavedSchemesScreen())),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('saved-guest-sign-in')), findsOneWidget);
    });
  });

  group('first-time tours', () {
    test('sign-out keeps the onboarding pages seen', () async {
      await const OnboardingStore().markSeen();
      await SessionCacheService.instance.clearSession();
      expect(await const OnboardingStore().isSeen(), isTrue);
    });

    test('Saarthi tour has its own record, kept across sign-out', () async {
      const saarthi = HomeTourStore(tour: 'saarthi');
      const home = HomeTourStore();
      await saarthi.record(null, HomeTourOutcome.completed);

      expect(await home.isDone(null), isFalse);
      await SessionCacheService.instance.clearSession();
      expect(await saarthi.isDone(null), isTrue);
      expect(await saarthi.isDone('u9'), isTrue);
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
