#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
enterprise_classification_catalog.json -- Phase 1 Step 3, catalog 1 of 4.

A controlled taxonomy (MSME_GRAPH_SCHEMA.md §1), not a per-scheme record.
Every numeric threshold below was fetched live from an approved-domain
official source this session (2026-08-14) -- not carried over from
training-data memory, which would risk citing a superseded threshold (the
MSME investment/turnover limits changed 1 April 2025; the startup turnover
threshold changed again 4 February 2026, mid-session). Where a fact could
not be freshly verified (e.g. the startup incorporation-age limit), the
field is left null with a missingFields entry -- never filled from memory.
"""
import json, os, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
AT = "2026-08-14T00:00:00Z"
REL = "1.0.0"

def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

RECORDS = [
    # ---- MSME size categories -- source: udyamregistration.gov.in, table read live
    # 2026-08-14, corroborated by dcmsme.gov.in citing Notification S.O. 1364(E),
    # dated 21.03.2025, effective 01.04.2025.
    dict(code="micro", name="Micro Enterprise", dim="msmeCategory",
         investmentMaxInr=25000000, investmentMaxText="₹2.5 crore",
         turnoverMaxInr=100000000, turnoverMaxText="₹10 crore",
         source="udyamregistration.gov.in (live table, 2026-08-14); corroborated by "
                "dcmsme.gov.in citing Notification S.O. 1364(E) dated 21.03.2025",
         sourceUrl="https://udyamregistration.gov.in/UdyamRegistration.aspx",
         effectiveFrom="2025-04-01"),
    dict(code="small", name="Small Enterprise", dim="msmeCategory",
         investmentMaxInr=250000000, investmentMaxText="₹25 crore",
         turnoverMaxInr=1000000000, turnoverMaxText="₹100 crore",
         source="udyamregistration.gov.in (live table, 2026-08-14); corroborated by "
                "dcmsme.gov.in citing Notification S.O. 1364(E) dated 21.03.2025",
         sourceUrl="https://udyamregistration.gov.in/UdyamRegistration.aspx",
         effectiveFrom="2025-04-01"),
    dict(code="medium", name="Medium Enterprise", dim="msmeCategory",
         investmentMaxInr=1250000000, investmentMaxText="₹125 crore",
         turnoverMaxInr=5000000000, turnoverMaxText="₹500 crore",
         source="udyamregistration.gov.in (live table, 2026-08-14); corroborated by "
                "dcmsme.gov.in citing Notification S.O. 1364(E) dated 21.03.2025",
         sourceUrl="https://udyamregistration.gov.in/UdyamRegistration.aspx",
         effectiveFrom="2025-04-01"),
    # ---- Business category -- descriptive, not a numeric threshold; no source
    # needed beyond the term itself being an MSME-sector-standard grouping already
    # used throughout scheme_catalog.json's own classification.sectorsText values.
    dict(code="manufacturing", name="Manufacturing", dim="businessCategory"),
    dict(code="service", name="Service", dim="businessCategory"),
    dict(code="trading", name="Trading", dim="businessCategory"),
    dict(code="exporter", name="Exporter", dim="businessCategory"),
    # ---- Special category -- vocabulary matched to values actually observed in
    # scheme_catalog.json's eligibility.structured.specialCategory (see
    # taxonomy_engine.py's COMMUNITIES table, built from the same source).
    dict(code="women_entrepreneur", name="Women Entrepreneur", dim="specialCategory"),
    dict(code="sc_st_entrepreneur", name="SC/ST Entrepreneur", dim="specialCategory"),
    dict(code="differently_abled_entrepreneur", name="Differently-Abled Entrepreneur", dim="specialCategory"),
    # ---- Startup -- source: startupindia.gov.in, live 2026-08-14. Only the
    # turnover threshold was found on the fetched page; the incorporation-age
    # limit was NOT independently re-confirmed this session (the page referred
    # to a separate "Check Eligibility" page/PDF not fetched) -- left null.
    dict(code="startup", name="Startup (DPIIT)", dim="businessStage",
         turnoverMaxInr=2000000000, turnoverMaxText="₹200 crore",
         source="startupindia.gov.in (live, 2026-08-14), citing DPIIT Gazette "
                "Notification 108(E) dated 4 February 2026",
         sourceUrl="https://www.startupindia.gov.in/",
         effectiveFrom="2026-02-04",
         missingNote="Incorporation-age limit not independently verified this "
                     "session; the fetched page referenced a separate eligibility "
                     "page/PDF that was not fetched. Left null rather than filled "
                     "from unverified prior knowledge."),
]


def build_record(i, r):
    code, name, dim = r["code"], r["name"], r["dim"]
    rid = f"ENTC{i:06d}"
    content = OrderedDict([
        ("code", code), ("dimension", dim),
        ("investmentMaxInr", r.get("investmentMaxInr")),
        ("investmentMaxText", r.get("investmentMaxText")),
        ("turnoverMaxInr", r.get("turnoverMaxInr")),
        ("turnoverMaxText", r.get("turnoverMaxText")),
        ("effectiveFrom", r.get("effectiveFrom")),
        ("definitionSource", r.get("source")),
    ])
    missing = []
    if r.get("missingNote"):
        missing.append({"field": "content.incorporationAgeMaxYears", "reason": r["missingNote"]})

    return OrderedDict([
        ("identity", OrderedDict([
            ("id", rid), ("entityType", "enterprise_classification"), ("code", code.upper()),
            ("legacyCodes", []), ("name", name), ("shortName", None), ("acronym", None),
            ("slug", code.replace("_", "-")), ("language", "en"), ("status", "active"),
        ])),
        ("content", content),
        ("relationships", OrderedDict([("references", [])])),
        ("localization", OrderedDict([("en", OrderedDict([("name", name)]))])),
        ("search", OrderedDict([
            ("keywords", OrderedDict([("en", [code, dim]), ("ta", [])])),
            ("synonyms", []), ("aliases", OrderedDict([("en", []), ("ta", [])])),
            ("crossReferences", []), ("searchRank", None), ("boostTerms", []),
        ])),
        ("ai", OrderedDict([
            ("summary", None), ("sectionSummaries", OrderedDict()),
            ("generationMode", None), ("confidence", None), ("generatedBy", None),
            ("generatedAt", None), ("sourceFieldsUsed", []), ("reviewedBy", None),
            ("reviewedAt", None), ("isApproved", False), ("semanticTags", []),
            ("relatedEntities", []), ("recommendations", []), ("recommendationsNote", None),
            ("similarityMethod", None), ("reviewRequired", False),
        ])),
        ("verification", OrderedDict([
            ("status", "verified" if r.get("source") else "unverified"),
            ("statusText", "Confirmed against a live official source this session"
                            if r.get("source") else "Descriptive category term; no numeric claim to verify"),
            ("isVerified", bool(r.get("source"))),
            ("verifiedAgainst", [r["source"]] if r.get("source") else []),
            ("verifiedBy", None), ("verifiedAt", AT if r.get("source") else None),
            ("confidence", "high" if r.get("source") else None),
            ("researchStatus", "Official-source researched" if r.get("source") else "not applicable"),
            ("notes", None), ("missingFields", missing), ("disputedFields", []), ("reviewDueOn", None),
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
            ("defaultSourceTier", 5 if r.get("source") else 3),
            ("primarySourceId", None), ("contributingSourceIds", []),
            ("extractionMethod", "live_official_source" if r.get("source") else "controlled_vocabulary"),
            ("extractedAt", AT), ("pipelineVersion", "build_enterprise_classification.py-1.0.0"),
            ("fieldSources", [{
                "field": "content", "sourceTier": 5, "sourceType": "official_website",
                "url": r["sourceUrl"], "organization": r["source"], "retrievedAt": "2026-08-14",
                "isBackfill": False, "supersededValue": None,
                "note": f"Live official threshold, not from training-data memory: {r['source']}",
            }] if r.get("source") else []),
            ("transformationNotes", []), ("translations", OrderedDict()),
        ])),
    ])


def main():
    records = [build_record(i, r) for i, r in enumerate(RECORDS, start=1)]
    out = OrderedDict([
        ("metadata", OrderedDict([
            ("catalogName", "enterprise_classification"), ("schemaVersion", "1.0.0"),
            ("catalogVersion", REL), ("generatedAt", AT), ("language", "en"),
            ("recordCount", len(records)),
            ("checksum", "sha256:" + hashlib.sha256(canon(records).encode()).hexdigest()),
        ])),
        ("data", records),
    ])
    json.dump(out, open(os.path.join(CAT, "enterprise_classification_catalog.json"), "w",
                         encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"enterprise_classification_catalog.json written: {len(records)} records")
    for r in records:
        print(f"   {r['identity']['id']}  {r['identity']['name']}  verified={r['verification']['isVerified']}")


if __name__ == "__main__":
    main()
