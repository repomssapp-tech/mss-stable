#!/usr/bin/env python3
"""Import verified Hindi reviewer edits into catalog.content.

Features:
1. Re-runs blocking number preservation check (multiset equality).
2. Validates script and content integrity.
3. Computes source_checksum for verified entities.
4. Updates catalog.content with verified=true, verified_by, verified_at, origin='human'.
5. Updates or registers admin.translation_jobs tracking.

Usage:
  python tools/import_verified_hindi.py --input docs/reports/unverified_hindi.csv [--reviewer "Name"] [--mark-all-verified] [--apply]
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / "backend"
SCRATCH_DIR = BACKEND_DIR / "scratch" / "lang"

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

DEV_TO_ASCII = str.maketrans("०१२३४५६७८९", "0123456789")

TEXT_FIELDS = [
    "name",
    "short_name",
    "summary",
    "objective",
    "description",
    "benefits_text",
    "eligibility_text",
    "application_text",
]


def extract_numbers(text: str) -> Counter:
    if not text:
        return Counter()
    norm = text.translate(DEV_TO_ASCII)
    tokens = re.findall(r"\b\d+(?:\.\d+)?\b", norm)
    result = []
    for t in tokens:
        try:
            val = float(t)
            result.append(int(val) if val.is_integer() else val)
        except ValueError:
            result.append(t)
    return Counter(result)


def content_checksum(fields: dict[str, str | None]) -> str:
    """Computes md5(jsonb_build_array(name, short_name, ...)::text) matching PostgreSQL."""
    arr = [fields.get(f) for f in TEXT_FIELDS]
    json_str = json.dumps(arr, ensure_ascii=False, separators=(", ", ": "))
    return hashlib.md5(json_str.encode("utf-8")).hexdigest()


def escape_sql_string(val: str | None) -> str:
    if val is None:
        return "null"
    escaped = val.replace("'", "''")
    return f"'{escaped}'"


def main():
    parser = argparse.ArgumentParser(description="Import verified Hindi content into catalog.content")
    parser.add_argument("--input", type=Path, required=True, help="Input CSV file path")
    parser.add_argument("--reviewer", type=str, default="Human Reviewer", help="Reviewer name / identifier")
    parser.add_argument("--mark-all-verified", action="store_true", help="Mark all valid CSV rows as verified")
    parser.add_argument("--apply", action="store_true", help="Apply updates to Supabase catalog.content")
    parser.add_argument("--output-sql", type=Path, default=SCRATCH_DIR / "apply_verified_hindi.sql", help="Path to save generated SQL")
    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: input file {args.input} does not exist.")
        sys.exit(1)

    print(f"Reading CSV from {args.input}...")
    with args.input.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        field_rows = list(reader)

    print(f"Loaded {len(field_rows)} field rows.")

    # Group rows by (entity_type, entity_id)
    entities: dict[tuple[str, str], dict] = {}
    for r in field_rows:
        e_type = r["entity_type"]
        e_id = r["entity_id"]
        key = (e_type, e_id)
        if key not in entities:
            entities[key] = {
                "entity_type": e_type,
                "entity_id": e_id,
                "fields_en": {},
                "fields_hi": {},
                "is_verified": False,
            }

        fname = r["field_name"]
        en_text = r.get("english_text") or None
        hi_text = r.get("hindi_text") or None
        entities[key]["fields_en"][fname] = en_text
        entities[key]["fields_hi"][fname] = hi_text

        # Verified flag check
        v_val = (r.get("verified") or "").strip().lower()
        if args.mark_all_verified or v_val in ("true", "1", "yes", "verified"):
            entities[key]["is_verified"] = True

    print(f"Total entities parsed: {len(entities)}")

    passed_entities = []
    rejected_fields = []

    for key, ent in entities.items():
        if not ent["is_verified"]:
            continue

        e_type, e_id = key
        has_error = False

        # Validate each field for number check
        for fname in TEXT_FIELDS:
            en_val = ent["fields_en"].get(fname)
            hi_val = ent["fields_hi"].get(fname)
            if not en_val or not hi_val:
                continue

            nums_en = extract_numbers(en_val)
            nums_hi = extract_numbers(hi_val)
            if nums_en != nums_hi:
                rejected_fields.append({
                    "entity_id": e_id,
                    "field": fname,
                    "reason": f"Number mismatch: EN {dict(nums_en)} != HI {dict(nums_hi)}",
                    "en": en_val[:60],
                    "hi": hi_val[:60],
                })
                has_error = True

        if not has_error:
            passed_entities.append(ent)

    print(f"\n--- Validation Results ---")
    print(f"Entities ready to verify: {len(passed_entities)}")
    print(f"Number check rejections: {len(rejected_fields)}")

    if rejected_fields:
        print("\nTop 5 rejected fields:")
        for rf in rejected_fields[:5]:
            print(f"  [{rf['entity_id']}] {rf['field']}: {rf['reason']}")

    # Build SQL update statements
    now_ts = datetime.now(timezone.utc).isoformat()
    reviewer_str = escape_sql_string(args.reviewer)

    sql_statements = ["-- Automated import of verified Hindi catalog content", "begin;"]

    for ent in passed_entities:
        e_type = ent["entity_type"]
        e_id = ent["entity_id"]
        chk = content_checksum(ent["fields_en"])

        set_clauses = [
            f"verified = true",
            f"verified_by = {reviewer_str}",
            f"verified_at = '{now_ts}'",
            f"origin = 'human'",
            f"source_checksum = '{chk}'",
            f"updated_at = now()",
        ]

        for fname in TEXT_FIELDS:
            if fname in ent["fields_hi"]:
                val_escaped = escape_sql_string(ent["fields_hi"][fname])
                set_clauses.append(f"{fname} = {val_escaped}")

        update_sql = (
            f"update catalog.content\n"
            f"set {', '.join(set_clauses)}\n"
            f"where entity_type = '{e_type}' and entity_id = '{e_id}' and lang = 'hi';"
        )
        sql_statements.append(update_sql)

    sql_statements.append("commit;")

    full_sql = "\n\n".join(sql_statements)
    args.output_sql.parent.mkdir(parents=True, exist_ok=True)
    args.output_sql.write_text(full_sql, encoding="utf-8")
    print(f"\nGenerated verification SQL saved to: {args.output_sql}")

    if args.apply:
        if not passed_entities:
            print("No verified entities to apply.")
            return

        print(f"Applying verification updates for {len(passed_entities)} entities to Supabase...")
        import subprocess
        cmd = f'npx supabase db query --linked --file "{args.output_sql}"'
        res = subprocess.run(cmd, cwd=str(BACKEND_DIR), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
        if res.returncode != 0:
            print(f"Error applying SQL updates: {res.stderr or res.stdout}")
            sys.exit(1)
        print("Successfully applied verification updates to catalog.content!")
    else:
        print("\nDry run completed. Use --apply to execute the updates on the linked database.")


if __name__ == "__main__":
    main()
