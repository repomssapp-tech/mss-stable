"""Hindi/Tamil stemming and search support (mirrors the Dart implementation)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from indic_search import IndicVocabulary, indic_text_tokens
from indic_stemmer import indic_stem

FIXTURE = (
    Path(__file__).resolve().parents[2]
    / "frontend"
    / "test"
    / "fixtures"
    / "indic_stem_cases.json"
)


@pytest.mark.parametrize("case", json.loads(FIXTURE.read_text(encoding="utf-8")))
def test_stem_matches_shared_fixture(case: dict[str, str]) -> None:
    assert indic_stem(case["word"]) == case["stem"]


def test_inflections_share_a_stem() -> None:
    assert indic_stem("महिला") == indic_stem("महिलाओं") == indic_stem("महिलाएं")
    assert indic_stem("திட்டம்") == indic_stem("திட்டத்தில்") == indic_stem("திட்டங்கள்")


def test_vocabulary_finds_inflected_variants() -> None:
    vocab = IndicVocabulary(["महिलाओं", "loan", "திட்டங்கள்"])
    assert vocab.variants("महिला") == {"महिलाओं"}
    assert vocab.variants("loan") == set()


def test_text_tokens_keep_only_indic_words() -> None:
    tokens = indic_text_tokens(
        {"hi": {"summary": "महिला loan"}, "ta": {"category": "திட்டம்"}},
        str.split,
    )
    assert tokens == sorted(["महिला", "திட்டம்"])
