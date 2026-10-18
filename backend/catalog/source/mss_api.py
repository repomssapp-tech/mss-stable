#!/usr/bin/env python3
"""
MSS Application Integration API -- Phase 4.

Transport-agnostic. Returns plain dicts; imports no web framework and binds
no port, so the same functions serve an HTTP adapter, an in-process caller,
or a batch job. See PHASE4_APPLICATION_INTEGRATION_PLAN.md §1 for why.

Builds ON TOP OF the existing intelligence layers -- it does not
reimplement any of them:
    taxonomy_engine.normalize()          intent extraction
    IntelligenceResolver.resolve()       cross-catalog resolution
    IntelligenceResolver.match_applicability()   eligibility matching
    HybridSearch.search()                ranking + explanations
    app_response.build_*()                base response envelopes

Adds only what the app layer needs and nothing below it had:
    - request validation with attributable errors
    - confidence, surfaced verbatim from verification.* (never computed)
    - nextActions, gated on data that actually exists
    - zero-coverage filter warnings
    - a meta() endpoint for cache invalidation

Determinism is preserved end to end: no LLM, no clock-dependent branching,
no set iteration leaking into output ordering. `generatedAt` is the only
varying field and is labelled operational.
"""
import json, os, sys
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CAT)

from taxonomy_engine import normalize as taxonomy_normalize
from intelligence_resolver import IntelligenceResolver
from hybrid_search import HybridSearch, WEIGHTS
import app_response

CONTRACT_VERSION = app_response.CONTRACT_VERSION

MAX_QUERY_LEN = 500
MAX_TOP_N = 50
DEFAULT_TOP_N = 10

# Profile dimensions the applicability matcher understands. Kept in sync with
# IntelligenceResolver._APPLICABILITY_FIELDS -- asserted at construction time
# so the two can never silently drift apart.
PROFILE_DIMENSIONS = ("gender", "community", "specialCategory", "enterpriseType",
                      "businessStage", "sector", "state", "district")

SUPPORTED_LANGUAGES = ("en", "ta")


class MssApiError(Exception):
    def __init__(self, code, message, field=None, detail=None):
        super().__init__(message)
        self.code, self.message, self.field, self.detail = code, message, field, detail

    def to_response(self):
        err = OrderedDict([("code", self.code), ("message", self.message)])
        if self.field:
            err["field"] = self.field
        if self.detail:
            err["detail"] = self.detail
        return OrderedDict([
            ("contractVersion", CONTRACT_VERSION), ("contract", "error"), ("error", err),
        ])


# HTTP status per error code, for whichever framework eventually mounts this.
HTTP_STATUS = {"INVALID_REQUEST": 400, "UNKNOWN_SCHEME": 404,
               "CATALOG_UNAVAILABLE": 503, "INTERNAL_ERROR": 500}


class MssApi:
    """Load once, serve many. Holds the resolver and search index in memory;
    construct a new instance after any catalog regeneration rather than
    mutating this one (same contract as IntelligenceResolver itself)."""

    def __init__(self):
        try:
            self.resolver = IntelligenceResolver()
            self.search_engine = HybridSearch()
        except (FileNotFoundError, KeyError) as e:
            raise MssApiError("CATALOG_UNAVAILABLE",
                              "Catalog files could not be loaded.", detail=str(e))

        self.schemes = {r["identity"]["id"]: r
                        for r in self.resolver.catalogs["scheme"]["data"]}

        # Guard: our PROFILE_DIMENSIONS must match the resolver's own list.
        # If someone adds a facet to the resolver and forgets this file, fail
        # loudly at startup rather than silently ignoring the new filter.
        resolver_dims = tuple(d for d, _ in IntelligenceResolver._APPLICABILITY_FIELDS)
        if set(resolver_dims) != set(PROFILE_DIMENSIONS):
            raise MssApiError(
                "INTERNAL_ERROR",
                "Profile dimensions are out of sync with the resolver.",
                detail=f"api={sorted(PROFILE_DIMENSIONS)} resolver={sorted(resolver_dims)}")

        # Allowed profile values + per-dimension coverage, derived from the
        # live applicability matrix rather than hardcoded -- so this can never
        # drift from the data. Coverage drives the zero-coverage warning.
        self._allowed_values, self._coverage = self._derive_profile_vocabulary()

    def _derive_profile_vocabulary(self):
        allowed, coverage = {}, {}
        matrix = self.resolver.catalogs.get("applicability_matrix")
        rows = matrix["data"] if matrix else []
        for dim, getter in IntelligenceResolver._APPLICABILITY_FIELDS:
            values, schemes_with_data = set(), 0
            for rec in rows:
                vals = getter(rec["content"])
                if vals:
                    schemes_with_data += 1
                    values.update(vals)
            allowed[dim] = values
            coverage[dim] = schemes_with_data
        return allowed, coverage

    # ---- validation ------------------------------------------------------

    def _validate_profile(self, profile):
        """Returns (clean_profile, warnings). Rejects unknown keys and unknown
        values -- silently dropping either would return results the user
        believes were filtered when they were not."""
        if profile is None:
            return None, []
        if not isinstance(profile, dict):
            raise MssApiError("INVALID_REQUEST", "profile must be an object.",
                              field="profile")

        unknown_keys = sorted(set(profile) - set(PROFILE_DIMENSIONS))
        if unknown_keys:
            raise MssApiError(
                "INVALID_REQUEST", f"Unknown profile field(s): {', '.join(unknown_keys)}.",
                field=f"profile.{unknown_keys[0]}",
                detail=f"supported fields: {', '.join(sorted(PROFILE_DIMENSIONS))}")

        clean, warnings = {}, []
        for dim in PROFILE_DIMENSIONS:          # fixed order -> deterministic warnings
            value = profile.get(dim)
            if value is None:
                continue
            if not isinstance(value, str):
                raise MssApiError("INVALID_REQUEST",
                                  f"profile.{dim} must be a string.", field=f"profile.{dim}")
            allowed = self._allowed_values.get(dim, set())
            if self._coverage.get(dim, 0) == 0:
                # Dimension exists in the schema but NO scheme carries data for
                # it (true today of community/sector/district). Accepting the
                # value silently would imply a filter was applied when, under
                # the tri-state rule, it excludes nothing at all.
                warnings.append(OrderedDict([
                    ("code", "FILTER_NO_COVERAGE"), ("field", f"profile.{dim}"),
                    ("message", f"No scheme in this catalog release records a "
                                 f"'{dim}' value, so this filter neither matches nor "
                                 f"excludes anything."),
                    ("hint", "SC/ST/women/disability eligibility is recorded under "
                              "'specialCategory'." if dim == "community" else None),
                ]))
                clean[dim] = value
                continue
            if value not in allowed:
                raise MssApiError(
                    "INVALID_REQUEST", f"Unknown value for profile.{dim}.",
                    field=f"profile.{dim}",
                    detail=f"got '{value}'; expected one of: {', '.join(sorted(allowed))}")
            clean[dim] = value
        return (clean or None), warnings

    def _validate_search_request(self, request):
        if not isinstance(request, dict):
            raise MssApiError("INVALID_REQUEST", "Request must be an object.")
        query = request.get("query")
        if not isinstance(query, str) or not query.strip():
            raise MssApiError("INVALID_REQUEST",
                              "query is required and must be a non-empty string.",
                              field="query")
        if len(query) > MAX_QUERY_LEN:
            raise MssApiError("INVALID_REQUEST",
                              f"query exceeds {MAX_QUERY_LEN} characters.", field="query",
                              detail=f"got {len(query)}")
        top_n = request.get("topN", DEFAULT_TOP_N)
        if not isinstance(top_n, int) or isinstance(top_n, bool) or not (1 <= top_n <= MAX_TOP_N):
            raise MssApiError("INVALID_REQUEST",
                              f"topN must be an integer between 1 and {MAX_TOP_N}.",
                              field="topN", detail=f"got {top_n!r}")
        language = request.get("language", "en")
        if language not in SUPPORTED_LANGUAGES:
            raise MssApiError("INVALID_REQUEST", "Unsupported language.", field="language",
                              detail=f"got '{language}'; expected one of: "
                                     f"{', '.join(SUPPORTED_LANGUAGES)}")
        profile, warnings = self._validate_profile(request.get("profile"))
        return query.strip(), top_n, language, profile, warnings

    # ---- derived fields --------------------------------------------------

    def _confidence(self, scheme_id):
        """Surfaced VERBATIM from verification.*, never computed. Blending
        search score into a confidence number would manufacture a figure with
        no grounding in any source, and would let a strong keyword match
        visually launder a poorly-verified scheme. Relevance and
        trustworthiness are different axes and stay separate."""
        rec = self.schemes.get(scheme_id)
        if not rec:
            return None
        v = rec["verification"]
        return OrderedDict([
            ("level", v.get("confidence")),
            ("verificationStatus", v.get("status")),
            ("schemeStatus", rec["identity"].get("status")),
            ("missingFieldCount", len(v.get("missingFields", []))),
            ("basis", "catalog verification.confidence, surfaced verbatim; "
                       "not blended with search score"),
        ])

    # ---- resolver enrichment (approved Phase-4 decision 1) ---------------

    def _finance_assistance(self, scheme_id):
        """Finance products linked to this scheme, via the ONE resolver.

        Field coverage is deliberately NOT smoothed over: `conditions` is
        empty on all 115 finance records and `disbursement.mode` on all 115,
        so both surface as empty/null rather than being back-filled from
        something adjacent. `mode` maps to applicationRoute (31/115), which
        is a real field, and is null when absent."""
        out = []
        for f in self.resolver.resolve(scheme_id)["finance"]:
            c = f["record"]["content"]
            amount = c.get("amount") or {}
            out.append(OrderedDict([
                ("financeId", f["id"]),
                ("type", c.get("productType")),
                ("typeText", c.get("productFamilyText")),
                ("isRepayable", c.get("isRepayable")),
                ("isGuarantee", c.get("isGuarantee")),
                ("amount", OrderedDict([
                    ("currency", amount.get("currency")),
                    ("percentage", amount.get("percentage")),
                    ("percentageText", amount.get("percentageText")),
                    ("maxInr", amount.get("maxInr")),
                    ("maxText", amount.get("maxText")),
                    ("minInr", amount.get("minInr")),
                    ("minText", amount.get("minText")),
                ])),
                # applicationRoute, NOT disbursement.mode (0/115 populated).
                ("mode", c.get("applicationRoute")),
                ("applicationUrl", c.get("applicationUrl")),
                # 0/115 populated today -- shipped as [] so the shape is
                # stable, never implying a condition exists.
                ("conditions", list(c.get("conditions") or [])),
                ("collateralStatus", (c.get("collateral") or {}).get("status")),
                ("providers", [p.get("entityId") for p in (c.get("providers") or [])]),
                ("description", c.get("description")),
            ]))
        return out

    def _authority_refs(self, scheme_id):
        """Administering/implementing bodies, via the ONE resolver. Includes
        institutions (SIDBI, NSIC, …) alongside government authorities, tagged
        by entityType so the app can distinguish them."""
        resolved = self.resolver.resolve(scheme_id)
        out = []
        for kind in ("authority", "institution"):
            for a in resolved[kind]:
                idn = a["record"]["identity"]
                out.append(OrderedDict([
                    ("entityId", a["id"]), ("entityType", kind),
                    ("name", idn.get("name")), ("shortName", idn.get("shortName")),
                    ("relationType", a["relationType"]),
                ]))
        return out

    def _enrich_citations(self, scheme_id, match_citations):
        """Adds sourceName + sourceTier from EXISTING provenance only, and
        appends the scheme's own official sources.

        Two distinct provenance origins, kept distinguishable rather than
        merged:
          * match-derived  -- provenance.fieldSources[] (why THIS result
            matched, e.g. a collateral-free determination). Carries a real
            sourceTier (5 = live official fetch, 2 = structured from held text).
          * scheme sources -- content.sources[], the scheme's own cited
            documents. Tier falls back to provenance.defaultSourceTier (2).
        """
        rec = self.schemes.get(scheme_id)
        if not rec:
            return list(match_citations)

        # Index every fieldSource in the release by (url, sourceId) so a
        # match-derived citation can recover its tier and type.
        tier_index = {}
        for cat in self.resolver.catalogs.values():
            if not cat:
                continue
            for entity in cat["data"]:
                eid = entity["identity"]["id"]
                for fs in entity["provenance"].get("fieldSources", []) or []:
                    tier_index[(eid, fs.get("url"))] = fs

        out = []
        for c in match_citations:
            fs = tier_index.get((c.get("sourceId"), c.get("url")))
            out.append(OrderedDict([
                ("sourceName", (fs or {}).get("sourceType")),
                ("organization", c.get("organization")),
                ("url", c.get("url")),
                ("retrievedDate", c.get("retrievedAt")),
                ("sourceTier", (fs or {}).get("sourceTier")),
                ("sourceId", c.get("sourceId")),
                ("externalSource", c.get("externalSource", False)),
                ("origin", "match_evidence"),
            ]))

        default_tier = rec["provenance"].get("defaultSourceTier")
        for src in rec["content"].get("sources", []):
            if not src.get("url"):
                continue
            out.append(OrderedDict([
                ("sourceName", src.get("title")),
                ("organization", src.get("publisherText")),
                ("url", src.get("url")),
                ("retrievedDate", src.get("accessedOn")),
                ("sourceTier", default_tier),
                ("sourceId", src.get("sourceId")),
                ("externalSource", True),   # a real published document URL
                ("origin", "scheme_source"),
                ("isPrimary", bool(src.get("isPrimary"))),
            ]))
        return out

    def _next_actions(self, scheme_id):
        """Gated on data that actually exists. Never emits an application
        action for a scheme recorded as closed."""
        rec = self.schemes.get(scheme_id)
        if not rec:
            return []
        content, identity = rec["content"], rec["identity"]
        scheme_status = identity.get("status")
        actions = []

        if scheme_status == "closed":
            # 12 schemes. Directing a user to apply to a closed scheme is the
            # most damaging error this layer could make -- suppress every
            # application-type action and say why.
            actions.append(OrderedDict([
                ("action", "scheme_closed"),
                ("label", "This scheme is recorded as closed -- do not apply"),
                ("url", None), ("available", False),
                ("note", "identity.status == 'closed' in the catalog."),
            ]))
        else:
            online_url = content["applicationProcess"].get("onlineUrl")
            if online_url:
                actions.append(OrderedDict([
                    ("action", "apply_online"),
                    ("label", "Apply on the official portal"),
                    ("url", online_url), ("available", True),
                ]))
            if content.get("requiredDocuments"):
                actions.append(OrderedDict([
                    ("action", "prepare_documents"),
                    ("label", f"Prepare {len(content['requiredDocuments'])} required document(s)"),
                    ("url", None), ("available", True),
                ]))

        primary = None
        for src in content.get("sources", []):
            if src.get("url") and (src.get("isPrimary") or primary is None):
                primary = src["url"]
                if src.get("isPrimary"):
                    break
        if primary:
            actions.append(OrderedDict([
                ("action", "view_official_source"), ("label", "Read the official source"),
                ("url", primary), ("available", True),
            ]))

        resolved = self.resolver.resolve(scheme_id)
        contacts = resolved["authority"] + resolved["institution"]
        if contacts:
            names = ", ".join(c["record"]["identity"]["name"] for c in contacts[:2])
            actions.append(OrderedDict([
                ("action", "contact_authority"), ("label", f"Contact: {names}"),
                ("url", None), ("available", True),
                ("entityIds", [c["id"] for c in contacts]),
            ]))

        if scheme_status == "unknown":
            # 112 schemes. Never badge as active, never hide -- flag it.
            for a in actions:
                a["statusUnconfirmed"] = True
        return actions

    # ---- operations ------------------------------------------------------

    def search(self, request):
        try:
            query, top_n, language, profile, warnings = self._validate_search_request(request)
        except MssApiError as e:
            return e.to_response()

        base = app_response.build_search_response(self.search_engine, query, top_n=top_n)

        # Components come from ONE extra search call, not one per result --
        # app_response drops `components` when it reshapes, and re-running the
        # engine per result would be O(n) full searches for the same query.
        raw = self.search_engine.search(query, top_n=top_n)
        components_by_scheme = {r["schemeId"]: r["components"] for r in raw["results"]}

        applicability_by_scheme = {}
        if profile:
            for m in self.resolver.match_applicability(profile):
                applicability_by_scheme[m["schemeId"]] = m

        results = []
        for r in base["results"]:
            sid = r["schemeId"]
            enriched = OrderedDict([
                ("rank", r["rank"]), ("schemeId", sid), ("name", r["name"]),
                ("score", r["score"]),
                ("rankingSignals", OrderedDict([
                    ("components", components_by_scheme.get(sid)),
                    ("weights", dict(WEIGHTS)),
                ])),
                ("matchReasons", r["matchReasons"]),
                ("explanation", r["explanation"]),
                ("citations", self._enrich_citations(sid, r["sources"])),
                ("confidence", self._confidence(sid)),
                ("assistance", self._finance_assistance(sid)),
                ("authority", self._authority_refs(sid)),
                ("applicability", applicability_by_scheme.get(sid) if profile else None),
                ("nextActions", self._next_actions(sid)),
            ])
            results.append(enriched)

        detected = base["query"]["detectedTags"]
        return OrderedDict([
            ("contractVersion", CONTRACT_VERSION), ("contract", "search_response"),
            ("generatedAt", base["generatedAt"]), ("catalogVersion", base["catalogVersion"]),
            ("deterministic", True),
            ("query", OrderedDict([("text", query), ("language", language),
                                    ("detectedIntent", detected)])),
            ("profileApplied", profile),
            ("warnings", warnings),
            ("resultCount", len(results)), ("results", results),
        ])

    def applicability(self, request):
        try:
            if not isinstance(request, dict):
                raise MssApiError("INVALID_REQUEST", "Request must be an object.")
            profile, warnings = self._validate_profile(request.get("profile"))
            if profile is None:
                raise MssApiError("INVALID_REQUEST",
                                  "profile is required and must contain at least one field.",
                                  field="profile",
                                  detail=f"supported fields: {', '.join(sorted(PROFILE_DIMENSIONS))}")
            only_eligible = bool(request.get("onlyEligible", False))
            limit = request.get("limit")
            if limit is not None and (not isinstance(limit, int) or isinstance(limit, bool) or limit < 1):
                raise MssApiError("INVALID_REQUEST", "limit must be a positive integer.",
                                  field="limit", detail=f"got {limit!r}")
        except MssApiError as e:
            return e.to_response()

        base = app_response.build_applicability_response(
            self.resolver, profile, only_eligible=only_eligible, limit=limit)
        for r in base["results"]:
            r["confidence"] = self._confidence(r["schemeId"])
        base["warnings"] = warnings
        return base

    def scheme_detail(self, request):
        try:
            if not isinstance(request, dict):
                raise MssApiError("INVALID_REQUEST", "Request must be an object.")
            scheme_id = request.get("schemeId")
            if not isinstance(scheme_id, str) or not scheme_id:
                raise MssApiError("INVALID_REQUEST",
                                  "schemeId is required and must be a string.",
                                  field="schemeId")
            if scheme_id not in self.schemes:
                raise MssApiError("UNKNOWN_SCHEME", f"No scheme with id '{scheme_id}'.",
                                  field="schemeId")
        except MssApiError as e:
            return e.to_response()

        base = app_response.build_scheme_intelligence_response(self.resolver, scheme_id)
        rec = self.schemes[scheme_id]
        base["name"] = rec["identity"]["name"]
        base["schemeStatus"] = rec["identity"]["status"]
        base["confidence"] = self._confidence(scheme_id)
        base["nextActions"] = self._next_actions(scheme_id)
        return base

    def meta(self):
        """Small, cheap, and the only call the app needs to make online in the
        recommended offline-first architecture (plan §4)."""
        scheme_meta = self.resolver.catalogs["scheme"]["metadata"]
        counts = OrderedDict()
        for etype in sorted(self.resolver.catalogs):
            cat = self.resolver.catalogs[etype]
            if cat:
                counts[etype] = cat["metadata"]["recordCount"]
        return OrderedDict([
            ("contractVersion", CONTRACT_VERSION), ("contract", "meta"),
            ("generatedAt", app_response._now()),
            ("catalogVersion", scheme_meta["catalogVersion"]),
            ("catalogChecksum", scheme_meta["checksum"]),
            ("schemaVersion", scheme_meta["schemaVersion"]),
            ("entityCounts", counts),
            ("supportedLanguages", list(SUPPORTED_LANGUAGES)),
            ("profileDimensions", OrderedDict(
                (d, OrderedDict([("schemesWithData", self._coverage.get(d, 0)),
                                  ("allowedValues", sorted(self._allowed_values.get(d, [])))]))
                for d in PROFILE_DIMENSIONS)),
            ("deterministic", True),
            ("rankingWeights", dict(WEIGHTS)),
        ])


if __name__ == "__main__":
    api = MssApi()
    demo_query = " ".join(sys.argv[1:]) or "I need a loan for my textile business"

    print("=" * 70, "\nMETA\n", "=" * 70, sep="")
    m = api.meta()
    print(f"catalogVersion : {m['catalogVersion'][:60]}…")
    print(f"entityCounts   : {dict(m['entityCounts'])}")
    print("profileDimensions coverage:")
    for d, info in m["profileDimensions"].items():
        print(f"   {d:16} schemesWithData={info['schemesWithData']:3}  "
              f"values={info['allowedValues']}")

    print("\n" + "=" * 70, f"\nSEARCH: {demo_query!r}\n", "=" * 70, sep="")
    resp = api.search({"query": demo_query, "topN": 3})
    print(f"detectedIntent : {resp['query']['detectedIntent']}")
    for r in resp["results"]:
        print(f"\n  #{r['rank']} {r['schemeId']}  score={r['score']}  {r['name'][:52]}")
        print(f"     confidence : {r['confidence']['level']} "
              f"(verification={r['confidence']['verificationStatus']}, "
              f"status={r['confidence']['schemeStatus']})")
        print(f"     explanation: {r['explanation'][:110]}…")
        for a in r["nextActions"]:
            flag = " [status unconfirmed]" if a.get("statusUnconfirmed") else ""
            print(f"     action     : {a['action']:22} available={a['available']}{flag}")

    print("\n" + "=" * 70, "\nERROR HANDLING\n", "=" * 70, sep="")
    for bad in [{}, {"query": "x", "topN": 999}, {"query": "x", "profile": {"gendre": "female"}},
                {"query": "x", "profile": {"enterpriseType": "huge"}}]:
        e = api.search(bad)
        print(f"   {str(bad)[:48]:50} -> {e['error']['code']}: {e['error']['message'][:44]}")

    print("\n" + "=" * 70, "\nZERO-COVERAGE FILTER WARNING\n", "=" * 70, sep="")
    w = api.search({"query": "loan", "profile": {"community": "sc"}, "topN": 1})
    for warn in w["warnings"]:
        print(f"   {warn['code']}: {warn['message']}")
        if warn.get("hint"):
            print(f"   hint -> {warn['hint']}")
