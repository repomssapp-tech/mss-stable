"""Tests for backend/scripts/build_questionnaire.py.

Run: python -m pytest backend/scripts/tests -q
"""

from __future__ import annotations

import csv
import io
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_questionnaire as bq  # noqa: E402

HEADER = [
    "field_id", "category", "required_for", "field_type",
    "question_en", "question_mr", "question_hi",
    "options_en", "options_mr", "options_hi", "purpose_and_scheme_relevance",
]
GENDER = [
    "owner_gender", "Core Profile", "Both", "Single Select",
    "Owner's gender", "मालकाचे लिंग काय आहे?", "मालिक का लिंग क्या है?",
    "Woman | Man | Other", "महिला | पुरुष | इतर", "महिला | पुरुष | अन्य", "",
]
RULES = {"schemes": [{"hard_eligibility_rules": {"owner_gender": {"operator": "in", "values": ["Woman"]}}}]}


def csv_bytes(*rows, bom=True) -> bytes:
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(HEADER)
    for r in rows:
        w.writerow(r)
    data = buf.getvalue().encode("utf-8")
    return (b"\xef\xbb\xbf" + data) if bom else data


def rules_bytes(rules=RULES) -> bytes:
    return json.dumps(rules, ensure_ascii=False).encode("utf-8")


def fields_of(q: bytes) -> dict:
    return {f["id"]: f for f in json.loads(q)["fields"]}


def test_bom_header_is_read():
    q, keyed = bq.build(csv_bytes(GENDER), rules_bytes())
    field = fields_of(q)["owner_gender"]
    assert [o["value"] for o in field["options"]] == ["woman", "man", "other"]
    assert json.loads(keyed)["schemes"][0]["hard_eligibility_rules"]["owner_gender"]["values"] == ["woman"]


def test_option_count_mismatch_fails():
    row = list(GENDER)
    row[8] = "महिला | पुरुष"
    with pytest.raises(bq.BuildError, match="option count differs"):
        bq.build(csv_bytes(row), rules_bytes())


@pytest.mark.parametrize("col,lang", [(5, "mr"), (6, "hi")])
def test_question_without_devanagari_fails(col, lang):
    row = list(GENDER)
    row[col] = "Owner's gender"
    with pytest.raises(bq.BuildError, match=f"question_{lang} has no Devanagari"):
        bq.build(csv_bytes(row), rules_bytes())


def test_unresolved_rule_value_fails():
    rules = {"schemes": [{"hard_eligibility_rules": {"owner_gender": {"values": ["Female"]}}}]}
    with pytest.raises(bq.BuildError, match="'Female' is not an option of owner_gender"):
        bq.build(csv_bytes(GENDER), rules_bytes(rules))


def test_duplicate_slug_fails():
    row = list(GENDER)
    row[7:10] = ["Woman | Woman! | Other", "a | b | c", "a | b | c"]
    with pytest.raises(bq.BuildError, match="duplicate option value 'woman'"):
        bq.build(csv_bytes(row), rules_bytes({}))


@pytest.mark.parametrize("text,key", [
    ("3+ years", "3_plus_years"),
    ("0-5%", "0_5_pct"),
    ("7th–9th Pass", "7th_9th_pass"),  # en dash
    ("Trading / Retail", "trading_retail"),
])
def test_slug(text, key):
    assert bq.slug(text) == key


def test_committed_outputs_are_current():
    """The real dataset builds and the committed files match it."""
    q, keyed = bq.build(bq.CSV_PATH.read_bytes(), bq.RULES_PATH.read_bytes())
    assert bq.OUT_BACKEND.read_bytes() == q
    assert bq.OUT_APP.read_bytes() == q
    assert bq.OUT_RULES.read_bytes() == keyed
    fields = fields_of(q)
    assert len(fields) == 26
    domicile = fields["is_maharashtra_domicile"]
    assert [(o["value"], o["answer"]) for o in domicile["options"]] == [("yes", True), ("no", False)]
    assert [o["value"] for o in fields["business_location"]["options"]] == ["village_rural", "town", "city_urban"]
    assert (fields["owner_age"]["answer"]["min"], fields["owner_age"]["answer"]["max"]) == (18, 99)


def test_rules_inside_lists_are_keyed():
    """Conditional rules are dicts in a list; their option refs must be keyed too."""
    keyed = json.loads(bq.OUT_RULES.read_bytes())
    pmegp = next(s for s in keyed["schemes"] if s["scheme_id"] == "pmegp_central")
    cond = pmegp["hard_eligibility_rules"]["education_level"]["conditional_rules"]
    assert [(c["if_sector"], c["min_level"]) for c in cond] == [
        ("manufacturing", "7th_9th_pass"),
        ("services", "7th_9th_pass"),
    ]
