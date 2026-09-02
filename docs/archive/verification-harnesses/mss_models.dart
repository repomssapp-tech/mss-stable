// ⚠ SUPERSEDED FOR THE SEARCH FLOW — READ BEFORE COPYING ⚠
//
// `mss_contract.dart` is the FINALIZED contract and supersedes this file for
// everything search-related. It implements the seven approved design
// decisions (nullable FinanceBenefit.mode, Citation.sourceName/sourceTier,
// EligibilityMatch.excludedByAll, and the removal of
// EligibilityMatch.confidence / Explanation.evidence[] /
// UpdateMetadata.availableUpdates).
//
// DO NOT copy both files into the Flutter project as-is: the search models
// here (MssSearchResponse / MssSearchResult / MssCitation / MssConfidence)
// overlap with mss_contract.dart's (MSSSearchResponse / SchemeResult /
// Citation / DataConfidence) and would give you two near-identical, subtly
// divergent model sets.
//
// This file is retained ONLY because it still carries models the finalized
// contract does not yet cover — the other two API operations:
//     MssApplicabilityResponse   <- applicability()
//     MssSchemeIntelligence      <- scheme_detail()
// If you need those, port them onto mss_contract.dart's types rather than
// copying this file wholesale.
//
// ---------------------------------------------------------------------------
// MSS Application Data Models — Phase 4 (first pass)
//
// DELIVERABLE, NOT INSTALLED. This file lives in the catalog repo
// (Plan/flutter_models/) and is intended to be copied into the Flutter
// project by whoever owns it. Per the standing constraint, this phase does
// not write into C:\development\SearchEngine\IN_Schemes\frontend.
//
// Mirrors the contracts in catalog/mss_api.py + catalog/app_response.py.
// See PHASE4_APPLICATION_INTEGRATION_PLAN.md §3.
//
// Design rules enforced throughout:
//   * Hand-written fromJson/toJson — no json_serializable, no build_runner
//     step. Zero build cost, trivially reviewable.
//   * BACKWARD COMPATIBLE: every parser tolerates missing fields (null-safe
//     defaults) and ignores unknown fields. A server adding a field must
//     never crash an older app build.
//   * OFFLINE CAPABLE: every model round-trips losslessly through toJson,
//     so a response can be cached to disk and rehydrated identically. No
//     model holds a socket, handle, or non-serialisable field.
//   * Unknown enum values degrade to a safe variant instead of throwing.

// ---------------------------------------------------------------------------
// Helpers — tolerant primitives. Every parse goes through these.
// ---------------------------------------------------------------------------

String? _str(dynamic v) => v is String ? v : null;
int _int(dynamic v, [int fallback = 0]) => v is int ? v : (v is num ? v.toInt() : fallback);
double _dbl(dynamic v, [double fallback = 0.0]) =>
    v is num ? v.toDouble() : fallback;
bool _bool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

List<String> _strList(dynamic v) =>
    v is List ? v.whereType<String>().toList() : const <String>[];

List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) parse) =>
    v is List
        ? v
            .whereType<Map>()
            .map((e) => parse(Map<String, dynamic>.from(e)))
            .toList()
        : <T>[];

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Strips null values so cached JSON stays compact and round-trips cleanly.
Map<String, dynamic> _clean(Map<String, dynamic> m) {
  m.removeWhere((_, value) => value == null);
  return m;
}

// ---------------------------------------------------------------------------
// Enums — all with an `unknown` fallback so a new server-side value cannot
// crash an older build.
// ---------------------------------------------------------------------------

/// Real-world status of the scheme itself. TRI-STATE — do not collapse to a
/// bool. 112 of 217 schemes are genuinely `unknown`: not active, not closed,
/// simply unrecorded. Never badge `unknown` as active; never hide it either.
enum SchemeStatus { active, closed, unknown, unrecognised }

SchemeStatus schemeStatusFrom(String? v) {
  switch (v) {
    case 'active':
      return SchemeStatus.active;
    case 'closed':
      return SchemeStatus.closed;
    case 'unknown':
      return SchemeStatus.unknown;
    default:
      return SchemeStatus.unrecognised;
  }
}

String schemeStatusTo(SchemeStatus s) =>
    s == SchemeStatus.unrecognised ? 'unknown' : s.name;

/// How well-verified the CATALOG DATA is. Distinct from search relevance —
/// a scheme can rank #1 and still be `low` confidence. Never merge the two.
enum ConfidenceLevel { high, medium, low, unrecognised }

ConfidenceLevel confidenceLevelFrom(String? v) {
  switch (v) {
    case 'high':
      return ConfidenceLevel.high;
    case 'medium':
      return ConfidenceLevel.medium;
    case 'low':
      return ConfidenceLevel.low;
    default:
      return ConfidenceLevel.unrecognised;
  }
}

enum VerificationStatus {
  verified,
  partiallyVerified,
  unverified,
  historical,
  derived,
  unrecognised
}

VerificationStatus verificationStatusFrom(String? v) {
  switch (v) {
    case 'verified':
      return VerificationStatus.verified;
    case 'partially_verified':
      return VerificationStatus.partiallyVerified;
    case 'unverified':
      return VerificationStatus.unverified;
    case 'historical':
      return VerificationStatus.historical;
    case 'derived':
      return VerificationStatus.derived;
    default:
      return VerificationStatus.unrecognised;
  }
}

// ---------------------------------------------------------------------------
// Citations & explanation
// ---------------------------------------------------------------------------

/// A source backing one match reason.
///
/// [externalSource] IS LOAD-BEARING. When false, the value was structured
/// from text already held in the catalog (a tier-2 fill, no live fetch) and
/// [organization]/[url] are both null. The UI MUST NOT render these as
/// web-verified citations — no "verified via sidbi.in" badge for a fill that
/// never touched the web. Same disclosure principle as machine-translated
/// Tamil being marked unapproved.
class MssCitation {
  final String? organization;
  final String? url;
  final String? sourceId;
  final String? retrievedAt;
  final bool externalSource;

  const MssCitation({
    this.organization,
    this.url,
    this.sourceId,
    this.retrievedAt,
    this.externalSource = false,
  });

  factory MssCitation.fromJson(Map<String, dynamic> j) => MssCitation(
        organization: _str(j['organization']),
        url: _str(j['url']),
        sourceId: _str(j['sourceId']),
        retrievedAt: _str(j['retrievedAt']),
        externalSource: _bool(j['externalSource']),
      );

  Map<String, dynamic> toJson() => _clean({
        'organization': organization,
        'url': url,
        'sourceId': sourceId,
        'retrievedAt': retrievedAt,
        'externalSource': externalSource,
      });

  /// Safe display label that never fabricates a source name.
  String get displayLabel {
    if (!externalSource) {
      return sourceId == null
          ? 'Internal catalog record (no external source)'
          : 'Internal record $sourceId (no external source)';
    }
    return organization ?? url ?? 'Official source';
  }
}

/// One named reason a scheme matched, tied to a scoring dimension.
class MssMatchReason {
  final String dimension; // keyword | category | eligibility | benefit | semantic
  final String detail;

  const MssMatchReason({required this.dimension, required this.detail});

  factory MssMatchReason.fromJson(Map<String, dynamic> j) => MssMatchReason(
        dimension: _str(j['dimension']) ?? 'unknown',
        detail: _str(j['detail']) ?? '',
      );

  Map<String, dynamic> toJson() => {'dimension': dimension, 'detail': detail};
}

/// Data-trustworthiness signal, surfaced verbatim from the catalog's
/// verification block. NOT a search-relevance score and must not be shown
/// as one.
class MssConfidence {
  final ConfidenceLevel level;
  final VerificationStatus verificationStatus;
  final SchemeStatus schemeStatus;
  final int missingFieldCount;
  final String? basis;

  const MssConfidence({
    this.level = ConfidenceLevel.unrecognised,
    this.verificationStatus = VerificationStatus.unrecognised,
    this.schemeStatus = SchemeStatus.unrecognised,
    this.missingFieldCount = 0,
    this.basis,
  });

  factory MssConfidence.fromJson(Map<String, dynamic> j) => MssConfidence(
        level: confidenceLevelFrom(_str(j['level'])),
        verificationStatus: verificationStatusFrom(_str(j['verificationStatus'])),
        schemeStatus: schemeStatusFrom(_str(j['schemeStatus'])),
        missingFieldCount: _int(j['missingFieldCount']),
        basis: _str(j['basis']),
      );

  Map<String, dynamic> toJson() => _clean({
        'level': level == ConfidenceLevel.unrecognised ? null : level.name,
        'verificationStatus': verificationStatus == VerificationStatus.partiallyVerified
            ? 'partially_verified'
            : (verificationStatus == VerificationStatus.unrecognised
                ? null
                : verificationStatus.name),
        'schemeStatus': schemeStatusTo(schemeStatus),
        'missingFieldCount': missingFieldCount,
        'basis': basis,
      });

  /// True when the app should show a neutral "status not confirmed" chip.
  bool get statusUnconfirmed => schemeStatus == SchemeStatus.unknown;
}

// ---------------------------------------------------------------------------
// Ranking & actions
// ---------------------------------------------------------------------------

/// Raw scoring components plus the weights that produced the final score, so
/// a client can audit the arithmetic instead of trusting a black box.
class MssRankingSignals {
  final Map<String, double> components;
  final Map<String, double> weights;

  const MssRankingSignals({this.components = const {}, this.weights = const {}});

  factory MssRankingSignals.fromJson(Map<String, dynamic> j) {
    Map<String, double> nums(dynamic v) => _map(v).map(
        (k, value) => MapEntry(k, _dbl(value)));
    return MssRankingSignals(
      components: nums(j['components']),
      weights: nums(j['weights']),
    );
  }

  Map<String, dynamic> toJson() => {'components': components, 'weights': weights};

  /// Recomputes the score from components × weights. Use in debug/tests to
  /// assert the server's arithmetic; small float drift is expected.
  double get recomputedScore {
    var total = 0.0;
    components.forEach((k, v) => total += v * (weights[k] ?? 0.0));
    return total;
  }
}

/// A concrete next step. Gated server-side on data that actually exists —
/// e.g. `apply_online` is only ever emitted when a real portal URL is known,
/// and NEVER for a scheme recorded as closed.
class MssNextAction {
  final String action;
  final String label;
  final String? url;
  final bool available;
  final String? note;
  final List<String> entityIds;

  /// True when the scheme's real-world status is unrecorded. Render a neutral
  /// "status not confirmed" chip — do not present as active, do not hide.
  final bool statusUnconfirmed;

  const MssNextAction({
    required this.action,
    required this.label,
    this.url,
    this.available = false,
    this.note,
    this.entityIds = const [],
    this.statusUnconfirmed = false,
  });

  factory MssNextAction.fromJson(Map<String, dynamic> j) => MssNextAction(
        action: _str(j['action']) ?? 'unknown',
        label: _str(j['label']) ?? '',
        url: _str(j['url']),
        available: _bool(j['available']),
        note: _str(j['note']),
        entityIds: _strList(j['entityIds']),
        statusUnconfirmed: _bool(j['statusUnconfirmed']),
      );

  Map<String, dynamic> toJson() => _clean({
        'action': action,
        'label': label,
        'url': url,
        'available': available,
        'note': note,
        'entityIds': entityIds.isEmpty ? null : entityIds,
        'statusUnconfirmed': statusUnconfirmed ? true : null,
      });

  bool get isClosedMarker => action == 'scheme_closed';
}

// ---------------------------------------------------------------------------
// Applicability
// ---------------------------------------------------------------------------

/// Structured eligibility outcome for one scheme against a user profile.
///
/// TRI-STATE, do not simplify: a facet in [neutralFacets] is *unrecorded* by
/// that scheme, not "matches everyone". Presenting neutral as a positive
/// match would tell users they qualify for things nobody verified.
class MssApplicabilityMatch {
  final String schemeId;
  final String? name;
  final bool eligible;
  final List<String> matchedFacets;
  final List<String> neutralFacets;
  final String? excludedBy;
  final MssConfidence? confidence;

  const MssApplicabilityMatch({
    required this.schemeId,
    this.name,
    this.eligible = false,
    this.matchedFacets = const [],
    this.neutralFacets = const [],
    this.excludedBy,
    this.confidence,
  });

  factory MssApplicabilityMatch.fromJson(Map<String, dynamic> j) =>
      MssApplicabilityMatch(
        schemeId: _str(j['schemeId']) ?? '',
        name: _str(j['name']),
        eligible: _bool(j['eligible']),
        matchedFacets: _strList(j['matchedFacets']),
        neutralFacets: _strList(j['neutralFacets']),
        excludedBy: _str(j['excludedBy']),
        confidence: j['confidence'] is Map
            ? MssConfidence.fromJson(_map(j['confidence']))
            : null,
      );

  Map<String, dynamic> toJson() => _clean({
        'schemeId': schemeId,
        'name': name,
        'eligible': eligible,
        'matchedFacets': matchedFacets,
        'neutralFacets': neutralFacets,
        'excludedBy': excludedBy,
        'confidence': confidence?.toJson(),
      });
}

/// Server-side notice that a requested filter did nothing — e.g. no scheme in
/// this release records a `community` value. Surface it; silently ignoring it
/// lets a user believe a filter applied when it did not.
class MssWarning {
  final String code;
  final String? field;
  final String message;
  final String? hint;

  const MssWarning({required this.code, this.field, required this.message, this.hint});

  factory MssWarning.fromJson(Map<String, dynamic> j) => MssWarning(
        code: _str(j['code']) ?? 'UNKNOWN',
        field: _str(j['field']),
        message: _str(j['message']) ?? '',
        hint: _str(j['hint']),
      );

  Map<String, dynamic> toJson() =>
      _clean({'code': code, 'field': field, 'message': message, 'hint': hint});
}

// ---------------------------------------------------------------------------
// Results & responses
// ---------------------------------------------------------------------------

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
    this.rank = 0,
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
        rank: _int(j['rank']),
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

  bool get hasExternalCitation => citations.any((c) => c.externalSource);
  bool get isClosed => nextActions.any((a) => a.isClosedMarker);
}

/// Detected query intent — produced by a deterministic table lookup, never a
/// language model. Same query text always yields the same tags.
class MssDetectedIntent {
  final List<String> intents;
  final List<String> industries;
  final List<String> benefits;
  final List<String> communities;
  final List<String> collateral;
  final List<String> treds;

  const MssDetectedIntent({
    this.intents = const [],
    this.industries = const [],
    this.benefits = const [],
    this.communities = const [],
    this.collateral = const [],
    this.treds = const [],
  });

  factory MssDetectedIntent.fromJson(Map<String, dynamic> j) => MssDetectedIntent(
        intents: _strList(j['intents']),
        industries: _strList(j['industries']),
        benefits: _strList(j['benefits']),
        communities: _strList(j['communities']),
        collateral: _strList(j['collateral']),
        treds: _strList(j['treds']),
      );

  Map<String, dynamic> toJson() => {
        'intents': intents,
        'industries': industries,
        'benefits': benefits,
        'communities': communities,
        'collateral': collateral,
        'treds': treds,
      };

  bool get isEmpty =>
      intents.isEmpty &&
      industries.isEmpty &&
      benefits.isEmpty &&
      communities.isEmpty &&
      collateral.isEmpty &&
      treds.isEmpty;
}

class MssSearchResponse {
  final String contractVersion;
  final String? generatedAt;
  final String? catalogVersion;
  final bool deterministic;
  final String queryText;
  final String language;
  final MssDetectedIntent detectedIntent;
  final Map<String, String> profileApplied;
  final List<MssWarning> warnings;
  final List<MssSearchResult> results;

  const MssSearchResponse({
    this.contractVersion = '',
    this.generatedAt,
    this.catalogVersion,
    this.deterministic = true,
    this.queryText = '',
    this.language = 'en',
    this.detectedIntent = const MssDetectedIntent(),
    this.profileApplied = const {},
    this.warnings = const [],
    this.results = const [],
  });

  factory MssSearchResponse.fromJson(Map<String, dynamic> j) {
    final q = _map(j['query']);
    final prof = _map(j['profileApplied']);
    return MssSearchResponse(
      contractVersion: _str(j['contractVersion']) ?? '',
      generatedAt: _str(j['generatedAt']),
      catalogVersion: _str(j['catalogVersion']),
      deterministic: _bool(j['deterministic'], true),
      queryText: _str(q['text']) ?? '',
      language: _str(q['language']) ?? 'en',
      detectedIntent: MssDetectedIntent.fromJson(_map(q['detectedIntent'])),
      profileApplied: prof.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      warnings: _objList(j['warnings'], MssWarning.fromJson),
      results: _objList(j['results'], MssSearchResult.fromJson),
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'contractVersion': contractVersion,
        'contract': 'search_response',
        'generatedAt': generatedAt,
        'catalogVersion': catalogVersion,
        'deterministic': deterministic,
        'query': {
          'text': queryText,
          'language': language,
          'detectedIntent': detectedIntent.toJson(),
        },
        'profileApplied': profileApplied.isEmpty ? null : profileApplied,
        'warnings': warnings.map((e) => e.toJson()).toList(),
        'resultCount': results.length,
        'results': results.map((e) => e.toJson()).toList(),
      });
}

class MssApplicabilityResponse {
  final String contractVersion;
  final String? generatedAt;
  final String? catalogVersion;
  final Map<String, String> profile;
  final List<MssWarning> warnings;
  final List<MssApplicabilityMatch> results;

  const MssApplicabilityResponse({
    this.contractVersion = '',
    this.generatedAt,
    this.catalogVersion,
    this.profile = const {},
    this.warnings = const [],
    this.results = const [],
  });

  factory MssApplicabilityResponse.fromJson(Map<String, dynamic> j) =>
      MssApplicabilityResponse(
        contractVersion: _str(j['contractVersion']) ?? '',
        generatedAt: _str(j['generatedAt']),
        catalogVersion: _str(j['catalogVersion']),
        profile: _map(j['profile']).map((k, v) => MapEntry(k, v?.toString() ?? '')),
        warnings: _objList(j['warnings'], MssWarning.fromJson),
        results: _objList(j['results'], MssApplicabilityMatch.fromJson),
      );

  Map<String, dynamic> toJson() => _clean({
        'contractVersion': contractVersion,
        'contract': 'applicability_response',
        'generatedAt': generatedAt,
        'catalogVersion': catalogVersion,
        'profile': profile,
        'warnings': warnings.map((e) => e.toJson()).toList(),
        'resultCount': results.length,
        'results': results.map((e) => e.toJson()).toList(),
      });

  List<MssApplicabilityMatch> get eligibleOnly =>
      results.where((r) => r.eligible).toList();
}

/// A linked entity (authority, institution, finance product, …). Deliberately
/// a summary, not a full record — the app already holds the full catalog
/// bundle offline, so re-shipping whole records per response would duplicate
/// data the device already has.
class MssEntityRef {
  final String id;
  final String? name;
  final String? relationType;

  const MssEntityRef({required this.id, this.name, this.relationType});

  factory MssEntityRef.fromJson(Map<String, dynamic> j) => MssEntityRef(
        id: _str(j['id']) ?? '',
        name: _str(j['name']),
        relationType: _str(j['relationType']),
      );

  Map<String, dynamic> toJson() =>
      _clean({'id': id, 'name': name, 'relationType': relationType});
}

/// Everything resolvable about one scheme.
///
/// Several lists are legitimately empty in the current catalog release
/// (treds, csr, cluster, privileges, enablement, knowledge) because no scheme
/// declares those edges yet. Empty means "not linked", NOT "failed to load" —
/// render accordingly, and do not retry as if it were an error.
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
      missingReferences: _strList(_map(j['dataIntegrity'])['missingReferences']),
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

/// Release/update metadata. In the recommended offline-first architecture
/// this is the ONLY call the app makes online: compare [catalogVersion] to
/// the cached tag and download a new bundle only on mismatch.
class MssMeta {
  final String contractVersion;
  final String? catalogVersion;
  final String? catalogChecksum;
  final String? schemaVersion;
  final Map<String, int> entityCounts;
  final List<String> supportedLanguages;
  final Map<String, dynamic> profileDimensions;
  final Map<String, double> rankingWeights;

  const MssMeta({
    this.contractVersion = '',
    this.catalogVersion,
    this.catalogChecksum,
    this.schemaVersion,
    this.entityCounts = const {},
    this.supportedLanguages = const ['en'],
    this.profileDimensions = const {},
    this.rankingWeights = const {},
  });

  factory MssMeta.fromJson(Map<String, dynamic> j) => MssMeta(
        contractVersion: _str(j['contractVersion']) ?? '',
        catalogVersion: _str(j['catalogVersion']),
        catalogChecksum: _str(j['catalogChecksum']),
        schemaVersion: _str(j['schemaVersion']),
        entityCounts: _map(j['entityCounts']).map((k, v) => MapEntry(k, _int(v))),
        supportedLanguages: _strList(j['supportedLanguages']).isEmpty
            ? const ['en']
            : _strList(j['supportedLanguages']),
        profileDimensions: _map(j['profileDimensions']),
        rankingWeights: _map(j['rankingWeights']).map((k, v) => MapEntry(k, _dbl(v))),
      );

  Map<String, dynamic> toJson() => _clean({
        'contractVersion': contractVersion,
        'contract': 'meta',
        'catalogVersion': catalogVersion,
        'catalogChecksum': catalogChecksum,
        'schemaVersion': schemaVersion,
        'entityCounts': entityCounts,
        'supportedLanguages': supportedLanguages,
        'profileDimensions': profileDimensions,
        'rankingWeights': rankingWeights,
      });

  /// True when a cached bundle is stale and should be refreshed.
  bool isStaleAgainst(String? cachedCatalogVersion) =>
      catalogVersion != null && catalogVersion != cachedCatalogVersion;

  /// Profile dimensions with zero data in this release — filtering on these
  /// neither matches nor excludes anything, so the UI should disable or
  /// annotate them rather than offering a filter that silently does nothing.
  List<String> get zeroCoverageDimensions {
    final out = <String>[];
    profileDimensions.forEach((dim, info) {
      if (_int(_map(info)['schemesWithData']) == 0) out.add(dim);
    });
    out.sort();
    return out;
  }
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

class MssApiError implements Exception {
  final String code; // INVALID_REQUEST | UNKNOWN_SCHEME | CATALOG_UNAVAILABLE | INTERNAL_ERROR
  final String message;
  final String? field;
  final String? detail;

  const MssApiError({
    required this.code,
    required this.message,
    this.field,
    this.detail,
  });

  factory MssApiError.fromJson(Map<String, dynamic> j) {
    final e = _map(j['error']);
    return MssApiError(
      code: _str(e['code']) ?? 'INTERNAL_ERROR',
      message: _str(e['message']) ?? 'Unknown error',
      field: _str(e['field']),
      detail: _str(e['detail']),
    );
  }

  /// Every response carries either `data` or `error`, never both.
  static bool isError(Map<String, dynamic> j) => j['contract'] == 'error';

  bool get isRetryable => code == 'CATALOG_UNAVAILABLE' || code == 'INTERNAL_ERROR';

  @override
  String toString() => 'MssApiError($code): $message${field != null ? " [$field]" : ""}';
}
