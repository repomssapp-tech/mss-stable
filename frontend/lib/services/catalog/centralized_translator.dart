import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// CentralizedTranslator
/// ─────────────────────
/// Centralized translation engine converting English catalog text, categories,
/// chips, badges, document names, service items, eligibility rules, and timeline steps
/// into accurate, natural Tamil when Tamil mode is active.
///
/// Priority Pipeline:
/// 1. Catalog JSON Tamil values (preferred if available).
/// 2. Centralized Flutter translation dictionary & sentence converter.
/// 3. Protected fields (URLs, emails, phone numbers, IDs, codes, dates, currency values) preserved.
///
/// C6 (Frontend Refactor): The static ~800-line dictionary mappings (tagMap,
/// phraseMap, termMap) are stored in `assets/catalog/translation_dictionary.json`
/// and loaded/cached at runtime, reducing file bloat while maintaining 100%
/// synchronous translation parity.
class CentralizedTranslator {
  CentralizedTranslator._();

  static final CentralizedTranslator instance = CentralizedTranslator._();

  static const String assetPath = 'assets/catalog/translation_dictionary.json';

  /// Hindi counterpart of [assetPath]: exact (lower-cased) English phrase or
  /// tag -> Hindi. Unlike the Tamil path there is no word-level rewriting, so
  /// text with no exact entry stays English instead of turning into a mix.
  static const String hiAssetPath =
      'assets/catalog/translation_dictionary_hi.json';

  /// Language the UI is currently shown in (`en`, `ta`, `hi`). Kept in sync by
  /// `main.dart`; [localize] and [localizeTag] follow it.
  String activeLanguage = 'en';

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.(gov|in|org|com|net|edu)(\/[^\s]*)?)',
    caseSensitive: false,
  );

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(\+91[\s-]?)?(\(?\d{3,5}\)?[\s-]?)?\d{6,8}',
  );

  static final RegExp _codeIdRegex = RegExp(r'^[A-Z0-9_]{3,20}$');

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Map<String, String> _tagMap = const {};
  Map<String, String> _phraseMap = const {};
  Map<String, String> _termMap = const {};
  List<String> _sortedPhrases = const [];
  List<String> _sortedTerms = const [];

  void _populate(Map<String, dynamic> json) {
    if (json['tagMap'] is Map) {
      _tagMap = (json['tagMap'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    if (json['phraseMap'] is Map) {
      _phraseMap = (json['phraseMap'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    if (json['termMap'] is Map) {
      _termMap = (json['termMap'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    _sortedPhrases = _phraseMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    _sortedTerms = _termMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    _loaded = true;
  }

  bool _hiLoaded = false;
  Map<String, String> _hiTagMap = const {};
  Map<String, String> _hiPhraseMap = const {};

  void _populateHi(Map<String, dynamic> json) {
    Map<String, String> read(Object? raw) => raw is Map
        ? raw.map((k, v) => MapEntry(k.toString(), v.toString()))
        : const {};
    _hiTagMap = read(json['tagMap']);
    _hiPhraseMap = read(json['phraseMap']);
    _hiLoaded = true;
  }

  void _ensureHiInitializedSync() {
    if (_hiLoaded) return;
    for (final path in const [hiAssetPath, 'frontend/$hiAssetPath']) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          _populateHi(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          );
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _ensureHiLoaded() async {
    if (_hiLoaded) return;
    try {
      _populateHi(
        jsonDecode(await rootBundle.loadString(hiAssetPath))
            as Map<String, dynamic>,
      );
    } catch (_) {
      _ensureHiInitializedSync();
    }
  }

  /// Text for the active UI language: Tamil via the full [translate] pipeline,
  /// Hindi via exact dictionary lookup, anything else unchanged.
  String localize(String? input) => localizeFor(activeLanguage, input);

  /// Tag/chip variant of [localize].
  String localizeTag(String? rawTag) => localizeTagFor(activeLanguage, rawTag);

  /// Like [localize] for callers that already hold a language code.
  String localizeFor(String lang, String? input) {
    switch (lang) {
      case 'ta':
        return translate(input);
      case 'hi':
        return _translateHi(input);
      default:
        return input ?? '';
    }
  }

  /// Like [localizeTag] for callers that already hold a language code.
  String localizeTagFor(String lang, String? rawTag) {
    switch (lang) {
      case 'ta':
        return translateTag(rawTag);
      case 'hi':
        return _translateHi(rawTag, tag: true);
      default:
        return rawTag ?? '';
    }
  }

  String _translateHi(String? input, {bool tag = false}) {
    if (!_hiLoaded) _ensureHiInitializedSync();
    if (input == null) return '';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return input;
    final lower = trimmed.toLowerCase();
    final first = tag ? _hiTagMap : _hiPhraseMap;
    final second = tag ? _hiPhraseMap : _hiTagMap;
    // An exact dictionary entry wins even if the text contains a URL.
    final exact = first[lower] ?? second[lower];
    if (exact != null) return exact;
    return input;
  }

  /// Synchronously ensures the dictionary is loaded.
  /// Uses direct file read if running in tests / VM before asset bundle is ready.
  void _ensureInitializedSync() {
    if (_loaded) return;
    const candidates = [assetPath, 'frontend/$assetPath'];
    for (final path in candidates) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final raw =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          _populate(raw);
          return;
        }
      } catch (_) {}
    }
  }

  /// Asynchronously loads and caches the shared translation dictionary JSON.
  /// Idempotent and safe to call from multiple sites (e.g. app bootstrap).
  Future<void> ensureLoaded() async {
    await _ensureHiLoaded();
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      _populate(raw);
    } catch (_) {
      // Fallback for flutter test / missing asset bundle -- direct file read.
      const candidates = [assetPath, 'frontend/$assetPath'];
      for (final path in candidates) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final raw =
                jsonDecode(await file.readAsString()) as Map<String, dynamic>;
            _populate(raw);
            return;
          }
        } catch (_) {}
      }
    }
  }

  /// Check if a given string should be preserved without translation.
  bool isProtectedText(String? input) {
    if (input == null) return true;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return true;

    // Preserve URLs
    if (_urlRegex.hasMatch(trimmed)) return true;
    // Preserve Emails
    if (_emailRegex.hasMatch(trimmed)) return true;
    // Preserve Scheme Codes / IDs
    if (_codeIdRegex.hasMatch(trimmed) && !trimmed.contains(' ')) return true;
    // Preserve Phone numbers
    if (_phoneRegex.hasMatch(trimmed) &&
        RegExp(r'^\+?[0-9\s-]{7,15}$').hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  /// Translate short tags, categories, levels, and chip labels.
  String translateTag(String? rawTag) {
    if (!_loaded) _ensureInitializedSync();
    if (rawTag == null) return '';
    final trimmed = rawTag.trim();
    if (trimmed.isEmpty) return rawTag;

    final lower = trimmed.toLowerCase();
    if (_tagMap.containsKey(lower)) {
      return _tagMap[lower] ?? rawTag;
    }
    if (isProtectedText(trimmed)) return rawTag;

    // Substring or fallback phrase map lookup
    if (_phraseMap.containsKey(lower)) {
      return _phraseMap[lower] ?? rawTag;
    }

    return translate(rawTag);
  }

  /// Translate dynamic text, descriptions, eligibility criteria, document items, services, or process steps.
  String translate(String? input) {
    if (!_loaded) _ensureInitializedSync();
    if (input == null) return '';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return input;

    final lower = trimmed.toLowerCase();
    if (_phraseMap.containsKey(lower)) {
      return _phraseMap[lower] ?? input;
    }
    if (_tagMap.containsKey(lower)) {
      return _tagMap[lower] ?? input;
    }
    if (isProtectedText(trimmed)) return input;

    String translated = trimmed;

    // 1. Pattern-based sentence transformations (runs on full original sentence)
    _sentencePatterns.forEach((pattern, replacement) {
      translated = translated.replaceAllMapped(pattern, (m) {
        return replacement(m);
      });
    });

    // 2. Step prefix replacements (e.g. "Step 1:", "Step 2:")
    translated = translated.replaceAllMapped(
      RegExp(r'\bStep\s+(\d+):?', caseSensitive: false),
      (m) => 'படி ${m.group(1) ?? ''}:',
    );

    // 3. Phrase replacements (sorted by length descending)
    for (final enPhrase in _sortedPhrases) {
      final taPhrase = _phraseMap[enPhrase]!;
      final reg = RegExp(
        r'\b' + RegExp.escape(enPhrase) + r'\b',
        caseSensitive: false,
      );
      if (reg.hasMatch(translated)) {
        translated = translated.replaceAll(reg, taPhrase);
      }
    }

    // 4. Term replacements (sorted by length descending)
    for (final enTerm in _sortedTerms) {
      final taTerm = _termMap[enTerm]!;
      final reg = RegExp(
        r'\b' + RegExp.escape(enTerm) + r'\b',
        caseSensitive: false,
      );
      if (reg.hasMatch(translated)) {
        translated = translated.replaceAll(reg, taTerm);
      }
    }

    return translated;
  }

  // ── Sentence Patterns ──────────────────────────────────────────────────

  static final Map<RegExp, String Function(Match)> _sentencePatterns = {
    RegExp(r'\bprovides?\s+capital\s+subsidy\b', caseSensitive: false): (m) =>
        'மூலதன மானிய நிதி உதவி வழங்குகிறது',
    RegExp(r'\bfinancial\s+assistance\s+for\b', caseSensitive: false): (m) =>
        'க்கான நிதி உதவி',
    RegExp(r'\bcredit\s+guarantee\s+cover\b', caseSensitive: false): (m) =>
        'கடன் உத்தரவாத பாதுகாப்பு',
    RegExp(r'\binterest\s+subvention\b', caseSensitive: false): (m) =>
        'வட்டி மானியம்',
    RegExp(r'\bmargin\s+money\s+assistance\b', caseSensitive: false): (m) =>
        'முன்பண நிதி உதவி',
    RegExp(
      r'\bfor\s+micro\s+and\s+small\s+enterprises\b',
      caseSensitive: false,
    ): (m) =>
        'குறு மற்றும் சிறு தொழில்களுக்காக',
    RegExp(r'\bin\s+tamil\s+nadu\b', caseSensitive: false): (m) =>
        'தமிழ்நாட்டில்',
    RegExp(
      r'\b(all\s+over\s+india|pan-india|across\s+india)\b',
      caseSensitive: false,
    ): (m) =>
        'இந்தியா முழுவதும்',
    RegExp(r'\btarget\s+beneficiaries:\s*', caseSensitive: false): (m) =>
        'பயனாளிகள்: ',
    RegExp(r'\bissued\s+by:\s*', caseSensitive: false): (m) => 'வழங்கியவர்: ',
    RegExp(r'\bestimated\s+cost:\s*', caseSensitive: false): (m) =>
        'மதிப்பிடப்பட்ட செலவு: ',
    RegExp(
      r'\bno\s+educational\s+qualification\s+required\b',
      caseSensitive: false,
    ): (m) =>
        'கல்வித் தகுதி தேவையில்லை',
    RegExp(r'\b8th\s+standard\s+pass\b', caseSensitive: false): (m) =>
        '8-ஆம் வகுப்பு தேர்ச்சி',
    RegExp(
      r'\baged?\s+between\s+(\d+)\s+and\s+(\d+)\s+years?\b',
      caseSensitive: false,
    ): (m) =>
        'வயது ${m.group(1) ?? ''} முதல் ${m.group(2) ?? ''} வரை',
    RegExp(
      r'\brolling\s+intake\s+throughout\s+(financial|fiscal|நிதி)\s+year\b',
      caseSensitive: false,
    ): (m) =>
        'நிதி ஆண்டு முழுவதும் தொடர் விண்ணப்ப ஏற்பு',
    RegExp(
      r'\bstep\s+1:\s*register\s+and\s+fill\s+online\s+application\s+via\s+(.*?)\s+portal\b',
      caseSensitive: false,
    ): (m) =>
        'படி 1: ${m.group(1) ?? ''} இணையதளம் மூலம் ஆன்லைன் விண்ணப்பத்தைப் பதிவு செய்து பூர்த்தி செய்யவும்',
    RegExp(
      r'\bstep\s+2:\s*submit\s+application\s+copy\s+and\s+checklist\s+documents\s+to\s+(.*?)\b',
      caseSensitive: false,
    ): (m) =>
        'படி 2: விண்ணப்ப நகல் மற்றும் சரிபார்ப்பு ஆவணங்களை ${m.group(1) ?? ''} இடம் சமர்ப்பிக்கவும்',
    RegExp(
      r'\bstep\s+3:\s*verification\s+&\s+field\s+inspection\s+by\s+(.*?)\b',
      caseSensitive: false,
    ): (m) =>
        'படி 3: ${m.group(1) ?? ''} மூலம் சரிபார்ப்பு மற்றும் கள ஆய்வு',
    RegExp(
      r'\bstep\s+4:\s*approval\s+and\s+direct\s+benefit\s+transfer\s*\(dbt\)\s*\/\s*subsidy\s+credit\s+to\s+bank\s+account\b',
      caseSensitive: false,
    ): (m) =>
        'படி 4: ஒப்புதல் மற்றும் நேரடி பயன் பரிமாற்றம் (DBT) / மானிய கடன் தொகையை வங்கி கணக்கில் செலுத்துதல்',
    RegExp(
      r'\bstep\s+5:\s*physical\s+verification\s+after\s+(\d+)\s+years?\b',
      caseSensitive: false,
    ): (m) =>
        'படி 5: ${m.group(1) ?? ''} ஆண்டுகளுக்குப் பிறகு நேரடி ஆய்வு',
    RegExp(
      r'\b(online\s+portal|official\s+portal)\s+registration\b',
      caseSensitive: false,
    ): (m) =>
        'ஆன்லைன் இணையதள பதிவு',
    RegExp(
      r'\bsubmit\s+project\s+report\s+and\s+documents\b',
      caseSensitive: false,
    ): (m) =>
        'திட்ட அறிக்கை மற்றும் ஆவணங்களைச் சமர்ப்பிக்கவும்',
    RegExp(
      r'\bbank\s+loan\s+sanction\s+and\s+disbursement\b',
      caseSensitive: false,
    ): (m) =>
        'வங்கி கடன் அனுமதி மற்றும் நிதி வழங்கல்',
    RegExp(r'\bsubsidy\s+claim\s+and\s+release\b', caseSensitive: false): (m) =>
        'மானியக் கோரிக்கை மற்றும் விடுவிப்பு',
    RegExp(
      r'\bproject\s+cost\s+up\s+to\s+rs\.?\s*(\d+(\.\d+)?)\s*(lakhs?|crores?|cr|l)\b',
      caseSensitive: false,
    ): (m) =>
        'ரூ. ${m.group(1) ?? ''} ${m.group(3) ?? ''} வரையிலான திட்டச் செலவு',
    RegExp(r'\bsubsidy\s+up\s+to\s+(\d+)\s*%\b', caseSensitive: false): (m) =>
        '${m.group(1) ?? ''}% வரை மானியம்',
    RegExp(r'\bminimum\s+age\s+(\d+)\s+years?\b', caseSensitive: false): (m) =>
        'குறைந்தபட்ச வயது ${m.group(1) ?? ''} ஆண்டுகள்',
    RegExp(r'\bmaximum\s+age\s+(\d+)\s+years?\b', caseSensitive: false): (m) =>
        'அதிகபட்ச வயது ${m.group(1) ?? ''} ஆண்டுகள்',
    RegExp(
      r'\blender\s+charges\s+as\s+applicable\b',
      caseSensitive: false,
    ): (m) =>
        'கடன் வழங்கும் நிறுவனக் கட்டணங்கள் பொருந்தும்',
  };

  @visibleForTesting
  Map<String, String> get tagMapForTesting {
    if (!_loaded) _ensureInitializedSync();
    return _tagMap;
  }

  @visibleForTesting
  Map<String, String> get phraseMapForTesting {
    if (!_loaded) _ensureInitializedSync();
    return _phraseMap;
  }

  @visibleForTesting
  Map<String, String> get termMapForTesting {
    if (!_loaded) _ensureInitializedSync();
    return _termMap;
  }

  @visibleForTesting
  static void resetForTesting() {
    instance._loaded = false;
    instance._tagMap = const {};
    instance._phraseMap = const {};
    instance._termMap = const {};
    instance._sortedPhrases = const [];
    instance._sortedTerms = const [];
  }
}
