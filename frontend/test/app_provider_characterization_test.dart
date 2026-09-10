// Characterization tests for AppProvider — they pin the *observable* behaviour
// of the tangled auth / session / language / lifecycle paths BEFORE C1.4 splits
// the provider into controllers behind a facade (see docs/audit/FRONTEND_REFACTOR.md).
//
// These assert what the code does today, not what it ideally should do. If a
// later commit changes one of these behaviours on purpose, update the
// expectation in that same commit.
//
// Coverage map (tracker C1.4 prereq 2):
//   - logout()                              -> full local reset + cache wipe + nav
//   - deleteAccount() (no server session)   -> same reset when there is no
//                                              delete_user RPC target
//   - changeLanguage()                      -> state + cache + stale-echo guard
//   - didChangeAppLifecycleState(resumed)   -> one catalog sync; other states none
//   - _reconcileServerLanguage in isolation -> also covered by
//                                              l10n_language_reconcile_batch6_test.dart
//
// NOT covered here (needs a mock Supabase auth stream / RPC, out of scope for a
// pure unit test): the signed-in hydration branch of _setupAuthListener, and the
// deleteAccount branch where a live delete_user RPC throws and local state must
// be *preserved*. Those want an integration-style fake client.
//
// Harness notes:
//  - The provider methods do real I/O (SchemeRepository HTTP, Supabase
//    sign-out). Plain `test()` runs in the real async zone so those awaits
//    resolve; `testWidgets` fake-async would deadlock on their timers. The two
//    cases that need a Navigator use `tester.runAsync()`.
//  - The constructor kicks off `_loadState()`, which (re)reads _selectedLanguage
//    from the cache. Every test waits for that to finish — signalled by the
//    injected sync service being called at the tail of _loadState — before it
//    mutates provider state, otherwise _loadState clobbers the mutation.
//  - Providers are deliberately not disposed: the Supabase auth stream emits its
//    first event asynchronously and calls notifyListeners(); disposing races it
//    (same choice as l10n_language_reconcile_batch6_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/account/session_cache_service.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Counts syncIfNeeded() calls and hands back a caller-chosen result so the
/// lifecycle hook can be observed without touching the network or the bundle.
/// A call also marks that the constructor's _loadState() has reached its tail.
class _RecordingSyncService extends SchemeCatalogSyncService {
  int calls = 0;
  CatalogSyncResult result =
      const CatalogSyncResult(CatalogSyncOutcome.unchanged);

  @override
  Future<CatalogSyncResult> syncIfNeeded({bool force = false}) async {
    calls++;
    return result;
  }
}

/// Spins the real event loop until [predicate] holds or [timeout] elapses.
Future<void> _until(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void _expectSignedOutDefaults(AppProvider p) {
  expect(p.isLoggedIn, isFalse);
  expect(p.isLoggingOut, isFalse);
  expect(p.mobileNumber, isEmpty);
  expect(p.selectedLanguage, 'en');
  expect(p.navigationMode, 'regular');
  expect(p.profile.name, isEmpty);
  expect(p.profile.profileCompleted, isFalse);
  expect(p.currentTabIndex, 0);
  expect(p.hasTabHistory, isFalse);
  expect(p.bookmarkedIds, isEmpty);
  expect(p.recentlyViewedIds, isEmpty);
  expect(p.savedEligibilitySchemeIds, isEmpty);
  expect(p.hasSavedEligibilityResults, isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('changeLanguage() updates state, persists, and guards the stale echo',
      () async {
    final sync = _RecordingSyncService();
    final provider = AppProvider(catalogSyncService: sync);
    await _until(() => sync.calls > 0); // let _loadState() settle

    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.changeLanguage('ta');

    expect(provider.selectedLanguage, 'ta');
    expect(provider.profile.language, 'ta');
    expect(await SessionCacheService.instance.getLanguage(), 'ta');
    expect(notifications, greaterThan(0));

    // A realtime echo / profile row still carrying the pre-switch language is
    // ignored while the guard window is open...
    expect(provider.debugReconcileServerLanguage('en'), 'ta');
    // ...until the server confirms the new value, which clears the marker...
    expect(provider.debugReconcileServerLanguage('ta'), 'ta');
    // ...after which later server-driven changes are trusted again.
    expect(provider.debugReconcileServerLanguage('en'), 'en');
  });

  test(
      'didChangeAppLifecycleState: resumed triggers a catalog sync, '
      'other states do not', () async {
    final sync = _RecordingSyncService();
    final provider = AppProvider(catalogSyncService: sync);

    // The constructor's _loadState() also kicks a sync. Wait for it to land,
    // then zero the counter so the assertions only see lifecycle-driven calls.
    await _until(() => sync.calls > 0);
    sync.calls = 0;

    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _until(() => sync.calls >= 1);
    expect(sync.calls, 1);

    provider.didChangeAppLifecycleState(AppLifecycleState.inactive);
    provider.didChangeAppLifecycleState(AppLifecycleState.paused);
    provider.didChangeAppLifecycleState(AppLifecycleState.detached);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(sync.calls, 1, reason: 'only the resumed transition syncs');

    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _until(() => sync.calls >= 2);
    expect(sync.calls, 2);
  });

  testWidgets('logout() resets every session field and wipes the cache',
      (tester) async {
    final sync = _RecordingSyncService();
    final provider = AppProvider(catalogSyncService: sync);

    late BuildContext hostContext;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              hostContext = c;
              return const Scaffold();
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await _until(() => sync.calls > 0); // let _loadState() settle

      await provider.changeNavigationMode('companion');
      await provider.updateProfile(
        UserProfile(
          name: 'Test User',
          email: 't@example.com',
          profileCompleted: true,
        ),
      );
      provider.toggleBookmark('scheme-1');
      await provider.saveEligibilityResults(['scheme-1', 'scheme-2']);
      provider.updateTabIndex(3);
      provider.setLoggedInForTesting(true);
      await provider.changeLanguage('ta');
    });

    expect(provider.selectedLanguage, 'ta');
    expect(provider.isLoggedIn, isTrue);
    expect(provider.bookmarkedIds, isNotEmpty);
    expect(provider.savedEligibilitySchemeIds, isNotEmpty);

    await tester.runAsync(() => provider.logout(hostContext));
    await tester.pump();

    _expectSignedOutDefaults(provider);
    expect(
      await SessionCacheService.instance.getLanguage(),
      anyOf(isNull, 'en'),
    );
    expect(await SessionCacheService.instance.loadProfile(), isNull);

    // Drop the pushed SplashScreen before its 3.2s timer / 1.6s animation
    // can outlive the test.
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'deleteAccount() with no server session skips the RPC and still '
      'resets local state', (tester) async {
    final sync = _RecordingSyncService();
    final provider = AppProvider(catalogSyncService: sync);

    late BuildContext hostContext;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              hostContext = c;
              return const Scaffold();
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await _until(() => sync.calls > 0); // let _loadState() settle

      await provider.changeNavigationMode('companion');
      provider.toggleBookmark('x');
      provider.updateTabIndex(2);
      // _isLoggedIn is true but a stub Supabase has no currentUser, so
      // delete_user is never called and cleanup proceeds.
      provider.setLoggedInForTesting(true);
    });

    expect(provider.isLoggedIn, isTrue);
    expect(provider.bookmarkedIds, isNotEmpty);

    await tester.runAsync(() => provider.deleteAccount(hostContext));
    await tester.pump();

    _expectSignedOutDefaults(provider);
    expect(await SessionCacheService.instance.loadProfile(), isNull);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
