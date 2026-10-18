#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 11 -- 4 Government of India MSME schemes: SFURTI,
MSME Innovative Scheme (Incubation), ASPIRE, MSE-CDP. Each has multiple
distinct sub-components with different caps -- the largest/headline
component is stored structurally, full breakdown in conditions[], per
the "do not collapse a multi-part statement" rule.
"""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
DOC = ('"Compendium of Schemes for MSMEs 2022" (MSME Department, Government '
       'of Tamil Nadu, September 2022), held locally as '
       'TN_Schemes_Booklet_2022_v10.md, page %s.')

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []


def add_source(rec, field, value, page, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field, "value": value,
        "sourceTier": 1, "sourceType": "official_booklet_held",
        "organization": "MSME Department, Government of Tamil Nadu",
        "url": None, "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None,
        "note": f"{DOC % page} {note}",
    })


def finalize(rec):
    rec["verification"]["status"] = "verified"
    rec["verification"]["confidence"] = "high"
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"] if "benefits" not in m["field"]]
    changed.append(rec["identity"]["id"])


# SCH000144 -- SFURTI, p.127
r = recs["SCH000144"]
b = r["content"]["benefits"]["trainingSupport"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 50000000
b["maxAmountText"] = "Rs 5 crore (major cluster, 500-1000 artisans)"
b["description"] = (
    "Cluster-level financial assistance for MSE capacity building via SHGs/consortia. "
    "Major cluster (500-1000 artisans): max Rs 5 crore. Mini cluster (up to 500 artisans): "
    "max Rs 2.5 crore. NE/J&K/hill-state clusters: 50% reduction in required artisan count "
    "at the same funding ceilings. Component ceilings: soft interventions max Rs 25 lakh; "
    "hard interventions max 75% of cost; technical agency involvement max 8% of soft+hard "
    "intervention cost; implementing agency/cluster executive costs max Rs 20 lakh."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.trainingSupport", {"maxAmountInr": 50000000}, 127,
           "Full multi-component ceiling structure, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Institution with cluster-development expertise; NGO or central/state/semi-government "
    "institution; or field functionary of a state/central Panchayati Raj Institution (PRI)."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           127, "Eligibility, verbatim.")
finalize(r)

# SCH000103 -- MSME Innovative Scheme (Incubation), p.128
r = recs["SCH000103"]
b = r["content"]["benefits"]["technologySupport"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 10000000
b["maxAmountText"] = "Rs 1 crore (host institute plant/machinery procurement); Rs 15 lakh/idea (development & nurturing)"
b["description"] = (
    "Financial support to host institutes/business incubation centres (recognised research "
    "institutions/universities) for developing and nurturing innovator ideas: max Rs 15 "
    "lakh/idea. Separately, max Rs 1 crore to the host institute for procuring and "
    "installing relevant plant/machines (hardware and software)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.technologySupport", {"maxAmountInr": 10000000}, 128,
           "Two-tier funding structure (per-idea vs. host-institute equipment), verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = "Existing or prospective entrepreneur."
add_source(r, "content.eligibility.narrative.criteria", "Existing or prospective entrepreneur.",
           128, "Eligibility, verbatim.")
finalize(r)

# SCH000150 -- ASPIRE, p.129
r = recs["SCH000150"]
b = r["content"]["benefits"]["grant"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 10000000
b["maxAmountText"] = "Rs 1 crore (government agencies, plant/machinery); Rs 75 lakh (private agencies); + Rs 1 crore operational grant"
b["description"] = (
    "Financial assistance for procuring plant/machinery for Livelihood Business Incubators "
    "(LBIs): max Rs 1 crore to government agencies, max Rs 75 lakh to private agencies. "
    "Separately, a max Rs 1 crore operational grant (manpower, running incubation/skill-"
    "development programmes) to government and private agencies."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", {"maxAmountInr": 10000000}, 129,
           "Government-vs-private ceiling split and operational grant, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Government of India institution/agency, existing training centre, or central/state "
    "government department; OR industry association/academic institution; OR a not-for-"
    "profit private institution experienced in incubation/skill-development programmes."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           129, "Eligibility, verbatim.")
finalize(r)

# SCH000092 -- MSE-CDP, p.130. 5 distinct grant components -- the
# largest ceiling (Common Facility Centres, 70%/Rs 15 crore) is stored
# structurally; the full breakdown (diagnostic study, soft interventions,
# DPR, infrastructure, NE/hill-state enhanced rates) is in conditions[].
r = recs["SCH000092"]
b = r["content"]["benefits"]["grant"]
assert b["percentage"] is None
b["applicable"] = True
b["percentage"] = 70.0
b["percentageText"] = "70% (Common Facility Centres component)"
b["maxAmountInr"] = 150000000
b["maxAmountText"] = "Rs 15 crore (Common Facility Centres, the largest single component)"
b["description"] = (
    "Government of India grants across 5 components: (1) Diagnostic Study Report -- max "
    "Rs 2.5 lakh (Rs 1 lakh for Ministry MSME-DFOs). (2) Soft interventions (awareness, "
    "counselling, exposure visits, export market development, training) -- 75% of sanctioned "
    "amount, max project cost Rs 25 lakh/cluster. (3) Detailed Project Report -- max Rs 5 "
    "lakh. (4) Common Facility Centres (machinery/equipment for critical processes, R&D, "
    "testing) -- 70% of project cost, max Rs 15 crore. (5) Infrastructure Development -- "
    "60% of project cost (excluding land), max Rs 10 crore. NE/hill-state clusters with "
    ">50% micro/village/women-owned/SC-ST units: enhanced to 90% (soft interventions & "
    "CFCs) / 80% (infrastructure)."
)
r["content"]["benefits"]["summary"] = b["description"]
if "grant" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("grant")
add_source(r, "content.benefits.grant", {"percentage": 70.0, "maxAmountInr": 150000000}, 130,
           "Full 5-component grant structure including NE/hill-state enhanced rates, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = "State government, MSME-DFOs, and autonomous bodies."
add_source(r, "content.eligibility.narrative.criteria", "State government, MSME-DFOs, and autonomous bodies.",
           130, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
