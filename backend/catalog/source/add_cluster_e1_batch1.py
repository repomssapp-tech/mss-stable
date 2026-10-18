#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.1 -- 6 verified sector-specific cluster records, covering
leather, engineering/auto-adjacent, printing, and food processing (rice
milling) -- the sectors explicitly named in this phase that Phase D2 could
not source.

Source: https://msmedi-chennai.gov.in/GARMS_Admin/ClusterTN.aspx (MSME
Development Institute, Chennai -- Ministry of MSME field office; .gov.in,
Tier 2 "official implementing agency" per this phase's source hierarchy),
fetched 2026-08-15. The page lists 50 completed/ongoing Common Facility
Centre (CFC) clusters under MSE-CDP with GoI/GoTN/SPV funding figures in
lakh. This script adds 6 representative records covering the 4 explicitly
requested sectors; the remaining ~44 are a sourced, ready-to-add backlog
for a future batch (see PHASE_E1_WEB_ENRICHMENT_REPORT.md).

IMPORTANT semantic note preserved in every record: these are AGGREGATE
CFC PROJECT GRANTS (total GoI+GoTN government contribution to build one
shared facility for a cluster of enterprises), NOT a per-enterprise
benefit amount -- described explicitly in each record's description/
conditions so a client cannot mistake it for "apply and get this amount."
"""
import json, hashlib
from copy import deepcopy

PATH = "cluster_assistance_catalog.json"
RETRIEVED_AT = "2026-08-15"
URL = "https://msmedi-chennai.gov.in/GARMS_Admin/ClusterTN.aspx"
ORG = "MSME Development Institute, Chennai (Ministry of MSME)"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
TEMPLATE = catalog["data"][0]

# (id, code, name, sector, sectorText, district, goi_lakh, gotn_lakh, facility_desc, status)
RECORDS = [
    ("CLUS000005", "TN_CLUSTER_PRINTING_SIVAKASI", "Printing Cluster CFC — Sivakasi",
     "printing", "Printing (offset)", "Sivakasi, Virudhunagar", 767.80, 90.66,
     "5-colour offset printing, cutting and plate-making facility", "completed"),
    ("CLUS000006", "TN_CLUSTER_PRINTING_KRISHNAGIRI", "Printing Cluster CFC — Krishnagiri",
     "printing", "Printing (offset, prepress)", "Krishnagiri", 936.81, 90.00,
     "Computer-to-plate, graphic designing and 4-colour offset facility", "completed"),
    ("CLUS000007", "TN_CLUSTER_ENGINEERING_HOSUR", "Engineering Cluster CFC — Hosur",
     "engineering", "Engineering (common metal processing)", "Hosur, Krishnagiri", 439.89, 70.75,
     "Common metal processing (de-coiling) facility", "completed"),
    ("CLUS000008", "TN_CLUSTER_ENGINEERING_RANIPET", "Engineering Cluster CFC — Ranipet",
     "engineering", "Engineering (general fabrication)", "Ranipet, Vellore", 616.39, 97.21,
     "Facility complementing firm-level engineering processes", "completed"),
    ("CLUS000009", "TN_CLUSTER_LEATHER_PALLAVARAM", "Leather Cluster CFC — Pallavaram",
     "leather", "Leather (design and pattern making)", "Pallavaram, Chengalpattu", 197.93, 29.69,
     "Designing, pattern making and cutting facility", "ongoing"),
    ("CLUS000010", "TN_CLUSTER_FOOD_PROCESSING_ALANGULAM", "Rice Mill Cluster CFC — Alangulam",
     "food_processing", "Food processing (rice milling)", "Alangulam, Tirunelveli", 550.25, 78.91,
     "Colour sorter and mechanized paddy pre-cleaning facility", "completed"),
]

new_records = []
for rid, code, name, sector, sector_text, district, goi, gotn, facility, status in RECORDS:
    total_lakh = goi + gotn
    total_inr = round(total_lakh * 100000)
    rec = deepcopy(TEMPLATE)
    rec["identity"] = {
        "id": rid, "entityType": "cluster_assistance", "code": code,
        "legacyCodes": [], "name": name, "shortName": None, "acronym": None,
        "slug": code.lower().replace("_", "-"), "language": "en", "status": "active",
    }
    desc = (
        f"Common Facility Centre (CFC) under the MSE Cluster Development Programme "
        f"(MSE-CDP), {'completed' if status == 'completed' else 'ongoing'}: {facility}. "
        f"THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the "
        f"cluster, not a per-enterprise benefit amount: GoI Rs {goi:.2f} lakh + GoTN "
        f"Rs {gotn:.2f} lakh = Rs {total_lakh:.2f} lakh total government grant "
        f"(SPV/cluster-unit own contribution separate, not counted as assistance)."
    )
    rec["content"] = {
        "clusterName": name,
        "sector": sector,
        "sectorText": sector_text,
        "districts": [district.split(",")[-1].strip()],
        "supportedBusinessTypes": [],
        "financialSupport": {
            "applicable": True,
            "assistanceType": "grant",
            "maxAmountInr": total_inr,
            "maxAmountText": f"Rs {total_lakh:.2f} lakh (GoI Rs {goi:.2f} lakh + GoTN Rs {gotn:.2f} lakh) -- aggregate CFC project grant, not a per-enterprise amount",
            "percentage": None,
            "conditions": [
                "Amount is the total Government of India + Government of Tamil Nadu grant "
                "for constructing one shared Common Facility Centre for this cluster, not an "
                "amount payable to an individual enterprise.",
                f"Facility: {facility}.",
            ],
        },
        "nonFinancialSupport": {
            "applicable": False,
            "supportTypes": [],
            "description": None,
        },
        "administeringAuthorityId": None,
        "relatedSchemeIds": [],
    }
    rec["relationships"] = {"references": []}
    rec["localization"] = {"en": {"name": name, "summary": desc}}
    rec["search"] = {
        "keywords": {"en": [sector, "cluster", "cfc", district.split(",")[0].lower(),
                             district.split(",")[-1].strip().lower()], "ta": []},
        "synonyms": [], "aliases": {"en": [], "ta": []},
        "crossReferences": [], "searchRank": None, "boostTerms": [],
    }
    rec["ai"] = deepcopy(TEMPLATE["ai"])
    rec["verification"] = {
        "status": "partially_verified",
        "statusText": "Financial support (aggregate CFC grant) confirmed on official source; "
                       "per-enterprise benefit not stated because this is project-level infrastructure funding",
        "isVerified": True,
        "verifiedAgainst": [URL],
        "verifiedBy": None,
        "verifiedAt": RETRIEVED_AT,
        "confidence": "high",
        "researchStatus": "Official-source researched",
        "notes": f"Fetched directly from {URL} (Tier 2, MSME-DI Chennai, .gov.in). Figures quoted verbatim from the page's cluster listing table.",
        "missingFields": [
            {"field": "content.supportedBusinessTypes", "reason": "Not itemised on the fetched source beyond the facility description."},
            {"field": "content.administeringAuthorityId", "reason": "No institution_catalog.json entry resolved for MSME-DI Chennai this round; not linked rather than guessed."},
        ],
        "disputedFields": [],
        "reviewDueOn": None,
    }
    rec["analytics"] = deepcopy(TEMPLATE["analytics"])
    rec["metadata"] = {
        "createdAt": RETRIEVED_AT + "T00:00:00Z", "updatedAt": RETRIEVED_AT + "T00:00:00Z",
        "catalogVersion": "1.0.0", "schemaVersion": "1.0.0",
        "recordStatus": "published", "revision": 1,
    }
    rec["provenance"] = {
        "defaultSourceTier": 2,
        "primarySourceId": None, "contributingSourceIds": [],
        "extractionMethod": "live_official_source", "extractedAt": RETRIEVED_AT,
        "pipelineVersion": "add_cluster_e1_batch1.py-1.0.0",
        "fieldSources": [{
            "field": "content.financialSupport", "sourceTier": 2, "sourceType": "official_website",
            "url": URL, "organization": ORG, "retrievedAt": RETRIEVED_AT,
            "isBackfill": False, "supersededValue": None, "note": desc,
        }],
        "transformationNotes": [], "translations": {},
    }
    new_records.append(rec)

catalog["data"].extend(new_records)
catalog["metadata"]["recordCount"] = len(catalog["data"])


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("recordCount now:", catalog["metadata"]["recordCount"])
