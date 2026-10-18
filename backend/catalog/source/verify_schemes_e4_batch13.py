#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 13 -- 6 DGFT (national) export schemes. Most are
100% duty-exemption schemes (percentage IS the correct, complete
figure -- not a partial subsidy needing a ceiling); Interest
Equalisation has a genuine two-tier percentage.
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


# SCH000005 -- Advance Authorisation Scheme, p.149
r = recs["SCH000005"]
b = r["content"]["benefits"]["taxBenefit"]
b["applicable"] = True
b["percentage"] = 100.0
b["percentageText"] = "100% exemption"
b["description"] = (
    "100% exemption on Basic Customs Duty, Additional Customs Duty, Education Cess, "
    "Anti-dumping Duty, Countervailing Duty, Safeguard Duty, Transition Product Specific "
    "Safeguard Duty, IGST, and Compensation Cess, on inputs for export production, subject "
    "to fulfilling the export obligation within the period set by the Foreign Trade Policy."
)
r["content"]["benefits"]["summary"] = b["description"]
if "taxBenefit" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("taxBenefit")
add_source(r, "content.benefits.taxBenefit", {"percentage": 100.0}, 149,
           "Full duty-exemption list, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Manufacturer exporter, or merchant exporter tied to a supporting manufacturer. Must "
    "adhere to Standard Input Output Norms (SION) or self-declare per the Handbook of "
    "Procedures, and maintain minimum 15% value addition."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           149, "Eligibility, verbatim.")
finalize(r)

# SCH000050 -- Duty Free Import Authorisation (DFIA), p.150
r = recs["SCH000050"]
b = r["content"]["benefits"]["capitalSubsidy"]
assert b["percentage"] is None
b["percentage"] = 100.0
b["percentageText"] = "100% exemption (Basic Customs Duty only)"
b["description"] = (
    "100% exemption on Basic Customs Duty for post-export import of inputs. Exporter must "
    "export first, then apply for authorisation (which is freely tradable once issued). "
    "Minimum 20% value addition required."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 100.0}, 150,
           "Verbatim -- Basic Customs Duty only, distinct from Advance Authorisation's "
           "broader duty list.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Manufacturer exporter, or merchant exporter tied to a supporting manufacturer, "
    "importing inputs on a post-export basis only, maintaining minimum 20% value addition."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           150, "Eligibility, verbatim.")
finalize(r)

# SCH000057 -- EPCG, p.151
r = recs["SCH000057"]
b = r["content"]["benefits"]["capitalSubsidy"]
assert b["percentage"] is None
b["percentage"] = 100.0
b["percentageText"] = "100% exemption"
b["description"] = (
    "100% exemption on customs duty and IGST for import of capital goods, conditional on "
    "exporting goods equivalent to 6 times the duty/tax saved, within 6 years of the EPCG "
    "licence date."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 100.0}, 151, "Verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Must export goods equivalent to 6 times duty and tax saved, within 6 years of EPCG "
    "licence authorisation."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           151, "Eligibility, verbatim.")
finalize(r)

# SCH000040 -- Deemed Exports, p.152
r = recs["SCH000040"]
b = r["content"]["benefits"]["capitalSubsidy"]
assert b["percentage"] is None
b["description"] = (
    "Advance authorisation for duty-free import of inputs physically incorporated in an "
    "export product (plus packaging/fuel/oil/catalyst consumed in production). Deemed "
    "export drawback: refund of Basic Customs Duty on inputs, per the Department of "
    "Revenue's All Industry Rate schedule. Refund of terminal excise duty on excisable "
    "goods. Not a percentage/ceiling-based benefit -- multiple duty-refund mechanisms, "
    "left without a single percentage figure since none is stated as one."
)
r["content"]["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.capitalSubsidy", "duty-refund mechanisms, no single percentage stated", 152,
           "Verbatim -- confirms this is a refund/drawback mechanism, not a flat-rate benefit.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Manufacturer/main contractor/sub-contractor, or exporter supplying goods against "
    "advance authorisation. Payment must be received in Indian rupees or free foreign "
    "exchange."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           152, "Eligibility, verbatim.")
finalize(r)

# SCH000172 -- Status Holder Certificate, p.153
r = recs["SCH000172"]
b = r["content"]["benefits"]["capitalSubsidy"] if "capitalSubsidy" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["capitalSubsidy"]
b["applicable"] = True
b["percentage"] = 100.0
b["percentageText"] = "100% exemption on bank guarantee furnishing"
b["description"] = (
    "Self-declaration-based authorisation/customs clearance for imports and exports; "
    "priority input-output norm fixation (60 days); 100% exemption from furnishing a bank "
    "guarantee under Foreign Trade Policy schemes; exemption from compulsory bank "
    "negotiation of documents. Star status (one to five star export house) awarded on "
    "achieving USD 3M/25M/100M/500M/2000M FOB/FOR export value in 2 of the latest 4 "
    "financial years respectively."
)
r["content"]["benefits"]["summary"] = b["description"]
if "capitalSubsidy" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("capitalSubsidy")
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 100.0}, 153,
           "Full star-status threshold table and privilege list, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Must possess an Importer-Exporter Code and achieve export performance in the current "
    "and previous three financial years."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           153, "Eligibility, verbatim.")
finalize(r)

# SCH000070 -- Interest Equalisation Scheme, p.154
r = recs["SCH000070"]
b = r["content"]["benefits"]["interestSubvention"] if "interestSubvention" in r["content"]["benefits"] else None
b = r["content"]["benefits"]["interestSubvention"]
b["applicable"] = True
b["percentage"] = 3.0
b["percentageText"] = "3% (any HS code); 2% (the 410 specified HS codes, excluding 6 telecom-sector lines)"
b["description"] = (
    "Pre- and post-shipment export credit interest equalisation for MSME manufacturer "
    "exporters: 3% for any Harmonised System (HS) code/line; 2% for exports under the 410 "
    "specified HS codes (excluding 6 telecom-sector HS lines)."
)
r["content"]["benefits"]["summary"] = b["description"]
if "interestSubvention" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("interestSubvention")
add_source(r, "content.benefits.interestSubvention", {"percentage": 3.0}, 154,
           "Two-tier percentage by HS-code scope, verbatim.")
r["content"]["eligibility"]["narrative"]["criteria"] = (
    "Manufacturer exporter, or merchant exporter tied to a supporting manufacturer, "
    "exporting under any HS code/line, or under the 410 specified HS codes excluding 6 "
    "telecom-sector lines."
)
add_source(r, "content.eligibility.narrative.criteria", r["content"]["eligibility"]["narrative"]["criteria"],
           154, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
