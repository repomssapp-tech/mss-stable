import '../content_language_resolver.dart';

/// Shared text parsing utilities for catalog scheme adapter.
class SchemeAdapterTextUtils {
  SchemeAdapterTextUtils._();

  /// [v] as a string map, or an empty map when it is anything else (a plain
  /// string, a list, null). Catalog fields change shape between records
  /// (`"x"` vs `{"en": "x"}`), so a hard `as Map<String, dynamic>?` throws on
  /// the first record that differs.
  static Map<String, dynamic> asMap(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

  /// [v] trimmed when it is a [String], else ''. Never throws and never
  /// stringifies a map or list.
  static String str(dynamic v) => v is String ? v.trim() : '';

  /// [v] as a string map, or null when it is anything else. Drop-in for
  /// `v as Map<String, dynamic>?`, which throws on a string or list.
  static Map<String, dynamic>? mapOrNull(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : null;

  /// Drop-in for `v as String?` that does not throw: a string is returned
  /// as is, a localized map or list is resolved to its text (null when it
  /// has none), and anything else is null.
  static String? textOrNull(dynamic v) {
    if (v is String) return v;
    if (v is Map || v is List) {
      final t = getLocalizedText(v);
      return t.isEmpty ? null : t;
    }
    return null;
  }

  /// The first non-empty entry of [candidates], or ''.
  static String firstText(Iterable<String> candidates) {
    for (final c in candidates) {
      if (c.isNotEmpty) return c;
    }
    return '';
  }

  /// Converts [val] to a list if it is a [List] or single non-empty [String].
  static List<dynamic>? asList(dynamic val) {
    if (val is List) return val;
    if (val is String && val.trim().isNotEmpty) return [val.trim()];
    return null;
  }

  static final RegExp _languageKey = RegExp(r'^[a-z]{2,3}$');

  /// Suffixed keys of an object that is not a language map (`name_ta`), tried
  /// in this order after the plain language key.
  static const List<String> _suffixedFields = ['name', 'title', 'description'];

  /// Extracts the English string and every other language's string from a
  /// multilingual object (`{"en": ..., "hi": ...}`, or `name_<lang>` keys) or a
  /// plain string. The map holds non-empty values only.
  static (String en, Map<String, String> translations) extractMultilingual(
    dynamic rawObj, [
    String defaultStr = '',
  ]) {
    if (rawObj is Map<String, dynamic>) {
      final en = str(rawObj['en']);
      final name = firstText([
        str(rawObj['name']),
        str(rawObj['title']),
        str(rawObj['description']),
      ]);
      final translations = <String, String>{};
      rawObj.forEach((key, value) {
        if (key == 'en' || !_languageKey.hasMatch(key)) return;
        final text = str(value);
        if (text.isNotEmpty) translations[key] = text;
      });
      for (final field in _suffixedFields) {
        final prefix = '${field}_';
        rawObj.forEach((key, value) {
          if (!key.startsWith(prefix)) return;
          final lang = key.substring(prefix.length);
          final text = str(value);
          if (_languageKey.hasMatch(lang) && text.isNotEmpty) {
            translations.putIfAbsent(lang, () => text);
          }
        });
      }
      return (
        en.isNotEmpty ? en : (name.isNotEmpty ? name : defaultStr),
        translations,
      );
    }
    if (rawObj is String && rawObj.trim().isNotEmpty) {
      return (rawObj.trim(), const {});
    }
    return (defaultStr, const {});
  }

  /// Extracts localized text from a map, list, or string. Delegates to
  /// [ContentLanguageResolver]: selected language -> English -> any other
  /// language present. Never stringifies a Map/List.
  static String getLocalizedText(dynamic val, [String preferredLang = 'en']) =>
      ContentLanguageResolver.text(val, preferredLang);
}
