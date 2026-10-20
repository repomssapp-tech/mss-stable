import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the in-app wording (ARB + translation dictionaries) on the terms the
/// scheme catalog itself uses, so a scheme's own translated text and the app's
/// labels around it read the same. The preferred forms were read off the catalog:
/// Tamil writes MSME in Latin letters and women as "மகளிர்"; Hindi says
/// "दिव्यांग", "अवसंरचना" and "महिला".
void main() {
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final ta = readJson('lib/l10n/app_ta.arb');
  final hi = readJson('lib/l10n/app_hi.arb');
  final taDict = readJson('assets/catalog/translation_dictionary.json');
  final hiDict = readJson('assets/catalog/translation_dictionary_hi.json');

  String taTag(String key) => (taDict['tagMap'] as Map)[key] as String;
  String hiTag(String key) => (hiDict['tagMap'] as Map)[key] as String;

  group('Tamil', () {
    test('MSME stays MSME, as in the catalog', () {
      expect(ta['catBusinessMsme'], contains('MSME'));
      expect(ta['udyamModuleDescription'], contains('MSME'));
      expect(taTag('msme'), 'MSME');
    });

    test('women entrepreneurs use "மகளிர்"', () {
      expect(ta['forWomenEntrepreneurs'], startsWith('மகளிர்'));
      expect(ta['catWomenEntrepreneurship'], 'மகளிர் தொழில்முனைவு');
      expect(taTag('women entrepreneurs'), 'மகளிர் தொழில்முனைவோர்');
      expect(taTag('women entrepreneurship'), 'மகளிர் தொழில்முனைவு');
      expect(ta['filterBenWomen'], 'மகளிர்');
    });

    test('no label uses a variant the catalog avoids', () {
      const avoided = ['எம்எஸ்எம்இ', 'பெண் தொழில்முனைவோ', 'கதர்', 'வரவு'];
      for (final e in ta.entries) {
        if (e.key.startsWith('@') || e.value is! String) continue;
        for (final w in avoided) {
          expect(e.value, isNot(contains(w)), reason: '${e.key} uses "$w"');
        }
      }
    });

    test('a category title never repeats one word for two meanings', () {
      expect(ta['catArtisanCraftsmen'], isNot('கைவினைஞர்கள் & கைவினைஞர்கள்'));
    });

    test('every state and union territory has a Tamil name', () {
      for (final s in ['assam', 'goa', 'kerala', 'ladakh', 'puducherry']) {
        expect(taDict['tagMap'], contains(s));
      }
    });
  });

  group('Hindi', () {
    test('uses the official or catalog term', () {
      expect(hi['filterBenWomen'], 'महिला');
      expect(hi['filterBenDifferentlyAbled'], 'दिव्यांग');
      expect(hi['filterTypeInfra'], 'अवसंरचना');
      expect(hi['catInfrastructureLogistics'], 'अवसंरचना एवं लॉजिस्टिक्स');
      expect(hiTag('business & msme'), hi['catBusinessMsme']);
      expect(hiTag('msme'), 'एमएसएमई');
      expect(hiTag('women entrepreneurs'), 'महिला उद्यमी');
    });

    test('no label uses a colloquial or literal variant', () {
      const avoided = ['औरत', 'अलग रूप से सक्षम', 'बुनियादी ढाँचा', 'उधार'];
      for (final e in hi.entries) {
        if (e.key.startsWith('@') || e.value is! String) continue;
        for (final w in avoided) {
          expect(e.value, isNot(contains(w)), reason: '${e.key} uses "$w"');
        }
      }
    });

    test('every state and union territory has a Hindi name', () {
      for (final s in ['assam', 'goa', 'kerala', 'ladakh', 'puducherry']) {
        expect(hiDict['tagMap'], contains(s));
      }
    });
  });
}
