#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/catalog_v3_1/generate_gate_b_report.py

Generates Gate B Deliverables:
1. Validator output (0 failures)
2. 3 full before/after diffs:
   - SCH000255 (MCGS)
   - SCH000289 (PM Surya Ghar)
   - SCH000220 (PMEGP 2nd loan)
3. Table of 83 rows' scheme_type, government_level, and ministry values.
"""
from __future__ import annotations

import difflib
import json
import os
import re
import subprocess
import sys

# Ensure stdout handles UTF-8 on Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

CAT_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
SCHEME_CAT_PATH = os.path.join(CAT_DIR, "scheme_catalog.json")
MIGRATION_ADD_PATH = r"backend\supabase\migrations\20261004193500_catalog_v3_1_add_schemes.sql"


def extract_before_from_sql(sql_content: str, sid: str) -> dict:
    target = f"'{sid}'"
    idx = sql_content.find(target)
    if idx == -1:
        raise ValueError(f"{sid} not found in migration SQL")
    j_start = sql_content.find("'{", idx)
    j_end = sql_content.find("::jsonb", j_start)
    raw_json = sql_content[j_start + 1 : j_end].rstrip()
    if raw_json.endswith("'"):
        raw_json = raw_json[:-1]
    clean_json = raw_json.replace("''", "'")
    return json.loads(clean_json)


def make_diff(before: dict, after: dict, title: str) -> str:
    before_str = json.dumps(before, indent=2, ensure_ascii=False, sort_keys=True).splitlines(keepends=True)
    after_str = json.dumps(after, indent=2, ensure_ascii=False, sort_keys=True).splitlines(keepends=True)
    diff = difflib.unified_diff(
        before_str, after_str,
        fromfile=f"a/{title}_before.json",
        tofile=f"b/{title}_after.json",
        n=3
    )
    return "".join(diff)


def main():
    out_lines = []
    def log(msg=""):
        out_lines.append(msg)

    # 1. Run validator and capture output
    log("=" * 80)
    log("GATE B DELIVERABLE 1: VALIDATOR OUTPUT")
    log("=" * 80)
    res = subprocess.run([sys.executable, "scripts/catalog_v3_1/validate_shape.py"], capture_output=True, text=True, encoding="utf-8")
    log(res.stdout)
    if res.returncode != 0:
        log(f"ERROR: Validator failed with code {res.returncode}")
        print("ERROR: Validator failed")
        sys.exit(res.returncode)

    # 2. Extract before/after diffs for the 3 schemes
    log("\n" + "=" * 80)
    log("GATE B DELIVERABLE 2: 3 FULL BEFORE/AFTER DIFFS")
    log("=" * 80)

    with open(MIGRATION_ADD_PATH, "r", encoding="utf-8") as f:
        sql_content = f.read()

    with open(SCHEME_CAT_PATH, "r", encoding="utf-8") as f:
        catalog_after = json.load(f)
    after_by_id = {r["identity"]["id"]: r for r in catalog_after["data"]}

    target_schemes = [
        ("SCH000255", "MCGS (Mutual Credit Guarantee Scheme for MSMEs)"),
        ("SCH000289", "PM Surya Ghar: Muft Bijli Yojana"),
        ("SCH000220", "PMEGP 2nd Loan for Upgradation"),
    ]

    for sid, name in target_schemes:
        log(f"\n### BEFORE/AFTER DIFF: {sid} - {name}")
        log("```diff")
        before_dict = extract_before_from_sql(sql_content, sid)
        after_dict = after_by_id[sid]
        diff_text = make_diff(before_dict, after_dict, sid)
        log(diff_text)
        log("```")

    # 3. Table of 83 rows' scheme_type, government_level, and ministry
    log("\n" + "=" * 80)
    log("GATE B DELIVERABLE 3: TABLE OF 83 ROWS' SCHEME_TYPE, GOVERNMENT_LEVEL, AND MINISTRY")
    log("=" * 80)
    log("| Scheme ID | Scheme Type | Level | Ministry | Scheme Name |")
    log("|:---|:---|:---|:---|:---|")

    for i in range(220, 303):
        sid = f"SCH{i:06d}"
        r = after_by_id[sid]
        s_name = r["identity"]["name"]
        cl = r["content"]["classification"]
        st = cl["schemeType"]
        gov = cl["government"]
        lvl = gov["level"]
        min_text = gov["ministryText"]
        log(f"| `{sid}` | `{st}` | `{lvl}` | {min_text} | {s_name} |")

    out_text = "\n".join(out_lines) + "\n"
    out_path = os.path.join("reports", "GATE_B_REPORT.md")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(out_text)
    print(f"Report written to {out_path} ({len(out_text)} bytes)")


if __name__ == "__main__":
    main()

