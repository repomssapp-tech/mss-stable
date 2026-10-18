#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
msme_privilege_catalog.json -- Phase 1 Step 3, catalog 2 of 4.

Per MSME_GRAPH_SCHEMA.md §2: privileges MSMEs RECEIVE, not obligations
they must meet (that's csr_catalog.json, deliberately not this).

Only content actually confirmed against a live approved-domain source this
session (samadhaan.msme.gov.in, fetched twice, batches 4/5/7 of Stage B and
again for this catalog) is populated with numbers. tenderBenefits and
billDiscounting are left honestly not_specified -- a GeM homepage fetch
this session found MSMEs referenced but no specific reservation percentage
or figure to cite (see fieldSources note on that record).
"""
import json, os, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
AT = "2026-08-14T00:00:00Z"
REL = "1.0.0"

def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

RECORD = OrderedDict([
    ("privilegeType", "delayed_payment_protection"),
    ("privilegeTypeText", "Delayed Payment Protection (MSME Samadhaan)"),
    ("statute", "MSMED Act 2006, Sections 15-24"),
    ("summary", "Buyers must pay MSE suppliers within 45 days of acceptance of goods/services; "
                "failing which compound interest applies at three times the RBI-notified bank "
                "rate, with monthly rests. Sections 20-21 authorise State Governments to "
                "establish Micro and Small Enterprise Facilitation Councils for dispute "
                "settlement."),
    ("tenderBenefits", OrderedDict([
        ("applicable", None), ("emdExemption", None), ("priceParity", None),
        ("reservedProcurementPercent", None), ("text", None),
    ])),
    ("delayedPaymentProtection", OrderedDict([
        ("applicable", True), ("maxPaymentDays", 45),
        ("interestBasis", "3x RBI-notified bank rate, compounded monthly"),
        ("grievanceForum", "MSME Samadhaan (Delayed Payment Monitoring System) / "
                           "Micro and Small Enterprise Facilitation Councils"),
        ("grievanceUrl", "https://samadhaan.msme.gov.in/"),
        ("newApplicationsUrl", "https://odr.msme.gov.in/"),
        ("statsAsOf", "2026-08-14"),
        ("applicationsFiled", 256892),
        ("amountPayableInr", 316256800000), ("amountPayableText", "₹31,625.68 crore"),
        ("casesDisposed", 65232),
        ("amountDisposedInr", 102914400000), ("amountDisposedText", "₹10,291.44 crore"),
    ])),
    ("billDiscounting", OrderedDict([
        ("applicable", None), ("platformIds", []), ("text", None),
    ])),
    ("compliance", OrderedDict([("benefits", []), ("text", None)])),
])

MISSING = [
    {"field": "content.tenderBenefits",
     "reason": "Public Procurement Policy for MSEs (Order 2012) is well-documented public "
               "policy, but no numeric reservation/EMD-exemption figure was found on any "
               "approved-domain source fetched this session (checked gem.gov.in -- MSMEs "
               "referenced but no percentage/figure present on the fetched page). Left null "
               "rather than filled from unverified prior knowledge."},
    {"field": "content.billDiscounting",
     "reason": "TReDS/bill-discounting mechanics are covered in treds_catalog.json; no "
               "MSME-privilege-specific numeric claim (e.g. discount rate, eligibility "
               "threshold) was independently verified this session to structure here."},
]


def build_record():
    rid = "PRIV000001"
    return OrderedDict([
        ("identity", OrderedDict([
            ("id", rid), ("entityType", "msme_privilege"), ("code", "DPP001"),
            ("legacyCodes", []), ("name", "Delayed Payment Protection (MSME Samadhaan)"),
            ("shortName", "MSME Samadhaan"), ("acronym", None),
            ("slug", "delayed-payment-protection"), ("language", "en"), ("status", "active"),
        ])),
        ("content", RECORD),
        ("relationships", OrderedDict([("references", [])])),
        ("localization", OrderedDict([("en", OrderedDict([
            ("name", "Delayed Payment Protection (MSME Samadhaan)"),
            ("summary", RECORD["summary"]),
        ]))])),
        ("search", OrderedDict([
            ("keywords", OrderedDict([
                ("en", ["delayed payment", "samadhaan", "45 days", "facilitation council",
                        "msmed act", "interest"]),
                ("ta", []),
            ])),
            ("synonyms", ["MSME Samadhaan", "delayed payment monitoring system"]),
            ("aliases", OrderedDict([("en", ["MSME Samadhaan"]), ("ta", [])])),
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
            ("isVerified", True), ("verifiedAgainst", ["samadhaan.msme.gov.in"]),
            ("verifiedBy", None), ("verifiedAt", AT), ("confidence", "high"),
            ("researchStatus", "Official-source researched"),
            ("notes", "delayedPaymentProtection fully sourced; tenderBenefits and "
                      "billDiscounting deliberately left unpopulated -- see missingFields."),
            ("missingFields", MISSING), ("disputedFields", []), ("reviewDueOn", None),
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
            ("pipelineVersion", "build_msme_privilege.py-1.0.0"),
            ("fieldSources", [{
                "field": "content.delayedPaymentProtection", "sourceTier": 5,
                "sourceType": "official_website", "url": "https://samadhaan.msme.gov.in/",
                "organization": "Ministry of MSME (MSME Samadhaan portal)",
                "retrievedAt": "2026-08-14", "isBackfill": False, "supersededValue": None,
                "note": "45-day rule, 3x bank rate interest formula, MSMED Act §15-24/20-21, "
                        "and live case statistics all read directly from the portal.",
            }]),
            ("transformationNotes", []), ("translations", OrderedDict()),
        ])),
    ])


def main():
    records = [build_record()]
    out = OrderedDict([
        ("metadata", OrderedDict([
            ("catalogName", "msme_privilege"), ("schemaVersion", "1.0.0"),
            ("catalogVersion", REL), ("generatedAt", AT), ("language", "en"),
            ("recordCount", len(records)),
            ("checksum", "sha256:" + hashlib.sha256(canon(records).encode()).hexdigest()),
        ])),
        ("data", records),
    ])
    json.dump(out, open(os.path.join(CAT, "msme_privilege_catalog.json"), "w",
                         encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"msme_privilege_catalog.json written: {len(records)} record(s)")


if __name__ == "__main__":
    main()
