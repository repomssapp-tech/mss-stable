#!/usr/bin/env python3
"""Inject per-scheme `content.schemeUrl` into the catalog source, then rebuild
the offline bundle.

`catalog.scheme.scheme_url` (added in migration
20260908120000_scheme_url_and_drop_funding_columns.sql) is the authoritative
"Apply Now" URL. The Flutter app reads it offline from
`frontend/assets/catalog/catalog_bundle.json.gz` at `content.schemeUrl`, so the
value has to be written into `scheme_catalog.json` and the bundle regenerated
(which recomputes `release.json` -> bundleSha256 / perFileSha256, the hash the
app verifies on load).

Steps:
  1. Export the id -> url map from the live DB. In the Supabase SQL editor:

         select jsonb_object_agg(id, scheme_url) as m
         from catalog.scheme
         where status = 'PUBLISHED' and scheme_url is not null and scheme_url <> '';

     Save the single `m` cell as scheme_url_map.json  ({ "SCH000001": "https://...", ... }).

  2. python tools/inject_scheme_url.py --map scheme_url_map.json

     (add --no-rebuild to only patch scheme_catalog.json and skip the bundle
      regen; add --allow-missing to tolerate published schemes absent from the map)

Usage:
    python tools/inject_scheme_url.py --map PATH [--source PATH] [--no-rebuild] [--allow-missing]
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = REPO_ROOT / "backend" / "catalog" / "source"
GENERATOR = REPO_ROOT / "tools" / "generate_catalog_bundle.py"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", type=Path, required=True,
                    help="JSON object { schemeId: url }, exported from catalog.scheme.scheme_url")
    ap.add_argument("--source", type=Path, default=DEFAULT_SOURCE,
                    help="catalog/ source dir holding scheme_catalog.json")
    ap.add_argument("--no-rebuild", action="store_true",
                    help="patch scheme_catalog.json only; do not regenerate the bundle")
    ap.add_argument("--allow-missing", action="store_true",
                    help="do not fail when a PUBLISHED scheme has no url in the map")
    args = ap.parse_args()

    url_map: dict[str, str] = json.loads(args.map.read_text(encoding="utf-8"))
    url_map = {k: (v or "").strip() for k, v in url_map.items()}

    scheme_file = args.source / "scheme_catalog.json"
    catalog = json.loads(scheme_file.read_text(encoding="utf-8"))
    records = catalog.get("data", [])

    patched, missing, unchanged = 0, [], 0
    for rec in records:
        rid = (rec.get("identity") or {}).get("id")
        status = (rec.get("verification") or {}).get("status") or rec.get("status")
        url = url_map.get(rid, "")
        if not url:
            if status == "PUBLISHED" or status is None:
                missing.append(rid)
            continue
        content = rec.setdefault("content", {})
        if content.get("schemeUrl") == url:
            unchanged += 1
        else:
            content["schemeUrl"] = url
            patched += 1

    if missing and not args.allow_missing:
        sys.exit(
            f"ERROR: {len(missing)} published scheme(s) have no url in the map, "
            f"e.g. {missing[:10]}. Fix the export or pass --allow-missing."
        )

    scheme_file.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"scheme_catalog.json: {patched} set, {unchanged} already current, "
          f"{len(missing)} left blank")

    if args.no_rebuild:
        print("--no-rebuild: skipping bundle regeneration.")
        return

    print("Regenerating catalog_bundle.json.gz + release.json ...")
    subprocess.run(
        [sys.executable, str(GENERATOR), "--source", str(args.source)],
        check=True,
    )
    print("Done. Commit frontend/assets/catalog/{catalog_bundle.json.gz,release.json}.")


if __name__ == "__main__":
    main()
