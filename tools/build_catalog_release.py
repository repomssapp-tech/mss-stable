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

import catalog_packs

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

# Bundle layout version read by the app (MssCatalogBundle). 2 = single file:
# language packs, release identity and the scheme id map are embedded.
BUNDLE_FORMAT = 3

# Scheme-content languages MSS offers per jurisdiction (language policy). A
# jurisdiction not listed here is offered every discovered language that is
# also in ACTIVE_LANGUAGES, so a new state needs no code change. Languages
# present in the data but not offered (e.g. Marathi) are preserved in the
# bundle without being exposed.
OFFERED_LANGUAGES_BY_JURISDICTION = {
    "central": ["en", "hi", "ta"],
    "tamil_nadu": ["en", "ta"],
    "maharashtra": ["en", "hi"],
}


INVENTORY_SECTIONS = INDEXED_CATALOGS + ["search_index.json"]
# Build-history keys of the source manifest; kept, but under `history`, because
# they describe how the catalogs were first authored, not this bundle.
HISTORY_KEYS = ["stage", "baseline", "generationOrder", "reservedFiles", "stageBPasses"]


def canonical_checksum(data) -> str:
    """sha256 of the canonical (sorted keys, compact) JSON of a section's `data`."""
    canonical = json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def finalize_sections(bundle: dict, manifest: dict, release_tag: str, released_at: str) -> None:
    """Make every piece of bundle metadata describe the data actually in the bundle.

    The source catalogs carry `metadata.recordCount`/`checksum` and the source
    manifest an inventory (`files`) written at authoring time; both go stale as
    soon as a catalog is regenerated or edited. Here each section's metadata is
    recomputed from its `data`, and the manifest inventory is rebuilt from those
    sections, so recordCount, schemaVersion and checksum agree everywhere.
    """
    was_required = {f.get("fileName"): f.get("required", False) for f in manifest.get("files", [])}
    inventory = []
    for name in INVENTORY_SECTIONS:
        section = bundle[name]
        data = section.get("data", [])
        meta = section.setdefault("metadata", {})
        meta["recordCount"] = len(data)
        meta["checksum"] = canonical_checksum(data)
        inventory.append({
            "fileName": name,
            "catalogName": meta.get("catalogName"),
            "schemaVersion": meta.get("schemaVersion"),
            "catalogVersion": meta.get("catalogVersion"),
            "recordCount": meta["recordCount"],
            "checksum": meta["checksum"],
            "required": was_required.get(name, False),
        })
    manifest["files"] = inventory
    manifest["history"] = {k: manifest.pop(k) for k in HISTORY_KEYS if k in manifest}
    manifest["catalogRelease"] = release_tag
    manifest["releasedAt"] = released_at


# Language a scheme's text falls back to when the selected language has no value,
# before English. Policy, per jurisdiction; any jurisdiction not listed (or whose
# default is not among the languages it carries) falls back to English directly.
# Kept as English everywhere for now: a Hindi user should see English, not
# Tamil, on a Tamil Nadu scheme.
DEFAULT_LANGUAGE_BY_JURISDICTION: dict[str, str] = {}


def stamp_scheme_languages(bundle: dict, registry: dict) -> None:
    """Write each scheme's own language facts onto the scheme, from the registry:
    `content.languages = {available, offered, default}`. The app then needs no
    jurisdiction table: a scheme says which languages it carries, which are
    offered for it, and which one to fall back to."""
    jurisdictions = registry["jurisdictions"]
    for ent in bundle["scheme_catalog.json"].get("data", []):
        jur = (ent.get("provenance") or {}).get("jurisdiction")
        entry = jurisdictions.get(jur) or {}
        available = sorted((ent.get("localization") or {}).keys(), key=lambda c: (c != "en", c))
        offered = [c for c in entry.get("offeredLanguages", available) if c in available]
        ent["content"]["languages"] = {
            "available": available,
            "offered": offered,
            "default": entry.get("defaultLanguage", "en"),
        }


def build_language_registry(bundle: dict) -> tuple[list[dict], dict]:
    """Discover content languages and per-jurisdiction availability from the data."""
    discovered: set[str] = set()
    by_jurisdiction: dict[str, dict] = {}
    for ent in bundle["scheme_catalog.json"].get("data", []):
        langs = set((ent.get("localization") or {}).keys())
        discovered |= langs
        jur = (ent.get("provenance") or {}).get("jurisdiction") or "unknown"
        entry = by_jurisdiction.setdefault(jur, {"schemeCount": 0, "contentLanguages": set()})
        entry["schemeCount"] += 1
        entry["contentLanguages"] |= langs
    for other in bundle.values():
        if isinstance(other, dict):
            for ent in other.get("data", []) if isinstance(other.get("data"), list) else []:
                if isinstance(ent, dict) and isinstance(ent.get("localization"), dict):
                    discovered |= set(ent["localization"].keys())
    order = sorted(discovered, key=lambda c: (c != "en", c))
    languages = [{"code": c, "isActive": c in ACTIVE_LANGUAGES} for c in order]
    registry = {"jurisdictions": {}}
    for jur, entry in sorted(by_jurisdiction.items()):
        content = sorted(entry["contentLanguages"], key=lambda c: (c != "en", c))
        offered = OFFERED_LANGUAGES_BY_JURISDICTION.get(
            jur, [c for c in content if c in ACTIVE_LANGUAGES])
        offered_in_data = [c for c in offered if c in content]
        default = DEFAULT_LANGUAGE_BY_JURISDICTION.get(jur, "en")
        registry["jurisdictions"][jur] = {
            "schemeCount": entry["schemeCount"],
            "contentLanguages": content,
            "offeredLanguages": offered_in_data,
            "defaultLanguage": default if default in content else "en",
        }
    return languages, registry

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
    """catalog.content rows, read from the local cache.

    The hosted database this used to be fetched from is retired, so the cache
    (backend/scratch/lang/catalog_content_cache.json) is the only source; [refresh]
    is accepted for old callers and ignored.
    """
    if not cache_path.exists():
        raise FileNotFoundError(
            f"catalog content cache not found: {cache_path}. It is the only source of "
            "the non-scheme entity names; restore it from version control."
        )
    with cache_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def inject_entity_content(ent: dict, entity_type: str, eid: str, content_map: dict) -> None:
    """Copy catalog.content (name, aliases, keywords, verified) onto a non-scheme
    entity so no separate language pack is needed at runtime.

    English only refreshes the entity name. Hindi/Tamil add the localized name,
    the reviewed flag, and language-scoped search aliases/keywords."""
    ent.setdefault("localization", {})
    for lang in ("en", "ta", "hi"):
        row = content_map.get((entity_type, eid, lang))
        if not row or not row.get("name"):
            continue
        if lang == "en":
            ent["identity"]["name"] = row["name"]
            ent["localization"][lang] = {"name": row["name"]}
            continue
        ent["localization"][lang] = {"name": row["name"], "verified": bool(row.get("verified", False))}
        search = ent.setdefault("search", {})
        for key in ("aliases", "keywords"):
            values = row.get(key) or []
            if not values:
                continue
            current = search.get(key)
            if isinstance(current, list):  # older shape: a plain English list
                current = {"en": current}
            current = dict(current or {})
            current[lang] = values
            search[key] = current


def build_release_metadata(
    *,
    release_tag: str,
    schema_version: str,
    released_at: str,
    out_dir: Path,
    core: dict,
    packs: list[dict],
    entity_count: int,
    search_index_count: int,
    record_counts: dict,
    per_file_sha256: dict,
) -> dict:
    """The release.json payload for a built core + packs in [out_dir].

    Size fields describe the files on disk: `bundleBytes` is the download size
    (core + packs) and `uncompressedBytes` what that expands to once decompressed,
    which GET /v1/catalog/releases/:tag publishes so clients can bound inflation.
    `bundleSha256` is the core's hash; the core manifest vouches for each pack.
    """
    return {
        "releaseId": str(uuid.uuid4()),
        "releaseTag": release_tag,
        "schemaVersion": schema_version,
        "releasedAt": released_at,
        "bundleFormat": BUNDLE_FORMAT,
        "bundleAsset": f"assets/catalog/{core['file']}",
        "bundleBytes": core["bytes"] + sum(p["bytes"] for p in packs),
        "bundleSha256": core["sha256"],
        "uncompressedBytes": catalog_packs.total_uncompressed_bytes(out_dir),
        "packs": [
            {k: p[k] for k in ("id", "file", "jurisdiction", "tenantId", "required", "bytes", "sha256")}
            for p in packs
        ],
        "entityCount": entity_count,
        "searchIndexCount": search_index_count,
        "activeLanguages": list(ACTIVE_LANGUAGES),
        "recordCounts": record_counts,
        "perFileSha256": per_file_sha256,
        "languagePacks": {},  # language text lives inside each entity's `localization`
    }


def build_release(
    source_dir: Path,
    out_dir: Path,
    cache_path: Path,
    release_tag_override: str | None = None,
    filter_unknown_schemes: bool = True,
    refresh_content: bool = True,
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
    content_rows = load_catalog_content(cache_path, refresh=refresh_content)
    
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

    # 2-3. Update authorities and institutions with catalog.content. Their
    # translations used to travel in separate language packs; they now live on
    # the entity itself (localization.<lang> + search.aliases/keywords.<lang>).
    for entity_type, catalog_key in (("authority", "authority_catalog.json"),
                                     ("institution", "institution_catalog.json")):
        print(f"Injecting catalog.content into {entity_type} records...")
        for ent in bundle[catalog_key].get("data", []):
            eid = ent.get("identity", {}).get("id")
            if not eid:
                continue
            inject_entity_content(ent, entity_type, eid, content_map)

    # Filter schemes if configured (Decision D4: hide draft schemes from offline bundle)
    published_ids_file = ROOT_DIR / "backend" / "scratch" / "lang" / "published_scheme_ids.json"
    published_ids = set(json.loads(published_ids_file.read_text(encoding="utf-8"))) if published_ids_file.exists() else None

    # Schemes imported from schemes_json_only carry their own status and text; the
    # D4 draft list is keyed by pre-2026 ids and must not filter them.
    embedded_schemes = scheme_catalog.get("metadata", {}).get("source") == "schemes_json_only"
    if embedded_schemes:
        filter_unknown_schemes = False

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

    # 4. Release identity. Hindi/Tamil text is embedded in each entity's
    # `localization` block, so there are no separate language packs to build.
    kept_scheme_ids = {s["identity"]["id"] for s in scheme_catalog.get("data", [])}
    manifest = bundle["manifest.json"]["data"][0]
    release_tag = release_tag_override if release_tag_override else manifest["catalogRelease"]
    manifest["catalogRelease"] = release_tag
    schema_version = manifest["schemaVersion"]
    released_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # 5. Build core catalog_bundle.json.gz
    record_counts: dict[str, int] = {}
    per_file_sha256: dict[str, str] = {}
    entity_count = 0
    hashed_files = INDEXED_CATALOGS + ["search_index.json"]

    for filename in INDEXED_CATALOGS + EXTRA_FILES:
        cat_obj = bundle[filename]
        src_path = source_dir / filename
        dest_path = out_dir / filename
        if src_path.exists() and out_dir.resolve() != source_dir.resolve():
            shutil.copy2(src_path, dest_path)
            stored_bytes = dest_path.read_bytes()
        elif src_path.exists():
            stored_bytes = src_path.read_bytes()
        else:
            stored_bytes = json.dumps(cat_obj, ensure_ascii=False, indent=2).encode("utf-8")
            dest_path.write_bytes(stored_bytes)

        if filename in hashed_files:
            per_file_sha256[filename] = compute_sha256(stored_bytes)
        if filename in INDEXED_CATALOGS:
            data = cat_obj.get("data", [])
            record_counts[filename] = len(data)
            entity_count += len(data)

    # Embed everything the app needs besides the catalogs themselves: the
    # release identity, the language registry and the old->new scheme id map.
    # (A hash of the .gz cannot live inside the .gz, so integrity inside the
    # bundle is the per-section record counts below plus gzip's own CRC; the
    # server-side SHA-256 in release.json still guards OTA downloads.)
    languages, language_registry = build_language_registry(bundle)
    stamp_scheme_languages(bundle, language_registry)  # before checksums are sealed
    finalize_sections(bundle, manifest, release_tag, released_at)
    manifest["bundleFormat"] = BUNDLE_FORMAT
    manifest["release"] = {
        "releaseTag": release_tag,
        "releasedAt": released_at,
        "schemaVersion": schema_version,
    }
    manifest["languages"] = languages
    manifest["languageRegistry"] = language_registry
    manifest["recordCounts"] = dict(record_counts)
    manifest["entityCount"] = entity_count
    id_map_path = source_dir / "scheme_id_map.json"
    if id_map_path.exists():
        bundle["migrations.json"] = {
            "metadata": {"catalogName": "migrations", "purpose": "pre-2026 scheme id -> 2026 id"},
            "schemeIdMap": load_json(id_map_path),
        }

    # Split into the core file plus one pack per jurisdiction. Everything above
    # (section metadata, checksums, record counts) describes the MERGED catalog;
    # the packs only partition its rows.
    jurisdiction_languages = {
        jur: info["contentLanguages"]
        for jur, info in language_registry["jurisdictions"].items()
    }
    for stale in out_dir.glob("catalog_*.json.gz"):
        stale.unlink()
    packs = catalog_packs.split(bundle, out_dir, jurisdiction_languages)
    core = catalog_packs.write_core(bundle, out_dir, packs)

    search_index_count = sum(p["recordCounts"]["search_index.json"] for p in packs) + len(
        bundle.get("search_index.json", {}).get("data", [])
    )

    release = build_release_metadata(
        release_tag=release_tag,
        schema_version=schema_version,
        released_at=released_at,
        out_dir=out_dir,
        core=core,
        packs=packs,
        entity_count=entity_count,
        search_index_count=search_index_count,
        record_counts=record_counts,
        per_file_sha256=per_file_sha256,
    )

    release_path = out_dir / "release.json"
    save_json(release_path, release)
    print(f"Generated {release_path}")
    print(f"Core: {core['file']} ({core['bytes']:,} bytes); packs: "
          + ", ".join(f"{p['file']} ({p['bytes']:,})" for p in packs))

    return release


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--rehearsal", action="store_true", help="Build to rehearsal directory")
    parser.add_argument("--offline", action="store_true",
                        help="Accepted for old callers; the build always uses the cached catalog.content")
    parser.add_argument("--release-tag", type=str, default=None, help="Override catalog release tag")
    args = parser.parse_args()

    out_dir = REHEARSAL_OUT_DIR if args.rehearsal else args.out_dir
    print(f"=== Starting Catalog Build (out_dir: {out_dir}) ===")
    release = build_release(args.source, out_dir, args.cache, release_tag_override=args.release_tag,
                            refresh_content=not args.offline)
    print("\n=== Build Completed Successfully! ===")


if __name__ == "__main__":
    main()
