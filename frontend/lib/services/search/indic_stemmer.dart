/// Light stemmers for Hindi (Devanagari) and Tamil search.
///
/// Both languages inflect by attaching suffixes, so "महिला", "महिलाओं" and
/// "महिलाएं" (or "திட்டம்", "திட்டத்தில்", "திட்டங்கள்") are one word to a
/// reader but different strings to a search index. Stemming both the indexed
/// words and the query words makes them meet.
library;

/// Hindi: the "Lightweight Stemmer for Hindi" (Ramanathan & Rao, 2003) as
/// implemented by the Snowball project: remove the longest matching suffix
/// that leaves at least one character; suffixes marked `afterConsonant` are
/// only removed when a consonant precedes them.
class _HindiSuffix {
  const _HindiSuffix(this.text, {this.afterConsonant = false});

  final String text;
  final bool afterConsonant;
}

// Independent-vowel forms (used when the stem already ends in a vowel letter).
const List<String> _hindiIndependent = [
  '्', 'अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ए', 'ओ', //
  'एं', 'ओं', 'आं', 'उआं', 'उएं', 'उओं', 'आएं', 'आओं',
  'इयां', 'इयों', 'आइयां', 'आइयों',
  'आँ', 'इयाँ', 'आइयाँ',
  'अताएं', 'अताओं', 'अनाएं', 'अनाओं', 'अता', 'अती',
  'ईं', 'अतीं', 'अते',
  'आता', 'आती', 'आतीं', 'आते', 'अना', 'अनी', 'अने',
  'आना', 'आने',
  'ऊंगा', 'ऊंगी', 'आऊंगा', 'आऊंगी',
  'एंगे', 'एंगी', 'आएंगे', 'आएंगी',
  'ओगे', 'ओगी', 'आओगे', 'आओगी',
  'एगा', 'एगी', 'आएगा', 'आएगी',
  'आया', 'आए', 'आई', 'आईं', 'इए', 'आओ', 'आइए', 'अकर', 'आकर',
];

// Dependent vowel signs (the usual case: a consonant + the ending).
const List<String> _hindiDependent = [
  'ा',
  'ि',
  'ी',
  'ु',
  'ू',
  'े',
  'ो',
  'ें',
  'ों',
  'ां',
  'ुआं',
  'ुएं',
  'ुओं',
  'ाएं',
  'ाओं',
  'ियां',
  'ियों',
  'ाइयां',
  'ाइयों',
  'ाँ',
  'ियाँ',
  'ाइयाँ',
  'ीं',
  'ाता',
  'ाती',
  'ाते',
  'ातीं',
  'ाना',
  'ाने',
  'ूंगा',
  'ूंगी',
  'ाऊंगा',
  'ाऊंगी',
  'ेंगे',
  'ेंगी',
  'ाएंगे',
  'ाएंगी',
  'ोगे',
  'ोगी',
  'ाओगे',
  'ाओगी',
  'ेगा',
  'ेगी',
  'ाएगा',
  'ाएगी',
  'ाया',
  'ाए',
  'ाई',
  'ाईं',
  'िए',
  'ाओ',
  'ाइए',
  'ाकर',
];

// Endings that start with an implicit "a" consonant: removed only after a
// consonant (so they are not cut out of the middle of a longer word).
const List<String> _hindiAfterConsonant = [
  'ताएं',
  'ताओं',
  'नाएं',
  'नाओं',
  'ता',
  'ती',
  'तीं',
  'ते',
  'ना',
  'नी',
  'ने',
  'कर',
];

final List<_HindiSuffix> _hindiSuffixes = ([
  for (final s in _hindiIndependent) _HindiSuffix(s),
  for (final s in _hindiDependent) _HindiSuffix(s),
  for (final s in _hindiAfterConsonant) _HindiSuffix(s, afterConsonant: true),
]..sort((a, b) => b.text.runes.length.compareTo(a.text.runes.length)));

bool _isDevanagariConsonant(int c) =>
    (c >= 0x0915 && c <= 0x0939) ||
    (c >= 0x0958 && c <= 0x095F) ||
    c == 0x0929 ||
    c == 0x0931 ||
    c == 0x0934 ||
    c == 0x093C;

/// Hindi stem of [word] (a Devanagari token).
String hindiStem(String word) {
  final runes = word.runes.toList();
  for (final suffix in _hindiSuffixes) {
    final s = suffix.text.runes.toList();
    if (s.length >= runes.length) continue; // must leave at least one letter
    var matches = true;
    for (var i = 0; i < s.length; i++) {
      if (runes[runes.length - s.length + i] != s[i]) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    if (suffix.afterConsonant &&
        !_isDevanagariConsonant(runes[runes.length - s.length - 1])) {
      continue;
    }
    return String.fromCharCodes(runes.sublist(0, runes.length - s.length));
  }
  return word;
}

// ── Tamil ────────────────────────────────────────────────────────────────
//
// A conservative suffix stripper. The suffix families were read off the
// catalog's own Tamil text (tools/indic_suffix_mining.py): plural "கள்",
// case endings (-ஐ, -இல், -இன், -உக்கு, -உடன், -ஆல், -ஆக, -ஆன), the
// sound changes of -ம் nouns ("திட்டம்" -> "திட்டத்தில்", "திட்டங்கள்") and the
// "ய" glide after a vowel ("நிதி" -> "நிதியை"). Only the longest matching
// ending is removed, and never below [_tamilMinStem] letters.
const int _tamilMinStem = 2;

const List<String> _tamilSuffixList = [
  // agent nouns (ஏற்றுமதி "export" -> ஏற்றுமதியாளர் "exporter")
  'யாளர்களுக்கு', 'யாளர்களின்', 'யாளர்கள்', 'யாளருக்கு', 'யாளர்',
  // "for the sake of" / "for"
  'ுக்காகவும்', 'ுக்காக', 'க்காகவும்', 'க்காக', 'த்துக்காக', 'களுக்காக',
  // plural + case
  'களுக்காகவும்', 'களுக்கான', 'களுக்கு', 'களுடன்', 'களிடமிருந்து', 'களிடம்',
  'களினால்', 'களால்', 'களில்', 'களின்', 'களை', 'களாக', 'களான', 'களும்', 'கள்',
  // plural of -ம் nouns (நிறுவனம் -> நிறுவனங்கள்)
  'ங்களுக்கான', 'ங்களுக்கு', 'ங்களுடன்', 'ங்களிடம்', 'ங்களால்', 'ங்களில்',
  'ங்களின்', 'ங்களை', 'ங்களாக', 'ங்களான', 'ங்களும்', 'ங்கள்',
  // case endings of -ம் nouns (திட்டம் -> திட்டத்தில்)
  'த்துக்கான', 'த்துக்கு', 'த்துடன்', 'த்தினால்', 'த்திலிருந்து', 'த்தில்',
  'த்தின்', 'த்தை', 'த்தால்', 'த்தாக', 'த்தான', 'த்தும்', 'த்து',
  // after a vowel-ending noun with the "ய" glide (நிதி -> நிதியை)
  'யுடன்',
  'யினால்',
  'யிலிருந்து',
  'யில்',
  'யின்',
  'யை',
  'யால்',
  'யாக',
  'யான',
  'யும்',
  // after a doubled ண் (பெண் -> பெண்ணுக்கு)
  'ணுக்கான', 'ணுக்கு', 'ணுடன்', 'ணிடம்', 'ணின்', 'ணால்', 'ணை',
  // ordinary case endings
  'ுக்கான', 'ுக்கு', 'ுடன்', 'ிடமிருந்து', 'ிடம்', 'ினால்', 'ிலிருந்து',
  'ின்', 'ில்', 'ால்', 'ாக', 'ான', 'ையும்', 'ைப்', 'ைத்', 'ை', 'ும்',
  'க்கான', 'க்கு', 'க்கும்', 'ப்பான', 'ப்பு', 'ம்',
];

final List<List<int>> _tamilSuffixes = ([
  for (final s in _tamilSuffixList) s.runes.toList(),
]..sort((a, b) => b.length.compareTo(a.length)));

/// A Tamil letter count that ignores vowel signs and the pulli (virama), so
/// the minimum stem is measured in letters, not code points.
int _tamilLetters(List<int> runes) {
  var n = 0;
  for (final c in runes) {
    final isSign = (c >= 0x0BBE && c <= 0x0BCD) || c == 0x0B82;
    if (!isSign) n++;
  }
  return n;
}

/// Tamil stem of [word] (a Tamil token).
String tamilStem(String word) {
  final runes = word.runes.toList();
  for (final s in _tamilSuffixes) {
    if (s.length >= runes.length) continue;
    var matches = true;
    for (var i = 0; i < s.length; i++) {
      if (runes[runes.length - s.length + i] != s[i]) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    final stem = runes.sublist(0, runes.length - s.length);
    if (_tamilLetters(stem) < _tamilMinStem) continue;
    return _dropFinalPulli(stem);
  }
  return _dropFinalPulli(runes);
}

/// A word's own final pulli ("கொள்முதல்") is lost when a suffix attaches
/// ("கொள்முதலுக்கு"), so stems are compared without it.
String _dropFinalPulli(List<int> runes) {
  if (runes.length > 1 && runes.last == 0x0BCD) {
    return String.fromCharCodes(runes.sublist(0, runes.length - 1));
  }
  return String.fromCharCodes(runes);
}

/// Stem of [word] by its script; other words are returned unchanged.
String indicStem(String word) {
  for (final c in word.runes) {
    if (c >= 0x0900 && c <= 0x097F) return hindiStem(word);
    if (c >= 0x0B80 && c <= 0x0BFF) return tamilStem(word);
  }
  return word;
}
