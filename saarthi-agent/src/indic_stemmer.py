"""Light stemmers for Hindi (Devanagari) and Tamil search.

Mirror of frontend/lib/services/search/indic_stemmer.dart -- keep the two in
step; tests on both sides share frontend/test/fixtures/indic_stem_cases.json.

Both languages inflect by attaching suffixes, so "महिला", "महिलाओं" and
"महिलाएं" (or "திட்டம்", "திட்டத்தில்", "திட்டங்கள்") are one word to a reader
but different strings to a search index. Stemming both the indexed words and
the query words makes them meet.

Hindi is the "Lightweight Stemmer for Hindi" (Ramanathan & Rao, 2003) as
implemented by the Snowball project: remove the longest matching suffix that
leaves at least one character; suffixes marked after-consonant are removed only
when a consonant precedes them.
"""

from __future__ import annotations

# Independent-vowel forms (used when the stem already ends in a vowel letter).
_HINDI_INDEPENDENT = [
    "्", "अ", "आ", "इ", "ई", "उ", "ऊ", "ए", "ओ",
    "एं", "ओं", "आं", "उआं", "उएं", "उओं", "आएं", "आओं",
    "इयां", "इयों", "आइयां", "आइयों",
    "आँ", "इयाँ", "आइयाँ",
    "अताएं", "अताओं", "अनाएं", "अनाओं", "अता", "अती",
    "ईं", "अतीं", "अते",
    "आता", "आती", "आतीं", "आते", "अना", "अनी", "अने",
    "आना", "आने",
    "ऊंगा", "ऊंगी", "आऊंगा", "आऊंगी",
    "एंगे", "एंगी", "आएंगे", "आएंगी",
    "ओगे", "ओगी", "आओगे", "आओगी",
    "एगा", "एगी", "आएगा", "आएगी",
    "आया", "आए", "आई", "आईं", "इए", "आओ", "आइए", "अकर", "आकर",
]

# Dependent vowel signs (the usual case: a consonant + the ending).
_HINDI_DEPENDENT = [
    "ा", "ि", "ी", "ु", "ू", "े", "ो", "ें", "ों", "ां",
    "ुआं", "ुएं", "ुओं", "ाएं", "ाओं",
    "ियां", "ियों", "ाइयां", "ाइयों",
    "ाँ", "ियाँ", "ाइयाँ", "ीं",
    "ाता", "ाती", "ाते", "ातीं", "ाना", "ाने",
    "ूंगा", "ूंगी", "ाऊंगा", "ाऊंगी",
    "ेंगे", "ेंगी", "ाएंगे", "ाएंगी",
    "ोगे", "ोगी", "ाओगे", "ाओगी",
    "ेगा", "ेगी", "ाएगा", "ाएगी",
    "ाया", "ाए", "ाई", "ाईं", "िए", "ाओ", "ाइए", "ाकर",
]

# Endings that start with an implicit "a" consonant: removed only after a
# consonant (so they are not cut out of the middle of a longer word).
_HINDI_AFTER_CONSONANT = [
    "ताएं", "ताओं", "नाएं", "नाओं", "ता", "ती", "तीं", "ते", "ना", "नी", "ने", "कर",
]

_HINDI_SUFFIXES = sorted(
    [(s, False) for s in _HINDI_INDEPENDENT]
    + [(s, False) for s in _HINDI_DEPENDENT]
    + [(s, True) for s in _HINDI_AFTER_CONSONANT],
    key=lambda item: -len(item[0]),
)


def _is_devanagari_consonant(ch: str) -> bool:
    c = ord(ch)
    return (
        0x0915 <= c <= 0x0939
        or 0x0958 <= c <= 0x095F
        or c in (0x0929, 0x0931, 0x0934, 0x093C)
    )


def hindi_stem(word: str) -> str:
    """Hindi stem of `word` (a Devanagari token)."""
    for suffix, after_consonant in _HINDI_SUFFIXES:
        if len(suffix) >= len(word) or not word.endswith(suffix):
            continue
        if after_consonant and not _is_devanagari_consonant(word[-len(suffix) - 1]):
            continue
        return word[: -len(suffix)]
    return word


# Tamil: a conservative suffix stripper. The suffix families were read off the
# catalog's own Tamil text (tools/indic_suffix_mining.py): plural "கள்", case
# endings, the sound changes of -ம் nouns ("திட்டம்" -> "திட்டத்தில்",
# "திட்டங்கள்") and the "ய" glide after a vowel ("நிதி" -> "நிதியை"). Only the
# longest matching ending is removed, and never below _TAMIL_MIN_STEM letters.
_TAMIL_MIN_STEM = 2

_TAMIL_SUFFIX_LIST = [
    # agent nouns (ஏற்றுமதி "export" -> ஏற்றுமதியாளர் "exporter")
    "யாளர்களுக்கு", "யாளர்களின்", "யாளர்கள்", "யாளருக்கு", "யாளர்",
    # "for the sake of" / "for"
    "ுக்காகவும்", "ுக்காக", "க்காகவும்", "க்காக", "த்துக்காக", "களுக்காக",
    # plural + case
    "களுக்காகவும்", "களுக்கான", "களுக்கு", "களுடன்", "களிடமிருந்து", "களிடம்",
    "களினால்", "களால்", "களில்", "களின்", "களை", "களாக", "களான", "களும்", "கள்",
    # plural of -ம் nouns (நிறுவனம் -> நிறுவனங்கள்)
    "ங்களுக்கான", "ங்களுக்கு", "ங்களுடன்", "ங்களிடம்", "ங்களால்", "ங்களில்",
    "ங்களின்", "ங்களை", "ங்களாக", "ங்களான", "ங்களும்", "ங்கள்",
    # case endings of -ம் nouns (திட்டம் -> திட்டத்தில்)
    "த்துக்கான", "த்துக்கு", "த்துடன்", "த்தினால்", "த்திலிருந்து", "த்தில்",
    "த்தின்", "த்தை", "த்தால்", "த்தாக", "த்தான", "த்தும்", "த்து",
    # after a vowel-ending noun with the "ய" glide (நிதி -> நிதியை)
    "யுடன்", "யினால்", "யிலிருந்து", "யில்", "யின்", "யை", "யால்", "யாக", "யான", "யும்",
    # after a doubled ண் (பெண் -> பெண்ணுக்கு)
    "ணுக்கான", "ணுக்கு", "ணுடன்", "ணிடம்", "ணின்", "ணால்", "ணை",
    # ordinary case endings
    "ுக்கான", "ுக்கு", "ுடன்", "ிடமிருந்து", "ிடம்", "ினால்", "ிலிருந்து",
    "ின்", "ில்", "ால்", "ாக", "ான", "ையும்", "ைப்", "ைத்", "ை", "ும்",
    "க்கான", "க்கு", "க்கும்", "ப்பான", "ப்பு", "ம்",
]
_TAMIL_SUFFIXES = sorted(_TAMIL_SUFFIX_LIST, key=lambda s: -len(s))


def _tamil_letters(text: str) -> int:
    """Tamil letter count ignoring vowel signs and the pulli (virama)."""
    n = 0
    for ch in text:
        c = ord(ch)
        if not (0x0BBE <= c <= 0x0BCD or c == 0x0B82):
            n += 1
    return n


def tamil_stem(word: str) -> str:
    """Tamil stem of `word` (a Tamil token)."""
    for suffix in _TAMIL_SUFFIXES:
        if len(suffix) >= len(word) or not word.endswith(suffix):
            continue
        stem = word[: -len(suffix)]
        if _tamil_letters(stem) < _TAMIL_MIN_STEM:
            continue
        return _drop_final_pulli(stem)
    return _drop_final_pulli(word)


def _drop_final_pulli(word: str) -> str:
    """A word's own final pulli ("கொள்முதல்") is lost when a suffix attaches
    ("கொள்முதலுக்கு"), so stems are compared without it."""
    if len(word) > 1 and word.endswith("்"):
        return word[:-1]
    return word


def indic_stem(word: str) -> str:
    """Stem of `word` by its script; other words are returned unchanged."""
    for ch in word:
        c = ord(ch)
        if 0x0900 <= c <= 0x097F:
            return hindi_stem(word)
        if 0x0B80 <= c <= 0x0BFF:
            return tamil_stem(word)
    return word
