// MSS Flutter Data Model Contract — Phase 4 (finalized)
//
// COPY-READY, NOT INSTALLED. Lives in the catalog repo under
// Plan/flutter_models/. Copy into the Flutter project when the integration
// is authorized. Nothing here writes to or depends on the Flutter project.
//
// Mirrors the finalized MSS intelligence response contract produced by
// catalog/mss_api.py. Every field below traces to real MSS output — see
// PHASE4_APPLICATION_INTEGRATION_PLAN.md and the field-mapping audit.
//
// APPROVED DESIGN DECISIONS BAKED IN (do not "fix" these later without
// re-reading the reasoning):
//
//  * FinanceBenefit.conditions  -> ships as an empty list. The underlying
//    field is populated on 0 of 115 finance records. The list exists so the
//    shape is stable; it must never be presented as "no conditions apply".
//  * FinanceBenefit.mode        -> NULLABLE, mapped to applicationRoute
//    (31/115). NOT mapped to disbursement.mode, which is 0/115.
//  * Citation.sourceTier        -> real provenance (5 = live official fetch,
//    2 = structured from already-held text). Never inferred.
//  * EligibilityMatch           -> has excludedByAll[], NOT a fabricated
//    "unmatchedCriteria" derived from a single exclusion.
//  * EligibilityMatch.confidence -> REMOVED. Verification confidence measures
//    DATA QUALITY, not whether the user qualifies. Conflating them would tell
//    a user "high confidence you're eligible" when it means "this scheme's
//    data is well-sourced". Data confidence lives on SchemeResult instead.
//  * Explanation.evidence[]     -> REMOVED. matchReasons[] already IS the
//    evidence; a parallel list would duplicate or invent.
//  * UpdateMetadata.availableUpdates -> REMOVED. No update-checking mechanism
//    exists server-side. Use UpdateMetadata.isStaleAgainst(cachedVersion).
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
// Enums — every one has an `unrecognised` fallback. A new server-side value
// must never crash an app build that predates it.
// ---------------------------------------------------------------------------

/// Real-world status of the scheme. TRI-STATE — never collapse to a bool.
/// 112 of 217 schemes are genuinely `unknown`: not active, not closed, simply
/// unrecorded. Never badge `unknown` as active; never hide it either.
enum SchemeStatus { active, closed, unknown, unrecognised }

SchemeStatus schemeStatusFrom(String? v) => switch (v) {
      'active' => SchemeStatus.active,
      'closed' => SchemeStatus.closed,
      'unknown' => SchemeStatus.unknown,
      _ => SchemeStatus.unrecognised,
    };

String schemeStatusTo(SchemeStatus s) =>
    s == SchemeStatus.unrecognised ? 'unknown' : s.name;

/// How well-verified the CATALOG DATA is — distinct from search relevance and
/// from eligibility. A scheme can rank #1 and still be `low`.
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
  unrecognised
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

/// Whether the user can act on this scheme right now. Derived server-side
/// from scheme status + available next actions — no new data invented.
enum ApplicationState {
  /// Scheme recorded as closed. NEVER offer an application path.
  closed,

  /// An official online application URL is known.
  openOnline,

  /// Actionable, but no online URL — offline/contact route only.
  openOffline,

  /// Real-world status unrecorded (112/217). Show a neutral
  /// "status not confirmed" chip. Do not present as active; do not hide.
  unconfirmed,

  unrecognised
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

/// Where a citation came from. Kept distinguishable rather than merged —
/// they answer different questions.
enum CitationOrigin {
  /// From provenance.fieldSources[] — why THIS result matched.
  matchEvidence,

  /// From content.sources[] — the scheme's own cited documents.
  schemeSource,

  unrecognised
}

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
// 6. Citation
// ---------------------------------------------------------------------------

/// A provenance record backing a claim.
///
/// [sourceTier] uses the MSS Data Completion Policy scale:
///   5 = retrieved live from an approved official government domain
///   2 = structured from a document already held (no live fetch)
/// Lower number does NOT mean worse — it means a different acquisition route.
///
/// [externalSource] IS LOAD-BEARING. When false, no live external source was
/// consulted; [organization] and [url] are typically null. The UI MUST NOT
/// render these as web-verified citations — no "verified via sidbi.in" badge
/// for a fill that never touched the web.
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

  factory Citation.fromJson(Map<String, dynamic> j) => Citation(
        sourceName: _str(j['sourceName']),
        organization: _str(j['organization']),
        url: _str(j['url']),
        retrievedDate: _str(j['retrievedDate']),
        sourceTier: _intOrNull(j['sourceTier']),
        sourceId: _str(j['sourceId']),
        externalSource: _bool(j['externalSource']),
        origin: citationOriginFrom(_str(j['origin'])),
        isPrimary: _bool(j['isPrimary']),
      );

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

  /// Display label that never fabricates a source name.
  String get displayLabel {
    if (!externalSource) {
      return sourceId == null
          ? 'Internal catalog record (no external source)'
          : 'Internal record $sourceId (no external source)';
    }
    return organization ?? sourceName ?? url ?? 'Official source';
  }

  /// True only for a live fetch from an approved official domain. Gate any
  /// "verified" badge on this, not on [externalSource] alone.
  bool get isLiveOfficialFetch => sourceTier == 5 && externalSource;

  bool get isOpenable => url != null && url!.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Supporting value objects
// ---------------------------------------------------------------------------

/// Monetary figures. Always prefer the *Text variants for display — they
/// preserve the government's own phrasing ("₹5 lakh"), which formatting an
/// integer would destroy ("₹500,000").
class BenefitAmount {
  final String? currency;
  final double? percentage;
  final String? percentageText;
  final int? maxInr;
  final String? maxText;
  final int? minInr;
  final String? minText;

  const BenefitAmount({
    this.currency,
    this.percentage,
    this.percentageText,
    this.maxInr,
    this.maxText,
    this.minInr,
    this.minText,
  });

  factory BenefitAmount.fromJson(Map<String, dynamic> j) => BenefitAmount(
        currency: _str(j['currency']),
        percentage: _dblOrNull(j['percentage']),
        percentageText: _str(j['percentageText']),
        maxInr: _intOrNull(j['maxInr']),
        maxText: _str(j['maxText']),
        minInr: _intOrNull(j['minInr']),
        minText: _str(j['minText']),
      );

  Map<String, dynamic> toJson() => _clean({
        'currency': currency,
        'percentage': percentage,
        'percentageText': percentageText,
        'maxInr': maxInr,
        'maxText': maxText,
        'minInr': minInr,
        'minText': minText,
      });

  /// Government-authored display string, never a self-formatted number.
  String? get displayText => maxText ?? percentageText ?? minText;

  bool get hasAnyValue =>
      percentage != null || maxInr != null || maxText != null || minText != null;
}

/// One named reason a scheme matched, tied to a scoring dimension.
/// This IS the evidence — there is deliberately no parallel `evidence[]`.
class MatchReason {
  final String dimension; // keyword | category | eligibility | benefit | semantic
  final String detail;

  const MatchReason({required this.dimension, required this.detail});

  factory MatchReason.fromJson(Map<String, dynamic> j) => MatchReason(
        dimension: _str(j['dimension']) ?? 'unknown',
        detail: _str(j['detail']) ?? '',
      );

  Map<String, dynamic> toJson() => {'dimension': dimension, 'detail': detail};
}

/// DATA-QUALITY signal, surfaced verbatim from the catalog's verification
/// block. NOT a search-relevance score and NOT an eligibility judgement.
class DataConfidence {
  final ConfidenceLevel level;
  final VerificationStatus verificationStatus;
  final SchemeStatus schemeStatus;
  final int missingFieldCount;
  final String? basis;

  const DataConfidence({
    this.level = ConfidenceLevel.unrecognised,
    this.verificationStatus = VerificationStatus.unrecognised,
    this.schemeStatus = SchemeStatus.unrecognised,
    this.missingFieldCount = 0,
    this.basis,
  });

  factory DataConfidence.fromJson(Map<String, dynamic> j) => DataConfidence(
        level: confidenceLevelFrom(_str(j['level'])),
        verificationStatus: verificationStatusFrom(_str(j['verificationStatus'])),
        schemeStatus: schemeStatusFrom(_str(j['schemeStatus'])),
        missingFieldCount: _intOrNull(j['missingFieldCount']) ?? 0,
        basis: _str(j['basis']),
      );

  Map<String, dynamic> toJson() => _clean({
        'level': level == ConfidenceLevel.unrecognised ? null : level.name,
        'verificationStatus': verificationStatusTo(verificationStatus),
        'schemeStatus': schemeStatusTo(schemeStatus),
        'missingFieldCount': missingFieldCount,
        'basis': basis,
      });

  bool get statusUnconfirmed => schemeStatus == SchemeStatus.unknown;
}

/// Administering or implementing body.
class AuthorityRef {
  final String entityId;
  final String entityType; // 'authority' | 'institution'
  final String? name;
  final String? shortName;
  final String? relationType; // administered_by | implemented_by

  const AuthorityRef({
    required this.entityId,
    this.entityType = 'authority',
    this.name,
    this.shortName,
    this.relationType,
  });

  factory AuthorityRef.fromJson(Map<String, dynamic> j) => AuthorityRef(
        entityId: _str(j['entityId']) ?? '',
        entityType: _str(j['entityType']) ?? 'authority',
        name: _str(j['name']),
        shortName: _str(j['shortName']),
        relationType: _str(j['relationType']),
      );

  Map<String, dynamic> toJson() => _clean({
        'entityId': entityId,
        'entityType': entityType,
        'name': name,
        'shortName': shortName,
        'relationType': relationType,
      });

  String get displayName => shortName ?? name ?? entityId;
}

/// Detected query intent — deterministic table lookup, never a language
/// model. The same query text always yields the same tags.
class DetectedIntent {
  final List<String> intents;
  final List<String> industries;
  final List<String> benefits;
  final List<String> communities;
  final List<String> collateral;
  final List<String> treds;

  const DetectedIntent({
    this.intents = const [],
    this.industries = const [],
    this.benefits = const [],
    this.communities = const [],
    this.collateral = const [],
    this.treds = const [],
  });

  factory DetectedIntent.fromJson(Map<String, dynamic> j) => DetectedIntent(
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

/// Server notice that a requested filter did nothing — e.g. no scheme in this
/// release records a `community` value. Surface it; ignoring it lets a user
/// believe a filter applied when it did not.
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
        code: _str(j['code']) ?? 'UNKNOWN',
        field: _str(j['field']),
        message: _str(j['message']) ?? '',
        hint: _str(j['hint']),
      );

  Map<String, dynamic> toJson() =>
      _clean({'code': code, 'field': field, 'message': message, 'hint': hint});
}

/// Raw scoring components + the weights that produced the score, so a client
/// can audit the arithmetic instead of trusting a black box.
class RankingSignals {
  final Map<String, double> components;
  final Map<String, double> weights;

  const RankingSignals({this.components = const {}, this.weights = const {}});

  factory RankingSignals.fromJson(Map<String, dynamic> j) {
    Map<String, double> nums(dynamic v) =>
        _map(v).map((k, value) => MapEntry(k, _dbl(value)));
    return RankingSignals(
      components: nums(j['components']),
      weights: nums(j['weights']),
    );
  }

  Map<String, dynamic> toJson() => {'components': components, 'weights': weights};

  /// Recomputes the score from components × weights — use in tests to assert
  /// the server's arithmetic. Small float drift is expected.
  double get recomputedScore {
    var total = 0.0;
    components.forEach((k, v) => total += v * (weights[k] ?? 0.0));
    return total;
  }
}

/// A concrete next step, gated server-side on data that actually exists.
/// `apply_online` is emitted ONLY when a real portal URL is known and NEVER
/// for a scheme recorded as closed.
class NextAction {
  final String action;
  final String label;
  final String? url;
  final bool available;
  final String? note;
  final List<String> entityIds;
  final bool statusUnconfirmed;

  const NextAction({
    required this.action,
    this.label = '',
    this.url,
    this.available = false,
    this.note,
    this.entityIds = const [],
    this.statusUnconfirmed = false,
  });

  factory NextAction.fromJson(Map<String, dynamic> j) => NextAction(
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
  bool get isOpenable => available && url != null && url!.isNotEmpty;
}

// ---------------------------------------------------------------------------
// 3. FinanceBenefit
// ---------------------------------------------------------------------------

/// Monetary assistance linked to a scheme, resolved from finance_catalog.
///
/// COVERAGE HONESTY (measured, 115 records):
///   type/typeText    115/115
///   amount.maxText    84/115   amount.maxInr 26/115   percentage 16/115
///   mode              31/115   (applicationRoute; disbursement.mode is 0/115)
///   conditions         0/115   -- EMPTY ON EVERY RECORD
///
/// [conditions] being empty means "no condition is recorded", NOT "no
/// condition applies". Never render it as "No conditions".
class FinanceBenefit {
  final String? financeId;
  final String? type;
  final String? typeText;
  final bool? isRepayable;
  final bool? isGuarantee;
  final BenefitAmount amount;

  /// Application route. NULLABLE by design — mapped to applicationRoute
  /// (31/115), not disbursement.mode (0/115). Null means unrecorded.
  final String? mode;

  final String? applicationUrl;

  /// Empty on all 115 records today. Present for shape stability only.
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

  factory FinanceBenefit.fromJson(Map<String, dynamic> j) => FinanceBenefit(
        financeId: _str(j['financeId']),
        type: _str(j['type']),
        typeText: _str(j['typeText']),
        isRepayable: j['isRepayable'] is bool ? j['isRepayable'] as bool : null,
        isGuarantee: j['isGuarantee'] is bool ? j['isGuarantee'] as bool : null,
        amount: BenefitAmount.fromJson(_map(j['amount'])),
        mode: _str(j['mode']),
        applicationUrl: _str(j['applicationUrl']),
        conditions: _strList(j['conditions']),
        collateralStatus: _str(j['collateralStatus']),
        providers: _strList(j['providers']),
        description: _str(j['description']),
        source: j['source'] is Map ? Citation.fromJson(_map(j['source'])) : null,
      );

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
        'collateralStatus': collateralStatus,
        'providers': providers.isEmpty ? null : providers,
        'description': description,
        'source': source?.toJson(),
      });

  /// True only when the catalog explicitly records collateral as not required.
  /// `guarantee_covered` is deliberately NOT treated as collateral-free — a
  /// credit guarantee and a collateral waiver are different facts.
  bool get isCollateralFree => collateralStatus == 'not_required';

  bool get isGuaranteeBacked => collateralStatus == 'guarantee_covered';

  /// Distinguishes "no conditions recorded" from "no conditions apply".
  bool get conditionsUnrecorded => conditions.isEmpty;
}

// ---------------------------------------------------------------------------
// 4. EligibilityMatch
// ---------------------------------------------------------------------------

/// Structured eligibility outcome for one scheme against a user profile.
///
/// TRI-STATE, do not simplify. [unknownCriteria] are facets the scheme does
/// not record — they are *unrecorded*, NOT "matches everyone". Presenting an
/// unknown as a positive match would tell users they qualify for things
/// nobody verified.
///
/// NOTE: there is deliberately no `confidence` here. Verification confidence
/// measures data quality, not whether the user qualifies; it lives on
/// [SchemeResult.confidence].
class EligibilityMatch {
  final String schemeId;
  final bool eligible;

  /// Facets where the profile value matched a value the scheme records.
  final List<String> matchedCriteria;

  /// Facets the scheme does not record at all — neutral, never excluding.
  final List<String> unknownCriteria;

  /// ALL facets that excluded this scheme, in dimension order. Empty when
  /// eligible. This is the real list — not a single exclusion dressed up as
  /// one.
  final List<String> excludedByAll;

  /// First excluding facet, retained for backward compatibility.
  /// Prefer [excludedByAll].
  final String? excludedBy;

  const EligibilityMatch({
    required this.schemeId,
    this.eligible = false,
    this.matchedCriteria = const [],
    this.unknownCriteria = const [],
    this.excludedByAll = const [],
    this.excludedBy,
  });

  factory EligibilityMatch.fromJson(Map<String, dynamic> j) {
    final all = _strList(j['excludedByAll']);
    final first = _str(j['excludedBy']);
    return EligibilityMatch(
      schemeId: _str(j['schemeId']) ?? '',
      eligible: _bool(j['eligible']),
      matchedCriteria: _strList(j['matchedFacets']),
      unknownCriteria: _strList(j['neutralFacets']),
      // Tolerates an older server that predates excludedByAll.
      excludedByAll: all.isNotEmpty ? all : (first != null ? [first] : const []),
      excludedBy: first,
    );
  }

  Map<String, dynamic> toJson() => _clean({
        'schemeId': schemeId,
        'eligible': eligible,
        'matchedFacets': matchedCriteria,
        'neutralFacets': unknownCriteria,
        'excludedByAll': excludedByAll,
        'excludedBy': excludedBy,
      });

  bool get isExcludedOnMultipleCounts => excludedByAll.length > 1;

  /// Honest one-liner for the UI. Never claims a positive match from unknowns.
  String get summary {
    if (eligible) {
      if (matchedCriteria.isEmpty) {
        return 'Not excluded, but no eligibility criteria were recorded to match against.';
      }
      final base = 'Matches on ${matchedCriteria.join(", ")}';
      return unknownCriteria.isEmpty
          ? '$base.'
          : '$base. Not recorded for this scheme: ${unknownCriteria.join(", ")}.';
    }
    return 'Not eligible — excluded on ${excludedByAll.join(", ")}.';
  }
}

// ---------------------------------------------------------------------------
// 5. Explanation
// ---------------------------------------------------------------------------

/// Why a scheme was returned.
///
/// There is deliberately NO `evidence[]` field: [reasons] already carries the
/// specific matched values (e.g. "matched keyword(s): loan"), which IS the
/// evidence. A parallel list would duplicate it or invite invention.
class Explanation {
  final String summary;
  final List<MatchReason> reasons;
  final List<Citation> citations;

  const Explanation({
    this.summary = '',
    this.reasons = const [],
    this.citations = const [],
  });

  factory Explanation.fromJson(Map<String, dynamic> j) => Explanation(
        summary: _str(j['summary']) ?? _str(j['explanation']) ?? '',
        reasons: _objList(j['reasons'] ?? j['matchReasons'], MatchReason.fromJson),
        citations: _objList(j['citations'], Citation.fromJson),
      );

  /// Builds from a SchemeResult's own fields — the server returns these
  /// flattened onto the result rather than under an `explanation` object.
  factory Explanation.fromResult(SchemeResult r) => Explanation(
        summary: r.explanationText,
        reasons: r.matchReasons,
        citations: r.citations,
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'reasons': reasons.map((e) => e.toJson()).toList(),
        'citations': citations.map((e) => e.toJson()).toList(),
      };

  bool get hasLiveOfficialCitation => citations.any((c) => c.isLiveOfficialFetch);
}

// ---------------------------------------------------------------------------
// 2. SchemeResult
// ---------------------------------------------------------------------------

class SchemeResult {
  final int rank;
  final String schemeId;
  final String name;
  final SchemeStatus status;
  final double matchScore;
  final RankingSignals rankingSignals;
  final List<MatchReason> matchReasons;
  final String explanationText;
  final List<FinanceBenefit> assistance;
  final EligibilityMatch? eligibility;
  final List<AuthorityRef> authority;
  final List<Citation> citations;
  final ApplicationState applicationState;
  final List<NextAction> nextActions;
  final DataConfidence? confidence;

  const SchemeResult({
    this.rank = 0,
    required this.schemeId,
    this.name = '',
    this.status = SchemeStatus.unrecognised,
    this.matchScore = 0.0,
    this.rankingSignals = const RankingSignals(),
    this.matchReasons = const [],
    this.explanationText = '',
    this.assistance = const [],
    this.eligibility,
    this.authority = const [],
    this.citations = const [],
    this.applicationState = ApplicationState.unrecognised,
    this.nextActions = const [],
    this.confidence,
  });

  factory SchemeResult.fromJson(Map<String, dynamic> j) {
    final conf = j['confidence'] is Map
        ? DataConfidence.fromJson(_map(j['confidence']))
        : null;
    final actions = _objList(j['nextActions'], NextAction.fromJson);

    // `status` is nested under confidence in the search response and top-level
    // in scheme_detail — accept either.
    final status = j['status'] != null || j['schemeStatus'] != null
        ? schemeStatusFrom(_str(j['status']) ?? _str(j['schemeStatus']))
        : (conf?.schemeStatus ?? SchemeStatus.unrecognised);

    return SchemeResult(
      rank: _intOrNull(j['rank']) ?? 0,
      schemeId: _str(j['schemeId']) ?? '',
      name: _str(j['name']) ?? '',
      status: status,
      matchScore: _dbl(j['score'] ?? j['matchScore']),
      rankingSignals: RankingSignals.fromJson(_map(j['rankingSignals'])),
      matchReasons: _objList(j['matchReasons'], MatchReason.fromJson),
      explanationText: _str(j['explanation']) ?? '',
      assistance: _objList(j['assistance'], FinanceBenefit.fromJson),
      eligibility: j['applicability'] is Map
          ? EligibilityMatch.fromJson(_map(j['applicability']))
          : (j['eligibility'] is Map
              ? EligibilityMatch.fromJson(_map(j['eligibility']))
              : null),
      authority: _objList(j['authority'], AuthorityRef.fromJson),
      citations: _objList(j['citations'], Citation.fromJson),
      applicationState: j['applicationState'] != null
          ? applicationStateFrom(_str(j['applicationState']))
          : _deriveApplicationState(status, actions),
      nextActions: actions,
      confidence: conf,
    );
  }

  /// Client-side fallback mirroring the server's own derivation, for older
  /// servers that don't yet send `applicationState`.
  static ApplicationState _deriveApplicationState(
      SchemeStatus status, List<NextAction> actions) {
    if (status == SchemeStatus.closed) return ApplicationState.closed;
    if (status == SchemeStatus.unknown) return ApplicationState.unconfirmed;
    final hasOnline =
        actions.any((a) => a.action == 'apply_online' && a.available);
    if (hasOnline) return ApplicationState.openOnline;
    return actions.isNotEmpty
        ? ApplicationState.openOffline
        : ApplicationState.unrecognised;
  }

  Map<String, dynamic> toJson() => _clean({
        'rank': rank,
        'schemeId': schemeId,
        'name': name,
        'status': schemeStatusTo(status),
        'score': matchScore,
        'rankingSignals': rankingSignals.toJson(),
        'matchReasons': matchReasons.map((e) => e.toJson()).toList(),
        'explanation': explanationText,
        'assistance': assistance.map((e) => e.toJson()).toList(),
        'applicability': eligibility?.toJson(),
        'authority': authority.map((e) => e.toJson()).toList(),
        'citations': citations.map((e) => e.toJson()).toList(),
        'applicationState': applicationStateTo(applicationState),
        'nextActions': nextActions.map((e) => e.toJson()).toList(),
        'confidence': confidence?.toJson(),
      });

  Explanation get explanation => Explanation.fromResult(this);

  /// HARD UI RULE: never offer an application path when this is true.
  bool get isClosed =>
      status == SchemeStatus.closed ||
      applicationState == ApplicationState.closed ||
      nextActions.any((a) => a.isClosedMarker);

  /// Show a neutral "status not confirmed" chip. Do not badge active; do not
  /// hide. Applies to 112 of 217 schemes.
  bool get statusUnconfirmed => status == SchemeStatus.unknown;

  bool get hasLiveOfficialCitation => citations.any((c) => c.isLiveOfficialFetch);

  NextAction? get applyAction {
    for (final a in nextActions) {
      if (a.action == 'apply_online' && a.isOpenable) return a;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// 7. UpdateMetadata
// ---------------------------------------------------------------------------

/// Release/update metadata.
///
/// There is deliberately NO `availableUpdates` field — no update-checking
/// mechanism exists server-side, and a hardcoded flag would be a fabrication.
/// Use [isStaleAgainst] with the locally cached catalog version instead: in
/// the recommended offline-first architecture that comparison IS the update
/// check.
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
        // The catalog's generation timestamp. NOT a data-currency guarantee —
        // it says when the bundle was built, not when the government last
        // changed the underlying scheme.
        lastUpdated: _str(j['lastUpdated']) ?? _str(j['generatedAt']),
        catalogChecksum: _str(j['catalogChecksum']),
        schemaVersion: _str(j['schemaVersion']),
        contractVersion: _str(j['contractVersion']),
        entityCounts:
            _map(j['entityCounts']).map((k, v) => MapEntry(k, _intOrNull(v) ?? 0)),
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

  /// The update check. True when the cached bundle differs from the server's
  /// current release and should be refreshed.
  bool isStaleAgainst(String? cachedCatalogVersion) =>
      catalogVersion != null && catalogVersion != cachedCatalogVersion;

  /// Profile dimensions with zero data in this release — filtering on these
  /// neither matches nor excludes anything. Disable or annotate them rather
  /// than offering a control that silently does nothing.
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
// 1. MSSSearchResponse
// ---------------------------------------------------------------------------

class MSSSearchResponse {
  final String query;
  final DetectedIntent detectedIntent;

  /// Echoed back so the app can confirm what was actually matched against.
  /// Null when no profile was sent. NEVER persisted server-side.
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
    final q = _map(j['query']);
    final profileRaw = j['profileApplied'] ?? j['userProfile'];
    final profile = profileRaw is Map
        ? _map(profileRaw).map((k, v) => MapEntry(k, v?.toString() ?? ''))
        : null;
    return MSSSearchResponse(
      // `query` is an object in the wire format and a plain string here.
      query: _str(q['text']) ?? _str(j['query']) ?? '',
      detectedIntent: DetectedIntent.fromJson(_map(q['detectedIntent'])),
      userProfile: (profile == null || profile.isEmpty) ? null : profile,
      results: _objList(j['results'], SchemeResult.fromJson),
      // Assembled from the response envelope; also accepts a nested
      // `metadata` object if a future server sends one.
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
      MSSSearchResponse.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  String encode() => jsonEncode(toJson());

  List<SchemeResult> get eligibleResults =>
      results.where((r) => r.eligibility?.eligible ?? true).toList();

  List<SchemeResult> get actionableResults =>
      results.where((r) => !r.isClosed).toList();
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

class MSSApiError implements Exception {
  final String code; // INVALID_REQUEST | UNKNOWN_SCHEME | CATALOG_UNAVAILABLE | INTERNAL_ERROR
  final String message;
  final String? field;
  final String? detail;

  const MSSApiError({
    required this.code,
    required this.message,
    this.field,
    this.detail,
  });

  factory MSSApiError.fromJson(Map<String, dynamic> j) {
    final e = _map(j['error']);
    return MSSApiError(
      code: _str(e['code']) ?? 'INTERNAL_ERROR',
      message: _str(e['message']) ?? 'Unknown error',
      field: _str(e['field']),
      detail: _str(e['detail']),
    );
  }

  /// Every response carries either data or an error, never both.
  static bool isError(Map<String, dynamic> j) => j['contract'] == 'error';

  bool get isRetryable => code == 'CATALOG_UNAVAILABLE' || code == 'INTERNAL_ERROR';

  @override
  String toString() =>
      'MSSApiError($code): $message${field != null ? " [$field]" : ""}';
}
