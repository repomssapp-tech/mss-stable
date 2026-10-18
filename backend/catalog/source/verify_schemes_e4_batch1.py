#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 -- live verification batch against official sources already
on file for each scheme (msmeonline.tn.gov.in). Each write is additive
(assert-checked before write) and carries a fieldSources[] provenance
entry with url/retrievedAt/sourceTier. verification.status is only ever
raised to 'verified' when the field this scheme's summary/benefit text
actually depends on was itself confirmed against the live page -- not
raised blindly."""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
URL = "https://msmeonline.tn.gov.in/incentives/html_cye_CS.php"
ORG = "MSME Department, Government of Tamil Nadu"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []

# SCH000166 -- Special Capital Subsidy for Thrust Sector Enterprises.
r = recs["SCH000166"]
b = r["content"]["benefits"]["capitalSubsidy"]
assert b["percentage"] is None and b["maxAmountInr"] is None
b["percentage"] = 25.0
b["percentageText"] = "25%"
b["maxAmountInr"] = 15000000
b["maxAmountText"] = "Rs 150 lakh"
b["description"] = (
    "25% capital subsidy on the value of eligible plant and machinery, subject to a "
    "maximum of Rs 150 lakh, for new small and medium enterprises in Tamil Nadu's 24 "
    "designated thrust sectors (electrical/electronics, leather goods, auto parts, "
    "pharmaceuticals, solar equipment, gold/diamond jewellery, pollution control "
    "equipment, EV components, cost-effective building material, readymade garments, "
    "food processing, plastic, rubber, biotechnology, petrochemicals/specialty "
    "chemicals, medical devices, sports goods, technical textiles, aerospace/defence, "
    "electronic system design and manufacturing, single-use-plastic alternates, "
    "e-waste processing, Industry 4.0, and traditional industries)."
)
r["content"]["benefits"]["summary"] = b["description"]
r["provenance"].setdefault("fieldSources", []).append({
    "field": "content.benefits.capitalSubsidy",
    "value": {"percentage": 25.0, "maxAmountInr": 15000000},
    "sourceTier": 5,
    "sourceType": "official_website",
    "organization": ORG,
    "url": URL,
    "retrievedAt": RETRIEVED_AT,
    "isBackfill": True,
    "supersededValue": None,
    "note": ('Verbatim: "25% capital subsidy on the value of eligible plant and machinery, '
             'subject to a maximum of Rs.150.00 lakh," confirmed as the thrust-sector rate '
             "(24 named sectors, matching this scheme's own name) on a second, targeted "
             "fetch of the same page already used for SCH000028's identical base rate. "
             "NOTE FOR HUMAN REVIEW: this is the same G.O./circular and the same 25%/Rs150 "
             "lakh figure as SCH000028 ('Capital Subsidy') -- the two may be the same "
             "government scheme catalogued twice under different names in the original "
             "source spreadsheet (TN028 vs TN166), or may be genuinely distinct "
             "general-vs-thrust-sector provisions of one G.O. Not merged or deduplicated by "
             "this script, since resolving that requires the original G.O. document, not "
             "just this summary page."),
})
r["verification"]["missingFields"] = [
    m for m in r["verification"]["missingFields"] if "capitalSubsidy" not in m["field"]]
r["verification"]["status"] = "verified"
r["verification"]["verifiedAgainst"] = list(set(r["verification"].get("verifiedAgainst", []) + ["SCH000166-SRC001"]))
r["verification"]["verifiedAt"] = RETRIEVED_AT
r["verification"]["confidence"] = "high"
r["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
r["metadata"]["revision"] += 1
changed.append("SCH000166")


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
