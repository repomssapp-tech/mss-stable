#!/usr/bin/env python3
"""Build backend/catalog/source/scheme_supplement_legacy.json.

The 2026 scheme JSON (schemes_json_only) is the authoritative source for every
scheme. The previous catalog (scheme_catalog.json, old SCH###### ids) carries a
few structured facets the new files do not: structured eligibility, typed
benefit breakdowns, detailed required documents, graph relationships,
classification ids, target beneficiaries, search keywords/aliases and the
verification block.

This tool re-keys those facets onto the NEW scheme ids through the three id
maps shipped with the new data and writes them to a separate supplement file.
It never edits the new source files. The importer merges the supplement with
the rule "new data wins; supplement only fills what the new record lacks".

Usage:
  python tools/build_scheme_supplement.py --new-dir C:\\...\\schemes_json_only \\
      --old legacy_scheme_catalog.json [--out ...]   (see --old help for how to extract it)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT_DIR / "backend" / "catalog" / "source" / "scheme_supplement_legacy.json"


def is_populated(value) -> bool:
    if value is None or value is False:
        return False
    if isinstance(value, (str, list, dict)):
        return len(value) > 0
    return True


def prune(value):
    """Drop null/empty leaves so the supplement stays small and honest."""
    if isinstance(value, dict):
        out = {k: prune(v) for k, v in value.items()}
        return {k: v for k, v in out.items() if is_populated(v)}
    if isinstance(value, list):
        out = [prune(v) for v in value]
        return [v for v in out if is_populated(v)]
    return value


def load_id_maps(new_dir: Path) -> dict[str, str]:
    cen = json.loads((new_dir / "f1_central" / "cen_id_map.json").read_text(encoding="utf-8"))
    tn = json.loads((new_dir / "f2_tamil_nadu" / "tn_id_map.json").read_text(encoding="utf-8"))
    mh_doc = json.loads((new_dir / "f3_maharashtra" / "maharashtra_id_map.json").read_text(encoding="utf-8"))
    mh = mh_doc.get("map", mh_doc)
    merged: dict[str, str] = {}
    for name, mapping in (("central", cen), ("tamil_nadu", tn), ("maharashtra", mh)):
        for old, new in mapping.items():
            if old in merged and merged[old] != new:
                raise SystemExit(f"id map conflict for {old}: {merged[old]} vs {new} ({name})")
            merged[old] = new
    return merged


def old_keys(entity: dict) -> list[str]:
    ident = entity.get("identity", {})
    keys = [ident.get("id"), ident.get("code")]
    keys += [lc.get("code") for lc in ident.get("legacyCodes", []) or []]
    return [k for k in keys if k]


def legacy_code_objects(entity: dict) -> list[dict]:
    """Every pre-2026 code of an old scheme as {code, system}, one entry per
    code: its `identity.legacyCodes` (with their original systems) plus the old
    catalog id."""
    ident = entity["identity"]
    out: list[dict] = []
    seen: set[str] = set()
    for lc in ident.get("legacyCodes") or []:
        code = lc.get("code")
        if code and code not in seen:
            seen.add(code)
            out.append({"code": code, "system": lc.get("system") or "legacy"})
    if ident["id"] not in seen:
        out.append({"code": ident["id"], "system": "pre_2026_catalog_id"})
    return out


def build(old_path: Path, new_dir: Path) -> tuple[dict, dict]:
    old_doc = json.loads(old_path.read_text(encoding="utf-8"))
    old_entities = old_doc["data"]
    id_map = load_id_maps(new_dir)

    # old scheme id (identity.id) -> new id, resolved through any of its codes
    old_to_new: dict[str, str] = {}
    unmatched: list[dict] = []
    for ent in old_entities:
        hits = {id_map[k] for k in old_keys(ent) if k in id_map}
        if len(hits) > 1:
            raise SystemExit(f"{ent['identity']['id']} maps to several new ids: {sorted(hits)}")
        if hits:
            old_to_new[ent["identity"]["id"]] = hits.pop()
        else:
            unmatched.append({"oldId": ent["identity"]["id"], "code": ent["identity"].get("code"),
                              "name": ent["identity"].get("name")})

    data: dict[str, dict] = {}
    duplicate_targets: list[str] = []
    for ent in old_entities:
        old_id = ent["identity"]["id"]
        new_id = old_to_new.get(old_id)
        if not new_id:
            continue
        if new_id in data:
            duplicate_targets.append(new_id)
            continue
        content = ent.get("content", {})
        refs = []
        for ref in ent.get("relationships", {}).get("references", []) or []:
            ref = dict(ref)
            if ref.get("entityType") == "scheme":
                target = old_to_new.get(ref.get("entityId"))
                if not target:
                    continue  # target scheme is not in the new catalog
                ref["entityId"] = target
            refs.append(ref)
        entry = {
            "origin": "legacy_catalog",
            "oldId": old_id,
            "legacyCodes": legacy_code_objects(ent),
            "eligibilityStructured": content.get("eligibility", {}).get("structured"),
            "eligibilityNarrative": content.get("eligibility", {}).get("narrative"),
            "benefits": content.get("benefits"),
            "requiredDocuments": content.get("requiredDocuments"),
            "classification": content.get("classification"),
            "targetBeneficiaries": content.get("targetBeneficiaries"),
            "relationships": refs,
            "search": ent.get("search"),
            "verification": ent.get("verification"),
        }
        data[new_id] = prune(entry)

    report = {
        "oldEntityCount": len(old_entities),
        "matchedToNewIds": len(old_to_new),
        "supplementRecords": len(data),
        "unmatchedOldEntities": unmatched,
        "duplicateTargets": duplicate_targets,
    }
    doc = {
        "metadata": {
            "catalogName": "scheme_supplement_legacy",
            "origin": "legacy_catalog",
            "sourceCatalogVersion": old_doc["metadata"].get("catalogVersion"),
            "mergeRule": "new scheme JSON wins; supplement fills only absent facets",
            "recordCount": len(data),
            "excludedLegacy": unmatched,
        },
        "data": data,
    }
    return doc, report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--new-dir", required=True, type=Path)
    ap.add_argument(
        "--old", required=True, type=Path,
        help="pre-2026 scheme_catalog.json (release 1.36.0-alpha). The repo copy was replaced "
             "by the 2026 import, so extract it from git: "
             "git show 88830a3:backend/catalog/source/scheme_catalog.json > legacy_scheme_catalog.json")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args()

    doc, report = build(args.old, args.new_dir)
    args.out.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(json.dumps({k: (v if not isinstance(v, list) else f"{len(v)} items") for k, v in report.items()}, indent=2))
    for item in report["unmatchedOldEntities"]:
        print(f"  unmatched old scheme: {item['oldId']} {item['code']} {item['name']}")
    return 1 if report["duplicateTargets"] else 0


if __name__ == "__main__":
    sys.exit(main())
