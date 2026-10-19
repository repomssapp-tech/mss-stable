#!/usr/bin/env python3
"""Before/after size and losslessness report for the runtime catalog assets.

Compares a baseline build (bundle + optional language packs, release.json and
id map) with the current runtime assets and writes a JSON report:

  * runtime asset layout and bytes, before and after
  * uncompressed (compact JSON) and GZIP size of the bundle, compression ratio
  * per-section size (compact JSON and as a standalone GZIP)
  * a lossless comparison: every baseline entity is compared with the current
    one; the only allowed differences are the documented consolidation
    changes, and every baseline language-pack row must be present on the
    current entity.

Usage:
  python tools/catalog_size_report.py --baseline <dir> --current <dir> [--out report.json]
"""
from __future__ import annotations

import argparse
import gzip
import json
import sys
from pathlib import Path

import catalog_packs

PACK_FIELDS = ("name", "shortName", "summary", "objective", "description",
               "benefitsText", "eligibilityText", "applicationText")


def compact(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def gz_len(data: bytes) -> int:
    return len(gzip.compress(data, 9, mtime=0))


def load_bundle(directory: Path) -> tuple[dict, int, int]:
    """The merged catalog, its on-disk size (core + packs) and its JSON size."""
    bundle = catalog_packs.load_dir(directory)
    on_disk = catalog_packs.total_bytes(directory)
    return bundle, on_disk, len(compact(bundle))


def layout(directory: Path, extra: dict[str, Path] | None = None) -> dict:
    runtime = {}
    for f in sorted(directory.iterdir()):
        if f.is_file() and (f.name.startswith("catalog_") and f.name.endswith(".json.gz")
                            or f.name in ("release.json", "scheme_id_map.json")):
            runtime[f.name] = f.stat().st_size
    for name, path in (extra or {}).items():
        if path.exists():
            runtime[name] = path.stat().st_size
    return {"files": runtime, "totalBytes": sum(runtime.values())}


def entity_index(bundle: dict) -> dict[tuple[str, str], dict]:
    index = {}
    for key, section in bundle.items():
        if key.endswith("_catalog.json"):
            for ent in section["data"]:
                index[(key, ent["identity"]["id"])] = ent
    return index


# Stamped by the derived-catalog builders on every run; not content.
VOLATILE_KEYS = {"regeneratedAt", "generatedAt", "extractedAt", "verifiedAt", "createdAt", "updatedAt"}


def drop_volatile(node):
    if isinstance(node, dict):
        return {k: drop_volatile(v) for k, v in node.items() if k not in VOLATILE_KEYS}
    if isinstance(node, list):
        return [drop_volatile(v) for v in node]
    return node


def strip_allowed(ent: dict) -> dict:
    """Remove the documented consolidation differences from an entity."""
    ent = drop_volatile(json.loads(json.dumps(ent)))
    for loc in (ent.get("localization") or {}).values():
        for key in [k for k in loc if k.endswith("List")]:
            loc.pop(key, None)  # duplicates of the verbatim lists kept in `source`
        loc.pop("verified", None)  # moved here from the pack rows
    return ent


def additive_only(base, cur) -> bool:
    """True when `cur` equals `base` plus extra keys (never fewer or different)."""
    if isinstance(base, dict) and isinstance(cur, dict):
        return all(k in cur and additive_only(v, cur[k]) for k, v in base.items())
    return base == cur


def lossless_comparison(base: dict, cur: dict, base_dir: Path) -> dict:
    b_idx, c_idx = entity_index(base), entity_index(cur)
    missing = sorted(set(b_idx) - set(c_idx))
    added = sorted(set(c_idx) - set(b_idx))
    changed = []
    for key in sorted(set(b_idx) & set(c_idx)):
        if not additive_only(strip_allowed(b_idx[key]), strip_allowed(c_idx[key])):
            changed.append(key[1])

    by_type_id = {(e["identity"]["entityType"], e["identity"]["id"]): e for e in c_idx.values()}
    pack_rows = found = 0
    problems = []
    for pack in sorted(base_dir.glob("catalog_pack_*.json.gz")):
        lang = pack.name[len("catalog_pack_"):-len(".json.gz")]
        rows = json.loads(gzip.decompress(pack.read_bytes()).decode("utf-8"))["data"]
        for row in rows:
            pack_rows += 1
            ent = by_type_id.get((row["entityType"], row["entityId"]))
            if ent is None:
                problems.append((lang, row["entityId"], "entity missing"))
                continue
            loc = (ent.get("localization") or {}).get(lang) or {}
            search = ent.get("search") or {}
            bad = [f for f in PACK_FIELDS if row.get(f) not in (None, "") and loc.get(f) != row[f]]
            for key in ("aliases", "keywords"):
                wanted = row.get(key) or []
                have = (search.get(key) or {}).get(lang) if isinstance(search.get(key), dict) else None
                if wanted and have != wanted:
                    bad.append(key)
            if "verified" in row and row["entityType"] != "scheme" and loc.get("verified") != row["verified"]:
                bad.append("verified")
            if bad:
                problems.append((lang, row["entityId"], bad))
            else:
                found += 1
    return {
        "baselineEntities": len(b_idx), "currentEntities": len(c_idx),
        "entitiesMissingFromCurrent": missing[:10], "entitiesAddedInCurrent": added[:10],
        "entitiesChangedBeyondDocumentedRules": changed[:10], "changedCount": len(changed),
        "baselinePackRows": pack_rows, "packRowsFoundOnEntities": found,
        "packProblems": problems[:10], "packProblemCount": len(problems),
        "lossless": not missing and not changed and not problems,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--baseline", required=True, type=Path)
    ap.add_argument("--current", required=True, type=Path)
    ap.add_argument("--baseline-id-map", type=Path, default=None,
                    help="scheme_id_map.json that shipped as a separate file in the baseline")
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    base, base_gz, base_raw = load_bundle(args.baseline)
    cur, cur_gz, cur_raw = load_bundle(args.current)

    def sections(bundle: dict) -> dict:
        out = {}
        for key, value in bundle.items():
            data = compact(value)
            records = len(value["data"]) if isinstance(value, dict) and isinstance(value.get("data"), list) else None
            out[key] = {"records": records, "compactBytes": len(data), "standaloneGzipBytes": gz_len(data)}
        return out

    extra = {"scheme_id_map.json": args.baseline_id_map} if args.baseline_id_map else None
    base_layout = layout(args.baseline, extra)
    cur_layout = layout(args.current)
    report = {
        "layout": {"before": base_layout, "after": cur_layout},
        "bundle": {
            "before": {"gzipBytes": base_gz, "uncompressedBytes": base_raw, "ratio": round(base_raw / base_gz, 2)},
            "after": {"gzipBytes": cur_gz, "uncompressedBytes": cur_raw, "ratio": round(cur_raw / cur_gz, 2)},
        },
        "runtimeCatalogBytes": {
            "before": base_layout["totalBytes"], "after": cur_layout["totalBytes"],
            "savedBytes": base_layout["totalBytes"] - cur_layout["totalBytes"],
            "savedPercent": round(100 * (1 - cur_layout["totalBytes"] / base_layout["totalBytes"]), 1),
        },
        "sections": {"before": sections(base), "after": sections(cur)},
        "losslessComparison": lossless_comparison(base, cur, args.baseline),
    }
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.out:
        args.out.write_text(text + "\n", encoding="utf-8")
    print(json.dumps({k: report[k] for k in ("bundle", "runtimeCatalogBytes", "losslessComparison")},
                     ensure_ascii=False, indent=2))
    return 0 if report["losslessComparison"]["lossless"] else 1


if __name__ == "__main__":
    sys.exit(main())
