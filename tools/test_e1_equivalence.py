#!/usr/bin/env python3
"""E1 equivalence test:
Compare schemes x 8 fields x {en, ta} between:
1. Current bundle in frontend/assets/catalog/catalog_bundle.json.gz
2. catalog.content from linked database
"""
from __future__ import annotations

import gzip
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
BUNDLE_PATH = ROOT_DIR / "frontend" / "assets" / "catalog" / "catalog_bundle.json.gz"

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from db_inspect import query

FIELDS = [
    ("name", "name"),
    ("shortName", "short_name"),
    ("summary", "summary"),
    ("objective", "objective"),
    ("description", "description"),
    ("benefitsText", "benefits_text"),
    ("eligibilityText", "eligibility_text"),
    ("applicationText", "application_text"),
]


def main():
    print("=== Testing E1 Equivalence ===")
    print(f"Reading current bundle from {BUNDLE_PATH}...")
    with gzip.open(BUNDLE_PATH, "rt", encoding="utf-8") as f:
        bundle = json.load(f)

    schemes_data = bundle.get("scheme_catalog.json", {}).get("data", [])
    print(f"Total schemes in bundle: {len(schemes_data)}")

    # Fetch catalog.content for all schemes for en and ta
    print("Fetching en and ta content from catalog.content in linked db...")
    sql = """
    select entity_id, lang, name, short_name, summary, objective, description,
           benefits_text, eligibility_text, application_text
    from catalog.content
    where entity_type = 'scheme' and lang in ('en', 'ta')
    """
    rows = query(sql)
    print(f"Total rows fetched from catalog.content: {len(rows)}")

    db_map = {}
    for r in rows:
        db_map[(r["entity_id"], r["lang"])] = r

    diffs = []
    checked = 0

    for s in schemes_data:
        eid = s["identity"]["id"]
        # Check EN
        en_row = db_map.get((eid, "en"), {})
        # In current bundle, EN is either in identity/attributes or in localization['en']
        loc = s.get("localization", {})
        loc_en = loc.get("en", {})
        attrs = s.get("attributes", {})
        ident = s.get("identity", {})

        for bundle_key, db_col in FIELDS:
            checked += 1
            if bundle_key == "name":
                b_val = ident.get("name") or loc_en.get("name")
            else:
                b_val = attrs.get(bundle_key) or loc_en.get(bundle_key)

            db_val = en_row.get(db_col)
            # Normalize whitespace/none
            b_str = (b_val or "").strip()
            d_str = (db_val or "").strip()
            if b_str != d_str:
                diffs.append((eid, "en", bundle_key, b_str, d_str))

        # Check TA
        ta_row = db_map.get((eid, "ta"), {})
        loc_ta = loc.get("ta", {})
        for bundle_key, db_col in FIELDS:
            checked += 1
            b_val = loc_ta.get(bundle_key)
            db_val = ta_row.get(db_col)
            b_str = (b_val or "").strip()
            d_str = (db_val or "").strip()
            if b_str != d_str:
                diffs.append((eid, "ta", bundle_key, b_str, d_str))

    print(f"Checked {checked} field-values across {len(schemes_data)} schemes.")
    print(f"Total diffs: {len(diffs)}")
    if diffs:
        print("Diff sample (first 10):")
        for d in diffs[:10]:
            print(f"  {d[0]} {d[1]} {d[2]}: bundle='{d[3][:30]}...' vs db='{d[4][:30]}...'")
    else:
        print("PASS: Zero diffs! E1 equivalence satisfied for current bundle vs catalog.content!")


if __name__ == "__main__":
    main()
