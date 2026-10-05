#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/catalog_v3_1/validate_shape.py

Strict structural validator for Catalog v3.1 Remediation:
1. Validates all 302 schemes against reference skeleton SCH000124.
2. Validates all 302 applicability matrices against reference APLM000124.
3. Validates all 302 search index scheme entries against SCH000124 entry.
4. Enforces 0 forbidden keys: 'applicable', 'min', 'max', 'requiredTypes', 'landHolding', 'maxAmountInr'.
5. Enforces scheme_type controlled vocabulary.
6. Enforces no empty strings "" in localization.hi.
7. Enforces Western amount corrections on SCH000103, SCH000136, SCH000144.
8. Enforces Hindi removal on SCH000101.
9. Enforces exact reference step shape {step, title, description, mode, url, documents}.
10. Enforces exact facet key sets per facet.
11. Enforces targetBeneficiaries non-empty where source has beneficiary_types.
12. Enforces no age gate without a source age (and age gate present where source has age).
"""
from __future__ import annotations

import csv
import json
import os
import sys

# Ensure stdout handles UTF-8 on Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

CAT_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
SCHEME_CAT_PATH = os.path.join(CAT_DIR, "scheme_catalog.json")
APLM_CAT_PATH = os.path.join(CAT_DIR, "applicability_matrix_catalog.json")
SEARCH_IDX_PATH = os.path.join(CAT_DIR, "search_index.json")
COMMON_CAT_PATH = os.path.join(CAT_DIR, "common_catalog.json")

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

FORBIDDEN_FACET_KEYS = {"applicable", "min", "max", "requiredTypes", "landHolding", "maxAmountInr"}

EXPECTED_ROOT = {'ai', 'analytics', 'content', 'identity', 'localization', 'metadata', 'provenance', 'relationships', 'search', 'verification'}
EXPECTED_CONTENT = {'applicationProcess', 'applicationTimeline', 'benefits', 'classification', 'contacts', 'eligibility', 'faqs', 'objectives', 'overview', 'requiredDocuments', 'schemeUrl', 'sources', 'targetBeneficiaries'}
EXPECTED_CLASSIFICATION = {'categories', 'government', 'schemeType', 'schemeTypeText', 'sectors', 'sectorsText', 'tags'}
EXPECTED_GOV = {'country', 'departmentId', 'departmentText', 'districts', 'districtsText', 'implementingAgencyIds', 'implementingAgencyText', 'level', 'levelText', 'ministryId', 'ministryText', 'states', 'statesText'}
EXPECTED_BENEFITS = {'benefitTypes', 'capitalSubsidy', 'currency', 'disbursement', 'equitySupport', 'grant', 'guarantee', 'insurance', 'interestSubvention', 'loan', 'marginMoney', 'marketSupport', 'reimbursement', 'summary', 'taxBenefit', 'technologySupport', 'trainingSupport'}
EXPECTED_STRUCT = {'age', 'businessStage', 'community', 'enterprise', 'existingRegistration', 'gender', 'investment', 'location', 'otherConditions', 'sector', 'specialCategory', 'turnover'}
EXPECTED_OVERVIEW = {'background', 'description', 'lastUpdated', 'lastUpdatedText', 'legalBasis', 'objective', 'summary', 'validity', 'version'}
EXPECTED_IDENTITY = {'acronym', 'code', 'entityType', 'id', 'language', 'legacyCodes', 'name', 'shortName', 'slug', 'status'}
EXPECTED_METADATA = {'catalogVersion', 'createdAt', 'recordStatus', 'revision', 'schemaVersion', 'updatedAt'}
EXPECTED_ANALYTICS = {'actionCount', 'lastAggregatedAt', 'popularity', 'saveCount', 'viewCount'}
EXPECTED_SEARCH = {'aliases', 'boostTerms', 'crossReferences', 'keywords', 'searchRank', 'synonyms'}
EXPECTED_VERIF = {'confidence', 'disputedFields', 'isVerified', 'missingFields', 'notes', 'researchStatus', 'reviewDueOn', 'status', 'statusText', 'verifiedAgainst', 'verifiedAt', 'verifiedBy', 'verifiedFields'}
EXPECTED_PROV = {'contributingSourceIds', 'defaultSourceTier', 'extractedAt', 'extractionMethod', 'fieldSources', 'pipelineVersion', 'primarySourceId', 'transformationNotes', 'translations'}
EXPECTED_LOC_EN = {'applicationText', 'benefitsText', 'description', 'eligibilityText', 'name', 'objective', 'shortName', 'summary'}

EXPECTED_STEP_KEYS = {'step', 'title', 'description', 'mode', 'url', 'documents'}

EXPECTED_FACET_KEYS = {
    "age": {"applies", "maxYears", "minYears", "text"},
    "businessStage": {"applies", "text", "values"},
    "community": {"applies", "text", "values"},
    "enterprise": {"applies", "constitution", "text", "types"},
    "existingRegistration": {"applies", "required", "text"},
    "gender": {"applies", "text", "values"},
    "investment": {"applies", "maxInr", "minInr", "text"},
    "location": {"applies", "areaTypes", "country", "districts", "states", "text"},
    "sector": {"applies", "excluded", "included", "text"},
    "specialCategory": {"applies", "text", "values"},
    "turnover": {"applies", "maxInr", "minInr", "text"},
}


def load_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_scheme_catalog(
    schemes: list[dict],
    allowed_scheme_types: set[str],
    id_map: dict[str, str],
    v3_schemes: dict[str, dict]
) -> list[str]:
    errors = []
    if len(schemes) != 302:
        errors.append(f"Expected 302 schemes, found {len(schemes)}")

    by_id = {r["identity"]["id"]: r for r in schemes}

    # Specific assertions
    # 1. Western amounts
    for sid, exp_amt in [("SCH000103", "₹15 lakh"), ("SCH000136", "₹13.5 crore"), ("SCH000144", "₹2.5 crore")]:
        if sid in by_id:
            g = by_id[sid].get("content", {}).get("benefits", {}).get("grant", {})
            if g.get("amountText") != exp_amt or g.get("maxAmountText") != exp_amt:
                errors.append(f"{sid}: Western amount not fixed (amountText='{g.get('amountText')}', maxAmountText='{g.get('maxAmountText')}', expected '{exp_amt}')")

    # 2. SCH000101 Hindi removal
    if "SCH000101" in by_id:
        h_name = by_id["SCH000101"].get("localization", {}).get("hi", {}).get("name")
        if h_name is not None:
            errors.append(f"SCH000101: Hindi name is '{h_name}', expected null")

    age_gate_count = 0

    for s in schemes:
        sid = s["identity"]["id"]

        # Structural contract checks
        if set(s.keys()) != EXPECTED_ROOT:
            errors.append(f"{sid}: Root keys mismatch: diff={set(s.keys()) ^ EXPECTED_ROOT}")
        c = s.get("content", {})
        if set(c.keys()) != EXPECTED_CONTENT:
            errors.append(f"{sid}: Content keys mismatch: diff={set(c.keys()) ^ EXPECTED_CONTENT}")
        cl = c.get("classification", {})
        if set(cl.keys()) != EXPECTED_CLASSIFICATION:
            errors.append(f"{sid}: Classification keys mismatch: diff={set(cl.keys()) ^ EXPECTED_CLASSIFICATION}")
        gov = cl.get("government", {})
        if set(gov.keys()) != EXPECTED_GOV:
            errors.append(f"{sid}: Government keys mismatch: diff={set(gov.keys()) ^ EXPECTED_GOV}")
        b = c.get("benefits", {})
        if set(b.keys()) != EXPECTED_BENEFITS:
            errors.append(f"{sid}: Benefits keys mismatch: diff={set(b.keys()) ^ EXPECTED_BENEFITS}")
        struct = c.get("eligibility", {}).get("structured", {})
        if set(struct.keys()) != EXPECTED_STRUCT:
            errors.append(f"{sid}: Structured eligibility keys mismatch: diff={set(struct.keys()) ^ EXPECTED_STRUCT}")
        ov = c.get("overview", {})
        if set(ov.keys()) != EXPECTED_OVERVIEW:
            errors.append(f"{sid}: Overview keys mismatch: diff={set(ov.keys()) ^ EXPECTED_OVERVIEW}")
        idn = s.get("identity", {})
        if set(idn.keys()) != EXPECTED_IDENTITY:
            errors.append(f"{sid}: Identity keys mismatch: diff={set(idn.keys()) ^ EXPECTED_IDENTITY}")
        meta = s.get("metadata", {})
        if set(meta.keys()) != EXPECTED_METADATA:
            errors.append(f"{sid}: Metadata keys mismatch: diff={set(meta.keys()) ^ EXPECTED_METADATA}")
        an = s.get("analytics", {})
        if set(an.keys()) != EXPECTED_ANALYTICS:
            errors.append(f"{sid}: Analytics keys mismatch: diff={set(an.keys()) ^ EXPECTED_ANALYTICS}")
        se = s.get("search", {})
        if set(se.keys()) != EXPECTED_SEARCH:
            errors.append(f"{sid}: Search keys mismatch: diff={set(se.keys()) ^ EXPECTED_SEARCH}")
        v = s.get("verification", {})
        if set(v.keys()) != EXPECTED_VERIF:
            errors.append(f"{sid}: Verification keys mismatch: diff={set(v.keys()) ^ EXPECTED_VERIF}")
        pr = s.get("provenance", {})
        if set(pr.keys()) != EXPECTED_PROV:
            errors.append(f"{sid}: Provenance keys mismatch: diff={set(pr.keys()) ^ EXPECTED_PROV}")
        loc_en = s.get("localization", {}).get("en", {})
        if set(loc_en.keys()) != EXPECTED_LOC_EN:
            errors.append(f"{sid}: Localization.en keys mismatch: diff={set(loc_en.keys()) ^ EXPECTED_LOC_EN}")

        # Forbidden facet keys & exact per-facet key set check
        for fk, fv in struct.items():
            if isinstance(fv, dict):
                bad = set(fv.keys()) & FORBIDDEN_FACET_KEYS
                if bad:
                    errors.append(f"{sid}: Facet '{fk}' has forbidden keys: {bad}")
                if fk in EXPECTED_FACET_KEYS:
                    exp_k = EXPECTED_FACET_KEYS[fk]
                    if set(fv.keys()) != exp_k:
                        errors.append(f"{sid}: Facet '{fk}' keys mismatch: diff={set(fv.keys()) ^ exp_k}")
            elif fk == "otherConditions":
                if not isinstance(fv, list):
                    errors.append(f"{sid}: Facet 'otherConditions' is not a list")

        # Step keys check
        steps = c.get("applicationProcess", {}).get("steps", [])
        for st_idx, st in enumerate(steps):
            if set(st.keys()) != EXPECTED_STEP_KEYS:
                errors.append(f"{sid}: Step {st_idx+1} keys mismatch: diff={set(st.keys()) ^ EXPECTED_STEP_KEYS}")

        # Location check
        loc = struct.get("location", {})
        if loc.get("areaTypes") == ["rural", "urban"] and not loc.get("states"):
            errors.append(f"{sid}: Location has dummy areaTypes ['rural', 'urban']")

        # Content types
        if not isinstance(c.get("objectives"), list):
            errors.append(f"{sid}: content.objectives is not a list")
        if ov.get("objective") is not None and not isinstance(ov.get("objective"), str):
            errors.append(f"{sid}: overview.objective is not string or null (type={type(ov.get('objective')).__name__})")
        crit = c.get("eligibility", {}).get("narrative", {}).get("criteria")
        if not isinstance(crit, str):
            errors.append(f"{sid}: narrative.criteria is not a string")
        elif ".." in crit:
            errors.append(f"{sid}: narrative.criteria contains '..' double full-stop")

        # Identity status contract: active, closed, unknown
        st = idn.get("status")
        if st not in ("active", "closed", "unknown"):
            errors.append(f"{sid}: Invalid identity.status '{st}' (must be active/closed/unknown)")

        # Controlled vocabulary
        scheme_type = cl.get("schemeType")
        if scheme_type is not None and scheme_type not in allowed_scheme_types:
            errors.append(f"{sid}: schemeType '{scheme_type}' not in controlled vocabulary")

        # No empty strings in localization.hi
        hi = s.get("localization", {}).get("hi", {})
        if isinstance(hi, dict):
            for k, val in hi.items():
                if val == "":
                    errors.append(f"{sid}: localization.hi.{k} is empty string '' (must be null)")

        # New schemes specific validations (SCH000220 - SCH000302)
        if sid >= "SCH000220" and sid <= "SCH000302":
            v3_id = id_map.get(sid)
            src_rec = v3_schemes.get(v3_id, {})
            src_tgt = src_rec.get("targeting", {})

            # 1. targetBeneficiaries non-empty where source has beneficiary_types
            src_bts = src_tgt.get("beneficiary_types") or []
            cat_bts = c.get("targetBeneficiaries", {}).get("beneficiaryTypes") or []
            if src_bts and not cat_bts:
                errors.append(f"{sid}: targetBeneficiaries.beneficiaryTypes is empty but source has {src_bts}")

            # 2. No age gate without a source age
            src_age_min = src_tgt.get("age_min")
            src_age_max = src_tgt.get("age_max")
            age_f = struct.get("age", {})
            if src_age_min is None and src_age_max is None:
                if age_f.get("applies") is not None:
                    errors.append(f"{sid}: age.applies is {age_f.get('applies')}, expected None (no source age)")
                if age_f.get("minYears") is not None or age_f.get("maxYears") is not None:
                    errors.append(f"{sid}: age has minYears={age_f.get('minYears')}, maxYears={age_f.get('maxYears')}, expected None")
            else:
                age_gate_count += 1
                if age_f.get("applies") is not True:
                    errors.append(f"{sid}: age.applies is {age_f.get('applies')}, expected True (source age={src_age_min}-{src_age_max})")

    if age_gate_count != 11:
        errors.append(f"Expected exactly 11 schemes with age gate, found {age_gate_count}")

    return errors


def validate_matrix_catalog(matrices: list[dict], ref_id: str = "APLM000124") -> list[str]:
    errors = []
    if len(matrices) != 302:
        errors.append(f"Expected 302 matrices, found {len(matrices)}")

    by_id = {r["identity"]["id"]: r for r in matrices}
    if ref_id not in by_id:
        return [f"Reference matrix {ref_id} not found"]

    ref_m = by_id[ref_id]
    ref_root = set(ref_m.keys())
    ref_content = set(ref_m["content"].keys())

    for m in matrices:
        mid = m["identity"]["id"]
        if set(m.keys()) != ref_root:
            errors.append(f"{mid}: Root keys mismatch: diff={set(m.keys()) ^ ref_root}")
        if set(m.get("content", {}).keys()) != ref_content:
            errors.append(f"{mid}: Content keys mismatch: diff={set(m.get('content', {}).keys()) ^ ref_content}")

    return errors


def validate_search_catalog(entries: list[dict], ref_entity_id: str = "SCH000124") -> list[str]:
    errors = []
    scheme_entries = {r["entityId"]: r for r in entries if r.get("entityType") == "scheme"}
    if len(scheme_entries) != 302:
        errors.append(f"Expected 302 scheme search entries, found {len(scheme_entries)}")

    if ref_entity_id not in scheme_entries:
        return [f"Reference scheme search entry {ref_entity_id} not found"]

    ref_s = scheme_entries[ref_entity_id]
    ref_root = set(ref_s.keys())
    ref_prof = set(ref_s["schemeSearchProfile"].keys())

    for sid, e in scheme_entries.items():
        if set(e.keys()) != ref_root:
            errors.append(f"{sid}: Root keys mismatch: diff={set(e.keys()) ^ ref_root}")
        prof = e.get("schemeSearchProfile")
        if not isinstance(prof, dict):
            errors.append(f"{sid}: Missing schemeSearchProfile")
        elif set(prof.keys()) != ref_prof:
            errors.append(f"{sid}: schemeSearchProfile keys mismatch: diff={set(prof.keys()) ^ ref_prof}")
        if "targeting" in e:
            errors.append(f"{sid}: Found forbidden 'targeting' block in search entry")

    return errors


def main():
    print("=" * 75)
    print("CATALOG V3.1 STRICT SHAPE VALIDATOR (GATE B REMEDIATION)")
    print("=" * 75)

    common_cat = load_json(COMMON_CAT_PATH)
    allowed_scheme_types = {
        r["content"]["code"]
        for r in common_cat["data"]
        if r["content"]["termType"] == "scheme_type"
    }

    id_map = {}
    with open(ID_MAP_PATH, "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            id_map[row["allocated_catalog_id"]] = row["v3_1_id"]

    with open(SOURCE_PATH, "r", encoding="utf-8") as f:
        v3_schemes = {s["id"]: s for s in json.load(f)["schemes"]}

    # 1. Scheme Catalog
    scheme_cat = load_json(SCHEME_CAT_PATH)
    schemes = scheme_cat["data"]
    print(f"\n1. Validating {len(schemes)} schemes against reference contract SCH000124...")
    s_errors = validate_scheme_catalog(schemes, allowed_scheme_types, id_map, v3_schemes)
    if s_errors:
        print(f"   [FAIL] Found {len(s_errors)} scheme validation errors:")
        for e in s_errors[:15]:
            print(f"     - {e}")
        if len(s_errors) > 15:
            print(f"     ... and {len(s_errors) - 15} more.")
    else:
        print(f"   [PASS] 0 failures across all {len(schemes)} schemes! Structure is 100% compliant.")

    # 2. Applicability Matrix Catalog
    matrix_cat = load_json(APLM_CAT_PATH)
    matrices = matrix_cat["data"]
    print(f"\n2. Validating {len(matrices)} applicability matrices against reference APLM000124...")
    m_errors = validate_matrix_catalog(matrices)
    if m_errors:
        print(f"   [FAIL] Found {len(m_errors)} matrix validation errors:")
        for e in m_errors[:15]:
            print(f"     - {e}")
    else:
        print(f"   [PASS] 0 failures across all {len(matrices)} matrices! Structure is 100% compliant.")

    # 3. Search Index Catalog
    search_cat = load_json(SEARCH_IDX_PATH)
    search_entries = search_cat["data"]
    print(f"\n3. Validating search index entries against reference SCH000124...")
    idx_errors = validate_search_catalog(search_entries)
    if idx_errors:
        print(f"   [FAIL] Found {len(idx_errors)} search index validation errors:")
        for e in idx_errors[:15]:
            print(f"     - {e}")
    else:
        print(f"   [PASS] 0 failures across all search entries! Structure is 100% compliant.")

    total_errors = len(s_errors) + len(m_errors) + len(idx_errors)
    print("\n" + "=" * 75)
    if total_errors == 0:
        print("ALL VALIDATION CHECKS PASSED: 0 FAILURES")
        print("=" * 75)
        sys.exit(0)
    else:
        print(f"VALIDATION FAILED: {total_errors} TOTAL ERRORS")
        print("=" * 75)
        sys.exit(1)


if __name__ == "__main__":
    main()
