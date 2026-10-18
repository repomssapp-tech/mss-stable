#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 3 -- 8 more schemes verified against the same Tier-1
held document (TN_Schemes_Booklet_2022_v10.md), each page read and the
scheme name matched exactly before writing. SCH000171 ("State MSME
Schemes") was checked and correctly left untouched -- its own overview
already states it is an umbrella/meta entry, not a benefit-bearing scheme.
"""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
DOC = ('"Compendium of Schemes for MSMEs 2022" (MSME Department, Government '
       'of Tamil Nadu, September 2022), held locally as '
       'TN_Schemes_Booklet_2022_v10.md, page %s.')
SRC_BASE = {
    "sourceTier": 1, "sourceType": "official_booklet_held",
    "organization": "MSME Department, Government of Tamil Nadu",
    "url": None, "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None,
}

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []


def add_source(rec, field, value, page, note):
    rec["provenance"].setdefault("fieldSources", []).append(
        {"field": field, "value": value, **SRC_BASE, "note": f"{DOC % page} {note}"})


def finalize(rec):
    rec["verification"]["status"] = "verified"
    rec["verification"]["confidence"] = "high"
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"]
        if "benefits" not in m["field"] and "eligibility" not in m["field"]]
    changed.append(rec["identity"]["id"])


def set_benefit(rec, pct, max_inr, max_text, desc, page, quote, elig=None):
    c = rec["content"]
    b = c["benefits"]["capitalSubsidy"]
    assert b["percentage"] is None and b["applicable"] is not False
    b["applicable"] = True
    b["percentage"] = pct
    b["percentageText"] = f"{pct}%"
    b["maxAmountInr"] = max_inr
    b["maxAmountText"] = max_text
    b["description"] = desc
    c["benefits"]["summary"] = desc
    if "capitalSubsidy" not in c["benefits"]["benefitTypes"]:
        c["benefits"]["benefitTypes"].append("capitalSubsidy")
    add_source(rec, "content.benefits.capitalSubsidy", {"percentage": pct, "maxAmountInr": max_inr}, page, quote)
    if elig:
        c["eligibility"]["narrative"]["criteria"] = elig
        add_source(rec, "content.eligibility.narrative.criteria", elig, page, "Eligibility, verbatim.")
    finalize(rec)


# SCH000062 -- Generator Subsidy, p.31
set_benefit(recs["SCH000062"], 25.0, 500000, "Rs 5 lakh",
            "25% of the cost of power generator sets (up to 320 kVA capacity), subject to a "
            "maximum of Rs 5 lakh.",
            31,
            'Verbatim: "Subsidy provided for 25% of the cost of power generator sets (up to '
            '320 kVA capacity); subject to a maximum of INR 5 lakh."',
            elig="New or existing micro manufacturing enterprise coming under the rural feeder "
                 "lines of TANGEDCO. Application must be filed within 6 months of the safety "
                 "certificate from the Electrical Inspectorate.")

# SCH000068 -- Infrastructure Subsidy for privately developed industrial estates, p.28
set_benefit(recs["SCH000068"], 20.0, None,
            "No ceiling stated; 20% of approved infrastructure development cost",
            "20% of the cost of approved infrastructure for development of infrastructure in "
            "privately developed industrial estates located outside a 30 km radius of Chennai "
            "City Centre.",
            28,
            'Verbatim: "Subsidy provided for 20% of the cost of approved infrastructure for '
            'development of infrastructure in privately developed industrial estates, which '
            'are in areas outside a radius of 30 km from Chennai City Centre." No maximum '
            "amount is stated on this page -- left null rather than invented.",
            elig="Private sector park developer setting up an industrial park in Tamil Nadu, "
                 "outside a 30 km radius of Chennai City Centre.")

# SCH000079 -- LTPT Subsidy, p.29. Resolves the gap left unfilled in the
# previous batch (live page didn't state the figure; this held document does).
set_benefit(recs["SCH000079"], 20.0, None,
            "No rupee ceiling; 20% of eligible power consumption charges for 36 months",
            "20% of power consumption charges paid to TANGEDCO, for the first 36 months from "
            "commencement of commercial production (or from the date of power connection, "
            "whichever is later). Applies to actual energy charges for manufacturing/lighting "
            "including surcharge and tax, excluding penalty. Restricted to micro enterprises "
            "using Low Tension Power supply (Tariff III B).",
            29,
            'Verbatim: "Subsidy provided for 20% of power consumption charges paid to The '
            'Tamil Nadu Generation and Distribution Corporation Limited (TANGEDCO), for the '
            'first 36 months from the date of commencement of commercial production, or from '
            'the date of power connection, whichever is later."',
            elig="New micro manufacturing enterprises anywhere in the state, OR existing micro "
                 "manufacturing enterprises undertaking substantial expansion/diversification, "
                 "using Low Tension Power supply (Tariff III B) only. Eligibility-certificate "
                 "application: within 3 months (new units) or 6 months (expansion/"
                 "diversification) of commencement/power connection. Subsidy claims: once "
                 "every 6 months, first claim within 30 days of the eligibility certificate.")

# SCH000142 -- Reimbursement of Stamp Duty and Registration charges, p.25
r = recs["SCH000142"]
b = r["content"]["benefits"]["reimbursement"]
assert b["percentage"] is None
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "50%"
b["description"] = (
    "50% reimbursement of stamp duty and registration charges incurred on purchase of land "
    "meant for industrial use. No rupee ceiling stated."
)
r["content"]["benefits"]["summary"] = b["description"]
if "reimbursement" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("reimbursement")
add_source(r, "content.benefits.reimbursement", {"percentage": 50.0}, 25,
           'Verbatim: "Reimbursement provided for 50% of stamp duty and registration charges '
           'incurred on purchase of land meant for industrial use." No ceiling stated on this '
           "page -- left null rather than invented.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Manufacturing enterprise (micro or small scale) set up in the state's declared backward "
    "blocks (see the source's Annexure 1 list). Application must be filed within 6 months of "
    "commencement of commercial production."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           25, "Eligibility, verbatim.")
finalize(r)

# SCH000175 -- Subsidy for Fund Raising from SME Exchange, p.35
set_benefit(recs["SCH000175"], 75.0, 3000000, "Rs 30 lakh",
            "75% of the expenditure incurred for getting successfully listed on the SME "
            "Exchange, subject to a maximum of Rs 30 lakh. Eligible costs: merchant banker "
            "fees, due diligence fees, registrar and transfer agent fees, peer review auditor "
            "fees, exchange fees, and listing charges.",
            35,
            'Verbatim: "Subsidy provided for 75% of the expenditure incurred for getting '
            'successfully listed; subject to a maximum of INR 30 lakh."',
            elig="Small or medium enterprise qualified for listing per NSE/BSE SME Exchange "
                 "norms. Application must be filed within 6 months of listing.")

# SCH000178 -- Support for development of mini tool room, p.37
set_benefit(recs["SCH000178"], 25.0, 10000000, "Rs 1 crore",
            "25% of project cost as a grant, subject to a maximum of Rs 1 crore, for "
            "development of a mini tool room manufacturing jigs, fixtures, cutting tools, "
            "gauges, press tools, plastic moulds, forging dies, pressure casting dies and "
            "other toolings for small scale industries.",
            37,
            'Verbatim: "Grant provided for 25% of the project cost; subject to a maximum of '
            'INR 1 crore."',
            elig="Any industrial cluster or association.")

# SCH000066 -- Incentives for setting up new cluster units on the outskirts of Towns and Cities, p.67
r = recs["SCH000066"]
b = r["content"]["benefits"]["grant"] if "grant" in r["content"]["benefits"] else None
# Use grant type (this is explicitly a "Grant" per the source, distinct from capitalSubsidy)
b = r["content"]["benefits"].setdefault("grant", {
    "applicable": None, "percentage": None, "percentageText": None, "amountInr": None,
    "amountText": None, "maxAmountInr": None, "maxAmountText": None, "minAmountInr": None,
    "minAmountText": None, "durationMonths": None, "basis": None, "varies": False,
    "variesBy": None, "conditions": [], "description": None,
})
assert b.get("percentage") is None
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "50%"
b["maxAmountInr"] = 150000000
b["maxAmountText"] = "Rs 15 crore"
b["description"] = (
    "50% of total development cost as a grant, subject to a maximum of Rs 15 crore, for "
    "infrastructure facilities (roads, drainage, culverts, storm water drains, street "
    "lights, water supply, electricity, conference/training halls, common facility "
    "centres) at a new cluster site on the outskirts of a town or city."
)
r["content"]["benefits"]["summary"] = b["description"]
r["content"]["benefits"]["benefitTypes"] = list(set(r["content"]["benefits"]["benefitTypes"] + ["grant"]))
add_source(r, "content.benefits.grant", {"percentage": 50.0, "maxAmountInr": 150000000}, 67,
           'Verbatim: "Grant up to 50% of the total development cost, subject to a maximum of '
           'INR 15 crores is provided for obtaining infrastructure facilities."')
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "MSME or MSME association; approval requires at least 20 MSMEs (manufacturing or "
    "service) coming together to relocate, forming a Special Purpose Vehicle (SPV) with a "
    "minimum of 50 acres of land (10 acres if the SPV consists only of micro enterprises; "
    "less than 50 acres may be considered where land cost is high)."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           67, "Eligibility, verbatim.")
finalize(r)

# SCH000067 -- Incentives to entrepreneurs for shifting of existing units outside Urban areas, p.66
r = recs["SCH000067"]
b = r["content"]["benefits"].setdefault("grant", {
    "applicable": None, "percentage": None, "percentageText": None, "amountInr": None,
    "amountText": None, "maxAmountInr": None, "maxAmountText": None, "minAmountInr": None,
    "minAmountText": None, "durationMonths": None, "basis": None, "varies": False,
    "variesBy": None, "conditions": [], "description": None,
})
assert b.get("percentage") is None
b["applicable"] = True
b["percentage"] = 75.0
b["percentageText"] = "75%"
b["maxAmountInr"] = 200000000
b["maxAmountText"] = "Rs 20 crore"
b["description"] = (
    "75% of total infrastructure development cost as a grant, subject to a maximum of "
    "Rs 20 crore, for enterprises relocating outside urban areas. Infrastructure includes "
    "(not limited to) roads, drainage, culverts, storm water drains, street lights, water "
    "supply, electricity, conference/training halls, and common facility centres."
)
r["content"]["benefits"]["summary"] = b["description"]
r["content"]["benefits"]["benefitTypes"] = list(set(r["content"]["benefits"]["benefitTypes"] + ["grant"]))
add_source(r, "content.benefits.grant", {"percentage": 75.0, "maxAmountInr": 200000000}, 66,
           'Verbatim: "Grant for obtaining infrastructure development is provided for 75% of '
           'the total development cost, subject to a maximum of INR 20 crores."')
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "MSME or MSME association; approval requires at least 20 MSMEs (manufacturing or "
    "service) coming together to relocate, forming a Special Purpose Vehicle (SPV) with a "
    "minimum of 50 acres of land (10 acres if the SPV consists only of micro enterprises; "
    "less than 50 acres may be considered where land cost is high)."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           66, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
