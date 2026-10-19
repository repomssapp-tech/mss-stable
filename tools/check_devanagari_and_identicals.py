#!/usr/bin/env python3
"""Check all 8 Hindi fields in catalog.content and catalog_pack_hi:
- Count and list IDs with no Devanagari
- Translation_jobs rows where translated_text = source_text
"""

import gzip
import json
import re
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR / "tools"))
from db_inspect import query

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

devanagari_pattern = re.compile(r"[\u0900-\u097F]")
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
CAMEL_FIELDS = [
    "name",
    "shortName",
    "summary",
    "objective",
    "description",
    "benefitsText",
    "eligibilityText",
    "applicationText",
]

def main():
    print("=== Part 1: catalog.content (all 8 Hindi fields) ===")
    sql = """
    select entity_type, entity_id, name, short_name, summary, objective,
           description, benefits_text, eligibility_text, application_text
    from catalog.content
    where lang = 'hi'
    order by entity_type, entity_id;
    """
    rows = query(sql)
    print(f"Total catalog.content 'hi' rows: {len(rows)}")

    no_dev_by_field = {f: [] for f in TEXT_FIELDS}
    for r in rows:
        eid = r["entity_id"]
        etype = r["entity_type"]
        for f in TEXT_FIELDS:
            val = r.get(f)
            if val and not devanagari_pattern.search(str(val)):
                no_dev_by_field[f].append((etype, eid, val))

    for f in TEXT_FIELDS:
        items = no_dev_by_field[f]
        print(f"  Field '{f}': {len(items)} rows with NO Devanagari")
        for etype, eid, val in items:
            print(f"    - [{etype}] {eid}: {repr(val)}")

    print("\n=== Part 2: catalog_pack_hi.json.gz (all 8 Hindi fields) ===")
    pack_path = ROOT_DIR / "frontend" / "assets" / "catalog" / "catalog_pack_hi.json.gz"
    if pack_path.exists():
        pack = json.loads(gzip.decompress(pack_path.read_bytes()).decode("utf-8"))
        pack_data = pack.get("data", [])
        print(f"Total entities in pack: {len(pack_data)}")

        pack_no_dev = {f: [] for f in CAMEL_FIELDS}
        for item in pack_data:
            eid = item.get("entityId") or item.get("id")
            etype = item.get("entityType", "unknown")
            for f in CAMEL_FIELDS:
                val = item.get(f)
                if val and not devanagari_pattern.search(str(val)):
                    pack_no_dev[f].append((etype, eid, val))

        for f in CAMEL_FIELDS:
            items = pack_no_dev[f]
            print(f"  Field '{f}': {len(items)} entities with NO Devanagari")
            for etype, eid, val in items:
                print(f"    - [{etype}] {eid}: {repr(val)}")
    else:
        print("catalog_pack_hi.json.gz not found.")

    print("\n=== Part 3: admin.translation_jobs where translated_text = source_text ===")
    tj_sql = """
    select id, entity_type, entity_id, field_name, status, source_text, translated_text
    from admin.translation_jobs
    where target_lang = 'hi'
      and translated_text = source_text
      and source_text is not null
      and trim(source_text) != ''
    order by entity_type, entity_id, field_name;
    """
    tj_rows = query(tj_sql)
    print(f"Total translation_jobs where translated_text = source_text: {len(tj_rows)}")
    for r in tj_rows:
        print(f"  - [{r['entity_type']}] {r['entity_id']} ({r['field_name']}, status={r['status']}): {repr(r['source_text'])}")


if __name__ == "__main__":
    main()
