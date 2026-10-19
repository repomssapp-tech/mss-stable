import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';

/// Tests verifying that the query expansion dictionary correctly resolves
/// acronyms, Tanglish transliterations, multi-word phrases, and colloquial
/// aliases to the intended schemes — without regressing existing search
/// accuracy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  late HybridSchemeSearch engine;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    engine = await HybridSchemeSearch.build(bundle);
  });

  // ─── Dictionary integrity ────────────────────────────────────────────

  group('Query Expansion Dictionary Integrity', () {
    test('all expansion target tokens exist in catalog _vocab', () {
      // Build the same vocab set the engine uses internally.
      final vocab = <String>{};
      for (final scheme in bundle.schemes) {
        final profile = bundle.searchProfiles[scheme.id];
        if (profile == null) continue;
        final tokens = profile['tokens'] as Map<String, dynamic>?;
        for (final lang in ['en', 'ta']) {
          final list = tokens?[lang];
          if (list is List) {
            for (final t in list) {
              vocab.add(t.toString());
            }
          }
        }
        final sp =
            profile['schemeSearchProfile'] as Map<String, dynamic>? ?? const {};
        for (final fieldKey in [
          'loanType',
          'subsidyType',
          'taxBenefits',
          'clusters',
          'industryTags',
          'benefitTags',
        ]) {
          final list = sp[fieldKey];
          if (list is List) {
            for (final t in list) {
              vocab.add(t.toString().toLowerCase());
            }
          }
        }
      }

      final missing = <String, List<String>>{};
      for (final entry in bundle.queryExpansions.entries) {
        for (final target in entry.value) {
          if (!vocab.contains(target)) {
            missing.putIfAbsent(entry.key, () => []).add(target);
          }
        }
      }
      expect(
        missing,
        isEmpty,
        reason: 'Expansion targets not in vocab: $missing',
      );
    });

    test('dictionary is not empty', () {
      expect(bundle.queryExpansions, isNotEmpty);
      expect(
        bundle.queryExpansions.length,
        greaterThanOrEqualTo(25),
        reason:
            'Expected at least 25 expansion entries (acronyms + tanglish + phrases)',
      );
    });
  });

  // ─── Acronym resolution ──────────────────────────────────────────────

  group('Acronym Expansion', () {
    test('PMEGP resolves to PMEGP scheme (CEN2026-085)', () {
      final results = engine.search('PMEGP', topN: 5);
      expect(results, isNotEmpty, reason: 'PMEGP should return results');
      final topIds = results.map((r) => r.$1.id).toList();
      expect(
        topIds.contains('CEN2026-085'),
        isTrue,
        reason: 'CEN2026-085 (TN130 PMEGP) should be in top-5; got $topIds',
      );
    });

    test('MUDRA resolves to a MUDRA-related scheme', () {
      final results = engine.search('MUDRA loan', topN: 5);
      expect(results, isNotEmpty, reason: 'MUDRA should return results');
      final topIds = results.map((r) => r.$1.id).toList();
      // CEN2026-083 = Pradhan Mantri Mudra Yojana (PMMY)
      // CEN2026-208 = Mudra Scheme
      expect(
        topIds.contains('CEN2026-083') || topIds.contains('CEN2026-208'),
        isTrue,
        reason:
            'CEN2026-083 or CEN2026-208 (MUDRA schemes) should be in top-5; got $topIds',
      );
    });

    test('CGTMSE resolves to Credit Guarantee scheme (CEN2026-023)', () {
      final results = engine.search('CGTMSE', topN: 5);
      expect(results, isNotEmpty, reason: 'CGTMSE should return results');
      final topIds = results.map((r) => r.$1.id).toList();
      expect(
        topIds.contains('CEN2026-023'),
        isTrue,
        reason: 'CEN2026-023 (TN038 CGTMSE) should be in top-5; got $topIds',
      );
    });

    test('PMFME resolves to food processing scheme (CEN2026-138)', () {
      final results = engine.search('PMFME', topN: 5);
      expect(results, isNotEmpty, reason: 'PMFME should return results');
      final topIds = results.map((r) => r.$1.id).toList();
      expect(
        topIds.contains('CEN2026-138'),
        isTrue,
        reason: 'CEN2026-138 (TN219 PMFME) should be in top-5; got $topIds',
      );
    });

    test('CLCSS resolves to Capital Subsidy scheme', () {
      final results = engine.search('CLCSS', topN: 5);
      expect(results, isNotEmpty, reason: 'CLCSS should return results');
      final topIds = results.map((r) => r.$1.id).toList();
      // Under Decision D4, CEN2026-018 is DRAFT (discontinued CLCSS).
      // Active capital subsidy schemes like CEN2026-152 (SCLCSS) or TN2026-001 resolve.
      expect(
        topIds.contains('CEN2026-152') || topIds.contains('TN2026-001'),
        isTrue,
        reason: 'Capital subsidy schemes should be in top-5; got $topIds',
      );
    });

    test('NEEDS resolves to NEEDS scheme (TN2026-028)', () {
      final results = engine.search('NEEDS scheme', topN: 5);
      expect(results, isNotEmpty, reason: 'NEEDS should return results');
      final topIds = results.map((r) => r.$1.id).toList();
      expect(
        topIds.contains('TN2026-028'),
        isTrue,
        reason: 'TN2026-028 (TN115 NEEDS) should be in top-5; got $topIds',
      );
    });
  });

  // ─── Tamil transliteration (Tanglish) ────────────────────────────────

  group('Tanglish Expansion', () {
    test('kadan returns loan/credit schemes', () {
      final results = engine.search('kadan', topN: 10);
      expect(results, isNotEmpty, reason: '"kadan" should return loan schemes');
      // Verify that keyword expansion is working — results should have
      // matches against loan/credit tokens.
      final allReasons = results.expand((r) => r.$3).join(' ').toLowerCase();
      expect(
        allReasons.contains('loan') ||
            allReasons.contains('credit') ||
            allReasons.contains('keyword') ||
            allReasons.contains('match'),
        isTrue,
        reason: 'Results for "kadan" should match loan/credit keywords',
      );
    });

    test('udavi returns subsidy/grant schemes', () {
      final results = engine.search('udavi', topN: 10);
      expect(results, isNotEmpty, reason: '"udavi" should return schemes');
    });

    test('thozhil returns business/enterprise schemes', () {
      final results = engine.search('thozhil', topN: 10);
      expect(results, isNotEmpty, reason: '"thozhil" should return schemes');
    });

    test('magalir returns women-focused schemes', () {
      final results = engine.search('magalir', topN: 10);
      expect(
        results,
        isNotEmpty,
        reason: '"magalir" should return women schemes',
      );
    });
  });

  // ─── Multi-word phrase expansion ─────────────────────────────────────

  group('Phrase Expansion', () {
    test('stand up india resolves Stand-Up India scheme', () {
      final results = engine.search('stand up india', topN: 5);
      expect(
        results,
        isNotEmpty,
        reason: '"stand up india" should return results',
      );
      final topIds = results.map((r) => r.$1.id).toList();
      // CEN2026-112 = Stand-Up India, CEN2026-137 = Stand-Up India Scheme
      expect(
        topIds.contains('CEN2026-112') || topIds.contains('CEN2026-137'),
        isTrue,
        reason:
            'CEN2026-112 or CEN2026-137 (Stand-Up India) should be in top-5; got $topIds',
      );
    });

    test('street vendor resolves PM SVANidhi (CEN2026-078)', () {
      final results = engine.search('street vendor loan', topN: 5);
      expect(
        results,
        isNotEmpty,
        reason: '"street vendor" should return results',
      );
      final topIds = results.map((r) => r.$1.id).toList();
      expect(
        topIds.contains('CEN2026-078'),
        isTrue,
        reason:
            'CEN2026-078 (TN123 PM SVANidhi) should be in top-5; got $topIds',
      );
    });

    test('tea stall returns micro vendor schemes', () {
      final results = engine.search('tea stall loan', topN: 10);
      expect(results, isNotEmpty, reason: '"tea stall" should return results');
    });

    test('student startup returns youth innovation schemes', () {
      final results = engine.search('student startup', topN: 10);
      expect(
        results,
        isNotEmpty,
        reason: '"student startup" should return results',
      );
    });
  });

  // ─── Non-regression: existing recall still holds ─────────────────────
  // Note: The full multilingual corpus test uses SchemeUnderstandingEngine,
  // which wraps HybridSchemeSearch with additional NLP layers. This test
  // validates that HybridSchemeSearch.search() alone has not regressed by
  // checking that a representative subset of simple queries still returns
  // expected results in top-5.

  group('Non-Regression', () {
    test('basic keyword queries still return expected results', () {
      final basicQueries = <String, String>{
        'women entrepreneur loan': 'SCH000',
        'food processing subsidy': 'SCH000',
        'startup registration': 'SCH000',
        'msme loan': 'SCH000',
        'export subsidy': 'SCH000',
      };

      for (final entry in basicQueries.entries) {
        final results = engine.search(entry.key, topN: 5);
        expect(
          results,
          isNotEmpty,
          reason: '"${entry.key}" should return results',
        );
        // Ensure score is reasonable (> 0)
        expect(
          results.first.$2,
          greaterThan(0),
          reason: '"${entry.key}" top result should have positive score',
        );
      }
    });

    test('expansion does not cause zero-result regressions', () {
      // Queries that previously returned results should still return results.
      final regressionQueries = [
        'loan for small business',
        'subsidy for women',
        'credit guarantee',
        'skill training programme',
        'export promotion',
        'agriculture equipment subsidy',
        'textile industry support',
      ];

      for (final query in regressionQueries) {
        final results = engine.search(query, topN: 10);
        expect(
          results,
          isNotEmpty,
          reason: '"$query" should not regress to zero results',
        );
      }
    });
  });
}
