import '../../models/scheme_model.dart';
import '../../services/voice/cloud_voice_protocol.dart';

/// Explicit IDs are authoritative, including an empty selection. Older servers
/// fall back to names in this reply, never to the whole search result list.
List<Scheme> schemesForReply(
  String reply,
  List<Scheme> catalog, {
  List<CloudSchemeResult> results = const [],
  List<String>? schemeIds,
  int limit = 2,
}) {
  if (reply.trim().isEmpty || limit <= 0) return const [];
  final count = limit.clamp(0, 2);
  if (schemeIds != null) {
    final byId = <String, Scheme>{
      for (final scheme in catalog) scheme.id: scheme,
    };
    for (final scheme in catalog) {
      if (scheme.schemeCode.isNotEmpty) {
        byId.putIfAbsent(scheme.schemeCode, () => scheme);
      }
    }
    final seen = <String>{};
    return [
      for (final id in schemeIds)
        if (byId[id] case final scheme?)
          if (seen.add(scheme.id)) scheme,
    ].take(count).toList();
  }
  return _mentioned(reply, catalog, results, count);
}

List<Scheme> schemesMentionedIn(
  String reply,
  List<Scheme> catalog, {
  int limit = 2,
}) => schemesForReply(reply, catalog, limit: limit);

final _unavailable = RegExp(
  r"\b(no verified|not verified|unverified|cannot verify|can't verify|could not verify|no (verified )?(details|information)|do not have|don't have)\b|சரிபார்க்கப்பட்ட.{0,40}இல்லை|விவரங்கள்.{0,20}இல்லை|सत्यापित.{0,40}नहीं|जानकारी.{0,20}नहीं",
  caseSensitive: false,
);
final _parenthesised = RegExp(r'\(([^)]+)\)');
String _normalize(String text) => text.toLowerCase().replaceAll(
  RegExp(r'[^a-z0-9\u0900-\u097F\u0B80-\u0BFF]'),
  '',
);

Iterable<String> _names(Scheme scheme) sync* {
  for (final name in [
    scheme.name,
    scheme.fullSchemeName,
    scheme.shortName,
    ...?scheme.nativeNames['name']?.values,
    ...?scheme.nativeNames['short_name']?.values,
  ]) {
    yield name;
    yield name.replaceAll(_parenthesised, '').trim();
    for (final acronym in RegExp(r'\b[A-Z]{3,12}\b').allMatches(name)) {
      yield acronym[0]!;
    }
  }
}

// Common spoken letter names in the catalog's Hindi and Tamil languages.
const _hindi = [
  'ए',
  'बी',
  'सी',
  'डी',
  'ई',
  'एफ',
  'जी',
  'एच',
  'आई',
  'जे',
  'के',
  'एल',
  'एम',
  'एन',
  'ओ',
  'पी',
  'क्यू',
  'आर',
  'एस',
  'टी',
  'यू',
  'वी',
  'डब्ल्यू',
  'एक्स',
  'वाई',
  'जेड',
];
const _tamil = [
  'ஏ',
  'பி',
  'சி',
  'டி',
  'இ',
  'எஃப்',
  'ஜி',
  'எச்',
  'ஐ',
  'ஜே',
  'கே',
  'எல்',
  'எம்',
  'என்',
  'ஓ',
  'பி',
  'க்யூ',
  'ஆர்',
  'எஸ்',
  'டி',
  'யு',
  'வி',
  'டபிள்யு',
  'எக்ஸ்',
  'ஒய்',
  'ஸெட்',
];
Iterable<String> _variants(String name) sync* {
  yield name;
  // Tamil case endings replace the final ம் (திட்டம் -> திட்டத்தில்).
  if (name.length > 10 && name.endsWith('ம்')) {
    yield name.substring(0, name.length - 2);
  }
  if (!RegExp(r'^[A-Z]{3,12}$').hasMatch(name)) return;
  yield name.codeUnits.map((letter) => _hindi[letter - 65]).join();
  yield name.codeUnits.map((letter) => _tamil[letter - 65]).join();
  final hindi = name.codeUnits.map((letter) => _hindi[letter - 65]).join();
  if (hindi.startsWith('पी')) yield 'प${hindi.substring(2)}';
}

List<Scheme> _mentioned(
  String reply,
  List<Scheme> catalog,
  List<CloudSchemeResult> results,
  int limit,
) {
  final lookup = <String, List<String>>{};
  for (final result in results) {
    for (final scheme in matchCloudSchemeResultsToCatalog([result], catalog)) {
      lookup.putIfAbsent(scheme.id, () => []).add(result.name);
    }
  }
  final hits = <({int start, int end, Scheme scheme, bool lookup})>[];
  var offset = 0;
  for (final sentence in reply.split(RegExp(r'(?<=[!?।\n])|\.(?=\s|$)'))) {
    final text = _normalize(sentence);
    if (!_unavailable.hasMatch(sentence)) {
      for (final scheme in catalog) {
        for (final name in {..._names(scheme), ...?lookup[scheme.id]}) {
          for (final variant in _variants(name)) {
            final token = _normalize(variant);
            if (token.length < 3) continue;
            if (RegExp(r'^[a-z0-9]+$').hasMatch(token)) {
              final pattern = token
                  .split('')
                  .map(RegExp.escape)
                  .join(r'[\s.\-’\x27]*');
              if (!RegExp(
                '(?<![A-Za-z0-9])$pattern(?![A-Za-z0-9])',
                caseSensitive: false,
              ).hasMatch(sentence)) {
                continue;
              }
            }
            final at = text.indexOf(token);
            if (at >= 0) {
              hits.add((
                start: offset + at,
                end: offset + at + token.length,
                scheme: scheme,
                lookup: lookup.containsKey(scheme.id),
              ));
            }
          }
        }
      }
    }
    offset += text.length + 1;
  }
  hits.sort((a, b) {
    final length = (b.end - b.start).compareTo(a.end - a.start);
    if (length != 0) return length;
    if (a.lookup != b.lookup) return a.lookup ? -1 : 1;
    return a.start.compareTo(b.start);
  });
  final chosen = <({int start, int end, Scheme scheme, bool lookup})>[];
  for (final hit in hits) {
    if (chosen.any((other) => hit.start < other.end && other.start < hit.end)) {
      continue;
    }
    chosen.add(hit);
  }
  chosen.sort((a, b) => a.start.compareTo(b.start));
  final seen = <String>{};
  return [
    for (final hit in chosen)
      if (seen.add(hit.scheme.id)) hit.scheme,
  ].take(limit).toList();
}
