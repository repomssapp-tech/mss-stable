#!/usr/bin/env python3
"""Resolve the 44 legacy number mismatches in catalog.content by:
1. For nullable fields: Setting the mismatched Hindi field to NULL in catalog.content (so it falls back to English per D3/D9)
   and inserting a 'needs_review' record in admin.translation_jobs per D9 and P2 Acceptance.
2. For non-nullable 'name' fields (SCH000271, SCH000280): Updating the Hindi name with the exact matching number components.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
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
    "name", "short_name", "summary", "objective", "description",
    "benefits_text", "eligibility_text", "application_text"
]


def run_query_json(sql: str) -> list[dict]:
    sql_file = SCRATCH_DIR / "query_mismatches.sql"
    sql_file.write_text(f"{sql};", encoding="utf-8")
    cmd = f'npx supabase db query --linked --file "{sql_file}"'
    import subprocess
    res = subprocess.run(cmd, cwd=str(BACKEND_DIR), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        raise RuntimeError(f"Database query failed: {res.stderr or res.stdout}")
    out = res.stdout
    start_idx = out.find("{")
    if start_idx == -1:
        return []
    data = json.loads(out[start_idx:])
    return data.get("rows", [])


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


def escape_sql(text: str) -> str:
    if not text:
        return ""
    return text.replace("'", "''")


def main():
    print("Fetching Hindi and English fields from catalog.content...")
    query = """
    select 
      e.entity_id,
      e.name as en_name, e.short_name as en_short_name, e.summary as en_summary,
      e.objective as en_objective, e.description as en_description,
      e.benefits_text as en_benefits_text, e.eligibility_text as en_eligibility_text,
      e.application_text as en_application_text,
      h.name as hi_name, h.short_name as hi_short_name, h.summary as hi_summary,
      h.objective as hi_objective, h.description as hi_description,
      h.benefits_text as hi_benefits_text, h.eligibility_text as hi_eligibility_text,
      h.application_text as hi_application_text
    from catalog.content h
    join catalog.content e on e.entity_type = h.entity_type and e.entity_id = h.entity_id and e.lang = 'en'
    where h.entity_type = 'scheme' and h.lang = 'hi'
    """
    rows = run_query_json(query)
    
    statements = []
    mismatch_count = 0
    for r in rows:
        eid = r["entity_id"]
        for f in TEXT_FIELDS:
            en_val = r.get(f"en_{f}")
            hi_val = r.get(f"hi_{f}")
            if en_val and hi_val:
                c_en = extract_numbers(en_val)
                c_hi = extract_numbers(hi_val)
                if c_en != c_hi:
                    mismatch_count += 1
                    if f == "name":
                        if eid == "SCH000271":
                            fixed_hi = "स्टार्टअप इंडिया फंड ऑफ फंड्स 2.0 (स्टार्टअप इंडिया FoF 2.0)"
                        elif eid == "SCH000280":
                            fixed_hi = "स्किल इंडिया कार्यक्रम (पुनर्गठित: पीएमकेवीवाई 4.0, पीएम-एनएपीएस, जेएसएस)"
                        else:
                            fixed_hi = en_val
                        statements.append(
                            f"UPDATE catalog.content SET name = '{escape_sql(fixed_hi)}' WHERE entity_type = 'scheme' AND entity_id = '{eid}' AND lang = 'hi';"
                        )
                    else:
                        err_msg = f"needs_review: number_mismatch (legacy seed): en={dict(c_en)} vs hi={dict(c_hi)}"
                        err_escaped = escape_sql(err_msg)
                        src_escaped = escape_sql(en_val)
                        tr_escaped = escape_sql(hi_val)
                        statements.append(
                            f"UPDATE catalog.content SET {f} = NULL WHERE entity_type = 'scheme' AND entity_id = '{eid}' AND lang = 'hi';"
                        )
                        statements.append(
                            f"DELETE FROM admin.translation_jobs WHERE entity_type = 'scheme' AND entity_id = '{eid}' AND field_name = '{f}' AND target_lang = 'hi';"
                        )
                        statements.append(
                            f"INSERT INTO admin.translation_jobs (entity_type, entity_id, field_name, target_lang, source_lang, status, source_text, translated_text, errors) "
                            f"VALUES ('scheme', '{eid}', '{f}', 'hi', 'en', 'FAILED', '{src_escaped}', '{tr_escaped}', '{err_escaped}');"
                        )

    print(f"Found {mismatch_count} number mismatches to handle.")
    if not statements:
        print("Nothing to do.")
        return

    sql_out = SCRATCH_DIR / "fix_legacy_number_mismatches.sql"
    sql_out.write_text("\n".join(statements), encoding="utf-8")
    print(f"Wrote {len(statements)} SQL statements to {sql_out}. Executing against linked database...")

    import subprocess
    cmd = f'npx supabase db query --linked --file "{sql_out}"'
    res = subprocess.run(cmd, cwd=str(BACKEND_DIR), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        print("STDOUT:", res.stdout)
        print("STDERR:", res.stderr)
        raise RuntimeError(f"Database execution failed with returncode {res.returncode}")
    print("Successfully updated database!")


if __name__ == "__main__":
    main()
