#!/usr/bin/env python3
"""Export 155 PUBLISHED scheme Hindi names to docs/reports/hindi_names_for_review.csv."""

import csv
import gzip
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from db_inspect import query

def main():
    root = Path(__file__).resolve().parent.parent
    bundle_path = root / "frontend" / "assets" / "catalog" / "catalog_bundle.json.gz"
    
    with gzip.open(bundle_path, "rt", encoding="utf-8") as f:
        bundle = json.load(f)

    # 155 published (active) schemes
    published_schemes = [
        s for s in bundle["scheme_catalog.json"]["data"]
        if s.get("identity", {}).get("status") == "active"
    ]
    published_ids = [s["identity"]["id"] for s in published_schemes]
    print(f"Total published scheme IDs: {len(published_ids)} (expect 155)")

    # Query catalog.content for English and Hindi entries
    sql = """
    select entity_id, lang, name, origin, engine
    from catalog.content
    where entity_type = 'scheme' and lang in ('en', 'hi')
    order by entity_id, lang
    """
    rows = query(sql)
    content_map = {}
    for r in rows:
        content_map[(r["entity_id"], r["lang"])] = r

    out_csv = root / "docs" / "reports" / "hindi_names_for_review.csv"
    out_csv.parent.mkdir(parents=True, exist_ok=True)

    with open(out_csv, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["id", "English name", "Hindi name", "origin", "engine"])
        for sid in published_ids:
            en_row = content_map.get((sid, "en"), {})
            hi_row = content_map.get((sid, "hi"), {})

            en_name = en_row.get("name", "")
            hi_name = hi_row.get("name", "")
            origin = hi_row.get("origin", "")
            engine = hi_row.get("engine", "")

            writer.writerow([sid, en_name, hi_name, origin, engine])

    print(f"Exported {len(published_ids)} schemes to {out_csv}")

if __name__ == "__main__":
    main()
