"""Apply approved text to a copy of the catalogue, and gate the result against the
previous release before anything replaces it.

Rules enforced here:
  * only approved text whose English has not changed is written;
  * existing text is replaced only when a reviewer superseded that exact text;
  * outside the target language, the catalogue must stay exactly equal.
"""
from __future__ import annotations

import collections
import copy
import hashlib
import re
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import catalog_packs  # noqa: E402

from .config import Config  # noqa: E402
from .ledger import Ledger  # noqa: E402
from .units import CORE, SCHEME_SECTION, Unit, all_units, checksum, get_path, has_text, read_target, write_target  # noqa: E402

MANIFEST = "manifest.json"
MANIFEST_LANGUAGE_KEYS = ("languages", "languageRegistry", "packs")


def project_localization(scheme: dict, lang: str, units: list[Unit]) -> dict:
    """The app-facing `localization.<lang>` block, built from a scheme's units."""
    value = {u.field: read_target(scheme, u, lang) for u in units}
    joined = lambda v: "\n".join(v) if isinstance(v, list) else v  # noqa: E731
    description = value.get("description")
    block = {
        "name": value.get("name"),
        "shortName": value.get("short_name"),
        "summary": description[0] if isinstance(description, list) and description else description,
        "description": joined(description),
        "benefitsText": joined(value.get("benefits")),
        "eligibilityText": joined(value.get("eligibility")),
        "applicationText": joined(value.get("steps")),
        "authority": value.get("authority"),
        "category": value.get("category"),
        "statusNote": value.get("status_note"),
        "mode": value.get("mode"),
        "documents": value.get("documents"),
        "notes": value.get("notes"),
        "altNames": value.get("alt_names"),
    }
    contacts = {f.split(".", 1)[1]: v for f, v in value.items() if f.startswith("contacts.") and v}
    if contacts:
        block["contacts"] = contacts
    return {k: v for k, v in block.items() if v not in (None, "", [])}


# Keys of `localization.<lang>` that each unit field feeds, where they differ from the field.
PROJECTED_KEYS = {
    "short_name": ("shortName",),
    "description": ("summary", "description"),
    "benefits": ("benefitsText",),
    "eligibility": ("eligibilityText",),
    "steps": ("applicationText",),
    "status_note": ("statusNote",),
    "alt_names": ("altNames",),
}


def _update_scheme_metadata(
    scheme: dict, lang: str, units: list[Unit], engines: set[str], superseded: set[str], filled: bool
) -> None:
    current = scheme.setdefault("localization", {}).get(lang) or {}
    projected = project_localization(scheme, lang, units)
    # Existing text stays. Gaps are filled only when this release added new text, and a
    # correction replaces only the fields a reviewer superseded, nothing else in the block.
    block = {**projected, **current} if filled else dict(current)
    for field_name in superseded:
        for key in PROJECTED_KEYS.get(field_name, ("contacts",) if field_name.startswith("contacts.") else (field_name,)):
            if key in projected:
                block[key] = projected[key]
    scheme["localization"][lang] = block
    alt = next((u for u in units if u.field == "alt_names"), None)
    search = scheme.setdefault("search", {})
    aliases = search.setdefault("aliases", {})
    if alt is not None and read_target(scheme, alt, lang) is not None and not aliases.get(lang):
        aliases[lang] = read_target(scheme, alt, lang)
    search.setdefault("keywords", {}).setdefault(lang, [])
    languages = scheme.setdefault("content", {}).setdefault("languages", {})
    available = languages.setdefault("available", [])
    if lang not in available:
        available.append(lang)
        available.sort()
    provenance = scheme.setdefault("provenance", {})
    if engines - {"human"}:
        provenance.setdefault("translationFlags", {})[f"{lang}_is_machine_translation"] = True
    master = provenance.get("master")
    if isinstance(master, dict):
        master.setdefault("translation_meta", {}).setdefault(lang, {
            "origin": "machine" if engines - {"human"} else "human",
            "engine": "+".join(sorted(engines)),
            "verified": False,
        })


def _update_manifest(bundle: dict, lang: str) -> None:
    manifest = bundle[MANIFEST]["data"][0]
    codes = manifest.setdefault("languages", [])
    if not any(entry.get("code") == lang for entry in codes):
        # Listed, not shown: making a language live is a separate, explicit step.
        codes.append({"code": lang, "isActive": False})
        codes.sort(key=lambda entry: entry["code"])
    have = collections.Counter()
    for scheme in bundle[SCHEME_SECTION]["data"]:
        # Any text counts: a scheme name stays English until an official one exists.
        block = get_path(scheme, ("localization", lang))
        if isinstance(block, dict) and any(has_text(v) for v in block.values()):
            have[(scheme.get("provenance") or {}).get("jurisdiction") or "central"] += 1
    jurisdictions = (manifest.get("languageRegistry") or {}).get("jurisdictions", {})
    for jurisdiction, entry in jurisdictions.items():
        if have[jurisdiction] and lang not in entry.get("contentLanguages", []):
            entry["contentLanguages"] = sorted({*entry.get("contentLanguages", []), lang})
    for pack in manifest.get("packs", []):
        if pack.get("kind") == "jurisdiction" and have[pack["jurisdiction"]] and lang not in pack.get("languages", []):
            pack["languages"] = sorted({*pack.get("languages", []), lang})


def _path_text(ident, path: tuple) -> str:
    return f"{ident}|" + "".join(f"[{p}]" if isinstance(p, int) else f".{p}" for p in path)


def apply_events(bundle: dict, lang: str, ledger: Ledger) -> dict:
    """Write approved units into [bundle] in place; returns what happened, per outcome."""
    outcome = collections.Counter()
    pairs = all_units(bundle)
    by_key = {u.key: (e, u) for e, u in pairs}
    units_of = collections.defaultdict(list)
    for _, unit in pairs:
        units_of[unit.entity_id].append(unit)
    written, replaced_paths = [], set()
    engines, superseded, filled = collections.defaultdict(set), collections.defaultdict(set), set()
    for event in ledger.in_state("approved"):
        entry = by_key.get(event["unit"])
        if entry is None:
            outcome["unit_no_longer_exists"] += 1
            continue
        entity, unit = entry
        if event.get("checksum") != unit.source_checksum:
            outcome["english_changed"] += 1
            continue
        existing = read_target(entity, unit, lang)
        if existing is not None and event.get("replaces") != checksum(existing):
            outcome["existing_text_not_superseded"] += 1
            continue
        paths = write_target(entity, unit, lang, copy.deepcopy(event["text"]))
        if not paths:
            outcome["no_write_location"] += 1
            continue
        outcome["written"] += 1
        written.append(event)
        engines[unit.entity_id].add(event.get("engine", "unknown"))
        if not event.get("replaces"):
            filled.add(unit.entity_id)
        else:
            superseded[unit.entity_id].add(unit.field)
            replaced_paths.update(_path_text(unit.entity_id, p) for p in paths)
            replaced_paths.add(_path_text(unit.entity_id, ("localization", lang)))
    for scheme in bundle[SCHEME_SECTION]["data"]:
        sid = scheme["identity"]["id"]
        if sid in engines:
            _update_scheme_metadata(scheme, lang, units_of[sid], engines[sid], superseded[sid], sid in filled)
    if written:
        _update_manifest(bundle, lang)
    return {"outcome": dict(outcome), "written": written, "replaced_paths": replaced_paths}


# ---- gate ------------------------------------------------------------------

def _owned_by(path: str, lang: str) -> bool:
    """Whether a changed path belongs to [lang] and may differ from the previous release."""
    parts = [p for p in re.split(r"[.\[\]]+", path) if p]
    if lang in parts or any(p.endswith(f"_{lang}") for p in parts):
        return True
    return path.endswith(f".translationFlags.{lang}_is_machine_translation")


def diff(old, new, path=""):
    """Leaf differences between two values, as (path, old, new)."""
    if isinstance(old, dict) and isinstance(new, dict):
        for key in old.keys() | new.keys():
            yield from diff(old.get(key), new.get(key), f"{path}.{key}")
    elif isinstance(old, list) and isinstance(new, list) and len(old) == len(new):
        for i, (a, b) in enumerate(zip(old, new)):
            yield from diff(a, b, f"{path}[{i}]")
    elif old != new:
        yield path, old, new


def _coverage(bundle: dict, code: str) -> int:
    return sum(read_target(e, u, code) is not None for e, u in all_units(bundle))


def _manifest_problems(previous: dict, candidate: dict) -> list[str]:
    strip = lambda b: {k: v for k, v in b[MANIFEST]["data"][0].items() if k not in MANIFEST_LANGUAGE_KEYS}  # noqa: E731
    return [f"manifest{path}: changed" for path, _, _ in diff(strip(previous), strip(candidate))]


def _row_problems(ident, old, new, lang: str, replaced: set[str]) -> list[str]:
    problems = []
    for path, before, after in diff(old, new):
        if isinstance(before, str) and isinstance(after, dict) and after.get("en") == before and set(after) <= {"en", lang}:
            continue  # a plain string promoted to {"en": ..., "<lang>": ...}
        if path == ".content.languages.available" and isinstance(before, list) and isinstance(after, list) and set(after) == {*before, lang}:
            continue  # the language list may only gain [lang]
        if not _owned_by(path, lang):
            problems.append(f"{ident}{path}: changed outside {lang}")
        elif has_text(before) and not any(f"{ident}|{path}".startswith(p) for p in replaced):
            problems.append(f"{ident}{path}: existing {lang} text changed or removed")
    return problems


def gate(previous: dict, candidate: dict, config: Config, lang: str, replaced: set[str] | None = None) -> list[str]:
    """Reasons [candidate] may not replace [previous]; empty means it passes."""
    replaced = replaced or set()
    problems = _manifest_problems(previous, candidate)
    for section in candidate.keys() | previous.keys():
        if section == MANIFEST:
            continue
        old_rows = (previous.get(section) or {}).get("data")
        new_rows = (candidate.get(section) or {}).get("data")
        if not isinstance(old_rows, list) or not isinstance(new_rows, list) or len(old_rows) != len(new_rows):
            if old_rows != new_rows:
                problems.append(f"{section}: row count or shape changed")
            continue
        for i, (old, new) in enumerate(zip(old_rows, new_rows)):
            if old == new:
                continue
            old_id = get_path(old, ("identity", "id")) if isinstance(old, dict) else None
            new_id = get_path(new, ("identity", "id")) if isinstance(new, dict) else None
            if old_id != new_id or new_id is None:
                problems.append(f"{section}[{i}]: entity id or order changed")
                continue
            problems.extend(_row_problems(new_id, old, new, lang, replaced))
    for code in {*config.languages, config.source}:
        before, after = _coverage(previous, code), _coverage(candidate, code)
        if after < before:
            problems.append(f"{code}: translations dropped from {before} to {after}")
    return problems


def _sha_all(directory: Path) -> dict[str, str]:
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in catalog_packs.pack_files(directory)}


def _write(bundle: dict, out_dir: Path) -> None:
    manifest = bundle[MANIFEST]["data"][0]
    languages = {p["jurisdiction"]: p.get("languages", []) for p in manifest.get("packs", []) if p.get("kind") == "jurisdiction"}
    packs = catalog_packs.split(bundle, out_dir, languages)
    catalog_packs.write_core(bundle, out_dir, packs)


def release(config: Config, lang: str, ledger: Ledger, packs_dir: Path, out_dir: Path, *, dry_run: bool = False) -> dict:
    """Build the candidate in a temp folder, gate it against [packs_dir], then publish
    it to [out_dir]. A failed gate leaves [out_dir] and the ledger untouched."""
    previous = catalog_packs.load_dir(packs_dir)
    candidate = copy.deepcopy(previous)
    applied = apply_events(candidate, lang, ledger)
    replaced = applied["replaced_paths"]
    problems = gate(previous, candidate, config, lang, replaced)
    result = {"outcome": applied["outcome"], "problems": problems[:50], "problem_count": len(problems), "published": False}
    if problems or dry_run or not applied["written"]:
        return result
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        _write(copy.deepcopy(candidate), tmp_dir)
        # Read back what was written: hashes, record counts and the gate again.
        recheck = gate(previous, catalog_packs.load_dir(tmp_dir), config, lang, replaced)
        if recheck:
            return {**result, "problems": recheck[:50], "problem_count": len(recheck)}
        if _sha_all(tmp_dir) == _sha_all(packs_dir):
            return {**result, "problems": ["candidate is identical to the previous release"], "problem_count": 1}
        out_dir.mkdir(parents=True, exist_ok=True)
        for path in catalog_packs.pack_files(tmp_dir):
            shutil.copy2(path, out_dir / path.name)
    result["files"] = _sha_all(out_dir)
    ledger.append([
        {**{k: v for k, v in e.items() if k != "at"}, "state": "written", "text_checksum": checksum(e["text"])}
        for e in applied["written"]
    ])
    result["published"] = True
    return result


def offer_check(bundle: dict, config: Config, lang: str) -> dict:
    """Per jurisdiction: whether core text is complete enough to offer [lang] to users."""
    language = config.language(lang)
    missing, total = collections.Counter(), collections.Counter()
    for entity, unit in all_units(bundle):
        if unit.tier == CORE and unit.jurisdiction and language.covers(unit.jurisdiction):
            total[unit.jurisdiction] += 1
            if read_target(entity, unit, lang) is None:
                missing[unit.jurisdiction] += 1
    return {j: {"core_units": total[j], "missing": missing[j], "ready": missing[j] == 0} for j in total}


def readiness(repo: Path, lang: str) -> dict:
    """What the app itself still needs before it can show [lang]."""
    l10n = repo / "frontend" / "lib" / "l10n"
    catalog = repo / "frontend" / "assets" / "catalog"
    resolver = repo / "frontend" / "lib" / "services" / "catalog" / "content_language_resolver.dart"
    names = repo / "frontend" / "lib" / "utils" / "language_names.dart"
    return {
        "ui_strings_arb": (l10n / f"app_{lang}.arb").exists(),
        "phrase_dictionary": lang == "ta" or (catalog / f"translation_dictionary_{lang}.json").exists(),
        "content_fallback_order": f"'{lang}'" in resolver.read_text(encoding="utf-8"),
        "language_name": f"'{lang}'" in names.read_text(encoding="utf-8"),
    }
