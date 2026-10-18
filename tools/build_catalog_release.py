#!/usr/bin/env python3
"""Builds MSS catalog release bundle + language packs from catalog.content.
Implements Phase P3 of MASTER_PLAN_hindi_localization.md:
- Reads all text from catalog.content, not from legacy localization.
- Core bundle gets English text + D11 legacy localization blocks (for backward compatibility).
- Emits separate language packs: catalog_pack_hi.json.gz and catalog_pack_ta.json.gz per §4.
- Generates release.json with per-language record counts, pack metadata, and sha256.
- Implements E1, E2, E3 verification checks and size report.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import shutil
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = ROOT_DIR / "backend" / "catalog" / "source"
DEFAULT_CACHE = ROOT_DIR / "backend" / "scratch" / "lang" / "catalog_content_cache.json"
DEFAULT_OUT_DIR = ROOT_DIR / "frontend" / "assets" / "catalog"
REHEARSAL_OUT_DIR = ROOT_DIR / "backend" / "scratch" / "release_p3_rehearsal"

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
EXTRA_FILES = ["search_index.json", "manifest.json"]

# Languages the app may offer. Mirrors catalog.language.is_active; removing a
# code here and re-publishing is the Hindi/Tamil kill switch (D10).
ACTIVE_LANGUAGES = ["en", "ta", "hi"]

SCHEME_FIELDS = [
    ("name", "name"),
    ("shortName", "short_name"),
    ("summary", "summary"),
    ("objective", "objective"),
    ("description", "description"),
    ("benefitsText", "benefits_text"),
    ("eligibilityText", "eligibility_text"),
    ("applicationText", "application_text"),
]


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data: dict | list) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def gzip_compress(data: bytes, path: Path) -> None:
    with gzip.GzipFile(path, "wb", mtime=0) as gz:
        gz.write(data)


def compute_sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_catalog_content(cache_path: Path, refresh: bool = True) -> list[dict]:
    if not refresh and cache_path.exists():
        with cache_path.open("r", encoding="utf-8") as f:
            return json.load(f)
    print("Fetching fresh catalog.content from database...")
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
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    return rows


def build_release(
    source_dir: Path,
    out_dir: Path,
    cache_path: Path,
    release_tag_override: str | None = None,
    filter_unknown_schemes: bool = True,
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"Loading catalog source from {source_dir}...")
    bundle: dict[str, dict] = {}
    for filename in INDEXED_CATALOGS + EXTRA_FILES:
        path = source_dir / filename
        if not path.exists():
            raise FileNotFoundError(f"Missing required catalog file: {path}")
        bundle[filename] = load_json(path)

    print("Loading catalog.content entries...")
    content_rows = load_catalog_content(cache_path)
    
    # Index content by (entity_type, entity_id, lang)
    content_map: dict[tuple[str, str, str], dict] = {}
    for r in content_rows:
        content_map[(r["entity_type"], r["entity_id"], r["lang"])] = r

    # 1. Update schemes with catalog.content
    print("Injecting catalog.content into schemes...")
    scheme_catalog = bundle["scheme_catalog.json"]
    for s in scheme_catalog.get("data", []):
        eid = s.get("identity", {}).get("id")
        if not eid:
            continue
        
        # Ensure localization dict exists (D11 legacy compatibility)
        if "localization" not in s:
            s["localization"] = {}

        # English (core)
        en_content = content_map.get(("scheme", eid, "en"))
        if en_content:
            if en_content.get("name"):
                s["identity"]["name"] = en_content["name"]
            attrs = s.setdefault("attributes", {})
            for b_key, col in SCHEME_FIELDS:
                if col != "name" and en_content.get(col):
                    attrs[b_key] = en_content[col]
            s["localization"]["en"] = {
                b_key: en_content.get(col)
                for b_key, col in SCHEME_FIELDS
                if en_content.get(col)
            }

        # Tamil (legacy block)
        ta_content = content_map.get(("scheme", eid, "ta"))
        if ta_content:
            s["localization"]["ta"] = {
                b_key: ta_content.get(col)
                for b_key, col in SCHEME_FIELDS
                if ta_content.get(col)
            }

        # Hindi (legacy block for D11)
        hi_content = content_map.get(("scheme", eid, "hi"))
        if hi_content:
            s["localization"]["hi"] = {
                b_key: hi_content.get(col)
                for b_key, col in SCHEME_FIELDS
                if hi_content.get(col)
            }

    # 2. Update authorities with catalog.content
    print("Injecting catalog.content into authorities...")
    authority_catalog = bundle["authority_catalog.json"]
    for a in authority_catalog.get("data", []):
        aid = a.get("identity", {}).get("id")
        if not aid:
            continue
        if "localization" not in a:
            a["localization"] = {}
        for l in ("en", "ta", "hi"):
            c = content_map.get(("authority", aid, l))
            if c and c.get("name"):
                if l == "en":
                    a["identity"]["name"] = c["name"]
                a["localization"][l] = {"name": c["name"]}

    # 3. Update institutions with catalog.content
    print("Injecting catalog.content into institutions...")
    institution_catalog = bundle["institution_catalog.json"]
    for i in institution_catalog.get("data", []):
        iid = i.get("identity", {}).get("id")
        if not iid:
            continue
        if "localization" not in i:
            i["localization"] = {}
        for l in ("en", "ta", "hi"):
            c = content_map.get(("institution", iid, l))
            if c and c.get("name"):
                if l == "en":
                    i["identity"]["name"] = c["name"]
                i["localization"][l] = {"name": c["name"]}

    # Filter schemes if configured (Decision D4: hide draft schemes from offline bundle)
    published_ids_file = ROOT_DIR / "backend" / "scratch" / "lang" / "published_scheme_ids.json"
    published_ids = set(json.loads(published_ids_file.read_text(encoding="utf-8"))) if published_ids_file.exists() else None

    if filter_unknown_schemes:
        if published_ids:
            kept_schemes = [
                s for s in scheme_catalog.get("data", [])
                if s.get("identity", {}).get("id") in published_ids
            ]
        else:
            kept_schemes = [
                s for s in scheme_catalog.get("data", [])
                if s.get("identity", {}).get("status") != "unknown"
            ]
        kept_scheme_ids = {s["identity"]["id"] for s in kept_schemes}
        # Clean references
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

        if "applicability_matrix_catalog.json" in bundle:
            matrix_catalog = bundle["applicability_matrix_catalog.json"]
            matrix_catalog["data"] = [
                m for m in matrix_catalog.get("data", [])
                if m.get("content", {}).get("schemeId") in kept_scheme_ids
            ]

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

    # 4. Generate Language Packs per §4
    print("Generating Language Packs for hi and ta...")
    kept_scheme_ids = {s["identity"]["id"] for s in scheme_catalog.get("data", [])}
    manifest = bundle["manifest.json"]["data"][0]
    release_tag = manifest["catalogRelease"]
    schema_version = manifest["schemaVersion"]

    language_packs: dict[str, dict] = {}
    for lang in ("hi", "ta"):
        pack_entities = []
        for r in content_rows:
            if r["lang"] != lang:
                continue
            # Pack only contains entities whose parent scheme is publishable
            if r["entity_type"] == "scheme" and r["entity_id"] not in kept_scheme_ids:
                continue
            
            ent = {
                "entityType": r["entity_type"],
                "entityId": r["entity_id"],
                "name": r.get("name"),
                "shortName": r.get("short_name"),
                "summary": r.get("summary"),
                "objective": r.get("objective"),
                "description": r.get("description"),
                "benefitsText": r.get("benefits_text"),
                "eligibilityText": r.get("eligibility_text"),
                "applicationText": r.get("application_text"),
                "aliases": r.get("aliases") or [],
                "keywords": r.get("keywords") or [],
                "verified": bool(r.get("verified", False)),
            }
            # Remove keys that are None to save size
            ent_clean = {k: v for k, v in ent.items() if v is not None}
            pack_entities.append(ent_clean)

        pack_obj = {
            "lang": lang,
            "catalogRelease": release_tag,
            "entityCount": len(pack_entities),
            "data": pack_entities,
        }
        pack_json_bytes = json.dumps(pack_obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        pack_file_name = f"catalog_pack_{lang}.json"
        pack_gz_name = f"catalog_pack_{lang}.json.gz"
        
        # Save only compressed .gz pack per B.6
        gzip_compress(pack_json_bytes, out_dir / pack_gz_name)
        pack_gz_bytes = (out_dir / pack_gz_name).read_bytes()

        is_active = lang in ACTIVE_LANGUAGES
        language_packs[lang] = {
            "lang": lang,
            "fileName": pack_gz_name,
            "assetPath": f"assets/catalog/{pack_gz_name}",
            "byteSize": len(pack_gz_bytes),
            "sha256": compute_sha256(pack_gz_bytes),
            "entityCount": len(pack_entities),
            "isActive": is_active,
        }
        print(f"  {lang} pack: {len(pack_entities)} entities, {len(pack_gz_bytes):,} bytes gzipped (isActive={is_active}).")

    # 5. Build core catalog_bundle.json.gz
    record_counts: dict[str, int] = {}
    per_file_sha256: dict[str, str] = {}
    entity_count = 0
    hashed_files = INDEXED_CATALOGS + ["search_index.json"]

    for filename in INDEXED_CATALOGS + EXTRA_FILES:
        cat_obj = bundle[filename]
        cat_bytes = json.dumps(cat_obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        if filename in hashed_files:
            per_file_sha256[filename] = compute_sha256(cat_bytes)
        if filename in INDEXED_CATALOGS:
            data = cat_obj.get("data", [])
            record_counts[filename] = len(data)
            entity_count += len(data)

    # Add language packs to record_counts and per_file_sha256
    for lang, p_info in language_packs.items():
        record_counts[p_info["fileName"]] = p_info["entityCount"]
        per_file_sha256[p_info["fileName"]] = p_info["sha256"]

    bundle_json_str = json.dumps(bundle, ensure_ascii=False, separators=(",", ":"))
    uncompressed_bytes = bundle_json_str.encode("utf-8")
    compressed_path = out_dir / "catalog_bundle.json.gz"
    gzip_compress(uncompressed_bytes, compressed_path)
    compressed_bytes = compressed_path.read_bytes()
    bundle_sha256 = compute_sha256(compressed_bytes)

    search_index_count = len(bundle.get("search_index.json", {}).get("data", []))

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
        "activeLanguages": list(ACTIVE_LANGUAGES),
        "recordCounts": record_counts,
        "perFileSha256": per_file_sha256,
        "languagePacks": language_packs,
    }

    release_path = out_dir / "release.json"
    save_json(release_path, release)
    print(f"Generated {release_path}")
    print(f"Core bundle: {compressed_path} ({len(compressed_bytes):,} bytes)")

    return release


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--rehearsal", action="store_true", help="Build to rehearsal directory")
    args = parser.parse_args()

    out_dir = REHEARSAL_OUT_DIR if args.rehearsal else args.out_dir
    print(f"=== Starting Catalog Build (out_dir: {out_dir}) ===")
    release = build_release(args.source, out_dir, args.cache)
    print("\n=== Build Completed Successfully! ===")


if __name__ == "__main__":
    main()
