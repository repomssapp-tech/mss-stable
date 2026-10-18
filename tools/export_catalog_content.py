#!/usr/bin/env python3
"""Export catalog.content from linked database to a local json cache."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / "backend"
CACHE_PATH = BACKEND_DIR / "scratch" / "lang" / "catalog_content_cache.json"

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from db_inspect import query


def main():
    print("Exporting catalog.content from linked database...")
    sql = """
    select 
      entity_type, entity_id, lang, name, short_name, summary,
      objective, description, benefits_text, eligibility_text,
      application_text, aliases, keywords, origin, engine,
      source_checksum, verified
    from catalog.content
    order by entity_type, entity_id, lang
    """
    rows = query(sql)
    print(f"Exported {len(rows)} rows from catalog.content.")
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved cache to {CACHE_PATH}")


if __name__ == "__main__":
    main()
