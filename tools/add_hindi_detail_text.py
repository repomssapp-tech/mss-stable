#!/usr/bin/env python3
"""Adds Hindi to the nested scheme detail text of the catalogue packs.

The app shows a scheme's required documents and services from
`content.requiredDocuments[]` and `content.applicationProcess.services[]`.
Those fields are plain English strings, or multilingual objects the adapter
already understands (`{"en": ..., "ta": ...}`). This writes the Hindi next to
the English as `{"en": ..., "hi": ...}`, so the app reads it from the catalogue
(`SchemeAdapterTextUtils.extractHi`) instead of only from the app dictionary.

Hindi comes from, in order:
  1. `localization.hi.documents` (the catalogue's own Hindi document names),
  2. `frontend/assets/catalog/translation_dictionary_hi.json` (exact match on the
     lower-cased English text).
Text with no Hindi is left as it is. The run is idempotent.

It reads the packs with `catalog_packs.load_dir`, edits the scheme records and
writes them back with `catalog_packs.split` / `write_core`, so the core manifest
carries the new pack hashes.

Usage:
    python tools/add_hindi_detail_text.py [--dir PATH] [--out-dir PATH] [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import catalog_packs  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DIR = ROOT / "frontend" / "assets" / "catalog"
DICTIONARY = DEFAULT_DIR / "translation_dictionary_hi.json"

DOC_FIELDS = ("name", "description", "issuingAuthorityText", "estimatedCostText", "remarks")
SERVICE_FIELDS = ("name", "category", "description", "purpose", "department", "notes")
FLAG = {"origin": "machine", "engine": "mss-hi-dictionary-1", "verified": False}


def load_dictionary(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("phraseMap", {}), data.get("tagMap", {})


def lookup(text: str, first: dict[str, str], second: dict[str, str]) -> str | None:
    key = text.strip().lower()
    return first.get(key) or second.get(key)


def english_of(value) -> str | None:
    """The English text of a plain string or an `{"en": ...}` object."""
    if isinstance(value, str):
        return value
    if isinstance(value, dict) and isinstance(value.get("en"), str):
        return value["en"]
    return None


def add_hi(item: dict, field: str, hindi: str | None) -> bool:
    """Store [hindi] beside the English in item[field]; True when it changed."""
    value = item.get(field)
    english = english_of(value)
    if english is None or not english.strip():
        return False
    if isinstance(value, dict) and value.get("hi"):
        return False
    if not hindi or hindi.strip() == english.strip():
        return False
    rest = value if isinstance(value, dict) else {}
    item[field] = {**rest, "en": english, "hi": hindi}
    return True


def services_of(content: dict) -> list:
    process = content.get("applicationProcess")
    for source in (
        process.get("services") if isinstance(process, dict) else None,
        content.get("services"),
        content.get("requiredServices"),
    ):
        if isinstance(source, list) and source:
            return source
    return []


def localise(scheme: dict, phrases: dict, tags: dict) -> int:
    content = scheme.get("content") or {}
    changed = 0

    docs = content.get("requiredDocuments") or content.get("documents")
    if isinstance(docs, list):
        stored = ((scheme.get("localization") or {}).get("hi") or {}).get("documents")
        stored = stored if isinstance(stored, list) and len(stored) == len(docs) else []
        for i, doc in enumerate(docs):
            if not isinstance(doc, dict):
                continue
            for field in DOC_FIELDS:
                english = english_of(doc.get(field))
                if english is None:
                    continue
                hindi = None
                if field == "name" and stored and isinstance(stored[i], str) and stored[i].strip():
                    hindi = stored[i].strip()
                hindi = hindi or lookup(english, phrases, tags)
                changed += add_hi(doc, field, hindi)

    for service in services_of(content):
        if not isinstance(service, dict):
            continue
        for field in SERVICE_FIELDS:
            english = english_of(service.get(field))
            if english is None:
                continue
            # Categories are tags: the tag table wins, like the app's meta().
            first, second = (tags, phrases) if field == "category" else (phrases, tags)
            changed += add_hi(service, field, lookup(english, first, second))

    if changed:
        flags = scheme.setdefault("provenance", {}).setdefault("translationFlags", {})
        flags["detailHi"] = dict(FLAG)
    return changed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", type=Path, default=DEFAULT_DIR, help="catalog packs to read")
    parser.add_argument("--out-dir", type=Path, help="where to write (default: --dir)")
    parser.add_argument("--dictionary", type=Path, default=DICTIONARY)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    out_dir = args.out_dir or args.dir

    phrases, tags = load_dictionary(args.dictionary)
    bundle = catalog_packs.load_dir(args.dir)
    languages = {
        p["jurisdiction"]: p.get("languages", [])
        for p in bundle["manifest.json"]["data"][0].get("packs", [])
        if p.get("kind") == "jurisdiction"
    }

    schemes = bundle[catalog_packs.SCHEME_SECTION]["data"]
    changed_fields = changed_schemes = 0
    for scheme in schemes:
        n = localise(scheme, phrases, tags)
        changed_fields += n
        changed_schemes += 1 if n else 0
    print(f"{changed_fields} fields in {changed_schemes} of {len(schemes)} schemes got Hindi")
    if args.dry_run:
        return

    out_dir.mkdir(parents=True, exist_ok=True)
    packs = catalog_packs.split(bundle, out_dir, languages)
    core = catalog_packs.write_core(bundle, out_dir, packs)
    print(f"wrote {len(packs)} packs; core {core['bytes']} bytes sha256 {core['sha256']}")


if __name__ == "__main__":
    main()
