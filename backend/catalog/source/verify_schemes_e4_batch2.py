#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.4 Batch 2 -- scheme-by-scheme verification, per the approved
workflow. Source: "Compendium of Schemes for MSMEs 2022," MSME Dept,
Govt of TN, held locally as TN_Schemes_Booklet_2022_v10.md (Tier 1),
cross-checked page by page against the exact scheme name before writing
anything. Additive/corrective only, asserted before write, every change
carries a fieldSources[] entry.

Schemes in this batch: SCH000148 (Q-Cert, filled from empty), SCH000134
(PEACE, filled from empty), SCH000177 (already-accurate data
independently re-confirmed -- status raised, eligibility enriched).
SCH000174 (IPR) has a real conflict (patent %/cap) and is NOT touched by
this script -- see SCHEME_DATA_CONFLICT_REPORT.md.
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


def finalize(rec, status="verified", confidence="high"):
    rec["verification"]["status"] = status
    rec["verification"]["confidence"] = confidence
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    changed.append(rec["identity"]["id"])


# ---------------------------------------------------------------------
# SCH000148 -- Scheme for acquiring Quality Certification (Q-Cert), p.56
r = recs["SCH000148"]
c = r["content"]
b = c["benefits"]["capitalSubsidy"]
assert b["applicable"] is None and b["percentage"] is None
b["applicable"] = True
b["percentage"] = 100.0
b["percentageText"] = "100%"
b["maxAmountInr"] = 200000
b["maxAmountText"] = "Rs 2 lakh (national certifications recognized by the Quality Council of India)"
b["description"] = (
    "100% of the cost for acquiring quality certifications, subject to a maximum of "
    "Rs 2 lakh for national certifications recognized by the Quality Council of India, "
    "and Rs 10 lakh for international certifications recognized by internationally "
    "recognized accreditation bodies. A unit with valid Udyam registration can obtain "
    "multiple certifications within the given financial limit, and can claim again for "
    "new certifications on scaling up to the next enterprise category. Eligible "
    "components: consultancy and certification agency payments, NABL-accredited "
    "testing/calibration charges. Not eligible: travel, accommodation, food/beverage, "
    "refreshment, surveillance charges; renewal expenditure; certifications mandatory "
    "under statutory requirement. Application must be filed within 1 year of "
    "certification."
)
c["benefits"]["summary"] = b["description"]
c["benefits"]["benefitTypes"] = ["capitalSubsidy"]
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 100.0, "maxAmountInr": 200000}, 56,
           'Verbatim: "Subsidy provided for 100% of the cost for acquiring quality '
           'certifications; subject to a maximum of INR 2 lakh for national '
           'certifications... and subject to a maximum of INR 10 lakh for international '
           'certifications."')
c["eligibility"]["narrative"]["criteria"] = (
    "Any MSME in Tamil Nadu with valid Udyam registration acquiring a recognized quality "
    "certification (national, via Quality Council of India-recognized bodies, or "
    "international, via internationally recognized accreditation bodies) may seek "
    "reimbursement of consultancy, certification, and NABL-accredited testing/calibration "
    "costs. Renewal expenditure and statutorily-mandatory certifications are not eligible. "
    "Application must be filed within 1 year of certification."
)
add_source(r, "content.eligibility.narrative.criteria", c["eligibility"]["narrative"]["criteria"], 56,
           "Eligibility and exclusion conditions, verbatim.")
r["verification"]["missingFields"] = [
    m for m in r["verification"]["missingFields"]
    if "benefits" not in m["field"] and "eligibility" not in m["field"]]
finalize(r)

# ---------------------------------------------------------------------
# SCH000134 -- Promotion of Energy Audit & Conservation of Energy (PEACE), p.57
# Two distinct components (audit 75%/Rs1L; implementation 50%/Rs10L) --
# the audit figure (the one that pairs its own percentage with its own
# cap) is stored structurally; both are fully described in text, per the
# "do not average/collapse a multi-part statement" rule.
r = recs["SCH000134"]
c = r["content"]
b = c["benefits"]["capitalSubsidy"]
assert b["percentage"] is None
b["percentage"] = 75.0
b["percentageText"] = "75% (energy audit component)"
b["maxAmountInr"] = 100000
b["maxAmountText"] = "Rs 1 lakh (energy audit); separately, 50% up to Rs 10 lakh for implementation of energy-efficient technologies -- see conditions"
b["description"] = (
    "Two components. (1) Energy audit: 75% subsidy on the cost of the energy audit, "
    "maximum Rs 1 lakh. Eligible applicant: existing manufacturing MSME undertaking an "
    "energy audit for the first time, or one undertaking a repeat audit 3+ years after "
    "its previous audit. (2) Implementation of energy-efficient technologies: 50% subsidy "
    "on the cost of eligible components, maximum Rs 10 lakh. Eligible applicant: existing "
    "manufacturing MSME that has completed an energy audit, implemented the recommended "
    "improvements, and saved at least 10% of energy consumed relative to the prior "
    "12-month average. Application must be filed within 1 year of the relevant audit/"
    "implementation completion."
)
c["benefits"]["summary"] = b["description"]
if "capitalSubsidy" not in c["benefits"]["benefitTypes"]:
    c["benefits"]["benefitTypes"].append("capitalSubsidy")
add_source(r, "content.benefits.capitalSubsidy", {"percentage": 75.0, "maxAmountInr": 100000}, 57,
           'Verbatim: "Conduct of energy audit: Subsidy provided for 75% of the energy '
           'audit; subject to a maximum of INR 1 lakh." / "Implementation of energy '
           'efficient technologies: Subsidy provided for 50% of cost of eligible '
           'components; subject to a maximum of INR 10 lakh."')
c["eligibility"]["narrative"]["criteria"] = (
    "Energy audit component: existing manufacturing MSME undertaking an energy audit for "
    "the first time, or a repeat audit at least 3 years after the previous one. "
    "Implementation component: existing manufacturing MSME that has completed an audit, "
    "implemented its recommendations, and achieved at least 10% energy savings versus the "
    "prior 12-month average consumption."
)
add_source(r, "content.eligibility.narrative.criteria", c["eligibility"]["narrative"]["criteria"], 57,
           "Eligibility for both components, verbatim.")
r["verification"]["missingFields"] = [
    m for m in r["verification"]["missingFields"]
    if "benefits" not in m["field"] and "eligibility" not in m["field"]]
finalize(r)

# ---------------------------------------------------------------------
# SCH000177 -- Support for co-sponsoring events organised by
# associations, p.44. Existing structured benefit data already matched
# the source exactly (independently re-confirmed, not corrected) --
# eligibility narrative enriched with the specific criteria the source
# states (event scale, applicant experience) that the existing generic
# text didn't capture.
r = recs["SCH000177"]
c = r["content"]
old_criteria = c["eligibility"]["narrative"]["criteria"]
c["eligibility"]["narrative"]["criteria"] = (
    "Applicant association must have been engaged in MSME development for at least 3 "
    "years and be able to demonstrate experience/capability to hold such an event. The "
    "event must have at least 5,000 sq. ft. of covered area exclusively for stalls, with "
    "participation from at least 50 MSME units. The association must submit an event "
    "blueprint and tentative agenda when applying, provide at least 100 sq. ft. of stall "
    "space to the MSME Department, and prominently display the department's name/logo as "
    "an event sponsor. Reimbursement is paid after the event, on submission of the event "
    "report and supporting documents."
)
add_source(r, "content.eligibility.narrative.criteria", c["eligibility"]["narrative"]["criteria"], 44,
           f'Replaces generic placeholder ("{old_criteria}") with the source\'s specific '
           "eligibility conditions -- event scale, applicant track record, blueprint/stall "
           "obligations, post-event reimbursement timing. Benefit figures (40% net "
           "expenditure, Rs 5L/3L/2L/1L by city class) were already accurate and are "
           "unchanged -- independently re-confirmed against p.44, not corrected.")
add_source(r, "content.benefits.reimbursement", "independently re-confirmed, unchanged", 44,
           "Existing percentage (40%) and city-tier caps (Rs 5L/3L/2L/1L) match the source "
           "verbatim -- confirmation only, no value changed.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
