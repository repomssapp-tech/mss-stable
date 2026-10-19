import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/search/search_models.dart';
import 'package:frontend/screens/regular_mode/search/search_input_section.dart';
import 'package:frontend/screens/regular_mode/search/search_results_view.dart';
import 'package:frontend/utils/spell_check.dart';

Widget _host(Locale locale, Widget screen) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: screen),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('DidYouMeanSuggestion', () {
    const expected = {
      'en': 'Did you mean "loan"?',
      'hi': 'क्या आपका मतलब "loan" था?',
      'ta': 'நீங்கள் "loan" என்பதைத் தேடினீர்களா?',
    };

    for (final entry in expected.entries) {
      testWidgets('shows the ${entry.key} wording and reports the tap', (
        tester,
      ) async {
        String? tapped;
        await tester.pumpWidget(
          _host(
            Locale(entry.key),
            DidYouMeanSuggestion(suggestion: 'loan', onTap: (s) => tapped = s),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        // An easy touch target, not a thin text link.
        expect(
          tester.getSize(find.byType(DidYouMeanSuggestion)).height,
          greaterThanOrEqualTo(48),
        );

        await tester.tap(find.text(entry.value));
        expect(tapped, 'loan');
      });
    }
  });

  group('platform spell check', () {
    test('is on only when the platform provides a spell checker', () {
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
      addTearDown(dispatcher.clearNativeSpellCheckServiceDefined);

      dispatcher.nativeSpellCheckServiceDefinedTestValue = false;
      expect(platformSpellCheck(), isNull);

      dispatcher.nativeSpellCheckServiceDefinedTestValue = true;
      expect(platformSpellCheck(), isNotNull);
      expect(platformSpellCheck()!.spellCheckEnabled, isTrue);
    });

    testWidgets('a search field renders without error where there is none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Locale('en'),
          SearchInputField(
            controller: TextEditingController(),
            focusNode: FocusNode(),
            isDictating: false,
            onToggleDictation: () {},
            onSubmitted: (_) {},
            onClear: () {},
            onSubmitTap: () {},
            scaledFontSize: (s) => s,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No native checker here, so spell check stays off. Passing a
      // configuration anyway would make Flutter assert, failing this test.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.spellCheckConfiguration, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('SearchResultsList', () {
    Widget list({
      required String queryText,
      String? didYouMean,
      ValueChanged<String>? onTap,
      List<Scheme> results = const [],
    }) {
      return _host(
        const Locale('en'),
        Builder(
          builder: (context) => SearchResultsList(
            searchResults: results,
            queryText: queryText,
            isForMe: false,
            forMeEmptyState: ForMeEmptyState.none,
            provider: context.read<AppProvider>(),
            scaledFontSize: (s) => s,
            didYouMean: didYouMean,
            onDidYouMeanTap: onTap,
          ),
        ),
      );
    }

    testWidgets('empty state offers the correction and reports the tap', (
      tester,
    ) async {
      String? tapped;
      await tester.pumpWidget(
        list(queryText: 'laon', didYouMean: 'loan', onTap: (s) => tapped = s),
      );
      await tester.pumpAndSettle();

      expect(find.text('No schemes found for "laon"'), findsOneWidget);
      expect(find.text('Did you mean "loan"?'), findsOneWidget);

      await tester.tap(find.text('Did you mean "loan"?'));
      expect(tapped, 'loan');
    });

    testWidgets('no suggestion means no "Did you mean" line', (tester) async {
      await tester.pumpWidget(list(queryText: 'zzzz'));
      await tester.pumpAndSettle();

      expect(find.text('No schemes found for "zzzz"'), findsOneWidget);
      expect(find.textContaining('Did you mean'), findsNothing);
    });

    testWidgets('a suggestion without a handler is not shown', (tester) async {
      await tester.pumpWidget(list(queryText: 'laon', didYouMean: 'loan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Did you mean'), findsNothing);
    });

    testWidgets('with results, the suggestion sits in the list header', (
      tester,
    ) async {
      await tester.pumpWidget(
        list(
          queryText: 'women entreprenuer',
          didYouMean: 'women entrepreneur',
          onTap: (_) {},
          results: [
            Scheme(
              id: 'CEN2026-001',
              name: 'Women Entrepreneur Scheme',
              state: 'All India',
              category: 'MSME',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Did you mean "women entrepreneur"?'), findsOneWidget);
    });
  });
}
