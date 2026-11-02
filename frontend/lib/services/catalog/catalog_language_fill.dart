/// Completes a server catalog with languages only the app's shipped packs have.
///
/// The admin site's dataset upload accepts English, Hindi and Tamil only, so a
/// release it publishes carries no Marathi at all, and installing that release
/// would take Marathi away from a phone that shipped with it. A language the
/// release has none of is copied in from the shipped packs, scheme by scheme.
/// A language the release has for any scheme is the server's to decide and is
/// never touched, so Hindi stays off Tamil Nadu schemes and a server edit is
/// never overwritten.
///
/// A release also holds each required document's name as English text alone.
/// Where that English matches a shipped document, the shipped name in every
/// language is used instead.
library;

const String _schemeSection = 'scheme_catalog.json';

List<Map<String, dynamic>> _schemeRows(Map<String, dynamic> bundle) {
  final section = bundle[_schemeSection];
  final rows = section is Map ? section['data'] : null;
  return rows is List
      ? rows.whereType<Map<String, dynamic>>().toList()
      : const [];
}

String? _schemeId(Map<String, dynamic> row) {
  final identity = row['identity'];
  final id = identity is Map ? identity['id'] : null;
  return id is String && id.isNotEmpty ? id : null;
}

/// Which of [languages] no scheme in [bundle] has any text in.
Set<String> languagesAbsentFrom(
  Map<String, dynamic> bundle,
  Iterable<String> languages,
) {
  final absent = languages.toSet();
  for (final row in _schemeRows(bundle)) {
    final localization = row['localization'];
    if (localization is Map) absent.removeAll(localization.keys);
    if (absent.isEmpty) break;
  }
  return absent;
}

/// Copies [languages] from [pack] (a shipped jurisdiction pack) onto the rows
/// of [bundle] with the same scheme id. Returns how many schemes gained text.
int fillLanguagesFromPack(
  Map<String, dynamic> bundle,
  Map<String, dynamic> pack,
  Set<String> languages,
) {
  final rows = {
    for (final row in _schemeRows(bundle))
      if (_schemeId(row) != null) _schemeId(row)!: row,
  };
  var filled = 0;
  for (final shipped in _schemeRows(pack)) {
    final row = rows[_schemeId(shipped)];
    if (row == null) continue;
    var changed = false;
    for (final lang in languages) {
      final localization = shipped['localization'];
      final block = localization is Map ? localization[lang] : null;
      if (block is! Map) continue;
      (row['localization'] ??= <String, dynamic>{})[lang] = block;
      changed = true;
      for (final key in const ['aliases', 'keywords']) {
        final search = shipped['search'];
        final group = search is Map ? search[key] : null;
        final words = group is Map ? group[lang] : null;
        if (words == null) continue;
        final target = (row['search'] ??= <String, dynamic>{}) as Map;
        (target[key] ??= <String, dynamic>{})[lang] = words;
      }
      _fillBenefitFacts(row, shipped, lang);
    }
    if (changed) filled++;
  }
  return filled;
}

/// Replaces plain-English document names in [bundle] with the shipped
/// multi-language name whose English is identical. Returns how many changed.
int fillDocumentNamesFromPack(
  Map<String, dynamic> bundle,
  Map<String, dynamic> pack,
) {
  List? documentsOf(Map<String, dynamic> scheme) {
    final content = scheme['content'];
    final documents = content is Map ? content['requiredDocuments'] : null;
    return documents is List ? documents : null;
  }

  final rows = {
    for (final row in _schemeRows(bundle))
      if (_schemeId(row) != null) _schemeId(row)!: row,
  };
  var filled = 0;
  for (final shipped in _schemeRows(pack)) {
    final row = rows[_schemeId(shipped)];
    final target = row == null ? null : documentsOf(row);
    final source = documentsOf(shipped);
    if (target == null || source == null) continue;
    final names = <String, Map>{
      for (final document in source)
        if (document is Map &&
            document['name'] is Map &&
            (document['name'] as Map)['en'] is String)
          (document['name'] as Map)['en'] as String: document['name'] as Map,
    };
    for (final document in target) {
      if (document is! Map || document['name'] is! String) continue;
      final name = names[document['name']];
      if (name == null) continue;
      document['name'] = name;
      filled++;
    }
  }
  return filled;
}

/// The facts of a benefit are listed in the same order in both, unless the
/// server has edited them; then their count differs and they stay as they are.
void _fillBenefitFacts(
  Map<String, dynamic> row,
  Map<String, dynamic> shipped,
  String lang,
) {
  List? factsOf(Map<String, dynamic> scheme) {
    final content = scheme['content'];
    final benefitFacts = content is Map ? content['benefitFacts'] : null;
    final facts = benefitFacts is Map ? benefitFacts['facts'] : null;
    return facts is List ? facts : null;
  }

  final from = factsOf(shipped);
  final to = factsOf(row);
  if (from == null || to == null || from.length != to.length) return;
  for (var i = 0; i < from.length; i++) {
    final source = from[i];
    final target = to[i];
    if (source is! Map || target is! Map) continue;
    final translations = source['translations'];
    final text = translations is Map ? translations[lang] : null;
    if (text == null) continue;
    (target['translations'] ??= <String, dynamic>{})[lang] = text;
  }
}
