"""
Staging Setup & Source Table Loader:
1. Creates staging tables:
   - catalog.scheme_new_v3_1
   - catalog.applicability_matrix_new_v3_1
   - catalog.search_index_new_v3_1
   - catalog.relationships_new_v3_1
2. Copies 83 new schemes (SCH000220 - SCH000302) and their matrices, search indexes,
   and relationships into the staging tables.
3. Reverts active catalog tables to baseline:
   - catalog.scheme reverts to 219
   - catalog.applicability_matrix reverts to 219
   - catalog.search_index reverts to 971
   - catalog.relationships reverts to 1,718
4. Creates and populates catalog.scheme_source_v3_1 holding all 393 raw v3.1 records.
5. Applies security lockdown (no anon/authenticated access) and creates catalog.v_scheme_all preview view.
"""

import json
import os
import subprocess
import sys

DATA_DIR = os.path.join("docs", "backend", "mss_scheme_data_v3_1", "mss_scheme_data_v3_1", "data")
MIGRATION_PATH = os.path.join("backend", "supabase", "migrations", "20261004200000_catalog_v3_1_staging_and_source.sql")

def run_query(sql):
    tmp_path = os.path.join("backend", "temp_staging_query.sql")
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(sql)
    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_staging_query.sql"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    res = subprocess.run(cmd, cwd="backend", capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, shell=True)
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    return res.stdout, res.stderr, res.returncode

def escape_sql_str(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"

def main():
    print("Preparing Staging & Source Migration...")

    # Load 393 source records
    src_path = os.path.join(DATA_DIR, "msme_schemes_v3_1.json")
    with open(src_path, "r", encoding="utf-8") as f:
        src_data = json.load(f)
    schemes = src_data.get("schemes", src_data)
    print(f"Loaded {len(schemes)} raw schemes from msme_schemes_v3_1.json")

    sql_parts = []
    sql_parts.append("-- ==========================================================================")
    sql_parts.append("-- MIGRATION: 20261004200000_catalog_v3_1_staging_and_source.sql")
    sql_parts.append("-- Purpose: Move SCH000220-SCH000302 into staging for isolated testing,")
    sql_parts.append("--          revert active catalog to baseline, and archive 393 source records.")
    sql_parts.append("-- ==========================================================================\n")
    sql_parts.append("BEGIN;\n")

    # 1. Staging tables
    sql_parts.append("""
-- 1. Create Staging Tables
CREATE TABLE IF NOT EXISTS catalog.scheme_new_v3_1 (
    LIKE catalog.scheme INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
);

CREATE TABLE IF NOT EXISTS catalog.applicability_matrix_new_v3_1 (
    LIKE catalog.applicability_matrix INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
);

CREATE TABLE IF NOT EXISTS catalog.search_index_new_v3_1 (
    LIKE catalog.search_index INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
);

CREATE TABLE IF NOT EXISTS catalog.relationships_new_v3_1 (
    LIKE catalog.relationships INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
);

-- Phase 5 Source Reference Table
CREATE TABLE IF NOT EXISTS catalog.scheme_source_v3_1 (
    id text PRIMARY KEY,
    source text NOT NULL,
    record jsonb NOT NULL,
    imported_at timestamptz NOT NULL DEFAULT now()
);
""")

    # 2. Copy data into staging
    sql_parts.append("""
-- 2. Populate Staging Tables from Active Tables (SCH000220 - SCH000302)
INSERT INTO catalog.scheme_new_v3_1
SELECT * FROM catalog.scheme 
WHERE id >= 'SCH000220' AND id <= 'SCH000302'
ON CONFLICT (id) DO UPDATE SET 
    record_json = EXCLUDED.record_json,
    checksum = EXCLUDED.checksum,
    updated_at = EXCLUDED.updated_at;

INSERT INTO catalog.applicability_matrix_new_v3_1
SELECT * FROM catalog.applicability_matrix 
WHERE scheme_id >= 'SCH000220' AND scheme_id <= 'SCH000302'
ON CONFLICT (id) DO UPDATE SET 
    record_json = EXCLUDED.record_json,
    checksum = EXCLUDED.checksum,
    updated_at = EXCLUDED.updated_at;

INSERT INTO catalog.search_index_new_v3_1
SELECT * FROM catalog.search_index 
WHERE scheme_id >= 'SCH000220' AND scheme_id <= 'SCH000302'
ON CONFLICT (id) DO UPDATE SET 
    record_json = EXCLUDED.record_json,
    content = EXCLUDED.content,
    updated_at = EXCLUDED.updated_at;

INSERT INTO catalog.relationships_new_v3_1
SELECT * FROM catalog.relationships 
WHERE (source_id >= 'SCH000220' AND source_id <= 'SCH000302')
   OR (target_id >= 'SCH000220' AND target_id <= 'SCH000302')
ON CONFLICT (id) DO NOTHING;
""")

    # 3. Revert active catalog tables
    sql_parts.append("""
-- 3. Revert Active Tables to Clean Baseline (Delete Staged Schemes from Active Tables)
DELETE FROM catalog.search_index 
WHERE scheme_id >= 'SCH000220' AND scheme_id <= 'SCH000302';

DELETE FROM catalog.applicability_matrix 
WHERE scheme_id >= 'SCH000220' AND scheme_id <= 'SCH000302';

DELETE FROM catalog.relationships 
WHERE (source_id >= 'SCH000220' AND source_id <= 'SCH000302')
   OR (target_id >= 'SCH000220' AND target_id <= 'SCH000302');

DELETE FROM catalog.scheme 
WHERE id >= 'SCH000220' AND id <= 'SCH000302';
""")

    # 4. Insert 393 source records into catalog.scheme_source_v3_1
    sql_parts.append("\n-- 4. Ingest 393 Raw Source Records into catalog.scheme_source_v3_1")
    for s in schemes:
        sid = s["id"]
        s_json = json.dumps(s, ensure_ascii=False).replace("'", "''")
        sql_parts.append(f"""
INSERT INTO catalog.scheme_source_v3_1 (id, source, record, imported_at)
VALUES ('{sid}', 'msme_schemes_v3_1', '{s_json}'::jsonb, now())
ON CONFLICT (id) DO UPDATE SET record = EXCLUDED.record, imported_at = EXCLUDED.imported_at;""")

    # 5. Security lockdown & RLS
    sql_parts.append("""
-- 5. Security Lockdown & RLS Configuration
ALTER TABLE catalog.scheme_new_v3_1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog.applicability_matrix_new_v3_1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog.search_index_new_v3_1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog.relationships_new_v3_1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog.scheme_source_v3_1 ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON catalog.scheme_new_v3_1 FROM anon, authenticated;
REVOKE ALL ON catalog.applicability_matrix_new_v3_1 FROM anon, authenticated;
REVOKE ALL ON catalog.search_index_new_v3_1 FROM anon, authenticated;
REVOKE ALL ON catalog.relationships_new_v3_1 FROM anon, authenticated;
REVOKE ALL ON catalog.scheme_source_v3_1 FROM anon, authenticated;

GRANT ALL ON catalog.scheme_new_v3_1 TO postgres, service_role;
GRANT ALL ON catalog.applicability_matrix_new_v3_1 TO postgres, service_role;
GRANT ALL ON catalog.search_index_new_v3_1 TO postgres, service_role;
GRANT ALL ON catalog.relationships_new_v3_1 TO postgres, service_role;
GRANT ALL ON catalog.scheme_source_v3_1 TO postgres, service_role;

-- 6. Unified Preview View (For Testing Queries Without Affecting Production Tables)
CREATE OR REPLACE VIEW catalog.v_scheme_all AS
SELECT 
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_code, name_en, name_ta, government_level, scheme_type, state,
    ministry, department, search_keywords, primary_authority_id,
    primary_institution_id, is_active, scheme_url, false AS is_staged
FROM catalog.scheme
UNION ALL
SELECT 
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_code, name_en, name_ta, government_level, scheme_type, state,
    ministry, department, search_keywords, primary_authority_id,
    primary_institution_id, is_active, scheme_url, true AS is_staged
FROM catalog.scheme_new_v3_1;

COMMIT;
""")

    full_sql = "\n".join(sql_parts)

    os.makedirs(os.path.dirname(MIGRATION_PATH), exist_ok=True)
    with open(MIGRATION_PATH, "w", encoding="utf-8") as f:
        f.write(full_sql)
    print(f"Wrote migration to {MIGRATION_PATH} ({len(full_sql)} bytes).")

    print("Executing migration on linked database...")
    stdout, stderr, rc = run_query(full_sql)
    if rc != 0:
        print("ERROR running migration:")
        print(stderr)
        print(stdout)
        sys.exit(1)
    print("Migration executed successfully.")

    print("\nVerifying Table Counts post-migration...")
    verify_sql = """
SELECT 
    (SELECT count(*) FROM catalog.scheme) as active_schemes,
    (SELECT count(*) FROM catalog.scheme_new_v3_1) as staged_schemes,
    (SELECT count(*) FROM catalog.applicability_matrix) as active_matrices,
    (SELECT count(*) FROM catalog.applicability_matrix_new_v3_1) as staged_matrices,
    (SELECT count(*) FROM catalog.search_index) as active_search_index,
    (SELECT count(*) FROM catalog.search_index_new_v3_1) as staged_search_index,
    (SELECT count(*) FROM catalog.relationships) as active_relationships,
    (SELECT count(*) FROM catalog.relationships_new_v3_1) as staged_relationships,
    (SELECT count(*) FROM catalog.scheme_source_v3_1) as source_v3_1_records,
    (SELECT count(*) FROM catalog.v_scheme_all) as total_view_schemes;
"""
    v_out, v_err, v_rc = run_query(verify_sql)
    print("Verification output:")
    print(v_out)

if __name__ == "__main__":
    main()
