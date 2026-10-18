#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/catalog_v3_1/rebuild_to_reference_shape.py

Phase B Remediation of Catalog v3.1 Migration:
1. Revert the 59 placeholder objectives on old records (< SCH000220) to null (matching published 1.35.0).
2. Fix Age facet on 83 new schemes: applies=True ONLY where source targeting has age_min/age_max (11 schemes). All others applies=null.
3. Fix existingRegistration: applies=True ONLY where source eligibility explicitly requires Udyam/UAM (9 schemes). All others applies=null.
4. Populate targetBeneficiaries (beneficiaryTypes, enterpriseTypes, specialCategories, businessStages=[]) from source targeting.
5. Fix Enterprise facet: applies=True ONLY when beneficiaryTypes contains NO individual/farmer/student/artisan/shg/household type (31 schemes). Fix SCH000289 and others to applies=null.
6. Fix Verification: isVerified=False, status from source confidence (high->verified, medium->partially_verified, low->unverified), notes from agent_flags, disputedFields from quote_verified=False facts.
7. Fix criteria '..' double period bug: strip trailing period and join with '. '.
8. Steps: use exact reference shape {step, title, description, mode, url, documents} restoring mode/url/documents from source application_steps.
9. Fix 6 Western amounts on SCH000103, SCH000136, SCH000144.
10. Fix Hindi: null instead of empty string "", remove wrong Hindi on SCH000101.
11. Regenerate applicability_matrix_catalog.json and search_index.json.
"""
from __future__ import annotations

import copy
import csv
import json
import os
import re
import sys
from collections import OrderedDict
from datetime import datetime, timezone

# Ensure stdout handles UTF-8 on Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

CAT_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
SCHEME_CAT_PATH = os.path.join(CAT_DIR, "scheme_catalog.json")
COMMON_CAT_PATH = os.path.join(CAT_DIR, "common_catalog.json")
AUTHORITY_CAT_PATH = os.path.join(CAT_DIR, "authority_catalog.json")

WORKSPACE_DIR = r"c:\development\MSS App\MSS_App"
ID_MAP_PATH = os.path.join(WORKSPACE_DIR, "reports", "id_map.csv")
SOURCE_PATH = os.path.join(
    WORKSPACE_DIR,
    "docs",
    "backend",
    "mss_scheme_data_v3_1",
    "mss_scheme_data_v3_1",
    "data",
    "new_schemes_2025_26.json"
)
SAARTHI_PATH = os.path.join(WORKSPACE_DIR, "saarthi-agent", "data", "scheme_catalog.json")

# Controlled scheme_type vocabulary from common_catalog.json
SCHEME_TYPE_VOCAB = {
    "capital_subsidy": "Capital Subsidy",
    "interest_subvention": "Interest Subvention",
    "credit_linked_subsidy": "Credit-Linked Subsidy",
    "credit_guarantee": "Credit Guarantee",
    "loan": "Loan / Term Finance",
    "grant": "Grant / Grant-in-Aid",
    "equity_funding": "Equity / Venture Funding",
    "training": "Training / Skill Development",
    "market_promotion": "Market / Export Promotion",
    "technology_support": "Technology / Innovation Support",
    "infrastructure": "Infrastructure Support",
    "social_assistance": "Social / Welfare Assistance",
    "reimbursement": "Reimbursement",
    "startup_support": "Startup Support",
    "event_support": "Event / Exhibition Support",
    "public_procurement": "Public Procurement Access",
    "energy_support": "Energy / Utility Support",
    "operating_incentive": "Operating / Location Incentive",
    "certification_support": "Certification / Quality Support",
    "facilitation": "Facilitation / Handholding",
}

# Explicit mapping for the 83 new schemes' schemeType
SCHEME_TYPE_MAP_83 = {
    "SCH000220": ("capital_subsidy", "Capital Subsidy"),
    "SCH000221": ("training", "Training / Skill Development"),
    "SCH000222": ("training", "Training / Skill Development"),
    "SCH000223": ("training", "Training / Skill Development"),
    "SCH000224": ("training", "Training / Skill Development"),
    "SCH000225": ("training", "Training / Skill Development"),
    "SCH000226": ("technology_support", "Technology / Innovation Support"),
    "SCH000227": ("market_promotion", "Market / Export Promotion"),
    "SCH000228": ("facilitation", "Facilitation / Handholding"),
    "SCH000229": ("social_assistance", "Social / Welfare Assistance"),
    "SCH000230": ("market_promotion", "Market / Export Promotion"),
    "SCH000231": ("market_promotion", "Market / Export Promotion"),
    "SCH000232": ("market_promotion", "Market / Export Promotion"),
    "SCH000233": ("capital_subsidy", "Capital Subsidy"),
    "SCH000234": ("market_promotion", "Market / Export Promotion"),
    "SCH000235": ("facilitation", "Facilitation / Handholding"),
    "SCH000236": ("reimbursement", "Reimbursement"),
    "SCH000237": ("reimbursement", "Reimbursement"),
    "SCH000238": ("reimbursement", "Reimbursement"),
    "SCH000239": ("reimbursement", "Reimbursement"),
    "SCH000240": ("reimbursement", "Reimbursement"),
    "SCH000241": ("reimbursement", "Reimbursement"),
    "SCH000242": ("market_promotion", "Market / Export Promotion"),
    "SCH000243": ("interest_subvention", "Interest Subvention"),
    "SCH000244": ("grant", "Grant / Grant-in-Aid"),
    "SCH000245": ("grant", "Grant / Grant-in-Aid"),
    "SCH000246": ("grant", "Grant / Grant-in-Aid"),
    "SCH000247": ("training", "Training / Skill Development"),
    "SCH000248": ("training", "Training / Skill Development"),
    "SCH000249": ("training", "Training / Skill Development"),
    "SCH000250": ("training", "Training / Skill Development"),
    "SCH000251": ("training", "Training / Skill Development"),
    "SCH000252": ("training", "Training / Skill Development"),
    "SCH000253": ("technology_support", "Technology / Innovation Support"),
    "SCH000254": ("technology_support", "Technology / Innovation Support"),
    "SCH000255": ("credit_guarantee", "Credit Guarantee"),
    "SCH000256": ("market_promotion", "Market / Export Promotion"),
    "SCH000257": ("market_promotion", "Market / Export Promotion"),
    "SCH000258": ("interest_subvention", "Interest Subvention"),
    "SCH000259": ("credit_guarantee", "Credit Guarantee"),
    "SCH000260": ("interest_subvention", "Interest Subvention"),
    "SCH000261": ("credit_guarantee", "Credit Guarantee"),
    "SCH000262": ("credit_guarantee", "Credit Guarantee"),
    "SCH000263": ("market_promotion", "Market / Export Promotion"),
    "SCH000264": ("certification_support", "Certification / Quality Support"),
    "SCH000265": ("reimbursement", "Reimbursement"),
    "SCH000266": ("grant", "Grant / Grant-in-Aid"),
    "SCH000267": ("grant", "Grant / Grant-in-Aid"),
    "SCH000268": ("grant", "Grant / Grant-in-Aid"),
    "SCH000269": ("loan", "Loan / Term Finance"),
    "SCH000270": ("loan", "Loan / Term Finance"),
    "SCH000271": ("equity_funding", "Equity / Venture Funding"),
    "SCH000272": ("loan", "Loan / Term Finance"),
    "SCH000273": ("facilitation", "Facilitation / Handholding"),
    "SCH000274": ("facilitation", "Facilitation / Handholding"),
    "SCH000275": ("grant", "Grant / Grant-in-Aid"),
    "SCH000276": ("equity_funding", "Equity / Venture Funding"),
    "SCH000277": ("technology_support", "Technology / Innovation Support"),
    "SCH000278": ("operating_incentive", "Operating / Location Incentive"),
    "SCH000279": ("training", "Training / Skill Development"),
    "SCH000280": ("training", "Training / Skill Development"),
    "SCH000281": ("training", "Training / Skill Development"),
    "SCH000282": ("training", "Training / Skill Development"),
    "SCH000283": ("capital_subsidy", "Capital Subsidy"),
    "SCH000284": ("capital_subsidy", "Capital Subsidy"),
    "SCH000285": ("facilitation", "Facilitation / Handholding"),
    "SCH000286": ("capital_subsidy", "Capital Subsidy"),
    "SCH000287": ("interest_subvention", "Interest Subvention"),
    "SCH000288": ("capital_subsidy", "Capital Subsidy"),
    "SCH000289": ("capital_subsidy", "Capital Subsidy"),
    "SCH000290": ("capital_subsidy", "Capital Subsidy"),
    "SCH000291": ("social_assistance", "Social / Welfare Assistance"),
    "SCH000292": ("training", "Training / Skill Development"),
    "SCH000293": ("social_assistance", "Social / Welfare Assistance"),
    "SCH000294": ("social_assistance", "Social / Welfare Assistance"),
    "SCH000295": ("training", "Training / Skill Development"),
    "SCH000296": ("technology_support", "Technology / Innovation Support"),
    "SCH000297": ("training", "Training / Skill Development"),
    "SCH000298": ("infrastructure", "Infrastructure Support"),
    "SCH000299": ("capital_subsidy", "Capital Subsidy"),
    "SCH000300": ("interest_subvention", "Interest Subvention"),
    "SCH000301": ("grant", "Grant / Grant-in-Aid"),
    "SCH000302": ("social_assistance", "Social / Welfare Assistance"),
}

# Authority normalization for Central ministries
MINISTRY_ID_MAP = {
    "ministry of micro, small and medium enterprises": "AUTH000003",
    "ministry of micro, small & medium enterprises": "AUTH000003",
    "ministry of commerce and industry": "AUTH000005",
    "ministry of housing and urban affairs": "AUTH000006",
    "ministry of science and technology": "AUTH000014",
    "department of science & technology": "AUTH000014",
    "ministry of finance": "AUTH000009",
    "ministry of agriculture and farmers welfare": "AUTH000016",
    "ministry of social justice and empowerment": "AUTH000017",
    "ministry of skill development and entrepreneurship": "AUTH000018",
    "ministry of electronics & information technology": "AUTH000125",
    "ministry of electronics and information technology": "AUTH000125",
    "ministry of labour and employment": "AUTH000126",
    "ministry of corporate affairs": "AUTH000127",
    "ministry of fisheries, animal husbandry and dairying": "AUTH000128",
    "ministry of new and renewable energy": "AUTH000129",
    "ministry of heavy industries": "AUTH000130",
    "ministry of tribal affairs": "AUTH000131",
}

# Explicit schemes where source eligibility text requires Udyam/UAM
UDYAM_EXPLICIT_SCHEMES = {
    "SCH000220",  # "UAM/Udyam Registration is mandatory."
    "SCH000226",  # "All Coir Production/processing units registered under Coir Board and having valid Udyam Registration Certificate."
    "SCH000227",  # "All Coir Production/processing units registered under Coir Board and having valid Udyam Registration Certificate."
    "SCH000228",  # "All Coir Production/processing units registered under Coir Board and having valid Udyam Registration Certificate."
    "SCH000229",  # "All Coir Production/processing units registered under Coir Board and having valid Udyam Registration Certificate."
    "SCH000255",  # "MSME with valid Udyam Registration Number."
    "SCH000261",  # "MSME e-commerce exporters with valid IEC and Udyam Registration."
    "SCH000264",  # "MSME exporters with valid IEC and Udyam Registration."
    "SCH000269",  # "Udyam-registered micro enterprises, including in rural and semi-urban areas."
}

# Non-enterprise / individual beneficiary types that prevent enterprise-only restriction
INDIVIDUAL_BENEFICIARY_TYPES = {
    "individual", "farmer", "student", "artisan", "shg", "ex_serviceman", "household"
}

# Vocabulary mapping for specialCategories from source target_groups
TARGET_GROUP_MAP = {
    "pwd": "differently_abled",
    "women": "women",
    "sc": "sc",
    "st": "st",
    "obc": "obc",
    "minority": "minority",
    "youth": "youth",
    "bpl": "bpl",
    "ner": "ner",
    "rural": "rural",
    "urban": "urban",
    "ex_serviceman": "ex_servicemen",
}


def format_inr(amount: int | float | None) -> str | None:
    if amount is None:
        return None
    try:
        amt = int(amount)
    except (ValueError, TypeError):
        return None
    if amt >= 10000000:
        cr = amt / 10000000
        return f"₹{cr:g} crore"
    if amt >= 100000:
        lakh = amt / 100000
        return f"₹{lakh:g} lakh"
    return f"₹{amt:,}"


def derive_imperative_step_title(desc: str, order: int) -> str:
    """Derive short imperative title (<= 6 words) from step description."""
    if not desc:
        return f"Step {order}"
    text = desc.strip()
    text = re.sub(r"^Step\s+\d+[:\s.-]*", "", text, flags=re.IGNORECASE).strip()

    t_lower = text.lower()
    if "register on" in t_lower or "register at" in t_lower or "registration" in t_lower or "register with" in t_lower:
        if "national portal" in t_lower or "portal" in t_lower:
            return "Register on online portal"
        return "Complete beneficiary registration"
    if "apply online" in t_lower or "online application" in t_lower:
        return "Submit online application"
    if "participating bank" in t_lower or "bank/nbfc" in t_lower or "choose the financing bank" in t_lower:
        return "Apply at participating bank"
    if "upfront contribution" in t_lower or "margin money" in t_lower:
        return "Deposit borrower contribution"
    if "install" in t_lower and "vendor" in t_lower:
        return "Install system via vendor"
    if "net meter" in t_lower or "inspection" in t_lower:
        return "Obtain commissioning inspection"
    if "cancelled cheque" in t_lower or "bank details" in t_lower or "subsidy credited" in t_lower:
        return "Submit bank details for subsidy"
    if "training" in t_lower or "commence training" in t_lower:
        return "Enroll in training program"
    if "verification" in t_lower or "scrutiny" in t_lower:
        return "Complete document verification"
    if "sanction" in t_lower or "disbursement" in t_lower:
        return "Receive loan sanction"
    if "join" in t_lower or "accept the offer" in t_lower:
        return "Join company program"

    first_clause = re.split(r"[,;.]", text)[0].strip()
    words = first_clause.split()
    if len(words) <= 6:
        return first_clause
    return " ".join(words[:5])


def rebuild_scheme(current_record: dict, ref_skeleton: dict, src_record: dict) -> dict:
    """Rebuild a single scheme record to exact reference shape, incorporating authoritative v3.1 data."""
    rec = copy.deepcopy(ref_skeleton)
    sid = current_record["identity"]["id"]

    # 1. Identity
    cur_id = current_record["identity"]
    rec["identity"]["id"] = sid
    rec["identity"]["code"] = sid
    rec["identity"]["entityType"] = "scheme"
    rec["identity"]["language"] = "en"
    rec["identity"]["name"] = cur_id["name"]
    rec["identity"]["shortName"] = cur_id.get("shortName")
    rec["identity"]["slug"] = cur_id.get("slug") or sid.lower()
    rec["identity"]["acronym"] = cur_id.get("acronym")
    rec["identity"]["legacyCodes"] = cur_id.get("legacyCodes") or []
    st = cur_id.get("status", "active")
    rec["identity"]["status"] = st if st in ("active", "closed", "unknown") else "active"

    # 2. Metadata
    cur_meta = current_record.get("metadata", {})
    rec["metadata"]["catalogVersion"] = "1.35.1-alpha"
    rec["metadata"]["schemaVersion"] = "1.0.0"
    rec["metadata"]["recordStatus"] = "published"
    rec["metadata"]["revision"] = cur_meta.get("revision", 1)
    rec["metadata"]["createdAt"] = cur_meta.get("createdAt", "2026-10-04T00:00:00Z")
    rec["metadata"]["updatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # 3. Content
    cur_c = current_record.get("content", {})
    raw_cl = current_record.get("classification") or cur_c.get("classification") or {}
    raw_gov = raw_cl.get("government") or {}

    # 3a. Classification
    st_code, st_text = SCHEME_TYPE_MAP_83.get(sid, ("financial_support", "Financial Support"))
    if st_code not in SCHEME_TYPE_VOCAB:
        st_code = "facilitation"
        st_text = SCHEME_TYPE_VOCAB["facilitation"]

    min_text = raw_gov.get("ministryText") or "Ministry of Micro, Small and Medium Enterprises"
    min_id = raw_gov.get("ministryId") or MINISTRY_ID_MAP.get(min_text.lower().strip())
    dept_text = raw_gov.get("departmentText")

    cl = rec["content"]["classification"]
    cl["schemeType"] = st_code
    cl["schemeTypeText"] = st_text
    cl["categories"] = ["financial_support"] if raw_cl.get("category") == "financial_support" else []
    cl["sectors"] = []
    cl["sectorsText"] = raw_cl.get("sectorsText")
    cl["tags"] = sorted(list(set(raw_cl.get("tags") or [st_code])))

    gov = cl["government"]
    gov["level"] = raw_gov.get("level", "central")
    gov["levelText"] = "Central" if gov["level"] == "central" else "State"
    gov["country"] = "IN"
    gov["ministryId"] = min_id
    gov["ministryText"] = min_text
    gov["departmentId"] = None
    gov["departmentText"] = dept_text
    gov["districts"] = []
    gov["districtsText"] = None
    gov["states"] = []
    gov["statesText"] = None
    gov["implementingAgencyIds"] = []
    gov["implementingAgencyText"] = None

    # 3b. Overview & Objectives
    cur_ov = cur_c.get("overview") or {}
    ov = rec["content"]["overview"]
    ov["version"] = cur_id["name"]
    ov["summary"] = cur_ov.get("summary") or cur_id["name"]
    ov["description"] = cur_ov.get("description") or ov["summary"]
    ov["lastUpdatedText"] = "Current"
    ov["validity"]["isOpenEnded"] = True

    raw_objs = cur_ov.get("objectives") or cur_c.get("objectives") or []
    if isinstance(raw_objs, list) and raw_objs:
        rec["content"]["objectives"] = [str(x).strip() for x in raw_objs if str(x).strip()]
        ov["objective"] = rec["content"]["objectives"][0]
    elif isinstance(raw_objs, str) and raw_objs.strip():
        rec["content"]["objectives"] = [raw_objs.strip()]
        ov["objective"] = raw_objs.strip()
    else:
        rec["content"]["objectives"] = [ov["summary"]]
        ov["objective"] = ov["summary"]

    # 3c. Target Beneficiaries from v3.1 source targeting
    tgt = src_record.get("targeting", {})
    raw_bts = tgt.get("beneficiary_types") or []
    raw_tgs = tgt.get("target_groups") or []

    # Map enterpriseTypes from micro/small/medium_enterprise
    ent_types = []
    if "micro_enterprise" in raw_bts:
        ent_types.append("micro")
    if "small_enterprise" in raw_bts:
        ent_types.append("small")
    if "medium_enterprise" in raw_bts:
        ent_types.append("medium")

    # Map specialCategories from target_groups + ex_serviceman
    mapped_sc = set()
    for tg in raw_tgs:
        if tg in TARGET_GROUP_MAP:
            mapped_sc.add(TARGET_GROUP_MAP[tg])
    if "ex_serviceman" in raw_bts:
        mapped_sc.add("ex_servicemen")
    special_categories = sorted(list(mapped_sc))

    cur_tb = cur_c.get("targetBeneficiaries") or {}
    tb = rec["content"]["targetBeneficiaries"]
    tb["description"] = cur_tb.get("description") or ov["summary"]
    tb["beneficiaryTypes"] = raw_bts
    tb["businessStages"] = []
    tb["enterpriseTypes"] = ent_types
    tb["specialCategories"] = special_categories

    # 3d. Benefits
    cur_b = cur_c.get("benefits") or {}
    b = rec["content"]["benefits"]
    b["summary"] = cur_b.get("summary") or "Financial assistance and business support."
    b["currency"] = "INR"

    bucket_keys = [
        "capitalSubsidy", "grant", "guarantee", "interestSubvention", "loan",
        "marginMoney", "reimbursement", "taxBenefit", "trainingSupport",
        "technologySupport", "marketSupport", "equitySupport", "insurance"
    ]
    applicable_types = []
    for bkey in bucket_keys:
        src_bucket = cur_b.get(bkey)
        tgt_bucket = b[bkey]
        if isinstance(src_bucket, dict):
            is_app = src_bucket.get("applicable") is True
            tgt_bucket["applicable"] = True if is_app else None
            if is_app:
                applicable_types.append(bkey)

            for sk in tgt_bucket.keys():
                if sk in src_bucket and src_bucket[sk] is not None:
                    tgt_bucket[sk] = src_bucket[sk]

            for amt_field in ("amountInr", "maxAmountInr", "minAmountInr", "maxCoverInr"):
                if amt_field in tgt_bucket and tgt_bucket[amt_field] is not None:
                    txt_field = amt_field.replace("Inr", "Text")
                    if txt_field in tgt_bucket:
                        tgt_bucket[txt_field] = format_inr(tgt_bucket[amt_field])

    b["benefitTypes"] = sorted(applicable_types)

    # 3e. Eligibility narrative & fix double-full-stop join bug
    cur_elig = cur_c.get("eligibility") or {}
    cur_narr = cur_elig.get("narrative") or {}
    narr = rec["content"]["eligibility"]["narrative"]
    raw_crit = cur_narr.get("criteria")
    if isinstance(raw_crit, list):
        clean_parts = [str(x).strip().rstrip(".") for x in raw_crit if str(x).strip()]
        narr_text = ". ".join(clean_parts) + ("." if clean_parts else "")
    elif isinstance(raw_crit, str):
        clean_text = re.sub(r"\.\s*\.+", ".", raw_crit.strip())
        narr_text = clean_text
    else:
        narr_text = ov["summary"]

    # Ensure no remaining '..' anywhere
    narr["criteria"] = re.sub(r"\.\.+", ".", narr_text).strip()
    narr["exclusions"] = cur_narr.get("exclusions")
    narr["relaxations"] = cur_narr.get("relaxations")
    narr["verifiedCriteria"] = None

    # Structured Eligibility Facets
    cur_struct = cur_elig.get("structured") or {}
    struct = rec["content"]["eligibility"]["structured"]

    # 1. Age: ONLY set when source targeting has age_min/age_max
    src_age_min = tgt.get("age_min")
    src_age_max = tgt.get("age_max")
    if src_age_min is not None or src_age_max is not None:
        struct["age"]["applies"] = True
        struct["age"]["minYears"] = int(src_age_min) if src_age_min is not None else None
        struct["age"]["maxYears"] = int(src_age_max) if src_age_max is not None else None
        if src_age_min is not None and src_age_max is not None:
            struct["age"]["text"] = f"aged {src_age_min}–{src_age_max}"
        elif src_age_min is not None:
            struct["age"]["text"] = f"aged {src_age_min}+"
        else:
            struct["age"]["text"] = f"up to {src_age_max} years"
    else:
        struct["age"]["applies"] = None
        struct["age"]["minYears"] = None
        struct["age"]["maxYears"] = None
        struct["age"]["text"] = None

    # 2. Gender, Community, BusinessStage
    for facet_name in ("gender", "community", "businessStage"):
        raw_f = cur_struct.get(facet_name) or {}
        vals = raw_f.get("values") or []
        vals = [str(v).strip() for v in vals if str(v).strip()]
        if vals and raw_f.get("applicable", raw_f.get("applies")) is not False:
            struct[facet_name]["applies"] = True
            struct[facet_name]["values"] = vals
            struct[facet_name]["text"] = ", ".join(vals)
        else:
            struct[facet_name]["applies"] = None
            struct[facet_name]["values"] = []
            struct[facet_name]["text"] = None

    # 3. SpecialCategory facet: from mapped specialCategories
    if special_categories:
        struct["specialCategory"]["applies"] = True
        struct["specialCategory"]["values"] = special_categories
        struct["specialCategory"]["text"] = ", ".join(special_categories)
    else:
        struct["specialCategory"]["applies"] = None
        struct["specialCategory"]["values"] = []
        struct["specialCategory"]["text"] = None

    # 4. Enterprise facet: applies=True ONLY when NO individual/farmer/artisan/student/shg types
    has_individual_types = any(bt in INDIVIDUAL_BENEFICIARY_TYPES for bt in raw_bts)
    if (not has_individual_types) and ent_types:
        struct["enterprise"]["applies"] = True
        struct["enterprise"]["types"] = ent_types
        struct["enterprise"]["constitution"] = []
        struct["enterprise"]["text"] = ", ".join(ent_types)
    else:
        struct["enterprise"]["applies"] = None
        struct["enterprise"]["types"] = []
        struct["enterprise"]["constitution"] = []
        struct["enterprise"]["text"] = None

    # 5. Sector
    raw_sec = cur_struct.get("sector") or {}
    s_inc = [str(x).strip() for x in (raw_sec.get("included") or []) if str(x).strip()]
    s_exc = [str(x).strip() for x in (raw_sec.get("excluded") or []) if str(x).strip()]
    if s_inc or s_exc:
        struct["sector"]["applies"] = True
        struct["sector"]["included"] = s_inc
        struct["sector"]["excluded"] = s_exc
        struct["sector"]["text"] = ", ".join(s_inc) if s_inc else "Specified sectors"
    else:
        struct["sector"]["applies"] = None
        struct["sector"]["included"] = []
        struct["sector"]["excluded"] = []
        struct["sector"]["text"] = None

    # 6. Location
    raw_loc = cur_struct.get("location") or {}
    loc_states = [str(x).strip() for x in (raw_loc.get("states") or []) if str(x).strip()]
    loc_districts = [str(x).strip() for x in (raw_loc.get("districts") or []) if str(x).strip()]
    loc_areas = [str(x).strip() for x in (raw_loc.get("areaTypes") or []) if str(x).strip()]
    if set(loc_areas) == {"rural", "urban"}:
        loc_areas = []

    if loc_states or loc_districts or loc_areas:
        struct["location"]["applies"] = True
        struct["location"]["states"] = loc_states
        struct["location"]["districts"] = loc_districts
        struct["location"]["areaTypes"] = loc_areas
        struct["location"]["country"] = "IN"
        parts = []
        if loc_states: parts.append(f"States: {', '.join(loc_states)}")
        if loc_districts: parts.append(f"Districts: {', '.join(loc_districts)}")
        if loc_areas: parts.append(f"Areas: {', '.join(loc_areas)}")
        struct["location"]["text"] = "; ".join(parts)
    else:
        struct["location"]["applies"] = None
        struct["location"]["states"] = []
        struct["location"]["districts"] = []
        struct["location"]["areaTypes"] = []
        struct["location"]["country"] = None
        struct["location"]["text"] = None

    # 7. existingRegistration: applies=True ONLY if explicitly in UDYAM_EXPLICIT_SCHEMES
    if sid in UDYAM_EXPLICIT_SCHEMES:
        struct["existingRegistration"]["applies"] = True
        struct["existingRegistration"]["required"] = ["Udyam Registration"]
        struct["existingRegistration"]["text"] = "Udyam Registration"
    else:
        struct["existingRegistration"]["applies"] = None
        struct["existingRegistration"]["required"] = []
        struct["existingRegistration"]["text"] = None

    # 8. Turnover
    raw_to = cur_struct.get("turnover") or {}
    to_min = raw_to.get("minInr")
    to_max = raw_to.get("maxInr") or raw_to.get("maxAmountInr")
    if to_min is not None or to_max is not None:
        struct["turnover"]["applies"] = True
        struct["turnover"]["minInr"] = to_min
        struct["turnover"]["maxInr"] = to_max
        struct["turnover"]["text"] = f"Turnover {format_inr(to_min) or '0'} to {format_inr(to_max) or 'above'}"
    else:
        struct["turnover"]["applies"] = None

    # 9. Investment
    raw_inv = cur_struct.get("investment") or {}
    inv_min = raw_inv.get("minInr")
    inv_max = raw_inv.get("maxInr") or raw_inv.get("maxAmountInr")
    if inv_min is not None or inv_max is not None:
        struct["investment"]["applies"] = True
        struct["investment"]["minInr"] = inv_min
        struct["investment"]["maxInr"] = inv_max
        struct["investment"]["text"] = f"Investment {format_inr(inv_min) or '0'} to {format_inr(inv_max) or 'above'}"
    else:
        struct["investment"]["applies"] = None

    # 3f. Application Process & Steps in reference shape {step, title, description, mode, url, documents}
    cur_ap = cur_c.get("applicationProcess") or {}
    ap = rec["content"]["applicationProcess"]
    ap["mode"] = cur_ap.get("mode", "online")
    ap["modeText"] = cur_ap.get("modeText") or "Through official portal/process"
    ap["onlineUrl"] = cur_ap.get("onlineUrl") or cur_c.get("schemeUrl")
    rec["content"]["schemeUrl"] = ap["onlineUrl"]

    sc = src_record.get("source_current", {})
    src_steps = sc.get("application_steps") or []
    norm_steps = []
    if src_steps:
        for s_idx, st in enumerate(src_steps, start=1):
            act = st.get("action")
            if isinstance(act, dict):
                s_desc = act.get("en") or act.get("hi") or ""
            elif isinstance(act, str):
                s_desc = act
            else:
                s_desc = ""
            s_title = derive_imperative_step_title(s_desc, s_idx)
            s_mode = st.get("mode") or "online"
            s_url = st.get("url")
            s_docs = st.get("documents") or []
            norm_steps.append({
                "step": s_idx,
                "title": s_title,
                "description": s_desc,
                "mode": s_mode,
                "url": s_url,
                "documents": s_docs
            })
    ap["steps"] = norm_steps

    # 3g. Required Documents
    raw_docs = cur_c.get("requiredDocuments") or []
    norm_docs = []
    for d in raw_docs:
        d_name = d.get("name") or "Required Document"
        norm_docs.append({
            "name": d_name,
            "documentTypeId": d.get("documentTypeId"),
            "documentTypeText": d.get("documentTypeText") or d_name,
            "isMandatory": d.get("isMandatory", True),
            "stage": d.get("stage", "application"),
            "issuingAuthority": d.get("issuingAuthority"),
            "description": d.get("description") or d_name,
            "validityPeriod": d.get("validityPeriod"),
            "originalRequired": d.get("originalRequired")
        })
    rec["content"]["requiredDocuments"] = norm_docs

    # 3h. Sources
    raw_srcs = cur_c.get("sources") or []
    if raw_srcs:
        rec["content"]["sources"] = raw_srcs
    else:
        rec["content"]["sources"] = [{
            "accessedOn": None,
            "documentFormat": "html",
            "isCurrent": True,
            "isPrimary": True,
            "organization": min_text,
            "sourceId": f"{sid}-SRC001",
            "sourceTier": 2,
            "title": f"Official Portal for {cur_id['name']}",
            "url": ap["onlineUrl"]
        }]

    # 4. Relationships
    rec["relationships"]["references"] = current_record.get("relationships", {}).get("references", [])

    # 5. Localization
    hi_name = (current_record.get("localization", {}).get("hi", {}) or {}).get("name")
    if hi_name:
        hi_name = str(hi_name).strip() or None

    rec["localization"]["en"] = {
        "name": cur_id["name"],
        "shortName": cur_id.get("shortName"),
        "summary": ov["summary"],
        "description": ov["description"],
        "objective": ov["objective"],
        "benefitsText": b["summary"],
        "eligibilityText": narr["criteria"],
        "applicationText": ap["modeText"]
    }
    rec["localization"]["hi"] = {
        "name": hi_name,
        "shortName": None,
        "summary": None,
        "description": None,
        "objective": None,
        "benefitsText": None,
        "eligibilityText": None,
        "applicationText": None
    }
    rec["localization"]["ta"] = {
        "name": None,
        "shortName": None,
        "summary": None,
        "description": None,
        "objective": None,
        "benefitsText": None,
        "eligibilityText": None,
        "applicationText": None
    }

    # 6. Search
    cur_search = current_record.get("search") or {}
    rec["search"]["synonyms"] = cur_search.get("synonyms") or []
    rec["search"]["boostTerms"] = []
    rec["search"]["crossReferences"] = []
    rec["search"]["searchRank"] = None
    kw_en = cur_search.get("keywords")
    if isinstance(kw_en, dict):
        rec["search"]["keywords"]["en"] = kw_en.get("en", [])
    elif isinstance(kw_en, list):
        rec["search"]["keywords"]["en"] = kw_en
    else:
        rec["search"]["keywords"]["en"] = []
    rec["search"]["keywords"]["ta"] = []

    al_en = cur_search.get("aliases")
    if isinstance(al_en, dict):
        rec["search"]["aliases"]["en"] = al_en.get("en", [])
    elif isinstance(al_en, list):
        rec["search"]["aliases"]["en"] = al_en
    else:
        rec["search"]["aliases"]["en"] = []
    rec["search"]["aliases"]["ta"] = []
    rec["search"]["aliases"]["hi"] = []

    # 7. AI & Analytics
    rec["analytics"] = {
        "popularity": None,
        "viewCount": None,
        "saveCount": None,
        "actionCount": None,
        "lastAggregatedAt": None
    }
    ai_used = []
    sec_summaries = {}
    if ov["summary"]:
        ai_used.append("content.overview.summary")
    if b["summary"]:
        ai_used.append("content.benefits.summary")
        sec_summaries["benefits"] = b["summary"]
    if narr["criteria"]:
        ai_used.append("content.eligibility.narrative.criteria")
        sec_summaries["eligibility"] = narr["criteria"]
    if norm_docs:
        doc_names = [d["name"] for d in norm_docs[:6]]
        sec_summaries["documents"] = "; ".join(doc_names)
        ai_used.append("content.requiredDocuments[].name")

    rec["ai"] = {
        "confidence": None,
        "generatedAt": "2026-10-04T00:00:00Z",
        "generatedBy": "build_scheme_catalog.py-1.0.0",
        "generationMode": "mechanical_derivation",
        "isApproved": False,
        "recommendations": [],
        "recommendationsNote": None,
        "relatedEntities": [],
        "reviewRequired": True,
        "reviewedAt": None,
        "reviewedBy": None,
        "sectionSummaries": sec_summaries,
        "semanticTags": [],
        "similarityMethod": None,
        "sourceFieldsUsed": ai_used,
        "summary": ov["summary"]
    }

    # 8. Provenance
    rec["provenance"] = {
        "primarySourceId": f"{sid}-SRC001",
        "contributingSourceIds": [f"{sid}-SRC001"],
        "defaultSourceTier": 2,
        "extractedAt": "2026-10-04T00:00:00Z",
        "extractionMethod": "automated",
        "fieldSources": [],
        "pipelineVersion": "catalog-v3.1-migration-1.35.1",
        "transformationNotes": [
            "Rebuilt to reference catalog shape in v3.1 migration"
        ],
        "translations": {}
    }
    if hi_name:
        rec["provenance"]["translations"]["hi"] = {
            "source": "booklet_2025_26_machine_hi",
            "status": "machine",
            "reviewRequired": True,
            "generatedAt": "2026-10-04T13:45:56Z"
        }

    # 9. Verification from v3.1 source status.confidence, agent_flags, quote_verified
    missing = []
    if not norm_docs:
        missing.append({"field": "content.requiredDocuments", "reason": "Not available in available sources"})
    if not cur_c.get("contacts"):
        missing.append({"field": "content.contacts", "reason": "Not available in available sources"})
    missing.append({"field": "content.applicationTimeline", "reason": "Not available in available sources"})
    missing.append({"field": "content.faqs", "reason": "Not available in available sources"})
    missing.append({"field": "localization.ta", "reason": "Tamil translation pending (D5=English-only)"})

    # Confidence and status
    src_conf = src_record.get("status", {}).get("confidence", "medium")
    status_map = {
        "high": "verified",
        "medium": "partially_verified",
        "low": "unverified"
    }
    verif_status = status_map.get(src_conf, "partially_verified")

    # Notes from agent_flags
    flags = src_record.get("agent_flags") or []
    notes_val = " | ".join(str(f).strip() for f in flags if str(f).strip()) if flags else None

    # Disputed fields from benefit_facts with quote_verified == False
    facts = src_record.get("benefit_facts") or []
    disputed = []
    for f_item in facts:
        if f_item.get("quote_verified") is False:
            b_type = f_item.get("type", "benefit")
            quote_text = f_item.get("source_quote_en") or f_item.get("condition_en") or "unverified benefit fact"
            disputed.append({
                "field": f"content.benefits.{b_type}",
                "reason": f"quote_verified=false in v3.1 source: '{quote_text}'",
                "resolvedBy": None,
                "values": []
            })

    rec["verification"] = {
        "confidence": src_conf,
        "disputedFields": disputed,
        "isVerified": False,
        "missingFields": missing,
        "notes": notes_val,
        "researchStatus": "Researched",
        "reviewDueOn": None,
        "status": verif_status,
        "statusText": None,
        "verifiedAgainst": [f"{sid}-SRC001"],
        "verifiedAt": "2026-10-04",
        "verifiedBy": None,
        "verifiedFields": []
    }

    return rec


def main():
    print(f"Loading scheme catalog: {SCHEME_CAT_PATH}")
    with open(SCHEME_CAT_PATH, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    data = catalog["data"]
    by_id = {r["identity"]["id"]: r for r in data}
    ref_skeleton = copy.deepcopy(by_id["SCH000124"])

    # Load ID map and source records
    print(f"Loading ID map: {ID_MAP_PATH}")
    id_map = {}
    with open(ID_MAP_PATH, "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            id_map[row["allocated_catalog_id"]] = row["v3_1_id"]

    print(f"Loading v3.1 source records: {SOURCE_PATH}")
    with open(SOURCE_PATH, "r", encoding="utf-8") as f:
        src_raw = json.load(f)
        v3_schemes = {s["id"]: s for s in src_raw["schemes"]}

    # 1. Revert the 59 placeholder objectives on old records (< SCH000220)
    print(f"Loading published 1.35.0 scheme catalog: {SAARTHI_PATH}")
    with open(SAARTHI_PATH, "r", encoding="utf-8") as f:
        saarthi_cat = json.load(f)
        saarthi_by_id = {r["identity"]["id"]: r for r in saarthi_cat["data"]}

    reverted_objs = 0
    for r in data:
        sid = r["identity"]["id"]
        if sid < "SCH000220":
            cur_obj = r.get("content", {}).get("overview", {}).get("objective")
            saarthi_obj = saarthi_by_id.get(sid, {}).get("content", {}).get("overview", {}).get("objective")
            if cur_obj != saarthi_obj:
                r["content"]["overview"]["objective"] = saarthi_obj
                reverted_objs += 1

    print(f"Reverted {reverted_objs} placeholder overview.objective values on old records to null.")

    # 2. Fix Western amounts on existing schemes
    fixed_western = 0
    if "SCH000103" in by_id:
        g = by_id["SCH000103"]["content"]["benefits"]["grant"]
        g["amountText"] = "₹15 lakh"
        g["maxAmountText"] = "₹15 lakh"
        fixed_western += 2
    if "SCH000136" in by_id:
        g = by_id["SCH000136"]["content"]["benefits"]["grant"]
        g["amountText"] = "₹13.5 crore"
        g["maxAmountText"] = "₹13.5 crore"
        fixed_western += 2
    if "SCH000144" in by_id:
        g = by_id["SCH000144"]["content"]["benefits"]["grant"]
        g["amountText"] = "₹2.5 crore"
        g["maxAmountText"] = "₹2.5 crore"
        fixed_western += 2
    print(f"Fixed {fixed_western} Western amount fields on SCH000103, SCH000136, SCH000144.")

    # 3. Fix Hindi on SCH000101 & remove empty strings "" across all schemes
    if "SCH000101" in by_id:
        by_id["SCH000101"]["localization"]["hi"]["name"] = None
        print("Removed invalid 2015 Hindi name from SCH000101.")

    empty_hi_fixed = 0
    for r in data:
        hi_dict = r.get("localization", {}).get("hi")
        if isinstance(hi_dict, dict):
            for k in list(hi_dict.keys()):
                if hi_dict[k] == "":
                    hi_dict[k] = None
                    empty_hi_fixed += 1

    print(f"Replaced {empty_hi_fixed} empty strings '' with null in localization.hi.")

    # 4. Rebuild the 83 new records (SCH000220 - SCH000302)
    rebuilt_count = 0
    age_gate_count = 0
    enterprise_applies_count = 0
    udyam_count = 0

    for i, r in enumerate(data):
        sid = r["identity"]["id"]
        if sid >= "SCH000220" and sid <= "SCH000302":
            v3_id = id_map.get(sid)
            src_rec = v3_schemes.get(v3_id, {})
            rebuilt = rebuild_scheme(r, ref_skeleton, src_rec)
            data[i] = rebuilt
            rebuilt_count += 1
            if rebuilt["content"]["eligibility"]["structured"]["age"]["applies"] is True:
                age_gate_count += 1
            if rebuilt["content"]["eligibility"]["structured"]["enterprise"]["applies"] is True:
                enterprise_applies_count += 1
            if rebuilt["content"]["eligibility"]["structured"]["existingRegistration"]["applies"] is True:
                udyam_count += 1

    print(f"Rebuilt {rebuilt_count} new schemes to reference shape:")
    print(f"  - Schemes with age gate: {age_gate_count} (expected 11)")
    print(f"  - Schemes with enterprise.applies=True: {enterprise_applies_count} (expected 31)")
    print(f"  - Schemes with Udyam registration required: {udyam_count} (expected 9)")

    with open(SCHEME_CAT_PATH, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    print(f"\n{SCHEME_CAT_PATH} successfully written.")

    # 5. Regenerate applicability_matrix_catalog.json using build_applicability_matrix.py
    print("\nRegenerating applicability_matrix_catalog.json...")
    sys.path.insert(0, CAT_DIR)
    import build_applicability_matrix
    build_applicability_matrix.main()

    # 6. Regenerate search_index.json using build_search_index.py
    print("\nRegenerating search_index.json...")
    import build_search_index
    build_search_index.main()

    print("\nPhase B Remediation Rebuild Complete!")


if __name__ == "__main__":
    main()
