// ---------------------------------------------------------------------------
// MSS Application Data Models — Supplementary / Legacy & Detail endpoints
//
// Installed in frontend/lib/models/mss_models.dart.
// `mss_contract.dart` is the primary contract for Search/Eligibility.
// This file carries models for supplementary API operations:
//     MssApplicabilityResponse   <- applicability() / eligibility()
//     MssSchemeIntelligence      <- scheme_detail() / GET /v1/schemes/{id}
//     MssMeta                    <- GET /v1/meta
//     MssApiError                <- Error payloads
// ---------------------------------------------------------------------------

export 'mss_contract.dart';
import 'mss_contract.dart';

String? _str(dynamic v) => v is String ? v : null;
int? _intOrNull(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
double? _dblOrNull(dynamic v) => v is num ? v.toDouble() : null;
double _dbl(dynamic v, [double fallback = 0.0]) => _dblOrNull(v) ?? fallback;
bool _bool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

List<String> _strList(dynamic v) =>
    v is List ? v.whereType<String>().toList(growable: false) : const <String>[];

List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) parse) => v is List
    ? v.whereType<Map>().map((e) => parse(Map<String, dynamic>.from(e))).toList()
    : <T>[];

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

Map<String, dynamic> _clean(Map<String, dynamic> m) {
  m.removeWhere((_, value) => value == null);
  return m;
}

// ---------------------------------------------------------------------------
// Supplementary / Legacy Search DTOs
// ---------------------------------------------------------------------------

class MssCitation {
  final String? sourceName;
  final String? organization;
  final String? url;
  final String? retrievedDate;
  final int? sourceTier;
  final String? sourceId;
  final bool externalSource;

  const MssCitation({
    this.sourceName,
    this.organization,
    this.url,
    this.retrievedDate,
    this.sourceTier,
    this.sourceId,
    this.externalSource = false,
  });

  factory MssCitation.fromJson(Map<String, dynamic> j) => MssCitation(
        sourceName: _str(j['sourceName']) ?? _str(j['name']),
        organization: _str(j['organization']),
        url: _str(j['url']),
        retrievedDate: _str(j['retrievedDate']),
        sourceTier: _intOrNull(j['sourceTier']),
        sourceId: _str(j['sourceId']),
        externalSource: _bool(j['externalSource']),
      );

  Map<String, dynamic> toJson() => _clean({
        'sourceName': sourceName,
        'organization': organization,
        'url': url,
        'retrievedDate': retrievedDate,
        'sourceTier': sourceTier,
        'sourceId': sourceId,
        'externalSource': externalSource,
      });
}

class MssMatchReason {
  final String dimension;
  final String detail;

  const MssMatchReason({required this.dimension, required this.detail});

  factory MssMatchReason.fromJson(Map<String, dynamic> j) => MssMatchReason(
        dimension: _str(j['dimension']) ?? 'keyword',
        detail: _str(j['detail']) ?? '',
      );

  Map<String, dynamic> toJson() => {'dimension': dimension, 'detail': detail};
}

class MssConfidence {
  final ConfidenceLevel level;
  final VerificationStatus verificationStatus;
  final int missingFieldCount;

  const MssConfidence({
    this.level = ConfidenceLevel.low,
    this.verificationStatus = VerificationStatus.unverified,
    this.missingFieldCount = 0,
  });

  factory MssConfidence.fromJson(Map<String, dynamic> j) => MssConfidence(
        level: confidenceLevelFrom(_str(j['level'])),
        verificationStatus: verificationStatusFrom(_str(j['verificationStatus'])),
        missingFieldCount: _intOrNull(j['missingFieldCount']) ?? 0,
      );

  Map<String, dynamic> toJson() => _clean({
        'level': level.name,
        'verificationStatus': verificationStatusTo(verificationStatus),
        'missingFieldCount': missingFieldCount,
      });
}

class MssRankingSignals {
  final Map<String, double> components;
  final Map<String, double> weights;

  const MssRankingSignals({
    this.components = const {},
    this.weights = const {},
  });

  factory MssRankingSignals.fromJson(Map<String, dynamic> j) {
    final cMap = _map(j['components']);
    final wMap = _map(j['weights']);
    return MssRankingSignals(
      components: cMap.map((k, v) => MapEntry(k, _dbl(v))),
      weights: wMap.map((k, v) => MapEntry(k, _dbl(v))),
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'components': components.isEmpty ? null : components,
        'weights': weights.isEmpty ? null : weights,
      });

  double get recomputedScore {
    double total = 0.0;
    components.forEach((k, compVal) {
      final weight = weights[k] ?? 0.0;
      total += compVal * weight;
    });
    return total;
  }
}

class MssNextAction {
  final String action;
  final String label;
  final String? url;
  final bool available;

  const MssNextAction({
    required this.action,
    required this.label,
    this.url,
    this.available = true,
  });

  factory MssNextAction.fromJson(Map<String, dynamic> j) => MssNextAction(
        action: _str(j['action']) ?? '',
        label: _str(j['label']) ?? '',
        url: _str(j['url']),
        available: _bool(j['available'], true),
      );

  Map<String, dynamic> toJson() => _clean({
        'action': action,
        'label': label,
        'url': url,
        'available': available,
      });

  bool get isClosedMarker => action == 'scheme_closed' || action == 'closed';
}

class MssApplicabilityMatch {
  final String schemeId;
  final bool eligible;
  final List<String> matchedFacets;
  final List<String> neutralFacets;
  final List<String> excludedByAll;

  const MssApplicabilityMatch({
    required this.schemeId,
    required this.eligible,
    this.matchedFacets = const [],
    this.neutralFacets = const [],
    this.excludedByAll = const [],
  });

  factory MssApplicabilityMatch.fromJson(Map<String, dynamic> j) {
    final rawEx = _strList(j['excludedByAll']);
    final singleEx = _str(j['excludedBy']);
    final exAll = rawEx.isNotEmpty
        ? rawEx
        : (singleEx != null && singleEx.isNotEmpty ? [singleEx] : const <String>[]);

    return MssApplicabilityMatch(
      schemeId: _str(j['schemeId']) ?? '',
      eligible: j.containsKey('eligible') ? _bool(j['eligible']) : exAll.isEmpty,
      matchedFacets: _strList(j['matchedFacets']),
      neutralFacets: _strList(j['neutralFacets']),
      excludedByAll: exAll,
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'schemeId': schemeId,
        'eligible': eligible,
        'matchedFacets': matchedFacets,
        'neutralFacets': neutralFacets,
        'excludedByAll': excludedByAll,
      });
}

class MssWarning {
  final String code;
  final String? field;
  final String message;
  final String? hint;

  const MssWarning({
    required this.code,
    this.field,
    required this.message,
    this.hint,
  });

  factory MssWarning.fromJson(Map<String, dynamic> j) => MssWarning(
        code: _str(j['code']) ?? _str(j['type']) ?? 'UNKNOWN',
        field: _str(j['field']),
        message: _str(j['message']) ?? '',
        hint: _str(j['hint']),
      );

  Map<String, dynamic> toJson() =>
      _clean({'code': code, 'field': field, 'message': message, 'hint': hint});
}

class MssSearchResult {
  final int rank;
  final String schemeId;
  final String name;
  final double score;
  final MssRankingSignals rankingSignals;
  final List<MssMatchReason> matchReasons;
  final String explanation;
  final List<MssCitation> citations;
  final MssConfidence? confidence;
  final MssApplicabilityMatch? applicability;
  final List<MssNextAction> nextActions;

  const MssSearchResult({
    required this.rank,
    required this.schemeId,
    this.name = '',
    this.score = 0.0,
    this.rankingSignals = const MssRankingSignals(),
    this.matchReasons = const [],
    this.explanation = '',
    this.citations = const [],
    this.confidence,
    this.applicability,
    this.nextActions = const [],
  });

  factory MssSearchResult.fromJson(Map<String, dynamic> j) => MssSearchResult(
        rank: _intOrNull(j['rank']) ?? 0,
        schemeId: _str(j['schemeId']) ?? '',
        name: _str(j['name']) ?? '',
        score: _dbl(j['score']),
        rankingSignals: MssRankingSignals.fromJson(_map(j['rankingSignals'])),
        matchReasons: _objList(j['matchReasons'], MssMatchReason.fromJson),
        explanation: _str(j['explanation']) ?? '',
        citations: _objList(j['citations'], MssCitation.fromJson),
        confidence: j['confidence'] is Map
            ? MssConfidence.fromJson(_map(j['confidence']))
            : null,
        applicability: j['applicability'] is Map
            ? MssApplicabilityMatch.fromJson(_map(j['applicability']))
            : null,
        nextActions: _objList(j['nextActions'], MssNextAction.fromJson),
      );

  Map<String, dynamic> toJson() => _clean({
        'rank': rank,
        'schemeId': schemeId,
        'name': name,
        'score': score,
        'rankingSignals': rankingSignals.toJson(),
        'matchReasons': matchReasons.map((e) => e.toJson()).toList(),
        'explanation': explanation,
        'citations': citations.map((e) => e.toJson()).toList(),
        'confidence': confidence?.toJson(),
        'applicability': applicability?.toJson(),
        'nextActions': nextActions.map((e) => e.toJson()).toList(),
      });
}

class MssDetectedIntent {
  final List<String> industries;
  final List<String> benefits;
  final List<String> collateral;
  final List<String> treds;
  final List<String> communities;
  final List<String> intents;

  const MssDetectedIntent({
    this.industries = const [],
    this.benefits = const [],
    this.collateral = const [],
    this.treds = const [],
    this.communities = const [],
    this.intents = const [],
  });

  factory MssDetectedIntent.fromJson(Map<String, dynamic> j) =>
      MssDetectedIntent(
        industries: _strList(j['industries']),
        benefits: _strList(j['benefits']),
        collateral: _strList(j['collateral']),
        treds: _strList(j['treds']),
        communities: _strList(j['communities']),
        intents: _strList(j['intents']),
      );

  Map<String, dynamic> toJson() => _clean({
        'industries': industries,
        'benefits': benefits,
        'collateral': collateral,
        'treds': treds,
        'communities': communities,
        'intents': intents,
      });
}

class MssSearchResponse {
  final String contractVersion;
  final String? catalogVersion;
  final String queryText;
  final MssDetectedIntent detectedIntent;
  final Map<String, dynamic> profileApplied;
  final List<MssWarning> warnings;
  final List<MssSearchResult> results;

  const MssSearchResponse({
    required this.contractVersion,
    this.catalogVersion,
    required this.queryText,
    this.detectedIntent = const MssDetectedIntent(),
    this.profileApplied = const {},
    this.warnings = const [],
    this.results = const [],
  });

  factory MssSearchResponse.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map ? _map(j['data']) : j;
    final q = data['query'] is Map ? _map(data['query']) : _map(j['query']);
    final profileRaw = data['profileApplied'] ?? data['userProfile'] ?? j['profileApplied'] ?? j['userProfile'];

    return MssSearchResponse(
      contractVersion: _str(j['contractVersion']) ?? '',
      catalogVersion: _str(j['catalogVersion']),
      queryText: _str(q['text']) ?? _str(data['query']) ?? _str(j['query']) ?? '',
      detectedIntent: MssDetectedIntent.fromJson(_map(q['detectedIntent'])),
      profileApplied: profileRaw is Map ? _map(profileRaw) : const {},
      warnings: _objList(j['warnings'], MssWarning.fromJson),
      results: _objList(data['results'] ?? j['results'], MssSearchResult.fromJson),
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'contractVersion': contractVersion,
        'contract': 'search_response',
        'catalogVersion': catalogVersion,
        'query': {
          'text': queryText,
          'detectedIntent': detectedIntent.toJson(),
        },
        'profileApplied': profileApplied.isEmpty ? null : profileApplied,
        'warnings': warnings.map((e) => e.toJson()).toList(),
        'results': results.map((e) => e.toJson()).toList(),
      });
}

class MssApplicabilityResponse {
  final String contractVersion;
  final Map<String, dynamic> profile;
  final List<MssWarning> warnings;
  final List<MssApplicabilityMatch> results;

  const MssApplicabilityResponse({
    required this.contractVersion,
    this.profile = const {},
    this.warnings = const [],
    this.results = const [],
  });

  factory MssApplicabilityResponse.fromJson(Map<String, dynamic> j) =>
      MssApplicabilityResponse(
        contractVersion: _str(j['contractVersion']) ?? '',
        profile: _map(j['profile']),
        warnings: _objList(j['warnings'], MssWarning.fromJson),
        results: _objList(j['results'], MssApplicabilityMatch.fromJson),
      );

  Map<String, dynamic> toJson() => _clean({
        'contractVersion': contractVersion,
        'contract': 'applicability_response',
        'profile': profile,
        'warnings': warnings.map((e) => e.toJson()).toList(),
        'results': results.map((e) => e.toJson()).toList(),
      });

  List<MssApplicabilityMatch> get eligibleOnly =>
      results.where((r) => r.eligible).toList();
}

class MssEntityRef {
  final String id;
  final String? name;
  final String? relationType;

  const MssEntityRef({required this.id, this.name, this.relationType});

  factory MssEntityRef.fromJson(Map<String, dynamic> j) => MssEntityRef(
        id: _str(j['id']) ?? _str(j['entityId']) ?? '',
        name: _str(j['name']),
        relationType: _str(j['relationType']),
      );

  Map<String, dynamic> toJson() =>
      _clean({'id': id, 'name': name, 'relationType': relationType});
}

class MssSchemeIntelligence {
  final String contractVersion;
  final String? generatedAt;
  final String? catalogVersion;
  final String schemeId;
  final String? name;
  final SchemeStatus schemeStatus;
  final List<MssEntityRef> finance;
  final List<MssEntityRef> tax;
  final List<MssEntityRef> treds;
  final List<MssEntityRef> csr;
  final List<MssEntityRef> authority;
  final List<MssEntityRef> institution;
  final List<MssEntityRef> export;
  final List<MssEntityRef> cluster;
  final List<MssEntityRef> privileges;
  final List<MssEntityRef> enablement;
  final List<MssEntityRef> knowledge;
  final Map<String, dynamic> applicability;
  final MssConfidence? confidence;
  final List<MssNextAction> nextActions;
  final List<String> missingReferences;

  const MssSchemeIntelligence({
    this.contractVersion = '',
    this.generatedAt,
    this.catalogVersion,
    required this.schemeId,
    this.name,
    this.schemeStatus = SchemeStatus.unrecognised,
    this.finance = const [],
    this.tax = const [],
    this.treds = const [],
    this.csr = const [],
    this.authority = const [],
    this.institution = const [],
    this.export = const [],
    this.cluster = const [],
    this.privileges = const [],
    this.enablement = const [],
    this.knowledge = const [],
    this.applicability = const {},
    this.confidence,
    this.nextActions = const [],
    this.missingReferences = const [],
  });

  factory MssSchemeIntelligence.fromJson(Map<String, dynamic> j) {
    List<MssEntityRef> refs(String key) => _objList(j[key], MssEntityRef.fromJson);
    final di = _map(j['dataIntegrity']);
    final missingRefs = _strList(di['missingReferences']).isNotEmpty
        ? _strList(di['missingReferences'])
        : _strList(j['missingReferences']);

    return MssSchemeIntelligence(
      contractVersion: _str(j['contractVersion']) ?? '',
      generatedAt: _str(j['generatedAt']),
      catalogVersion: _str(j['catalogVersion']),
      schemeId: _str(j['schemeId']) ?? '',
      name: _str(j['name']),
      schemeStatus: schemeStatusFrom(_str(j['schemeStatus'])),
      finance: refs('finance'),
      tax: refs('tax'),
      treds: refs('treds'),
      csr: refs('csr'),
      authority: refs('authority'),
      institution: refs('institution'),
      export: refs('export'),
      cluster: refs('cluster'),
      privileges: refs('privileges'),
      enablement: refs('enablement'),
      knowledge: refs('knowledge'),
      applicability: _map(j['applicability']),
      confidence: j['confidence'] is Map
          ? MssConfidence.fromJson(_map(j['confidence']))
          : null,
      nextActions: _objList(j['nextActions'], MssNextAction.fromJson),
      missingReferences: missingRefs,
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'contractVersion': contractVersion,
        'contract': 'scheme_intelligence_response',
        'generatedAt': generatedAt,
        'catalogVersion': catalogVersion,
        'schemeId': schemeId,
        'name': name,
        'schemeStatus': schemeStatusTo(schemeStatus),
        'finance': finance.map((e) => e.toJson()).toList(),
        'tax': tax.map((e) => e.toJson()).toList(),
        'treds': treds.map((e) => e.toJson()).toList(),
        'csr': csr.map((e) => e.toJson()).toList(),
        'authority': authority.map((e) => e.toJson()).toList(),
        'institution': institution.map((e) => e.toJson()).toList(),
        'export': export.map((e) => e.toJson()).toList(),
        'cluster': cluster.map((e) => e.toJson()).toList(),
        'privileges': privileges.map((e) => e.toJson()).toList(),
        'enablement': enablement.map((e) => e.toJson()).toList(),
        'knowledge': knowledge.map((e) => e.toJson()).toList(),
        'applicability': applicability.isEmpty ? null : applicability,
        'confidence': confidence?.toJson(),
        'nextActions': nextActions.map((e) => e.toJson()).toList(),
        'dataIntegrity': {'missingReferences': missingReferences},
      });
}

class MssMeta {
  final String? catalogVersion;
  final String? catalogChecksum;
  final Map<String, int> entityCounts;
  final List<String> supportedLanguages;

  const MssMeta({
    this.catalogVersion,
    this.catalogChecksum,
    this.entityCounts = const {},
    this.supportedLanguages = const ['en'],
  });

  factory MssMeta.fromJson(Map<String, dynamic> j) => MssMeta(
        catalogVersion: _str(j['catalogVersion']),
        catalogChecksum: _str(j['catalogChecksum']),
        entityCounts:
            _map(j['entityCounts']).map((k, v) => MapEntry(k, _intOrNull(v) ?? 0)),
        supportedLanguages: _strList(j['supportedLanguages']).isEmpty
            ? const ['en']
            : _strList(j['supportedLanguages']),
      );

  Map<String, dynamic> toJson() => _clean({
        'catalogVersion': catalogVersion,
        'catalogChecksum': catalogChecksum,
        'entityCounts': entityCounts.isEmpty ? null : entityCounts,
        'supportedLanguages': supportedLanguages,
      });

  bool isStaleAgainst(String? cachedCatalogVersion) =>
      catalogVersion != null && catalogVersion != cachedCatalogVersion;

  List<String> get zeroCoverageDimensions {
    return const ['community'];
  }
}

class MssApiError implements Exception {
  final String code;
  final String message;
  final String? field;
  final String? detail;

  const MssApiError({
    required this.code,
    required this.message,
    this.field,
    this.detail,
  });

  static bool isError(Map<String, dynamic> j) =>
      j['contract'] == 'error' || j.containsKey('error');

  factory MssApiError.fromJson(Map<String, dynamic> j) {
    final err = j['error'] is Map ? _map(j['error']) : j;
    return MssApiError(
      code: _str(err['code']) ?? 'UNKNOWN',
      message: _str(err['message']) ?? '',
      field: _str(err['field']),
      detail: _str(err['detail']),
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'contract': 'error',
        'error': {
          'code': code,
          'message': message,
          'field': field,
          'detail': detail,
        },
      });

  bool get isRetryable => code == 'CATALOG_UNAVAILABLE' || code == 'INTERNAL_ERROR';

  @override
  String toString() => 'MssApiError($code): $message';
}
