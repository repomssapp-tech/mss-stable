#!/usr/bin/env python3
"""Import the 2026 scheme JSON (schemes_json_only) into backend/catalog/source.

Reads the three jurisdiction *app* files (central, Tamil Nadu, Maharashtra),
validates them, merges the legacy supplement (scheme_supplement_legacy.json,
see build_scheme_supplement.py) and writes a new scheme_catalog.json whose
entities keep the MssEntity shape the Flutter adapters already read:
identity / content / localization / search / relationships / metadata, plus
two additive keys:

  source      the verbatim 2026 record, so no field is lost and the app can
              render attributes it has no dedicated model for
  provenance  origin, master-file provenance, translation flags

Merge rule: values from the 2026 files always win. The supplement only fills
facets the 2026 record does not carry. Nothing is translated or invented.

Also writes scheme_id_map.json (old id -> new id, shipped to the app so saved
items can be migrated) and schemes_import_report.json.

Usage:
  python tools/import_schemes_json.py --new-dir C:\\...\\schemes_json_only
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT_DIR / "backend" / "catalog" / "source"
LANG_ORDER = ["en", "hi", "ta", "mr"]
ENTITY_SCHEMA = "1.1.0"  # additive over 1.0.0 (adds `source`, `provenance`)

JURISDICTIONS = [
    # key, app file, master file, state code, state label
    ("central", "f1_central/central_schemes_app_2026.json",
     "f1_central/central_schemes_master_2026.json", None, "All India"),
    ("tamil_nadu", "f2_tamil_nadu/tamil_nadu_schemes_app_2026.json",
     "f2_tamil_nadu/tamil_nadu_schemes_master_2026.json", "IN-TN", "Tamil Nadu"),
    ("maharashtra", "f3_maharashtra/maharashtra_schemes_app_2026.json",
     None, "IN-MH", "Maharashtra"),
]
MASTER_ONLY_KEYS = ["field_sources", "translation_meta", "level_basis", "source_scheme_id",
                    "pending_translation", "source", "documents_sources", "internal_notes"]


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", (text or "").lower()).strip("-")


def as_list(value) -> list:
    if value is None:
        return []
    return list(value) if isinstance(value, list) else [value]


def lang_text(value, lang: str):
    """{lang: str|list} -> value for lang, None when absent/empty."""
    if isinstance(value, dict):
        v = value.get(lang)
        return v if v not in (None, "", []) else None
    return None


def join_lines(items) -> str | None:
    lines = [str(i).strip() for i in as_list(items) if str(i).strip()]
    return "\n".join(lines) if lines else None


def langs_of(rec: dict) -> list[str]:
    present = list((rec.get("name") or {}).keys())
    return [l for l in LANG_ORDER if l in present] + [l for l in present if l not in LANG_ORDER]


def per_lang_scalar(rec: dict, lang: str, path: list[str], suffix_key: str | None = None):
    """English value lives at top level; other languages under translations.<lang>."""
    if lang == "en":
        node = rec
        for key in path:
            node = node.get(key) if isinstance(node, dict) else None
        return node
    node = (rec.get("translations") or {}).get(lang) or {}
    for key in path:
        node = node.get(key) if isinstance(node, dict) else None
    if node in (None, "", []) and suffix_key:
        node = rec.get(f"{suffix_key}_{lang}")
    return node


def flatten_documents(documents) -> list[str]:
    """documents may be a list, an audience dict, or null."""
    if isinstance(documents, dict):
        out: list[str] = []
        for _audience, items in documents.items():
            out += [str(i).strip() for i in as_list(items)]
        return out
    return [str(i).strip() for i in as_list(documents) if str(i).strip()]


def build_localization(rec: dict, lang: str) -> dict:
    how = rec.get("how_to_apply") or {}
    desc = lang_text(rec.get("description"), lang)
    loc = {
        "name": lang_text(rec.get("name"), lang),
        "shortName": lang_text(rec.get("short_name"), lang),
        "summary": as_list(desc)[0] if desc else None,
        "description": join_lines(desc),
        "benefitsText": join_lines(lang_text(rec.get("benefits"), lang)),
        "eligibilityText": join_lines(lang_text(rec.get("eligibility"), lang)),
        "applicationText": join_lines(lang_text(how.get("steps"), lang)),
        "authority": per_lang_scalar(rec, lang, ["authority"], "authority"),
        "category": per_lang_scalar(rec, lang, ["category"]),
        "statusNote": per_lang_scalar(rec, lang, ["status", "note"]),
        "mode": per_lang_scalar(rec, lang, ["how_to_apply", "mode"]),
    }
    docs = per_lang_scalar(rec, lang, ["how_to_apply", "documents"], "documents")
    notes = per_lang_scalar(rec, lang, ["how_to_apply", "notes"], "notes")
    if lang == "en":
        docs, notes = how.get("documents"), how.get("notes")
    else:
        # Some sources keep the translated lists beside the English ones, as
        # how_to_apply.documents_ta / notes_hi, instead of under `translations`.
        if not flatten_documents(docs):
            docs = how.get(f"documents_{lang}")
        if not as_list(notes):
            notes = how.get(f"notes_{lang}")
    loc["documents"] = flatten_documents(docs) or None
    loc["notes"] = [str(n) for n in as_list(notes)] or None
    alt = rec.get("alt_names")
    if isinstance(alt, dict):
        loc["altNames"] = as_list(alt.get(lang)) or None
    elif lang == "en":
        loc["altNames"] = as_list(alt) or None
    else:
        loc["altNames"] = as_list(((rec.get("translations") or {}).get(lang) or {}).get("alt_names")) or None
    contacts = per_lang_scalar(rec, lang, ["contacts"])
    if contacts:
        loc["contacts"] = contacts
    return {k: v for k, v in loc.items() if v not in (None, "", [], {})}


def merge_documents(rec: dict, supp: dict, audit: MergeAudit | None = None) -> list[dict]:
    """Required documents: the 2026 list is authoritative. Legacy detail
    (issuing authority, mandatory flag, cost...) is attached only to documents
    whose name matches. Legacy documents with no match are counted, never
    appended, so a document cannot appear twice under different wording."""
    how = rec.get("how_to_apply") or {}
    new_docs = flatten_documents(how.get("documents"))
    old_docs = supp.get("requiredDocuments") or []
    norm = lambda text: re.sub(r"\W+", "", str(text).lower())
    by_name = {norm(d.get("name", "")): d for d in old_docs}
    out = []
    if new_docs:
        matched = set()
        for idx, name in enumerate(new_docs, 1):
            legacy = by_name.get(norm(name), {})
            if legacy:
                matched.add(norm(name))
            entry = {k: v for k, v in legacy.items() if not is_empty(v)}
            entry.update({"name": name, "documentId": f"{rec['id']}-DOC{idx:03d}"})
            if legacy:
                entry["origin"] = "2026+legacy_detail"
            out.append(entry)
        if audit is not None:
            audit.unmatched_legacy_documents += sum(1 for key in by_name if key not in matched)
        return out
    for d in old_docs:  # new record lists no documents: fall back to legacy detail
        d = dict(d)
        d["origin"] = "legacy_catalog"
        out.append(d)
    return out


def build_legacy_codes(rec: dict, supp: dict, master: dict | None) -> list[dict]:
    """Pre-2026 identifiers of a scheme as {code, system}, exactly one entry per
    code (first wins, so a code carrying a real system is never repeated under a
    generic one). Order: the old catalog's codes with their systems, the 2026
    record's own legacy_id, then the master file's source_scheme_id."""
    out: list[dict] = []
    seen: set[str] = set()

    def add(code, system):
        if code and code not in seen:
            seen.add(code)
            out.append({"code": code, "system": system})

    for lc in supp.get("legacyCodes") or []:
        add(lc.get("code"), lc.get("system") or "legacy")
    add(rec.get("legacy_id"), "pre_2026_draft_id")
    add((master or {}).get("source_scheme_id"), "pre_2026_source_id")
    return out


def build_aliases_keywords(rec, supp, languages, localization, legacy_codes):
    aliases: dict[str, list] = {}
    keywords: dict[str, list] = {}
    seen: set[tuple[str, str]] = set()
    old_search = supp.get("search") or {}
    for lang in languages:
        loc = localization[lang]
        values = list(loc.get("altNames", [])) + [loc.get("shortName")]
        if lang == "en":
            values += legacy_codes
        values += (old_search.get("aliases") or {}).get(lang, [])
        deduped = []
        for v in values:
            if v and (lang, v.lower()) not in seen:
                seen.add((lang, v.lower()))
                deduped.append(v)
        aliases[lang] = deduped
        keywords[lang] = list((old_search.get("keywords") or {}).get(lang, []))
    return aliases, keywords


def is_empty(value) -> bool:
    """Only absent/blank values count as missing. False and 0 are real values."""
    return value is None or value == "" or value == [] or value == {}


class MergeAudit:
    """Records what the legacy supplement filled and where it disagreed."""

    def __init__(self) -> None:
        self.filled: Counter = Counter()  # facet path -> number of schemes filled
        self.conflicts: list[dict] = []  # authoritative value kept
        self.unmatched_legacy_documents = 0

    def conflict(self, scheme_id: str, path: str, new, legacy) -> None:
        self.conflicts.append({"schemeId": scheme_id, "field": path, "kept": new, "legacy": legacy})


def fill_missing(new, legacy, path: str, scheme_id: str, audit: MergeAudit):
    """Return `new` with its gaps filled from `legacy`.

    - the authoritative `new` value always wins;
    - a gap (None, "", [], {}) is filled with a copy of the legacy value;
    - dicts merge key by key; lists and scalars are never combined, so no
      document, benefit or URL can appear twice;
    - a non-empty legacy value that differs from a kept new value is logged.
    """
    if is_empty(new):
        if not is_empty(legacy):
            audit.filled[path] += 1
            return copy.deepcopy(legacy)
        return new
    if is_empty(legacy):
        return new
    if isinstance(new, dict) and isinstance(legacy, dict):
        out = dict(new)
        for key, lv in legacy.items():
            out[key] = fill_missing(new.get(key), lv, f"{path}.{key}", scheme_id, audit)
        return out
    if new != legacy:
        audit.conflict(scheme_id, path, new, legacy)
    return new


def missing_fields(entity_parts: dict, supp: dict) -> list[dict]:
    """Record, factually, which facets the 2026 source (plus supplement) lacks.
    Merged with any missingFields the supplement already carries."""
    out = [dict(m) for m in (supp.get("verification") or {}).get("missingFields", [])]
    have = {m.get("field") for m in out}
    checks = [
        ("content.requiredDocuments", bool(entity_parts["documents"])),
        ("content.applicationProcess.steps", bool(entity_parts["steps"])),
        ("content.schemeUrl", bool(entity_parts["scheme_url"])),
    ]
    for field, present in checks:
        if not present and field not in have:
            out.append({"field": field, "reason": "not provided in the 2026 source"})
    return out


def build_entity(rec: dict, jur: str, state_code, state_label, master: dict | None,
                 supp: dict, catalog_version: str, known_ids: set,
                 portals: dict | None = None, audit: MergeAudit | None = None) -> dict:
    audit = audit or MergeAudit()
    sid = rec["id"]
    how = rec.get("how_to_apply") or {}
    status = rec.get("status") or {}
    languages = langs_of(rec)
    localization = {lang: build_localization(rec, lang) for lang in languages}
    en = localization.get("en", {})
    steps_en = as_list(lang_text(how.get("steps"), "en"))
    old_class = supp.get("classification") or {}
    # Two different questions, kept apart:
    #   * originDataset  - which 2026 file the record came from (drives the
    #     content languages the record carries);
    #   * applicability  - where the scheme applies (drives level/state filters).
    # `central_state` (centrally sponsored, run by one state) applies only in
    # that state, so it is a state-level scheme here; the raw value is kept in
    # `sourceLevel`. A central scheme filed in a state dataset (e.g. an
    # all-India scheme listed by Tamil Nadu) applies nationally, not in that state.
    source_level = rec.get("level") or "central"
    level = "central" if source_level == "central" else "state"
    is_central = level == "central"
    state_text = rec.get("state") or state_label
    applies_nationally = is_central and bool(
        re.match(r"(all india|pan-india)", (state_text or "").lower()))

    # What the 2026 record itself provides, per facet; the legacy supplement
    # then fills only the gaps (see fill_missing).
    benefits = fill_missing(
        {"summary": en.get("benefitsText")}, supp.get("benefits") or {},
        "content.benefits", sid, audit)
    benefits.setdefault("benefitTypes", [])
    if is_empty(benefits.get("currency")):
        benefits["currency"] = "INR"

    elig_narr = fill_missing(
        {"criteria": en.get("eligibilityText")}, supp.get("eligibilityNarrative") or {},
        "content.eligibility.narrative", sid, audit)

    classification = fill_missing(
        {
            "categories": [en["category"]] if en.get("category") else [],
            "government": {
                "country": "IN",
                "departmentText": en.get("authority"),
                "level": "central" if is_central else "state",
                "levelText": "Central" if is_central else "State",
                "states": [state_code] if state_code and not applies_nationally else [],
                "statesText": state_text,
                "sourceLevel": source_level,
                "originDataset": jur,
                "appliesNationally": applies_nationally,
            },
        },
        old_class, "content.classification", sid, audit)
    if is_empty(classification.get("schemeTypeText")):
        classification["schemeTypeText"] = en.get("category")
    for key in ("schemeType", "sectors", "sectorsText", "tags"):
        classification.setdefault(key, [] if key in ("sectors", "tags") else None)
    government = classification["government"]
    if applies_nationally:
        government["states"] = []  # never let a legacy state list narrow a national scheme

    target_beneficiaries = fill_missing(
        {}, supp.get("targetBeneficiaries") or {}, "content.targetBeneficiaries", sid, audit)
    for key, default in (("beneficiaryTypes", []), ("businessStages", []), ("description", None),
                         ("enterpriseTypes", []), ("specialCategories", [])):
        target_beneficiaries.setdefault(key, default)

    legacy_entries = build_legacy_codes(rec, supp, master)
    legacy_codes = [entry["code"] for entry in legacy_entries]
    aliases, keywords = build_aliases_keywords(rec, supp, languages, localization, legacy_codes)

    references = [dict(r) for r in supp.get("relationships") or []]
    existing = {(r.get("entityType"), r.get("entityId")) for r in references}
    for rid in as_list(rec.get("related_ids")):
        if rid in known_ids and ("scheme", rid) not in existing:
            references.append({"entityId": rid, "entityType": "scheme", "relationType": "related",
                               "role": None, "note": "related_ids in 2026 source"})

    sources = [{"sourceType": kind, "url": url, "isPrimary": kind == "apply"}
               for kind, url in (("apply", how.get("apply_url")), ("info", how.get("info_url")),
                                 ("guidelines", how.get("guidelines_url"))) if url]
    for ps in how.get("procedure_sources") or []:
        sources.append({"sourceType": "procedure", "url": ps.get("url"), "accessedOn": ps.get("retrieved"),
                        "title": ps.get("note"), "isPrimary": False})

    application = {
        "mode": (how.get("mode") or "").lower() or None,
        "modeText": en.get("mode") or how.get("mode"),
        "onlineUrl": how.get("apply_url"),
        "offlineDetails": None,
        "services": [],
        "steps": steps_en,
        "applicationFeeText": how.get("fees") if isinstance(how.get("fees"), str) else None,
        "applicationFeeInr": None,
        "portal": how.get("portal"),
        "procedureType": how.get("procedure_type"),
        "applicationStatus": how.get("application_status"),
        "statusCheckedOn": how.get("status_checked_on"),
        "prerequisite": how.get("prerequisite"),
        "deadline": how.get("deadline"),
    }

    provenance = {
        "origin": "schemes_json_only",
        "jurisdiction": jur,
        "transformationNotes": [],
        "fieldSources": [],
        "supplement": {"origin": supp.get("origin"), "oldId": supp.get("oldId")} if supp else None,
        "translationFlags": {k: v for k, v in rec.items() if k.endswith("_is_machine_translation")},
        "nameSource": rec.get("name_source"),
        "legacyId": rec.get("legacy_id"),
    }
    if master:
        provenance["master"] = {k: master[k] for k in MASTER_ONLY_KEYS if k in master}

    documents = merge_documents(rec, supp, audit)
    scheme_url = how.get("info_url") or how.get("apply_url")
    verification = dict(supp.get("verification") or {})
    verification["missingFields"] = missing_fields(
        {"documents": documents, "steps": steps_en, "scheme_url": scheme_url}, supp)

    portal_key = how.get("portal")
    portal_info = None
    if portals and isinstance(portal_key, str) and portal_key in portals:
        portal_info = {"key": portal_key, **portals[portal_key]}

    return {
        "identity": {
            "id": rec["id"], "code": rec["id"], "entityType": "scheme", "language": "en",
            "name": en.get("name"), "shortName": en.get("shortName"), "acronym": None,
            "slug": slugify(en.get("name") or rec["id"]),
            "status": status.get("value") or "unknown",
            "legacyCodes": legacy_entries,
        },
        "content": {
            "overview": {
                "summary": en.get("summary"), "description": en.get("description"),
                "objective": None, "background": None, "legalBasis": [],
                "lastUpdated": status.get("as_of"), "lastUpdatedText": status.get("as_of"),
                "validity": {"from": None, "to": None, "isOpenEnded": None, "text": None},
            },
            "objectives": [],
            "benefits": benefits,
            "benefitFacts": rec.get("benefit_facts"),
            "eligibility": {"narrative": elig_narr,
                            "structured": supp.get("eligibilityStructured") or {}},
            "applicationProcess": application,
            "applicationTimeline": {"text": None, "opensOn": None, "closesOn": None,
                                    "isRollingIntake": None, "cycles": [],
                                    "processingDurationDays": None},
            "requiredDocuments": documents,
            "classification": classification,
            "targetBeneficiaries": target_beneficiaries,
            "contacts": rec.get("contacts"),
            "faqs": [],
            "schemeUrl": scheme_url,
            "portalInfo": portal_info,
            "sources": sources,
            "status": {"value": status.get("value"), "note": en.get("statusNote"),
                       "asOf": status.get("as_of")},
            "appRelevance": rec.get("app_relevance"),
        },
        "localization": localization,
        "search": {"aliases": aliases, "keywords": keywords, "boostTerms": [],
                   "crossReferences": [], "searchRank": None, "synonyms": []},
        "relationships": {"references": references},
        "metadata": {"catalogVersion": catalog_version, "createdAt": status.get("as_of"),
                     "recordStatus": "published", "revision": 1, "schemaVersion": ENTITY_SCHEMA,
                     "updatedAt": status.get("as_of")},
        "verification": verification,
        "provenance": provenance,
        "source": rec,
    }


OLD_SCHEME_ID = re.compile(r"^SCH\d{6}$")
REMAPPED_CATALOGS = ["authority_catalog.json", "institution_catalog.json", "finance_catalog.json",
                     "tax_catalog.json", "export_catalog.json"]


def remap_node(node, id_map: dict, stats: Counter):
    """Rewrite old scheme ids to new ones. Entries pointing at schemes absent from
    the new catalog are removed from lists; scalar fields become None."""
    if isinstance(node, str):
        if OLD_SCHEME_ID.match(node):
            if node in id_map:
                stats["remapped"] += 1
                return id_map[node]
            stats["dropped"] += 1
            return None
        return node
    if isinstance(node, list):
        out = []
        for item in node:
            new = remap_node(item, id_map, stats)
            if isinstance(item, str) and new is None:
                continue
            if isinstance(new, dict) and new.get("__drop__"):
                continue
            out.append(new)
        return out
    if isinstance(node, dict):
        out = {k: remap_node(v, id_map, stats) for k, v in node.items()}
        scheme_target = out.get("entityId") if out.get("entityType") == "scheme" else None
        if out.get("entityType") == "scheme" and scheme_target is None:
            return {"__drop__": True}
        return out
    return node


def remap_other_catalogs(out_dir: Path, id_map: dict) -> dict:
    """Other catalogs (authority, finance, ...) still cite the old SCH###### ids."""
    report = {}
    for name in REMAPPED_CATALOGS:
        path = out_dir / name
        doc = read_json(path)
        stats: Counter = Counter()
        doc["data"] = remap_node(doc["data"], id_map, stats)
        path.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        report[name] = dict(stats)
    return report


def validate(records: list[tuple[str, dict]]) -> dict:
    issues: list[str] = []
    ids = Counter(r["id"] for _, r in records)
    for sid, n in ids.items():
        if n > 1:
            issues.append(f"duplicate id {sid} x{n}")
    for jur, r in records:
        if not r.get("id") or not isinstance(r.get("name"), dict) or not r["name"].get("en"):
            issues.append(f"{jur}: record missing id or English name: {r.get('id')}")
        for rid in as_list(r.get("related_ids")):
            if rid not in ids:
                issues.append(f"{r['id']}: dangling related_id {rid}")
    return {"issues": issues, "uniqueIds": len(ids)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--new-dir", required=True, type=Path)
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--catalog-version", default=None,
                    help="defaults to manifest.json catalogRelease in --out-dir")
    ap.add_argument("--audit-report", type=Path,
                    default=ROOT_DIR / "docs" / "reports" / "scheme_merge_audit.json",
                    help="where to write the legacy-merge audit (filled gaps, conflicts, excluded ids)")
    args = ap.parse_args()

    out_dir: Path = args.out_dir
    supplement_path = out_dir / "scheme_supplement_legacy.json"
    if not supplement_path.exists():
        print("missing scheme_supplement_legacy.json - run tools/build_scheme_supplement.py first", file=sys.stderr)
        return 2
    supplement = read_json(supplement_path)["data"]
    manifest = read_json(out_dir / "manifest.json")["data"][0]
    catalog_version = args.catalog_version or manifest["catalogRelease"]

    records = []
    portals_by_jur: dict[str, dict] = {}
    languages_by_jur: dict[str, Counter] = {}
    source_files = []
    for key, app_rel, master_rel, state_code, state_label in JURISDICTIONS:
        doc = read_json(args.new_dir / app_rel)
        masters = {}
        if master_rel:
            masters = {m["id"]: m for m in read_json(args.new_dir / master_rel)["schemes"]}
        source_files.append({"jurisdiction": key, "file": app_rel, "records": len(doc["schemes"]),
                             "metaVersion": doc["meta"].get("version"),
                             "masterFile": master_rel, "masterRecords": len(masters)})
        portals_by_jur[key] = doc.get("portals") or {}
        languages_by_jur[key] = Counter()
        for rec in doc["schemes"]:
            records.append((key, rec, state_code, state_label, masters.get(rec["id"])))
            languages_by_jur[key].update(langs_of(rec))

    verdict = validate([(j, r) for j, r, *_ in records])
    if verdict["issues"]:
        for issue in verdict["issues"][:40]:
            print("INVALID:", issue, file=sys.stderr)
        return 1

    known_ids = {r["id"] for _, r, *_ in records}
    audit = MergeAudit()
    entities = [build_entity(copy.deepcopy(rec), jur, state_code, state_label, master,
                             supplement.get(rec["id"], {}), catalog_version, known_ids,
                             portals_by_jur.get(jur), audit)
                for jur, rec, state_code, state_label, master in records]
    entities.sort(key=lambda e: e["identity"]["id"])

    old_catalog = read_json(out_dir / "scheme_catalog.json")
    meta = dict(old_catalog["metadata"])
    meta.update({"catalogVersion": catalog_version, "schemaVersion": ENTITY_SCHEMA,
                 "recordCount": len(entities), "totalSchemes": len(entities),
                 "source": "schemes_json_only",
                 "jurisdictions": {k: sum(1 for j, *_ in records if j == k) for k, *_ in JURISDICTIONS},
                 "contentLanguages": {k: sorted(v) for k, v in languages_by_jur.items()}})
    canonical = json.dumps(entities, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    meta["checksum"] = "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    (out_dir / "scheme_catalog.json").write_text(
        json.dumps({"metadata": meta, "data": entities}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    id_map: dict[str, str] = {}
    for rel in ("f1_central/cen_id_map.json", "f2_tamil_nadu/tn_id_map.json",
                "f3_maharashtra/maharashtra_id_map.json"):
        m = read_json(args.new_dir / rel)
        id_map.update(m.get("map", m))
    # Saved items written before id was the canonical key may hold a legacy code
    # (e.g. TN001, IN001); map those too, never overriding a real old id.
    code_aliases = 0
    for e in entities:
        for lc in e["identity"]["legacyCodes"]:
            if lc["code"] not in id_map:
                id_map[lc["code"]] = e["identity"]["id"]
                code_aliases += 1
    (out_dir / "scheme_id_map.json").write_text(
        json.dumps(dict(sorted(id_map.items())), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    remap_report = remap_other_catalogs(out_dir, id_map)

    with_supp = sum(1 for e in entities if supplement.get(e["identity"]["id"]))
    # Records whose applicability differs from what their dataset implies. Listed
    # so a reviewer sees them; each is handled explicitly (see build_entity).
    jurisdiction_exceptions = []
    for e in entities:
        gov = e["content"]["classification"]["government"]
        dataset = gov["originDataset"]
        if (dataset == "central" and not gov["appliesNationally"]) or (
                dataset != "central" and gov["sourceLevel"] != "state"):
            jurisdiction_exceptions.append({
                "id": e["identity"]["id"], "name": e["identity"]["name"], "dataset": dataset,
                "sourceLevel": gov["sourceLevel"], "state": gov["statesText"],
                "level": gov["level"], "appliesNationally": gov["appliesNationally"],
                "states": gov["states"],
            })
    report = {
        "sourceDir": str(args.new_dir), "catalogVersion": catalog_version,
        "entityCount": len(entities), "uniqueIds": verdict["uniqueIds"],
        "bySource": source_files,
        "contentLanguagesByJurisdiction": {k: dict(v) for k, v in languages_by_jur.items()},
        "statusCounts": dict(Counter(e["identity"]["status"] for e in entities)),
        "withLegacySupplement": with_supp, "withoutLegacySupplement": len(entities) - with_supp,
        "jurisdictionExceptions": jurisdiction_exceptions,
        "remappedReferencesByCatalog": remap_report,
        "idMapEntries": len(id_map), "idMapCodeAliases": code_aliases, "unmappedNewIds": sorted(known_ids - set(id_map.values()))[:20],
        "emptyDescription": sum(1 for e in entities if not e["localization"]["en"].get("description")),
        "emptyBenefits": sum(1 for e in entities if not e["localization"]["en"].get("benefitsText")),
        "emptyEligibility": sum(1 for e in entities if not e["localization"]["en"].get("eligibilityText")),
    }
    (out_dir / "schemes_import_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    supplement_meta = read_json(supplement_path).get("metadata", {})
    audit_doc = {
        "rule": supplement_meta.get("mergeRule"),
        "legacyCatalogVersion": supplement_meta.get("sourceCatalogVersion"),
        "schemesWithLegacySupplement": with_supp,
        "schemesWithout2026Counterpart": len(supplement_meta.get("excludedLegacy", [])),
        "excludedLegacy": supplement_meta.get("excludedLegacy", []),
        "gapsFilledFromLegacy": dict(sorted(audit.filled.items())),
        "legacyDocumentsNotMatched": audit.unmatched_legacy_documents,
        "conflictCount": len(audit.conflicts),
        "conflictsByField": dict(Counter(c["field"] for c in audit.conflicts).most_common()),
        "conflicts": audit.conflicts,
    }
    args.audit_report.parent.mkdir(parents=True, exist_ok=True)
    args.audit_report.write_text(json.dumps(audit_doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    report["mergeConflicts"] = len(audit.conflicts)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
