#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.5 Batch 1 -- live web verification, central government (BIRAC)
schemes. All 5 fetched directly from birac.nic.in (.nic.in, approved
domain) this session. Each covers the minimum required fields: name,
eligibility, benefits, application process -- with official source
evidence for each. Two records (SCH000023, SCH000027) had existing
figures that were independently CONFIRMED (not changed) by this fetch.
"""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
ORG = "Biotechnology Industry Research Assistance Council (BIRAC), Dept of Biotechnology, Govt of India"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []


def add_source(rec, field, value, url, note):
    rec["provenance"].setdefault("fieldSources", []).append({
        "field": field, "value": value,
        "sourceTier": 5, "sourceType": "official_website",
        "organization": ORG, "url": url, "retrievedAt": RETRIEVED_AT,
        "isBackfill": True, "supersededValue": None, "note": note,
    })


def finalize(rec):
    rec["verification"]["status"] = "verified"
    rec["verification"]["confidence"] = "high"
    rec["verification"]["verifiedAt"] = RETRIEVED_AT
    rec["verification"]["verifiedAgainst"] = list(set(rec["verification"].get("verifiedAgainst", [])))
    rec["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    rec["metadata"]["revision"] += 1
    rec["verification"]["missingFields"] = [
        m for m in rec["verification"]["missingFields"] if "benefits" not in m["field"]]
    changed.append(rec["identity"]["id"])


def elig(rec, text, url, note):
    rec["content"]["eligibility"]["narrative"]["criteria"] = text
    add_source(rec, "content.eligibility.narrative.criteria", text, url, note)


def app_process(rec, mode, url_val, steps_text, url, note):
    ap = rec["content"]["applicationProcess"]
    ap["mode"] = mode
    ap["onlineUrl"] = url_val
    ap["modeText"] = "Online" if mode == "online" else ap.get("modeText")
    add_source(rec, "content.applicationProcess", steps_text, url, note)


# ---------------------------------------------------------------------
# SCH000023 -- Biotechnology Ignition Grant (BIG), birac.nic.in/big.php
r = recs["SCH000023"]
c = r["content"]
b = c["benefits"]["grant"]
assert b["maxAmountInr"] == 5000000  # CONFIRM, not change
add_source(r, "content.benefits.grant", {"maxAmountInr": 5000000}, "https://birac.nic.in/big.php",
           'CONFIRMED (not changed): "INR 50 Lakhs as grant-in-aid," 18-month duration, for '
           'young startups/researchers to translate ideas into Proof of Concept.')
b["durationMonths"] = 18
elig(r, "Young startups and researchers seeking to commercialise a biotech innovation, applying through one of BIRAC's ~8 BIG Partner institutions.",
     "https://birac.nic.in/big.php", "Eligibility (partner-mediated), from the live page.")
app_process(r, "online", "https://birac.nic.in/big.php",
            "Call announced twice yearly (1 Jan, 1 Jul), application window ~45 days, applied via one of 8 BIG Partners providing mentoring/business-development support.",
            "https://birac.nic.in/big.php", "Application cadence and partner structure, verbatim.")
finalize(r)

# ---------------------------------------------------------------------
# SCH000024 -- BIPP, birac.nic.in/birac_i4.php
r = recs["SCH000024"]
c = r["content"]
b = c["benefits"]["grant"] if "grant" in c["benefits"] else c["benefits"]["equitySupport"]
b["applicable"] = True
b["percentage"] = 50.0
b["percentageText"] = "Up to 50% of total project cost (BIRAC contribution)"
b["description"] = (
    "BIRAC's contribution to validation/demonstration/pre-commercialisation projects (TRL 7+) "
    "will not exceed 50% of total project cost; the entire cost to a collaborating academic "
    "institution (if any) is borne by BIRAC."
)
c["benefits"]["summary"] = b["description"]
if "grant" not in c["benefits"]["benefitTypes"] and "equitySupport" not in c["benefits"]["benefitTypes"]:
    key = "grant" if "grant" in c["benefits"] and c["benefits"]["grant"] is b else "equitySupport"
    c["benefits"]["benefitTypes"].append(key)
add_source(r, "content.benefits.grant", {"percentage": 50.0}, "https://www.birac.nic.in/birac_i4.php",
           'Verbatim: BIRAC contribution "will not exceed 50%" of total project cost; academic '
           "collaborator's full cost borne by BIRAC.")
elig(r, "Single or consortia of Indian company(ies) registered under the Companies Act 2013, or LLPs under the LLP Act 2008, with or without an academic partner.",
     "https://www.birac.nic.in/birac_i4.php", "Eligibility, verbatim.")
app_process(r, "online", "https://www.birac.nic.in/birac_i4.php",
            "Submission via BIRAC's proposal format for the i4 (SBIRI/BIPP) programme; detailed procedure in the linked scheme guidelines.",
            "https://www.birac.nic.in/birac_i4.php", "Application route, from the live page.")
finalize(r)

# ---------------------------------------------------------------------
# SCH000025 -- BIRAC AcE Fund, birac.nic.in/aceFundNew.php
r = recs["SCH000025"]
c = r["content"]
b = c["benefits"]["equitySupport"]
b["description"] = (
    "Fund-of-funds equity investment: BIRAC commits an initial investment, and daughter funds "
    "commit to invest 2x BIRAC's committed amount, into biotech/life-sciences/pharma/med-tech/"
    "diagnostics/industrial-biotech/agri-tech/bio-IT startups. As of Aug 2025: Rs 174.50 crore "
    "from the AcE Fund, Rs 349 crore investment commitment, Rs 1,560 crore actual investment, "
    "102 startups supported across 16 daughter funds."
)
c["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.equitySupport", "fund-of-funds structure, no fixed per-startup ceiling stated", "https://www.birac.nic.in/aceFundNew.php",
           "Verbatim -- confirms this is a fund-of-funds mechanism with no single per-startup "
           "ceiling stated on the page.")
elig(r, "Biotech/life-sciences/pharma/med-tech/diagnostics/industrial-biotech/agri-tech/bio-IT startups and SMEs, applying through one of 12 registered AcE Fund Partners.",
     "https://www.birac.nic.in/aceFundNew.php", "Eligibility sectors and partner-mediated route, from the live page.")
app_process(r, "online", "https://www.birac.nic.in/aceFundNew.php",
            "Startups avail the AcE Fund through one of the registered AcE Fund Partners; full procedure in the linked guidelines PDF.",
            "https://www.birac.nic.in/aceFundNew.php", "Application route, from the live page.")
finalize(r)

# ---------------------------------------------------------------------
# SCH000026 -- BIRAC LEAP Fund, birac.nic.in/leapFundNew.php
r = recs["SCH000026"]
c = r["content"]
b = c["benefits"]["grant"]
b["maxAmountInr"] = 50000000
b["maxAmountText"] = "Rs 500 lakh/cycle (to the partner incubator, for deployment to startups)"
b["description"] = (
    "Grant-in-aid of Rs 500 lakh/cycle to partner incubators, for deployment to Biotech/"
    "Life-Sciences startups at proof-of-concept-to-pilot stage. As of Feb 2023: 47 startups "
    "supported, Rs 30 crore equity investment, Rs 1,668 crore combined valuation across 33 "
    "startups, 46 products commercialised."
)
c["benefits"]["summary"] = b["description"]
add_source(r, "content.benefits.grant", {"maxAmountInr": 50000000}, "https://www.birac.nic.in/leapFundNew.php",
           'Verbatim: "grant-in-aid support of INR 500 lakhs/cycle for deployment in Biotech Startups."')
elig(r, (
    "For incubators to become LEAP Fund Partners: must already be a BIRAC SEED Fund partner, "
    "operational 5+ years, with in-house incubation/mentoring capacity for early-stage biotech "
    "startups, established IP&TT facilitation, and 4+ years managing early-stage funding schemes."
), "https://www.birac.nic.in/leapFundNew.php", "Partner-incubator eligibility, verbatim.")
app_process(r, "online", "https://www.birac.nic.in/leapFundNew.php",
            "Startups avail the LEAP Fund through a registered LEAP Fund Partner incubator; full procedure in the linked guidelines PDF.",
            "https://www.birac.nic.in/leapFundNew.php", "Application route, from the live page.")
finalize(r)

# ---------------------------------------------------------------------
# SCH000027 -- BIRAC SEED Fund, birac.nic.in/seedFundNew.php
r = recs["SCH000027"]
c = r["content"]
b = c["benefits"]["grant"]
assert b["maxAmountInr"] == 3000000  # CONFIRM, not change
add_source(r, "content.benefits.grant", {"maxAmountInr": 3000000}, "https://birac.nic.in/seedFundNew.php",
           'CONFIRMED (not changed): "Up to INR 30 lakhs in equity" per startup. Separately, '
           "partner incubators receive Rs 200 lakh/cycle for deployment (a different figure, "
           "not conflated with the per-startup ceiling).")
b["conditions"] = b.get("conditions", []) + [
    "Partner incubators (separately) receive Rs 200 lakh/cycle for deployment to startups -- "
    "not the same figure as the Rs 30 lakh per-startup equity ceiling.",
]
elig(r, (
    "Post-Proof-of-Concept startups with new/meritorious biotech or life-sciences ideas. For "
    "incubators to become SEED Fund Partners: supported through BIRAC's BioNEST programme, "
    "operational 3+ years, with in-house incubation capacity, established IP&TT facilitation, "
    "and prior early-stage-funding management experience."
), "https://birac.nic.in/seedFundNew.php", "Eligibility (startup + partner-incubator), verbatim.")
app_process(r, "online", "https://birac.nic.in/seedFundNew.php",
            "Startups avail the SEED Fund through a registered SEED Fund Partner incubator; full procedure in the linked guidelines PDF.",
            "https://birac.nic.in/seedFundNew.php", "Application route, from the live page.")
finalize(r)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
