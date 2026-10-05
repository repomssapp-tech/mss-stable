"""
Phase 6 Step 1 Validation Runner:
Executes the comprehensive verification checklist required by ANTIGRAVITY_PROMPT.md:
1. Scheme count = 219 + 83 - 0 = 302
2. Every child_of has a matching parent_of
3. No orphan relationship ids
4. Checksums updated by trigger (checksum matches sha256(record_json::text))
5. Every new PUBLISHED row has name_en, scheme_url/onlineUrl, and content.sources[]
6. Eligibility RPC (public.mss_lookup_catalog) and search RPC (public.mss_search_data) return new schemes
"""

import json
import os
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

def run_query(sql):
    tmp_path = os.path.join("backend", "temp_p6_val.sql")
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(sql)
    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_p6_val.sql"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    res = subprocess.run(cmd, cwd="backend", capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, shell=True)
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    return res.stdout, res.stderr, res.returncode

def parse_rows(stdout):
    try:
        idx = stdout.find("{")
        if idx != -1:
            data = json.loads(stdout[idx:])
            return data.get("rows", [])
    except Exception as e:
        print("JSON parse error:", e)
    return []

def main():
    print("==========================================================================")
    print("PHASE 6 STEP 1: COMPREHENSIVE DATABASE INTEGRITY VALIDATION")
    print("==========================================================================\n")

    results = {}

    # Check 1: Scheme counts
    print("1. Validating Scheme Counts (catalog.scheme)...")
    sql1 = """
SELECT 
    count(*) as total_schemes,
    count(*) FILTER (WHERE id < 'SCH000220') as baseline_schemes,
    count(*) FILTER (WHERE id >= 'SCH000220' AND id <= 'SCH000302') as new_v3_1_schemes,
    count(*) FILTER (WHERE status = 'PUBLISHED') as published_count,
    count(*) FILTER (WHERE status = 'DRAFT') as draft_count,
    count(*) FILTER (WHERE status = 'ARCHIVED') as archived_count
FROM catalog.scheme;
"""
    out, err, rc = run_query(sql1)
    r1 = parse_rows(out)[0] if parse_rows(out) else {}
    results["scheme_counts"] = r1
    print(f"   Total schemes: {r1.get('total_schemes')} (Baseline: {r1.get('baseline_schemes')}, New v3.1: {r1.get('new_v3_1_schemes')})")
    print(f"   Published: {r1.get('published_count')}, Draft: {r1.get('draft_count')}, Archived: {r1.get('archived_count')}")

    # Check 2: Relationship Symmetry (child_of <-> parent_of)
    print("\n2. Validating Relationship Symmetry (child_of <-> parent_of)...")
    sql2 = """
SELECT 
    (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'child_of') as child_of_count,
    (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'parent_of') as parent_of_count,
    (
        SELECT count(*) 
        FROM catalog.relationships r1
        WHERE r1.relationship_type = 'child_of'
          AND NOT EXISTS (
              SELECT 1 FROM catalog.relationships r2
              WHERE r2.relationship_type = 'parent_of'
                AND r2.source_id = r1.target_id
                AND r2.target_id = r1.source_id
          )
    ) as asymmetric_child_of_count,
    (
        SELECT count(*) 
        FROM catalog.relationships r1
        WHERE r1.relationship_type = 'parent_of'
          AND NOT EXISTS (
              SELECT 1 FROM catalog.relationships r2
              WHERE r2.relationship_type = 'child_of'
                AND r2.source_id = r1.target_id
                AND r2.target_id = r1.source_id
          )
    ) as asymmetric_parent_of_count;
"""
    out, err, rc = run_query(sql2)
    r2 = parse_rows(out)[0] if parse_rows(out) else {}
    results["relationship_symmetry"] = r2
    print(f"   child_of count: {r2.get('child_of_count')}, parent_of count: {r2.get('parent_of_count')}")
    print(f"   Asymmetric child_of: {r2.get('asymmetric_child_of_count')}, Asymmetric parent_of: {r2.get('asymmetric_parent_of_count')}")

    # Check 3: Orphan Relationships
    print("\n3. Validating Orphan Relationships (source/target IDs exist)...")
    sql3 = """
SELECT 
    count(*) as total_relationships,
    count(*) FILTER (
        WHERE source_type = 'scheme' 
          AND NOT EXISTS (SELECT 1 FROM catalog.scheme s WHERE s.id = r.source_id)
    ) as orphan_source_schemes,
    count(*) FILTER (
        WHERE target_type = 'scheme' 
          AND NOT EXISTS (SELECT 1 FROM catalog.scheme s WHERE s.id = r.target_id)
    ) as orphan_target_schemes,
    count(*) FILTER (
        WHERE target_type = 'authority' 
          AND NOT EXISTS (SELECT 1 FROM catalog.authority a WHERE a.id = r.target_id)
    ) as orphan_target_authorities
FROM catalog.relationships r;
"""
    out, err, rc = run_query(sql3)
    r3 = parse_rows(out)[0] if parse_rows(out) else {}
    results["orphan_relationships"] = r3
    print(f"   Total relationships: {r3.get('total_relationships')}")
    print(f"   Orphan source schemes: {r3.get('orphan_source_schemes')}")
    print(f"   Orphan target schemes: {r3.get('orphan_target_schemes')}")
    print(f"   Orphan target authorities: {r3.get('orphan_target_authorities')}")

    # Check 4: Checksums Updated by Trigger
    print("\n4. Validating Row Checksums on catalog.scheme...")
    sql4 = """
SELECT 
    count(*) as total_schemes,
    count(*) FILTER (WHERE checksum IS NULL) as null_checksums,
    count(*) FILTER (WHERE checksum != encode(digest(record_json::text, 'sha256'), 'hex')) as mismatched_checksums
FROM catalog.scheme;
"""
    out, err, rc = run_query(sql4)
    r4 = parse_rows(out)[0] if parse_rows(out) else {}
    results["checksum_integrity"] = r4
    print(f"   Null checksums: {r4.get('null_checksums')}")
    print(f"   Mismatched checksums: {r4.get('mismatched_checksums')}")

    # Check 5: Published Row Requirements for New Schemes
    print("\n5. Validating Published Row Requirements for New Schemes (SCH000220-SCH000302)...")
    sql5 = """
SELECT 
    count(*) as new_published_count,
    count(*) FILTER (WHERE name_en IS NULL OR trim(name_en) = '') as missing_name_en,
    count(*) FILTER (WHERE scheme_url IS NULL AND (record_json->'applicationProcess'->>'onlineUrl') IS NULL) as missing_urls,
    count(*) FILTER (WHERE jsonb_array_length(record_json->'content'->'sources') = 0) as missing_sources
FROM catalog.scheme
WHERE id >= 'SCH000220' AND id <= 'SCH000302' AND status = 'PUBLISHED';
"""
    out, err, rc = run_query(sql5)
    r5 = parse_rows(out)[0] if parse_rows(out) else {}
    results["published_requirements"] = r5
    print(f"   New Published schemes: {r5.get('new_published_count')}")
    print(f"   Missing name_en: {r5.get('missing_name_en')}")
    print(f"   Missing URLs: {r5.get('missing_urls')}")
    print(f"   Missing sources: {r5.get('missing_sources')}")

    # Check 6: Search & Eligibility RPC spot checks
    print("\n6. Checking Search Data & Eligibility RPCs...")
    sql6 = """
SELECT 
    scheme_id,
    name_en,
    search_record->'schemeSearchProfile'->>'name' as search_name,
    search_record->'tokens'->>'en' as sample_tokens
FROM public.mss_search_data()
WHERE scheme_id IN ('SCH000269', 'SCH000272', 'SCH000274', 'SCH000302')
ORDER BY scheme_id;
"""
    out, err, rc = run_query(sql6)
    r6 = parse_rows(out)
    results["search_data_spot_checks"] = r6
    print("   Search Data RPC Spot Checks:")
    for row in r6:
        print(f"   -> [{row.get('scheme_id')}] {row.get('name_en')}")

    # Check 7: Eligibility Catalog Lookup
    print("\n7. Checking Eligibility Catalog Lookup (public.mss_lookup_catalog)...")
    sql7 = """
SELECT count(*) as eligibility_rows,
       count(*) FILTER (WHERE id >= 'SCH000220' AND id <= 'SCH000302') as new_staged_eligibility_rows
FROM public.mss_lookup_catalog('applicability_matrix');
"""
    out, err, rc = run_query(sql7)
    r7 = parse_rows(out)[0] if parse_rows(out) else {}
    results["eligibility_lookup"] = r7
    print(f"   Total eligibility matrix rows via RPC: {r7.get('eligibility_rows')}")
    print(f"   New v3.1 rows in RPC: {r7.get('new_staged_eligibility_rows')}")

    # Save to report
    rep_path = os.path.join("reports", "phase6_step1_validation_report.json")
    os.makedirs(os.path.dirname(rep_path), exist_ok=True)
    with open(rep_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\nSaved validation results to {rep_path}.")

if __name__ == "__main__":
    main()
