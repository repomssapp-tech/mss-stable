// Drives the REAL search screen on an Android emulator/device, so the system
// spell checker and the full search + ranking pipeline are exercised end to
// end (the host test runner cannot reach the platform spell-check service).
//
//   python tools/search_eval_device.py serve          # host: queries + config
//   python tools/search_eval_device.py config en 0 100  # lang, offset, limit
//   flutter drive --driver=test_driver/integration_test.dart \
//       --target=integration_test/search_emulator_test.dart -d emulator-5554 \
//       [--use-application-binary=build/app/outputs/flutter-apk/app-debug.apk]
//   python tools/search_eval_device.py convert
//   -> results land in build/integration_response_data.json on the host
//
// (Queries and the language/slice come from the host, and results are returned
// through reportData, because the app's own storage is wiped when a run ends.)
//
// Per query it records: what the system spell checker flagged and suggested,
// where the expected scheme ranks in what the screen shows, and what happens
// after tapping "Did you mean". For misspelt queries it also spell-checks the
// clean text, to measure false alarms. Finally it runs the recommendation
// engine for a set of profiles written in the device language.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Which language and slice of cases to run is read from the host at run time
// (eval_config.json: {"lang": "en", "offset": 0, "limit": 100}), so one built
// APK serves every language and batch: no rebuild, no Gradle, far less memory.
// A slice [offset, offset + limit) keeps a long run resumable: an interrupted
// batch loses only itself.
String _lang = 'en';
int _limit = 100000;
int _offset = 0;

// The host serves queries.json and eval_config.json (10.0.2.2 is the
// emulator's alias for the host machine). Too large to pass as a dart-define:
// Windows caps the Gradle command line, and the app's own storage is wiped when
// a device test ends.
const _hostUrl = String.fromEnvironment(
  'EVAL_HOST_URL',
  defaultValue: 'http://10.0.2.2:8765',
);

Future<String> _fetch(String path) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse('$_hostUrl/$path'));
    final response = await request.close();
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

Future<void> _wait(WidgetTester tester, int ms) async {
  // Real time on a device: the platform channels answer on their own clock.
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump();
}

Future<bool> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int timeoutMs = 8000,
}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(end)) {
    await _wait(tester, 120);
    if (done()) return true;
  }
  return false;
}

/// The words the spell checker flagged, with their suggestions.
List<Map<String, Object?>> _spellSpans(WidgetTester tester) {
  final state = tester.state<EditableTextState>(find.byType(EditableText));
  final results = state.spellCheckResults;
  if (results == null) return const [];
  final text = results.spellCheckedText;
  return [
    for (final span in results.suggestionSpans)
      if (span.range.start >= 0 && span.range.end <= text.length)
        {
          'word': text.substring(span.range.start, span.range.end),
          'suggestions': span.suggestions,
        },
  ];
}

List<String> _shownIds(WidgetTester tester) {
  final list = tester.widget<SearchResultsList>(find.byType(SearchResultsList));
  return [for (final s in list.searchResults.take(25)) s.id];
}

List<String> _shownNames(WidgetTester tester, {int take = 3}) {
  final list = tester.widget<SearchResultsList>(find.byType(SearchResultsList));
  return [for (final s in list.searchResults.take(take)) s.name];
}

/// The results list object currently on screen (a new object per search), or
/// null when the screen is idle. Used to tell a fresh result from a stale one.
Object? _currentResults(WidgetTester tester) =>
    find.byType(SearchResultsList).evaluate().isEmpty
    ? null
    : tester
          .widget<SearchResultsList>(find.byType(SearchResultsList))
          .searchResults;

/// Waits for results that are NOT [stale] and for the loading skeleton to go.
Future<bool> _waitForFreshResults(WidgetTester tester, Object? stale) =>
    _pumpUntil(tester, () {
      final now = _currentResults(tester);
      return now != null &&
          !identical(now, stale) &&
          find.byType(SearchLoadingSkeleton).evaluate().isEmpty;
    });

int? _rank(List<String> ids, String expected) {
  final i = ids.indexOf(expected);
  return i < 0 ? null : i + 1;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'search + spell check evaluation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final config =
          jsonDecode((await tester.runAsync(() => _fetch('eval_config.json')))!)
              as Map<String, dynamic>;
      _lang = config['lang'] as String;
      _limit = (config['limit'] ?? 100000) as int;
      _offset = (config['offset'] ?? 0) as int;
      final all =
          (jsonDecode((await tester.runAsync(() => _fetch('queries.json')))!)
                  as List)
              .cast<Map<String, dynamic>>();
      final queries = [
        for (final q in all)
          if (q['lang'] == _lang) q,
      ].skip(_offset).take(_limit).toList();

      final provider = AppProvider();
      await provider.changeLanguage(_lang);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            locale: Locale(_lang),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('hi'), Locale('ta')],
            home: const Scaffold(body: SearchScreen()),
          ),
        ),
      );
      await _wait(tester, 1500);

      final field = find.byType(TextField);
      final rows = <Map<String, Object?>>[];

      // Is spell check on for the field, and does the Android service answer?
      final probeText = const {
        'en': 'Steet Technlogy hello',
        'ta': 'திட்டம் திட்டமம் பெணகள்',
        'hi': 'योजना योजनन महिलाए',
      }[_lang]!;
      final probe = await tester.runAsync(
        () => DefaultSpellCheckService().fetchSpellCheckSuggestions(
          Locale(_lang),
          probeText,
        ),
      );
      final spellDiagnostics = {
        'nativeSpellCheckServiceDefined': WidgetsBinding
            .instance
            .platformDispatcher
            .nativeSpellCheckServiceDefined,
        'fieldSpellCheckEnabled': tester
            .widget<TextField>(field)
            .spellCheckConfiguration
            ?.spellCheckEnabled,
        'probeText': probeText,
        'probeSpans': [
          for (final s in probe ?? const <SuggestionSpan>[])
            {
              'word': probeText.substring(s.range.start, s.range.end),
              'suggestions': s.suggestions,
            },
        ],
        'probeReturnedNull': probe == null,
      };
      // ignore: avoid_print
      print('[eval $_lang] spell diagnostics: $spellDiagnostics');

      Future<List<Map<String, Object?>>> typeAndSpellCheck(String text) async {
        // Searching unfocuses the field; tap it (as a user would) so typing
        // reaches it again.
        await tester.tap(field);
        await _wait(tester, 150);
        await tester.enterText(field, '');
        await _wait(tester, 450); // debounce -> idle
        await tester.enterText(field, text);
        await _wait(tester, 700); // let the system spell checker answer
        return _spellSpans(tester);
      }

      for (var n = 0; n < queries.length; n++) {
        final q = queries[n];
        final query = q['query'] as String;
        final expected = q['expected'] as String;
        final started = DateTime.now();

        final spans = await typeAndSpellCheck(query);

        // False alarms: does the spell checker flag the CLEAN text?
        List<Map<String, Object?>> cleanSpans = const [];
        if (q['typo'] == true) {
          cleanSpans = await typeAndSpellCheck(q['clean'] as String);
          await typeAndSpellCheck(query); // restore the typed query
        }

        final stale = _currentResults(tester);
        final fieldTextAtSubmit = tester
            .widget<TextField>(field)
            .controller
            ?.text;
        // Tap the search icon, as a user would (the keyboard action stops
        // reaching the field after the first submit, which unfocuses it).
        await tester.tap(
          find.descendant(
            of: find.byType(SearchInputField),
            matching: find.byIcon(Icons.search),
          ),
        );
        final shown = await _waitForFreshResults(tester, stale);
        final ids = shown ? _shownIds(tester) : <String>[];
        final topNames = shown ? _shownNames(tester) : <String>[];
        String? suggestion;
        int? rankAfter;
        if (shown) {
          suggestion = tester
              .widget<SearchResultsList>(find.byType(SearchResultsList))
              .didYouMean;
          if (suggestion != null &&
              find.byType(DidYouMeanSuggestion).evaluate().isNotEmpty) {
            final before = _currentResults(tester);
            await tester.tap(find.byType(DidYouMeanSuggestion).first);
            final reshown = await _waitForFreshResults(tester, before);
            if (reshown) rankAfter = _rank(_shownIds(tester), expected);
          }
        }

        final clean = (q['clean'] as String).toLowerCase().trim();
        rows.add({
          ...q,
          'returned': ids.length,
          'top3': topNames,
          'fieldTextAtSubmit': fieldTextAtSubmit,
          'listQueryText': shown
              ? tester
                    .widget<SearchResultsList>(find.byType(SearchResultsList))
                    .queryText
              : null,
          'timedOut': !shown,
          'rank': _rank(ids, expected),
          'suggestion': suggestion,
          'suggestionRecoversClean':
              suggestion != null && suggestion.toLowerCase().trim() == clean,
          'rankAfterSuggestion': rankAfter,
          'spellFlagged': spans.map((s) => s['word']).toList(),
          'spellSuggestions': {
            for (final s in spans) s['word'] as String: s['suggestions'],
          },
          'cleanSpellFlagged': cleanSpans.map((s) => s['word']).toList(),
          'ms': DateTime.now().difference(started).inMilliseconds,
        });
        if (n % 25 == 0) {
          // ignore: avoid_print
          print('[eval $_lang] ${n + 1}/${queries.length}');
        }
      }

      // Recommendation engine, with profile labels in the device language.
      final schemes = await SchemeRepository.instance.getAllSchemes();
      final l10n = await AppLocalizations.delegate.load(Locale(_lang));
      final profiles = <String, UserProfile>{
        'woman-SC-TN': UserProfile(
          gender: l10n.genderFemale,
          community: l10n.commSc,
          state: _stateName(_lang),
          educationLevel: l10n.eduUndergraduate,
          employmentStatus: 'Aspiring Entrepreneur',
          disability: l10n.valNo,
          dob: DateTime(1996, 3, 14),
          businessStage: 'Idea',
          profileCompleted: true,
        ),
        'man-general-TN': UserProfile(
          gender: l10n.genderMale,
          community: l10n.commGeneral,
          state: _stateName(_lang),
          educationLevel: l10n.eduPostgraduate,
          employmentStatus: 'Existing Business',
          disability: l10n.valNo,
          dob: DateTime(1985, 7, 2),
          businessStage: 'Operational',
          profileCompleted: true,
        ),
      };
      final recommendations = {
        for (final e in profiles.entries)
          e.key: {
            'forMeCount': RecommendationEngine.forMeSchemes(
              e.value,
              schemes,
            ).length,
            'top10': [
              for (final r in RecommendationEngine.getRecommendations(
                e.value,
                schemes,
              ).take(10))
                r.key.id,
            ],
          },
      };

      binding.reportData = {
        'lang': _lang,
        'offset': _offset,
        'spellDiagnostics': spellDiagnostics,
        'rows': rows,
        'recommendations': recommendations,
      };
      // ignore: avoid_print
      print('[eval $_lang] done: ${rows.length} cases');
    },
    timeout: const Timeout(Duration(minutes: 90)),
  );
}

String _stateName(String lang) =>
    const {'en': 'Tamil Nadu', 'hi': 'तमिलनाडु', 'ta': 'தமிழ்நாடு'}[lang]!;
