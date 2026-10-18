import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../../models/mss_entity.dart';
import 'intelligent_scheme_search.dart' show SchemeSearchMatch;
import '../catalog/mss_catalog_bundle.dart';
import '../catalog/mss_scheme_adapter.dart';

/// Deterministic query-tag normalizer, faithfully ported from
/// `Plan/catalog/taxonomy_engine.py` (the reference implementation the
/// backend `mss_api_rc1.py` search endpoint uses). A controlled vocabulary +
/// keyword/pattern matcher over a versioned table -- not an LLM call, so the
/// same query always produces the same tags.
///
/// 1.2 (audit_fix.md): every field below is loaded once from
/// `assets/search/search_taxonomy.json` -- the single source of truth also
/// read by search_engine.ts (TypeScript) and scheme_catalog.py (Python),
/// instead of being declared independently in each language. [ensureLoaded]
/// must be awaited before any other member of this class is used (Dart
/// cannot load JSON at `const` time, so these are runtime-initialized, not
/// compile-time constants as before). Do not hand-edit these values here;
/// edit `backend/catalog/search_taxonomy.json` (the canonical copy) and
/// re-sync all three engines' local copies plus their parity tests.
class SchemeSearchTaxonomy {
  const SchemeSearchTaxonomy._();

  static const String assetPath = 'assets/search/search_taxonomy.json';

  static bool _loaded = false;

  // Only way a <3-char token becomes searchable. Derived from the same
  // controlled sources as the Python original; do not add to this without
  // re-deriving from the catalog (see taxonomy_engine.py's own comment).
  static Set<String> shortTokenVocab = const {};

  static Map<String, List<String>> industries = const {};
  static Map<String, List<String>> benefits = const {};
  // Two DISTINCT concepts, deliberately not merged: a lender waiving
  // security ("collateral_free") is not the same fact as a third party
  // covering default risk ("guarantee_backed").
  static Map<String, List<String>> collateral = const {};
  static Map<String, List<String>> treds = const {};
  static Map<String, List<String>> communities = const {};
  static Map<String, List<String>> intents = const {};

  // Partial (not full) credit across related-but-distinct concepts.
  static Map<String, List<String>> relatedConcepts = const {};

  static Map<String, double> weights = const {};

  // Applies AFTER the weighted sum as a uniform multiplicative factor keyed
  // only on identity.status. "closed" is discounted, never zeroed -- an
  // explicitly relevant closed scheme still outranks an unrelated active
  // one. "unknown" gets no penalty: absence of confirmed status is not
  // evidence of closure.
  static Map<String, double> statusFactor = const {};
  static Map<String, String> statusToConcept = const {};
  static List<String> semanticQueryGroups = const [];

  // Mirrors the index builder's tokenizer regex so a query term and an
  // index term share the same surface form.
  static RegExp tokenRe = RegExp('');

  /// Loads and caches the shared taxonomy JSON. Idempotent and safe to call
  /// from multiple call sites (every [HybridSchemeSearch.build]); the file
  /// is only actually read once per process.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    String jsonStr;
    try {
      jsonStr = await rootBundle.loadString(assetPath);
    } catch (_) {
      // Fallback for flutter test / missing asset bundle -- direct file read.
      jsonStr = await File(assetPath).readAsString();
    }
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    shortTokenVocab = (data['shortTokenVocab'] as List).cast<String>().toSet();
    tokenRe = RegExp(data['tokenRegexSource'] as String);

    final taxonomy = data['taxonomy'] as Map<String, dynamic>;
    industries = _stringListMap(taxonomy['industries']);
    benefits = _stringListMap(taxonomy['benefits']);
    collateral = _stringListMap(taxonomy['collateral']);
    treds = _stringListMap(taxonomy['treds']);
    communities = _stringListMap(taxonomy['communities']);
    intents = _stringListMap(taxonomy['intents']);

    relatedConcepts = _stringListMap(data['relatedConcepts']);
    weights = (data['weights'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    statusFactor = (data['statusFactor'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    statusToConcept =
        (data['statusToConcept'] as Map<String, dynamic>).cast<String, String>();
    semanticQueryGroups =
        (data['semanticQueryGroups'] as List).cast<String>();

    _loaded = true;
  }

  static Map<String, List<String>> _stringListMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  static bool isSearchableToken(String token) {
    final t = token.toLowerCase();
    return t.length >= 3 || shortTokenVocab.contains(t);
  }

  static List<String> _find(String textLower, Map<String, List<String>> table) {
    final hits = <String>[];
    for (final entry in table.entries) {
      for (final term in entry.value) {
        if (textLower.contains(term)) {
          hits.add(entry.key);
          break;
        }
      }
    }
    return hits;
  }

  /// Deterministic: same text always returns the same tags in the same
  /// order (table-declaration order, not match order).
  static Map<String, List<String>> normalize(String text) {
    final textLower =
        ' ${text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0900-\u097F\u0B80-\u0BFF ]'), ' ')} ';
    return {
      'industries': _find(textLower, industries),
      'benefits': _find(textLower, benefits),
      'collateral': _find(textLower, collateral),
      'treds': _find(textLower, treds),
      'communities': _find(textLower, communities),
      'intents': _find(textLower, intents),
    };
  }

  /// Given matched concept tags (from collateral or treds), return the tags
  /// that partially reinforce them -- used for partial-credit scoring only,
  /// never full-credit merging.
  static Set<String> expandRelated(Iterable<String> concepts) {
    final expanded = <String>{};
    for (final c in concepts) {
      expanded.addAll(relatedConcepts[c] ?? const []);
    }
    return expanded;
  }
}

/// One query concept: the set of equivalent surface forms (hyphenation,
/// vocabulary-gated plural/singular) sharing one IDF weight.
class _Concept {
  const _Concept(this.forms, this.idf);
  final Set<String> forms;
  final double idf;
}

class _ScoredScheme {
  _ScoredScheme(this.entry, this.score);
  final MssEntity entry;
  final double score;
}

/// Precomputed lookup surface for one scheme: the forms a name/acronym/alias
/// query is matched against. Built once per engine, cached. Kept entirely
/// out of the parity-locked scoring path ([HybridSchemeSearch.search] /
/// `_scoreEntry` / `search_taxonomy.json`).
class _LookupEntry {
  _LookupEntry({
    required this.entry,
    required this.fullForms,
    required this.acronym,
    required this.shortName,
    required this.nameTokens,
    required this.meaningfulNameCount,
  });

  final MssEntity entry;

  /// Normalised whole-string forms: localised names + every alias.
  final Set<String> fullForms;

  /// Curated `identity.acronym`, normalised and space-stripped ('' if none).
  final String acronym;

  /// Curated `identity.shortName`, normalised and space-stripped ('' if none).
  final String shortName;

  /// Union of meaningful tokens across the English name and all aliases.
  final Set<String> nameTokens;

  /// Meaningful-token count of the English name alone (tier-3 denominator).
  final int meaningfulNameCount;
}

/// Offline port of `Plan/catalog/hybrid_search.py` -- the same ranking
/// formula the backend's `/v1/search` endpoint uses server-side:
///
///   FinalScore = w1*Keyword + w2*Semantic + w3*Category + w4*Eligibility
///              + w5*Benefit  (w6*UserProfile is always 0, same as upstream)
///
/// applied with the same IDF term-rarity weighting, taxonomy-based query
/// normalization, and status-aware ranking factor, deterministically sorted
/// (score desc, entityId asc tiebreak) -- so offline results match what the
/// server would return for the same catalog data. This is the single
/// offline search implementation for catalog search; it is not a second,
/// independently-tuned engine.
class HybridSchemeSearch {
  HybridSchemeSearch._(this._bundle, this._schemeEntries, this._expansions) {
    _semanticCodes = {
      for (final entry in _schemeEntries)
        entry.id: _semanticTagCodes(entry),
    };
    _buildIdf();
    // Split the expansion dictionary into phrase keys (multi-word,
    // matched against the raw query) and single-token keys (matched
    // per-token during concept building). Done once at build time.
    for (final entry in _expansions.entries) {
      if (entry.key.contains(' ')) {
        _phraseExpansions[entry.key] = entry.value;
      } else {
        _tokenExpansions[entry.key] = entry.value;
      }
    }
  }

  final MssCatalogBundle _bundle;
  final List<MssEntity> _schemeEntries;
  final Map<String, List<String>> _expansions;
  final Map<String, List<String>> _phraseExpansions = {};
  final Map<String, List<String>> _tokenExpansions = {};
  late final Map<String, Set<String>> _semanticCodes;
  final Map<String, Set<String>> _entryTermCache = {};
  late int _nDocs;
  late Set<String> _vocab;

  static Future<HybridSchemeSearch> build(MssCatalogBundle bundle) async {
    await SchemeSearchTaxonomy.ensureLoaded();
    return HybridSchemeSearch._(bundle, bundle.schemes, bundle.queryExpansions);
  }

  Set<String> _semanticTagCodes(MssEntity entry) {
    final ai = entry.raw['ai'] as Map<String, dynamic>?;
    final tags = ai?['semanticTags'] as List?;
    if (tags == null) return const {};
    return {
      for (final t in tags)
        if (t is Map && t['code'] is String) t['code'] as String,
    };
  }

  Set<String> _stringSet(dynamic value) {
    if (value is! List) return const {};
    return value.map((e) => e.toString()).toSet();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> _profileOf(MssEntity entry) {
    final profile = _bundle.searchProfiles[entry.id];
    return profile?['schemeSearchProfile'] as Map<String, dynamic>? ?? const {};
  }

  /// Every field the keyword scorer consults, with its field weight.
  /// Single source of truth so IDF is computed over exactly the terms that
  /// can actually be matched.
  List<(List<String> tokens, double weight)> _searchableFields(
    MssEntity entry,
  ) {
    final profile = _bundle.searchProfiles[entry.id];
    final tokens = profile?['tokens'] as Map<String, dynamic>?;
    final searchProfile = _profileOf(entry);
    final aliasRaw = (entry.search['aliases'] as Map<String, dynamic>?) ?? const {};
    final kwRaw = (entry.search['keywords'] as Map<String, dynamic>?) ?? const {};
    final isDevanagari = RegExp(r'[\u0900-\u097F]');
    final hiNameTokens = _meaningfulTokens(_normLookup(entry.getLocalizedName('hi')))
        .where(isDevanagari.hasMatch)
        .toList();
    final hiAliasTokens = [
      for (final a in _stringList(aliasRaw['hi']))
        ..._meaningfulTokens(_normLookup(a)),
    ].where(isDevanagari.hasMatch).toList();
    final hiKwTokens = [
      for (final k in _stringList(kwRaw['hi']))
        ..._meaningfulTokens(_normLookup(k)),
    ].where(isDevanagari.hasMatch).toList();
    return [
      (_stringList(tokens?['en']), 1.0),
      (_stringList(tokens?['ta']), 1.0),
      (_stringList(tokens?['hi']), 1.0),
      (hiNameTokens, 1.0),
      (hiAliasTokens, 1.0),
      (hiKwTokens, 1.0),
      (
        _stringList(searchProfile['loanType'])
            .map((e) => e.toLowerCase())
            .toList(),
        0.9,
      ),
      (
        _stringList(searchProfile['subsidyType'])
            .map((e) => e.toLowerCase())
            .toList(),
        0.9,
      ),
      (
        _stringList(searchProfile['taxBenefits'])
            .map((e) => e.toLowerCase())
            .toList(),
        0.7,
      ),
      (
        _stringList(searchProfile['clusters'])
            .map((e) => e.toLowerCase())
            .toList(),
        0.7,
      ),
      (
        _stringList(searchProfile['industryTags'])
            .map((e) => e.toLowerCase())
            .toList(),
        0.8,
      ),
      (
        _stringList(searchProfile['benefitTags'])
            .map((e) => e.toLowerCase())
            .toList(),
        0.8,
      ),
    ];
  }

  Set<String> _entryTerms(MssEntity entry) {
    return _entryTermCache.putIfAbsent(entry.id, () {
      final terms = <String>{};
      for (final (tokens, _) in _searchableFields(entry)) {
        terms.addAll(tokens);
      }
      return terms;
    });
  }

  void _buildIdf() {
    _nDocs = _schemeEntries.length;
    final vocab = <String>{};
    for (final entry in _schemeEntries) {
      for (final (tokens, _) in _searchableFields(entry)) {
        vocab.addAll(tokens);
      }
    }
    _vocab = vocab;
  }

  /// Smoothed IDF: ln((N + 1) / (df + 1)) + 1. Every value >= 1, so a
  /// matched term never scores below the pre-IDF flat weight of 1.0.
  double _idf(int docFreq) => math.log((_nDocs + 1) / (docFreq + 1)) + 1;

  String _stripEdges(String s, String chars) {
    var start = 0;
    var end = s.length;
    while (start < end && chars.contains(s[start])) {
      start++;
    }
    while (end > start && chars.contains(s[end - 1])) {
      end--;
    }
    return s.substring(start, end);
  }

  /// Query -> list of concepts (surface-form set + IDF). Computed once per
  /// query, not per candidate.
  List<_Concept> _queryConcepts(String query) {
    final raw = SchemeSearchTaxonomy.tokenRe
        .allMatches(query)
        .map((m) => _stripEdges(m.group(0)!, '-&').toLowerCase())
        .toList();

    final concepts = <_Concept>[];
    final seen = <String>{};

    // ── Phase 1: Multi-word phrase expansion ──────────────────────────
    // Detect multi-word keys in the lowercased query before per-token
    // processing. Each matched phrase injects a dedicated concept whose
    // forms are the phrase's expansion targets, vocab-gated.
    if (_phraseExpansions.isNotEmpty) {
      final queryLower =
          ' ${query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0900-\u097F\u0B80-\u0BFF ]'), ' ')} ';
      for (final entry in _phraseExpansions.entries) {
        if (!queryLower.contains(' ${entry.key} ')) continue;
        final forms = entry.value.where(_vocab.contains).toSet();
        if (forms.isEmpty) continue;
        final key = (forms.toList()..sort()).join('\x01');
        if (seen.contains(key)) continue;
        seen.add(key);
        final docFreq = _schemeEntries
            .where((e) => forms.intersection(_entryTerms(e)).isNotEmpty)
            .length;
        concepts.add(_Concept(forms, _idf(docFreq)));
      }
    }

    // ── Phase 2: Per-token concept building (with single-token expansion)
    for (final tok in raw) {
      if (!SchemeSearchTaxonomy.isSearchableToken(tok)) continue;
      var forms = <String>{tok};
      if (tok.contains('-')) {
        forms.addAll(
          tok.split('-').where(SchemeSearchTaxonomy.isSearchableToken),
        );
      }
      if (tok.endsWith('s') && _vocab.contains(tok.substring(0, tok.length - 1))) {
        forms.add(tok.substring(0, tok.length - 1));
      }
      if (_vocab.contains('${tok}s')) {
        forms.add('${tok}s');
      }

      // ── Single-token expansion ─────────────────────────────────────
      // If the expansion dictionary has this token, merge its expansions
      // into forms BEFORE the vocab gate. The original token is kept;
      // expansions that are not in _vocab are silently dropped by the
      // gate below, exactly as designed.
      final expansion = _tokenExpansions[tok];
      if (expansion != null) {
        forms.addAll(expansion);
      }

      final gated = forms.where(_vocab.contains).toSet();
      forms = gated.isEmpty ? {tok} : gated;

      final key = (forms.toList()..sort()).join('\x01');
      if (seen.contains(key)) continue;
      seen.add(key);

      final docFreq = _schemeEntries
          .where((e) => forms.intersection(_entryTerms(e)).isNotEmpty)
          .length;
      concepts.add(_Concept(forms, _idf(docFreq)));
    }
    return concepts;
  }

  double _keywordScoreIdf(MssEntity entry, List<_Concept> concepts) {
    var score = 0.0;
    for (final (tokens, weight) in _searchableFields(entry)) {
      final tokset = tokens.toSet();
      for (final concept in concepts) {
        if (concept.forms.intersection(tokset).isNotEmpty) {
          score += weight * concept.idf;
        }
      }
    }
    return score;
  }

  double _tredsScore(MssEntity entry, Map<String, List<String>> queryTags) {
    final profile = _profileOf(entry);
    final entryTreds = _stringSet(profile['tredsTags']);
    final queryTreds = queryTags['treds']!.toSet();
    if (entryTreds.isEmpty || queryTreds.isEmpty) return 0.0;
    var score = 0.0;
    if (entryTreds.intersection(queryTreds).isNotEmpty) score += 1.0;
    if (entryTreds
        .intersection(SchemeSearchTaxonomy.expandRelated(queryTreds))
        .isNotEmpty) {
      score += 0.3;
    }
    return score;
  }

  double _categoryScore(MssEntity entry, Map<String, List<String>> queryTags) {
    final profile = _profileOf(entry);
    var score = 0.0;
    if (queryTags['industries']!
        .toSet()
        .intersection(_stringSet(profile['industryTags']))
        .isNotEmpty) {
      score += 1.0;
    }
    if (queryTags['communities']!
        .toSet()
        .intersection(_stringSet(profile['communityTags']))
        .isNotEmpty) {
      score += 1.0;
    }
    score += _tredsScore(entry, queryTags);
    return score;
  }

  double _eligibilityScore(
    MssEntity entry,
    Map<String, List<String>> queryTags,
  ) {
    final profile = _profileOf(entry);
    final elig = _stringSet(profile['eligibilityKeywords'])
        .map((e) => e.toLowerCase())
        .toSet();
    if (elig.isEmpty) return 0.0; // neutral -- unrecorded, not "matches all"
    final queryTerms = {
      ...queryTags['communities']!,
      ...queryTags['industries']!,
    };
    return elig.intersection(queryTerms).isNotEmpty ? 1.0 : 0.0;
  }

  double _benefitScore(MssEntity entry, Map<String, List<String>> queryTags) {
    final profile = _profileOf(entry);
    final benefitTags = _stringSet(profile['benefitTags']);
    final intentTags = _stringSet(profile['userIntentTags']);
    var score = 0.0;
    if (benefitTags.intersection(queryTags['benefits']!.toSet()).isNotEmpty) {
      score += 1.0;
    }
    if (intentTags.intersection(queryTags['intents']!.toSet()).isNotEmpty) {
      score += 1.0;
    }
    final entryCollateralConcepts = {
      for (final s in _stringSet(profile['collateralStatus']))
        if (SchemeSearchTaxonomy.statusToConcept.containsKey(s)) SchemeSearchTaxonomy.statusToConcept[s]!,
    };
    if (entryCollateralConcepts
        .intersection(queryTags['collateral']!.toSet())
        .isNotEmpty) {
      score += 1.0;
    }
    return score;
  }

  double _semanticScore(MssEntity entry, Map<String, List<String>> queryTags) {
    final codes = _semanticCodes[entry.id];
    if (codes == null || codes.isEmpty) return 0.0;
    final concepts = <String>{};
    for (final group in SchemeSearchTaxonomy.semanticQueryGroups) {
      concepts.addAll(queryTags[group] ?? const []);
    }
    if (concepts.isEmpty) return 0.0;
    return concepts.intersection(codes).length / concepts.length;
  }

  List<String> _explainReasons(
    MssEntity entry,
    Map<String, List<String>> queryTags,
    List<_Concept> concepts,
  ) {
    final reasons = <String>[];
    final entryTerms = _entryTerms(entry);
    final hits = <(String, double)>[];
    for (final concept in concepts) {
      final matched = concept.forms.intersection(entryTerms);
      if (matched.isNotEmpty) {
        hits.add(((matched.toList()..sort()).first, concept.idf));
      }
    }
    if (hits.isNotEmpty) {
      hits.sort((a, b) {
        final c = b.$2.compareTo(a.$2);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
      reasons.add('Matches: ${hits.map((h) => h.$1).join(', ')}');
    }

    final profile = _profileOf(entry);
    final ind = queryTags['industries']!
        .toSet()
        .intersection(_stringSet(profile['industryTags']));
    if (ind.isNotEmpty) reasons.add('Industry match: ${ind.join(', ')}');

    final comm = queryTags['communities']!
        .toSet()
        .intersection(_stringSet(profile['communityTags']));
    if (comm.isNotEmpty) reasons.add('Community match: ${comm.join(', ')}');

    final elig = _stringSet(profile['eligibilityKeywords'])
        .map((e) => e.toLowerCase())
        .toSet();
    final eligHits = elig.intersection({
      ...queryTags['communities']!,
      ...queryTags['industries']!,
    });
    if (eligHits.isNotEmpty) {
      reasons.add('Eligibility match: ${eligHits.join(', ')}');
    }

    final ben = queryTags['benefits']!
        .toSet()
        .intersection(_stringSet(profile['benefitTags']));
    if (ben.isNotEmpty) reasons.add('Benefit match: ${ben.join(', ')}');

    final intent = queryTags['intents']!
        .toSet()
        .intersection(_stringSet(profile['userIntentTags']));
    if (intent.isNotEmpty) reasons.add('Intent match: ${intent.join(', ')}');

    final entryCollateral = {
      for (final s in _stringSet(profile['collateralStatus']))
        if (SchemeSearchTaxonomy.statusToConcept.containsKey(s)) SchemeSearchTaxonomy.statusToConcept[s]!,
    };
    final collateralHit =
        entryCollateral.intersection(queryTags['collateral']!.toSet());
    if (collateralHit.isNotEmpty) {
      reasons.add('Collateral match: ${collateralHit.join(', ')}');
    }

    final codes = _semanticCodes[entry.id] ?? const {};
    if (codes.isNotEmpty) {
      final semanticConcepts = <String>{};
      for (final group in SchemeSearchTaxonomy.semanticQueryGroups) {
        semanticConcepts.addAll(queryTags[group] ?? const []);
      }
      final covered = semanticConcepts.intersection(codes);
      if (covered.isNotEmpty) {
        reasons.add('Semantic match: ${covered.join(', ')}');
      }
    }

    return reasons;
  }

  /// Ranks all scheme entities for [query]. Deterministic: score desc, then
  /// entityId asc as a total-order tiebreak (matches hybrid_search.py).
  List<(MssEntity entry, double score, List<String> reasons)> search(
    String query, {
    int? topN,
  }) {
    final queryTags = SchemeSearchTaxonomy.normalize(query);
    final concepts = _queryConcepts(query);

    final scored = <_ScoredScheme>[];
    for (final entry in _schemeEntries) {
      final finalScore = _scoreEntry(entry, queryTags, concepts);
      if (finalScore <= 0) continue;
      scored.add(_ScoredScheme(entry, finalScore));
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.entry.id.compareTo(b.entry.id);
    });

    final limited = topN != null ? scored.take(topN) : scored;
    return [
      for (final s in limited)
        (s.entry, s.score, _explainReasons(s.entry, queryTags, concepts)),
    ];
  }

  double _scoreEntry(
    MssEntity entry,
    Map<String, List<String>> queryTags,
    List<_Concept> concepts,
  ) {
    final kw = _keywordScoreIdf(entry, concepts);
    final cat = _categoryScore(entry, queryTags);
    final elig = _eligibilityScore(entry, queryTags);
    final ben = _benefitScore(entry, queryTags);
    final semantic = _semanticScore(entry, queryTags);
    final raw = SchemeSearchTaxonomy.weights['keyword']! * kw +
        SchemeSearchTaxonomy.weights['semantic']! * semantic +
        SchemeSearchTaxonomy.weights['category']! * cat +
        SchemeSearchTaxonomy.weights['eligibility']! * elig +
        SchemeSearchTaxonomy.weights['benefit']! * ben;
    final statusFactor = SchemeSearchTaxonomy.statusFactor[entry.status.toLowerCase()] ?? 1.0;
    final finalScore = raw * statusFactor;
    return (finalScore * 10000).round() / 10000;
  }

  /// Scores every scheme entity against [query] without dropping zero-score
  /// entries (unlike [search], which is a "find relevant results" query).
  /// For ranking an already-filtered subset (e.g. a category/ministry/state
  /// listing) by the same relevance signal the search engine uses, without
  /// excluding members that just don't share keywords with the query text --
  /// that would be a completeness regression, not a ranking improvement.
  Map<String, double> scoreByQuery(String query) {
    final queryTags = SchemeSearchTaxonomy.normalize(query);
    final concepts = _queryConcepts(query);
    return {
      for (final entry in _schemeEntries)
        entry.id: _scoreEntry(entry, queryTags, concepts),
    };
  }

  // ── Exact-entity lookup ─────────────────────────────────────────────
  // A scheme-name / acronym / alias query is a *lookup*, not a relevance
  // search: it must return that scheme (or nothing) -- never a spread of
  // topically-adjacent schemes. [exactEntityMatches] runs BEFORE the scored
  // search in [rank]. It reads identity.name / identity.acronym /
  // identity.shortName / search.aliases -- all already in the catalog
  // bundle -- and never touches the parity-locked scoring path.

  /// How far below the top score a scored result may fall before it is
  /// dropped as a weak/incidental match. Relative, so it adapts to how
  /// peaked the score distribution is for a given query.
  static const double _kRelevanceFloorRatio = 0.35;

  /// Hard ceiling on how many scored results a single query returns.
  static const int _kMaxResults = 25;

  /// When a query reads like a specific scheme name (>= this many meaningful
  /// tokens) but no exact-entity tier matched, the scored fallback must
  /// clear [_kNameLookupMinScore] or the query is treated as "not in the
  /// catalog" (empty result) rather than answered with common-word noise.
  static const int _kNameLookupMinTokens = 3;
  static const double _kNameLookupMinScore = 4.0;

  /// Tokens that carry no lookup signal on their own -- ignored when
  /// deciding whether a multi-word query "is" a particular scheme's name.
  static const Set<String> _lookupStopwords = {
    'scheme', 'schemes', 'yojana', 'program', 'programme', 'the', 'of',
    'for', 'and', 'a', 'an', 'to', 'in', 'on', 'by',
  };

  List<_LookupEntry>? _lookupCache;

  static String _normLookup(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0900-\u097F\u0B80-\u0BFF]+'), ' ')
      .trim();

  List<String> _meaningfulTokens(String norm) => [
        for (final t in norm.split(' '))
          if (t.length >= 2 && !_lookupStopwords.contains(t)) t,
      ];

  List<_LookupEntry> _lookupEntries() {
    return _lookupCache ??= [
      for (final e in _schemeEntries) _buildLookupEntry(e),
    ];
  }

  _LookupEntry _buildLookupEntry(MssEntity e) {
    final nameEn = _normLookup(e.getLocalizedName('en'));
    final nameTa = _normLookup(e.getLocalizedName('ta'));
    final nameHi = _normLookup(e.getLocalizedName('hi'));
    final identity = e.identity;
    final acronym =
        _normLookup((identity['acronym'] ?? '').toString()).replaceAll(' ', '');
    final shortName = _normLookup((identity['shortName'] ?? '').toString())
        .replaceAll(' ', '');
    final aliasRaw = (e.search['aliases'] as Map<String, dynamic>?) ?? const {};
    final aliases = <String>{
      for (final lang in const ['en', 'ta', 'hi'])
        ..._stringList(aliasRaw[lang]).map(_normLookup),
    }..removeWhere((a) => a.isEmpty);
    final fullForms = <String>{nameEn, nameTa, nameHi, ...aliases}
      ..removeWhere((a) => a.isEmpty);
    final nameTokens = <String>{
      ..._meaningfulTokens(nameEn),
      ..._meaningfulTokens(nameHi),
      ..._meaningfulTokens(nameTa),
      for (final a in aliases) ..._meaningfulTokens(a),
    };
    return _LookupEntry(
      entry: e,
      fullForms: fullForms,
      acronym: acronym,
      shortName: shortName,
      nameTokens: nameTokens,
      meaningfulNameCount: _meaningfulTokens(nameEn).length,
    );
  }

  /// The scheme(s) a lookup-style [rawQuery] names exactly or near-exactly,
  /// or an empty list when the query is not a scheme lookup (a broad/intent
  /// query). Deterministic: results sorted by entity id. Public for tests.
  List<MssEntity> exactEntityMatches(String rawQuery) {
    final nq = _normLookup(rawQuery);
    if (nq.isEmpty) return const [];
    final cq = nq.replaceAll(' ', '');
    final qMeaning = _meaningfulTokens(nq);
    final table = _lookupEntries();

    // Tier 1 -- the query IS a whole scheme name / alias.
    final t1 = [for (final l in table) if (l.fullForms.contains(nq)) l.entry];
    if (t1.isNotEmpty) return _sortedById(t1);

    // Tier 2 -- the query IS a curated acronym / short name.
    if (cq.length >= 2 && cq.length <= 15) {
      final t2 = [
        for (final l in table)
          if ((l.acronym.isNotEmpty && l.acronym == cq) ||
              (l.shortName.isNotEmpty && l.shortName == cq))
            l.entry,
      ];
      if (t2.isNotEmpty) return _sortedById(t2);
    }

    // Tier 3 -- a multi-word query that covers >=60% of one scheme's name
    // and introduces no token the name lacks.
    if (qMeaning.length >= 2) {
      final t3 = [
        for (final l in table)
          if (l.meaningfulNameCount > 0 &&
              qMeaning.every(l.nameTokens.contains) &&
              qMeaning.length / l.meaningfulNameCount >= 0.6)
            l.entry,
      ];
      if (t3.isNotEmpty) return _sortedById(t3);
    }

    return const [];
  }

  List<MssEntity> _sortedById(List<MssEntity> xs) =>
      xs..sort((a, b) => a.id.compareTo(b.id));

  /// Test/diagnostic only: the per-signal score contributions for one
  /// scheme under [query]. Not referenced by any UI.
  Map<String, double> debugScoreBreakdown(String query, String schemeId) {
    final entry = _schemeEntries.firstWhere(
      (e) => e.id == schemeId,
      orElse: () => throw ArgumentError('unknown scheme: $schemeId'),
    );
    final queryTags = SchemeSearchTaxonomy.normalize(query);
    final concepts = _queryConcepts(query);
    final kw = _keywordScoreIdf(entry, concepts);
    final cat = _categoryScore(entry, queryTags);
    final elig = _eligibilityScore(entry, queryTags);
    final ben = _benefitScore(entry, queryTags);
    final semantic = _semanticScore(entry, queryTags);
    final w = SchemeSearchTaxonomy.weights;
    final raw = w['keyword']! * kw +
        w['semantic']! * semantic +
        w['category']! * cat +
        w['eligibility']! * elig +
        w['benefit']! * ben;
    final statusFactor =
        SchemeSearchTaxonomy.statusFactor[entry.status.toLowerCase()] ?? 1.0;
    return {
      'keyword': kw,
      'semantic': semantic,
      'category': cat,
      'eligibility': elig,
      'benefit': ben,
      'statusFactor': statusFactor,
      'raw': raw,
      'final': (raw * statusFactor * 10000).round() / 10000,
      'exactTier':
          exactEntityMatches(query).any((e) => e.id == schemeId) ? 1.0 : 0.0,
    };
  }

  /// Ranks the offline catalog and returns [SchemeSearchMatch]es, the same
  /// shape `SchemeRepository` already expects from the offline fallback
  /// path -- see `scheme_repository.dart`'s `searchSchemeMatchesOffline`.
  ///
  /// Pipeline: exact-entity lookup first ([exactEntityMatches]); otherwise
  /// the scored [search], with the weak tail dropped (relative floor) and
  /// the count capped so one shared generic term cannot fill the screen.
  static Future<List<SchemeSearchMatch>> rank(
    String query,
    MssCatalogBundle bundle, {
    int? limit,
    String langCode = 'en',
  }) async {
    if (query.trim().isEmpty) return const [];
    final engine = await build(bundle);

    SchemeSearchMatch toMatch(
      MssEntity entry,
      double score,
      List<String> reasons,
    ) =>
        SchemeSearchMatch(
          scheme: MssSchemeAdapter.toScheme(entry, bundle, langCode: langCode),
          score: score,
          reasons: reasons,
        );

    // 1. Exact-entity lookup -- return just the named scheme(s).
    final exact = engine.exactEntityMatches(query);
    if (exact.isNotEmpty) {
      final picked = limit != null ? exact.take(limit) : exact;
      return [
        for (final e in picked) toMatch(e, 1.0, const ['Exact scheme match']),
      ];
    }

    // 2. Relevance search, then drop the weak tail and cap the count.
    final results = engine.search(query, topN: limit);
    if (results.isEmpty) return const [];
    final maxScore = results.first.$2;

    // A multi-word proper-name query that no tier matched and that only
    // scrapes common-word noise -> "not available", not a wrong list.
    final meaningfulTokens =
        engine._meaningfulTokens(_normLookup(query)).length;
    if (meaningfulTokens >= _kNameLookupMinTokens &&
        maxScore < _kNameLookupMinScore) {
      return const [];
    }

    final floor = maxScore * _kRelevanceFloorRatio;
    var kept = [for (final r in results) if (r.$2 >= floor) r];
    if (kept.isEmpty) kept = [results.first];
    if (kept.length > _kMaxResults) kept = kept.sublist(0, _kMaxResults);
    return [for (final (e, s, r) in kept) toMatch(e, s, r)];
  }
}
