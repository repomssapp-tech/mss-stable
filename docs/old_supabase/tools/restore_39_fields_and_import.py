#!/usr/bin/env python3
"""Restore 39 removed Hindi fields from 1.35.1-alpha bundle into backend/catalog/source/scheme_catalog.json
and rebuild catalog.content through normal DB import.
Per Decision D9: If a restored value fails the number check, keep it and flag it.
"""
from __future__ import annotations

import argparse
import gzip
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / "backend"
SCRATCH_DIR = BACKEND_DIR / "scratch" / "lang"
SOURCE_SCHEMES = BACKEND_DIR / "catalog" / "source" / "scheme_catalog.json"
P135_BUNDLE = ROOT_DIR / "scratch" / "storage_releases" / "1.35.1-alpha" / "catalog_bundle.json.gz"

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

DEV_TO_ASCII = str.maketrans("०१२३४५६७८९", "0123456789")

FIELD_MAP = {
    "summary": "summary",
    "objective": "objective",
    "description": "description",
    "benefitsText": "benefits_text",
    "eligibilityText": "eligibility_text",
    "applicationText": "application_text",
    "name": "name",
    "shortName": "short_name",
}


def extract_numbers(text: str | None) -> Counter:
    if not text:
        return Counter()
    norm = str(text).translate(DEV_TO_ASCII)
    tokens = re.findall(r"\b\d+(?:\.\d+)?\b", norm)
    result = []
    for t in tokens:
        try:
            val = float(t)
            result.append(int(val) if val.is_integer() else val)
        except ValueError:
            result.append(t)
    return Counter(result)


def escape_sql(val: str | None) -> str:
    if val is None:
        return "null"
    return "'" + str(val).replace("'", "''") + "'"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Apply updates to database")
    args = parser.parse_args()

    print("=== Step 1: Loading 1.35.1 bundle and Source Master ===")
    p_bundle = json.loads(gzip.decompress(P135_BUNDLE.read_bytes()).decode("utf-8"))
    p_schemes = {s["identity"]["id"]: s for s in p_bundle.get("scheme_catalog.json", {}).get("data", [])}

    source_data = json.loads(SOURCE_SCHEMES.read_text(encoding="utf-8"))
    source_schemes = {s["identity"]["id"]: s for s in source_data.get("data", [])}

    # Identify the 39 fields
    c_bundle_path = ROOT_DIR / "scratch" / "storage_releases" / "1.36.0-alpha" / "catalog_bundle.json.gz"
    c_bundle = json.loads(gzip.decompress(c_bundle_path.read_bytes()).decode("utf-8"))
    c_schemes = {s["identity"]["id"]: s for s in c_bundle.get("scheme_catalog.json", {}).get("data", [])}

    removed_fields = []
    for sid in sorted(p_schemes.keys()):
        p_hi = p_schemes[sid].get("localization", {}).get("hi", {})
        c_hi = c_schemes.get(sid, {}).get("localization", {}).get("hi", {})
        for f_camel, f_snake in FIELD_MAP.items():
            pv = p_hi.get(f_camel)
            cv = c_hi.get(f_camel)
            if (pv is not None and pv != "") and (cv is None or cv == ""):
                removed_fields.append((sid, f_camel, f_snake, pv))

    print(f"Identified {len(removed_fields)} removed fields from 1.35.1.")

    # Step 2: Ensure source master has all 39 values
    source_modified = False
    for sid, f_camel, f_snake, pv in removed_fields:
        s_obj = source_schemes.get(sid)
        if not s_obj:
            continue
        hi_loc = s_obj.setdefault("localization", {}).setdefault("hi", {})
        if hi_loc.get(f_camel) != pv:
            hi_loc[f_camel] = pv
            source_modified = True

    if source_modified:
        SOURCE_SCHEMES.write_text(json.dumps(source_data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("Updated backend/catalog/source/scheme_catalog.json with restored values.")
    else:
        print("backend/catalog/source/scheme_catalog.json already contains all 39 restored values.")

    # Step 3: Run number check on all 39 fields
    print("\n=== Step 2: Validating Number Checks against English Master ===")
    results = []
    sql_updates = []
    
    for sid, f_camel, f_snake, hi_val in removed_fields:
        s_obj = source_schemes[sid]
        en_val = (
            s_obj.get("attributes", {}).get(f_camel)
            or s_obj.get("content", {}).get(f_camel)
            or s_obj.get("localization", {}).get("en", {}).get(f_camel)
        )
        nums_en = extract_numbers(en_val)
        nums_hi = extract_numbers(hi_val)
        passes_numbers = (nums_en == nums_hi)

        status_str = "PASS" if passes_numbers else "FAIL (D9 FLAGGED)"
        flag_note = "" if passes_numbers else f"D9 review: EN={dict(nums_en)} vs HI={dict(nums_hi)}"
        results.append({
            "entity_id": sid,
            "field_camel": f_camel,
            "field_snake": f_snake,
            "status": status_str,
            "flag_note": flag_note,
            "hi_val": hi_val,
        })
        print(f"  {sid:<10} | {f_camel:<16} | {status_str:<18} | {flag_note}")

        # SQL update for catalog.content
        sql_updates.append(f"""
        UPDATE catalog.content
        SET {f_snake} = {escape_sql(hi_val)},
            origin = 'imported',
            engine = 'official_booklet_2025_26',
            updated_at = now()
        WHERE entity_type = 'scheme' AND entity_id = '{sid}' AND lang = 'hi';
        """)

        # Also register in admin.translation_jobs
        t_status = "COMPLETED" if passes_numbers else "FAILED"
        err_val = escape_sql(flag_note) if flag_note else "null"
        sql_updates.append(f"""
        INSERT INTO admin.translation_jobs (id, source_lang, target_lang, entity_type, entity_id, field_name, status, source_text, translated_text, errors, created_at, updated_at)
        VALUES (gen_random_uuid(), 'en', 'hi', 'scheme', '{sid}', '{f_snake}', '{t_status}', {escape_sql(en_val)}, {escape_sql(hi_val)}, {err_val}, now(), now());
        """)

    # Re-sync catalog.scheme record_json from catalog.content
    sync_scheme_sql = """
    WITH content_hi AS (
      SELECT 
        c.entity_id AS scheme_id,
        jsonb_strip_nulls(jsonb_build_object(
          'name', c.name,
          'shortName', c.short_name,
          'summary', c.summary,
          'objective', c.objective,
          'description', c.description,
          'benefitsText', c.benefits_text,
          'eligibilityText', c.eligibility_text,
          'applicationText', c.application_text
        )) AS loc_hi,
        to_jsonb(COALESCE(c.aliases, '{}'::text[])) AS aliases_hi
      FROM catalog.content c
      WHERE c.entity_type = 'scheme' AND c.lang = 'hi'
    )
    UPDATE catalog.scheme s
    SET record_json = jsonb_set(
      jsonb_set(
        s.record_json,
        '{search,aliases,hi}',
        c.aliases_hi
      ),
      '{localization,hi}',
      c.loc_hi
    )
    FROM content_hi c
    WHERE s.id = c.scheme_id;
    """

    # Update source_checksum
    checksum_sql = """
    UPDATE catalog.content h
    SET source_checksum = catalog.content_checksum(e.name, e.short_name, e.summary, e.objective, e.description, e.benefits_text, e.eligibility_text, e.application_text)
    FROM catalog.content e
    WHERE e.entity_type = 'scheme' AND e.entity_id = h.entity_id AND e.lang = 'en'
      AND h.entity_type = 'scheme' AND h.lang = 'hi';
    """

    full_sql = "BEGIN;\n" + "\n".join(sql_updates) + "\n" + sync_scheme_sql + "\n" + checksum_sql + "\nCOMMIT;"
    sql_file = SCRATCH_DIR / "restore_39_fields.sql"
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text(full_sql, encoding="utf-8")
    print(f"\nGenerated restore SQL saved to: {sql_file}")

    if args.apply:
        print("Applying SQL updates to linked Supabase database...")
        import subprocess
        cmd = f'npx supabase db query --linked --file "{sql_file}"'
        res = subprocess.run(cmd, cwd=str(BACKEND_DIR), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
        if res.returncode != 0:
            print("Database update failed:")
            print(res.stderr or res.stdout)
            sys.exit(1)
        print("Successfully rebuilt catalog.content and catalog.scheme in database!")
    else:
        print("Dry run completed. Run with --apply to commit updates to database.")


if __name__ == "__main__":
    main()
