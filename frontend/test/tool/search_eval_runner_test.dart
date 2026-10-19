// Held-out search evaluation runner. Inert in the normal suite: it only runs
// when SEARCH_EVAL_FILE points at a JSON eval file of the shape below, and
// writes per-query results to SEARCH_EVAL_OUT. The query set itself is not
// part of the repo.
//
//   SEARCH_EVAL_FILE=queries.json SEARCH_EVAL_OUT=results.json \
//     flutter test test/tool/search_eval_runner_test.dart
//
// Each query is {lang, level, typo, query, expected (scheme id), clean}.
// Results record where the expected scheme ranks in what the user sees, and
// for misspelt queries whether "Did you mean" fires, whether it recovers the
// clean text, and how results look after the user taps it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';

int? _rankOf(List<String> ids, String expected) {
  final i = ids.indexOf(expected);
  return i < 0 ? null : i + 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final evalFile = Platform.environment['SEARCH_EVAL_FILE'];
  final outFile = Platform.environment['SEARCH_EVAL_OUT'];

  test(
    'run held-out search evaluation',
    () async {
      final queries = (jsonDecode(File(evalFile!).readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
      final bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
      final engine = await HybridSchemeSearch.build(bundle);

      Future<List<String>> idsFor(String q) async {
        final matches = await HybridSchemeSearch.rank(q, bundle, limit: 25);
        return [for (final m in matches) m.scheme.id];
      }

      final results = <Map<String, dynamic>>[];
      for (final q in queries) {
        final query = q['query'] as String;
        final expected = q['expected'] as String;
        final ids = await idsFor(query);
        final suggestion = engine.didYouMean(query);

        int? afterRank;
        if (suggestion != null) {
          afterRank = _rankOf(await idsFor(suggestion), expected);
        }
        final clean = (q['clean'] as String).toLowerCase().trim();
        results.add({
          ...q,
          'returned': ids.length,
          'rank': _rankOf(ids, expected),
          'suggestion': suggestion,
          'suggestionRecoversClean':
              suggestion != null && suggestion.toLowerCase().trim() == clean,
          'rankAfterSuggestion': afterRank,
        });
      }
      File(
        outFile!,
      ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(results));
    },
    skip: evalFile == null || outFile == null
        ? 'set SEARCH_EVAL_FILE and SEARCH_EVAL_OUT to run'
        : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
