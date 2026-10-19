#!/usr/bin/env python3
"""Export unverified Hindi content from catalog.content to CSV.

Outputs CSV with English text next to Hindi text, ordered by app_relevance
(high -> medium -> low -> unranked) and entity_id.

Usage:
  python tools/export_unverified_hindi.py [--output path/to/output.csv] [--force-db]
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / "backend"
CACHE_PATH = BACKEND_DIR / "scratch" / "lang" / "catalog_content_cache.json"
V3_1_PATH = ROOT_DIR / "docs" / "backend" / "mss_scheme_data_v3_1" / "mss_scheme_data_v3_1" / "data" / "msme_schemes_v3_1.json"
DEFAULT_OUT = ROOT_DIR / "docs" / "reports" / "unverified_hindi.csv"

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


def load_content(force_db: bool = False) -> list[dict]:
    if not force_db and CACHE_PATH.exists():
        with CACHE_PATH.open("r", encoding="utf-8") as f:
            return json.load(f)
    sys.path.insert(0, str(ROOT_DIR / "tools"))
    from db_inspect import query
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
    if not rows:
        raise RuntimeError("Database query returned empty or failed to connect.")
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    return rows


def load_relevance_map() -> dict[str, str]:
    if not V3_1_PATH.exists():
        return {}
    with V3_1_PATH.open("r", encoding="utf-8") as f:
        data = json.load(f)
    mapping = {}
    for s in data.get("schemes", []):
        rel = s.get("app_relevance")
        for cid in s.get("mss_catalog_ids") or []:
            if rel:
                mapping[cid] = rel.lower()
    return mapping


def main():
    parser = argparse.ArgumentParser(description="Export unverified Hindi content to CSV")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUT, help="Output CSV path")
    parser.add_argument("--force-db", action="store_true", help="Force refetch from Supabase")
    args = parser.parse_args()

    rows = load_content(force_db=args.force_db)
    relevance_map = load_relevance_map()

    # Index by (entity_type, entity_id, lang)
    content_map: dict[tuple[str, str, str], dict] = {}
    for r in rows:
        key = (r["entity_type"], r["entity_id"], r["lang"])
        content_map[key] = r

    # Find all unverified Hindi rows
    unverified_hindi = [
        r for r in rows
        if r["lang"] == "hi" and not r.get("verified", False)
    ]

    print(f"Total unverified Hindi entity rows: {len(unverified_hindi)}")

    rel_order = {"high": 1, "medium": 2, "low": 3, "unranked": 4}

    export_rows = []
    for h in unverified_hindi:
        e_type = h["entity_type"]
        e_id = h["entity_id"]
        rel = relevance_map.get(e_id, "unranked")

        # Get English counterpart
        en = content_map.get((e_type, e_id, "en"), {})

        for field in TEXT_FIELDS:
            en_val = en.get(field) or ""
            hi_val = h.get(field) or ""
            if not en_val and not hi_val:
                continue

            export_rows.append({
                "entity_type": e_type,
                "entity_id": e_id,
                "app_relevance": rel,
                "rel_rank": rel_order.get(rel, 4),
                "field_name": field,
                "english_text": en_val,
                "hindi_text": hi_val,
                "verified": "false",
                "source_checksum": h.get("source_checksum") or "",
                "origin": h.get("origin") or "machine",
                "engine": h.get("engine") or "",
            })

    # Sort by relevance, entity_type, entity_id, field order
    field_order = {f: idx for idx, f in enumerate(TEXT_FIELDS)}
    export_rows.sort(key=lambda r: (
        r["rel_rank"],
        0 if r["entity_type"] == "scheme" else (1 if r["entity_type"] == "authority" else 2),
        r["entity_id"],
        field_order.get(r["field_name"], 99)
    ))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "entity_type",
            "entity_id",
            "app_relevance",
            "field_name",
            "english_text",
            "hindi_text",
            "verified",
            "source_checksum",
            "origin",
            "engine",
        ])
        for r in export_rows:
            writer.writerow([
                r["entity_type"],
                r["entity_id"],
                r["app_relevance"],
                r["field_name"],
                r["english_text"],
                r["hindi_text"],
                r["verified"],
                r["source_checksum"],
                r["origin"],
                r["engine"],
            ])

    print(f"Exported {len(export_rows)} unverified field rows to {args.output}")


if __name__ == "__main__":
    main()
