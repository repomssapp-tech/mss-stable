import '../content_language_resolver.dart';

/// Shared text parsing utilities for catalog scheme adapter.
class SchemeAdapterTextUtils {
  SchemeAdapterTextUtils._();

  /// Converts [val] to a list if it is a [List] or single non-empty [String].
  static List<dynamic>? asList(dynamic val) {
    if (val is List) return val;
    if (val is String && val.trim().isNotEmpty) return [val.trim()];
    return null;
  }

  /// Extracts English and Tamil strings from a multilingual object or string.
  static (String en, String ta) extractMultilingualStr(
    dynamic rawObj, [
    String defaultStr = '',
  ]) {
    if (rawObj is Map<String, dynamic>) {
      final en = (rawObj['en'] as String? ?? '').trim();
      final ta = (rawObj['ta'] as String? ?? '').trim();
      final name =
          (rawObj['name'] as String? ??
                  rawObj['title'] as String? ??
                  rawObj['description'] as String? ??
                  '')
              .trim();
      final nameTa =
          (rawObj['name_ta'] as String? ??
                  rawObj['title_ta'] as String? ??
                  rawObj['description_ta'] as String? ??
                  '')
              .trim();
      return (
        en.isNotEmpty ? en : (name.isNotEmpty ? name : defaultStr),
        ta.isNotEmpty ? ta : nameTa,
      );
    }
    if (rawObj is String && rawObj.trim().isNotEmpty) {
      return (rawObj.trim(), '');
    }
    return (defaultStr, '');
  }

  /// The Hindi string of a multilingual object (`{"en": ..., "hi": ...}`), or
  /// '' when [rawObj] is plain text or has no Hindi.
  static String extractHi(dynamic rawObj) {
    if (rawObj is Map) {
      final hi = rawObj['hi'];
      if (hi is String) return hi.trim();
    }
    return '';
  }

  /// Extracts localized text from a map, list, or string. Delegates to
  /// [ContentLanguageResolver]: selected language -> English -> any other
  /// language present. Never stringifies a Map/List.
  static String getLocalizedText(dynamic val, [String preferredLang = 'en']) =>
      ContentLanguageResolver.text(val, preferredLang);
}
