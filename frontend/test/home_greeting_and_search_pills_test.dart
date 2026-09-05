import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/home_screen.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('Time-of-day greeting tests', () {
    test('AppConstants.getTimeGreeting returns expected strings across day brackets', () {
      final greetingEn = AppConstants.getTimeGreeting(isTa: false, withComma: true);
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        expect(greetingEn, equals('Good Morning,'));
      } else if (hour >= 12 && hour < 17) {
        expect(greetingEn, equals('Good Afternoon,'));
      } else {
        expect(greetingEn, equals('Good Evening,'));
      }

      final greetingTa = AppConstants.getTimeGreeting(isTa: true, withComma: true);
      if (hour >= 5 && hour < 12) {
        expect(greetingTa, equals('காலை வணக்கம்,'));
      } else if (hour >= 12 && hour < 17) {
        expect(greetingTa, equals('மதிய வணக்கம்,'));
      } else {
        expect(greetingTa, equals('மாலை வணக்கம்,'));
      }
    });

    test('AppConstants.getTimeGreeting without comma works correctly', () {
      final greeting = AppConstants.getTimeGreeting(isTa: false, withComma: false);
      expect(greeting.endsWith(','), isFalse);
      expect(
        greeting == 'Good Morning' || greeting == 'Good Afternoon' || greeting == 'Good Evening',
        isTrue,
      );
    });
  });

  group('HomeScreen search pills visibility tests', () {
    testWidgets(
        'Quick search pills are visible immediately, and tapping the search '
        'bar fires onSearchBarTap exactly once (no dead two-tap reveal step)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      provider.setLoggedInForTesting(true);
      var searchBarTapCount = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HomeScreen(
                onSearchBarTap: () => searchBarTapCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick pills are always visible now -- no reveal gesture needed.
      expect(find.text('Search PMEGP'), findsOneWidget);
      expect(find.text('Search Startup India'), findsOneWidget);

      // Verify dynamic time-of-day greeting is present
      final currentGreeting = AppConstants.getTimeGreeting(
        isTa: false,
        withComma: true,
      );
      expect(find.text(currentGreeting), findsOneWidget);

      // Search bar placeholder should be visible
      final searchField = find.textContaining('Search schemes');
      expect(searchField, findsOneWidget);

      // A single tap on the search bar must fire onSearchBarTap exactly
      // once -- previously this required a second tap, and even then only
      // switched tabs without ever focusing a real TextField.
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      expect(searchBarTapCount, 1);

      // Pills remain visible; there is no close button anymore (the old
      // "tap again to dismiss pills" state no longer exists).
      expect(find.text('Search PMEGP'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
