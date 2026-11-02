"""The catalogue's translatable text as one flat list of units.

The packs store target text in irregular places (`source.name.hi`, `notes_ta`,
`authority_ta`, `translations.hi.category`, ...). This is the only module that
knows them: everything else works on `Unit`, for any language code. A path part
containing "{L}" is filled with the language code.
"""
from __future__ import annotations

import hashlib
import json
import unicodedata
from dataclasses import dataclass, field

SCHEME_SECTION = "scheme_catalog.json"
CORE, DETAIL, REFERENCE = "core", "detail", "reference"
# Fact properties that hold identifiers rather than display text.
FACT_SKIP = {"type", "source"}
CONTACT_TEXT = ("office", "address", "hours")
DOC_DETAIL = ("name", "description", "issuingAuthorityText", "estimatedCostText", "remarks")


def get_path(node, path):
    for part in path:
        if isinstance(node, dict) and part in node:
            node = node[part]
        elif isinstance(node, list) and isinstance(part, int) and 0 <= part < len(node):
            node = node[part]
        else:
            return None
    return node


def has_text(value) -> bool:
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, list):
        return any(has_text(v) for v in value)
    return False


def checksum(value) -> str:
    """Hash of a value's meaning: normalised, so whitespace edits do not mark it stale."""
    def norm(v):
        if isinstance(v, str):
            return " ".join(unicodedata.normalize("NFC", v).split())
        return [norm(x) for x in v] if isinstance(v, list) else v
    raw = json.dumps(norm(value), ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


@dataclass(frozen=True)
class Spec:
    """Where one field lives. `writes` entries are (path, anchor): the first
    `anchor` path parts must already exist, or that location is skipped."""
    id: str
    en: tuple
    reads: tuple
    writes: tuple
    tier: str = CORE
    promote: tuple | None = None  # a plain string here becomes {"en": ..., "<L>": ...}


@dataclass
class Unit:
    entity_id: str
    section: str
    jurisdiction: str | None
    field: str
    tier: str
    en: object
    spec: Spec = field(repr=False)
    pending: bool = False  # English the owner has marked "do not translate yet"

    @property
    def key(self) -> str:
        return f"{self.entity_id}|{self.field}"

    @property
    def source_checksum(self) -> str:
        return checksum(self.en)


def fill(path, lang):
    return tuple(p.replace("{L}", lang) if isinstance(p, str) else p for p in path)


def _simple(fid, *base):
    """A field stored as a {lang: value} map at [base]."""
    return Spec(fid, (("source", *base, "en"),), (("source", *base, "{L}"),), ((("source", *base, "{L}"), 0),))


def _translated(fid, en, tr, *legacy):
    """A field whose English is plain and whose target sits in `translations.<L>`."""
    path = ("source", "translations", "{L}", *tr)
    return Spec(fid, (en,), (path, *legacy), ((path, 0),))


_HOW = ("source", "how_to_apply")
_TR_HOW = ("source", "translations", "{L}", "how_to_apply")
BASE_SPECS = (
    _simple("name", "name"),
    _simple("short_name", "short_name"),
    Spec(
        "alt_names",
        (("source", "alt_names", "en"), ("source", "alt_names"), ("source", "alt_names_i18n", "en")),
        (("source", "alt_names", "{L}"), ("source", "alt_names_i18n", "{L}"), ("source", "translations", "{L}", "alt_names")),
        # source.alt_names may be a plain list, which rejects the write.
        ((("source", "alt_names", "{L}"), 2), (("source", "alt_names_i18n", "{L}"), 2), (("source", "translations", "{L}", "alt_names"), 0)),
    ),
    _simple("description", "description"),
    _simple("benefits", "benefits"),
    _simple("eligibility", "eligibility"),
    Spec("steps", (_HOW + ("steps", "en"),), (_HOW + ("steps", "{L}"),), ((_HOW + ("steps", "{L}"), 0),)),
    _translated("authority", ("source", "authority"), ("authority",), ("source", "authority_{L}")),
    _translated("category", ("source", "category"), ("category",)),
    _translated("status_note", ("source", "status", "note"), ("status", "note")),
    _translated("mode", _HOW + ("mode",), ("how_to_apply", "mode")),
    Spec("notes", (_HOW + ("notes",),), (_HOW + ("notes_{L}",), _TR_HOW + ("notes",)), ((_TR_HOW + ("notes",), 0),)),
)


def _scheme_specs(scheme: dict) -> list[Spec]:
    specs = list(BASE_SPECS)
    docs = get_path(scheme, _HOW + ("documents",))
    if isinstance(docs, dict):
        for key in docs:
            path = _TR_HOW + ("documents", key)
            specs.append(Spec(f"documents.{key}", (_HOW + ("documents", key),), (path,), ((path, 0),)))
    elif docs:
        doc_path = _HOW + ("documents_{L}",)
        specs.append(Spec("documents", (_HOW + ("documents",),), (doc_path, _TR_HOW + ("documents",)), ((doc_path, 0),)))
    for key in CONTACT_TEXT:
        path = ("source", "translations", "{L}", "contacts", key)
        specs.append(Spec(f"contacts.{key}", (("source", "contacts", key),), (path,), ((path, 0),)))
    facts = get_path(scheme, ("source", "benefit_facts", "facts")) or []
    for i, fact in enumerate(facts):
        if not isinstance(fact, dict):
            continue
        for key, value in fact.items():
            if isinstance(value, str) and key not in FACT_SKIP:
                base = ("source", "benefit_facts", "facts", i, "translations", "{L}", key)
                mirror = ("content", "benefitFacts", "facts", i, "translations", "{L}", key)
                specs.append(Spec(f"facts[{i}].{key}", (("source", "benefit_facts", "facts", i, key),), (base,), ((base, 0), (mirror, 4))))
    for i, doc in enumerate(get_path(scheme, ("content", "requiredDocuments")) or []):
        if not isinstance(doc, dict):
            continue
        for key in DOC_DETAIL:
            base = ("content", "requiredDocuments", i, key)
            specs.append(Spec(f"required_documents[{i}].{key}", (base + ("en",), base), (base + ("{L}",),), ((base + ("{L}",), 0),), tier=DETAIL, promote=base))
    return specs


def _english(entity: dict, spec: Spec):
    for path in spec.en:
        value = get_path(entity, path)
        if has_text(value):
            return value
    return None


def scheme_units(scheme: dict) -> list[Unit]:
    jurisdiction = (scheme.get("provenance") or {}).get("jurisdiction") or "central"
    pending = get_path(scheme, ("provenance", "master", "pending_translation")) is True
    units = []
    for spec in _scheme_specs(scheme):
        en = _english(scheme, spec)
        if en is not None:
            units.append(Unit(scheme["identity"]["id"], SCHEME_SECTION, jurisdiction, spec.id, spec.tier, en, spec, pending))
    return units


def reference_units(section: str, entity: dict) -> list[Unit]:
    entity_id = get_path(entity, ("identity", "id"))
    english = get_path(entity, ("localization", "en"))
    if not entity_id or not isinstance(english, dict):
        return []
    units = []
    for key, value in english.items():
        if isinstance(value, str) and value.strip():
            path = ("localization", "{L}", key)
            spec = Spec(key, (("localization", "en", key),), (path,), ((path, 0),), tier=REFERENCE)
            units.append(Unit(entity_id, section, None, key, REFERENCE, value, spec))
    return units


def all_units(bundle: dict) -> list[tuple[dict, Unit]]:
    """Every (entity, unit) in a merged bundle, in stable catalogue order."""
    out = []
    for section, body in bundle.items():
        rows = body.get("data") if isinstance(body, dict) else None
        if not isinstance(rows, list):
            continue
        for row in rows:
            if not isinstance(row, dict):
                continue
            found = scheme_units(row) if section == SCHEME_SECTION else reference_units(section, row)
            out.extend((row, unit) for unit in found)
    return out


def read_target(entity: dict, unit: Unit, lang: str):
    """The existing [lang] text of [unit], or None."""
    for path in unit.spec.reads:
        value = get_path(entity, fill(path, lang))
        if has_text(value):
            return value
    return None


def _set_path(entity, path, value, anchor) -> bool:
    node = entity
    for i, part in enumerate(path[:-1]):
        nxt = get_path(node, (part,))
        if not isinstance(nxt, (dict, list)):
            if i < anchor or nxt is not None or not isinstance(node, dict):
                return False
            nxt = {}
            node[part] = nxt
        node = nxt
    if not isinstance(node, dict):
        return False
    node[path[-1]] = value
    return True


def write_target(entity: dict, unit: Unit, lang: str, value) -> list[tuple]:
    """Write [value] everywhere [unit] keeps it; returns the paths written."""
    if unit.spec.promote:
        current = get_path(entity, unit.spec.promote)
        if isinstance(current, str):
            _set_path(entity, unit.spec.promote, {"en": current}, len(unit.spec.promote))
    written = []
    for path, anchor in unit.spec.writes:
        filled = fill(path, lang)
        if _set_path(entity, filled, value, anchor):
            written.append(filled)
    # An older copy read ahead of what was written would keep hiding the new text.
    for path in unit.spec.reads:
        filled = fill(path, lang)
        if filled in written:
            break
        if has_text(get_path(entity, filled)) and _set_path(entity, filled, value, len(filled) - 1):
            written.append(filled)
    return written
