#!/usr/bin/env python3
"""
App Consumption Layer -- Phase 2.

Packages hybrid_search.py / intelligence_resolver.py's internal working
shapes into a stable, versioned contract. The internal shapes (HybridSearch
.search()'s raw dict, IntelligenceResolver.resolve()/match_applicability())
are allowed to keep changing as scoring/resolution logic evolves; this
module is the one seam the app depends on, so an internal refactor doesn't
break the app as long as this module's own CONTRACT_VERSION-tagged shape
stays stable (or is bumped deliberately, per SEARCH_INTEGRATION_CONTRACT.md
§4's rule: "the weights are configuration to revisit... treat the weights
as configuration, not the contract").

Nothing in this module invents data: every field is copied or reshaped from
hybrid_search.py / intelligence_resolver.py output, same discipline as the
Scheme Search Profile (PHASE1_INTELLIGENCE_ARCHITECTURE.md Part 2: "derived,
must be regenerable, never hand-edited").
"""
import json, os
from datetime import datetime, timezone
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
CONTRACT_VERSION = "1.0.0"


def _now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _catalog_version():
    d = json.load(open(os.path.join(CAT, "scheme_catalog.json"), encoding="utf-8"))
    return d["metadata"]["catalogVersion"]


def _sources_for(reasons):
    """Dedup citations across a result's reasons into one traceability list,
    machine-consumable independent of the prose `explanation` string."""
    seen, out = set(), []
    for r in reasons:
        c = r.get("citation")
        if not c:
            continue
        key = (c.get("organization"), c.get("url"), c.get("sourceId"))
        if key in seen:
            continue
        seen.add(key)
        out.append(OrderedDict([
            ("organization", c.get("organization")),
            ("url", c.get("url")),
            ("sourceId", c.get("sourceId")),
            ("retrievedAt", c.get("retrievedAt")),
            ("externalSource", bool(c.get("organization") or c.get("url"))),
        ]))
    return out


def build_search_response(hybrid_search, query, top_n=10):
    """Final app-facing search response. Wraps HybridSearch.search()."""
    raw = hybrid_search.search(query, top_n=top_n)

    results = []
    for rank, r in enumerate(raw["results"], start=1):
        results.append(OrderedDict([
            ("rank", rank),
            ("schemeId", r["schemeId"]),
            ("name", r["name"]),
            ("score", r["score"]),
            ("matchReasons", [OrderedDict([("dimension", x["dimension"]), ("detail", x["detail"])])
                               for x in r["reasons"]]),
            ("explanation", r["explanation"]),
            ("sources", _sources_for(r["reasons"])),
        ]))

    return OrderedDict([
        ("contractVersion", CONTRACT_VERSION),
        ("contract", "search_response"),
        ("generatedAt", _now()),
        ("catalogVersion", _catalog_version()),
        ("deterministic", True),
        ("query", OrderedDict([("text", raw["query"]), ("detectedTags", raw["detectedTags"])])),
        ("resultCount", len(results)),
        ("results", results),
    ])


def build_applicability_response(resolver, profile, only_eligible=False, limit=None):
    """Final app-facing applicability-match response. Wraps
    IntelligenceResolver.match_applicability()."""
    raw = resolver.match_applicability(profile)
    if only_eligible:
        raw = [r for r in raw if r["eligible"]]
    if limit:
        raw = raw[:limit]

    scheme_names = {r["identity"]["id"]: r["identity"]["name"]
                     for r in resolver.catalogs["scheme"]["data"]}

    results = []
    for rank, r in enumerate(raw, start=1):
        results.append(OrderedDict([
            ("rank", rank),
            ("schemeId", r["schemeId"]),
            ("name", scheme_names.get(r["schemeId"])),
            ("eligible", r["eligible"]),
            ("matchedFacets", r["matchedFacets"]),
            ("neutralFacets", r["neutralFacets"]),
            ("excludedBy", r["excludedBy"]),
        ]))

    return OrderedDict([
        ("contractVersion", CONTRACT_VERSION),
        ("contract", "applicability_response"),
        ("generatedAt", _now()),
        ("catalogVersion", _catalog_version()),
        ("deterministic", True),
        ("profile", profile),
        ("resultCount", len(results)),
        ("results", results),
    ])


def build_scheme_intelligence_response(resolver, scheme_id):
    """Final app-facing 'everything about one scheme' response -- wraps
    IntelligenceResolver.resolve(), reshaped into stable field names and
    with full records replaced by (id, name) summaries, since the app
    fetches full records from its own catalog bundle, not through this
    response (avoids duplicating ~13MB of catalog data into every call)."""
    resolved = resolver.resolve(scheme_id)

    def summarize(items):
        out = []
        for x in items:
            idn = x["record"]["identity"]
            out.append(OrderedDict([("id", x["id"]), ("name", idn.get("name")),
                                     ("relationType", x["relationType"])]))
        return out

    am = resolved["applicability"]
    return OrderedDict([
        ("contractVersion", CONTRACT_VERSION),
        ("contract", "scheme_intelligence_response"),
        ("generatedAt", _now()),
        ("catalogVersion", _catalog_version()),
        ("schemeId", scheme_id),
        ("finance", summarize(resolved["finance"])),
        ("tax", summarize(resolved["tax"])),
        ("treds", summarize(resolved["treds"])),
        ("csr", summarize(resolved["csr"])),
        ("authority", summarize(resolved["authority"])),
        ("institution", summarize(resolved["institution"])),
        ("export", summarize(resolved["export"])),
        ("cluster", summarize(resolved["cluster"])),
        ("privileges", summarize(resolved["privileges"])),
        ("enablement", summarize(resolved["enablement"])),
        ("knowledge", summarize(resolved["knowledge"])),
        ("applicability", am["content"] if am else None),
        ("dataIntegrity", OrderedDict([
            ("missingReferences", resolved["missingReferences"]),
        ])),
    ])


if __name__ == "__main__":
    import sys
    from hybrid_search import HybridSearch
    from intelligence_resolver import IntelligenceResolver

    hs = HybridSearch()
    resolver = IntelligenceResolver()

    query = " ".join(sys.argv[1:]) or "women entrepreneur loan"
    resp = build_search_response(hs, query, top_n=3)
    print(json.dumps(resp, indent=2, ensure_ascii=False))

    print("\n---\n")
    prof_resp = build_applicability_response(
        resolver, {"gender": "female", "enterpriseType": "micro", "state": "IN-TN"}, limit=3)
    print(json.dumps(prof_resp, indent=2, ensure_ascii=False))

    print("\n---\n")
    detail_resp = build_scheme_intelligence_response(resolver, "SCH000001")
    print(json.dumps(detail_resp, indent=2, ensure_ascii=False))
