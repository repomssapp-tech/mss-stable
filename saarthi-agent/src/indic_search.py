"""Hindi/Tamil search support for the voice agent's catalog search.

Mirror of frontend/lib/services/search/indic_search_support.dart: index a
scheme's own Hindi/Tamil text and match inflected words through a shared stem.
"""

from __future__ import annotations

import re
from collections.abc import Callable, Iterable
from typing import Any

from indic_stemmer import indic_stem

INDIC_SCRIPT = re.compile("[ऀ-ॿ஀-௿]")
_TEXT_FIELDS = ("summary", "description", "benefitsText", "eligibilityText", "category")


def indic_text_tokens(
    localization: Any, tokenize: Callable[[str], Iterable[str]]
) -> list[str]:
    """Indic-script words of a scheme's own Hindi and Tamil text."""
    if not isinstance(localization, dict):
        return []
    out: set[str] = set()
    for lang in ("hi", "ta"):
        block = localization.get(lang)
        if not isinstance(block, dict):
            continue
        for key in _TEXT_FIELDS:
            text = block.get(key)
            if isinstance(text, str):
                out.update(t for t in tokenize(text) if INDIC_SCRIPT.search(t))
    return sorted(out)


class IndicVocabulary:
    """Indic words of the search vocabulary, grouped by linguistic stem."""

    def __init__(self, vocabulary: Iterable[str]) -> None:
        self._by_stem: dict[str, set[str]] = {}
        for word in vocabulary:
            if INDIC_SCRIPT.search(word):
                self._by_stem.setdefault(indic_stem(word), set()).add(word)

    def variants(self, token: str) -> set[str]:
        """Vocabulary words sharing the token's stem (inflections of one word)."""
        return self._by_stem.get(indic_stem(token), set()) - {token}
