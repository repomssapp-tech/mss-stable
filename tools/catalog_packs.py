"""Catalog packs: the runtime catalog as one `core` file plus one file per jurisdiction.

    catalog_core.json.gz        every non-scheme catalog, the manifest, the id map
    catalog_<jurisdiction>.json.gz   that jurisdiction's schemes, applicability rows
                                     and search-index rows (central, tamil_nadu, ...)

Every file is a registry of sections keyed by catalog file name, the same shape
the single-file bundle had, so a reader that merges the packs sees exactly the
old bundle. Only three sections are partitioned (PARTITIONED); in a pack they
carry just `data`. The core file keeps each section's `metadata` (describing the
merged section) and a `packSlot`: where the packs' rows go inside the core rows,
so the merged order equals the original order.

The core manifest lists the packs (file, jurisdiction, tenantId, required,
languages, per-section record counts, sha256, bytes). A pack file's SHA-256
cannot live inside itself, so the core file is the root: it vouches for every
pack, and the server-side SHA-256 in release.json vouches for the core file.
"""

from __future__ import annotations

import gzip
import hashlib
import json
from pathlib import Path

CORE_FILE = "catalog_core.json.gz"
LEGACY_BUNDLE_FILE = "catalog_bundle.json.gz"  # the single-file layout (bundleFormat 2)
PACK_FILE_FMT = "catalog_{jurisdiction}.json.gz"
PACK_SECTION = "pack.json"
SCHEME_SECTION = "scheme_catalog.json"
PARTITIONED = [SCHEME_SECTION, "applicability_matrix_catalog.json", "search_index.json"]
# Jurisdictions whose schemes apply to every user: their pack is always required.
REQUIRED_JURISDICTIONS = {"central"}


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def pack_file_name(jurisdiction: str) -> str:
    return PACK_FILE_FMT.format(jurisdiction=jurisdiction)


def dump_gz(obj: dict, path: Path) -> bytes:
    raw = json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    # mtime=0: the same data always gives the same bytes, so hashes are reproducible.
    blob = gzip.compress(raw, compresslevel=9, mtime=0)
    path.write_bytes(blob)
    return blob


def load_gz(path: Path) -> dict:
    return json.loads(gzip.decompress(path.read_bytes()).decode("utf-8"))


def _scheme_jurisdictions(bundle: dict) -> dict[str, str]:
    return {
        e["identity"]["id"]: (e.get("provenance") or {}).get("jurisdiction") or "central"
        for e in bundle[SCHEME_SECTION]["data"]
    }


def _row_scheme_id(section: str, row: dict) -> str | None:
    """The scheme a partitioned row belongs to, or None for a core row."""
    if section == SCHEME_SECTION:
        return row["identity"]["id"]
    if section == "applicability_matrix_catalog.json":
        return (row.get("identity") or {}).get("code")
    if row.get("entityType") == "scheme":  # search_index.json
        return row.get("entityId")
    return None


def split(bundle: dict, out_dir: Path, languages_by_jurisdiction: dict | None = None) -> list[dict]:
    """Write the jurisdiction packs of [bundle] to [out_dir]; return `manifest.packs`.

    [bundle] is changed in place: its partitioned sections keep only the core
    rows and a `packSlot`. The caller stores the returned list in the manifest
    and then calls [write_core], so the core's manifest carries every pack's hash.
    """
    jur_of = _scheme_jurisdictions(bundle)
    order: list[str] = []
    for jur in jur_of.values():
        if jur not in order:
            order.append(jur)

    rows: dict[str, dict[str, list]] = {j: {s: [] for s in PARTITIONED} for j in order}
    core_rows: dict[str, list] = {s: [] for s in PARTITIONED}
    slots: dict[str, int | None] = {s: None for s in PARTITIONED}
    for section in PARTITIONED:
        for row in bundle[section]["data"]:
            sid = _row_scheme_id(section, row)
            jur = jur_of.get(sid) if sid else None
            if jur is None:
                core_rows[section].append(row)
            else:
                if slots[section] is None:
                    slots[section] = len(core_rows[section])
                rows[jur][section].append(row)
        if slots[section] is None:
            slots[section] = len(core_rows[section])

    packs = []
    for jur in order:
        counts = {s: len(rows[jur][s]) for s in PARTITIONED}
        file_name = pack_file_name(jur)
        content = {
            PACK_SECTION: {
                "metadata": {"catalogName": "pack"},
                "data": [{"packId": jur, "jurisdiction": jur, "tenantId": jur}],
            },
            **{s: {"data": rows[jur][s]} for s in PARTITIONED},
        }
        blob = dump_gz(content, out_dir / file_name)
        packs.append({
            "id": jur,
            "kind": "jurisdiction",
            "file": file_name,
            "jurisdiction": jur,
            # Only the id for now; branding and access rules come with tenants.
            "tenantId": jur,
            "required": jur in REQUIRED_JURISDICTIONS,
            "languages": (languages_by_jurisdiction or {}).get(jur, []),
            "recordCounts": counts,
            "bytes": len(blob),
            "sha256": _sha256(blob),
        })
    for section in PARTITIONED:
        bundle[section]["data"] = core_rows[section]
        bundle[section]["packSlot"] = slots[section]
    return packs


def write_core(bundle: dict, out_dir: Path, packs: list[dict]) -> dict:
    """Write the core file; its manifest lists the core itself, then [packs]."""
    manifest = bundle["manifest.json"]["data"][0]
    core_entry = {"id": "core", "kind": "core", "file": CORE_FILE, "required": True}
    manifest["packs"] = [core_entry, *packs]
    blob = dump_gz(bundle, out_dir / CORE_FILE)
    return {"file": CORE_FILE, "bytes": len(blob), "sha256": _sha256(blob)}


def merge(core: dict, packs: dict[str, dict]) -> dict:
    """Merge [packs] (file name -> parsed pack) into [core]; returns the merged bundle.

    The result is the old single-file bundle: partitioned sections hold every
    row in original order and `packSlot` is gone.
    """
    manifest = core["manifest.json"]["data"][0]
    listed = [p for p in manifest.get("packs", []) if p.get("kind") == "jurisdiction"]
    merged = dict(core)
    for section in PARTITIONED:
        base = core[section]
        slot = base.get("packSlot", len(base["data"]))
        rows = list(base["data"][:slot])
        for info in listed:
            pack = packs.get(info["file"])
            if pack is not None:
                rows.extend(pack[section]["data"])
        rows.extend(base["data"][slot:])
        merged[section] = {k: v for k, v in base.items() if k != "packSlot"}
        merged[section]["data"] = rows
    return merged


def load_dir(directory: Path, *, verify: bool = True) -> dict:
    """Read the core and every pack listed in its manifest, verify each pack's
    SHA-256 against the manifest, and return the merged bundle."""
    if not (directory / CORE_FILE).exists() and (directory / LEGACY_BUNDLE_FILE).exists():
        return load_gz(directory / LEGACY_BUNDLE_FILE)  # a release from before the packs
    core = load_gz(directory / CORE_FILE)
    manifest = core["manifest.json"]["data"][0]
    parsed: dict[str, dict] = {}
    for info in manifest.get("packs", []):
        if info.get("kind") != "jurisdiction":
            continue
        path = directory / info["file"]
        if not path.exists():
            if info.get("required"):
                raise FileNotFoundError(f"required pack missing: {info['file']}")
            continue
        if verify and _sha256(path.read_bytes()) != info["sha256"]:
            raise ValueError(f"pack {info['file']} does not match its manifest sha256")
        parsed[info["file"]] = load_gz(path)
    return merge(core, parsed)


def pack_files(directory: Path) -> list[Path]:
    """Every runtime catalog file in [directory]: the core and the packs."""
    return sorted(p for p in directory.glob("catalog_*.json.gz") if p.is_file())


def total_bytes(directory: Path) -> int:
    return sum(p.stat().st_size for p in pack_files(directory))


def total_uncompressed_bytes(directory: Path) -> int:
    """Bytes the runtime catalog expands to: the core and every pack, decompressed.

    `release.json` publishes this as `uncompressedBytes` so a client can bound its
    decompression output before inflating (the API verifies length + SHA-256 first,
    then decompresses with a limit)."""
    return sum(len(gzip.decompress(p.read_bytes())) for p in pack_files(directory))
