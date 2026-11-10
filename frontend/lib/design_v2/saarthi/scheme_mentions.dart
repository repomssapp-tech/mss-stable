import '../../models/scheme_model.dart';
import '../../services/catalog/language_pack_manager.dart';
import '../../services/search/indic_search_support.dart';
import '../../services/search/indic_stemmer.dart';
import '../../services/voice/cloud_voice_protocol.dart';

/// The catalog schemes a Saarthi reply names, in the order it names them.
///
/// A scheme counts as mentioned when its acronym or short name (PMEGP,
/// P.M.E.G.P, பிஎம்இஜிபி) appears as whole words, or its name (English, Hindi,
/// Tamil or the full official name) appears, ignoring punctuation and
/// Hindi/Tamil word endings. Run once per reply, not per frame.
List<Scheme> schemesMentionedIn(
  String reply,
  List<Scheme> catalog, {
  int limit = 2,
}) => schemesForReply(reply, catalog, limit: limit);

/// The cards for a Saarthi reply.
///
/// [schemeIds] from the server are authoritative, including an empty
/// selection. Older servers send none, so the cards fall back to the schemes
/// the reply actually names, skipping sentences that say a scheme's details
/// are unavailable. [results] are the agent's search hits, and being one is
/// extra evidence: the reply may say the hit's title in its own language, or
/// just a word of its name that no other scheme has ("Mudra"), and a hit wins
/// when two schemes share a name. The hit list alone never supplies a card.
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
  final titles = <String, List<String>>{};
  for (final r in results) {
    for (final s in matchCloudSchemeResultsToCatalog([r], catalog)) {
      titles.putIfAbsent(s.id, () => []).add(r.name);
    }
  }
  final available = [
    for (final sentence in reply.split(_sentenceEnd))
      if (!_unavailable.hasMatch(sentence)) sentence,
  ].join(' \n ');
  return _rankNamed(available, catalog, titles, count);
}

final RegExp _sentenceEnd = RegExp(r'(?<=[!?।\n])|\.(?=\s|$)');

/// A sentence saying Saarthi has no verified details, in en, ta or hi.
final RegExp _unavailable = RegExp(
  r"\b(no verified|not verified|unverified|cannot verify|can't verify|could not verify|no (verified )?(details|information)|do not have|don't have)\b|சரிபார்க்கப்பட்ட.{0,40}இல்லை|விவரங்கள்.{0,20}இல்லை|सत्यापित.{0,40}नहीं|जानकारी.{0,20}नहीं",
  caseSensitive: false,
);

/// Finds every scheme's mentions as spans of reply words, then settles overlaps:
/// the longest span wins, then a search hit, so "Mudra Yojana" inside a longer
/// name, or a short name two schemes share, gives one card and not two.
List<Scheme> _rankNamed(
  String reply,
  List<Scheme> catalog,
  Map<String, List<String>> hitTitles,
  int limit,
) {
  if (reply.trim().isEmpty || catalog.isEmpty) return const [];
  final words = _words(reply);
  final stems = [for (final w in words) _stem(w)];
  final indic = indicScript.hasMatch(reply);
  final nameWordCounts = <String, int>{};
  if (hitTitles.isNotEmpty) {
    for (final s in catalog) {
      for (final w in _nameStems(s)) {
        nameWordCounts[w] = (nameWordCounts[w] ?? 0) + 1;
      }
    }
  }

  final spans = <({Scheme scheme, int start, int length, bool hit})>[];
  for (final s in catalog) {
    final titles = hitTitles[s.id];
    final hit = titles != null;
    void add(int start, int length) =>
        spans.add((scheme: s, start: start, length: length, hit: hit));
    void addPhrase(String text) {
      final needle = [for (final w in _words(text)) _stem(w)];
      final at = _indexOfWords(stems, needle);
      if (at >= 0) add(at, needle.length);
    }

    for (final short in _shortForms(s)) {
      addPhrase(short);
      final span = _acronymSpan(words, short, indic);
      if (span != null) add(span.$1, span.$2);
    }
    for (final full in _names(s)) {
      final f = _withoutParentheses(full);
      if (f.runes.length >= 12 || f.contains(' ')) addPhrase(f);
    }
    if (!hit) continue;
    for (final title in titles) {
      if (title.trim().runes.length >= 4) addPhrase(title);
    }
    for (final w in _nameStems(s)) {
      if (w.runes.length < 4 || nameWordCounts[w] != 1) continue;
      final at = stems.indexOf(w);
      if (at >= 0) add(at, 1);
    }
  }

  spans.sort((a, b) {
    final byLength = b.length.compareTo(a.length);
    if (byLength != 0) return byLength;
    if (a.hit != b.hit) return a.hit ? -1 : 1;
    return a.start.compareTo(b.start);
  });
  final taken = List<bool>.filled(words.length, false);
  final seen = <String>{};
  final kept = <(int, Scheme)>[];
  for (final span in spans) {
    if (seen.contains(span.scheme.id)) continue;
    final range = taken.sublist(span.start, span.start + span.length);
    if (range.contains(true)) continue;
    taken.fillRange(span.start, span.start + span.length, true);
    seen.add(span.scheme.id);
    kept.add((span.start, span.scheme));
  }
  kept.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final k in kept.take(limit)) k.$2];
}

final RegExp _joiners = RegExp('[‌‍\'’]');
final RegExp _wordBreak = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

/// Lowercase words, so punctuation and spacing never decide a match.
List<String> _words(String text) => [
  for (final w in text.toLowerCase().replaceAll(_joiners, '').split(_wordBreak))
    if (w.isNotEmpty) w,
];

/// A word's root: Hindi and Tamil lose their endings, English its plural.
String _stem(String word) {
  if (indicScript.hasMatch(word)) return indicStem(word);
  final singular = word.length > 3 && word.endsWith('s')
      ? word.substring(0, word.length - 1)
      : word;
  return singular == 'programme' ? 'program' : singular;
}

/// A scheme's names in every language the catalog or a loaded pack has.
Iterable<String> _names(Scheme s) sync* {
  yield s.name;
  yield s.fullSchemeName;
  for (final lang in _replyLanguages) {
    final native = s.nativeName('name', lang);
    if (native != null) yield native;
  }
  for (final lang in _replyLanguages) {
    final name = LanguagePackManager.instance.getField(
      lang: lang,
      entityType: 'scheme',
      entityId: s.id,
      fieldName: 'name',
    );
    if (name != null) yield name;
  }
}

const List<String> _replyLanguages = ['hi', 'ta'];

Set<String> _nameStems(Scheme s) => {
  for (final name in _names(s))
    for (final w in _words(_withoutParentheses(name))) _stem(w),
};

int _indexOfWords(List<String> haystack, List<String> needle) {
  if (needle.isEmpty) return -1;
  outer:
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// An acronym split up ("P.M.E.G.P") or spelled out in Hindi or Tamil letters
/// ("पीएमईजीपी", "பி.எம்.இ.ஜி.பி"), as (first word, word count).
(int, int)? _acronymSpan(List<String> words, String short, bool indic) {
  final latin = short.toLowerCase();
  if (latin.contains(' ')) return null;
  final spelled = indic ? _spelledAcronym(short) : null;
  for (var i = 0; i < words.length; i++) {
    var joined = '';
    for (var j = i; j < words.length && j - i < short.length; j++) {
      joined += words[j];
      if (joined == latin || (spelled?.hasMatch(joined) ?? false)) {
        return (i, j - i + 1);
      }
    }
  }
  return null;
}

/// Matches [acronym] spelled letter by letter, plus a short attached ending.
RegExp? _spelledAcronym(String acronym) {
  if (!RegExp(r'^[A-Z]{3,8}$').hasMatch(acronym)) return null;
  final letters = [
    for (final c in acronym.split('')) '(?:${_spokenLetters[c]})',
  ];
  return RegExp('^${letters.join()}.{0,6}\$', unicode: true);
}

const Map<String, String> _spokenLetters = {
  'A': 'ए|ஏ',
  'B': 'बी|பி',
  'C': 'सी|சி|ஸி',
  'D': 'डी|டி',
  'E': 'ई|இ|ஈ',
  'F': 'एफ|எஃப்',
  'G': 'जी|ஜி',
  'H': 'एच|ஹெச்|எச்',
  'I': 'आई|ஐ',
  'J': 'जे|ஜே',
  'K': 'के|கே',
  'L': 'एल|எல்',
  'M': 'एम|எம்',
  'N': 'एन|என்',
  'O': 'ओ|ஓ',
  'P': 'पी|பி',
  'Q': 'क्यू|க்யூ',
  'R': 'आर|ஆர்',
  'S': 'एस|எஸ்',
  'T': 'टी|டி',
  'U': 'यू|யூ',
  'V': 'वी|வி',
  'W': 'डब्ल्यू|டபிள்யூ|டபிள்யு',
  'X': 'एक्स|எக்ஸ்',
  'Y': 'वाई|ஒய்|வை',
  'Z': 'जेड|இசட்|ஜெட்',
};

final RegExp _parenthesised = RegExp(r'\(([^)]+)\)');

String _withoutParentheses(String text) =>
    text.replaceAll(_parenthesised, '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Acronyms worth matching as whole words: the short name and any
/// all-caps word in brackets ("Prime Minister's ... (PMEGP)").
Iterable<String> _shortForms(Scheme s) sync* {
  final short = s.shortName.trim();
  if (short.length >= 3 && short.length <= 16) yield short;
  for (final lang in _replyLanguages) {
    final native = s.nativeName('shortName', lang);
    if (native != null) yield native;
  }
  for (final m in _parenthesised.allMatches(s.name)) {
    final inner = m[1]!.trim();
    if (inner.length >= 3 &&
        inner.length <= 12 &&
        !inner.contains(' ') &&
        inner == inner.toUpperCase()) {
      yield inner;
    }
  }
}
