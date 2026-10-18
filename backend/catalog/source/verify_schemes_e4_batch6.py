#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 6. Includes one genuine correction (SCH000200) found
by re-reading the primary source more carefully than the record that
first populated it did -- not a two-source conflict, a single-source
computation error being fixed against the source itself.
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
corrections = []


def add_source(rec, field, value, page, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field, "value": value,
        "sourceTier": 1, "sourceType": "official_booklet_held",
        "organization": "MSME Department, Government of Tamil Nadu",
        "url": None, "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None,
        "note": f"{DOC % page} {note}",
    })


def finalize(rec, raise_status=True):
    if raise_status:
        rec["verification"]["status"] = "verified"
        rec["verification"]["confidence"] = "high"
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"] if "benefits" not in m["field"]]
    changed.append(rec["identity"]["id"])


# ---------------------------------------------------------------------
# SCH000200 -- UYEGP, p.15. CORRECTION: the existing description states
# "25% capital subsidy capped at INR 3.75 lakh" -- a computed figure
# (25% x the INR 15 lakh PROJECT COST ceiling) that does not appear
# anywhere in the source. The source states a flat, independent subsidy
# cap of INR 2.5 lakh, unrelated to the project-cost ceiling. This is a
# single-source arithmetic error being corrected against the primary
# source, not a competing value from elsewhere -- logged as a correction
# in SCHEME_DATA_CONFLICT_REPORT.md, not left as an open dispute.
r = recs["SCH000200"]
c = r["content"]
old_desc = c["benefits"]["capitalSubsidy"]["description"]
c["benefits"]["capitalSubsidy"]["maxAmountInr"] = 250000
c["benefits"]["capitalSubsidy"]["maxAmountText"] = "Rs 2.5 lakh (subsidy ceiling, independent of the project-cost ceiling below)"
c["benefits"]["capitalSubsidy"]["description"] = (
    "25% of project cost as a subsidy, subject to a maximum of Rs 2.5 lakh. Separately, "
    "project cost itself is capped at Rs 15 lakh for manufacturing or Rs 5 lakh for "
    "business/service activities -- this is a project-cost ceiling, not the subsidy amount, "
    "and does not change the flat Rs 2.5 lakh subsidy cap."
)
c["benefits"]["summary"] = c["benefits"]["capitalSubsidy"]["description"]
add_source(r, "content.benefits.capitalSubsidy", {"maxAmountInr": 250000}, 15,
           'Verbatim: "Subsidy provided for 25% of project cost; subject to a maximum of INR '
           '2.5 lakh." CORRECTS an existing computed figure of Rs 3.75 lakh (25% x the Rs 15 '
           "lakh project-cost ceiling), which does not appear in the source -- the source "
           "states a flat, independent Rs 2.5 lakh cap.")
c["eligibility"]["narrative"]["criteria"] = (
    "Age 18+ (max 35 for general category, max 45 for SC/ST/MBC/BC/Minorities/Ex-"
    "Servicemen/Differently-abled/Transgender). Minimum 8th standard pass. Family income "
    "not exceeding Rs 5 lakh/annum. Applicant's contribution: 10% (general) or 5% (special "
    "category) of project cost. Entrepreneurship Development Programme (EDP) training is "
    "mandatory. Project cost capped at Rs 15 lakh (manufacturing) or Rs 5 lakh (business/"
    "service)."
)
add_source(r, "content.eligibility.narrative.criteria", c["eligibility"]["narrative"]["criteria"],
           15, "Full eligibility detail, verbatim.")
corrections.append({
    "scheme": "SCH000200", "field": "content.benefits.capitalSubsidy.maxAmountInr / description",
    "oldValue": f"Rs 3.75 lakh (computed, description: \"{old_desc[:90]}...\")",
    "newValue": "Rs 2.5 lakh (verbatim from source)",
    "source": DOC % 15, "sourcePriority": "Tier 1, single source, no competing value",
    "decision": "CORRECTED -- the old figure was an unstated computation, not a sourced fact.",
})
finalize(r)

# SCH000115 -- NEEDS, p.16. Already accurate (independently re-confirmed
# earlier this session) -- status upgrade only, no value change.
finalize(recs["SCH000115"])

# SCH000028 -- Capital Subsidy, p.19. Adds the micro-enterprise tier
# (25%/Rs 25 lakh) the existing record didn't distinguish from the small/
# medium tier (25%/Rs 150 lakh, already correct and unchanged).
r = recs["SCH000028"]
c = r["content"]
c["benefits"]["capitalSubsidy"]["conditions"] = c["benefits"]["capitalSubsidy"]["conditions"] + [
    "For micro manufacturing enterprises specifically: 25% of eligible plant and machinery "
    "cost, subject to a maximum of Rs 25 lakh (lower than the Rs 150 lakh small/medium "
    "ceiling already recorded).",
]
add_source(r, "content.benefits.capitalSubsidy", {"microTierMaxAmountInr": 2500000}, 19,
           'Verbatim: "For micro manufacturing enterprises - Subsidy provided for 25% of '
           'eligible plant and machinery cost; subject to a maximum of INR 25 lakh." Adds '
           "the micro-specific ceiling; the existing Rs 150 lakh small/medium ceiling was "
           "already correct and is unchanged.")
finalize(r)

# SCH000090 -- Marketing Development Assistance to registered MSME associations, p.39
r = recs["SCH000090"]
b = r["content"]["benefits"]["reimbursement"]
assert b["percentage"] is None
b["percentage"] = 50.0
b["percentageText"] = "50%"
b["maxAmountInr"] = 750000
b["maxAmountText"] = "Rs 7.5 lakh/event (Chennai or other-state exhibitions); Rs 1.5 lakh/event (districts other than Chennai)"
b["description"] = (
    "50% of expenses incurred on hall rent: max Rs 7.5 lakh/event in Chennai, max Rs 1.5 "
    "lakh/event in other districts, max Rs 7.5 lakh/exhibition for participation in other "
    "states' exhibitions."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.reimbursement", {"percentage": 50.0, "maxAmountInr": 750000}, 39,
           "Verbatim tiered hall-rent reimbursement rates by location.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Registered MSME association, in existence at least 3 years, with a minimum of 20 "
    "Micro and Small Enterprise (MSE) units as members."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           39, "Eligibility, verbatim.")
finalize(r)

# SCH000163 -- Skill Training and Employment Scheme, p.61
r = recs["SCH000163"]
b = r["content"]["benefits"]["capitalSubsidy"]
assert b["maxAmountInr"] is None
b["applicable"] = True
b["maxAmountInr"] = 2000
b["maxAmountText"] = "Rs 2,000 per month per candidate, max 6 months"
b["description"] = (
    "Training subsidy of Rs 2,000/month/candidate, for up to 6 months. Trainees must be "
    "18-25 years old with an engineering degree, polytechnic diploma, ITI certificate, or "
    "sector skill council qualification; the employer must pay a stipend of Rs 5,000/month "
    "for up to 6 months. Certification via National Skill Development Corporation (NSDC) "
    "assessment."
)
r["content"]["benefits"]["summary"] = b["description"]
if "capitalSubsidy" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("capitalSubsidy")
add_source(r, "content.benefits.capitalSubsidy", {"maxAmountInr": 2000}, 61,
           'Verbatim: "Subsidy provided for training; subject to a maximum of INR 2000 per '
           'month per candidate, for a maximum of 6 months."')
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Any MSME in the state training candidates aged 18-25 who hold an engineering degree, "
    "polytechnic diploma, ITI certificate, or qualification prescribed by the relevant "
    "sector skill council. Employer must pay the trainee a stipend of Rs 5,000/month for up "
    "to 6 months."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           61, "Eligibility, verbatim.")
finalize(r)

# SCH000053 -- EDII Technology Development Fund, p.58
r = recs["SCH000053"]
b = r["content"]["benefits"]["grant"]
assert b["percentage"] is None
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "50%"
b["maxAmountInr"] = 250000
b["maxAmountText"] = "Rs 2.5 lakh (project cost) OR 50%, whichever is less"
b["description"] = (
    "50% of project cost, or Rs 2.5 lakh, whichever is less, for operational-efficiency "
    "studies at micro enterprises. Funded from a Rs 25 lakh corpus; capped at 100 studies/"
    "year (first-come-first-served), each up to 6 person-days, carried out only by "
    "institutions approved by the Industries Commissioner and Director of Industries and "
    "Commerce."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", {"percentage": 50.0, "maxAmountInr": 250000}, 58,
           'Verbatim: "Subsidy provided for 50% of the project cost or INR 2.5 lakh, '
           'whichever is less." Plus corpus/cap/study-scope detail.')
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "MSME association that has taken up a small development project through a recognized "
    "educational institution, with prior approval of the Industries Commissioner and "
    "Director of Industries and Commerce."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           58, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
print("Corrections:", json.dumps(corrections, indent=2, ensure_ascii=False))
