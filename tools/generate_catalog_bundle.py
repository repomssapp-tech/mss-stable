#!/usr/bin/env python3
"""Regenerates frontend/assets/catalog/catalog_bundle.json.gz + release.json
from the latest catalog JSON package (default source: the Plan workspace's
`catalog/` directory).

Usage:
    python tools/generate_catalog_bundle.py [--source PATH] [--out-dir PATH]
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import uuid
from datetime import datetime, timezone
from pathlib import Path

# These are the catalogs MssCatalogBundle indexes into byId/byCatalog
# (see frontend/lib/services/mss_catalog_bundle.dart `catalogKeys`).
INDEXED_CATALOGS = [
    "common_catalog.json",
    "authority_catalog.json",
    "institution_catalog.json",
    "scheme_catalog.json",
    "finance_catalog.json",
    "tax_catalog.json",
    "treds_catalog.json",
    "csr_catalog.json",
    "export_catalog.json",
    "knowledge_catalog.json",
    "applicability_matrix_catalog.json",
    "enterprise_classification_catalog.json",
    "msme_privilege_catalog.json",
    "business_enablement_catalog.json",
    "cluster_assistance_catalog.json",
]

# Extra files carried in the bundle for reference but not indexed as entities.
EXTRA_FILES = ["search_index.json", "manifest.json"]

DEFAULT_SOURCE = Path(r"C:\Users\roger\OneDrive\Documents\Plan\catalog")
DEFAULT_OUT_DIR = (
    Path(__file__).resolve().parent.parent / "frontend" / "assets" / "catalog"
)


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    args = parser.parse_args()

    source: Path = args.source
    out_dir: Path = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    bundle: dict[str, dict] = {}

    for filename in INDEXED_CATALOGS + EXTRA_FILES:
        path = source / filename
        if not path.exists():
            raise FileNotFoundError(f"Missing required catalog file: {path}")
        raw_bytes = path.read_bytes()
        catalog = json.loads(raw_bytes)
        bundle[filename] = catalog

    # Decision D4: Hide DRAFT schemes from the offline app bundle
    # Preserves PUBLISHED (active) and ARCHIVED (closed) schemes (171 schemes).
    scheme_catalog = bundle["scheme_catalog.json"]
    kept_schemes = [
        s for s in scheme_catalog.get("data", [])
        if s.get("identity", {}).get("status") != "unknown"
    ]
    kept_scheme_ids = {s["identity"]["id"] for s in kept_schemes}

    # Clean references to hidden schemes from kept schemes
    for s in kept_schemes:
        refs = s.get("relationships", {}).get("references", [])
        s["relationships"]["references"] = [
            r for r in refs
            if not (
                (r.get("entityType") == "scheme" or str(r.get("entityId", "")).startswith("SCH"))
                and (r.get("entityId") or r.get("targetId")) not in kept_scheme_ids
            )
        ]
    scheme_catalog["data"] = kept_schemes

    # Filter applicability_matrix to match kept schemes
    if "applicability_matrix_catalog.json" in bundle:
        matrix_catalog = bundle["applicability_matrix_catalog.json"]
        matrix_catalog["data"] = [
            m for m in matrix_catalog.get("data", [])
            if m.get("content", {}).get("schemeId") in kept_scheme_ids
        ]

    # Filter search_index to match kept schemes (keep all non-schemes)
    if "search_index.json" in bundle:
        search_catalog = bundle["search_index.json"]
        search_catalog["data"] = [
            item for item in search_catalog.get("data", [])
            if item.get("entityType") != "scheme" or item.get("entityId") in kept_scheme_ids
        ]

    # Clean references in all other catalogs pointing to hidden schemes
    for fn in INDEXED_CATALOGS:
        if fn in ("scheme_catalog.json", "applicability_matrix_catalog.json"):
            continue
        for ent in bundle[fn].get("data", []):
            refs = ent.get("relationships", {}).get("references", [])
            if refs:
                ent["relationships"]["references"] = [
                    r for r in refs
                    if not (
                        (r.get("entityType") == "scheme" or str(r.get("entityId", "")).startswith("SCH"))
                        and (r.get("entityId") or r.get("targetId")) not in kept_scheme_ids
                    )
                ]

    record_counts: dict[str, int] = {}
    per_file_sha256: dict[str, str] = {}
    entity_count = 0
    hashed_files = INDEXED_CATALOGS + ["search_index.json"]

    for filename in INDEXED_CATALOGS + EXTRA_FILES:
        cat_obj = bundle[filename]
        cat_bytes = json.dumps(cat_obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        if filename in hashed_files:
            per_file_sha256[filename] = hashlib.sha256(cat_bytes).hexdigest()
        if filename in INDEXED_CATALOGS:
            data = cat_obj.get("data", [])
            record_counts[filename] = len(data)
            entity_count += len(data)

    manifest = bundle["manifest.json"]["data"][0]
    release_tag = manifest["catalogRelease"]
    schema_version = manifest["schemaVersion"]

    bundle_json_str = json.dumps(bundle, ensure_ascii=False, separators=(",", ":"))
    uncompressed_bytes = bundle_json_str.encode("utf-8")

    compressed_path = out_dir / "catalog_bundle.json.gz"
    with gzip.GzipFile(compressed_path, "wb", mtime=0) as gz:
        gz.write(uncompressed_bytes)
    compressed_bytes = compressed_path.read_bytes()

    bundle_sha256 = hashlib.sha256(compressed_bytes).hexdigest()

    search_index_data = bundle.get("search_index.json", {}).get("data", [])
    search_index_count = len(search_index_data)

    release = {
        "releaseId": str(uuid.uuid4()),
        "releaseTag": release_tag,
        "schemaVersion": schema_version,
        "releasedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "bundleAsset": "assets/catalog/catalog_bundle.json.gz",
        "bundleBytes": len(compressed_bytes),
        "bundleSha256": bundle_sha256,
        "uncompressedBytes": len(uncompressed_bytes),
        "entityCount": entity_count,
        "searchIndexCount": search_index_count,
        "recordCounts": record_counts,
        "perFileSha256": per_file_sha256,
    }

    release_path = out_dir / "release.json"
    release_path.write_text(
        json.dumps(release, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    print(f"Wrote {compressed_path} ({len(compressed_bytes):,} bytes)")
    print(f"Wrote {release_path}")
    print(f"entityCount={entity_count}, releaseTag={release_tag}")
    for name, count in record_counts.items():
        print(f"  {name}: {count}")


if __name__ == "__main__":
    main()
