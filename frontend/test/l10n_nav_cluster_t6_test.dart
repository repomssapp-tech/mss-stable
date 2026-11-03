// T6 of the custom string-map -> gen-l10n ARB migration.
//
// Covers the "remaining hardcoded English" sweep across the core-navigation
// cluster:
//   - regular_mode/eligibility_results_screen.dart  (eligRes*)
//   - notifications_screen.dart                     (notif* + relative-time)
//   - providers/app_state_provider.dart             (seed notification data)
//   - regular_mode/home_screen.dart                 (commonUserFallback)
//   - regular_mode/search_screen.dart               (searchHintFallback, best-matches)
//   - regular_mode/search_results_screen.dart       (share header, tooltips)
//   - regular_mode/saved_schemes_screen.dart        (saved*)
//
// (i)  getter-level assertions: each representative new key is non-empty and
//      ta != en, loaded straight from the generated delegate, including
//      placeholder interpolation for notifSelectedCount / timeAgoDays / the
//      eligibility clipboard + summary keys.
// (ii) EligibilityResultsScreen pumped under a real MaterialApp locale (en/ta)
//      inside a ChangeNotifierProvider<AppProvider>; assert the localized
//      "Great News" header + "Save Results" CTA render per locale.
//      Pattern mirrors test/l10n_categories_batch3_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/eligibility_results_screen.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('T6 new keys: non-empty and ta != en', () {
    late AppLocalizations en;
    late AppLocalizations ta;

    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      ta = await AppLocalizations.delegate.load(const Locale('ta'));
    });

    test(
      'representative simple keys across every T6 namespace differ by locale',
      () {
        final pairs = <String, List<String>>{
          // shared tooltips
          'shareResultsTooltip': [
            en.shareResultsTooltip,
            ta.shareResultsTooltip,
          ],
          'clearSearchTooltip': [en.clearSearchTooltip, ta.clearSearchTooltip],
          'voiceSearchTooltip': [en.voiceSearchTooltip, ta.voiceSearchTooltip],
          // eligibility_results_screen.dart
          'eligResGreatNews': [en.eligResGreatNews, ta.eligResGreatNews],
          'eligResSaveResults': [en.eligResSaveResults, ta.eligResSaveResults],
          'eligResBasedOnInfo': [en.eligResBasedOnInfo, ta.eligResBasedOnInfo],
          'eligResSecurePrivate': [
            en.eligResSecurePrivate,
            ta.eligResSecurePrivate,
          ],
          'eligResShareHeader': [en.eligResShareHeader, ta.eligResShareHeader],
          // notifications_screen.dart
          'notifCatNewSchemes': [en.notifCatNewSchemes, ta.notifCatNewSchemes],
          'notifBadgeNew': [en.notifBadgeNew, ta.notifBadgeNew],
          'notifMarkAllAsRead': [en.notifMarkAllAsRead, ta.notifMarkAllAsRead],
          'notifNoMatchingAlerts': [
            en.notifNoMatchingAlerts,
            ta.notifNoMatchingAlerts,
          ],
          'notifTagEducation': [en.notifTagEducation, ta.notifTagEducation],
          'timeAgoJustNow': [en.timeAgoJustNow, ta.timeAgoJustNow],
          // app_state_provider.dart seed prose
          'notifSeed2Title': [en.notifSeed2Title, ta.notifSeed2Title],
          'notifSeed7Body': [en.notifSeed7Body, ta.notifSeed7Body],
          // home_screen.dart
          'commonUserFallback': [en.commonUserFallback, ta.commonUserFallback],
          // search_screen.dart
          'searchHintFallback': [en.searchHintFallback, ta.searchHintFallback],
          'searchBestMatchesForCriteria': [
            en.searchBestMatchesForCriteria,
            ta.searchBestMatchesForCriteria,
          ],
          // saved_schemes_screen.dart
          'savedKeepListUpdated': [
            en.savedKeepListUpdated,
            ta.savedKeepListUpdated,
          ],
          'savedRemoveFromSavedTooltip': [
            en.savedRemoveFromSavedTooltip,
            ta.savedRemoveFromSavedTooltip,
          ],
        };

        pairs.forEach((key, values) {
          expect(values[0].trim(), isNotEmpty, reason: '$key (en) non-empty');
          expect(values[1].trim(), isNotEmpty, reason: '$key (ta) non-empty');
          expect(
            values[1],
            isNot(equals(values[0])),
            reason: '$key ta must be a real translation, not the en string',
          );
        });
      },
    );

    test('notifSelectedCount interpolates the count placeholder', () {
      expect(en.notifSelectedCount(3), contains('3'));
      expect(ta.notifSelectedCount(3), contains('3'));
      expect(ta.notifSelectedCount(3), isNot(equals(en.notifSelectedCount(3))));
    });

    test('relative-time keys interpolate count and differ by locale', () {
      expect(en.timeAgoDays(5), contains('5'));
      expect(en.timeAgoHours(2), contains('2'));
      expect(en.timeAgoMinutes(10), contains('10'));
      expect(en.daysLeftFmt(20), contains('20'));
      expect(ta.timeAgoDays(5), contains('5'));
      expect(ta.timeAgoDays(5), isNot(equals(en.timeAgoDays(5))));
      expect(ta.daysLeftFmt(20), isNot(equals(en.daysLeftFmt(20))));
    });

    test('eligibility clipboard + summary keys interpolate placeholders', () {
      expect(
        en.eligResShareItem('PMEGP', 87),
        allOf(contains('PMEGP'), contains('87')),
      );
      expect(
        ta.eligResShareItem('PMEGP', 87),
        allOf(contains('PMEGP'), contains('87')),
      );
      expect(
        ta.eligResShareItem('PMEGP', 87),
        isNot(equals(en.eligResShareItem('PMEGP', 87))),
      );

      expect(en.eligResGovernmentSchemesCount(4), contains('4'));
      expect(ta.eligResGovernmentSchemesCount(4), contains('4'));
      expect(
        ta.eligResGovernmentSchemesCount(4),
        isNot(equals(en.eligResGovernmentSchemesCount(4))),
      );
    });

    test('search best-matches-for-query interpolates the query', () {
      expect(en.searchBestMatchesForQuery('mudra'), contains('mudra'));
      expect(ta.searchBestMatchesForQuery('mudra'), contains('mudra'));
      expect(
        ta.searchBestMatchesForQuery('mudra'),
        isNot(equals(en.searchBestMatchesForQuery('mudra'))),
      );
    });

    test('searchResultsShareHeader interpolates the title', () {
      expect(en.searchResultsShareHeader('PMEGP'), contains('PMEGP'));
      expect(ta.searchResultsShareHeader('PMEGP'), contains('PMEGP'));
    });
  });

  group('EligibilityResultsScreen renders migrated strings for the locale', () {
    testWidgets('English locale: Great News header + Save Results CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Locale('en'), const EligibilityResultsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your results'), findsOneWidget);
      expect(find.text('Save results'), findsOneWidget);
    });

    testWidgets('Tamil locale: Great News header + Save Results CTA from ARB', (
      tester,
    ) async {
      final ta = await AppLocalizations.delegate.load(const Locale('ta'));

      await tester.pumpWidget(
        _host(const Locale('ta'), const EligibilityResultsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(ta.eligResGreatNews), findsOneWidget);
      expect(find.text(ta.eligResSaveResults), findsOneWidget);
      expect(find.text('Your results'), findsNothing);
      expect(find.text('Save results'), findsNothing);
    });
  });
}
