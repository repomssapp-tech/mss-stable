import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/search/indic_stemmer.dart';

void main() {
  // Shared with saarthi-agent/tests/test_indic_search.py so the Dart and
  // Python stemmers cannot drift apart.
  final cases =
      jsonDecode(File('test/fixtures/indic_stem_cases.json').readAsStringSync())
          as List;

  for (final c in cases) {
    final word = c['word'] as String;
    test('stems $word', () {
      expect(indicStem(word), c['stem']);
    });
  }

  test('inflections of one word share a stem', () {
    expect(indicStem('महिला'), indicStem('महिलाओं'));
    expect(indicStem('திட்டம்'), indicStem('திட்டங்கள்'));
  });
}
