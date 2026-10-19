import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/home_screen.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Time-of-day greeting tests', () {
    test(
      'AppConstants.getTimeGreeting returns expected strings across day brackets',
      () async {
        final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
        final greetingEn = AppConstants.getTimeGreeting(l10nEn);
        final hour = DateTime.now().hour;
        if (hour >= 5 && hour < 12) {
          expect(greetingEn, equals('Good Morning,'));
        } else if (hour >= 12 && hour < 17) {
          expect(greetingEn, equals('Good Afternoon,'));
        } else {
          expect(greetingEn, equals('Good Evening,'));
        }

        final l10nTa = await AppLocalizations.delegate.load(const Locale('ta'));
        final greetingTa = AppConstants.getTimeGreeting(l10nTa);
        if (hour >= 5 && hour < 12) {
          expect(greetingTa, equals('காலை வணக்கம்,'));
        } else if (hour >= 12 && hour < 17) {
          expect(greetingTa, equals('மதிய வணக்கம்,'));
        } else {
          expect(greetingTa, equals('மாலை வணக்கம்,'));
        }

        // The greeting differs between locales and the ARB carries the comma.
        expect(greetingEn == greetingTa, isFalse);
        expect(greetingEn.endsWith(','), isTrue);
        expect(greetingTa.endsWith(','), isTrue);
      },
    );
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
                body: HomeScreen(onSearchBarTap: () => searchBarTapCount++),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Quick pills are always visible now -- no reveal gesture needed.
        expect(find.text('Search PMEGP'), findsOneWidget);
        expect(find.text('Search Startup India'), findsOneWidget);

        // Verify dynamic time-of-day greeting is present
        final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
        final currentGreeting = AppConstants.getTimeGreeting(l10nEn);
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
      },
    );
  });
}
