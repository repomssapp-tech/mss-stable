/// Hindi (Devanagari) and Tamil search support for the offline catalog search:
/// indexing a scheme's own Hindi/Tamil text and matching inflected words.
/// Kept apart from `hybrid_scheme_search.dart` so that file does not grow.
library;

import 'indic_stemmer.dart';

/// Whether a token contains Devanagari or Tamil script.
final RegExp indicScript = RegExp(r'[ऀ-ॿ஀-௿]');

/// Localized text fields that describe what a scheme does.
const List<String> _kTextFields = [
  'summary',
  'description',
  'benefitsText',
  'eligibilityText',
  'category',
];

/// The words of a scheme's own Hindi and Tamil text (Indic script only;
/// English comes from the prebuilt index), from the catalog `localization`
/// block. Without them a Hindi or Tamil query could only match a scheme's
/// *name*, never what it does. [tokenize] splits text into candidate words.
List<String> indicTextTokens(
  Object? localization,
  List<String> Function(String text) tokenize,
) {
  if (localization is! Map) return const [];
  final out = <String>{};
  for (final lang in const ['hi', 'ta']) {
    final block = localization[lang];
    if (block is! Map) continue;
    for (final key in _kTextFields) {
      final text = block[key];
      if (text is! String) continue;
      out.addAll(tokenize(text).where(indicScript.hasMatch));
    }
  }
  return out.toList()..sort();
}

/// The words of a scheme's English summary / description / benefits /
/// eligibility text. The prebuilt English index holds only a scheme's name-like
/// tokens, so a plain-language query ("cooking gas", "sewer cleaners") could
/// never reach a scheme whose own description says exactly that.
List<String> englishTextTokens(
  Object? localization,
  List<String> Function(String text) tokenize,
) {
  final block = localization is Map ? localization['en'] : null;
  if (block is! Map) return const [];
  final out = <String>{};
  for (final key in _kTextFields) {
    final text = block[key];
    if (text is String) out.addAll(tokenize(text));
  }
  return out.toList()..sort();
}

/// The Indic words of the search vocabulary, for matching inflected forms.
///
/// Hindi and Tamil attach suffixes ("கொள்முதல்" -> "கொள்முதலுக்காக"), so a
/// query word is often not literally in the vocabulary although its root is.
class IndicVocabulary {
  IndicVocabulary(Iterable<String> vocabulary)
    : _words = [
        for (final v in vocabulary)
          if (indicScript.hasMatch(v))
            (word: v, stem: _stem(v), runes: v.runes.length),
      ] {
    for (final w in _words) {
      _byLinguisticStem
          .putIfAbsent(indicStem(w.word), () => <String>{})
          .add(w.word);
    }
  }

  /// Words that share a real (Snowball Hindi / Tamil) stem, so "महिला",
  /// "महिलाओं" and "महिलाएं" meet. See [indicStem].
  final Map<String, Set<String>> _byLinguisticStem = {};

  /// Longest suffix (in code points) treated as an inflection of a root.
  static const int maxSuffixRunes = 7;

  /// Roots shorter than this are never matched by prefix: too many unrelated
  /// words would share them.
  static const int minRootRunes = 4;

  /// Each word with its stem: the word minus a final virama / vowel sign
  /// ("கொள்முதல்" -> "கொள்முதல"), which is what an inflected form such as
  /// "கொள்முதலுக்காக" actually continues from.
  final List<({String word, String stem, int runes})> _words;

  static String _stem(String word) {
    final runes = word.runes.toList();
    while (runes.length > 1) {
      final c = runes.last;
      final isVirama = c == 0x0BCD || c == 0x094D;
      final isVowelSign =
          (c >= 0x0BBE && c <= 0x0BCC) || (c >= 0x093E && c <= 0x094C);
      if (!isVirama && !isVowelSign) break;
      runes.removeLast();
    }
    return String.fromCharCodes(runes);
  }

  /// Vocabulary words that are an inflection-root of [token] (the root is a
  /// prefix of the token, up to [maxSuffixRunes] extra characters) or that
  /// extend it (the token is a prefix of the word).
  Set<String> variants(String token) {
    // 1. Words with the same linguistic stem (the precise match).
    final sameStem = _byLinguisticStem[indicStem(token)];
    if (sameStem != null) {
      final others = {...sameStem}..remove(token);
      if (others.isNotEmpty) return others;
    }
    // 2. Otherwise fall back to the looser prefix rule below.
    final tokenRunes = token.runes.length;
    if (tokenRunes < minRootRunes) return const {};
    final out = <String>{};
    for (final v in _words) {
      if (v.word == token) continue;
      final stemRunes = v.stem.runes.length;
      final rootOfToken =
          stemRunes >= minRootRunes &&
          token.startsWith(v.stem) &&
          tokenRunes - stemRunes <= maxSuffixRunes;
      final extendsToken =
          v.word.startsWith(token) && v.runes - tokenRunes <= maxSuffixRunes;
      if (rootOfToken || extendsToken) out.add(v.word);
    }
    return out;
  }
}
