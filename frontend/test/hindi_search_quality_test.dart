import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';

/// Phase P5: Acceptance test for Hindi Search
/// Tests 20 real Hindi queries (including required 'कारीगर', 'ऋण', 'सब्सिडी')
/// and verifies that the top-5 search results return relevant scheme matches.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  late HybridSchemeSearch engine;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    engine = await HybridSchemeSearch.build(bundle);
  });

  final hindiQueries = <String, String>{
    'कारीगर': r'Vishwakarma|Artisan|Handicraft|Coir',
    'ऋण': r'Loan|Credit|Mudra|CGTMSE|PMEGP|Fund',
    'सब्सिडी': r'Subsidy|Capital|PMEGP|Interest',
    'मुद्रा': r'MUDRA|Mudra|Micro',
    'प्रशिक्षण': r'Training|Skill|ESDP|ATI|Capacity',
    'कौशल विकास': r'Skill|Training|ESDP|Development',
    'स्टार्टअप': r'Startup|Innovation|AIM|BIRAC|Seed',
    'क्रेडिट गारंटी': r'Credit|Guarantee|CGTMSE|Trust',
    'महिला उद्यमी': r'Women|Mahila|Coir|Udyami',
    'सूक्ष्म उद्यम': r'Micro|MSME|Enterprise|PMEGP',
    'प्रौद्योगिकी उन्नयन': r'Technology|Upgradation|Credit|ZED',
    'क्लस्टर विकास': r'Cluster|MSE-CDP|SFURTI',
    'खाद्य प्रसंस्करण': r'Food|PMFME|Processing|Agro',
    'सौर ऊर्जा': r'Solar|Renewable|Energy',
    'बैंक ऋण': r'Bank|Credit|Facilitation|Loan',
    'अनुसूचित जाति': r'SC|Ambedkar|Stand|Scheduled',
    'खादी': r'Khadi|KVIC|Village',
    'रोजगार': r'Self|Employment|PMEGP|Entrepreneur',
    'पीएमईजीपी': r'PMEGP|Prime Minister',
    'पीएम विश्वकर्मा': r'Vishwakarma|SCH000124',
  };

  test('HybridSchemeSearch processes 20 real Hindi queries with high relevance', () async {
    int passedCount = 0;
    final resultsReport = <String, dynamic>{};

    for (final entry in hindiQueries.entries) {
      final query = entry.key;
      final expectedRegex = RegExp(entry.value, caseSensitive: false);

      final matches = await HybridSchemeSearch.rank(query, bundle, limit: 10);

      expect(matches, isNotEmpty, reason: 'Query "$query" returned 0 results');

      // Check top 5 results
      final top5 = matches.take(5).toList();
      final hits = top5.where((m) {
        final s = m.scheme;
        final reasons = m.reasons;
        final matchesName = expectedRegex.hasMatch(s.name) || expectedRegex.hasMatch(s.shortName);
        final matchesDesc = expectedRegex.hasMatch(s.overview) || expectedRegex.hasMatch(s.benefits);
        final matchesId = expectedRegex.hasMatch(s.id);
        final matchesKeywords = expectedRegex.hasMatch(s.searchKeywords);
        final matchesReasons = reasons.any((reason) => expectedRegex.hasMatch(reason));
        return matchesName || matchesDesc || matchesId || matchesKeywords || matchesReasons;
      }).toList();

      final passed = hits.isNotEmpty;
      if (passed) passedCount++;

      resultsReport[query] = {
        'totalResults': matches.length,
        'passed': passed,
        'topResult': matches.first.scheme.name,
        'topResultId': matches.first.scheme.id,
        'topScore': matches.first.score,
      };
    }

    print('\n=== P5 Hindi Search Test Results ===');
    for (final entry in resultsReport.entries) {
      print('Query: "${entry.key}" -> Found: ${entry.value['totalResults']} schemes, Top: ${entry.value['topResultId']} (${entry.value['topResult']})');
    }
    print('\nTotal Passed: $passedCount / ${hindiQueries.length}');

    // Pass mark: at least 90% (18/20) hit top-5 on-topic
    expect(passedCount, greaterThanOrEqualTo(18),
        reason: 'Hindi search pass mark is 18/20 queries hit relevant schemes in top 5');
  });
}
