#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 -- mandatory field-reconciliation retroactive check on UYEGP
and NEEDS, per the new safety-check requirement.

UYEGP (SCH000200): re-checked. Already field-meaning-correct as fixed in
Batch 5 -- maxAmountInr holds the SUBSIDY ceiling (Rs 2.5 lakh), not the
project-cost ceiling (Rs 15 lakh), which lives only in prose. No further
change.

NEEDS (SCH000115): re-checked, and a real schema_mapping_error found
(pre-dating this phase's own Batch 5 touch, which only checked prose
accuracy, not which VALUE occupied the maxAmountInr slot). maxAmountInr
held the PROJECT COST ceiling (Rs 5 crore) while its own maxAmountText
correctly said "subsidy max Rs 75 lakh" -- a naive reader of the
structured field alone (e.g. an API filter on "maximum assistance")
would see Rs 5 crore and be wrong by 6.7x. Corrected: maxAmountInr now
holds the actual subsidy ceiling (Rs 75 lakh); minAmountInr (which held
"project cost from Rs 10 lakh") is cleared to null since NEEDS' subsidy
itself has no stated minimum -- project cost range moves to prose only.

Formal comparison record for both, per the new required structure.
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

COMPARISONS = []

# ---------------------------------------------------------------------
# UYEGP -- re-verified, no change
# ---------------------------------------------------------------------
COMPARISONS.append({
    "schemeId": "SCH000200",
    "field": "content.benefits.capitalSubsidy.maxAmountInr",
    "existingValue": "250000 (Rs 2.5 lakh)",
    "sourceValue": "Rs 2.5 lakh subsidy ceiling (project cost separately capped at Rs 15L/Rs 5L)",
    "sourcePage": 15,
    "sourceTier": 1,
    "differenceType": "none -- already correct (fixed in Batch 5 as confirmed_error, "
                       "re-verified now under the field-meaning safety check: maxAmountInr "
                       "correctly holds the SUBSIDY ceiling, not the project-cost ceiling)",
    "action": "NO CHANGE",
})

# ---------------------------------------------------------------------
# NEEDS -- full 6-point comparison per the mandated checklist
# ---------------------------------------------------------------------
r = recs["SCH000115"]
b = r["content"]["benefits"]["interestSubvention"]

NEEDS_CHECKLIST = [
    ("Project cost limit", "Rs 10 lakh (min) to Rs 5 crore (max)", "content.eligibility / prose only -- NOT a benefit-amount field", "confirmed_correct_as_prose"),
    ("Subsidy percentage", "25% capital subsidy", "content.benefits.interestSubvention.percentage = 25.0", "confirmed_correct"),
    ("Subsidy ceiling", "Rs 75 lakh", "content.benefits.interestSubvention.maxAmountInr", "SCHEMA_MAPPING_ERROR -- field held Rs 5 crore (project cost) instead"),
    ("Beneficiary/promoter contribution", "10% (general) / 5% (special category) of project cost", "prose only, not a dedicated structured field on this schema", "confirmed_correct_as_prose"),
    ("Loan component", "Not stated as a fixed percentage anywhere in the source", "not populated", "not_applicable -- correctly left unstated, not computed/inferred"),
    ("Bank contribution", "Not stated as a fixed percentage anywhere in the source", "not populated", "not_applicable -- correctly left unstated, not computed/inferred"),
]
for label, source_val, field, note in NEEDS_CHECKLIST:
    COMPARISONS.append({
        "schemeId": "SCH000115", "checklistItem": label,
        "sourceValue": source_val, "catalogField": field, "note": note,
    })

assert b["maxAmountInr"] == 50000000
old_max = b["maxAmountInr"]
old_max_text = b["maxAmountText"]
old_min = b["minAmountInr"]
old_min_text = b["minAmountText"]

b["maxAmountInr"] = 7500000
b["maxAmountText"] = "Rs 75 lakh (subsidy ceiling)"
b["minAmountInr"] = None
b["minAmountText"] = None
b["description"] = (
    "25% capital subsidy on project cost, subject to a maximum of Rs 75 lakh. Separately, "
    "3% interest subvention throughout the repayment period. Project cost itself must be "
    "above Rs 10 lakh and below Rs 5 crore -- this is a project-cost eligibility range, not "
    "the subsidy amount, and is not stored in the amount fields. Promoter contribution: 10% "
    "of project cost (general category) or 5% (special category). An additional 10% capital "
    "subsidy applies for enterprises promoted by SC/ST or differently-abled candidates. "
    "SIDCO industrial-estate allotment priority also applies. Loan/bank-contribution "
    "percentages are not stated as a fixed rule in the source and are not populated."
)
r["content"]["benefits"]["summary"] = b["description"]

r["provenance"].setdefault("fieldSources", []).append({
    "field": "content.benefits.interestSubvention.maxAmountInr / minAmountInr",
    "value": {"maxAmountInr": 7500000, "minAmountInr": None},
    "sourceTier": 1, "sourceType": "official_booklet_held",
    "organization": "MSME Department, Government of Tamil Nadu",
    "url": None, "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None,
    "note": (f"{DOC % 16} CORRECTION (schema_mapping_error, found under the mandatory "
             f"field-reconciliation safety check): maxAmountInr previously held "
             f"{old_max} (Rs 5 crore, the PROJECT COST ceiling, text: \"{old_max_text}\") "
             f"in a field meant to represent the subsidy/assistance ceiling. Corrected to "
             f"7500000 (Rs 75 lakh), the actual subsidy ceiling verbatim from the source: "
             f'"25% capital subsidy up to Rs 75 lakh." minAmountInr (previously {old_min}, '
             f'text: "{old_min_text}") is cleared to null -- the subsidy itself has no '
             f"stated minimum; Rs 10 lakh was the project-cost floor, not a subsidy minimum. "
             f"Project cost range (Rs 10L-Rs 5cr) is preserved in description prose only, "
             f"never in an amount-typed field."),
})
r["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
r["metadata"]["revision"] += 1


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

with open("needs_uyegp_reconciliation.json", "w", encoding="utf-8") as f:
    json.dump(COMPARISONS, f, ensure_ascii=False, indent=2)

print("Done. SCH000115.maxAmountInr:", old_max, "->", b["maxAmountInr"])
