#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 9. Includes a near-miss caught before writing:
SCH000046 ("Domestic Market Promotion Scheme") looked like a title match
for the booklet's p.96 entry of the same name, but SCH000046's own
overview identifies it as a SPICES BOARD scheme, while p.96 is a COIR
BOARD scheme -- a name collision, not the same scheme. NOT touched.
Instead, the coir domestic-promotion data is added to SCH000033 (Coir
Vikas Yojana, the umbrella record), as an additional benefit component,
since no dedicated coir-domestic-promotion scheme record exists to hold
it and the umbrella record already covers other Coir Vikas sub-components
the same way.
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


# SCH000089 -- MPDA (khadi), p.94
r = recs["SCH000089"]
b = r["content"]["benefits"]["marketSupport"]
assert b["percentage"] is None and "not inserted" in b["description"]
b["applicable"] = True
b["percentage"] = 30.0
b["percentageText"] = "30% (Modified Market Development Assistance component)"
b["description"] = (
    "Grant/subsidy for construction of khadi plazas. Modified Market Development Assistance "
    "(MMDA): 30% of the prime cost of khadi (cotton, silk, woollen) and polyvastra, claimed "
    "quarterly by the producing institution from KVIC and distributed 40% (spinners/"
    "weavers) / 20% (producing institutions) / 40% (selling institutions)."
)
b["modalities"] = ["grant", "market_development_assistance"]
b["durationText"] = "Quarterly claim, adjusted in the final quarter against audited accounts"
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.marketSupport", "30% MMDA + khadi plaza grant", 94,
           'Verbatim: "Modified Market Development Assistance (MMDA) provided at the rate of '
           '30% on the prime cost of khadi... and polyvastra."')
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Khadi institution with a valid khadi certificate, categorised A+/A/B/C."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           94, "Eligibility, verbatim.")
finalize(r)

# SCH000033 -- Coir Vikas Yojana (umbrella), p.96. Adds the domestic
# market-promotion component (marketSupport) alongside the record's
# existing trainingSupport component -- this schema's marketSupport
# sub-object has no percentage/maxAmountInr fields, so the figure is
# recorded in description/conditions instead.
r = recs["SCH000033"]
b = r["content"]["benefits"]["marketSupport"]
assert b["description"] is None
b["applicable"] = True
b["description"] = (
    "Domestic Market Promotion Scheme component: market development assistance at 10% of "
    "average annual sales turnover of coir products (including coir yarn and rubberised "
    "coir goods) over the preceding 3 financial years, shared equally between central and "
    "state government. Central-share disbursement is subject to Coir Board's available "
    "budgetary outlay."
)
b["modalities"] = ["market_development_assistance"]
b["conditions"] = [
    "Eligible applicants: apex societies, central co-operative societies, primary "
    "co-operatives, public sector enterprises, or Coir Board showrooms/sales depots.",
]
r["content"]["benefits"]["benefitTypes"] = list(set(r["content"]["benefits"]["benefitTypes"] + ["marketSupport"]))
add_source(r, "content.benefits.marketSupport", "10% of average annual turnover, central/state shared", 96,
           'Verbatim: "market development assistance is provided at the rate of 10% of '
           'their average annual sales turnover of coir products... during the preceding 3 '
           'financial years."')
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
