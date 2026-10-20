import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CentralizedTranslator C6 Dictionary Extraction Parity', () {
    test('asset translation_dictionary.json exists and is valid JSON', () {
      const paths = [
        'assets/catalog/translation_dictionary.json',
        'frontend/assets/catalog/translation_dictionary.json',
      ];
      File? found;
      for (final p in paths) {
        final f = File(p);
        if (f.existsSync()) {
          found = f;
          break;
        }
      }
      expect(
        found,
        isNotNull,
        reason: 'translation_dictionary.json should exist',
      );

      final content = found!.readAsStringSync();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded.containsKey('tagMap'), isTrue);
      expect(decoded.containsKey('phraseMap'), isTrue);
      expect(decoded.containsKey('termMap'), isTrue);

      final tags = decoded['tagMap'] as Map<String, dynamic>;
      final phrases = decoded['phraseMap'] as Map<String, dynamic>;
      final terms = decoded['termMap'] as Map<String, dynamic>;

      expect(tags.length, 117);
      expect(
        phrases.length,
        greaterThanOrEqualTo(428),
      ); // grows as UI text is added
      expect(terms.length, 141);
    });

    test('ensureLoaded() populates in-memory dictionary', () async {
      final translator = CentralizedTranslator.instance;
      await translator.ensureLoaded();
      expect(translator.isLoaded, isTrue);
    });

    test(
      'translateTag translates known tags into Tamil and retains unknown tags',
      () {
        final translator = CentralizedTranslator.instance;

        expect(translator.translateTag('Tamil Nadu'), 'தமிழ்நாடு');
        expect(translator.translateTag('Agriculture'), 'வேளாண்மை');
        expect(translator.translateTag('Women'), 'மகளிர்');
        expect(translator.translateTag('Loan'), 'கடன்');
        expect(translator.translateTag('Subsidy'), 'மானியம்');
        expect(translator.translateTag('Youth'), 'இளைஞர்கள்');
        expect(translator.translateTag('UnknownTagXYZ'), 'UnknownTagXYZ');
      },
    );

    test(
      'translate converts phrases and terms while preserving protected tokens',
      () {
        final translator = CentralizedTranslator.instance;

        // Known phrase
        expect(
          translator.translate('Government of India'),
          contains('இந்திய அரசு'),
        );
        expect(
          translator.translate('Ministry of Finance'),
          contains('நிதி அமைச்சகம்'),
        );
        expect(
          translator.translate('Aadhaar Card Proof'),
          contains('ஆதார் அட்டை சான்று'),
        );

        // Known term
        expect(translator.translate('Portal'), contains('தளம்'));

        // Protected tokens (URLs, emails, phone numbers)
        expect(
          translator.translate('Visit https://tnega.tn.gov.in for details'),
          contains('https://tnega.tn.gov.in'),
        );
        expect(
          translator.translate('Email helpdesk@tnega.gov.in'),
          contains('helpdesk@tnega.gov.in'),
        );

        // Numbers and currency
        expect(translator.translate('₹50,000 per year'), contains('₹50,000'));
      },
    );

    test('isProtectedText identifies emails, URLs, and code IDs', () {
      final translator = CentralizedTranslator.instance;

      expect(translator.isProtectedText('https://myscheme.gov.in'), isTrue);
      expect(translator.isProtectedText('admin@gov.in'), isTrue);
      expect(translator.isProtectedText('PM_KISAN_001'), isTrue);
      expect(translator.isProtectedText('Normal English sentence'), isFalse);
    });
  });
}
