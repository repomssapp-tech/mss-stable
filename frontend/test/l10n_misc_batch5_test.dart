// Batch 5 of the localization consolidation.
//
// Covers:
//  (i)  AppConstants.getTimeGreeting(AppLocalizations) -- pure function test
//       against the ARB values for en / ta.
//  (ii) SplashScreen pumped under a real MaterialApp locale: the previously
//       hardcoded 'Loading...' / subtitle now render from AppLocalizations.
//  (iii) SearchResultsScreen empty-state: the migrated 'Sort' /
//       'Clear Filters & Explore Schemes' / no-results strings render from ARB.
//
// Pattern mirrors test/l10n_categories_batch3_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/regular_mode/search_results_screen.dart';
import 'package:frontend/utils/constants.dart';

Widget _host(Locale locale, Widget screen) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
}

String _expectedGreeting(AppLocalizations l10n) {
  final hour = DateTime.now().hour;
  if (hour < 5) return l10n.greetingLateNight;
  if (hour < 12) return l10n.goodMorning;
  if (hour >= 12 && hour < 17) return l10n.goodAfternoon;
  return l10n.goodEvening;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('getTimeGreeting(AppLocalizations)', () {
    test(
      'returns the locale-specific ARB greeting and differs by locale',
      () async {
        final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
        final l10nTa = await AppLocalizations.delegate.load(const Locale('ta'));

        final en = AppConstants.getTimeGreeting(l10nEn);
        final ta = AppConstants.getTimeGreeting(l10nTa);

        expect(en, equals(_expectedGreeting(l10nEn)));
        expect(ta, equals(_expectedGreeting(l10nTa)));
        expect(en, isNot(equals(ta)));
        // ARB values carry the trailing comma.
        expect(en.endsWith(','), isTrue);
        expect(ta.endsWith(','), isTrue);
      },
    );
  });

  group('SplashScreen loading copy renders from ARB', () {
    testWidgets('English locale shows the English loading strings', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Locale('en'), const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Loading...'), findsOneWidget);
      expect(
        find.text('Please wait while we prepare\nsomething amazing for you'),
        findsOneWidget,
      );
      expect(find.text('ஏற்றுகிறது...'), findsNothing);

      // Dispose SplashScreen so its 3.2s navigation Timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tamil locale shows the Tamil loading string', (tester) async {
      await tester.pumpWidget(_host(const Locale('ta'), const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ஏற்றுகிறது...'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('SearchResultsScreen migrated strings render from ARB', () {
    testWidgets('English locale: Sort + empty-state + clear-filters', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Locale('en'),
          const SearchResultsScreen(
            title: 'All',
            type: 'category',
            initialSchemes: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The sort chip shows "<label>: <current sort>" -- label from ARB.
      expect(find.textContaining('Sort'), findsOneWidget);
      expect(
        find.text('No schemes found matching your filters'),
        findsOneWidget,
      );
      expect(find.text('Clear Filters & Explore Schemes'), findsOneWidget);
      expect(find.textContaining('வரிசைப்படுத்து'), findsNothing);
    });

    testWidgets('Tamil locale: Sort + empty-state + clear-filters', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Locale('ta'),
          const SearchResultsScreen(
            title: 'All',
            type: 'category',
            initialSchemes: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('வரிசைப்படுத்து'), findsOneWidget);
      expect(
        find.text(
          'தேர்ந்தெடுக்கப்பட்ட வடிகட்டிகளுக்கு பொருந்தும் திட்டங்கள் எதுவும் இல்லை',
        ),
        findsOneWidget,
      );
      expect(
        find.text('வடிகட்டிகளை அழித்து திட்டங்களைக் காண்க'),
        findsOneWidget,
      );
      expect(find.textContaining('Sort'), findsNothing);
    });
  });
}
