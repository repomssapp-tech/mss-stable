#!/usr/bin/env python3
"""Phase D1 — Financial Enrichment.

Applies ONLY tier-5 verified findings from official approved-domain sources
(MSS_Data_Completion_Policy_v1.0.md Sec 4.3), confirmed live 2026-08-15.
Every write is additive (fills a null), never overwrites, and carries a
fieldSources[] provenance entry with url + retrievedAt per policy Sec 6.

Two records verified this round:

  FIN000075 (PM Vishwakarma loan) <- https://pmvishwakarma.gov.in/
  FIN000026 (CGTMSE credit guarantee) <- https://www.cgtmse.in/

All other loan/guarantee/subvention records were checked against their
applicationUrl (where it fell on an approved domain) and no new verifiable
figure was found beyond what the record already states -- see
FINANCIAL_ENRICHMENT_REPORT.md for the per-record account. No field is
touched for those records.
"""
import json
from copy import deepcopy

PATH = "finance_catalog.json"
RETRIEVED_AT = "2026-08-15"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)

recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed_ids = []


def add_field_source(rec, field, value, url, org, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field,
        "value": value,
        "sourceTier": 5,
        "sourceType": "official_website",
        "organization": org,
        "url": url,
        "retrievedAt": RETRIEVED_AT,
        "isBackfill": True,
        "supersededValue": None,
        "note": note,
    })


def remove_missing_field(rec, field):
    mf = rec["verification"].get("missingFields", [])
    rec["verification"]["missingFields"] = [m for m in mf if m["field"] != field]


# ---------------------------------------------------------------------------
# FIN000075 — PM Vishwakarma loan. https://pmvishwakarma.gov.in/, fetched
# 2026-08-15: "Concessional Rate of Interest: 5% to be charged from the
# beneficiary with Interest Subvention cap of 8%"; "Collateral free Enterprise
# Development Loans"; first tranche Rs 1 lakh / 18 months, second tranche
# Rs 2 lakh / 30 months; "Credit Guarantee fees to be borne by GoI".
# ---------------------------------------------------------------------------
r = recs["FIN000075"]
before = deepcopy(r)
c = r["content"]

assert c["interestRate"]["percent"] is None, "must be a gap-fill, not overwrite"
c["interestRate"]["percent"] = 5.0
c["interestRate"]["text"] = (
    "5% p.a. concessional rate charged to beneficiary; Government of India "
    "bears the balance up to an 8% interest subvention cap."
)
add_field_source(
    r, "content.interestRate", c["interestRate"],
    "https://pmvishwakarma.gov.in/", "Ministry of Micro, Small & Medium Enterprises",
    'Verbatim: "Concessional Rate of Interest: 5% to be charged from the '
    'beneficiary with Interest Subvention cap of 8%."',
)
remove_missing_field(r, "content.interestRate")

assert c["tenure"] == {"durationMonths": None, "tenureMonths": None, "moratoriumMonths": None}
c["tenure"]["tenureMonths"] = 18
c["tenure"]["moratoriumMonths"] = None
add_field_source(
    r, "content.tenure", {"tenureMonths": 18},
    "https://pmvishwakarma.gov.in/", "Ministry of Micro, Small & Medium Enterprises",
    "First enterprise-development-loan tranche (Rs 1 lakh) carries an "
    "18-month repayment period; a second tranche of Rs 2 lakh at 30 months "
    "is available on repayment of the first (recorded as a condition, not "
    "the tenure default, since it is conditional on the first tranche).",
)
remove_missing_field(r, "content.tenure")

assert c["amount"]["minInr"] is None and c["amount"]["maxInr"] is None
c["amount"]["minInr"] = 100000
c["amount"]["minText"] = "Rs 1 lakh (first tranche)"
c["amount"]["maxInr"] = 200000
c["amount"]["maxText"] = "Rs 2 lakh (second tranche, on repayment of the first)"
add_field_source(
    r, "content.amount", {"minInr": 100000, "maxInr": 200000},
    "https://pmvishwakarma.gov.in/", "Ministry of Micro, Small & Medium Enterprises",
    "First tranche Rs 1 lakh / 18 months; second tranche Rs 2 lakh / 30 "
    "months, conditional on repayment of the first.",
)

assert c["conditions"] == []
c["conditions"] = [
    "Second loan tranche (Rs 2 lakh) is released only after satisfactory "
    "repayment of the first tranche (Rs 1 lakh).",
    "Credit guarantee fee for the loan is borne by the Government of India, "
    "not the beneficiary.",
]
add_field_source(
    r, "content.conditions", c["conditions"],
    "https://pmvishwakarma.gov.in/", "Ministry of Micro, Small & Medium Enterprises",
    "Verbatim tranche-sequencing and guarantee-fee conditions from the "
    "official scheme page.",
)

r["metadata"]["updatedAt"] = "2026-08-15T00:00:00Z"
r["metadata"]["revision"] += 1
r["provenance"]["transformationNotes"].append(
    "Phase D1 (2026-08-15): interestRate, tenure, amount range and "
    "conditions filled from https://pmvishwakarma.gov.in/ (tier 5, "
    "approved domain). Additive only -- no prior value overwritten."
)
changed_ids.append("FIN000075")

# ---------------------------------------------------------------------------
# FIN000026 — CGTMSE credit guarantee. https://www.cgtmse.in/, fetched
# 2026-08-15: guarantee ceiling raised to Rs 10 crore; "Reduced the guarantee
# fee to a minimum level of 0.37% pa"; guarantee cover is for "collateral
# and/or third party guarantee free credit facilities". Coverage PERCENTAGE
# (e.g. 75/85%) is not stated on the fetched page -- left null, recorded as
# a gap, not guessed from category tables not shown on the page.
# ---------------------------------------------------------------------------
r = recs["FIN000026"]
c = r["content"]

assert c["maxCoverInr"] is None
c["maxCoverInr"] = 100000000  # Rs 10 crore
add_field_source(
    r, "content.maxCoverInr", 100000000,
    "https://www.cgtmse.in/", "Credit Guarantee Fund Trust for Micro and Small Enterprises",
    'Verbatim: guarantee ceiling "increased to Rs 10 crore" (special '
    "announcement banner, live page).",
)
remove_missing_field(r, "content.maxCoverInr")

assert c["feePercent"] is None
c["feePercent"] = 0.37
add_field_source(
    r, "content.feePercent", 0.37,
    "https://www.cgtmse.in/", "Credit Guarantee Fund Trust for Micro and Small Enterprises",
    'Verbatim: "Reduced the guarantee fee to a minimum level of 0.37% pa." '
    "Recorded as a minimum/floor rate, not a flat rate -- actual fee can be "
    "higher depending on loan slab and category; coveragePercent itself is "
    "not stated on the fetched page and is left null (see missingFields).",
)
remove_missing_field(r, "content.feePercent")

r["verification"]["missingFields"].append({
    "field": "content.coveragePercent",
    "reason": "Fetched page (cgtmse.in) states the fee floor and the Rs 10 "
              "crore ceiling but does not state a guarantee coverage "
              "percentage; the CGS-I scheme document (not fetched this "
              "round) would be the tier-1/tier-5 source for that figure.",
})

r["metadata"]["updatedAt"] = "2026-08-15T00:00:00Z"
r["metadata"]["revision"] += 1
r["provenance"]["transformationNotes"].append(
    "Phase D1 (2026-08-15): maxCoverInr and feePercent filled from "
    "https://www.cgtmse.in/ (tier 5, approved domain). coveragePercent "
    "remains null -- not stated on the fetched page, recorded as a gap "
    "rather than estimated from category tables not shown there."
)
changed_ids.append("FIN000026")

# ---------------------------------------------------------------------------
catalog["metadata"]["updatedAt"] = "2026-08-15T00:00:00Z"

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed records:", changed_ids)
