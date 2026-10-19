import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/adapter/scheme_adapter_text_utils.dart';
import 'package:frontend/services/catalog/content_language_resolver.dart';

void main() {
  group('ContentLanguageResolver.text fallback chain', () {
    const map = {'en': 'English', 'hi': 'हिन्दी', 'ta': 'தமிழ்'};

    test('selected language wins when present', () {
      expect(ContentLanguageResolver.text(map, 'hi'), 'हिन्दी');
      expect(ContentLanguageResolver.text(map, 'ta'), 'தமிழ்');
    });

    test('missing selected language falls back to English', () {
      expect(ContentLanguageResolver.text({'en': 'English'}, 'ta'), 'English');
      expect(
        ContentLanguageResolver.text({'en': 'English', 'ta': 'தமிழ்'}, 'hi'),
        'English',
      );
    });

    test('English user is never shown Tamil ahead of another source', () {
      // Previously an empty `en` made an English user see `ta` first.
      expect(
        ContentLanguageResolver.text({'en': '', 'hi': 'हिन्दी', 'ta': 'தமிழ்'}),
        'हिन्दी',
      );
    });

    test('empty selected value falls through to English, not empty text', () {
      expect(
        ContentLanguageResolver.text({'en': 'English', 'hi': '  '}, 'hi'),
        'English',
      );
    });

    test('content-only languages (mr) are used when nothing else exists', () {
      expect(ContentLanguageResolver.text({'mr': 'मराठी'}, 'ta'), 'मराठी');
    });

    test('never stringifies a Map or List', () {
      expect(ContentLanguageResolver.text({'a': 1, 'b': 2}), '');
      expect(
        ContentLanguageResolver.text({
          'en': {'x': 1},
        }),
        '',
      );
      expect(ContentLanguageResolver.text(<String, Object>{}), '');
      expect(
        ContentLanguageResolver.text({
          'en': ['one', 'two'],
        }),
        'one\n• two',
      );
    });

    test('null, blanks and unknown types yield empty text', () {
      expect(ContentLanguageResolver.text(null), '');
      expect(ContentLanguageResolver.text('   '), '');
      expect(ContentLanguageResolver.text(Object()), '');
    });

    test('plain object with text keys resolves (non-language map)', () {
      expect(
        ContentLanguageResolver.text({'description': 'Desc', 'x': 1}),
        'Desc',
      );
    });
  });

  group('ContentLanguageResolver.list / pickLanguage / normalizeCode', () {
    test('list picks one language\'s list with English fallback', () {
      const v = {
        'en': ['a', 'b'],
        'ta': ['x'],
      };
      expect(ContentLanguageResolver.list(v, 'ta'), ['x']);
      expect(ContentLanguageResolver.list(v, 'hi'), ['a', 'b']);
      expect(ContentLanguageResolver.list('solo'), ['solo']);
      expect(ContentLanguageResolver.list(null), isEmpty);
    });

    test('normalizeCode handles locales, case and junk', () {
      expect(ContentLanguageResolver.normalizeCode('ta-IN'), 'ta');
      expect(ContentLanguageResolver.normalizeCode(' HI '), 'hi');
      expect(ContentLanguageResolver.normalizeCode('en_US'), 'en');
      expect(ContentLanguageResolver.normalizeCode(null), 'en');
      expect(ContentLanguageResolver.normalizeCode(''), 'en');
    });

    test('pickLanguage: selected, record default, English, then registry', () {
      expect(ContentLanguageResolver.pickLanguage(['en', 'ta'], 'ta'), 'ta');
      expect(ContentLanguageResolver.pickLanguage(['en', 'ta'], 'hi'), 'en');
      expect(
        ContentLanguageResolver.pickLanguage(
          ['hi', 'mr'],
          'ta',
          recordDefault: 'mr',
        ),
        'mr',
      );
      expect(ContentLanguageResolver.pickLanguage(['mr'], 'ta'), 'mr');
      expect(ContentLanguageResolver.pickLanguage([], 'ta'), isNull);
    });
  });

  test('SchemeAdapterTextUtils.getLocalizedText delegates to the resolver', () {
    expect(
      SchemeAdapterTextUtils.getLocalizedText({'en': 'E', 'ta': 'T'}, 'ta'),
      'T',
    );
    expect(SchemeAdapterTextUtils.getLocalizedText({'ta': 'T'}, 'en'), 'T');
  });
}
