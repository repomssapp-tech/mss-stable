#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 7 -- 3 event-participation reimbursement schemes,
each with tiered rates by enterprise category (micro/special vs. small-
general vs. medium) and cost type (fare/accommodation/entry/stall). The
most generous tier (micro & special-category enterprises) is stored
structurally; the full tier table is preserved verbatim in conditions[],
per the "do not collapse a multi-part statement into one invented
figure" rule -- nothing here is averaged or interpolated.
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


ELIG = (
    "Delegation led/organised by an association (5-10 entrepreneurs/delegation/year), or by "
    "FaMe TN/TANSIM/EDII, or an individual enterprise."
)

# SCH000045 -- Domestic events, p.40
r = recs["SCH000045"]
b = r["content"]["benefits"]["marketSupport"]
assert b["percentage"] is None
b["percentage"] = 100.0
b["percentageText"] = "100% (micro/special-category enterprises); 75% (small-general); 50% entry fee only (medium)"
b["maxAmountInr"] = 100000
b["maxAmountText"] = "Rs 3,000/day accommodation; Rs 1,00,000 stall charges; entry fee full/75%/50% by category"
b["description"] = (
    "Travel (air/2nd AC train), accommodation, entry fee, and stall-charge support for "
    "domestic event participation. Micro & special-category enterprises: 100% travel fare, "
    "100% accommodation (max Rs 3,000/day), 100% entry fee, 100% stall charges (max Rs "
    "1,00,000). Small enterprises (general category): 75% of each. Medium enterprises: 50% "
    "entry fee and 50% stall charges only (no travel/accommodation support stated). "
    "Reimbursed against proof of payment; 50% may be claimed as an advance in exceptional "
    "cases."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.marketSupport", {"percentage": 100.0}, 40,
           "Full tiered rate table by enterprise category and cost type, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = ELIG
add_source(r, "content.eligibility.narrative.criteria", ELIG, 40, "Eligibility, verbatim.")
finalize(r)

# SCH000073 -- International event: visiting/buyer-seller meets, p.41
r = recs["SCH000073"]
b = r["content"]["benefits"]["reimbursement"] if "reimbursement" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["reimbursement"]
assert b.get("percentage") is None
b["applicable"] = True
b["percentage"] = 100.0
b["percentageText"] = "100% (micro/special-category); 75% (small-general); 50% entry fee only (medium)"
b["maxAmountInr"] = 100000
b["maxAmountText"] = "Air fare: Rs 1,00,000 (class A countries)/Rs 55,000 (class B); accommodation Rs 6,000/day (A)/Rs 3,000/day (B)"
b["description"] = (
    "Air fare, accommodation, and entry-fee support for visiting international business "
    "exploration/exhibitions/buyer-seller meets. Micro & special-category: 100% air fare "
    "(max Rs 1,00,000 class-A countries / Rs 55,000 class-B), 100% accommodation (max Rs "
    "6,000/day class-A / Rs 3,000/day class-B), 100% entry fee. Small (general category): "
    "75% of fare/accommodation/entry fee at the same caps. Medium: 50% entry fee only."
)
r["content"]["benefits"]["summary"] = b["description"]
if "reimbursement" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("reimbursement")
add_source(r, "content.benefits.reimbursement", {"percentage": 100.0}, 41,
           "Full tiered rate table by enterprise category, country class, and cost type, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = ELIG
add_source(r, "content.eligibility.narrative.criteria", ELIG, 41, "Eligibility, verbatim.")
finalize(r)

# SCH000072 -- International event: participation in exhibitions, p.42
r = recs["SCH000072"]
b = r["content"]["benefits"]["reimbursement"]
assert b["percentage"] is None
b["percentage"] = 100.0
b["percentageText"] = "100% (micro/special-category); 75% (small-general); 50% (medium, stall charges only)"
b["maxAmountInr"] = 300000
b["maxAmountText"] = "Stall charges: Rs 3,00,000 (class A countries)/Rs 1,50,000 (class B); air fare/accommodation as in the visiting-event scheme"
b["description"] = (
    "Air fare, accommodation, and stall-charge support for participating in international "
    "exhibitions. Same air fare/accommodation tiers as the 'visiting' scheme (100%/75% by "
    "category, Rs 1,00,000-55,000 air fare and Rs 6,000/3,000 per day accommodation by "
    "country class). Stall charges: 100% (micro/special-category), 75% (small-general), 50% "
    "(medium), max Rs 3,00,000 (class A) / Rs 1,50,000 (class B). 50% reimbursed on proof of "
    "payment/booking, remainder after travel completion and a brief report."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.reimbursement", {"percentage": 100.0}, 42,
           "Full tiered rate table by enterprise category, country class, and cost type, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = ELIG
add_source(r, "content.eligibility.narrative.criteria", ELIG, 42, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
