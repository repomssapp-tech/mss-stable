#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
business_enablement_catalog.json -- Phase 1 Step 3, catalog 3 of 4.

Four records, each anchored to a portal already independently confirmed
official during this session's Stage B Pass 1 fetches or this round's
own fetches -- no new unverified claim, each citing the specific fetch.
"""
import json, os, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
AT = "2026-08-14T00:00:00Z"
REL = "1.0.0"

def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

RECORDS = [
    dict(code="registration_support", name="Udyam Registration (MSME Self-Registration)",
         enablementType="registration_support",
         summary="Free, paperless, self-declaration-based MSME registration. Aadhaar number "
                 "required initially; PAN and GSTIN retrieved automatically from government "
                 "databases (mandatory since 1 April 2021). No fee is charged at any stage.",
         url="https://udyamregistration.gov.in/", org="Ministry of MSME (NIC-hosted)",
         note="Confirmed official portal; page states \"no other private online or offline "
              "system, service, agency or person is authorized... to do MSME Registration.\""),
    dict(code="cluster_single_window", name="MSME Cluster Development Programme",
         enablementType="single_window_support",
         summary="Application and support channel for Common Facility Centres and "
                 "Infrastructure Development initiatives under the Cluster Development "
                 "Programme framework.",
         url="https://cluster.dcmsme.gov.in/", org="DCMSME (Ministry of MSME)",
         note="Confirmed official portal (batch-4 Stage B Pass 1 fetch); warns of fake sites, "
              "directs Udyam registration queries to the correct official domain."),
    dict(code="grievance_compliance", name="CHAMPIONS Portal",
         enablementType="compliance_support",
         summary="\"Our Small Hands to make you LARGE\" -- platform for resolution, redressal "
                 "and remedies for MSMEs, plus guidance and scheme information dissemination. "
                 "Control rooms across states, nodal officer directories.",
         url="https://champions.gov.in/", org="Ministry of MSME (NIC-hosted)",
         note="Confirmed official portal (batch-6 Stage B Pass 1 fetch)."),
    dict(code="startup_recognition", name="Startup India / DPIIT Recognition",
         enablementType="startup_support",
         summary="DPIIT recognition, BHASKAR startup registry, Seed Fund Scheme, National "
                 "Startup Awards, and mentorship (MAARG) for the startup ecosystem.",
         url="https://www.startupindia.gov.in/", org="DPIIT, Ministry of Commerce and Industry",
         note="Confirmed official portal (batches 3/4/5/7 Stage B Pass 1 fetches)."),
]


def build_record(i, r):
    rid = f"ENAB{i:06d}"
    content = OrderedDict([
        ("enablementType", r["enablementType"]),
        ("enablementTypeText", r["name"]),
        ("summary", r["summary"]),
        ("providerAuthorityId", None),
        ("servicesOffered", []),
        ("onlineUrl", r["url"]),
        ("eligibility", OrderedDict([("enterpriseTypeIds", []), ("text", None)])),
    ])
    return OrderedDict([
        ("identity", OrderedDict([
            ("id", rid), ("entityType", "business_enablement"), ("code", r["code"].upper()),
            ("legacyCodes", []), ("name", r["name"]), ("shortName", None), ("acronym", None),
            ("slug", r["code"].replace("_", "-")), ("language", "en"), ("status", "active"),
        ])),
        ("content", content),
        ("relationships", OrderedDict([("references", [])])),
        ("localization", OrderedDict([("en", OrderedDict([
            ("name", r["name"]), ("summary", r["summary"]),
        ]))])),
        ("search", OrderedDict([
            ("keywords", OrderedDict([("en", [r["enablementType"], r["code"]]), ("ta", [])])),
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
            ("status", "verified"), ("statusText", "Confirmed against live official source"),
            ("isVerified", True), ("verifiedAgainst", [r["url"]]), ("verifiedBy", None),
            ("verifiedAt", AT), ("confidence", "high"),
            ("researchStatus", "Official-source researched"), ("notes", r["note"]),
            ("missingFields", [
                {"field": "content.servicesOffered", "reason": "Detailed service list not "
                 "itemised on the fetched homepage/landing page; would need a deeper "
                 "per-service page fetch not performed this session."},
                {"field": "content.providerAuthorityId", "reason": "Would require resolving "
                 "against authority_catalog.json by name match, not attempted this pass."},
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
            ("pipelineVersion", "build_business_enablement.py-1.0.0"),
            ("fieldSources", [{
                "field": "content", "sourceTier": 5, "sourceType": "official_website",
                "url": r["url"], "organization": r["org"], "retrievedAt": "2026-08-14",
                "isBackfill": False, "supersededValue": None, "note": r["note"],
            }]),
            ("transformationNotes", []), ("translations", OrderedDict()),
        ])),
    ])


def main():
    records = [build_record(i, r) for i, r in enumerate(RECORDS, start=1)]
    out = OrderedDict([
        ("metadata", OrderedDict([
            ("catalogName", "business_enablement"), ("schemaVersion", "1.0.0"),
            ("catalogVersion", REL), ("generatedAt", AT), ("language", "en"),
            ("recordCount", len(records)),
            ("checksum", "sha256:" + hashlib.sha256(canon(records).encode()).hexdigest()),
        ])),
        ("data", records),
    ])
    json.dump(out, open(os.path.join(CAT, "business_enablement_catalog.json"), "w",
                         encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"business_enablement_catalog.json written: {len(records)} records")


if __name__ == "__main__":
    main()
