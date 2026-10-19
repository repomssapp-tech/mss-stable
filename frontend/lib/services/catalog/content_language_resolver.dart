/// Resolves scheme *content* in the user's language, independent of the UI
/// locale. Interface strings come from the ARB files; scheme text comes from
/// the catalog and may be a plain string, a `{lang: value}` map, a list, or a
/// nested combination of those.
///
/// Fallback chain per value: selected language -> English -> any other
/// language present, in [fallbackOrder]. A Map or List is never stringified
/// with `toString()`, so raw JSON can no longer leak into the UI.
class ContentLanguageResolver {
  ContentLanguageResolver._();

  /// Languages tried last, in order, when neither the selected language nor
  /// English has a value. Content-only languages (e.g. `mr`) are included so
  /// their text is never discarded.
  static const List<String> fallbackOrder = ['en', 'hi', 'ta', 'mr'];

  /// Keys that hold display text inside an object that is not a language map.
  static const List<String> _textKeys = [
    'text',
    'description',
    'summary',
    'name',
    'title',
  ];

  /// Normalises `ta-IN`, `HI`, `' en '` to `ta`, `hi`, `en`. Returns `en` for
  /// null/blank input.
  static String normalizeCode(String? code) {
    final c = (code ?? '').trim().toLowerCase().replaceAll('_', '-');
    if (c.isEmpty) return 'en';
    return c.split('-').first;
  }

  static bool _looksLikeLanguageMap(Map map) {
    if (map.isEmpty) return false;
    return map.keys.every(
      (k) => k is String && RegExp(r'^[a-z]{2,3}$').hasMatch(k),
    );
  }

  /// Picks the best available language code from [available].
  static String? pickLanguage(
    Iterable<String> available,
    String preferred, {
    String? recordDefault,
  }) {
    final have = available.map(normalizeCode).toSet();
    final want = normalizeCode(preferred);
    if (have.contains(want)) return want;
    final fallback = normalizeCode(recordDefault);
    if (recordDefault != null && have.contains(fallback)) return fallback;
    if (have.contains('en')) return 'en';
    for (final lang in fallbackOrder) {
      if (have.contains(lang)) return lang;
    }
    return have.isEmpty ? null : have.first;
  }

  static List<String> _chain(String lang, Iterable<String> present) {
    return <String>{
      normalizeCode(lang),
      'en',
      ...fallbackOrder,
      ...present.map(normalizeCode),
    }.toList();
  }

  /// Display text for [value] in [lang]. Lists become newline-joined bullets
  /// (matching the previous adapter behaviour); unknown shapes become `''`.
  static String text(dynamic value, [String lang = 'en']) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      final items = value
          .map((e) => text(e, lang))
          .where((s) => s.isNotEmpty)
          .toList();
      return items.join('\n• ');
    }
    if (value is Map) {
      if (_looksLikeLanguageMap(value)) {
        for (final candidate in _chain(lang, value.keys.cast<String>())) {
          final resolved = text(value[candidate], lang);
          if (resolved.isNotEmpty) return resolved;
        }
        return '';
      }
      for (final key in _textKeys) {
        final resolved = text(value[key], lang);
        if (resolved.isNotEmpty) return resolved;
      }
    }
    return '';
  }

  /// Items of a list-valued field in [lang], each as display text. A `{lang:
  /// [..]}` map picks one language's list; a plain string becomes one item.
  static List<String> list(dynamic value, [String lang = 'en']) {
    if (value == null) return const [];
    if (value is String) {
      final t = value.trim();
      return t.isEmpty ? const [] : [t];
    }
    if (value is List) {
      return value
          .map((e) => text(e, lang))
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
    if (value is Map && _looksLikeLanguageMap(value)) {
      for (final candidate in _chain(lang, value.keys.cast<String>())) {
        final resolved = list(value[candidate], lang);
        if (resolved.isNotEmpty) return resolved;
      }
    }
    return const [];
  }
}
