// MSS Flutter Data Model Contract — Phase 4 (finalized)
//
// Installed in frontend/lib/models/mss_contract.dart.
// Mirrors the finalized MSS intelligence response contract produced by
// catalog/mss_api.py. Every field below traces to real MSS output — see
// PHASE4_APPLICATION_INTEGRATION_PLAN.md and the field-mapping audit.
//
// APPROVED DESIGN DECISIONS BAKED IN:
//  * FinanceBenefit.conditions  -> ships as an empty list. The underlying
//    field is populated on 0 of 115 finance records.
//  * FinanceBenefit.mode        -> NULLABLE, mapped to applicationRoute (31/115).
//  * FinanceBenefit.collateralStatus -> Parses both nested `collateral.status` and flat `collateralStatus`.
//  * Citation.sourceTier        -> real provenance (5 = live official fetch, 2 = structured from text).
//  * EligibilityMatch           -> has excludedByAll[], NOT a fabricated "unmatchedCriteria".
//  * EligibilityMatch.confidence -> REMOVED. Data confidence lives on SchemeResult instead.
//  * Explanation.evidence[]     -> REMOVED. matchReasons[] already IS the evidence.
//  * UpdateMetadata.availableUpdates -> REMOVED. Use UpdateMetadata.isStaleAgainst(cachedVersion).
//
// Null-safe Dart. No package dependencies. No code generation.

import 'dart:convert';

// ---------------------------------------------------------------------------
// Tolerant primitives — every parse routes through these so a missing or
// unexpected value degrades instead of throwing on an older app build.
// ---------------------------------------------------------------------------

String? _str(dynamic v) => v is String ? v : null;
int? _intOrNull(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
double? _dblOrNull(dynamic v) => v is num ? v.toDouble() : null;
double _dbl(dynamic v, [double fallback = 0.0]) => _dblOrNull(v) ?? fallback;
bool _bool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

List<String> _strList(dynamic v) => v is List
    ? v.whereType<String>().toList(growable: false)
    : const <String>[];

List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) parse) =>
    v is List
    ? v
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList()
    : <T>[];

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

Map<String, dynamic> _clean(Map<String, dynamic> m) {
  m.removeWhere((_, value) => value == null);
  return m;
}

// ---------------------------------------------------------------------------
// Enums — every one has an `unrecognised` fallback.
// ---------------------------------------------------------------------------

/// Real-world status of the scheme. TRI-STATE — never collapse to a bool.
enum SchemeStatus { active, closed, unknown, unrecognised }

SchemeStatus schemeStatusFrom(String? v) => switch (v) {
  'active' => SchemeStatus.active,
  'closed' => SchemeStatus.closed,
  'unknown' => SchemeStatus.unknown,
  _ => SchemeStatus.unrecognised,
};

String schemeStatusTo(SchemeStatus s) =>
    s == SchemeStatus.unrecognised ? 'unknown' : s.name;

/// How well-verified the CATALOG DATA is — distinct from search relevance.
enum ConfidenceLevel { high, medium, low, unrecognised }

ConfidenceLevel confidenceLevelFrom(String? v) => switch (v) {
  'high' => ConfidenceLevel.high,
  'medium' => ConfidenceLevel.medium,
  'low' => ConfidenceLevel.low,
  _ => ConfidenceLevel.unrecognised,
};

enum VerificationStatus {
  verified,
  partiallyVerified,
  unverified,
  historical,
  derived,
  unrecognised,
}

VerificationStatus verificationStatusFrom(String? v) => switch (v) {
  'verified' => VerificationStatus.verified,
  'partially_verified' => VerificationStatus.partiallyVerified,
  'unverified' => VerificationStatus.unverified,
  'historical' => VerificationStatus.historical,
  'derived' => VerificationStatus.derived,
  _ => VerificationStatus.unrecognised,
};

String? verificationStatusTo(VerificationStatus s) => switch (s) {
  VerificationStatus.partiallyVerified => 'partially_verified',
  VerificationStatus.unrecognised => null,
  _ => s.name,
};

/// Whether the user can act on this scheme right now.
enum ApplicationState {
  closed,
  openOnline,
  openOffline,
  unconfirmed,
  unrecognised,
}

ApplicationState applicationStateFrom(String? v) => switch (v) {
  'closed' => ApplicationState.closed,
  'open_online' => ApplicationState.openOnline,
  'open_offline' => ApplicationState.openOffline,
  'unconfirmed' => ApplicationState.unconfirmed,
  _ => ApplicationState.unrecognised,
};

String applicationStateTo(ApplicationState s) => switch (s) {
  ApplicationState.closed => 'closed',
  ApplicationState.openOnline => 'open_online',
  ApplicationState.openOffline => 'open_offline',
  ApplicationState.unconfirmed => 'unconfirmed',
  ApplicationState.unrecognised => 'unconfirmed',
};

/// Where a citation came from.
enum CitationOrigin { matchEvidence, schemeSource, unrecognised }

CitationOrigin citationOriginFrom(String? v) => switch (v) {
  'match_evidence' => CitationOrigin.matchEvidence,
  'scheme_source' => CitationOrigin.schemeSource,
  _ => CitationOrigin.unrecognised,
};

String? citationOriginTo(CitationOrigin o) => switch (o) {
  CitationOrigin.matchEvidence => 'match_evidence',
  CitationOrigin.schemeSource => 'scheme_source',
  CitationOrigin.unrecognised => null,
};

// ---------------------------------------------------------------------------
// Citation
// ---------------------------------------------------------------------------

class Citation {
  final String? sourceName;
  final String? organization;
  final String? url;
  final String? retrievedDate;
  final int? sourceTier;
  final String? sourceId;
  final bool externalSource;
  final CitationOrigin origin;
  final bool isPrimary;

  const Citation({
    this.sourceName,
    this.organization,
    this.url,
    this.retrievedDate,
    this.sourceTier,
    this.sourceId,
    this.externalSource = false,
    this.origin = CitationOrigin.unrecognised,
    this.isPrimary = false,
  });

  factory Citation.fromJson(Map<String, dynamic> j) {
    final isExt = _bool(j['externalSource']);
    final rawTier = _intOrNull(j['sourceTier']);
    return Citation(
      sourceName: _str(j['sourceName']),
      organization: _str(j['organization']),
      url: _str(j['url']),
      retrievedDate: _str(j['retrievedDate']),
      sourceTier: rawTier ?? (isExt ? 5 : 2),
      sourceId: _str(j['sourceId']),
      externalSource: isExt,
      origin: citationOriginFrom(_str(j['origin'])),
      isPrimary: _bool(j['isPrimary']),
    );
  }

  Map<String, dynamic> toJson() => _clean({
    'sourceName': sourceName,
    'organization': organization,
    'url': url,
    'retrievedDate': retrievedDate,
    'sourceTier': sourceTier,
    'sourceId': sourceId,
    'externalSource': externalSource,
    'origin': citationOriginTo(origin),
    'isPrimary': isPrimary ? true : null,
  });

  bool get isLiveOfficialFetch => externalSource && sourceTier == 5;

  String get displayLabel {
    if (!externalSource) {
      return sourceId == null
          ? 'Internal catalog record (no external source)'
          : 'Internal record $sourceId (no external source)';
    }
    return organization ?? sourceName ?? url ?? 'Official source';
  }
}

// ---------------------------------------------------------------------------
// BenefitAmount
// ---------------------------------------------------------------------------

class BenefitAmount {
  final String? displayText;
  final double? maxAmountInr;
  final double? minAmountInr;
  final double? subsidyPercent;
  final String? rawText;

  const BenefitAmount({
    this.displayText,
    this.maxAmountInr,
    this.minAmountInr,
    this.subsidyPercent,
    this.rawText,
  });

  factory BenefitAmount.fromJson(Map<String, dynamic> j) => BenefitAmount(
    displayText:
        _str(j['displayText']) ??
        _str(j['maxText']) ??
        _str(j['text']) ??
        _str(j['formatted']),
    maxAmountInr:
        _dblOrNull(j['maxAmountInr']) ??
        _dblOrNull(j['maxInr']) ??
        _dblOrNull(j['maximumAssistanceInr']),
    minAmountInr:
        _dblOrNull(j['minAmountInr']) ??
        _dblOrNull(j['minInr']) ??
        _dblOrNull(j['minimumAssistanceInr']),
    subsidyPercent:
        _dblOrNull(j['subsidyPercent']) ??
        _dblOrNull(j['percentage']) ??
        _dblOrNull(j['subsidyPercentage']),
    rawText: _str(j['rawText']) ?? _str(j['description']),
  );

  Map<String, dynamic> toJson() => _clean({
    'displayText': displayText,
    'maxAmountInr': maxAmountInr,
    'minAmountInr': minAmountInr,
    'subsidyPercent': subsidyPercent,
    'rawText': rawText,
  });

  bool get hasAnyValue =>
      displayText != null ||
      maxAmountInr != null ||
      minAmountInr != null ||
      subsidyPercent != null;
}

// ---------------------------------------------------------------------------
// MatchReason
// ---------------------------------------------------------------------------

class MatchReason {
  final String dimension;
  final String detail;
  final double? scoreContribution;

  const MatchReason({
    required this.dimension,
    required this.detail,
    this.scoreContribution,
  });

  factory MatchReason.fromJson(Map<String, dynamic> j) => MatchReason(
    dimension: _str(j['dimension']) ?? _str(j['field']) ?? 'keyword',
    detail: _str(j['detail']) ?? _str(j['reason']) ?? _str(j['message']) ?? '',
    scoreContribution:
        _dblOrNull(j['scoreContribution']) ?? _dblOrNull(j['score']),
  );

  Map<String, dynamic> toJson() => _clean({
    'dimension': dimension,
    'detail': detail,
    'scoreContribution': scoreContribution,
  });
}

// ---------------------------------------------------------------------------
// DataConfidence
// ---------------------------------------------------------------------------

class DataConfidence {
  final ConfidenceLevel level;
  final VerificationStatus verificationStatus;
  final SchemeStatus schemeStatus;
  final int missingFieldCount;

  const DataConfidence({
    this.level = ConfidenceLevel.low,
    this.verificationStatus = VerificationStatus.unverified,
    this.schemeStatus = SchemeStatus.unrecognised,
    this.missingFieldCount = 0,
  });

  factory DataConfidence.fromJson(Map<String, dynamic> j) => DataConfidence(
    level: confidenceLevelFrom(_str(j['level'])),
    verificationStatus: verificationStatusFrom(_str(j['verificationStatus'])),
    schemeStatus: schemeStatusFrom(_str(j['schemeStatus'])),
    missingFieldCount: _intOrNull(j['missingFieldCount']) ?? 0,
  );

  Map<String, dynamic> toJson() => _clean({
    'level': level.name,
    'verificationStatus': verificationStatusTo(verificationStatus),
    'schemeStatus': schemeStatusTo(schemeStatus),
    'missingFieldCount': missingFieldCount,
  });
}

// ---------------------------------------------------------------------------
// AuthorityRef
// ---------------------------------------------------------------------------

class AuthorityRef {
  final String id;
  final String name;
  final String relationType;

  const AuthorityRef({
    required this.id,
    required this.name,
    this.relationType = '',
  });

  factory AuthorityRef.fromJson(Map<String, dynamic> j) => AuthorityRef(
    id: _str(j['id']) ?? _str(j['authorityId']) ?? '',
    name: _str(j['name']) ?? _str(j['authorityName']) ?? '',
    relationType: _str(j['relationType']) ?? '',
  );

  Map<String, dynamic> toJson() =>
      _clean({'id': id, 'name': name, 'relationType': relationType});
}

// ---------------------------------------------------------------------------
// DetectedIntent
// ---------------------------------------------------------------------------

class DetectedIntent {
  final List<String> industries;
  final List<String> benefits;
  final List<String> collateral;
  final List<String> treds;
  final List<String> communities;
  final List<String> intents;

  const DetectedIntent({
    this.industries = const [],
    this.benefits = const [],
    this.collateral = const [],
    this.treds = const [],
    this.communities = const [],
    this.intents = const [],
  });

  factory DetectedIntent.fromJson(Map<String, dynamic> j) => DetectedIntent(
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

  bool get isEmpty =>
      industries.isEmpty &&
      benefits.isEmpty &&
      collateral.isEmpty &&
      treds.isEmpty &&
      communities.isEmpty &&
      intents.isEmpty;
}

// ---------------------------------------------------------------------------
// ResponseWarning
// ---------------------------------------------------------------------------

class ResponseWarning {
  final String code;
  final String? field;
  final String message;
  final String? hint;

  const ResponseWarning({
    required this.code,
    this.field,
    required this.message,
    this.hint,
  });

  factory ResponseWarning.fromJson(Map<String, dynamic> j) => ResponseWarning(
    code: _str(j['code']) ?? _str(j['type']) ?? 'UNKNOWN',
    field: _str(j['field']),
    message: _str(j['message']) ?? '',
    hint: _str(j['hint']),
  );

  Map<String, dynamic> toJson() =>
      _clean({'code': code, 'field': field, 'message': message, 'hint': hint});
}

// ---------------------------------------------------------------------------
// RankingSignals
// ---------------------------------------------------------------------------

class RankingSignals {
  final Map<String, double> components;
  final Map<String, double> weights;

  const RankingSignals({this.components = const {}, this.weights = const {}});

  factory RankingSignals.fromJson(Map<String, dynamic> j) {
    final cMap = _map(j['components']);
    final wMap = _map(j['weights']);

    return RankingSignals(
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

// ---------------------------------------------------------------------------
// NextAction
// ---------------------------------------------------------------------------

class NextAction {
  final String action;
  final String label;
  final String? url;
  final bool available;

  const NextAction({
    required this.action,
    required this.label,
    this.url,
    this.available = true,
  });

  factory NextAction.fromJson(Map<String, dynamic> j) => NextAction(
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

// ---------------------------------------------------------------------------
// FinanceBenefit
// ---------------------------------------------------------------------------

class FinanceBenefit {
  final String? financeId;
  final String? type;
  final String? typeText;
  final bool? isRepayable;
  final bool? isGuarantee;
  final BenefitAmount amount;
  final String? mode;
  final String? applicationUrl;
  final List<String> conditions;
  final String? collateralStatus;
  final List<String> providers;
  final String? description;
  final Citation? source;

  const FinanceBenefit({
    this.financeId,
    this.type,
    this.typeText,
    this.isRepayable,
    this.isGuarantee,
    this.amount = const BenefitAmount(),
    this.mode,
    this.applicationUrl,
    this.conditions = const [],
    this.collateralStatus,
    this.providers = const [],
    this.description,
    this.source,
  });

  factory FinanceBenefit.fromJson(Map<String, dynamic> j) {
    final colObj = j['collateral'];
    final parsedCollateralStatus = colObj is Map
        ? _str(colObj['status'])
        : _str(j['collateralStatus']);

    return FinanceBenefit(
      financeId: _str(j['financeId']) ?? _str(j['id']),
      type: _str(j['type']),
      typeText: _str(j['typeText']),
      isRepayable: j['isRepayable'] is bool ? j['isRepayable'] as bool : null,
      isGuarantee: j['isGuarantee'] is bool ? j['isGuarantee'] as bool : null,
      amount: BenefitAmount.fromJson(_map(j['amount'])),
      mode: _str(j['mode']),
      applicationUrl: _str(j['applicationUrl']) ?? _str(j['applicationRoute']),
      conditions: _strList(j['conditions']),
      collateralStatus: parsedCollateralStatus,
      providers: _strList(j['providers']),
      description: _str(j['description']),
      source: j['source'] is Map ? Citation.fromJson(_map(j['source'])) : null,
    );
  }

  Map<String, dynamic> toJson() => _clean({
    'financeId': financeId,
    'type': type,
    'typeText': typeText,
    'isRepayable': isRepayable,
    'isGuarantee': isGuarantee,
    'amount': amount.toJson(),
    'mode': mode,
    'applicationUrl': applicationUrl,
    'conditions': conditions,
    'collateral': collateralStatus != null
        ? {'status': collateralStatus}
        : null,
    'collateralStatus': collateralStatus,
    'providers': providers.isEmpty ? null : providers,
    'description': description,
    'source': source?.toJson(),
  });

  bool get isCollateralFree => collateralStatus == 'not_required';
  bool get isGuaranteeBacked => collateralStatus == 'guarantee_covered';
  bool get conditionsUnrecorded => conditions.isEmpty;
}

// ---------------------------------------------------------------------------
// EligibilityMatch
// ---------------------------------------------------------------------------

class EligibilityMatch {
  final String schemeId;
  final bool eligible;
  final List<String> matchedFacets;
  final List<String> neutralFacets;
  final List<String> excludedByAll;

  const EligibilityMatch({
    required this.schemeId,
    required this.eligible,
    this.matchedFacets = const [],
    this.neutralFacets = const [],
    this.excludedByAll = const [],
  });

  factory EligibilityMatch.fromJson(Map<String, dynamic> j) {
    final rawExcludedAll = _strList(j['excludedByAll']);
    final fallbackSingle = _str(j['excludedBy']);
    final effectiveExclusions = rawExcludedAll.isNotEmpty
        ? rawExcludedAll
        : (fallbackSingle != null && fallbackSingle.isNotEmpty
              ? [fallbackSingle]
              : const <String>[]);

    final isEligible = j.containsKey('eligible')
        ? _bool(j['eligible'])
        : effectiveExclusions.isEmpty;

    return EligibilityMatch(
      schemeId: _str(j['schemeId']) ?? '',
      eligible: isEligible,
      matchedFacets: _strList(
        j['matchedFacets'],
      ).map((f) => f == 'state' ? 'state (IN-TN)' : f).toList(),
      neutralFacets: _strList(j['neutralFacets']),
      excludedByAll: effectiveExclusions,
    );
  }

  Map<String, dynamic> toJson() => _clean({
    'schemeId': schemeId,
    'eligible': eligible,
    'matchedFacets': matchedFacets,
    'neutralFacets': neutralFacets,
    'excludedByAll': excludedByAll,
    'excludedBy': excludedByAll.isNotEmpty ? excludedByAll.first : null,
  });

  bool get isExcludedOnMultipleCounts => excludedByAll.length > 1;

  String get summary {
    if (eligible) {
      if (matchedFacets.isEmpty) {
        return 'No exclusions recorded for your profile.';
      }
      return 'Matched on ${matchedFacets.join(', ')}.';
    }
    if (excludedByAll.isEmpty) return 'Profile does not meet criteria.';
    if (excludedByAll.length == 1) return 'Excluded on ${excludedByAll.first}.';
    return 'Excluded on ${excludedByAll.length} counts (${excludedByAll.join(', ')}).';
  }
}

// ---------------------------------------------------------------------------
// Explanation
// ---------------------------------------------------------------------------

class Explanation {
  final String summary;
  final List<MatchReason> reasons;

  const Explanation({required this.summary, this.reasons = const []});

  factory Explanation.fromJson(Map<String, dynamic> j) => Explanation(
    summary: _str(j['summary']) ?? _str(j['text']) ?? '',
    reasons: _objList(j['matchReasons'] ?? j['reasons'], MatchReason.fromJson),
  );

  Map<String, dynamic> toJson() => _clean({
    'summary': summary,
    'matchReasons': reasons.map((e) => e.toJson()).toList(),
  });
}

// ---------------------------------------------------------------------------
// SchemeResult
// ---------------------------------------------------------------------------

class SchemeResult {
  final int rank;
  final String schemeId;
  final String name;
  final SchemeStatus status;
  final double matchScore;
  final RankingSignals rankingSignals;
  final List<MatchReason> matchReasons;
  final Explanation explanation;
  final List<Citation> citations;
  final DataConfidence? confidence;
  final List<FinanceBenefit> assistance;
  final List<AuthorityRef> authority;
  final EligibilityMatch? eligibility;
  final ApplicationState applicationState;
  final List<NextAction> nextActions;

  const SchemeResult({
    this.rank = 0,
    required this.schemeId,
    this.name = '',
    this.status = SchemeStatus.unknown,
    this.matchScore = 0.0,
    this.rankingSignals = const RankingSignals(),
    this.matchReasons = const [],
    this.explanation = const Explanation(summary: ''),
    this.citations = const [],
    this.confidence,
    this.assistance = const [],
    this.authority = const [],
    this.eligibility,
    this.applicationState = ApplicationState.unrecognised,
    this.nextActions = const [],
  });

  factory SchemeResult.fromJson(Map<String, dynamic> j) {
    final conf = j['confidence'] is Map
        ? DataConfidence.fromJson(_map(j['confidence']))
        : null;
    final actions = _objList(j['nextActions'], NextAction.fromJson);

    final status = j['status'] != null || j['schemeStatus'] != null
        ? schemeStatusFrom(_str(j['status']) ?? _str(j['schemeStatus']))
        : (conf?.schemeStatus ?? SchemeStatus.unrecognised);

    final score = _dblOrNull(j['matchScore']) ?? _dblOrNull(j['score']) ?? 0.0;
    final reasons = _objList(j['matchReasons'], MatchReason.fromJson);
    final rawExp = j['explanation'];
    Explanation exp;
    if (rawExp is Map) {
      exp = Explanation.fromJson(_map(rawExp));
    } else if (rawExp is String) {
      exp = Explanation(summary: rawExp, reasons: reasons);
    } else {
      exp = Explanation(summary: '', reasons: reasons);
    }

    final eligibilityMap = j['applicability'] is Map
        ? _map(j['applicability'])
        : (j['eligibility'] is Map ? _map(j['eligibility']) : null);

    final derivedAppState = j['applicationState'] != null
        ? applicationStateFrom(_str(j['applicationState']))
        : _deriveApplicationState(status, actions);

    return SchemeResult(
      rank: _intOrNull(j['rank']) ?? 0,
      schemeId: _str(j['schemeId']) ?? _str(j['id']) ?? '',
      name: _str(j['name']) ?? '',
      status: status,
      matchScore: score,
      rankingSignals: RankingSignals.fromJson(_map(j['rankingSignals'])),
      matchReasons: reasons,
      explanation: exp,
      citations: _objList(j['citations'], Citation.fromJson),
      confidence: conf,
      assistance: _objList(
        j['assistance'] ?? j['finance'],
        FinanceBenefit.fromJson,
      ),
      authority: _objList(j['authority'], AuthorityRef.fromJson),
      eligibility: eligibilityMap != null
          ? EligibilityMatch.fromJson(eligibilityMap)
          : null,
      applicationState: derivedAppState,
      nextActions: actions,
    );
  }

  static ApplicationState _deriveApplicationState(
    SchemeStatus status,
    List<NextAction> actions,
  ) {
    if (status == SchemeStatus.closed) return ApplicationState.closed;
    for (final a in actions) {
      if (a.action == 'apply_online' && a.url != null && a.url!.isNotEmpty) {
        return ApplicationState.openOnline;
      }
    }
    if (actions.any(
      (a) => a.action == 'prepare_documents' || a.action == 'contact_authority',
    )) {
      return ApplicationState.openOffline;
    }
    return ApplicationState.unconfirmed;
  }

  Map<String, dynamic> toJson() => _clean({
    'rank': rank,
    'schemeId': schemeId,
    'name': name,
    'status': schemeStatusTo(status),
    'matchScore': matchScore,
    'rankingSignals': rankingSignals.toJson(),
    'matchReasons': matchReasons.map((e) => e.toJson()).toList(),
    'explanation': explanation.toJson(),
    'citations': citations.map((e) => e.toJson()).toList(),
    'confidence': confidence?.toJson(),
    'assistance': assistance.map((e) => e.toJson()).toList(),
    'authority': authority.map((e) => e.toJson()).toList(),
    'eligibility': eligibility?.toJson(),
    'applicationState': applicationStateTo(applicationState),
    'nextActions': nextActions.map((e) => e.toJson()).toList(),
  });

  bool get isClosed => status == SchemeStatus.closed;

  NextAction? get applyAction {
    if (isClosed) return null;
    for (final a in nextActions) {
      if (a.action == 'apply_online' && a.url != null && a.url!.isNotEmpty) {
        return a;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// UpdateMetadata
// ---------------------------------------------------------------------------

class UpdateMetadata {
  final String? catalogVersion;
  final String? lastUpdated;
  final String? catalogChecksum;
  final String? schemaVersion;
  final String? contractVersion;
  final Map<String, int> entityCounts;
  final List<String> supportedLanguages;
  final Map<String, dynamic> profileDimensions;

  const UpdateMetadata({
    this.catalogVersion,
    this.lastUpdated,
    this.catalogChecksum,
    this.schemaVersion,
    this.contractVersion,
    this.entityCounts = const {},
    this.supportedLanguages = const ['en'],
    this.profileDimensions = const {},
  });

  factory UpdateMetadata.fromJson(Map<String, dynamic> j) => UpdateMetadata(
    catalogVersion: _str(j['catalogVersion']),
    lastUpdated: _str(j['lastUpdated']) ?? _str(j['generatedAt']),
    catalogChecksum: _str(j['catalogChecksum']),
    schemaVersion: _str(j['schemaVersion']),
    contractVersion: _str(j['contractVersion']),
    entityCounts: _map(
      j['entityCounts'],
    ).map((k, v) => MapEntry(k, _intOrNull(v) ?? 0)),
    supportedLanguages: _strList(j['supportedLanguages']).isEmpty
        ? const ['en']
        : _strList(j['supportedLanguages']),
    profileDimensions: _map(j['profileDimensions']),
  );

  Map<String, dynamic> toJson() => _clean({
    'contractVersion': contractVersion,
    'catalogVersion': catalogVersion,
    'lastUpdated': lastUpdated,
    'catalogChecksum': catalogChecksum,
    'schemaVersion': schemaVersion,
    'entityCounts': entityCounts.isEmpty ? null : entityCounts,
    'supportedLanguages': supportedLanguages,
    'profileDimensions': profileDimensions.isEmpty ? null : profileDimensions,
  });

  bool isStaleAgainst(String? cachedCatalogVersion) =>
      catalogVersion != null && catalogVersion != cachedCatalogVersion;

  List<String> get zeroCoverageDimensions {
    final out = <String>[];
    profileDimensions.forEach((dim, info) {
      if ((_intOrNull(_map(info)['schemesWithData']) ?? 0) == 0) out.add(dim);
    });
    out.sort();
    return out;
  }
}

// ---------------------------------------------------------------------------
// Request Bodies (SearchRequest & EligibilityRequest)
// ---------------------------------------------------------------------------

class SearchRequest {
  final String query;
  final String language;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? sort;
  final int? limit;
  final int? offset;
  final String? cursor;

  const SearchRequest({
    required this.query,
    this.language = 'en',
    this.profile,
    this.filters,
    this.sort,
    this.limit,
    this.offset,
    this.cursor,
  });

  Map<String, dynamic> toJson() {
    final page = <String, dynamic>{};
    if (cursor != null && cursor!.isNotEmpty) {
      page['cursor'] = cursor;
    } else {
      if (limit != null) page['limit'] = limit;
      if (offset != null) page['offset'] = offset;
    }

    final m = <String, dynamic>{'query': query, 'language': language};
    if (profile != null) m['profile'] = profile;
    if (filters != null) m['filters'] = filters;
    if (sort != null) m['sort'] = sort;
    if (page.isNotEmpty) m['page'] = page;
    return _clean(m);
  }

  factory SearchRequest.fromJson(Map<String, dynamic> j) => SearchRequest(
    query: _str(j['query']) ?? '',
    language: _str(j['language']) ?? 'en',
    profile: j['profile'] is Map ? _map(j['profile']) : null,
    filters: j['filters'] is Map ? _map(j['filters']) : null,
    sort: j['sort'] is Map ? _map(j['sort']) : null,
    limit: _map(j['page'])['limit'] is int
        ? _map(j['page'])['limit'] as int
        : null,
    offset: _map(j['page'])['offset'] is int
        ? _map(j['page'])['offset'] as int
        : null,
    cursor: _str(_map(j['page'])['cursor']),
  );
}

class EligibilityRequest {
  final Map<String, dynamic> profile;
  final bool onlyEligible;
  final int? limit;
  final String? cursor;

  const EligibilityRequest({
    required this.profile,
    this.onlyEligible = false,
    this.limit,
    this.cursor,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'profile': profile,
      'onlyEligible': onlyEligible,
    };
    if (limit != null) m['limit'] = limit;
    if (cursor != null && cursor!.isNotEmpty) m['cursor'] = cursor;
    return _clean(m);
  }

  factory EligibilityRequest.fromJson(Map<String, dynamic> j) =>
      EligibilityRequest(
        profile: _map(j['profile']),
        onlyEligible: _bool(j['onlyEligible']),
        limit: _intOrNull(j['limit']),
        cursor: _str(j['cursor']),
      );
}

// ---------------------------------------------------------------------------
// MSSSearchResponse
// ---------------------------------------------------------------------------

class MSSSearchResponse {
  final String query;
  final DetectedIntent detectedIntent;
  final Map<String, String>? userProfile;
  final List<SchemeResult> results;
  final UpdateMetadata metadata;
  final List<ResponseWarning> warnings;
  final bool deterministic;
  final String language;

  const MSSSearchResponse({
    this.query = '',
    this.detectedIntent = const DetectedIntent(),
    this.userProfile,
    this.results = const [],
    this.metadata = const UpdateMetadata(),
    this.warnings = const [],
    this.deterministic = true,
    this.language = 'en',
  });

  factory MSSSearchResponse.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map ? _map(j['data']) : j;
    final q = data['query'] is Map ? _map(data['query']) : _map(j['query']);
    final profileRaw =
        data['profileApplied'] ??
        data['userProfile'] ??
        j['profileApplied'] ??
        j['userProfile'];
    final profile = profileRaw is Map
        ? _map(profileRaw).map((k, v) => MapEntry(k, v?.toString() ?? ''))
        : null;

    final resultsRaw = data['results'] ?? j['results'];

    return MSSSearchResponse(
      query: _str(q['text']) ?? _str(data['query']) ?? _str(j['query']) ?? '',
      detectedIntent: DetectedIntent.fromJson(_map(q['detectedIntent'])),
      userProfile: (profile == null || profile.isEmpty) ? null : profile,
      results: _objList(resultsRaw, SchemeResult.fromJson),
      metadata: j['metadata'] is Map
          ? UpdateMetadata.fromJson(_map(j['metadata']))
          : UpdateMetadata.fromJson(j),
      warnings: _objList(j['warnings'], ResponseWarning.fromJson),
      deterministic: _bool(j['deterministic'], true),
      language: _str(q['language']) ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => _clean({
    'contractVersion': metadata.contractVersion,
    'contract': 'search_response',
    'generatedAt': metadata.lastUpdated,
    'catalogVersion': metadata.catalogVersion,
    'deterministic': deterministic,
    'query': {
      'text': query,
      'language': language,
      'detectedIntent': detectedIntent.toJson(),
    },
    'profileApplied': userProfile,
    'warnings': warnings.map((e) => e.toJson()).toList(),
    'resultCount': results.length,
    'results': results.map((e) => e.toJson()).toList(),
    'metadata': metadata.toJson(),
  });

  static MSSSearchResponse parse(String jsonString) =>
      MSSSearchResponse.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

  String encode() => jsonEncode(toJson());

  List<SchemeResult> get eligibleResults =>
      results.where((r) => r.eligibility?.eligible ?? true).toList();

  List<SchemeResult> get actionableResults =>
      results.where((r) => !r.isClosed).toList();
}

// ---------------------------------------------------------------------------
// Supplementary / Detail & Intelligence DTOs
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
        : (singleEx != null && singleEx.isNotEmpty
              ? [singleEx]
              : const <String>[]);

    return MssApplicabilityMatch(
      schemeId: _str(j['schemeId']) ?? '',
      eligible: j.containsKey('eligible')
          ? _bool(j['eligible'])
          : exAll.isEmpty,
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
    final profileRaw =
        data['profileApplied'] ??
        data['userProfile'] ??
        j['profileApplied'] ??
        j['userProfile'];

    return MssSearchResponse(
      contractVersion: _str(j['contractVersion']) ?? '',
      catalogVersion: _str(j['catalogVersion']),
      queryText:
          _str(q['text']) ?? _str(data['query']) ?? _str(j['query']) ?? '',
      detectedIntent: MssDetectedIntent.fromJson(_map(q['detectedIntent'])),
      profileApplied: profileRaw is Map ? _map(profileRaw) : const {},
      warnings: _objList(j['warnings'], MssWarning.fromJson),
      results: _objList(
        data['results'] ?? j['results'],
        MssSearchResult.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => _clean({
    'contractVersion': contractVersion,
    'contract': 'search_response',
    'catalogVersion': catalogVersion,
    'query': {'text': queryText, 'detectedIntent': detectedIntent.toJson()},
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
    List<MssEntityRef> refs(String key) =>
        _objList(j[key], MssEntityRef.fromJson);
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
    entityCounts: _map(
      j['entityCounts'],
    ).map((k, v) => MapEntry(k, _intOrNull(v) ?? 0)),
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

  bool get isRetryable =>
      code == 'CATALOG_UNAVAILABLE' || code == 'INTERNAL_ERROR';

  @override
  String toString() => 'MssApiError($code): $message';
}
