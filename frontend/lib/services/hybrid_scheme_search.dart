import 'dart:math' as math;

import '../models/mss_entity.dart';
import 'intelligent_scheme_search.dart' show SchemeSearchMatch;
import 'mss_catalog_bundle.dart';
import 'mss_scheme_adapter.dart';

/// Deterministic query-tag normalizer, faithfully ported from
/// `Plan/catalog/taxonomy_engine.py` (the reference implementation the
/// backend `mss_api_rc1.py` search endpoint uses). A controlled vocabulary +
/// keyword/pattern matcher over a versioned table -- not an LLM call, so the
/// same query always produces the same tags.
class SchemeSearchTaxonomy {
  const SchemeSearchTaxonomy._();

  // Only way a <3-char token becomes searchable. Derived from the same
  // controlled sources as the Python original; do not add to this without
  // re-deriving from the catalog (see taxonomy_engine.py's own comment).
  static const Set<String> shortTokenVocab = {'sc', 'st', 'tn'};

  static bool isSearchableToken(String token) {
    final t = token.toLowerCase();
    return t.length >= 3 || shortTokenVocab.contains(t);
  }

  static const Map<String, List<String>> industries = {
    'textile': [
      'textile', 'cloth', 'garment', 'weaving', 'power loom', 'handloom',
      'apparel', 'fabric', 'yarn', 'spinning',
    ],
    'auto': [
      'auto', 'automobile', 'automotive', 'vehicle', 'auto component',
      'auto parts',
    ],
    'leather': ['leather', 'tannery', 'footwear', 'tanning'],
    'printing': ['printing', 'press', 'publication', 'packaging print'],
    'manufacturing': [
      'manufacturing', 'manufacture', 'factory', 'production',
      'plant and machinery',
    ],
    'service': ['service', 'services sector', 'service enterprise'],
    'food_processing': [
      'food processing', 'food product', 'food products', 'agro processing',
      'agro-based', 'agro based', 'food industry', 'food safety',
    ],
  };

  static const Map<String, List<String>> benefits = {
    'loan': [
      'loan', 'business loan', 'msme loan', 'term loan', 'capital loan',
      'working capital', 'credit', 'borrow', 'financing', 'finance',
      'funding',
    ],
    'subsidy': ['subsidy', 'subsidies', 'subsidised', 'subsidized'],
    'grant': ['grant', 'grant-in-aid'],
    'guarantee': ['guarantee'],
    'training': [
      'training', 'skill development', 'capacity building', 'workshop',
    ],
    'export_support': [
      'export', 'export incentive', 'export assistance', 'duty exemption',
    ],
  };

  // Two DISTINCT concepts, deliberately not merged: a lender waiving
  // security ("collateral_free") is not the same fact as a third party
  // covering default risk ("guarantee_backed").
  static const Map<String, List<String>> collateral = {
    'collateral_free': [
      'collateral free', 'collateral-free', 'without collateral',
      'no collateral', 'security free', 'security-free',
      'no security required',
    ],
    'guarantee_backed': [
      'credit guarantee', 'guarantee backed', 'guarantee-backed',
      'backed by guarantee', 'cgtmse', 'cgss', 'credit guarantee fund',
    ],
  };

  static const Map<String, List<String>> treds = {
    'treds_platform': [
      'treds', 'trade receivables discounting system', 'rxil', 'm1xchange',
      'm1 xchange', 'invoicemart', 'invoice mart',
      'receivables exchange of india',
    ],
    'invoice_discounting': [
      'invoice discounting', 'invoice financing', 'bill discounting',
    ],
    'receivables_financing': [
      'receivables financing', 'receivable financing', 'msme receivables',
    ],
  };

  // Partial (not full) credit across related-but-distinct concepts.
  static const Map<String, List<String>> relatedConcepts = {
    'treds_platform': ['invoice_discounting', 'receivables_financing'],
    'invoice_discounting': ['treds_platform', 'receivables_financing'],
    'receivables_financing': ['treds_platform', 'invoice_discounting'],
    'collateral_free': [],
    'guarantee_backed': [],
  };

  static const Map<String, List<String>> communities = {
    'women': ['women', 'woman', 'female', 'mahila'],
    'sc': ['sc entrepreneur', 'scheduled caste', ' sc '],
    'st': ['st entrepreneur', 'scheduled tribe', ' st '],
    'differently_abled': [
      'differently abled', 'disability', 'disabled', 'pwd',
    ],
    'transgender': ['transgender'],
    'minority': ['minority'],
    'ex_servicemen': ['ex-servicemen', 'ex servicemen', 'veteran'],
  };

  static const Map<String, List<String>> intents = {
    'LOAN_REQUEST': [
      'loan', 'borrow', 'credit', 'money to start', 'money for', 'funding',
      'finance my',
    ],
    'SUBSIDY_REQUEST': ['subsidy', 'subsidised', 'subsidized'],
    'GRANT_REQUEST': ['grant'],
    'TRAINING_REQUEST': [
      'training', 'skill development', 'workshop', 'capacity building',
    ],
    'REGISTRATION_REQUEST': [
      'register', 'registration', 'udyam', 'how to register',
    ],
    'EXPORT_REQUEST': ['export', 'iec', 'dgft'],
    'TAX_REQUEST': ['gst', 'tax', 'income tax', 'exemption'],
    'WOMEN_SUPPORT': ['women', 'female', 'mahila', 'woman entrepreneur'],
    'STARTUP_SUPPORT': [
      'startup', 'start up', 'new business', 'start a business', 'start my',
    ],
    'CLUSTER_SUPPORT': [
      'cluster', 'common facility centre', 'common facility center',
    ],
  };

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
        ' ${text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')} ';
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
  HybridSchemeSearch._(this._bundle, this._schemeEntries) {
    _semanticCodes = {
      for (final entry in _schemeEntries)
        entry.id: _semanticTagCodes(entry),
    };
    _buildIdf();
  }

  static const Map<String, double> _weights = {
    'keyword': 1.0,
    'semantic': 0.6,
    'category': 0.8,
    'eligibility': 0.5,
    'benefit': 0.9,
  };

  // Applies AFTER the weighted sum as a uniform multiplicative factor keyed
  // only on identity.status. "closed" is discounted, never zeroed --  an
  // explicitly relevant closed scheme still outranks an unrelated active
  // one. "unknown" gets no penalty: absence of confirmed status is not
  // evidence of closure.
  static const Map<String, double> _statusFactor = {
    'active': 1.0,
    'unknown': 1.0,
    'closed': 0.72,
  };

  static const Map<String, String> _statusToConcept = {
    'not_required': 'collateral_free',
    'guarantee_covered': 'guarantee_backed',
  };

  static const List<String> _semanticQueryGroups = [
    'industries', 'benefits', 'communities', 'collateral', 'treds',
  ];

  // Mirrors the index builder's tokenizer regex so a query term and an
  // index term share the same surface form.
  static final RegExp _tokenRe = RegExp(
    r'[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}',
  );

  final MssCatalogBundle _bundle;
  final List<MssEntity> _schemeEntries;
  late final Map<String, Set<String>> _semanticCodes;
  final Map<String, Set<String>> _entryTermCache = {};
  late int _nDocs;
  late Set<String> _vocab;

  static HybridSchemeSearch build(MssCatalogBundle bundle) {
    return HybridSchemeSearch._(bundle, bundle.schemes);
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
    return [
      (_stringList(tokens?['en']), 1.0),
      (_stringList(tokens?['ta']), 1.0),
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
    final raw = _tokenRe
        .allMatches(query)
        .map((m) => _stripEdges(m.group(0)!, '-&').toLowerCase())
        .toList();

    final concepts = <_Concept>[];
    final seen = <String>{};
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
      final gated = forms.where(_vocab.contains).toSet();
      forms = gated.isEmpty ? {tok} : gated;

      final key = (forms.toList()..sort()).join('');
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
        if (_statusToConcept.containsKey(s)) _statusToConcept[s]!,
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
    for (final group in _semanticQueryGroups) {
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
        if (_statusToConcept.containsKey(s)) _statusToConcept[s]!,
    };
    final collateralHit =
        entryCollateral.intersection(queryTags['collateral']!.toSet());
    if (collateralHit.isNotEmpty) {
      reasons.add('Collateral match: ${collateralHit.join(', ')}');
    }

    final codes = _semanticCodes[entry.id] ?? const {};
    if (codes.isNotEmpty) {
      final semanticConcepts = <String>{};
      for (final group in _semanticQueryGroups) {
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
    final raw = _weights['keyword']! * kw +
        _weights['semantic']! * semantic +
        _weights['category']! * cat +
        _weights['eligibility']! * elig +
        _weights['benefit']! * ben;
    final statusFactor = _statusFactor[entry.status.toLowerCase()] ?? 1.0;
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

  /// Ranks the offline catalog and returns [SchemeSearchMatch]es, the same
  /// shape `SchemeRepository` already expects from the offline fallback
  /// path -- see `scheme_repository.dart`'s `searchSchemeMatchesOffline`.
  static List<SchemeSearchMatch> rank(
    String query,
    MssCatalogBundle bundle, {
    int? limit,
    String langCode = 'en',
  }) {
    if (query.trim().isEmpty) return const [];
    final engine = build(bundle);
    final results = engine.search(query, topN: limit);
    return [
      for (final (entry, score, reasons) in results)
        SchemeSearchMatch(
          scheme: MssSchemeAdapter.toScheme(entry, bundle, langCode: langCode),
          score: score,
          reasons: reasons,
        ),
    ];
  }
}
