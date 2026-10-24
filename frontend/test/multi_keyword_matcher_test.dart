import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/regular_mode/categories/discover_counts.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/utils/multi_keyword_matcher.dart';

/// What [MultiKeywordMatcher.matchesIn] must equal: one `contains` per keyword.
Set<int> _naive(List<String> keywords, String text) => {
  for (var i = 0; i < keywords.length; i++)
    if (text.contains(keywords[i])) i,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MultiKeywordMatcher', () {
    test('finds overlapping, nested and repeated keywords', () {
      const keywords = ['he', 'she', 'his', 'hers', 'her', 'e', 'z'];
      final m = MultiKeywordMatcher(keywords);
      for (final text in ['ushers', 'his', 'shhe', 'h', '', 'zz', 'hershe']) {
        expect(m.matchesIn(text), _naive(keywords, text), reason: text);
      }
    });

    test('multi-word, punctuation and non-Latin keywords', () {
      const keywords = [
        'self help group',
        'self-help',
        'women',
        'மகளிர்',
        'महिला',
        'r&d',
      ];
      final m = MultiKeywordMatcher(keywords);
      const text =
          'loans for women self help groups and r&d; மகளிர் குழு, महिला उद्यमी';
      expect(m.matchesIn(text), _naive(keywords, text));
      expect(m.matchesIn('self-hel'), isEmpty);
    });

    test('an empty keyword matches every text, like String.contains', () {
      final m = MultiKeywordMatcher(const ['', 'a']);
      expect(m.matchesIn(''), {0});
      expect(m.matchesIn('a'), {0, 1});
    });

    test('agrees with String.contains on random input', () {
      final rng = Random(7);
      String word(int max) => String.fromCharCodes(
        List.generate(1 + rng.nextInt(max), (_) => 97 + rng.nextInt(3)),
      );
      for (var round = 0; round < 200; round++) {
        final keywords = List.generate(1 + rng.nextInt(12), (_) => word(4));
        final text = word(40);
        expect(
          MultiKeywordMatcher(keywords).matchesIn(text),
          _naive(keywords, text),
          reason: '$keywords in "$text"',
        );
      }
    });
  });

  test(
    'Discover category counts match the per-keyword contains rule',
    () async {
      final schemes = await SchemeRepository.instance.getAllSchemes();
      expect(schemes, isNotEmpty);
      for (final label in DiscoverCounts.categoryLabels) {
        final keywords = DiscoverCounts.categoryKeywordsFor(label);
        final expected = schemes.where((s) {
          final hay =
              ('${s.name} ${s.shortName} ${s.category} ${s.schemeType} '
                      '${s.sector} ${s.targetBeneficiary} ${s.searchKeywords} '
                      '${s.overview} ${s.benefits}')
                  .toLowerCase();
          return keywords.any(hay.contains);
        }).length;
        expect(
          DiscoverCounts.schemesFor(label, 'category', schemes).length,
          expected,
          reason: label,
        );
      }
    },
  );
}
