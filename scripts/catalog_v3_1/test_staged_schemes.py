"""
Test Suite for Staged MSME v3.1 Schemes (catalog.scheme_new_v3_1):
Performs structural, referential, search index, and data consistency tests
on the 83 staged schemes prior to production rewiring.
"""

import hashlib
import json
import os
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REPORT_PATH = os.path.join("reports", "phase5_staging_test_report.json")

def run_query(sql):
    tmp_path = os.path.join("backend", "temp_test_staged_query.sql")
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(sql)
    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_test_staged_query.sql"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    res = subprocess.run(cmd, cwd="backend", capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, shell=True)
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    return res.stdout, res.stderr, res.returncode

def parse_supabase_rows(stdout):
    try:
        # Find json object
        idx = stdout.find("{")
        if idx != -1:
            data = json.loads(stdout[idx:])
            return data.get("rows", [])
    except Exception as e:
        print("JSON parse error:", e)
    return []

def main():
    print("=================================================================")
    print("RUNNING AUTOMATED TESTS ON STAGED SCHEMES (catalog.*_new_v3_1)")
    print("=================================================================\n")

    results = {
        "status": "PASS",
        "tests": {},
        "summary": {}
    }

    # Test 1: Record counts across staging tables
    print("Test 1: Verifying Staging Table Counts...")
    sql_counts = """
SELECT 
    (SELECT count(*) FROM catalog.scheme_new_v3_1) as staged_schemes,
    (SELECT count(*) FROM catalog.applicability_matrix_new_v3_1) as staged_matrices,
    (SELECT count(*) FROM catalog.search_index_new_v3_1) as staged_search_index,
    (SELECT count(*) FROM catalog.relationships_new_v3_1) as staged_relationships,
    (SELECT count(*) FROM catalog.scheme_source_v3_1) as source_records,
    (SELECT count(*) FROM catalog.scheme) as active_schemes,
    (SELECT count(*) FROM catalog.v_scheme_all) as total_view_schemes;
"""
    out, err, rc = run_query(sql_counts)
    rows = parse_supabase_rows(out)
    if not rows:
        print("FAILED to get table counts:", err)
        sys.exit(1)
    counts = rows[0]
    results["tests"]["staging_counts"] = {
        "expected": {
            "staged_schemes": 83,
            "staged_matrices": 83,
            "staged_search_index": 83,
            "staged_relationships": 183,
            "source_records": 393,
            "active_schemes": 219,
            "total_view_schemes": 302
        },
        "actual": counts,
        "pass": (
            counts.get("staged_schemes") == 83 and
            counts.get("staged_matrices") == 83 and
            counts.get("staged_search_index") == 83 and
            counts.get("staged_relationships") == 183 and
            counts.get("source_records") == 393 and
            counts.get("active_schemes") == 219 and
            counts.get("total_view_schemes") == 302
        )
    }
    print(f"  -> Result: {'PASS' if results['tests']['staging_counts']['pass'] else 'FAIL'}")

    # Test 2: Field integrity on staged schemes
    print("Test 2: Field Integrity & Non-Null Requirements...")
    sql_fields = """
SELECT 
    count(*) as total,
    count(*) FILTER (WHERE name_en IS NULL OR trim(name_en) = '') as missing_name_en,
    count(*) FILTER (WHERE record_json IS NULL) as missing_record_json,
    count(*) FILTER (WHERE status NOT IN ('PUBLISHED', 'DRAFT')) as invalid_status,
    count(*) FILTER (WHERE government_level != 'central') as non_central_gov_level,
    count(*) FILTER (WHERE status = 'PUBLISHED' AND (scheme_url IS NULL AND record_json->'applicationProcess'->>'onlineUrl' IS NULL)) as published_missing_url,
    count(*) FILTER (WHERE jsonb_array_length(record_json->'content'->'sources') = 0) as missing_sources
FROM catalog.scheme_new_v3_1;
"""
    out, err, rc = run_query(sql_fields)
    rows = parse_supabase_rows(out)
    field_check = rows[0] if rows else {}
    results["tests"]["field_integrity"] = {
        "actual": field_check,
        "pass": (
            field_check.get("missing_name_en") == 0 and
            field_check.get("missing_record_json") == 0 and
            field_check.get("invalid_status") == 0 and
            field_check.get("published_missing_url") == 0 and
            field_check.get("missing_sources") == 0
        )
    }
    print(f"  -> Result: {'PASS' if results['tests']['field_integrity']['pass'] else 'FAIL'}")

    # Test 3: Relationship Symmetry & Referencing
    print("Test 3: Relationship Graph Symmetry & Referencing...")
    sql_rels = """
SELECT 
    (SELECT count(*) FROM catalog.relationships_new_v3_1 WHERE relationship_type = 'child_of') as child_of_count,
    (SELECT count(*) FROM catalog.relationships_new_v3_1 WHERE relationship_type = 'parent_of') as parent_of_count,
    (SELECT count(*) FROM catalog.relationships_new_v3_1 WHERE relationship_type = 'administered_by') as administered_by_count,
    (
        SELECT count(*) 
        FROM catalog.relationships_new_v3_1 r1
        WHERE r1.relationship_type = 'child_of'
          AND NOT EXISTS (
              SELECT 1 FROM catalog.relationships_new_v3_1 r2
              WHERE r2.relationship_type = 'parent_of'
                AND r2.source_id = r1.target_id
                AND r2.target_id = r1.source_id
          )
    ) as asymmetric_parent_child_pairs;
"""
    out, err, rc = run_query(sql_rels)
    rows = parse_supabase_rows(out)
    rel_check = rows[0] if rows else {}
    results["tests"]["relationships"] = {
        "actual": rel_check,
        "pass": (
            rel_check.get("child_of_count") == rel_check.get("parent_of_count") and
            rel_check.get("asymmetric_parent_child_pairs") == 0
        )
    }
    print(f"  -> Result: {'PASS' if results['tests']['relationships']['pass'] else 'FAIL'}")

    # Test 4: Spot Checks on Target Schemes
    print("Test 4: Key Scheme Spot Checks...")
    sql_spots = """
SELECT id, scheme_code, name_en, status, 
       record_json->'localization'->'hi'->>'name' as hi_name,
       scheme_url
FROM catalog.scheme_new_v3_1
WHERE id IN ('SCH000269', 'SCH000272', 'SCH000274', 'SCH000302')
ORDER BY id;
"""
    out, err, rc = run_query(sql_spots)
    rows = parse_supabase_rows(out)
    results["tests"]["spot_checks"] = {
        "rows": rows,
        "pass": len(rows) == 4
    }
    for r in rows:
        print(f"  -> [{r.get('id')}] {r.get('name_en')} (Status: {r.get('status')}) | Hindi: {r.get('hi_name')}")

    # Overall Status
    all_pass = all(t.get("pass", False) for t in results["tests"].values())
    results["status"] = "PASS" if all_pass else "FAIL"

    os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\nSaved test report to {REPORT_PATH}.")
    print(f"OVERALL STATUS: {results['status']}")

if __name__ == "__main__":
    main()
