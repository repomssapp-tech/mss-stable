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
    testWidgets('Quick search pills are hidden by default and appear on search bar click',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      provider.setLoggedInForTesting(true);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By default: quick pills should NOT be visible
      expect(find.text('Search PMEGP'), findsNothing);
      expect(find.text('Search Startup India'), findsNothing);

      // Verify dynamic time-of-day greeting is present
      final currentGreeting = AppConstants.getTimeGreeting(
        isTa: false,
        withComma: true,
      );
      expect(find.text(currentGreeting), findsOneWidget);

      // Search bar placeholder should be visible
      final searchField = find.textContaining('Search schemes');
      expect(searchField, findsOneWidget);

      // Tap on the search bar
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Now quick pills should be visible!
      expect(find.text('Search PMEGP'), findsOneWidget);
      expect(find.text('Search Startup India'), findsOneWidget);

      // A close button (Icons.close) should now be present in the search bar
      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);

      // Tap close button to dismiss pills
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Pills should be hidden again
      expect(find.text('Search PMEGP'), findsNothing);
      expect(find.text('Search Startup India'), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
