#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 10 -- 5 KVIC/Coir Board skill-development schemes.
These are genuinely non-monetary (training/equipment-in-kind, not a
percentage subsidy or loan) -- benefit sub-object percentage/maxAmountInr
fields are correctly left null; the actual content goes into
trainingSupport's description/conditions fields, matching what the
source states.
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


def set_training(rec, desc, elig, page, quote):
    c = rec["content"]
    b = c["benefits"]["trainingSupport"]
    b["applicable"] = True
    b["description"] = desc
    c["benefits"]["summary"] = desc
    if "trainingSupport" not in c["benefits"]["benefitTypes"]:
        c["benefits"]["benefitTypes"].append("trainingSupport")
    add_source(rec, "content.benefits.trainingSupport", desc[:80], page, quote)
    c["eligibility"]["narrative"]["criteria"] = elig
    add_source(rec, "content.eligibility.narrative.criteria", elig, page, "Eligibility, verbatim.")
    finalize(rec)


# SCH000125 -- Pottery Activity GVY, p.119
set_training(
    recs["SCH000125"],
    "Skill development for SHG artisans (garden pots, khullad, decorative products). "
    "Assistance to set up a unit under PMEGP after training; market-linkage support "
    "(export/large buying houses); support for new-product/raw-material innovation.",
    "Artisan aged 18-55. Preference to those previously trained/engaged in the activity; "
    "minimum 50% of places reserved for SC/ST/women/BPL candidates. Non-pottery artisans "
    "may be selected for press-pottery/jigger-jolly training.",
    119, 'Verbatim benefit and eligibility detail, including the 50% SC/ST/women/BPL reservation.')

# SCH000019 -- Beekeeping Activity GVY, p.120
set_training(
    recs["SCH000019"],
    "5-day beekeeping training (scientific bee management, natural-resource utilisation, "
    "sustainable/supplementary income). One person per family eligible for 10 bee boxes "
    "with bee colonies and a tool kit (veil, smoker, knife, hive tool).",
    "Age 18-55, with Aadhaar/voter ID. Not eligible if already benefited from a similar "
    "government scheme (self-declaration required). Persons already trained by KVIC/KVIB/"
    "NABARD/Krishi Vigyan Kendra/agri-horti boards/eligible beekeeping NGOs are eligible "
    "for the bee-box/tool-kit support.",
    120, "Verbatim benefit (10 bee boxes/family) and eligibility detail.")

# SCH000006 -- Agarbatti Making Project GVY, p.121
set_training(
    recs["SCH000006"],
    "10-day free agarbatti skill-upgradation training (20 candidates/batch), with "
    "manufacturing machines and raw material provided. One person/family for pedal-"
    "operated machines; two persons/family for SHG automatic-machine activity.",
    "Artisan aged 18-55 with Aadhaar/voter ID and ration card. Not eligible if already "
    "benefited from a similar government scheme. Preference to artisans working with "
    "Khadi Village Institutes for agarbatti production; for SHGs, all members are trained.",
    121, "Verbatim training structure and machine-eligibility detail.")

# SCH000035 -- Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana, p.122.
# Already has good description text; enriches with the R&D-institute
# incubation detail and confirms eligibility.
r = recs["SCH000035"]
r["content"]["eligibility"]["narrative"]["criteria"] = "Any existing or aspiring entrepreneur."
add_source(r, "content.eligibility.narrative.criteria", "Any existing or aspiring entrepreneur.",
           122, "Eligibility, verbatim.")
r["content"]["benefits"]["trainingSupport"]["conditions"] = r["content"]["benefits"]["trainingSupport"].get("conditions", []) + [
    "Training is stipendiary. Additional training/incubation/handholding support for "
    "setting up new units is available from the Coir Board's Research and Development "
    "Institutes.",
]
add_source(r, "content.benefits.trainingSupport.conditions", "R&D institute incubation support", 122,
           "Additional detail not previously captured.")
finalize(r)

# SCH000194 -- Trade and Industry Related Functional Support, p.123
r = recs["SCH000194"]
r["content"]["benefits"]["trainingSupport"]["applicable"] = True
r["content"]["benefits"]["trainingSupport"]["description"] = (
    "Statistical surveys and export reports on the coir sector, provided as feedback to "
    "traders and industries. Human Resource Development (HRD) programmes for coir workers "
    "to improve knowledge of modern technology. Non-monetary support service, not a subsidy "
    "or grant."
)
r["content"]["benefits"]["summary"] = r["content"]["benefits"]["trainingSupport"]["description"]
if "trainingSupport" not in r["content"]["benefits"]["benefitTypes"]:
    r["content"]["benefits"]["benefitTypes"].append("trainingSupport")
add_source(r, "content.benefits.trainingSupport", "surveys + HRD programmes, non-monetary", 123,
           "Verbatim -- confirms this is a data/HRD support service, not a monetary benefit.")
r["content"]["eligibility"]["narrative"]["criteria"] = "Coir workers and new entrepreneurs in the coir sector."
add_source(r, "content.eligibility.narrative.criteria", "Coir workers and new entrepreneurs in the coir sector.",
           123, "Eligibility, verbatim.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
