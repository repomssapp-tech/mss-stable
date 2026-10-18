#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cluster_assistance_catalog.json -- Phase 1 Step 3, catalog 4 of 4.

Honest scope limitation, stated up front: no sector-specific Tamil Nadu
cluster (Textile/Auto/Leather/Printing) financial-assistance figures were
found on any approved-domain source fetched this session. cluster.dcmsme.gov.in
was checked specifically for this and confirmed to show no cluster names or
funding figures on its overview page (only application procedure). Rather
than invent Textile/Auto/Leather cluster percentages from general knowledge,
this catalog ships with the two clusters/programmes that ARE genuinely
sourced this session, and the sector-specific TN clusters are logged as an
open gap in REMAINING_DATA_COVERAGE_GAPS.md, not fabricated here.

Per MSME_GRAPH_SCHEMA.md §4's structural rule: financialSupport and
nonFinancialSupport are always separate sub-objects with independent
`applicable` flags, so a non-financial item can never collapse into
`amount: 0`.
"""
import json, os, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
AT = "2026-08-14T00:00:00Z"
REL = "1.0.0"

def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

RECORDS = [
    dict(
        code="cluster_development_programme", name="MSME Cluster Development Programme",
        sector="general", sectorText="General MSME clusters (multi-sector)",
        districts=[],
        nonFinApplicable=True,
        nonFinTypes=["common_facility_center", "infrastructure_development"],
        nonFinText="Application and support channel for Common Facility Centres (CFC) and "
                   "Infrastructure Development (ID) for MSME clusters nationally.",
        finApplicable=None, finText=None,
        url="https://cluster.dcmsme.gov.in/", org="DCMSME (Ministry of MSME)",
        note="Confirmed official portal. Explicitly checked for named clusters (textile/auto/"
             "leather) and financial figures -- none present on the fetched overview page; "
             "only CFC/ID category names and an application procedure are shown.",
    ),
    dict(
        code="sipcot_industrial_parks", name="SIPCOT Industrial Parks (Tamil Nadu)",
        sector="general", sectorText="General industrial infrastructure, multi-sector tenancy",
        districts=[],
        nonFinApplicable=True,
        nonFinTypes=["industrial_park", "plot_allotment"],
        nonFinText="50 industrial parks including 8 SEZs across Tamil Nadu; plot allotment "
                   "and grievance redressal for tenant enterprises. Established 1971. Major "
                   "tenants referenced on-site include Bosch, Apollo Tyres, Reliance Retail.",
        finApplicable=None, finText=None,
        url="https://sipcotweb.tn.gov.in/", org="SIPCOT (State Industries Promotion "
                                                 "Corporation of Tamil Nadu)",
        note="Confirmed official homepage (batch-6/8 Stage B Pass 1 fetches). Note: SIPCOT "
             "manages general industrial parks, not sector-named clusters in the "
             "Textile/Auto/Leather sense -- classified honestly as 'general', not assigned "
             "to a specific sector without evidence.",
    ),
]

MISSING_CATALOG_LEVEL = [
    {"field": "data[*].content.clusterName (sector-specific)",
     "reason": "No Tamil Nadu Textile, Auto, Leather, or Printing cluster with a specific "
               "name, district list, or financial-assistance figure was found on any "
               "approved-domain source fetched this session. cluster.dcmsme.gov.in was "
               "checked specifically and confirmed to show no cluster names/figures. "
               "Left entirely unbuilt rather than invented -- see REMAINING_DATA_COVERAGE_GAPS.md."},
]


def build_record(i, r):
    rid = f"CLUS{i:06d}"
    content = OrderedDict([
        ("clusterName", r["name"]),
        ("sector", r["sector"]), ("sectorText", r["sectorText"]),
        ("districts", r["districts"]),
        ("supportedBusinessTypes", []),
        ("financialSupport", OrderedDict([
            ("applicable", r["finApplicable"]), ("assistanceType", None),
            ("maxAmountInr", None), ("maxAmountText", r["finText"]), ("conditions", []),
        ])),
        ("nonFinancialSupport", OrderedDict([
            ("applicable", r["nonFinApplicable"]),
            ("supportTypes", r["nonFinTypes"]),
            ("description", r["nonFinText"]),
        ])),
        ("administeringAuthorityId", None),
        ("relatedSchemeIds", []),
    ])
    return OrderedDict([
        ("identity", OrderedDict([
            ("id", rid), ("entityType", "cluster_assistance"), ("code", r["code"].upper()),
            ("legacyCodes", []), ("name", r["name"]), ("shortName", None), ("acronym", None),
            ("slug", r["code"].replace("_", "-")), ("language", "en"), ("status", "active"),
        ])),
        ("content", content),
        ("relationships", OrderedDict([("references", [])])),
        ("localization", OrderedDict([("en", OrderedDict([
            ("name", r["name"]), ("summary", r["nonFinText"]),
        ]))])),
        ("search", OrderedDict([
            ("keywords", OrderedDict([("en", [r["code"], "cluster"]), ("ta", [])])),
            ("synonyms", []), ("aliases", OrderedDict([("en", []), ("ta", [])])),
            ("crossReferences", []), ("searchRank", None), ("boostTerms", []),
        ])),
        ("ai", OrderedDict([
            ("summary", None), ("sectionSummaries", OrderedDict()), ("generationMode", None),
            ("confidence", None), ("generatedBy", None), ("generatedAt", None),
            ("sourceFieldsUsed", []), ("reviewedBy", None), ("reviewedAt", None),
            ("isApproved", False), ("semanticTags", []), ("relatedEntities", []),
            ("recommendations", []), ("recommendationsNote", None), ("similarityMethod", None),
            ("reviewRequired", False),
        ])),
        ("verification", OrderedDict([
            ("status", "partially_verified"),
            ("statusText", "Non-financial support confirmed; financial support not found on "
                            "any approved source, left null"),
            ("isVerified", True), ("verifiedAgainst", [r["url"]]), ("verifiedBy", None),
            ("verifiedAt", AT), ("confidence", "medium"),
            ("researchStatus", "Official-source researched"), ("notes", r["note"]),
            ("missingFields", [
                {"field": "content.financialSupport", "reason": "No financial-assistance "
                 "figure found on the fetched source for this record."},
                {"field": "content.districts", "reason": "Not itemised on the fetched "
                 "overview page."},
            ]),
            ("disputedFields", []), ("reviewDueOn", None),
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
            ("defaultSourceTier", 5), ("primarySourceId", None), ("contributingSourceIds", []),
            ("extractionMethod", "live_official_source"), ("extractedAt", AT),
            ("pipelineVersion", "build_cluster_assistance.py-1.0.0"),
            ("fieldSources", [{
                "field": "content.nonFinancialSupport", "sourceTier": 5,
                "sourceType": "official_website", "url": r["url"], "organization": r["org"],
                "retrievedAt": "2026-08-14", "isBackfill": False, "supersededValue": None,
                "note": r["note"],
            }]),
            ("transformationNotes", []), ("translations", OrderedDict()),
        ])),
    ])


def main():
    records = [build_record(i, r) for i, r in enumerate(RECORDS, start=1)]
    out = OrderedDict([
        ("metadata", OrderedDict([
            ("catalogName", "cluster_assistance"), ("schemaVersion", "1.0.0"),
            ("catalogVersion", REL), ("generatedAt", AT), ("language", "en"),
            ("recordCount", len(records)),
            ("checksum", "sha256:" + hashlib.sha256(canon(records).encode()).hexdigest()),
        ])),
        ("data", records),
    ])
    json.dump(out, open(os.path.join(CAT, "cluster_assistance_catalog.json"), "w",
                         encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"cluster_assistance_catalog.json written: {len(records)} records")
    print("NOTE: sector-specific TN clusters (textile/auto/leather) intentionally NOT built "
          "-- no verified source found this session. See REMAINING_DATA_COVERAGE_GAPS.md.")


if __name__ == "__main__":
    main()
