import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/search/intelligent_scheme_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2.6 perf: widened golden corpus (234 queries -- English, Tamil,
  // misspellings, multi-term, single-word, and edge cases like '', ' ',
  // 'a', '1', '??') covering the catalog ranking hot path
  // (_scoreScheme/_containsAlias) that the length-diff pre-check in
  // _containsAlias touches. Captured against the real catalog bundle both
  // before and after that change (verified byte-identical via a git-stash
  // A/B comparison in-session) -- this is the permanent record of that
  // comparison, so any future change to the matching logic that reorders
  // or rescales results gets caught here instead of discovered in prod.
  test('ranking the real catalog for 234 diverse queries stays byte-identical '
      'to the pre-2.6 snapshot', () async {
    final schemes = await SchemeRepository.instance.getAllSchemes();
    final queries =
        (jsonDecode(
                  File(
                    'test/fixtures/scheme_search_rank_stability_corpus.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<String>();
    final expected =
        jsonDecode(
              File(
                'test/fixtures/scheme_search_rank_stability_expected.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(queries.length, 234);

    final mismatches = <String>[];
    for (final q in queries) {
      final matches = IntelligentSchemeSearch.rank(q, schemes, limit: 10);
      final actual = matches
          .map(
            (m) => {
              'code': m.scheme.schemeCode,
              'score': double.parse(m.score.toStringAsFixed(6)),
            },
          )
          .toList();
      final expectedForQuery = expected[q] as List;
      if (jsonEncode(actual) != jsonEncode(expectedForQuery)) {
        mismatches.add(q.isEmpty ? '<empty>' : q);
      }
    }

    expect(
      mismatches,
      isEmpty,
      reason: 'Ranking changed for these queries:\n${mismatches.join('\n')}',
    );
  });
}
