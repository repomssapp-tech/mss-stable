import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';

void main() {
  final t = CentralizedTranslator.instance;

  Map<String, dynamic> loadHi() =>
      jsonDecode(
            File(
              'assets/catalog/translation_dictionary_hi.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('Hindi dictionary', () {
    test('covers every key the Tamil dictionary covers', () {
      final ta =
          jsonDecode(
                File(
                  'assets/catalog/translation_dictionary.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final hi = loadHi();
      for (final map in ['tagMap', 'phraseMap']) {
        final missing = (ta[map] as Map).keys
            .where((k) => !(hi[map] as Map).containsKey(k))
            .toList();
        expect(missing, isEmpty, reason: '$map missing Hindi entries');
      }
    });

    test('every Hindi value is non-empty Devanagari-bearing text', () {
      final hi = loadHi();
      final devanagari = RegExp(r'[\u0900-\u097F]');
      for (final map in ['tagMap', 'phraseMap']) {
        for (final e in (hi[map] as Map).entries) {
          expect(e.value as String, matches(devanagari), reason: e.key);
        }
      }
    });

    test('numbers and URLs in the English key survive into Hindi', () {
      final hi = loadHi();
      for (final e in (hi['phraseMap'] as Map).entries) {
        final key = e.key as String;
        final value = e.value as String;
        for (final m in RegExp(r'\d+').allMatches(key)) {
          final ordinal = RegExp(
            r'^(st|nd|rd|th)\b',
          ).hasMatch(key.substring(m.end));
          final forms = {
            '1': ['पहला', 'पहली', 'पहले', 'प्रथम'],
            '2': ['दूसरा', 'दूसरी', 'दूसरे', 'द्वितीय'],
            '3': ['तीसरा', 'तीसरी', 'तीसरे', 'तृतीय'],
            '4': ['चौथा', 'चौथी', 'चौथे', 'चतुर्थ'],
          };
          if (ordinal && (forms[m[0]] ?? const <String>[]).any(value.contains))
            continue;
          expect(value, contains(m.group(0)!), reason: key);
        }
        for (final m in RegExp(r'[a-z0-9.-]+\.gov\.in').allMatches(key)) {
          expect(value, contains(m.group(0)!), reason: key);
        }
      }
    });
  });

  group('CentralizedTranslator language-aware lookup', () {
    setUpAll(() async {
      await t.ensureLoaded();
    });

    test('hi translates known UI phrases and tags', () {
      expect(t.localizeFor('hi', 'Base Amount'), 'मूल राशि');
      expect(t.localizeFor('hi', 'GST Rate (%)'), 'जीएसटी दर (%)');
      expect(t.localizeTagFor('hi', 'Tamil Nadu'), 'तमिलनाडु');
      expect(t.localizeFor('hi', 'Tamil Nadu'), 'तमिलनाडु');
    });

    test('hi is case/space tolerant and leaves unknown text in English', () {
      expect(t.localizeFor('hi', '  base amount '), 'मूल राशि');
      expect(
        t.localizeFor('hi', 'Some brand new sentence'),
        'Some brand new sentence',
      );
    });

    test('hi never touches URLs, emails or scheme codes', () {
      expect(
        t.localizeFor('hi', 'https://udyamregistration.gov.in'),
        'https://udyamregistration.gov.in',
      );
      expect(t.localizeFor('hi', 'help@msme.gov.in'), 'help@msme.gov.in');
      expect(t.localizeFor('hi', 'SCH000006'), 'SCH000006');
    });

    test('en returns the input and ta still uses the Tamil pipeline', () {
      expect(t.localizeFor('en', 'Base Amount'), 'Base Amount');
      expect(t.localizeFor('ta', 'Base Amount'), t.translate('Base Amount'));
      expect(t.localizeFor('ta', 'Base Amount'), isNot('Base Amount'));
      expect(t.localizeFor('hi', null), '');
    });

    test('localize follows activeLanguage', () {
      final saved = t.activeLanguage;
      addTearDown(() => t.activeLanguage = saved);
      t.activeLanguage = 'hi';
      expect(t.localize('Cancel'), 'रद्द करें');
      t.activeLanguage = 'en';
      expect(t.localize('Cancel'), 'Cancel');
    });
  });

  test('every literal passed to localize()/localizeTag() has a Hindi entry', () {
    final hi = loadHi();
    final known = <String>{
      ...(hi['phraseMap'] as Map).keys.cast<String>(),
      ...(hi['tagMap'] as Map).keys.cast<String>(),
    };
    final call = RegExp(
      r'''\.localize(?:Tag)?\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")\s*,?\s*\)''',
    );
    final missing = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final src = file.readAsStringSync();
      for (final m in call.allMatches(src)) {
        final raw = (m.group(1) ?? m.group(2))!;
        if (raw.contains(r'$')) continue; // interpolated, checked at runtime
        final text = raw.replaceAll(r"\'", "'").replaceAll(r'\n', '\n');
        if (!known.contains(text.trim().toLowerCase())) {
          missing.add('${file.path}: $text');
        }
      }
    }
    expect(missing, isEmpty);
  });
}
