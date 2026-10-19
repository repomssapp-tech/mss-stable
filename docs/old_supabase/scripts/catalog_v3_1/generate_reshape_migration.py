#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/catalog_v3_1/generate_reshape_migration.py

Generates Phase D migration:
backend/supabase/migrations/20261005011500_catalog_v3_1_reshape_new_records.sql

Uses UPDATEs keyed by id for the 83 new records (SCH000220 - SCH000302)
across catalog.scheme, catalog.applicability_matrix, and catalog.search_index.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

CAT_DIR = Path(r"C:\Users\roger\OneDrive\Documents\Plan\catalog")
MIGRATION_PATH = Path("backend/supabase/migrations/20261005011500_catalog_v3_1_reshape_new_records.sql")

def escape_sql_str(val: str | None) -> str:
    if val is None:
        return "NULL"
    return "'" + val.replace("'", "''") + "'"

def escape_sql_json(obj: dict | list) -> str:
    raw = json.dumps(obj, ensure_ascii=False)
    return "'" + raw.replace("'", "''") + "'::jsonb"

def escape_sql_array(arr: list[str] | None) -> str:
    if not arr:
        return "ARRAY[]::text[]"
    elements = [escape_sql_str(x) for x in arr]
    return f"ARRAY[{', '.join(elements)}]::text[]"

def main():
    with open(CAT_DIR / "scheme_catalog.json", "r", encoding="utf-8") as f:
        schemes = json.load(f)["data"]
    new_schemes = [s for s in schemes if 220 <= int(s["identity"]["id"].replace("SCH", "")) <= 302]
    new_schemes.sort(key=lambda s: s["identity"]["id"])

    with open(CAT_DIR / "applicability_matrix_catalog.json", "r", encoding="utf-8") as f:
        matrices = json.load(f)["data"]
    m_by_scheme = {m["content"]["schemeId"]: m for m in matrices}

    with open(CAT_DIR / "search_index.json", "r", encoding="utf-8") as f:
        search_entries = json.load(f)["data"]
    s_by_scheme = {s["entityId"]: s for s in search_entries if s.get("entityType") == "scheme"}

    lines = [
        "-- ==========================================================================",
        "-- MIGRATION: 20261005011500_catalog_v3_1_reshape_new_records.sql",
        "-- Purpose: Apply Phase B reshaped reference contract to the 83 new records",
        "--          (SCH000220 - SCH000302) across catalog.scheme, applicability_matrix,",
        "--          and search_index using UPDATEs keyed by id.",
        "-- ==========================================================================",
        "BEGIN;",
        "",
        "-- ==========================================================================",
        "-- 1. UPDATE catalog.scheme (83 records)",
        "-- ==========================================================================",
    ]

    for s in new_schemes:
        sid = s["identity"]["id"]
        cl = s["content"]["classification"]
        gov = cl["government"]
        
        st = cl.get("schemeType")
        gl = gov.get("level")
        min_text = gov.get("ministryText")
        dept_text = gov.get("departmentText")
        states = gov.get("states") or []
        state_val = states[0] if states else None
        min_id = gov.get("ministryId")
        tags = cl.get("tags") or []
        
        lines.append(f"-- {sid}: {s['identity']['name']}")
        lines.append("UPDATE catalog.scheme SET")
        lines.append(f"    scheme_type = {escape_sql_str(st)},")
        lines.append(f"    government_level = {escape_sql_str(gl)},")
        lines.append(f"    ministry = {escape_sql_str(min_text)},")
        lines.append(f"    department = {escape_sql_str(dept_text)},")
        lines.append(f"    state = {escape_sql_str(state_val)},")
        lines.append(f"    primary_authority_id = {escape_sql_str(min_id)},")
        lines.append(f"    search_keywords = {escape_sql_array(tags)},")
        lines.append(f"    record_json = {escape_sql_json(s)},")
        lines.append("    updated_at = now()")
        lines.append(f"WHERE id = '{sid}';")
        lines.append("")

    lines.append("-- ==========================================================================")
    lines.append("-- 2. UPDATE catalog.applicability_matrix (83 records)")
    lines.append("-- ==========================================================================")

    for s in new_schemes:
        sid = s["identity"]["id"]
        m = m_by_scheme[sid]
        mid = m["identity"]["id"]
        mc = m["content"]
        
        gl = mc.get("governmentLevel")
        sec_text = mc.get("sectorText")
        dist_text = mc.get("districtText")
        
        lines.append(f"-- {mid} ({sid})")
        lines.append("UPDATE catalog.applicability_matrix SET")
        lines.append(f"    government_level = {escape_sql_str(gl)},")
        lines.append(f"    sector_text = {escape_sql_str(sec_text)},")
        lines.append(f"    district_text = {escape_sql_str(dist_text)},")
        lines.append(f"    record_json = {escape_sql_json(m)},")
        lines.append("    updated_at = now()")
        lines.append(f"WHERE id = '{mid}';")
        lines.append("")

    lines.append("-- ==========================================================================")
    lines.append("-- 3. UPDATE catalog.search_index (83 records)")
    lines.append("-- ==========================================================================")

    for s in new_schemes:
        sid = s["identity"]["id"]
        se = s_by_scheme[sid]
        
        name_en = se.get("name", {}).get("en") or s["identity"]["name"]
        keywords_en = " ".join(se.get("keywords", {}).get("en") or [])
        aliases_en = " ".join(se.get("aliases", {}).get("en") or [])
        code = se.get("code") or ""
        
        content_text = f"{name_en} {keywords_en} {aliases_en} {code}".strip()
        
        lines.append(f"-- Search Index for {sid}")
        lines.append("UPDATE catalog.search_index SET")
        lines.append(f"    content = {escape_sql_str(content_text)},")
        lines.append(f"    record_json = {escape_sql_json(se)},")
        lines.append("    updated_at = now()")
        lines.append(f"WHERE scheme_id = '{sid}';")
        lines.append("")

    lines.append("COMMIT;")
    lines.append("")

    content = "\n".join(lines)
    with open(MIGRATION_PATH, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Generated {MIGRATION_PATH} successfully ({len(content)} bytes, {len(new_schemes)} schemes updated).")

if __name__ == "__main__":
    main()
