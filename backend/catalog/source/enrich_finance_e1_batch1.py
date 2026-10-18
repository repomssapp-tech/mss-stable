#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.1 Batch 1 -- Financial enrichment from an already-held Tier-1
official document: "Compendium of Schemes for MSMEs 2022", MSME
Department, Government of Tamil Nadu, September 2022
(TN_Schemes_Booklet_2022_v10.md, "FaMe TN"). Tier 1 per
MSS_Data_Completion_Policy_v1.0.md sec 2 ("Latest official Government PDF,
booklet... already held").

Every write below is additive only (assert-checked null before write) and
carries a fieldSources[] entry with sourceTier=1, organization, and a
document citation (no live URL -- this is a held document, not a web
fetch). Where the booklet states a RANGE (e.g. "7.10% to 7.75%"), the
lower bound is stored in the single-value field and the full range is
preserved verbatim in conditions[] -- never averaged or invented as a
midpoint.

CGTMSE (FIN000026) special case: the booklet's loan-guarantee ceiling
(Rs 2 crore, 2022) CONFLICTS with the Phase D1 live-fetched ceiling
(Rs 10 crore, cgtmse.in, retrieved 2026-08-15). Per this phase's explicit
instruction ("Reject information if source conflicts exist"), maxCoverInr
is NOT touched by this script -- the conflict is recorded in
verification.disputedFields[] only. Only the non-conflicting
coveragePercent/category breakdown (which the live page never stated) is
added.
"""
import json, hashlib
from copy import deepcopy

PATH = "finance_catalog.json"
RETRIEVED_AT = "2026-08-15"
SRC = {
    "sourceTier": 1,
    "sourceType": "official_booklet_held",
    "organization": "MSME Department, Government of Tamil Nadu",
    "url": None,
    "retrievedAt": RETRIEVED_AT,
    "isBackfill": True,
    "supersededValue": None,
}
DOC = ('"Compendium of Schemes for MSMEs 2022" (MSME Department, Government '
       'of Tamil Nadu, September 2022 -- "FaMe TN"), held locally as '
       'TN_Schemes_Booklet_2022_v10.md, page %s.')

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []


def src(page, note):
    d = dict(SRC)
    d["note"] = f"{DOC % page} {note}"
    return d


def add_source(rec, field, value, page, note):
    rec["provenance"].setdefault("fieldSources", []).append(
        {"field": field, "value": value, **src(page, note)})


def remove_missing(rec, field):
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"] if m["field"] != field]


def bump(rec):
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1


# ---------------------------------------------------------------------
# FIN000006 -- SAFE (page 85)
r = recs["FIN000006"]; c = r["content"]
assert c["amount"]["maxInr"] is None
c["amount"]["maxInr"] = 5000000; c["amount"]["maxText"] = "Rs 50 lakh"
add_source(r, "content.amount", {"maxInr": 5000000}, 85,
           'Verbatim: "Loan provided to MSMEs; subject to a maximum of INR 50 lakh."')
assert c["interestRate"]["percent"] is None
c["interestRate"]["percent"] = 5.0
c["interestRate"]["text"] = "5% per annum, fixed on reducing balance basis"
add_source(r, "content.interestRate", {"percent": 5.0}, 85,
           'Verbatim: "Rate of interest provided is 5%/annum, fixed on reducing balance basis."')
remove_missing(r, "content.interestRate")
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 60
add_source(r, "content.tenure", {"tenureMonths": 60}, 85,
           "Term loan repayment max 5 years (60 months) including moratorium; a separate "
           "Working Capital Term Loan variant caps at 18 months including moratorium -- "
           "recorded as a condition below, not the primary tenure.")
remove_missing(r, "content.tenure")
c["conditions"] = c["conditions"] + [
    "Collateral is conditional: existing SIDBI customers extend existing security; new "
    "customers receive credit guarantee coverage (cost borne by SIDBI, up to 100%) or "
    "other security -- collateral.status left not_specified because no single answer "
    "applies to both cases.",
    "Working Capital Term Loan (WCTL) variant: repayment max 18 months including "
    "moratorium (vs. 60 months for the standard term loan).",
]
add_source(r, "content.conditions", c["conditions"], 85, "Collateral and WCTL variant terms.")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000007 -- ARISE (page 84)
r = recs["FIN000007"]; c = r["content"]
assert c["amount"]["maxInr"] is None
c["amount"]["maxInr"] = 70000000; c["amount"]["maxText"] = "Rs 700 lakh (Rs 7 crore)"
add_source(r, "content.amount", {"maxInr": 70000000}, 84,
           'Verbatim: "Term loans upto INR 700 lakh is provided; subject to a maximum of 80% '
           'of project cost." An alternate structure -- 100% financing subject to a maximum '
           'of Rs 5 crore, based on an interest-bearing fixed deposit of at least 25% -- is '
           'recorded in conditions[] rather than as a second maxInr.')
assert c["interestRate"]["percent"] is None
c["interestRate"]["percent"] = 7.10
c["interestRate"]["text"] = "7.10% to 7.75% for the first year, with reset thereafter (per internal rating)"
add_source(r, "content.interestRate", {"percent": 7.10}, 84, "First-year rate range, verbatim.")
remove_missing(r, "content.interestRate")
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 84
add_source(r, "content.tenure", {"tenureMonths": 84}, 84, 'Verbatim: "Repayment period is of 7 years generally."')
remove_missing(r, "content.tenure")
c["conditions"] = c["conditions"] + [
    "Alternate structure: 100% financing subject to a maximum of Rs 5 crore, based on an "
    "interest-bearing fixed deposit of at least 25%.",
]
add_source(r, "content.conditions", c["conditions"], 84, "Alternate financing structure.")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000038 -- 4E Financing (page 111)
r = recs["FIN000038"]; c = r["content"]
assert c["amount"]["maxInr"] is None
c["amount"]["maxInr"] = 30000000; c["amount"]["maxText"] = "Rs 3 crore"
add_source(r, "content.amount", {"maxInr": 30000000}, 111,
           'Verbatim: "Term loans; subject to a maximum of INR 3 crore is provided for '
           'purchase of machineries."')
assert c["interestRate"]["percent"] is None
c["interestRate"]["percent"] = 5.90
c["interestRate"]["text"] = "5.90% to 7% per annum"
add_source(r, "content.interestRate", {"percent": 5.90}, 111, "Verbatim rate range.")
remove_missing(r, "content.interestRate")
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 60
add_source(r, "content.tenure", {"tenureMonths": 60}, 111, 'Verbatim: "Tenure of loans is upto 60 months."')
remove_missing(r, "content.tenure")
assert c["collateral"]["status"] == "not_specified"
c["collateral"]["status"] = "required"
c["collateral"]["notes"] = ('Verbatim: "Cash collateral at the rate of 25% as fixed deposit is '
                             'provided under 100% funding model." Explicit collateral requirement, not inferred.')
add_source(r, "content.collateral", {"status": "required"}, 111, "Cash collateral (25% FD) explicitly required.")
remove_missing(r, "content.collateral.status")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000040 -- General Purpose Term Loan (page 82)
r = recs["FIN000040"]; c = r["content"]
assert c["amount"]["minInr"] is None
c["amount"]["minInr"] = 1000000; c["amount"]["minText"] = "Rs 10 lakh (need-based, at least)"
add_source(r, "content.amount", {"minInr": 1000000}, 82,
           'Verbatim: "Need based financial assistance of atleast INR 10 lakh is provided."')
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 96
c["tenure"]["moratoriumMonths"] = 18
add_source(r, "content.tenure", {"tenureMonths": 96, "moratoriumMonths": 18}, 82,
           'Verbatim: "Repayment period for term loan, including the moratorium period of '
           'upto 18 months, is around 8-10 years." Lower bound (8 years = 96 months) stored; '
           'upper bound (10 years) recorded in conditions[], not averaged.')
remove_missing(r, "content.tenure")
c["conditions"] = c["conditions"] + [
    "Repayment period stated as a range: 8 to 10 years including moratorium (96 stored as the lower bound).",
]
add_source(r, "content.conditions", c["conditions"], 82, "Repayment range.")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000050 -- SPEED (page 80)
r = recs["FIN000050"]; c = r["content"]
assert c["amount"]["maxInr"] is None
c["amount"]["maxInr"] = 20000000; c["amount"]["maxText"] = "Rs 2 crore (existing customers); Rs 1 crore (new customers)"
add_source(r, "content.amount", {"maxInr": 20000000}, 80,
           'Verbatim: "100% of the machinery cost provided; subject to a maximum of: a. INR 1 '
           'crore, for new customers, and b. INR 2 crores, for existing customers." Higher of '
           "the two ceilings stored as maxInr; both figures preserved in conditions[].")
assert c["interestRate"]["percent"] is None
c["interestRate"]["percent"] = 7.50
c["interestRate"]["text"] = "7.50% to 9% per annum (Marginal Capital Lending Ratio based, per internal rating)"
add_source(r, "content.interestRate", {"percent": 7.50}, 80, "Verbatim rate range.")
remove_missing(r, "content.interestRate")
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 24
c["tenure"]["moratoriumMonths"] = 3
add_source(r, "content.tenure", {"tenureMonths": 24, "moratoriumMonths": 3}, 80,
           'Verbatim: "Repayment period of term loan is 2 to 5 years, including a moratorium '
           'period of 3-6 months." Lower bounds stored; upper bounds in conditions[].')
remove_missing(r, "content.tenure")
c["conditions"] = c["conditions"] + [
    "Machinery-cost ceiling: Rs 1 crore for new customers, Rs 2 crore for existing customers.",
    "Repayment period range: 2 to 5 years, moratorium 3 to 6 months.",
]
add_source(r, "content.conditions", c["conditions"], 80, "Ceiling split and repayment range.")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000085 -- RMA against bank guarantee (page 77) -- was already
# partially populated (collateral=guarantee_covered from an earlier
# round); this adds interestRate/feePercent/maxInr, all null before write.
r = recs["FIN000085"]; c = r["content"]
assert c["interestRate"]["percent"] is None
c["interestRate"]["percent"] = 7.5
c["interestRate"]["text"] = "7.5% to 9% for Micro, Small and Medium sized enterprises"
add_source(r, "content.interestRate", {"percent": 7.5}, 77, "Verbatim rate range.")
remove_missing(r, "content.interestRate")
assert c["feePercent"] is None
c["feePercent"] = 1.0
add_source(r, "content.feePercent", 1.0, 77,
           'Verbatim: "Processing fee of 1% per annum applicable for new sanctions and for '
           'renewals; processing fee of 0.5% per annum applicable for renewal by micro units."')
assert c["amount"]["maxInr"] is None
c["amount"]["maxInr"] = 1000000
c["amount"]["maxText"] = "Rs 10 lakh (manufacturing); Rs 6 lakh (service); Rs 500 lakh (infrastructure)"
add_source(r, "content.amount", {"maxInr": 1000000}, 77,
           'Verbatim category ceilings: "Maximum limit of INR 10 lakh for manufacturing units '
           'and INR 6 lakh for service units. Limit is INR 500 lakh for units engaged in '
           "infrastructure activities.\" Manufacturing figure (most common case) stored as "
           "maxInr; full breakdown in conditions[].")
c["conditions"] = c["conditions"] + [
    "Category ceilings: Rs 10 lakh (manufacturing), Rs 6 lakh (service), Rs 500 lakh (infrastructure).",
    "Processing fee: 1% p.a. (new sanctions, renewals); 0.5% p.a. (renewal by micro units).",
]
add_source(r, "content.conditions", c["conditions"], 77, "Category ceilings and fee schedule.")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000089 -- Secured Business Loans for MSMEs (page 83). BOTH maxInr
# (Rs 25 lakh, already populated from an earlier round) and tenureMonths
# (36) are ALREADY populated -- and the booklet's figures (max Rs 10
# crore, repayment max 10 years / 120 months) are drastically different
# from both, a real order-of-magnitude conflict, not a complementary
# detail. Per this phase's explicit "reject on conflict" instructionnothing
# is written to content for this record; the conflict is only logged.
r = recs["FIN000089"]; c = r["content"]
assert c["amount"]["maxInr"] == 2500000 and c["tenure"]["tenureMonths"] == 36
r["verification"]["disputedFields"] = r["verification"].get("disputedFields", []) + [{
    "field": "content.amount.maxInr / content.tenure.tenureMonths",
    "existingValue": "maxInr=Rs 25 lakh, tenureMonths=36 (source: earlier round, not re-derived here)",
    "tier1CandidateValue": "maxInr=Rs 10 crore (incl. foreign-currency loans), tenureMonths<=120 "
                            "(10 years incl. moratorium), per Compendium of Schemes for MSMEs "
                            "2022 p.83",
    "note": "Order-of-magnitude conflict (40x on amount). REJECTED, not applied -- per this "
            "phase's explicit instruction to reject rather than resolve a source conflict. "
            "content unchanged. Flagged for human review: possible causes include the existing "
            "figure describing a different/smaller loan variant, or an extraction error in an "
            "earlier round -- this script cannot tell which without a human decision.",
}]
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000095 -- SMILE (page 102)
r = recs["FIN000095"]; c = r["content"]
assert c["amount"]["maxInr"] is None and c["amount"]["minInr"] is None
c["amount"]["maxInr"] = 20000000; c["amount"]["maxText"] = "Rs 2 crore (under CGTMSE)"
c["amount"]["minInr"] = 1000000; c["amount"]["minText"] = "Rs 10 lakh (equipment finance); Rs 25 lakh (other)"
add_source(r, "content.amount", {"maxInr": 20000000, "minInr": 1000000}, 102,
           'Verbatim: "Term loan and soft loan provided; subject to a maximum of INR 2 crores '
           'under CGTMSE." Minimum: "Minimum loan size for equipment finance - INR 10 lakh. '
           'Minimum loan size for things other than equipment finance: INR 25 lakh." Lower '
           "minimum (equipment) stored; both preserved in conditions[].")
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 120
c["tenure"]["moratoriumMonths"] = 36
add_source(r, "content.tenure", {"tenureMonths": 120, "moratoriumMonths": 36}, 102,
           'Verbatim: "Repayment of term loan: 10 years including 3 years moratorium."')
remove_missing(r, "content.tenure")
assert c["collateral"]["status"] == "not_specified"
c["collateral"]["status"] = "guarantee_covered"
c["collateral"]["notes"] = 'Verbatim: financing "under CGTMSE" -- explicit guarantee-scheme backing, not inferred.'
add_source(r, "content.collateral", {"status": "guarantee_covered"}, 102, "CGTMSE-backed, stated explicitly.")
c["conditions"] = c["conditions"] + [
    "Minimum loan size: Rs 10 lakh for equipment finance; Rs 25 lakh for other finance.",
    "Promoter's contribution: minimum 15%, subject to a debt-equity ratio of 3:1.",
]
add_source(r, "content.conditions", c["conditions"], 102, "Minimums and promoter contribution.")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000096 -- STHAPAN (page 78)
r = recs["FIN000096"]; c = r["content"]
assert c["amount"]["maxInr"] is None
c["amount"]["maxInr"] = 200000000
c["amount"]["maxText"] = "Rs 2000 lakh (Rs 20 crore), subject to max 75% of project cost"
add_source(r, "content.amount", {"maxInr": 200000000}, 78,
           'Verbatim: "Term loan is provided upto INR 2000 lakh, subject to maximum of 75% of '
           'project cost."')
assert c["interestRate"]["percent"] is None
c["interestRate"]["percent"] = 7.60
c["interestRate"]["text"] = "7.60% to 8.25% for the first year, with reset thereafter (per internal rating)"
add_source(r, "content.interestRate", {"percent": 7.60}, 78, "Verbatim first-year rate range.")
remove_missing(r, "content.interestRate")
assert c["tenure"]["tenureMonths"] is None
c["tenure"]["tenureMonths"] = 84
add_source(r, "content.tenure", {"tenureMonths": 84}, 78, 'Verbatim: "Repayment period if loan is of 7 years."')
remove_missing(r, "content.tenure")
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
# FIN000026 -- CGTMSE (page 100). Category coveragePercent breakdown is
# NEW (not stated on the live page consulted in Phase D1); maxCoverInr is
# LEFT UNTOUCHED because it conflicts with the Phase D1 live-fetched
# value -- recorded as a dispute per this phase's explicit "reject on
# conflict" instruction, not resolved by tier priority.
r = recs["FIN000026"]; c = r["content"]
assert c["coveragePercent"] is None
c["coveragePercent"] = 75.0
add_source(r, "content.coveragePercent", 75.0, 100,
           'Verbatim: "For other enterprises: guarantee is provided upto 75%." Stored as the '
           "general/default category rate; full category breakdown below.")
remove_missing(r, "content.coveragePercent")
c["conditions"] = c["conditions"] + [
    "Coverage varies by category: micro enterprise 85% (max Rs 5 lakh); other enterprises 75%; "
    "retail trade 50% (loans Rs 10-100 lakh); woman-owned/operated micro or small enterprise "
    "80% (max Rs 50 lakh); North East Region enterprise 80%; default claims settled up to 75% "
    "(max Rs 200 lakh).",
]
add_source(r, "content.conditions", c["conditions"], 100, "Full category coverage breakdown, verbatim.")
r["verification"]["disputedFields"] = r["verification"].get("disputedFields", []) + [{
    "field": "content.maxCoverInr",
    "tier1Value": "Rs 2 crore (loans up to this amount are eligible for guarantee), per "
                  "Compendium of Schemes for MSMEs 2022 p.100",
    "tier5Value": "Rs 10 crore (guarantee ceiling), per https://www.cgtmse.in/ retrieved "
                  "2026-08-15 (Phase D1)",
    "note": "Likely a genuine temporal change (CGTMSE's ceiling has been raised in real-world "
            "policy over time) rather than an extraction error, but this script does not "
            "overwrite either value on that assumption -- flagged for human review per this "
            "phase's explicit instruction to reject on source conflict rather than resolve by "
            "tier priority. content.maxCoverInr is left at its Phase D1 value (Rs 10 crore, "
            "tier 5) UNCHANGED by this script.",
}]
bump(r); changed.append(r["identity"]["id"])

# ---------------------------------------------------------------------
catalog["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()
catalog["metadata"].pop("updatedAt", None)  # keep envelope keys exactly matching validate_base.py's MD list

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed records:", changed, f"({len(changed)} total)")
