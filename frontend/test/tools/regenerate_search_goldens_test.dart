// Opt-in maintenance tool (skipped unless REGENERATE_SEARCH_GOLDENS=1):
//
//   REGENERATE_SEARCH_GOLDENS=1 flutter test test/tools/regenerate_search_goldens_test.dart
//
// Rewrites the ranking golden files from the bundled catalog after a
// deliberate catalog or ranking change:
//   * backend/catalog/search_parity_golden.json  (HybridSchemeSearch rows,
//     shared with the TypeScript and Python engine parity tests)
//   * test/fixtures/scheme_search_rank_stability_expected.json
//     (IntelligentSchemeSearch top-10 per corpus query)
//
// Regenerating only records current behaviour; review the diff and spot-check
// the rankings before committing (see docs/audit/CATALOG_V3_1_AUDIT.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';
import 'package:frontend/services/search/intelligent_scheme_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enabled = Platform.environment['REGENERATE_SEARCH_GOLDENS'] == '1';
  const encoder = JsonEncoder.withIndent('  ');

  test(
    'regenerate backend/catalog/search_parity_golden.json',
    () async {
      final file = File('../backend/catalog/search_parity_golden.json');
      final old = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
      final bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
      final engine = await HybridSchemeSearch.build(bundle);
      final rows = <Map<String, dynamic>>[];
      for (final row in old) {
        final query = row['query'] as String;
        final topN = (row['results'] as List).length;
        final hits = engine.search(query, topN: topN);
        rows.add({
          'query': query,
          'results': [
            for (final h in hits)
              {
                'schemeId': h.$1.id,
                'score': double.parse(h.$2.toStringAsFixed(4)),
              },
          ],
        });
      }
      file.writeAsStringSync('${encoder.convert(rows)}\n');
    },
    skip: enabled ? false : 'set REGENERATE_SEARCH_GOLDENS=1 to run',
  );

  test(
    'regenerate scheme_search_rank_stability_expected.json',
    () async {
      final schemes = await SchemeRepository.instance.getAllSchemes();
      final queries =
          (jsonDecode(
                    File(
                      'test/fixtures/scheme_search_rank_stability_corpus.json',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<String>();
      final expected = <String, dynamic>{};
      for (final q in queries) {
        expected[q] = [
          for (final m in IntelligentSchemeSearch.rank(q, schemes, limit: 10))
            {
              'code': m.scheme.schemeCode,
              'score': double.parse(m.score.toStringAsFixed(6)),
            },
        ];
      }
      File(
        'test/fixtures/scheme_search_rank_stability_expected.json',
      ).writeAsStringSync('${encoder.convert(expected)}\n');
    },
    skip: enabled ? false : 'set REGENERATE_SEARCH_GOLDENS=1 to run',
  );
}
