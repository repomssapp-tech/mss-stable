// Guard: every chip a scheme card can show (category, scheme type, sector) must
// come out in Tamil / Hindi letters. When a catalog refresh brings new chip
// text, this fails with the list to add to assets/catalog/translation_dictionary
// (Tamil) and translation_dictionary_hi (Hindi) `tagMap`.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/utils/chip_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every catalog card chip is translated in Tamil and Hindi', () async {
    final all = await SchemeRepository.instance.getAllSchemes();
    final chips = <String>{};
    for (final s in all) {
      for (final field in [s.category, s.schemeType, s.sector]) {
        chips.addAll(splitChipList(field));
      }
    }
    expect(chips, isNotEmpty);

    // Three or more Latin letters in a row means an English word survived.
    final latin = RegExp(r'[A-Za-z]{3,}');
    for (final lang in ['ta', 'hi']) {
      final untranslated = [
        for (final c in chips)
          if (latin.hasMatch(
            CentralizedTranslator.instance.localizeTagFor(lang, c),
          ))
            c,
      ]..sort();
      expect(
        untranslated,
        isEmpty,
        reason:
            '$lang chips still contain English:\n${untranslated.join('\n')}',
      );
    }
  });
}
