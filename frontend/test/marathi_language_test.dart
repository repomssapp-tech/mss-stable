import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/catalog/catalog_language_fill.dart';
import 'package:frontend/services/recommendation/indian_states.dart';
import 'package:frontend/services/recommendation/profile_canonicalizer.dart';
import 'package:frontend/services/search/indic_search_support.dart';
import 'package:frontend/services/search/indic_stemmer.dart';
import 'package:frontend/widgets/assistant/smart_assessment/assessment_question_flows.dart';

Map<String, dynamic> _scheme(String id, Map<String, dynamic> localization) => {
  'identity': {'id': id},
  'localization': localization,
  'search': {
    'aliases': {'en': <String>[]},
    'keywords': {'en': <String>[]},
  },
  'content': {
    'benefitFacts': {
      'facts': [
        {'type': 'max'},
      ],
    },
  },
};

/// Through JSON so the maps have the types a parsed catalog has.
Map<String, dynamic> _bundle(List<Map<String, dynamic>> rows) =>
    jsonDecode(
          jsonEncode({
            'scheme_catalog.json': {'data': rows},
          }),
        )
        as Map<String, dynamic>;

void main() {
  group('profile labels', () {
    test('a label tapped in Marathi reads the same as English', () {
      final mr = lookupAppLocalizations(const Locale('mr'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(ProfileCanonicalizer.gender(mr.genderFemale), en.genderFemale);
      expect(ProfileCanonicalizer.gender(mr.genderMale), en.genderMale);
    });
  });

  group('state names', () {
    test('Marathi spellings resolve to the English catalog name', () {
      expect(IndianStates.canonical('तमिळनाडू'), 'Tamil Nadu');
      expect(IndianStates.canonical('केरळ'), 'Kerala');
      expect(IndianStates.code('छत्तीसगड'), 'IN-CT');
    });

    test('Marathi display keeps Marathi spelling, Hindi is unchanged', () {
      expect(IndianStates.displayName('Tamil Nadu', 'mr'), 'तमिळनाडू');
      expect(IndianStates.displayName('Maharashtra', 'mr'), 'महाराष्ट्र');
      expect(IndianStates.displayName('Tamil Nadu', 'hi'), 'तमिलनाडु');
    });
  });

  group('state questions', () {
    for (final (code, name) in const [
      ('mr', 'महाराष्ट्र'),
      ('hi', 'महाराष्ट्र'),
      ('ta', 'மகாராஷ்டிரா'),
    ]) {
      test('$code carries the state name in $code', () {
        final flow = getStateFlow(
          'Maharashtra',
          lookupAppLocalizations(const Locale('en')),
          lookupAppLocalizations(Locale(code)),
        );
        expect(flow['state_q1']!.questionTextTa, contains(name));
      });
    }
  });

  group('search', () {
    test('Marathi postpositions meet the plain word', () {
      expect(indicStem('महिलांसाठी'), indicStem('महिला'));
      expect(indicStem('उद्योगामध्ये'), indicStem('उद्योग'));
    });

    test('Hindi words that merely end alike keep their stem', () {
      expect(indicStem('महिला'), hindiStem('महिला'));
      expect(indicStem('चाचा'), hindiStem('चाचा'));
    });

    test("a scheme's Marathi text is indexed", () {
      final tokens = indicTextTokens({
        'mr': {'summary': 'उद्योजकांसाठी अनुदान'},
      }, (text) => text.split(' '));
      expect(tokens, contains('अनुदान'));
    });
  });

  group('server release without Marathi', () {
    test('finds only languages the whole release lacks', () {
      final bundle = _bundle([
        _scheme('A', {'en': {}, 'hi': {}}),
        _scheme('B', {'en': {}, 'ta': {}}),
      ]);
      expect(languagesAbsentFrom(bundle, ['en', 'hi', 'ta', 'mr']), {'mr'});
    });

    test('copies the language onto matching schemes only', () {
      final bundle = _bundle([
        _scheme('A', {
          'en': {'name': 'server name'},
        }),
        _scheme('NEW', {
          'en': {'name': 'added on server'},
        }),
      ]);
      final pack = _bundle([
        {
          'identity': {'id': 'A'},
          'localization': {
            'en': {'name': 'old shipped name'},
            'mr': {'name': 'मराठी नाव'},
          },
          'search': {
            'aliases': {
              'mr': ['उपनाव'],
            },
            'keywords': {
              'mr': ['शब्द'],
            },
          },
          'content': {
            'benefitFacts': {
              'facts': [
                {
                  'translations': {
                    'mr': {'basis': 'आधार'},
                  },
                },
              ],
            },
          },
        },
      ]);
      expect(fillLanguagesFromPack(bundle, pack, {'mr'}), 1);
      final rows = ((bundle['scheme_catalog.json'] as Map)['data'] as List)
          .cast<Map<String, dynamic>>();
      expect(rows[0]['localization']['mr']['name'], 'मराठी नाव');
      expect(rows[0]['localization']['en']['name'], 'server name');
      expect(rows[0]['search']['aliases']['mr'], ['उपनाव']);
      expect(
        rows[0]['content']['benefitFacts']['facts'][0]['translations']['mr'],
        {'basis': 'आधार'},
      );
      expect((rows[1]['localization'] as Map).containsKey('mr'), isFalse);
    });

    Map<String, dynamic> shippedDocuments() => _bundle([
      {
        'identity': {'id': 'A'},
        'localization': {
          'ta': {
            'documents': ['ஆதார் அட்டை'],
          },
          'hi': {
            'documents': ['आधार'],
          },
        },
        'content': {
          'requiredDocuments': [
            {
              'mandatory': 'required',
              'name': {'en': 'Aadhaar card'},
            },
          ],
        },
      },
    ]);

    test('an unchanged document list gains the shipped translations', () {
      final bundle = _bundle([
        {
          'identity': {'id': 'A'},
          'localization': {'en': {}, 'ta': {}},
          'content': {
            'requiredDocuments': [
              {'mandatory': 'unknown', 'name': 'Aadhaar card'},
            ],
          },
        },
      ]);
      expect(fillDocumentsFromPack(bundle, shippedDocuments()), 1);
      final row = ((bundle['scheme_catalog.json'] as Map)['data'] as List).first;
      expect(row['localization']['ta']['documents'], ['ஆதார் அட்டை']);
      expect((row['localization'] as Map).containsKey('hi'), isFalse);
      expect(row['content']['requiredDocuments'][0]['mandatory'], 'required');
    });

    test('documents the server already translates are left alone', () {
      final bundle = _bundle([
        {
          'identity': {'id': 'A'},
          'localization': {
            'ta': {
              'documents': ['சர்வரில் திருத்தியது'],
            },
          },
          'content': {
            'requiredDocuments': [
              {
                'mandatory': 'optional',
                'name': {'en': 'Aadhaar card', 'ta': 'சர்வரில் திருத்தியது'},
              },
            ],
          },
        },
      ]);
      expect(fillDocumentsFromPack(bundle, shippedDocuments()), 0);
      final row = ((bundle['scheme_catalog.json'] as Map)['data'] as List).first;
      expect(row['localization']['ta']['documents'], ['சர்வரில் திருத்தியது']);
      expect(row['content']['requiredDocuments'][0]['mandatory'], 'optional');
    });

    test('a document list edited on the server stays as it is', () {
      final bundle = _bundle([
        {
          'identity': {'id': 'A'},
          'localization': {'ta': {}},
          'content': {
            'requiredDocuments': [
              {'name': 'Edited on server'},
            ],
          },
        },
      ]);
      expect(fillDocumentsFromPack(bundle, shippedDocuments()), 0);
      final row = ((bundle['scheme_catalog.json'] as Map)['data'] as List).first;
      expect(row['content']['requiredDocuments'][0]['name'], 'Edited on server');
    });

    test('a language outside the request is not copied', () {
      final bundle = _bundle([
        _scheme('A', {'en': {}}),
      ]);
      final pack = _bundle([
        {
          'identity': {'id': 'A'},
          'localization': {
            'hi': {'name': 'हिंदी'},
          },
        },
      ]);
      expect(fillLanguagesFromPack(bundle, pack, {'mr'}), 0);
    });
  });

  group('shipped Marathi strings', () {
    test('cover every English key and keep placeholders', () {
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final mr =
          jsonDecode(File('lib/l10n/app_mr.arb').readAsStringSync())
              as Map<String, dynamic>;
      final placeholder = RegExp(r'\{(\w+)');
      for (final key in en.keys.where((k) => !k.startsWith('@'))) {
        expect(mr.containsKey(key), isTrue, reason: key);
        expect(
          placeholder.allMatches(mr[key] as String).map((m) => m[1]).toSet(),
          placeholder.allMatches(en[key] as String).map((m) => m[1]).toSet(),
          reason: key,
        );
      }
    });
  });
}
