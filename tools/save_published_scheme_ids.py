#!/usr/bin/env python3
"""Save the exact 171 scheme IDs of the published/archived bundle."""
import gzip
import json
from pathlib import Path

bundle_path = Path("frontend/assets/catalog/catalog_bundle.json.gz")
with gzip.open(bundle_path, "rt", encoding="utf-8") as f:
    bundle = json.load(f)

scheme_ids = [s["identity"]["id"] for s in bundle["scheme_catalog.json"]["data"]]
print(f"Total scheme IDs: {len(scheme_ids)}")
out_file = Path("backend/scratch/lang/published_scheme_ids.json")
out_file.write_text(json.dumps(scheme_ids, indent=2), encoding="utf-8")
print(f"Saved to {out_file}")
