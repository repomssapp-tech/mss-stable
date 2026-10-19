import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';

/// 1.2 (audit_fix.md): guards the shared ranking parameters and search
/// output against silent drift across the three engines (this file, Dart;
/// search_engine.ts, TypeScript; scheme_catalog.py, Python).
///
/// Two checks:
///  1. This engine's local copy of search_taxonomy.json is byte-identical
///     to the canonical copy at backend/catalog/. The three engines each
///     keep their own local copy (deployment-bundling constraints rule out
///     a single shared file -- see the audit's fix-time notes), so nothing
///     else catches a hand-edit to only one copy.
///  2. Running the fixed query set from backend/catalog/search_parity_golden.json
///     through HybridSchemeSearch reproduces the exact recorded scores.
///     Any change to the taxonomy tables, weights, or scoring logic that
///     shifts a single query's ranking will fail here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local search_taxonomy.json matches the canonical copy', () {
    final canonical = File(
      '../backend/catalog/search_taxonomy.json',
    ).readAsStringSync();
    final local = File('assets/search/search_taxonomy.json').readAsStringSync();
    expect(
      local,
      equals(canonical),
      reason:
          'frontend/assets/search/search_taxonomy.json has drifted from '
          'backend/catalog/search_taxonomy.json (the canonical copy). Copy '
          'the canonical file over this one -- never hand-edit this copy '
          'directly.',
    );
  });

  test(
    'canonical queryExpansions matches assets/search/query_expansion.json',
    () {
      final canonical =
          jsonDecode(
                File(
                  '../backend/catalog/search_taxonomy.json',
                ).readAsStringSync(),
              )['queryExpansions']
              as Map<String, dynamic>;
      final dartExpansions =
          jsonDecode(
                File('assets/search/query_expansion.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        const DeepCollectionEquality().equals(canonical, dartExpansions),
        isTrue,
        reason:
            'backend/catalog/search_taxonomy.json\'s queryExpansions has '
            'drifted from assets/search/query_expansion.json (the file '
            'this engine loads). This is the exact class of bug that made '
            'the TypeScript server silently miss the \'tax\'/\'exemption\' '
            'expansions this file already had -- keep both in sync.',
      );
    },
  );

  test('HybridSchemeSearch reproduces the golden parity fixture', () async {
    final golden =
        (jsonDecode(
                  File(
                    '../backend/catalog/search_parity_golden.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();

    final bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    final engine = await HybridSchemeSearch.build(bundle);

    final mismatches = <String>[];
    for (final row in golden) {
      final query = row['query'] as String;
      final expected = (row['results'] as List).cast<Map<String, dynamic>>();
      final actual = engine.search(query, topN: expected.length);

      final actualIds = actual.map((r) => r.$1.id).toList();
      final expectedIds = expected.map((r) => r['schemeId'] as String).toList();
      if (!const ListEquality<String>().equals(actualIds, expectedIds)) {
        mismatches.add('"$query": expected $expectedIds, got $actualIds');
        continue;
      }

      for (var i = 0; i < expected.length; i++) {
        final expectedScore = (expected[i]['score'] as num).toDouble();
        final actualScore = actual[i].$2;
        if ((actualScore - expectedScore).abs() > 0.0001) {
          mismatches.add(
            '"$query" #$i (${actualIds[i]}): expected score '
            '$expectedScore, got $actualScore',
          );
        }
      }
    }

    expect(
      mismatches,
      isEmpty,
      reason:
          'HybridSchemeSearch output diverged from the golden parity '
          'fixture:\n${mismatches.join('\n')}\n\nIf this divergence is '
          'intentional (a deliberate ranking change), regenerate '
          'backend/catalog/search_parity_golden.json and re-verify the '
          'TypeScript and Python engines still match it too.',
    );
  });
}

class ListEquality<T> {
  const ListEquality();
  bool equals(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
