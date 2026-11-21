#!/usr/bin/env python3
"""Build questionnaire.json from the officials' Maharashtra MSME dataset.

Inputs:
  The officials' dataset and eligibility rules below are committed byte-for-byte.
  backend/catalog/msme_maharashtra_dataset_schema.csv      (UTF-8 with BOM)
  backend/catalog/msme_maharashtra_eligibility_rules.json
  The general scope is maintained in:
  backend/catalog/questionnaire_general.json

Outputs:
  backend/catalog/questionnaire.json             generated questionnaire
  frontend/assets/data/questionnaire.json        same bytes, shipped in the app
  backend/catalog/eligibility_rules.keyed.json   the rules with every option
                                                 display text swapped for its
                                                 stable value key

Option value keys are slugs of the English option text. They are stable and
never translated; answers are never matched by display text.

The build fails when:
  * a field has a different option count in en / mr / hi,
  * a Marathi or Hindi question has no Devanagari,
  * two options in one field slug to the same key, or a slug is empty,
  * a rule names an option that the CSV does not have.

Usage:
  python backend/scripts/build_questionnaire.py           write the outputs
  python backend/scripts/build_questionnaire.py --check   fail if out of date
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import sys
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CATALOG = REPO / "backend" / "catalog"
CSV_PATH = CATALOG / "msme_maharashtra_dataset_schema.csv"
RULES_PATH = CATALOG / "msme_maharashtra_eligibility_rules.json"
OUT_BACKEND = CATALOG / "questionnaire.json"
OUT_APP = REPO / "frontend" / "assets" / "data" / "questionnaire.json"
OUT_RULES = CATALOG / "eligibility_rules.keyed.json"
GENERAL_PATH = CATALOG / "questionnaire_general.json"

SCHEMA_VERSION = "1.1.0"
LANGS = ("en", "mr", "hi")
TRANSLATED = ("mr", "hi")
DEVANAGARI = re.compile(r"[ऀ-ॿ]")
OPTION_SEP = re.compile(r"\s*\|\s*")

# CSV field_type -> questionnaire type.
TYPE_MAP = {
    "Single Select": "single_select",
    "Multi Select": "multi_select",
    "Boolean": "boolean",
    "Boolean + Text": "boolean_with_district",
    "Location Selector": "location",
    "Number": "number",
    "Number (Pair)": "number_pair",
    "Text / Tag Picker": "text_tags",
}

# Answer shapes, per DEV-SHARED.md "Profile answer shape".
ANSWER_SHAPE = {
    "single_select": {"kind": "option_value"},
    "multi_select": {"kind": "option_values"},
    "boolean": {"kind": "boolean"},
    "boolean_with_district": {
        "kind": "object",
        "fields": {"resident": "boolean", "district": "string"},
    },
    "location": {
        "kind": "object",
        "fields": {"area": "option_value", "district": "string", "taluka": "string"},
    },
    "number": {"kind": "integer"},
    "number_pair": {"kind": "object", "fields": {"total": "integer", "women": "integer"}},
    "text_tags": {"kind": "strings"},
}


class BuildError(Exception):
    """The dataset breaks a build rule. The message names the field."""


def slug(text: str) -> str:
    """Stable value key from English display text."""
    norm = unicodedata.normalize("NFKD", text)
    # Drop accents; any other non-ASCII char (en dash, etc.) separates words.
    norm = "".join(
        c if ord(c) < 128 else ("" if unicodedata.combining(c) else " ") for c in norm
    ).lower()
    # Keep "3+ years" and "0-5%" readable: 3_plus_years, 0_5_pct.
    norm = norm.replace("+", " plus ").replace("%", " pct ")
    return re.sub(r"[^a-z0-9]+", "_", norm).strip("_")


def read_csv_rows(raw: bytes) -> list[dict[str, str]]:
    # utf-8-sig drops the BOM; plain utf-8 would name the first column
    # "﻿field_id" and every lookup would miss.
    text = raw.decode("utf-8-sig")
    rows = list(csv.DictReader(io.StringIO(text, newline="")))
    if not rows or "field_id" not in rows[0]:
        raise BuildError("CSV has no field_id column (BOM not stripped?)")
    return rows


def split_options(cell: str) -> list[str]:
    cell = cell.strip()
    return OPTION_SEP.split(cell) if cell else []


def per_lang(row: dict[str, str], prefix: str) -> dict[str, str]:
    return {lang: row[f"{prefix}_{lang}"].strip() for lang in LANGS}


def check_devanagari(field_id: str, question: dict[str, str]) -> None:
    for lang in TRANSLATED:
        if not DEVANAGARI.search(question[lang]):
            raise BuildError(f"{field_id}: question_{lang} has no Devanagari")


def build_options(field_id: str, labels: dict[str, list[str]]) -> list[dict]:
    counts = {lang: len(labels[lang]) for lang in LANGS}
    if len(set(counts.values())) != 1:
        raise BuildError(f"{field_id}: option count differs across languages {counts}")
    options, seen = [], set()
    for i, en in enumerate(labels["en"]):
        value = slug(en)
        if not value:
            raise BuildError(f"{field_id}: option {i + 1} ({en!r}) has an empty slug")
        if value in seen:
            raise BuildError(f"{field_id}: duplicate option value {value!r}")
        seen.add(value)
        options.append({"value": value, **{lang: labels[lang][i] for lang in LANGS}})
    return options


# "No (+ Home District)" -> ("No", "Home District")
SUFFIX_PAREN = re.compile(r"^(?P<label>.*?)\s*\(\+\s*(?P<extra>[^)]+)\)\s*$")
# "City (Urban) + District & Taluka" -> ("City (Urban)", "District & Taluka")
SUFFIX_PLUS = re.compile(r"^(?P<label>.*?)\s+\+\s+(?P<extra>.+)$")


def strip_suffix(field_id: str, cell: str, pattern: re.Pattern) -> tuple[list[str], str]:
    """Split the sub-input label off the last option."""
    opts = split_options(cell)
    m = pattern.match(opts[-1]) if opts else None
    if not m:
        raise BuildError(f"{field_id}: expected a sub-input suffix on the last option of {cell!r}")
    opts[-1] = m.group("label").strip()
    return opts, m.group("extra").strip()


def build_field(row: dict[str, str]) -> dict:
    field_id = row["field_id"].strip()
    csv_type = row["field_type"].strip()
    if csv_type not in TYPE_MAP:
        raise BuildError(f"{field_id}: unknown field_type {csv_type!r}")
    qtype = TYPE_MAP[csv_type]
    question = per_lang(row, "question")
    check_devanagari(field_id, question)
    raw = per_lang(row, "options")

    field: dict = {
        "id": field_id,
        "category": slug(row["category"]),
        "category_label_en": row["category"].strip(),
        "required_for": slug(row["required_for"]),
        "type": qtype,
        "question": question,
        "answer": ANSWER_SHAPE[qtype],
    }

    if qtype in ("single_select", "multi_select"):
        field["options"] = build_options(field_id, {l: split_options(raw[l]) for l in LANGS})

    elif qtype in ("boolean", "boolean_with_district"):
        pattern = SUFFIX_PAREN if qtype == "boolean_with_district" else None
        labels, extra = {}, {}
        for lang in LANGS:
            if pattern:
                labels[lang], extra[lang] = strip_suffix(field_id, raw[lang], pattern)
            else:
                labels[lang] = split_options(raw[lang])
        options = build_options(field_id, labels)
        if [o["value"] for o in options] != ["yes", "no"]:
            raise BuildError(f"{field_id}: boolean options must be Yes | No, got {labels['en']}")
        for opt in options:
            opt["answer"] = opt["value"] == "yes"
        field["options"] = options
        if pattern:
            # The CSV attaches the district input to the "No" option.
            field["sub_input"] = {"key": "district", "attached_to": "no", "label": extra}

    elif qtype == "location":
        labels, extra = {}, {}
        for lang in LANGS:
            labels[lang], extra[lang] = strip_suffix(field_id, raw[lang], SUFFIX_PLUS)
        field["options"] = build_options(field_id, labels)
        field["sub_input"] = {"keys": ["district", "taluka"], "label": extra}

    elif qtype == "number":
        # Range from the English cell only; the Marathi cell uses Devanagari digits.
        m = re.search(r"(\d+)\s*-\s*(\d+)", raw["en"])
        if not m:
            raise BuildError(f"{field_id}: no numeric range in {raw['en']!r}")
        field["answer"] = {**field["answer"], "min": int(m.group(1)), "max": int(m.group(2))}
        field["hint"] = raw

    elif qtype == "number_pair":
        parts = {lang: re.split(r"\s+\+\s+", raw[lang]) for lang in LANGS}
        if {len(p) for p in parts.values()} != {2}:
            raise BuildError(f"{field_id}: expected 'A + B' in every language, got {parts}")
        field["parts"] = [
            {
                "key": key,
                "label": {lang: re.sub(r"\s*\([^)]*\)\s*$", "", parts[lang][i]).strip() for lang in LANGS},
            }
            for i, key in enumerate(("total", "women"))
        ]

    elif qtype == "text_tags":
        field["hint"] = raw

    purpose = row.get("purpose_and_scheme_relevance", "").strip()
    if purpose:
        field["purpose_en"] = purpose
    return field


# --- rules: display text -> value key ------------------------------------

# Keys whose string values (or list items) are option display text.
OPTION_REF_KEYS = {
    "value", "values", "if_equals", "if_in", "min_level",
    "required", "required_at_disbursement", "recommended_for_kishore_and_above",
}
# Keys that name another field instead of the one we are inside.
FIELD_ALIAS_KEYS = {"if_sector": "business_nature"}


def _resolve(fields: dict[str, dict], field_id: str, text, where: str):
    if not isinstance(text, str):
        return text  # booleans and numbers pass through
    for opt in fields[field_id].get("options", []):
        if opt["en"] == text:
            return opt["value"]
    raise BuildError(f"rules {where}: {text!r} is not an option of {field_id}")


def key_rules(node, fields: dict[str, dict], field_id: str | None = None, where: str = "$"):
    """Return a copy of the rules with option text replaced by value keys."""
    if isinstance(node, list):
        has_options = bool(field_id and fields[field_id].get("options"))
        return [
            _resolve(fields, field_id, v, f"{where}[{i}]")
            if has_options and isinstance(v, str)
            else key_rules(v, fields, field_id, f"{where}[{i}]")
            for i, v in enumerate(node)
        ]
    if not isinstance(node, dict):
        return node
    out = {}
    for key, value in node.items():
        path = f"{where}.{key}"
        if key in fields:
            out[key] = key_rules(value, fields, key, path)
        elif key in FIELD_ALIAS_KEYS:
            out[key] = _resolve(fields, FIELD_ALIAS_KEYS[key], value, path)
        elif field_id and fields[field_id].get("options") and (
            key in OPTION_REF_KEYS or key.startswith("nudge_")
        ):
            out[key] = (
                [_resolve(fields, field_id, v, path) for v in value]
                if isinstance(value, list)
                else _resolve(fields, field_id, value, path)
            )
        else:
            out[key] = key_rules(value, fields, field_id, path)
    return out


# --- build ----------------------------------------------------------------

def dump(obj) -> bytes:
    return (json.dumps(obj, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def build(
    csv_bytes: bytes,
    rules_bytes: bytes,
    general_bytes: bytes | None = None,
) -> tuple[bytes, bytes]:
    if general_bytes is None:
        general_bytes = GENERAL_PATH.read_bytes()
    rows = read_csv_rows(csv_bytes)
    fields = [build_field(r) for r in rows]
    ids = [f["id"] for f in fields]
    if len(ids) != len(set(ids)):
        raise BuildError("duplicate field_id in CSV")
    general = json.loads(general_bytes.decode("utf-8"))
    if not isinstance(general, dict):
        raise BuildError("general scope must be an object")
    general_fields = general.get("fields", [])
    if not isinstance(general_fields, list) or any(
        not isinstance(field, dict) or not isinstance(field.get("id"), str)
        for field in general_fields
    ):
        raise BuildError("general scope fields must have string ids")
    general_ids = [field["id"] for field in general_fields]
    if len(general_ids) != len(set(general_ids)):
        raise BuildError("general scope has duplicate or invalid field ids")
    if set(ids) & set(general_ids):
        raise BuildError("general scope field ids must not duplicate questionnaire fields")
    by_id = {f["id"]: f for f in fields}

    questionnaire = {
        "schema_version": SCHEMA_VERSION,
        "region": "maharashtra",
        "languages": list(LANGS),
        "source": {"file": CSV_PATH.name, "sha256": hashlib.sha256(csv_bytes).hexdigest()},
        "fields": fields,
        "scopes": {
            "general": {
                **general,
                "source": {
                    "file": GENERAL_PATH.name,
                    "sha256": hashlib.sha256(general_bytes).hexdigest(),
                },
            },
        },
    }

    rules = json.loads(rules_bytes.decode("utf-8"))
    keyed = {
        "generated_from": {
            "file": RULES_PATH.name,
            "sha256": hashlib.sha256(rules_bytes).hexdigest(),
            "note": "Option display text replaced by questionnaire.json value keys. "
            "Do not edit; rebuild with backend/scripts/build_questionnaire.py.",
        },
        **key_rules(rules, by_id),
    }
    return dump(questionnaire), dump(keyed)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="fail if committed outputs are stale")
    args = ap.parse_args(argv)
    try:
        questionnaire, keyed = build(
            CSV_PATH.read_bytes(),
            RULES_PATH.read_bytes(),
            GENERAL_PATH.read_bytes(),
        )
    except BuildError as e:
        print(f"build_questionnaire: FAIL: {e}", file=sys.stderr)
        return 1

    targets = {OUT_BACKEND: questionnaire, OUT_APP: questionnaire, OUT_RULES: keyed}
    if args.check:
        stale = [p for p, data in targets.items() if not p.exists() or p.read_bytes() != data]
        for p in stale:
            print(f"build_questionnaire: stale: {p.relative_to(REPO).as_posix()}", file=sys.stderr)
        if stale:
            print("Run: python backend/scripts/build_questionnaire.py", file=sys.stderr)
            return 1
        print("build_questionnaire: outputs up to date")
        return 0

    for path, data in targets.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        print(f"wrote {path.relative_to(REPO).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
