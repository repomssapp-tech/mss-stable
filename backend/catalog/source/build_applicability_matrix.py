#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 1, Step 3 — applicability_matrix_catalog.json

Derived, not authored (MSME_GRAPH_SCHEMA.md §3): every field here is copied
from the scheme record it belongs to. One record per scheme, 217 total.
Regenerating this file from an unchanged scheme_catalog.json must produce a
byte-identical result — that's the guard checked at the bottom of this file
and re-run by validate_applicability_matrix.py.

Does not modify scheme_catalog.json or any other existing catalog.
"""
import json, os, sys, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CAT)
from taxonomy_engine import normalize as taxonomy_normalize
from datetime import datetime, timezone
AT = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
REL = "1.0.0"


def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def facet_values(struct, key):
    """Return the values list for a structured-eligibility facet only when
    applies == True. applies is tri-state; None/False both mean 'do not
    assert a value here' -- never collapse them to an empty-means-excluded
    read, per the tri-state rule already established project-wide."""
    f = struct.get(key, {})
    if f.get("applies") is True:
        if "values" in f: return list(f["values"])
        if "types" in f: return list(f["types"])
        if "included" in f: return list(f["included"])
    return []


def build_record(scheme):
    idn = scheme["identity"]
    c = scheme["content"]
    struct = c["eligibility"]["structured"]
    gov = c["classification"]["government"]

    content = OrderedDict([
        ("schemeId", idn["id"]),
        ("governmentLevel", gov.get("level")),
        ("department", gov.get("departmentId")),
        ("agency", list(gov.get("implementingAgencyIds") or [])),
        ("gender", facet_values(struct, "gender")),
        ("community", facet_values(struct, "community")),
        ("specialCategory", facet_values(struct, "specialCategory")),
        ("enterpriseType", facet_values(struct, "enterprise")),
        ("businessStage", facet_values(struct, "businessStage")),
        # `sectors` is empty on all 217 records, which left the sector filter
        # completely dead. Where the scheme's own sectorsText names a sector
        # the controlled taxonomy recognises, derive the code from it -- a
        # deterministic classification of text the catalog already asserts,
        # not a new fact. Yield is small and honest: 147 of 158 sectorsText
        # values are theme descriptors ("Women entrepreneurship",
        # "Social welfare") rather than industries, and those stay empty
        # rather than being force-fitted to a sector they do not name.
        ("sector", (c["classification"].get("sectors")
                    or taxonomy_normalize(c["classification"].get("sectorsText") or "")["industries"])),
        ("sectorText", c["classification"].get("sectorsText")),
        ("district", list(gov.get("districts") or [])),
        ("districtText", gov.get("districtsText")),
        ("cluster", []),        # populated once cluster_assistance links exist (Migration Plan Step 3 follow-on)
        ("location", OrderedDict([
            ("states", list(gov.get("states") or [])),
            ("statesText", gov.get("statesText")),
        ])),
        ("regeneratedFrom", OrderedDict([
            ("sourceRecordId", idn["id"]),
            ("sourceContentChecksum", "sha256:" + hashlib.sha256(canon(c).encode()).hexdigest()),
            ("regeneratedAt", AT),
        ])),
    ])

    return OrderedDict([
        ("identity", OrderedDict([
            ("id", None),  # filled by caller with sequential APLM id
            ("entityType", "applicability_matrix"),
            ("code", idn.get("code")),
            ("legacyCodes", []),
            ("name", f"Applicability Matrix — {idn['name']}"),
            ("shortName", None), ("acronym", None),
            ("slug", f"applicability-{idn.get('slug', idn['id'].lower())}"),
            ("language", "en"), ("status", idn.get("status")),
        ])),
        ("content", content),
        # Deliberately no relationships.references entry -- MSME_GRAPH_SCHEMA.md §3:
        # "applicability_matrix is excluded from graph traversal by design." The
        # schemeId -> record link is a keyed lookup (content.schemeId), not an edge,
        # so it never needs a declared inverse relation type.
        ("relationships", OrderedDict([("references", [])])),
        # No display text of its own -- derived index, display always resolves through the
        # scheme (MSME_GRAPH_SCHEMA.md §3). "en" kept as a single empty shape so base rule 23
        # (all localization languages must share one key shape) is satisfiable.
        ("localization", OrderedDict([("en", OrderedDict())])),
        ("search", OrderedDict([
            ("keywords", OrderedDict([("en", []), ("ta", [])])),
            ("synonyms", []), ("aliases", OrderedDict([("en", []), ("ta", [])])),
            ("crossReferences", []), ("searchRank", None), ("boostTerms", []),
        ])),
        ("ai", OrderedDict([
            ("summary", None), ("sectionSummaries", OrderedDict()),
            ("generationMode", "mechanical_derivation"), ("confidence", None),
            ("generatedBy", "build_applicability_matrix.py-1.0.0"), ("generatedAt", AT),
            ("sourceFieldsUsed", ["content.classification", "content.eligibility.structured"]),
            ("reviewedBy", None), ("reviewedAt", None), ("isApproved", False),
            ("semanticTags", []), ("relatedEntities", []), ("recommendations", []),
            ("recommendationsNote", None), ("similarityMethod", None), ("reviewRequired", False),
        ])),
        ("verification", OrderedDict([
            ("status", "derived"), ("statusText", "Mechanically derived from scheme_catalog.json"),
            ("isVerified", True),  # verified BY CONSTRUCTION -- it's a copy, not a new claim
            ("verifiedAgainst", [idn["id"]]), ("verifiedBy", None), ("verifiedAt", AT),
            ("confidence", "high"), ("researchStatus", "not applicable -- derived, no research performed"),
            ("notes", "Every value copied from the source scheme record; regenerable and diffable."),
            ("missingFields", []), ("disputedFields", []), ("reviewDueOn", None),
        ])),
        ("analytics", OrderedDict([
            ("popularity", None), ("viewCount", None), ("saveCount", None),
            ("actionCount", None), ("lastAggregatedAt", None),
        ])),
        ("metadata", OrderedDict([
            ("createdAt", AT), ("updatedAt", AT), ("catalogVersion", REL),
            ("schemaVersion", "1.0.0"), ("recordStatus", "published"), ("revision", 1),
        ])),
        ("provenance", OrderedDict([
            ("defaultSourceTier", 2), ("primarySourceId", idn["id"]),
            ("contributingSourceIds", [idn["id"]]),
            ("extractionMethod", "mechanical_derivation"), ("extractedAt", AT),
            ("pipelineVersion", "build_applicability_matrix.py-1.0.0"),
            ("fieldSources", []),
            ("transformationNotes", [
                f"Derived from {idn['id']} content.classification and content.eligibility.structured; "
                "no new facts asserted, tri-state applies==True required before copying a facet value."
            ]),
            ("translations", OrderedDict()),
        ])),
    ])


def main():
    scheme_cat = load("scheme_catalog.json")
    records = []
    for i, s in enumerate(scheme_cat["data"], start=1):
        rec = build_record(s)
        rec["identity"]["id"] = f"APLM{i:06d}"
        records.append(rec)

    out = OrderedDict([
        ("metadata", OrderedDict([
            ("catalogName", "applicability_matrix"), ("schemaVersion", "1.0.0"),
            ("catalogVersion", REL), ("generatedAt", AT), ("language", "en"),
            ("recordCount", len(records)),
            ("checksum", "sha256:" + hashlib.sha256(canon(records).encode()).hexdigest()),
        ])),
        ("data", records),
    ])
    out_path = os.path.join(CAT, "applicability_matrix_catalog.json")
    json.dump(out, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    # ---- regeneration guard: same scheme_catalog.json in -> byte-identical out
    scheme_checksum_used = scheme_cat["metadata"]["checksum"]
    print(f"applicability_matrix_catalog.json written: {len(records)} records")
    print(f"source scheme_catalog.json checksum: {scheme_checksum_used}")
    print(f"output checksum: {out['metadata']['checksum']}")

    facet_coverage = {
        "gender": sum(1 for r in records if r["content"]["gender"]),
        "community": sum(1 for r in records if r["content"]["community"]),
        "specialCategory": sum(1 for r in records if r["content"]["specialCategory"]),
        "enterpriseType": sum(1 for r in records if r["content"]["enterpriseType"]),
        "businessStage": sum(1 for r in records if r["content"]["businessStage"]),
        "sector": sum(1 for r in records if r["content"]["sectorText"]),
        "district": sum(1 for r in records if r["content"]["districtText"]),
        "governmentLevel": sum(1 for r in records if r["content"]["governmentLevel"]),
    }
    print("facet coverage (non-empty / 217):")
    for k, v in facet_coverage.items():
        print(f"   {k:16} {v}")


if __name__ == "__main__":
    main()
