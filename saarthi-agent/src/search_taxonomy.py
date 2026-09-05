"""Shared scheme-search ranking parameters, loaded from the canonical JSON.

1.2/1.3 (audit_fix.md): mirrors search_engine.ts (TypeScript) and
hybrid_scheme_search.dart (Dart) -- all three load the same values from
their own local copy of search_taxonomy.json rather than declaring them
independently. Do not hand-edit these values here; edit
backend/catalog/search_taxonomy.json (the canonical copy) and re-sync all
three engines' local copies plus their parity tests.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

DEFAULT_TAXONOMY_PATH = (
    Path(__file__).resolve().parents[1] / "data" / "search_taxonomy.json"
)


class SchemeSearchTaxonomy:
    """Loads and holds the shared taxonomy once; safe to call load() repeatedly."""

    def __init__(self, path: Path | str = DEFAULT_TAXONOMY_PATH) -> None:
        data: dict[str, Any] = json.loads(Path(path).read_text(encoding="utf-8"))

        self.short_token_vocab: set[str] = set(data["shortTokenVocab"])
        self.token_re = re.compile(data["tokenRegexSource"])

        taxonomy = data["taxonomy"]
        self.industries: dict[str, list[str]] = taxonomy["industries"]
        self.benefits: dict[str, list[str]] = taxonomy["benefits"]
        self.collateral: dict[str, list[str]] = taxonomy["collateral"]
        self.treds: dict[str, list[str]] = taxonomy["treds"]
        self.communities: dict[str, list[str]] = taxonomy["communities"]
        self.intents: dict[str, list[str]] = taxonomy["intents"]

        self.related_concepts: dict[str, list[str]] = data["relatedConcepts"]
        self.weights: dict[str, float] = data["weights"]
        self.status_factor: dict[str, float] = data["statusFactor"]
        self.status_to_concept: dict[str, str] = data["statusToConcept"]
        self.semantic_query_groups: list[str] = data["semanticQueryGroups"]
        self.query_expansions: dict[str, list[str]] = data["queryExpansions"]

        self.phrase_expansions: dict[str, list[str]] = {}
        self.token_expansions: dict[str, list[str]] = {}
        for key, value in self.query_expansions.items():
            if " " in key:
                self.phrase_expansions[key] = value
            else:
                self.token_expansions[key] = value

    def is_searchable_token(self, token: str) -> bool:
        t = token.lower()
        return len(t) >= 3 or t in self.short_token_vocab

    @staticmethod
    def _find(text_lower: str, table: dict[str, list[str]]) -> list[str]:
        hits: list[str] = []
        for key, terms in table.items():
            for term in terms:
                if term in text_lower:
                    hits.append(key)
                    break
        return hits

    def normalize(self, text: str) -> dict[str, list[str]]:
        """Deterministic: same text always returns the same tags in the same
        order (table-declaration order, not match order)."""
        text_lower = " " + re.sub(r"[^a-z0-9 ]", " ", text.lower()) + " "
        return {
            "industries": self._find(text_lower, self.industries),
            "benefits": self._find(text_lower, self.benefits),
            "collateral": self._find(text_lower, self.collateral),
            "treds": self._find(text_lower, self.treds),
            "communities": self._find(text_lower, self.communities),
            "intents": self._find(text_lower, self.intents),
        }

    def expand_related(self, concepts: set[str]) -> set[str]:
        expanded: set[str] = set()
        for c in concepts:
            expanded.update(self.related_concepts.get(c, []))
        return expanded
