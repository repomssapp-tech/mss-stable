#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 8. Includes a real data-quality finding: SCH000017
was marked verification.status="verified" despite having NULL
percentage/maxAmountInr on its only active benefit -- a status that
overstated what the record actually contained. This batch fills the
real figures (now genuinely verified) rather than leaving the status
misleading.
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


# ---------------------------------------------------------------------
# SCH000180 -- Tamil Nadu Credit Guarantee Scheme (TNCGS), p.51.
# Resolves the gap Batch 1 left open (live homepage fetch didn't mention
# TNCGS at all, and no approved-domain page was found then) -- this held
# document covers it directly.
r = recs["SCH000180"]
c = r["content"]
b = c["benefits"]["guarantee"]
assert b["coveragePercent"] is None
b["applicable"] = True
b["coveragePercent"] = 90.0
b["maxAmountInr"] = 20000000
b["maxAmountText"] = "Rs 2 crore (pilot phase restricted to Rs 40 lakh)"
b["description"] = (
    "Digitally-issued government-guaranteed loan, up to Rs 2 crore (pilot phase restricted "
    "to Rs 40 lakh), with no collateral/security required and no financial statements to "
    "submit. Government covers 90% of the loan for amounts up to Rs 40 lakh, and 80% for "
    "loans up to Rs 2 crore. Available from multiple banks on the state portal (pilot: TIIC "
    "and TAICO Bank). Successful borrowers build a credit score for easier future loans."
)
c["benefits"]["summary"] = b["description"]
if "guarantee" not in c["benefits"]["benefitTypes"]:
    c["benefits"]["benefitTypes"].append("guarantee")
add_source(r, "content.benefits.guarantee", {"coveragePercent": 90.0, "maxAmountInr": 20000000}, 51,
           'Verbatim: "government will cover 90% of the loan if it is upto INR 40 lakh and '
           '80% of the loan, if the loan is upto INR 2 crores." Loan ceiling and pilot '
           "restriction also verbatim.")
c["eligibility"]["narrative"]["criteria"] = "Any manufacturing MSME in Tamil Nadu."
add_source(r, "content.eligibility.narrative.criteria", "Any manufacturing MSME in Tamil Nadu.",
           51, "Eligibility, verbatim.")
c["applicationProcess"]["steps"] = c["applicationProcess"].get("steps") or []
finalize(r)

# ---------------------------------------------------------------------
# SCH000017 -- Back-ended Interest Subsidy, p.50. Was marked "verified"
# with a null percentage/maxAmountInr -- a status/content mismatch. This
# fills the two distinct components the source actually states (CGTMSE
# loan component vs. CLCSS technology-upgradation component), each with
# its own rate/cap, rather than collapsing them into one figure.
r = recs["SCH000017"]
c = r["content"]
b = c["benefits"]["interestSubvention"]
assert b["percentage"] is None
b["percentage"] = 5.0
b["percentageText"] = "5% (both components)"
b["maxAmountInr"] = 2500000
b["maxAmountText"] = "Rs 20 lakh/loan (CGTMSE component, loan up to Rs 2 crore); Rs 25 lakh/loan (CLCSS technology-upgradation component, loan up to Rs 5 crore)"
b["durationMonths"] = 60
b["description"] = (
    "Two components, both at 5% p.a. for a maximum of 5 years: (1) CGTMSE-linked term "
    "loans for technology upgradation/modernisation -- subsidy capped at Rs 20 lakh/loan, "
    "loan itself capped at Rs 2 crore. (2) CLCSS (Credit Linked Capital Subsidy Scheme) "
    "technology-upgradation term loans -- subsidy capped at Rs 25 lakh/loan, loan itself "
    "capped at Rs 5 crore. Reimbursed quarterly to the financial institution; not paid "
    "during loan/interest default periods."
)
c["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.interestSubvention", {"percentage": 5.0, "maxAmountInr": 2500000}, 50,
           "Verbatim two-component rate/cap structure (CGTMSE vs. CLCSS), not previously "
           "captured despite the record's verification.status already reading \"verified\" -- "
           "a status/content mismatch this batch corrects with real figures, not just a "
           "relabelling.")
c["eligibility"]["narrative"]["criteria"] = (
    "Existing micro/small enterprise that has availed a term loan for technology "
    "upgradation/modernisation under CGTMSE, OR a substantial-expansion/diversification "
    "term loan under CGTMSE, OR upgraded plant/machinery under CLCSS-listed sub-sectors/"
    "products (as approved by the Technical Committee headed by the Principal Secretary, "
    "MSME Department). Application filed quarterly, after completion of each quarter."
)
add_source(r, "content.eligibility.narrative.criteria", c["eligibility"]["narrative"]["criteria"],
           50, "Eligibility, verbatim.")
finalize(r)

# ---------------------------------------------------------------------
# SCH000093 -- MSEFC / MSME SAMADHAAN, p.49. Already correctly framed as
# "not a subsidy or grant" -- enriches with the specific statutory
# procedure the source states (resolution timeline, default interest
# rate, appeal deposit) and upgrades status.
r = recs["SCH000093"]
c = r["content"]
c["eligibility"]["narrative"]["criteria"] = (
    "Any micro or small enterprise (except traders) with a valid Udyam registration."
)
add_source(r, "content.eligibility.narrative.criteria", c["eligibility"]["narrative"]["criteria"],
           49, "Eligibility, verbatim.")
c["benefits"]["capitalSubsidy"]["conditions"] = c["benefits"]["capitalSubsidy"]["conditions"] + [
    "Statutory procedure: every complaint must be resolved within 90 days; a buyer who "
    "fails to pay within 45 days of accepting goods/services is liable for compound "
    "interest at 3x the bank rate; a buyer appealing an MSEFC award to a court must "
    "deposit 75% of the award amount with the council.",
]
add_source(r, "content.benefits.capitalSubsidy.conditions", "statutory procedure detail", 49,
           "MSEFC statutory procedure, verbatim -- not a monetary benefit, adds procedural "
           "detail to the already-correct 'not a subsidy or grant' framing.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
