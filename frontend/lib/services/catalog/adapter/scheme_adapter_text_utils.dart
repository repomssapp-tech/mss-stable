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

  /// Extracts localized text from a map, list, or string with strict fallback:
  /// `preferred locale (langCode) → alternate locale (en/ta) → default text`
  static String getLocalizedText(dynamic val, [String preferredLang = 'en']) {
    if (val == null) return '';
    if (val is Map) {
      final preferred = val[preferredLang]?.toString();
      if (preferred != null && preferred.trim().isNotEmpty) {
        return preferred.trim();
      }
      final altLang = preferredLang == 'ta' ? 'en' : 'ta';
      final alt = val[altLang]?.toString();
      if (alt != null && alt.trim().isNotEmpty) {
        return alt.trim();
      }
      final desc =
          val['description'] ?? val['summary'] ?? val['text'] ?? val['name'];
      if (desc != null) return getLocalizedText(desc, preferredLang);
    } else if (val is List) {
      final items = val
          .map((e) => getLocalizedText(e, preferredLang))
          .where((s) => s.isNotEmpty);
      return items.join('\n• ');
    } else if (val is String) {
      return val.trim();
    }
    return '';
  }
}
