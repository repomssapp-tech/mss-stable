"""
Phase 4 Runner: Add New Schemes (83 Schemes)
- Allocates SCH000220 to SCH000302 for 83 schemes in 01_new_scheme_actions.csv
- Generates reports/id_map.csv
- Maps record_json, relationships, applicability_matrix, search_index
- Creates and runs migration backend/supabase/migrations/20261004193500_catalog_v3_1_add_schemes.sql
"""

import copy
import csv
import json
import os
import re
import subprocess
from datetime import datetime, timezone

from builder import map_v3_1_to_record_json, format_inr, resolve_ministry

WORKLIST_DIR = os.path.join("docs", "backend", "mss_scheme_data_v3_1", "mss_scheme_data_v3_1", "worklists")
DATA_DIR = os.path.join("docs", "backend", "mss_scheme_data_v3_1", "mss_scheme_data_v3_1", "data")
MIGRATION_PATH = os.path.join("backend", "supabase", "migrations", "20261004193500_catalog_v3_1_add_schemes.sql")

def run_query(sql):
    tmp_path = os.path.join("backend", "temp_p4_query.sql")
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(sql)
    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_p4_query.sql"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    res = subprocess.run(cmd, cwd="backend", capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, shell=True)
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    return res.stdout, res.stderr, res.returncode

def load_v3_data():
    v3_schemes = {}
    p1 = os.path.join(DATA_DIR, "msme_schemes_v3_1.json")
    if os.path.exists(p1):
        with open(p1, "r", encoding="utf-8") as f:
            d = json.load(f)
            items = d.get("schemes", d) if isinstance(d, dict) else d
            for s in items:
                v3_schemes[s["id"]] = s

    p2 = os.path.join(DATA_DIR, "new_schemes_2025_26.json")
    if os.path.exists(p2):
        with open(p2, "r", encoding="utf-8") as f:
            d = json.load(f)
            items = d.get("schemes", d) if isinstance(d, dict) else d
            for s in items:
                v3_schemes[s["id"]] = s
    return v3_schemes

def main():
    print("Loading datasets and action worklist...")
    v3_data = load_v3_data()
    print(f"Loaded {len(v3_data)} v3.1 raw schemes.")

    with open(os.path.join(WORKLIST_DIR, "01_new_scheme_actions.csv"), encoding="utf-8") as f:
        all_action_rows = list(csv.DictReader(f))

    # Existing map from our_id to catalog_id
    existing_our_to_cat = {}
    for r in all_action_rows:
        if r["catalog_ids"]:
            # Pick first/canonical ID if semicolon-separated
            first_id = r["catalog_ids"].split(";")[0].strip()
            existing_our_to_cat[r["our_id"]] = first_id

    # Filter to ADD_NEW and ADD_CHILD
    new_action_rows = [r for r in all_action_rows if r["action"] in ("ADD_NEW", "ADD_CHILD")]
    print(f"Total new scheme actions: {len(new_action_rows)}")

    open_issues_by_our_id = {}
    with open(os.path.join(WORKLIST_DIR, "05_open_issues.csv"), encoding="utf-8") as f:
        for r in csv.DictReader(f):
            open_issues_by_our_id.setdefault(r["our_id"], []).append(r)

    # 1. Allocate IDs: SCH000220 to SCH000302
    start_num = 220
    id_map = []
    our_to_allocated = {}

    for idx, r in enumerate(new_action_rows):
        cat_id = f"SCH{start_num + idx:06d}"
        our_id = r["our_id"]
        our_to_allocated[our_id] = cat_id

    # 2. Build full parent resolver
    def resolve_parent_catalog_id(parent_our_id):
        if not parent_our_id:
            return None
        if parent_our_id in our_to_allocated:
            return our_to_allocated[parent_our_id]
        if parent_our_id in existing_our_to_cat:
            return existing_our_to_cat[parent_our_id]
        return None

    # Populate id_map rows
    for r in new_action_rows:
        our_id = r["our_id"]
        cat_id = our_to_allocated[our_id]
        parent_cat_id = resolve_parent_catalog_id(r["parent_our_id"])
        id_map.append({
            "v3_1_id": our_id,
            "allocated_catalog_id": cat_id,
            "scheme_name": r["name_en"],
            "action": r["action"],
            "parent_id": parent_cat_id or "",
            "proposed_status": r["proposed_record_status"] or "PUBLISHED"
        })

    # Save reports/id_map.csv
    os.makedirs("reports", exist_ok=True)
    id_map_path = os.path.join("reports", "id_map.csv")
    with open(id_map_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["v3_1_id", "allocated_catalog_id", "scheme_name", "action", "parent_id", "proposed_status"])
        writer.writeheader()
        writer.writerows(id_map)
    print(f"Saved {len(id_map)} mappings to {id_map_path}")

    # Build SQL Statements
    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    scheme_inserts = []
    app_matrix_inserts = []
    rel_inserts = []
    search_inserts = []

    for item in id_map:
        our_id = item["v3_1_id"]
        cat_id = item["allocated_catalog_id"]
        action = item["action"]
        parent_cat_id = item["parent_id"] if item["parent_id"] else None
        target_status = item["proposed_status"]
        is_active = (target_status == "PUBLISHED")

        v3_rec = v3_data.get(our_id)
        if not v3_rec:
            print(f"Warning: {our_id} not found in v3_data!")
            continue

        issues = open_issues_by_our_id.get(our_id, [])

        # Build record_json
        rj = map_v3_1_to_record_json(
            v3_rec=v3_rec,
            allocated_id=cat_id,
            action=action,
            parent_sch_id=parent_cat_id,
            open_issues=issues
        )
        rj["metadata"]["catalogVersion"] = "1.35.0-alpha"

        # Also align identity.status with target_status
        if target_status == "DRAFT":
            rj["identity"]["status"] = "unknown"
        elif target_status == "PUBLISHED":
            rj["identity"]["status"] = "active"

        name_en = rj["identity"]["name"]
        slug = rj["identity"]["slug"]
        scheme_type = rj["classification"]["schemeType"]
        min_id = rj["classification"]["government"]["ministryId"] or "AUTH000003"
        min_text = rj["classification"]["government"]["ministryText"] or "Ministry of MSME"
        dept_text = rj["classification"]["government"]["departmentText"] or min_text
        scheme_url = rj["content"].get("schemeUrl") or "https://www.dcmsme.gov.in"
        tags = rj["classification"].get("tags") or []
        tags_sql = "ARRAY[" + ", ".join([f"'{t}'" for t in tags]) + "]::text[]" if tags else "ARRAY[]::text[]"

        rj_escaped = json.dumps(rj, ensure_ascii=False).replace("'", "''")
        name_en_escaped = name_en.replace("'", "''")
        min_text_escaped = min_text.replace("'", "''")
        dept_text_escaped = dept_text.replace("'", "''")

        # 1. catalog.scheme INSERT
        scheme_sql = f"""
INSERT INTO catalog.scheme (
  id, version, status, record_json, scheme_code, name_en, name_ta,
  government_level, scheme_type, state, ministry, department, search_keywords,
  primary_authority_id, is_active, scheme_url, updated_at, published_at
) VALUES (
  '{cat_id}',
  '1.35.0-alpha',
  '{target_status}',
  '{rj_escaped}'::jsonb,
  '{cat_id}',
  '{name_en_escaped}',
  NULL,
  'central',
  '{scheme_type}',
  NULL,
  '{min_text_escaped}',
  '{dept_text_escaped}',
  '{name_en_escaped}',
  '{min_id}',
  {str(is_active).lower()},
  '{scheme_url}',
  NOW(),
  {"NOW()" if is_active else "NULL"}
);"""
        scheme_inserts.append(scheme_sql.strip())

        # 2. catalog.applicability_matrix INSERT
        aplm_id = f"APLM{int(cat_id.replace('SCH', '')):06d}"
        app_matrix_rj = {
            "entityId": cat_id,
            "entityType": "scheme",
            "name": {"en": name_en, "ta": None},
            "targeting": v3_rec.get("targeting") or {},
            "eligibility": rj["content"].get("eligibility", {})
        }
        app_matrix_rj_escaped = json.dumps(app_matrix_rj, ensure_ascii=False).replace("'", "''")

        app_matrix_sql = f"""
INSERT INTO catalog.applicability_matrix (
  id, version, status, record_json, scheme_id, government_level,
  department_authority_id, updated_at, published_at
) VALUES (
  '{aplm_id}',
  '1.35.0-alpha',
  '{target_status}',
  '{app_matrix_rj_escaped}'::jsonb,
  '{cat_id}',
  'central',
  '{min_id}',
  NOW(),
  {"NOW()" if is_active else "NULL"}
);"""
        app_matrix_inserts.append(app_matrix_sql.strip())

        # 3. catalog.relationships INSERT
        # Ministry administered_by
        rel_sql_min = f"""
INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', '{cat_id}', 'authority', '{min_id}', 'administered_by', '{{}}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = '{cat_id}' AND target_id = '{min_id}' AND relationship_type = 'administered_by'
);"""
        rel_inserts.append(rel_sql_min.strip())

        # Parent-child relationships (if child)
        if parent_cat_id:
            rel_sql_child = f"""
INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', '{cat_id}', 'scheme', '{parent_cat_id}', 'child_of', '{{}}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = '{cat_id}' AND target_id = '{parent_cat_id}' AND relationship_type = 'child_of'
);"""
            rel_sql_parent = f"""
INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', '{parent_cat_id}', 'scheme', '{cat_id}', 'parent_of', '{{}}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = '{parent_cat_id}' AND target_id = '{cat_id}' AND relationship_type = 'parent_of'
);"""
            rel_inserts.append(rel_sql_child.strip())
            rel_inserts.append(rel_sql_parent.strip())

        # 4. catalog.search_index INSERT
        # Build search text content
        aliases_en = rj.get("search", {}).get("aliases", {}).get("en") or []
        aliases_hi = rj.get("search", {}).get("aliases", {}).get("hi") or []
        keywords_en = rj.get("search", {}).get("keywords", {}).get("en") or []
        content_tokens = [name_en] + aliases_en + aliases_hi + keywords_en + tags
        content_str = " ".join([t for t in content_tokens if t])
        content_escaped = content_str.replace("'", "''")

        search_rj = {
            "entityId": cat_id,
            "entityType": "scheme",
            "name": {"en": name_en, "ta": None},
            "slug": slug,
            "status": "active" if is_active else "draft",
            "aliases": {"en": aliases_en, "ta": [], "hi": aliases_hi},
            "keywords": {"en": keywords_en, "ta": []},
            "tokens": {"en": [t.lower() for t in keywords_en]}
        }
        search_rj_escaped = json.dumps(search_rj, ensure_ascii=False).replace("'", "''")

        search_sql = f"""
INSERT INTO catalog.search_index (
  id, version, status, record_json, scheme_id, content, updated_at, published_at
) VALUES (
  '{cat_id}',
  '1.35.0-alpha',
  '{target_status}',
  '{search_rj_escaped}'::jsonb,
  '{cat_id}',
  '{content_escaped}',
  NOW(),
  {"NOW()" if is_active else "NULL"}
);"""
        search_inserts.append(search_sql.strip())

    # Build Complete Migration
    print(f"Prepared {len(scheme_inserts)} scheme inserts, {len(app_matrix_inserts)} applicability matrix inserts, {len(rel_inserts)} relationship inserts, {len(search_inserts)} search index inserts.")

    migration_sql = f"""-- Migration: catalog_v3_1_add_schemes
-- Created At: {now_iso}
-- Purpose: Ingest 83 new schemes (SCH000220 to SCH000302) from v3.1 dataset (ADD_NEW and ADD_CHILD).
-- Conforms to: ANTIGRAVITY_PROMPT.md Phase 4 specifications.
-- Trigger trg_recompute_checksum will automatically recompute SHA-256 row checksums.
-- Trigger trg_sync_entity_registry will automatically synchronize entity registry.

BEGIN;

-- ============================================================================
-- 1. CATALOG.SCHEME INSERTS (83 ROWS)
-- ============================================================================
{chr(10).join(scheme_inserts)}

-- ============================================================================
-- 2. CATALOG.APPLICABILITY_MATRIX INSERTS (83 ROWS)
-- ============================================================================
{chr(10).join(app_matrix_inserts)}

-- ============================================================================
-- 3. CATALOG.RELATIONSHIPS INSERTS
-- ============================================================================
{chr(10).join(rel_inserts)}

-- ============================================================================
-- 4. CATALOG.SEARCH_INDEX INSERTS (83 ROWS)
-- ============================================================================
{chr(10).join(search_inserts)}

COMMIT;

/*
-- DOWN MIGRATION (ROLLBACK):
BEGIN;
DELETE FROM catalog.search_index WHERE scheme_id >= 'SCH000220' AND scheme_id <= 'SCH000302';
DELETE FROM catalog.relationships WHERE (source_id >= 'SCH000220' AND source_id <= 'SCH000302') OR (target_id >= 'SCH000220' AND target_id <= 'SCH000302');
DELETE FROM catalog.applicability_matrix WHERE scheme_id >= 'SCH000220' AND scheme_id <= 'SCH000302';
DELETE FROM catalog.scheme WHERE id >= 'SCH000220' AND id <= 'SCH000302';
COMMIT;
*/
"""

    with open(MIGRATION_PATH, "w", encoding="utf-8") as f:
        f.write(migration_sql)
    print(f"Saved migration to {MIGRATION_PATH}")

    # Execute against linked DB
    print("Applying migration to linked DB...")
    stdout_mig, stderr_mig, code_mig = run_query(migration_sql)
    print(f"Migration result code: {code_mig}")
    if code_mig != 0:
        print("Migration stdout:", stdout_mig)
        print("Migration stderr:", stderr_mig)
        return

    print("Phase 4 executed successfully on linked DB!")

if __name__ == "__main__":
    main()
