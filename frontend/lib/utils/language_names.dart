import '../services/catalog/content_language_resolver.dart';

/// How a language is named and labelled, for every language the catalogue may
/// carry. This is reference data, not a list of languages the app offers: that
/// list comes from the catalogue manifest (`LanguagePackManager.offeredLanguages`).
/// The entries are in display order; a code with no entry sorts after them.
const Map<String, ({String endonym, String english, String? step})> _languages =
    {
      'en': (endonym: 'English', english: 'English', step: 'Step'), // i18n-ok
      'ta': (endonym: 'தமிழ்', english: 'Tamil', step: 'படி'), // i18n-ok
      'hi': (endonym: 'हिन्दी', english: 'Hindi', step: 'चरण'), // i18n-ok
      'bn': (endonym: 'বাংলা', english: 'Bengali', step: null), // i18n-ok
      'te': (endonym: 'తెలుగు', english: 'Telugu', step: null), // i18n-ok
      'kn': (endonym: 'ಕನ್ನಡ', english: 'Kannada', step: null), // i18n-ok
      'ml': (endonym: 'മലയാളം', english: 'Malayalam', step: null), // i18n-ok
      'gu': (endonym: 'ગુજરાતી', english: 'Gujarati', step: null), // i18n-ok
      'pa': (endonym: 'ਪੰਜਾਬੀ', english: 'Punjabi', step: null), // i18n-ok
      'or': (endonym: 'ଓଡ଼ିଆ', english: 'Odia', step: null), // i18n-ok
      'as': (endonym: 'অসমীয়া', english: 'Assamese', step: null), // i18n-ok
      'ur': (endonym: 'اردو', english: 'Urdu', step: null), // i18n-ok
    };

/// Name of a language written in its own script, whatever the active UI
/// language is. Used wherever the current language is shown as a value
/// (Settings, Profile), so a Hindi user never sees "English" for Hindi. A code
/// with no known name is shown as the code itself rather than as a wrong name.
String languageEndonym(String code) {
  final normalized = ContentLanguageResolver.normalizeCode(code);
  return _languages[normalized]?.endonym ?? normalized.toUpperCase();
}

/// English name of a language, shown under its [languageEndonym] in the picker.
String languageEnglishName(String code) {
  final normalized = ContentLanguageResolver.normalizeCode(code);
  return _languages[normalized]?.english ?? normalized.toUpperCase();
}

/// The language code [value] names, given a code ("hi") or an English name
/// ("Hindi") in any case; null when it names no known language.
String? languageCodeOf(String value) {
  final lower = value.trim().toLowerCase();
  if (_languages.containsKey(lower)) return lower;
  for (final entry in _languages.entries) {
    if (entry.value.english.toLowerCase() == lower) return entry.key;
  }
  return null;
}

/// Label of application step [number] in [code] ("चरण 2:"). A language with no
/// known word for "step" gets the bare number, not the English word.
String stepLabel(String code, Object number) {
  final word = _languages[ContentLanguageResolver.normalizeCode(code)]?.step;
  return word == null ? '$number.' : '$word $number:';
}

/// [codes] in display order, known languages first.
List<String> inDisplayOrder(Iterable<String> codes) {
  final known = _languages.keys.toList();
  int rank(String c) {
    final i = known.indexOf(c);
    return i < 0 ? known.length : i;
  }

  return codes.toList()..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.compareTo(b);
  });
}
