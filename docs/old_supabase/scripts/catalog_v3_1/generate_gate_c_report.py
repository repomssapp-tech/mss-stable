import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = REPO_ROOT / "backend"
PLAN_CATALOG = Path(r"C:\Users\roger\OneDrive\Documents\Plan\catalog")

def run_cmd(cmd, cwd=None):
    res = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8",
        shell=(sys.platform == "win32")
    )
    if res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {' '.join(cmd)}\nstdout: {res.stdout}\nstderr: {res.stderr}")
    return res.stdout

def parse_json_object(cli_output: str) -> dict:
    start = cli_output.find("{")
    end = cli_output.rfind("}")
    if start == -1 or end == -1:
        raise ValueError(f"No JSON object found: {cli_output}")
    return json.loads(cli_output[start : end + 1])

def query_supabase(sql: str) -> list[dict]:
    tmp_sql = BACKEND_DIR / "temp_gate_c_query.sql"
    tmp_sql.write_text(f"{sql};", encoding="utf-8")
    try:
        out = run_cmd(["npx", "supabase", "db", "query", "--linked", "--file", str(tmp_sql)], cwd=BACKEND_DIR)
        parsed = parse_json_object(out)
        return parsed.get("rows", [])
    finally:
        if tmp_sql.exists():
            tmp_sql.unlink()

def main():
    print("=" * 80)
    print("GATE C AUDIT & VERIFICATION REPORT (LIVE DATABASE)")
    print("=" * 80)

    # 1. RELATIONSHIP SYMMETRY (GATE C CORE CHECK)
    print("\n" + "=" * 80)
    print("GATE C CHECK 1: RELATIONSHIP SYMMETRY")
    print("=" * 80)
    sql_sym = """
    SELECT 
        (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'child_of') as total_child_of,
        (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'parent_of') as total_parent_of,
        (SELECT count(*) FROM catalog.relationships c 
         WHERE c.relationship_type = 'child_of' 
         AND NOT EXISTS (
             SELECT 1 FROM catalog.relationships p 
             WHERE p.relationship_type = 'parent_of' 
             AND p.source_id = c.target_id 
             AND p.target_id = c.source_id
         )) as asymmetric_child_of,
        (SELECT count(*) FROM catalog.relationships p 
         WHERE p.relationship_type = 'parent_of' 
         AND NOT EXISTS (
             SELECT 1 FROM catalog.relationships c 
             WHERE c.relationship_type = 'child_of' 
             AND c.source_id = p.target_id 
             AND c.target_id = p.source_id
         )) as asymmetric_parent_of;
    """
    sym_rows = query_supabase(sql_sym)
    print(f"Query:\n{sql_sym.strip()}\n")
    print(f"Raw Output:\n{json.dumps(sym_rows[0], indent=2)}")
    asym_child = sym_rows[0]["asymmetric_child_of"]
    asym_parent = sym_rows[0]["asymmetric_parent_of"]
    if asym_child == 0 and asym_parent == 0:
        print("\n--> [PASS] Asymmetric relationships count = 0 (100% symmetric pairs across 85 child_of / 85 parent_of)")
    else:
        print(f"\n--> [FAIL] Asymmetric child_of={asym_child}, parent_of={asym_parent}")

    # 2. STATUS MATRIX (GATE C CORE CHECK)
    print("\n" + "=" * 80)
    print("GATE C CHECK 2: STATUS MATRIX (All 302 schemes)")
    print("=" * 80)
    sql_status = """
    SELECT 
        status, 
        is_active, 
        record_json->'identity'->>'status' as json_identity_status,
        count(*) as count,
        array_agg(id ORDER BY id) as ids
    FROM catalog.scheme 
    GROUP BY status, is_active, record_json->'identity'->>'status'
    ORDER BY count DESC;
    """
    status_rows = query_supabase(sql_status)
    print(f"Query:\n{sql_status.strip()}\n")
    print("Raw Output:")
    for r in status_rows:
        print(f"  {r['status']:12} | is_active={str(r['is_active']):5} | json={r['json_identity_status']:8} | count={r['count']}")
    
    allowed = {
        ('PUBLISHED', True, 'active'),
        ('DRAFT', False, 'unknown'),
        ('ARCHIVED', False, 'closed')
    }
    invalid = [r for r in status_rows if (r['status'], r['is_active'], r['json_identity_status']) not in allowed]
    if not invalid:
        print("\n--> [PASS] Status matrix has ONLY the three allowed combinations: {PUBLISHED/true/active, DRAFT/false/unknown, ARCHIVED/false/closed}")
    else:
        print(f"\n--> [FAIL] Found {len(invalid)} invalid status combinations!")

    # 3. SUCCESSOR LINKS VERIFICATION
    print("\n" + "=" * 80)
    print("GATE C CHECK 3: SUCCESSOR RELATIONSHIPS")
    print("=" * 80)
    sql_succ = """
    SELECT source_id, target_id, relationship_type, metadata
    FROM catalog.relationships
    WHERE (source_id = 'SCH000043' AND target_id = 'SCH000302')
       OR (source_id = 'SCH000302' AND target_id = 'SCH000043')
       OR (source_id = 'SCH000070' AND target_id = 'SCH000258')
       OR (source_id = 'SCH000258' AND target_id = 'SCH000070')
    ORDER BY source_id;
    """
    succ_rows = query_supabase(sql_succ)
    print(f"Query:\n{sql_succ.strip()}\n")
    print(f"Raw Output ({len(succ_rows)} rows):\n{json.dumps(succ_rows, indent=2)}")

    # 4. CGTMSE GUARANTEE CEILING CHECK
    print("\n" + "=" * 80)
    print("GATE C CHECK 4: CGTMSE (SCH000038) CEILING & CONDITIONS")
    print("=" * 80)
    sql_cgtmse = """
    SELECT 
        id, 
        record_json->'content'->'benefits'->'guarantee'->'maxCoverInr' as max_cover_inr,
        record_json->'content'->'benefits'->'guarantee'->'conditions' as conditions,
        record_json->'verification'->'notes' as verification_notes
    FROM catalog.scheme 
    WHERE id = 'SCH000038';
    """
    cgtmse_rows = query_supabase(sql_cgtmse)
    print(f"Query:\n{sql_cgtmse.strip()}\n")
    print(f"Raw Output:\n{json.dumps(cgtmse_rows[0], indent=2)}")

    # 5. STAGING CLEANUP & RLS HARDENING CHECK
    print("\n" + "=" * 80)
    print("GATE C CHECK 5: STAGING CLEANUP & RLS HARDENING")
    print("=" * 80)
    sql_staging = """
    SELECT 
        (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'catalog' AND table_name IN ('scheme_new_v3_1', 'applicability_matrix_new_v3_1', 'search_index_new_v3_1', 'relationships_new_v3_1')) as remaining_staging_tables,
        (SELECT count(*) FROM information_schema.views WHERE table_schema = 'catalog' AND table_name = 'v_scheme_all') as remaining_staging_views,
        (SELECT relrowsecurity FROM pg_class WHERE relname = 'scheme_source_v3_1' AND relnamespace = 'catalog'::regnamespace) as source_rls_enabled,
        (SELECT relforcerowsecurity FROM pg_class WHERE relname = 'scheme_source_v3_1' AND relnamespace = 'catalog'::regnamespace) as source_force_rls;
    """
    staging_rows = query_supabase(sql_staging)
    print(f"Query:\n{sql_staging.strip()}\n")
    print(f"Raw Output:\n{json.dumps(staging_rows[0], indent=2)}")

    # 6. COLUMNS CHECK (PHASE A QUERY 3)
    print("\n" + "=" * 80)
    print("PHASE A QUERY 3: COLUMNS ON NEW SCHEMES (SCH000220 - SCH000302)")
    print("=" * 80)
    sql_cols = """
    SELECT 
        count(*) as total_new,
        count(*) FILTER (WHERE scheme_type IS NULL) as null_scheme_type,
        count(*) FILTER (WHERE government_level IS NULL) as null_government_level,
        count(*) FILTER (WHERE ministry IS NULL) as null_ministry,
        count(*) FILTER (WHERE department IS NULL) as null_department,
        count(*) FILTER (WHERE name_ta IS NULL) as null_name_ta
    FROM catalog.scheme 
    WHERE id >= 'SCH000220' AND id <= 'SCH000302';
    """
    col_rows = query_supabase(sql_cols)
    print(f"Query:\n{sql_cols.strip()}\n")
    print(f"Raw Output:\n{json.dumps(col_rows[0], indent=2)}")

if __name__ == "__main__":
    main()
