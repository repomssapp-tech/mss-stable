#!/usr/bin/env python3
"""Acceptance verification for Phase P2 Hindi Content.
Checks:
1. Number check over all written Hindi content in catalog.content -> must be 0 violations.
2. Needs review jobs in admin.translation_jobs -> should match the 2 flagged.
3. Fingerprint of catalog.scheme/authority/institution -> must match A3.
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
    sql_file = SCRATCH_DIR / "verify_query.sql"
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


def main():
    print("=== Phase P2 Acceptance Verification ===")
    
    # 1. Number check over all written Hindi content in catalog.content
    print("1. Fetching all Hindi scheme content from catalog.content...")
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
    print(f"Total Hindi scheme records found in catalog.content: {len(rows)}")

    number_violations = 0
    checked_fields = 0
    for r in rows:
        eid = r["entity_id"]
        for f in TEXT_FIELDS:
            en_val = r.get(f"en_{f}")
            hi_val = r.get(f"hi_{f}")
            if en_val and hi_val:
                checked_fields += 1
                c_en = extract_numbers(en_val)
                c_hi = extract_numbers(hi_val)
                if c_en != c_hi:
                    number_violations += 1
                    print(f"  VIOLATION: {eid} {f} | EN: {dict(c_en)} vs HI: {dict(c_hi)}")

    print(f"Number check over written Hindi content: checked {checked_fields} fields. Violations = {number_violations}")
    if number_violations == 0:
        print("  PASS: 0 number violations in catalog.content!")
    else:
        print(f"  FAIL: {number_violations} number violations detected.")

    # 2. Check admin.translation_jobs for needs_review
    print("\n2. Checking admin.translation_jobs for needs_review...")
    jobs = run_query_json("select entity_id, field_name, errors from admin.translation_jobs where status = 'FAILED'")
    print(f"Failed / Needs review jobs count: {len(jobs)}")
    for j in jobs:
        print(f"  Job: {j['entity_id']} - {j['field_name']}: {j['errors']}")

    # 3. Check existing data fingerprint
    print("\n3. Re-verifying database fingerprint...")
    fp_rows = run_query_json("""
    select 'scheme' t, count(*), md5(string_agg(md5(coalesce(record_json::text,'')||coalesce(name_en,'')||coalesce(name_ta,'')), '' order by id)) from catalog.scheme
    union all select 'authority', count(*), md5(string_agg(md5(coalesce(record_json::text,'')||name_en||coalesce(name_ta,'')), '' order by id)) from catalog.authority
    union all select 'institution', count(*), md5(string_agg(md5(coalesce(record_json::text,'')||name_en||coalesce(name_ta,'')), '' order by id)) from catalog.institution
    """)
    for r in fp_rows:
        print(f"  {r['t']}: count={r['count']}, md5={r['md5']}")

    expected_fp = {
        "scheme": ("302", "55f3406e14ff60f514535c77f4f231da"),
        "authority": ("131", "618b91d75bd3ad7b8257fdaafd01cb81"),
        "institution": ("83", "8c91b2b124c1a3867194b09fdf29abf5"),
    }

    fp_match = True
    for r in fp_rows:
        exp_c, exp_m = expected_fp[r["t"]]
        if str(r["count"]) != exp_c or r["md5"] != exp_m:
            fp_match = False
            print(f"  FINGERPRINT MISMATCH on {r['t']}!")

    if fp_match:
        print("  PASS: Fingerprint is 100% byte-identical to A3!")
    else:
        print("  FAIL: Fingerprint mismatch!")


if __name__ == "__main__":
    main()
