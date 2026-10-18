#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 4. Two kinds of work:

1. SCH000028, SCH000036: already-accurate data independently re-confirmed
   against the booklet -- status raised, one enrichment each (registration
   fee detail for SCH000036) where the source had more than was captured.
2. SCH000056, SCH000058: filled from empty, same booklet.
3. SCH000059, SCH000061, SCH000078: these scheme records' own `benefits.loan`
   sub-object was never synced with the SAME booklet data already used to
   enrich their linked finance_catalog.json records (FIN000038/040/050) in
   Phase E.1 -- this batch closes that sync gap using the identical source
   citations already established then, not new research.
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
        if "benefits" not in m["field"]]
    changed.append(rec["identity"]["id"])


# SCH000028 -- Capital Subsidy. Already matched the source exactly
# (25%/Rs150 lakh) when independently checked in an earlier batch --
# status upgrade only, no value change.
finalize(recs["SCH000028"])

# SCH000036 -- Consortia and Tender Marketing Scheme, p.91. Existing
# "no direct subsidy... marketing facilitation" description already
# matches the source. Adds the registration-fee detail, which the
# existing record didn't capture.
r = recs["SCH000036"]
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Micro or small enterprise registered with NSIC under its Single Point Registration "
    "Scheme (SPRS). A registration fee of Rs 1,000 to Rs 5,000 applies (based on limits "
    "from Rs 1 crore to Rs 5 crore); SC/ST entrepreneurs are exempted."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           91, "Registration fee detail, verbatim, not previously captured.")
finalize(r)

# SCH000056 -- Events organised by academic institutions, p.43
r = recs["SCH000056"]
b = r["content"]["benefits"]["reimbursement"]
assert b.get("percentage") is None and not b.get("applicable")
b["applicable"] = True
b["maxAmountInr"] = 200000
b["maxAmountText"] = "Rs 2,00,000 per academic institution per year"
b["description"] = (
    "Reimbursement of expenses incurred towards organising a business/trade-opportunity "
    "event, subject to a maximum of Rs 2,00,000 per academic institution per year."
)
r["content"]["benefits"]["summary"] = b["description"]
if "reimbursement" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("reimbursement")
add_source(r, "content.benefits.reimbursement", {"maxAmountInr": 200000}, 43,
           'Verbatim: "Reimbursement provided for expenses incurred towards organising the '
           'event, subject to a maximum of INR 2,00,000 per academic institution per year."')
r["content"]["eligibility"]["narrative"]["criteria"] = "Any recognised academic institution."
add_source(r, "content.eligibility.narrative.criteria", "Any recognised academic institution.",
           43, "Eligibility, verbatim.")
finalize(r)

# SCH000058 -- Financial Assistance for participation in International Trade Fair, p.38
r = recs["SCH000058"]
b = r["content"]["benefits"]["reimbursement"]
assert b["percentage"] is None
b["percentage"] = 50.0
b["percentageText"] = "50%"
b["maxAmountInr"] = 1500000
b["maxAmountText"] = "Rs 15 lakh per international trade fair/exhibition"
b["description"] = (
    "50% reimbursement of rent paid towards stall or space charges, subject to a maximum "
    "of Rs 15 lakh per international trade fair/exhibition."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.reimbursement", {"percentage": 50.0, "maxAmountInr": 1500000}, 38,
           'Verbatim: "Reimbursement provided for 50% of the rent paid towards stall or '
           'space charges, subject to a maximum of INR 15 lakh per international trade '
           'fair/ exhibition."')
r["content"]["eligibility"]["narrative"]["criteria"] = "Any registered MSME association in the state."
add_source(r, "content.eligibility.narrative.criteria", "Any registered MSME association in the state.",
           38, "Eligibility, verbatim.")
finalize(r)

# ---------------------------------------------------------------------
# SCH000059/061/078 -- sync scheme-level benefits.loan with the SAME
# booklet data already applied to the linked finance_catalog.json
# records (FIN000038, FIN000040, FIN000050) in Phase E.1. Same source,
# same citations -- a sync, not new research.
LOAN_SYNC = {
    "SCH000059": {  # 4E Financing, p.111 -- FIN000038
        "maxAmountInr": 30000000, "maxAmountText": "Rs 3 crore",
        "interestRatePercent": 5.90, "interestRateText": "5.90% to 7% per annum",
        "tenureMonths": 60, "collateralRequired": True,
        "repaymentText": "Cash collateral at 25% (fixed deposit) required under the 100% funding model.",
        "page": 111,
    },
    "SCH000061": {  # General Purpose Term Loan, p.82 -- FIN000040
        "minAmountInr": 1000000, "minAmountText": "Rs 10 lakh (need-based, at least)",
        "tenureMonths": 96, "moratoriumMonths": 18,
        "repaymentText": "Repayment period 8 to 10 years including moratorium of up to 18 months (96 months stored as the lower bound).",
        "page": 82,
    },
    "SCH000078": {  # SPEED, p.80 -- FIN000050
        "maxAmountInr": 20000000, "maxAmountText": "Rs 2 crore (existing customers); Rs 1 crore (new customers)",
        "interestRatePercent": 7.50, "interestRateText": "7.50% to 9% per annum (per internal rating)",
        "tenureMonths": 24, "moratoriumMonths": 3,
        "repaymentText": "Repayment period 2 to 5 years including moratorium of 3-6 months (lower bounds stored).",
        "page": 80,
    },
}
for sid, vals in LOAN_SYNC.items():
    r = recs[sid]
    b = r["content"]["benefits"]["loan"]
    page = vals.pop("page")
    for k, v in vals.items():
        b[k] = v
    b["description"] = vals.get("repaymentText", b["description"])
    r["content"]["benefits"]["summary"] = b["description"]
    add_source(r, "content.benefits.loan", vals, page,
               "Synced from the same booklet page already used to enrich the linked "
               f"finance_catalog.json record ({'FIN000038' if sid == 'SCH000059' else 'FIN000040' if sid == 'SCH000061' else 'FIN000050'}) "
               "in Phase E.1 -- same source, not re-derived.")
    finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
