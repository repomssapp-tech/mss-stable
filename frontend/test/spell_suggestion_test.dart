import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';
import 'package:frontend/services/search/spell_suggester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpellSuggester', () {
    final speller = SpellSuggester({
      'apple': 5,
      'loan': 40,
      'loans': 3,
      'subsidy': 30,
      'women': 25,
      'cen2026-001': 1,
      'कर्ज': 4,
      'प्रशिक्षण': 12,
      'கடன்': 20,
      'ஏற்றுமதி': 9,
    });

    test('"aple" becomes "apple"', () {
      expect(speller.suggest('aple'), 'apple');
    });

    test('a swapped pair of letters is one edit', () {
      expect(speller.suggest('laon'), 'loan');
    });

    test('only the unknown word changes; the rest of the query is kept', () {
      expect(speller.suggest('Loan for womne'), 'Loan for women');
    });

    test('a correctly spelled query gets no suggestion', () {
      expect(speller.suggest('loan'), isNull);
      expect(speller.suggest('subsidy for women'), isNull);
    });

    test('plural / singular of a known word is not "corrected"', () {
      expect(speller.suggest('subsidys'), isNull); // "subsidy" + s
      expect(speller.suggest('loans'), isNull);
      expect(speller.suggest('womens'), isNull); // "women" + s
    });

    test('very short words and ids are never touched', () {
      expect(speller.suggest('lo'), isNull);
      expect(speller.suggest('cen2026-002'), isNull);
    });

    test('a word far from every catalog word is left alone', () {
      expect(speller.suggest('zebra'), isNull);
    });

    test('two edits need the same first letter', () {
      // Both are two edits from "subsidy"; only the one that keeps the first
      // letter is accepted.
      expect(speller.suggest('sybsidi'), 'subsidy');
      expect(speller.suggest('xubsidi'), isNull);
    });

    test('the more common word wins a tie', () {
      final s = SpellSuggester({'cats': 1, 'cars': 50});
      expect(s.suggest('caps'), 'cars');
    });

    test('Hindi and Tamil words are corrected on code points', () {
      expect(speller.suggest('प्रशिक्षन'), 'प्रशिक्षण');
      expect(speller.suggest('ஏற்றுமதீ'), 'ஏற்றுமதி');
      expect(speller.suggest('கடன்'), isNull);
    });
  });

  group('HybridSchemeSearch.didYouMean over the real catalog', () {
    late MssCatalogBundle bundle;
    late HybridSchemeSearch engine;

    setUpAll(() async {
      bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
      engine = await HybridSchemeSearch.build(bundle);
    });

    test('common typos are corrected to a query that finds schemes', () {
      for (final (typo, fixed) in const [
        ('laon', 'loan'),
        ('subsidey', 'subsidy'),
        ('startap', 'startup'),
        ('entreprenuer', 'entrepreneur'),
      ]) {
        final suggestion = engine.didYouMean(typo);
        expect(suggestion, fixed, reason: typo);
        expect(engine.search(suggestion!, topN: 1), isNotEmpty, reason: typo);
      }
    });

    test('a typo inside a longer query is fixed, the rest is kept', () {
      expect(
        engine.didYouMean('women entreprenuer loan'),
        'women entrepreneur loan',
      );
    });

    test('a scheme name or acronym typed correctly is never altered', () {
      expect(engine.didYouMean('PMEGP'), isNull);
      expect(engine.didYouMean('mudra'), isNull);
    });

    test(
      'correctly spelled English, Hindi and Tamil queries are not changed',
      () {
        const queries = [
          'loan',
          'subsidy',
          'training',
          'women entrepreneur',
          'food processing',
          'credit guarantee',
          'ऋण',
          'सब्सिडी',
          'प्रशिक्षण',
          'महिला उद्यमी',
          'खाद्य प्रसंस्करण',
          'கடன்',
          'மானியம்',
          'பயிற்சி',
          'பெண் தொழில்முனைவோர்',
          'உணவு பதப்படுத்துதல்',
        ];
        for (final q in queries) {
          expect(engine.didYouMean(q), isNull, reason: q);
        }
      },
    );

    test('empty and whitespace queries give no suggestion', () {
      expect(engine.didYouMean(''), isNull);
      expect(engine.didYouMean('   '), isNull);
    });
  });

  // Kept out of the widget tests: the repository caches its bundle future,
  // and one first loaded inside a testWidgets fake-async zone never completes.
  group('SchemeRepository.suggestQueryCorrection', () {
    test('corrects a typo from the real catalog vocabulary', () async {
      expect(
        await SchemeRepository.instance.suggestQueryCorrection('laon'),
        'loan',
      );
    });

    test('leaves a correct query alone', () async {
      expect(
        await SchemeRepository.instance.suggestQueryCorrection('loan'),
        isNull,
      );
    });
  });
}
