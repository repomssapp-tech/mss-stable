#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 5 -- closes the same scheme<->finance sync gap Batch 2
found, for the remaining Phase E.1 finance records: SAFE, ARISE, RMA,
SMILE, STHAPAN, CGTMSE. Same source citations already established in
Phase E.1 (TN booklet for the first 5; cgtmse.in live fetch + the
booklet's category breakdown for CGTMSE) -- a sync, not new research.

SCH000011/SCH000012 (SAFE/ARISE) keep their existing verification.status
of "historical" (a correct, more specific status than "verified" would
be for a discontinued scheme) -- only their benefit data is filled.
"""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
DOC_BOOKLET = ('"Compendium of Schemes for MSMEs 2022" (MSME Department, Government '
               'of Tamil Nadu, September 2022), held locally as '
               'TN_Schemes_Booklet_2022_v10.md, page %s.')

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []


def add_source_booklet(rec, field, value, page, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field, "value": value,
        "sourceTier": 1, "sourceType": "official_booklet_held",
        "organization": "MSME Department, Government of Tamil Nadu",
        "url": None, "retrievedAt": RETRIEVED_AT, "isBackfill": True, "supersededValue": None,
        "note": f"{DOC_BOOKLET % page} {note}",
    })


def add_source_web(rec, field, value, url, org, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field, "value": value,
        "sourceTier": 5, "sourceType": "official_website",
        "organization": org, "url": url, "retrievedAt": RETRIEVED_AT,
        "isBackfill": True, "supersededValue": None, "note": note,
    })


def touch(rec, raise_status=True):
    if raise_status:
        rec["verification"]["status"] = "verified"
        rec["verification"]["confidence"] = "high"
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"] if "benefits" not in m["field"]]
    changed.append(rec["identity"]["id"])


# SCH000011 -- SAFE, p.85. Status stays "historical" (more specific/correct
# than "verified" for a discontinued scheme).
r = recs["SCH000011"]
b = r["content"]["benefits"]["loan"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 5000000
b["maxAmountText"] = "Rs 50 lakh"
b["interestRatePercent"] = 5.0
b["interestRateText"] = "5% per annum, fixed on reducing balance basis"
b["tenureMonths"] = 60
b["repaymentText"] = ("Term loan max 5 years incl. moratorium; Working Capital Term Loan "
                       "variant caps at 18 months incl. moratorium.")
b["collateralRequired"] = None  # conditional (existing vs new customers) -- not a single answer, left null
b["description"] = (
    "Loan up to Rs 50 lakh to acquire equipment/plant/machinery/raw materials, at 5% p.a. "
    "fixed (reducing balance), repayable over max 5 years (60 months) including moratorium "
    "(WCTL variant: max 18 months)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source_booklet(r, "content.benefits.loan", {"maxAmountInr": 5000000, "interestRatePercent": 5.0, "tenureMonths": 60},
                    85, "Synced with FIN000006's Phase E.1 enrichment -- same source.")
touch(r, raise_status=False)

# SCH000012 -- ARISE, p.84. Status stays "historical".
r = recs["SCH000012"]
b = r["content"]["benefits"]["loan"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 70000000
b["maxAmountText"] = "Rs 700 lakh (Rs 7 crore), max 80% of project cost"
b["interestRatePercent"] = 7.10
b["interestRateText"] = "7.10% to 7.75% for the first year, with reset thereafter (per internal rating)"
b["tenureMonths"] = 84
b["repaymentText"] = "Repayment period generally 7 years (84 months)."
b["description"] = (
    "Term loan up to Rs 700 lakh (max 80% of project cost) for expansion/modernisation/"
    "capex, at 7.10-7.75% p.a. for the first year, repayable over ~7 years. Alternate "
    "structure: 100% financing up to Rs 5 crore, based on a 25%+ interest-bearing fixed "
    "deposit."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source_booklet(r, "content.benefits.loan", {"maxAmountInr": 70000000, "interestRatePercent": 7.10, "tenureMonths": 84},
                    84, "Synced with FIN000007's Phase E.1 enrichment -- same source.")
touch(r, raise_status=False)

# SCH000140 -- RMA against bank guarantee, p.77. Sub-object schema is
# "guarantee" type (coveragePercent/feePercent, not interestRatePercent)
# -- the 7.5-9% financing rate is recorded in percentageText/description
# instead, and the 1% processing fee in feePercent, matching this
# sub-object's actual field set rather than the loan sub-object's.
r = recs["SCH000140"]
b = r["content"]["benefits"]["guarantee"]
assert b["maxAmountInr"] is None
b["percentageText"] = "7.5% to 9% financing rate for Micro, Small and Medium sized enterprises"
b["feePercent"] = 1.0
b["maxAmountInr"] = 1000000
b["maxAmountText"] = "Rs 10 lakh (manufacturing); Rs 6 lakh (service); Rs 500 lakh (infrastructure)"
b["description"] = (
    "Financing for raw material procurement (indigenous/imported) against bank guarantee, "
    "credit support up to 180 days, interest 7.5-9%. Category ceilings: Rs 10 lakh "
    "(manufacturing), Rs 6 lakh (service), Rs 500 lakh (infrastructure). Processing fee: "
    "1% p.a. (new/renewal), 0.5% p.a. (renewal by micro units)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source_booklet(r, "content.benefits.guarantee", {"interestRatePercent": 7.5, "maxAmountInr": 1000000}, 77,
                    "Synced with FIN000085's Phase E.1 enrichment -- same source.")
touch(r)

# SCH000159 -- SMILE, p.102
r = recs["SCH000159"]
b = r["content"]["benefits"]["loan"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 20000000
b["maxAmountText"] = "Rs 2 crore (under CGTMSE)"
b["minAmountInr"] = 1000000
b["minAmountText"] = "Rs 10 lakh (equipment finance); Rs 25 lakh (other)"
b["tenureMonths"] = 120
b["moratoriumMonths"] = 36
b["collateralRequired"] = False
b["repaymentText"] = "Term loan repayment 10 years including 3-year moratorium."
b["description"] = (
    "Term/soft loan for MSME market expansion and modernisation, up to Rs 2 crore under "
    "CGTMSE, minimum Rs 10 lakh (equipment finance) or Rs 25 lakh (other), repayable over "
    "10 years including a 3-year moratorium. Promoter's contribution minimum 15%, debt-"
    "equity ratio up to 3:1."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source_booklet(r, "content.benefits.loan", {"maxAmountInr": 20000000, "tenureMonths": 120}, 102,
                    "Synced with FIN000095's Phase E.1 enrichment -- same source.")
touch(r)

# SCH000160 -- STHAPAN, p.78
r = recs["SCH000160"]
b = r["content"]["benefits"]["loan"]
assert b["maxAmountInr"] is None
b["maxAmountInr"] = 200000000
b["maxAmountText"] = "Rs 2000 lakh (Rs 20 crore), max 75% of project cost"
b["interestRatePercent"] = 7.60
b["interestRateText"] = "7.60% to 8.25% for the first year, with reset thereafter (per internal rating)"
b["tenureMonths"] = 84
b["repaymentText"] = "Repayment period 7 years (84 months) for a 7-year loan."
b["description"] = (
    "Term loan for greenfield units (land, factory construction, equipment/plant/"
    "machinery), up to Rs 20 crore (max 75% of project cost), at 7.60-8.25% p.a. for the "
    "first year, repayable over 7 years. Promoters require 5+ years of business experience."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source_booklet(r, "content.benefits.loan", {"maxAmountInr": 200000000, "interestRatePercent": 7.60}, 78,
                    "Synced with FIN000096's Phase E.1 enrichment -- same source.")
touch(r)

# SCH000038 -- CGTMSE. maxCoverInr intentionally NOT set here (Phase E.1
# left it as an open dispute between tier-1 booklet Rs 2cr and tier-5 live
# Rs 10cr, see SCHEME_DATA_CONFLICT_REPORT.md sec 2) -- only the
# non-conflicting coveragePercent breakdown, already added to
# FIN000026 in Phase E.1, is synced here.
r = recs["SCH000038"]
b = r["content"]["benefits"]["guarantee"]
assert b["coveragePercent"] is None
b["coveragePercent"] = 75.0
b["description"] = (
    "Credit guarantee, collateral-free, for eligible MSME credit facilities. Coverage "
    "varies by category: micro enterprise 85% (max Rs 5 lakh); other enterprises 75%; "
    "retail trade 50% (loans Rs 10-100 lakh); woman-owned/operated micro or small "
    "enterprise 80% (max Rs 50 lakh); North East Region enterprise 80%; default claims "
    "settled up to 75% (max Rs 200 lakh). Guarantee-ceiling figure is under an open "
    "source conflict -- see SCHEME_DATA_CONFLICT_REPORT.md -- and is deliberately left "
    "null here rather than picked."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source_booklet(r, "content.benefits.guarantee", {"coveragePercent": 75.0}, 100,
                    "Synced with FIN000026's Phase E.1 enrichment (coveragePercent only; "
                    "maxCoverInr remains an open conflict, not set here).")
touch(r, raise_status=False)  # stays partially_verified: maxCoverInr conflict is unresolved


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
