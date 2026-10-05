import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';

/// Result-engine behaviour tests for the offline scheme search that the
/// search bar actually calls (`HybridSchemeSearch.rank`, via
/// `SchemeRepository.searchSchemeMatchesOffline`):
///
///  * a scheme-name / acronym / alias query is a LOOKUP -- it returns that
///    scheme (or those schemes), never a spread of topically-adjacent ones;
///  * a broad/intent query returns a tightly-bounded, text-relevance list;
///  * an unmatched query returns nothing (the UI then says "not available");
///  * results never depend on the user's profile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  late HybridSchemeSearch engine;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    engine = await HybridSchemeSearch.build(bundle);
  });

  Future<List<String>> ids(String q, {int? limit}) async {
    final matches = await HybridSchemeSearch.rank(q, bundle, limit: limit);
    return matches.map((m) => m.scheme.id).toList();
  }

  group('Exact-entity lookup', () {
    test('acronym query returns only that scheme', () async {
      expect(await ids('PMEGP'), ['SCH000130']);
      expect(await ids('NEEDS'), ['SCH000115']);
    });

    test('acronym lookup is case- and whitespace-insensitive', () async {
      expect(await ids('pmegp'), ['SCH000130']);
      expect(await ids('  PMEGP  '), ['SCH000130']);
      expect(await ids('PmEgP'), ['SCH000130']);
    });

    test('near-exact multi-word name returns that scheme', () async {
      expect(await ids('Women Entrepreneurship Platform'), contains('SCH000212'));
      // Under Decision D4, SCH000009 is DRAFT; test against active bundled SCH000255
      final mcgs = await ids('Mutual Credit Guarantee Scheme');
      expect(mcgs, contains('SCH000255'));
    });

    test('exactEntityMatches is empty for a broad/intent query', () {
      expect(engine.exactEntityMatches('women entrepreneur schemes'), isEmpty);
      expect(engine.exactEntityMatches('msme loans'), isEmpty);
      expect(engine.exactEntityMatches('working capital'), isEmpty);
    });
  });

  group('Broad queries stay lists, ranked by relevance', () {
    test('"women entrepreneur schemes" -> women-enterprise schemes, '
        'no marriage-assistance scheme, bounded', () async {
      final r = await ids('women entrepreneur schemes');
      expect(r.length, greaterThan(3));
      expect(r.length, lessThanOrEqualTo(25));
      // E.V.R. Maniyammaiyar Ninaivu Marriage Assistance -- carries no
      // women/entrepreneur signal; must not surface here.
      expect(r.take(10), isNot(contains('SCH000051')));
      // At least one genuine women-enterprise scheme near the top.
      const womenBiz = {
        'SCH000087', 'SCH000088', 'SCH000086', 'SCH000212', 'SCH000218',
        'SCH000168', 'SCH000195', 'SCH000052', 'SCH000199', 'SCH000198',
        'SCH000184', 'SCH000139', 'SCH000029', 'SCH000044',
      };
      expect(r.take(6).any(womenBiz.contains), isTrue,
          reason: 'top-6 had no women-enterprise scheme: ${r.take(6)}');
    });

    test('"MSME Loans" -> loan/credit schemes on top', () async {
      final r = await ids('MSME Loans');
      expect(r, isNotEmpty);
      expect(r.take(5), isNot(contains('SCH000051')));
      const loanish = {
        'loan', 'credit_guarantee', 'credit_linked_subsidy',
        'interest_subvention', 'credit', 'guarantee',
      };
      final top5 = r.take(5).toList();
      var loanCount = 0;
      for (final id in top5) {
        final scheme = bundle.schemes.firstWhere((e) => e.id == id);
        final content = scheme.raw['content'] as Map<String, dynamic>?;
        final classification =
            content?['classification'] as Map<String, dynamic>?;
        final schemeType =
            (classification?['schemeType'] ?? '').toString().toLowerCase();
        final benefits = content?['benefits'] as Map<String, dynamic>?;
        final benefitTypes = ((benefits?['benefitTypes'] as List?) ?? const [])
            .map((e) => e.toString().toLowerCase())
            .toList();
        final isLoan = loanish.any(schemeType.contains) ||
            benefitTypes.any((b) =>
                b.contains('loan') ||
                b.contains('guarantee') ||
                b.contains('interest') ||
                b.contains('credit'));
        if (isLoan) loanCount++;
      }
      expect(loanCount, greaterThanOrEqualTo(4),
          reason: 'At least 4 of top 5 must be loan/credit schemes');
    });

    test('every returned result clears the relative relevance floor', () async {
      final matches = await HybridSchemeSearch.rank('cluster development', bundle);
      expect(matches, isNotEmpty);
      final top = matches.first.score;
      for (final m in matches) {
        expect(m.score, greaterThanOrEqualTo(top * 0.35 - 1e-9),
            reason: '${m.scheme.id} @ ${m.score} is below 0.35 * $top');
      }
    });
  });

  group('No-result behaviour', () {
    test('unrelated gibberish returns nothing', () async {
      expect(await ids('zzzq nonsense xyzzy'), isEmpty);
    });

    test('a plausible but absent scheme name returns nothing', () async {
      expect(await ids('Rajiv Gandhi Shramik Kalyan Yojana'), isEmpty);
    });

    test('empty / whitespace query returns nothing', () async {
      expect(await ids(''), isEmpty);
      expect(await ids('   '), isEmpty);
    });
  });

  test('limit is respected by the lookup path', () async {
    // "stand up india" tier-3 matches the duplicate pair SCH000168/218.
    final all = await ids('Stand Up India Scheme');
    expect(all.length, greaterThanOrEqualTo(1));
    final capped = await ids('Stand Up India Scheme', limit: 1);
    expect(capped.length, 1);
  });
}
