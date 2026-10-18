#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 12 -- 5 Spices Board export-support schemes. All 5
have the same two-tier structure (general category vs. SC/ST/FPO/NE-
Himalayan-region/island-territory exporters, the latter always getting a
higher rate/cap) -- the general-category rate is stored structurally,
the enhanced tier in conditions[], per the "do not collapse a two-tier
statement into one figure" rule.
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


ENHANCED_ELIG = (
    "Enhanced (75%) tier applies to: SC/ST exporters, Farmers Producer Organisation (FPO) "
    "exporters, and exporters in North-East region (incl. Sikkim/Darjeeling), other "
    "Himalayan states/J&K/Ladakh, state-notified Integrated Tribal Development Programme "
    "areas, and Andaman & Nicobar/Lakshadweep."
)

# SCH000135 -- Promotion of Indian Spice Brands Abroad, p.135
r = recs["SCH000135"]
b = r["content"]["benefits"]["reimbursement"]
assert b["percentage"] is None
b["percentage"] = 100.0
b["percentageText"] = "100% (interest-free loan)"
b["maxAmountInr"] = 10000000
b["maxAmountText"] = "Rs 1 crore/exporter"
b["description"] = (
    "Interest-free loan covering 100% of slotting/listing fee, promotion measures, and "
    "product-development cost, max Rs 1 crore/exporter."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.reimbursement", {"percentage": 100.0, "maxAmountInr": 10000000}, 135,
           'Verbatim: "interest free loan covering 100% of slotting/ listing fee and '
           'promotion measures... subject to a maximum of INR 1 crore/exporter."')
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Registered exporter of spices with brand names registered with the Spices Board."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           135, "Eligibility, verbatim.")
finalize(r)

# SCH000121 -- Participation in International fairs (spices), p.136
r = recs["SCH000121"]
b = r["content"]["benefits"]["reimbursement"]
assert b["percentage"] is None
b["percentage"] = 50.0
b["percentageText"] = "50% (general); 75% (SC/ST/FPO/NE-Himalayan/island exporters)"
b["maxAmountInr"] = 150000
b["maxAmountText"] = "Rs 1.5 lakh/year air fare + Rs 5 lakh/year stall rent (general); Rs 2.25L/Rs 7.5L (enhanced tier)"
b["description"] = (
    "50% of air fare (max Rs 1.5 lakh/year) and 50% of stall rent (max Rs 5 lakh/year) for "
    f"general-category exporters. {ENHANCED_ELIG.split(':')[0]}: 75% of air fare (max "
    "Rs 2.25 lakh/year) and 75% of stall rent (max Rs 7.5 lakh/year)."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.reimbursement", {"percentage": 50.0, "maxAmountInr": 150000}, 136,
           "Two-tier air-fare/stall-rent rate structure, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = "Exporter holding a valid export license. " + ENHANCED_ELIG
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           136, "Eligibility, verbatim.")
finalize(r)

# SCH000141 -- CRES fee reimbursement, p.137
r = recs["SCH000141"]
b = r["content"]["benefits"]["reimbursement"]
assert b.get("percentage") is None
b["applicable"] = True
b["percentage"] = 75.0
b["percentageText"] = "75%"
b["maxAmountInr"] = 11250
b["maxAmountText"] = "Rs 11,250"
b["description"] = (
    "75% of the registration charges for a Certificate of Registration as Exporter of "
    "Spices (CRES), excluding GST, max Rs 11,250."
)
r["content"]["benefits"]["summary"] = b["description"]
if "reimbursement" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("reimbursement")
add_source(r, "content.benefits.reimbursement", {"percentage": 75.0, "maxAmountInr": 11250}, 137,
           "Verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Entrepreneur in North-East region (incl. Sikkim/Darjeeling), other Himalayan states/"
    "J&K/Ladakh, state-notified Integrated Tribal Development Programme areas/islands, or "
    "SC/ST exporters and Farmers Producer Organisations nationwide."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           137, "Eligibility, verbatim.")
finalize(r)

# SCH000119 -- Packaging development/Bar Coding/QR/EPC/RFID, p.138
r = recs["SCH000119"]
b = r["content"]["benefits"]["reimbursement"]
assert b.get("percentage") is None
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "50% (general); 75% (SC/ST/FPO/NE-Himalayan/island exporters)"
b["maxAmountInr"] = 150000
b["maxAmountText"] = "Rs 1.5 lakh (general); Rs 2.25 lakh (enhanced tier)"
b["description"] = (
    "50% of packaging development/bar coding/QR code/EPC/RFID/traceability cost, max "
    f"Rs 1.5 lakh, for general-category exporters. {ENHANCED_ELIG.split(':')[0]}: 75%, max "
    "Rs 2.25 lakh."
)
r["content"]["benefits"]["summary"] = b["description"]
if "reimbursement" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("reimbursement")
add_source(r, "content.benefits.reimbursement", {"percentage": 50.0, "maxAmountInr": 150000}, 138,
           "Two-tier rate structure, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Registered exporter with brand names registered with the Spices Board. " + ENHANCED_ELIG
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           138, "Eligibility, verbatim.")
finalize(r)

# SCH000154 -- Sending Business Samples Abroad, p.139
r = recs["SCH000154"]
b = r["content"]["benefits"]["capitalSubsidy"]
assert b["percentage"] is None
b["percentage"] = 50.0
b["percentageText"] = "50% (general); 75% (SC/ST/FPO/NE-Himalayan/island exporters)"
b["maxAmountInr"] = 150000
b["maxAmountText"] = "Rs 1.5 lakh (general); Rs 2.25 lakh (enhanced tier)"
b["description"] = (
    f"50% of courier charges for sending business samples abroad, max Rs 1.5 lakh (general). "
    f"{ENHANCED_ELIG.split(':')[0]}: 75%, max Rs 2.25 lakh."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 50.0, "maxAmountInr": 150000}, 139,
           "Two-tier rate structure, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Registered merchant exporter with annual turnover up to Rs 250 crore (FY 2020-21), or "
    "an MSME exporter. " + ENHANCED_ELIG
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           139, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
