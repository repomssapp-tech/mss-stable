#!/usr/bin/env python3
"""Phase D2 — Cluster Intelligence: add verified textile-sector cluster
financial-assistance records.

Both records are Tier-5, fetched live 2026-08-15 from
tntextilesschemes.tn.gov.in (Group A, .gov.in) -- the Tamil Nadu
Department of Textiles' dedicated scheme portal, distinct from the general
TN MSME capital subsidy circular already represented in finance_catalog.json.

Leather/auto/agro/printing were searched this round (see
CLUSTER_COVERAGE_REPORT.md) but no comparable sector-specific cluster
scheme was found and independently confirmed by direct page fetch -- the
only leather/auto figures surfaced by search were later found, on direct
fetch, to be the SAME general 24-thrust-sector TN capital subsidy already
in the catalog (25% / max Rs 150 lakh), not a distinct cluster program.
Per policy, a WebSearch summary that is not independently confirmed by
fetching the actual page is not accepted as a source -- so nothing was
added for those sectors this round.
"""
import json, hashlib
from copy import deepcopy

PATH = "cluster_assistance_catalog.json"
RETRIEVED_AT = "2026-08-15"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)

TEMPLATE = catalog["data"][0]


def make_record(rid, code, name, sector, sector_text, max_amount_inr,
                 max_amount_text, pct, conditions, url, summary, keywords):
    rec = deepcopy(TEMPLATE)
    rec["identity"] = {
        "id": rid, "entityType": "cluster_assistance", "code": code,
        "legacyCodes": [], "name": name, "shortName": None, "acronym": None,
        "slug": code.lower().replace("_", "-"), "language": "en", "status": "active",
    }
    rec["content"] = {
        "clusterName": name,
        "sector": sector,
        "sectorText": sector_text,
        "districts": [],
        "supportedBusinessTypes": [],
        "financialSupport": {
            "applicable": True,
            "assistanceType": "capital_subsidy",
            "maxAmountInr": max_amount_inr,
            "maxAmountText": max_amount_text,
            "percentage": pct,
            "conditions": conditions,
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
    rec["localization"] = {"en": {"name": name, "summary": summary}}
    rec["search"] = {
        "keywords": {"en": keywords, "ta": []},
        "synonyms": [], "aliases": {"en": [], "ta": []},
        "crossReferences": [], "searchRank": None, "boostTerms": [],
    }
    rec["ai"] = deepcopy(TEMPLATE["ai"])
    rec["verification"] = {
        "status": "partially_verified",
        "statusText": "Financial support confirmed on official source; districts/administering authority not itemised",
        "isVerified": True,
        "verifiedAgainst": [url],
        "verifiedBy": None,
        "verifiedAt": RETRIEVED_AT,
        "confidence": "high",
        "researchStatus": "Official-source researched",
        "notes": f"Fetched directly from {url} (Tier 5, approved domain tn.gov.in). Figures quoted verbatim.",
        "missingFields": [
            {"field": "content.districts", "reason": "Not itemised on the fetched page."},
            {"field": "content.administeringAuthorityId", "reason": "No institution_catalog.json entry resolved for the TN Department of Textiles this round; not linked rather than guessed."},
        ],
        "disputedFields": [],
        "reviewDueOn": None,
    }
    rec["analytics"] = deepcopy(TEMPLATE["analytics"])
    rec["metadata"] = {
        "createdAt": RETRIEVED_AT + "T00:00:00Z",
        "updatedAt": RETRIEVED_AT + "T00:00:00Z",
        "catalogVersion": "1.0.0",
        "schemaVersion": "1.0.0",
        "recordStatus": "published",
        "revision": 1,
    }
    rec["provenance"] = {
        "defaultSourceTier": 5,
        "primarySourceId": None,
        "contributingSourceIds": [],
        "extractionMethod": "live_official_source",
        "extractedAt": RETRIEVED_AT,
        "pipelineVersion": "add_cluster_d2.py-1.0.0",
        "fieldSources": [
            {
                "field": "content.financialSupport",
                "sourceTier": 5,
                "sourceType": "official_website",
                "url": url,
                "organization": "Department of Textiles, Government of Tamil Nadu",
                "retrievedAt": RETRIEVED_AT,
                "isBackfill": False,
                "supersededValue": None,
                "note": summary,
            }
        ],
        "transformationNotes": [],
        "translations": {},
    }
    return rec


cut_sew = make_record(
    rid="CLUS000003",
    code="TN_TEXTILE_CUT_SEW_SCHEME",
    name="Cut & Sew Scheme (Tamil Nadu Textiles)",
    sector="textile",
    sector_text="Garmenting, Home Textiles and Technical Textile sectors",
    max_amount_inr=5000000,
    max_amount_text="Rs 50 lakh per machine",
    pct=50.0,
    conditions=[
        "For brand new computerized cutting machine with CAD/CAM software only.",
        "Eligible applicants: Common Facility Centres (partnership of 2+ units, registered as an SPV) or individual primary units with MOUs with 3+ peripheral manufacturing units and minimum 25% machinery capacity allocated to peripheral units.",
        "Subsidy released in 3 instalments: 60% / 20% / 20%.",
    ],
    url="https://tntextilesschemes.tn.gov.in/cut_sew_landing",
    summary=(
        "50% capital subsidy for brand new computerized cutting machines with "
        "CAD/CAM software in Garmenting, Home Textiles and Technical Textile "
        "sectors; maximum ceiling Rs 50 lakh per machine; released in 60/20/20 "
        "instalments. Verbatim from tntextilesschemes.tn.gov.in/cut_sew_landing."
    ),
    keywords=["cut", "sew", "textile", "garmenting", "cluster", "cad", "cam", "cutting", "machine"],
)

fibre_yarn = make_record(
    rid="CLUS000004",
    code="TN_TEXTILE_NONCONVENTIONAL_FIBRE_YARN",
    name="Non-Conventional Fibre/Yarn Manufacturing Capital Investment Subsidy (Tamil Nadu Textiles)",
    sector="textile",
    sector_text="Non-conventional fibre and yarn manufacturing (new factories/spinning mills)",
    max_amount_inr=10000000,
    max_amount_text="Rs 1.00 crore per unit",
    pct=25.0,
    conditions=[
        "Applies to new factories/spinning mills engaged in non-conventional fibre and yarn manufacturing.",
        "Disbursed in two phases: 60% after installation and commencement of production, 40% after one year of operation.",
    ],
    url="https://tntextilesschemes.tn.gov.in/fibre",
    summary=(
        "25% capital investment subsidy on eligible plant and machinery cost "
        "for new non-conventional fibre/yarn manufacturing factories and "
        "spinning mills; maximum ceiling Rs 1.00 crore per unit; disbursed "
        "60% on commencement, 40% after one year. Verbatim from "
        "tntextilesschemes.tn.gov.in/fibre."
    ),
    keywords=["fibre", "yarn", "textile", "spinning", "cluster", "non-conventional", "manufacturing"],
)

catalog["data"].extend([cut_sew, fibre_yarn])
catalog["metadata"]["recordCount"] = len(catalog["data"])


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("recordCount now:", catalog["metadata"]["recordCount"])
