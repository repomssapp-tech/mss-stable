"""Python port of the unified scheme-search ranking engine.

1.3 (audit_fix.md): ported from search_engine.ts (TypeScript, closest in
structure to this file) rather than re-derived, replacing the previous
bucket-scoring approach in scheme_catalog.py. Same taxonomy-based query
normalization, IDF term-rarity weighting, and status-aware ranking factor
as search_engine.ts and hybrid_scheme_search.dart -- this is the third
copy of the SAME engine, not a fourth independently-tuned one. Do not
diverge from the other two without re-validating against them (see
tests/test_hybrid_search_parity.py).
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from typing import Any

from indic_search import (
    IndicVocabulary,
    english_text_tokens,
    indic_text_tokens,
)
from search_taxonomy import SchemeSearchTaxonomy


@dataclass
class SchemeEntry:
    id: str
    status: str  # identity.status: active/unknown/closed
    name_en: str
    raw: dict[str, Any]  # full scheme record
    search_profile: dict[str, Any]  # full search_index record for this scheme, or {}


@dataclass
class ScoredResult:
    scheme_id: str
    name: str
    score: float
    reasons: list[str] = field(default_factory=list)


@dataclass
class _Concept:
    forms: set[str]
    idf: float


def _to_string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(v) for v in value]


def _to_string_set(value: Any) -> set[str]:
    return set(_to_string_list(value))


def _strip_edges(s: str, chars: str) -> str:
    start, end = 0, len(s)
    while start < end and s[start] in chars:
        start += 1
    while end > start and s[end - 1] in chars:
        end -= 1
    return s[start:end]


class HybridSearchEngine:
    def __init__(
        self, entries: list[SchemeEntry], taxonomy: SchemeSearchTaxonomy
    ) -> None:
        self.entries = entries
        self.tax = taxonomy
        self.n_docs = len(entries)
        self.vocab: set[str] = set()
        self._entry_term_cache: dict[str, set[str]] = {}
        self._semantic_codes: dict[str, set[str]] = {}

        for entry in entries:
            ai = entry.raw.get("ai") or {}
            tags = ai.get("semanticTags") or []
            codes = {
                t["code"]
                for t in tags
                if isinstance(t, dict) and isinstance(t.get("code"), str)
            }
            self._semantic_codes[entry.id] = codes

        self._english_text = self._common_word_filtered_english_text()
        self._build_idf()
        self._indic_vocab = IndicVocabulary(self.vocab)

    @staticmethod
    def _tokens_of(profile: dict[str, Any], path: str) -> list[str]:
        tokens = profile.get("tokens") or {}
        return _to_string_list(tokens.get(path))

    @staticmethod
    def _search_profile_of(entry: SchemeEntry) -> dict[str, Any]:
        return entry.search_profile.get("schemeSearchProfile") or {}

    # A word in more than this share of schemes' English text ("eligible",
    # "support") carries no meaning for ranking (mirrors the Dart engine).
    _COMMON_WORD_SHARE = 0.20

    def _common_word_filtered_english_text(self) -> dict[str, list[str]]:
        raw = {
            e.id: english_text_tokens(e.raw.get("localization")) for e in self.entries
        }
        df: dict[str, int] = {}
        for tokens in raw.values():
            for t in tokens:
                df[t] = df.get(t, 0) + 1
        limit = len(self.entries) * self._COMMON_WORD_SHARE
        return {i: [t for t in ts if df[t] <= limit] for i, ts in raw.items()}

    def _indic_tokens(self, entry: SchemeEntry) -> list[str]:
        """The scheme's own Hindi/Tamil text words (the prebuilt index has none)."""
        return indic_text_tokens(
            entry.raw.get("localization"),
            lambda text: [m.group(0).lower() for m in self.tax.token_re.finditer(text)],
        )

    def _searchable_fields(self, entry: SchemeEntry) -> list[tuple[list[str], float]]:
        sp = self._search_profile_of(entry)

        def lower(v: Any) -> list[str]:
            return [s.lower() for s in _to_string_list(v)]

        return [
            (self._tokens_of(entry.search_profile, "en"), 1.0),
            (self._tokens_of(entry.search_profile, "ta"), 1.0),
            (self._indic_tokens(entry), 1.2),
            (self._english_text[entry.id], 0.8),
            (lower(sp.get("loanType")), 0.9),
            (lower(sp.get("subsidyType")), 0.9),
            (lower(sp.get("taxBenefits")), 0.7),
            (lower(sp.get("clusters")), 0.7),
            (lower(sp.get("industryTags")), 0.8),
            (lower(sp.get("benefitTags")), 0.8),
        ]

    def _entry_terms(self, entry: SchemeEntry) -> set[str]:
        cached = self._entry_term_cache.get(entry.id)
        if cached is None:
            cached = set()
            for tokens, _ in self._searchable_fields(entry):
                cached.update(tokens)
            self._entry_term_cache[entry.id] = cached
        return cached

    def _build_idf(self) -> None:
        for entry in self.entries:
            for tokens, _ in self._searchable_fields(entry):
                self.vocab.update(tokens)

    def _idf(self, doc_freq: int) -> float:
        return math.log((self.n_docs + 1) / (doc_freq + 1)) + 1

    def _query_concepts(self, query: str) -> list[_Concept]:
        raw = [
            _strip_edges(m.group(0), "-&").lower()
            for m in self.tax.token_re.finditer(query)
        ]

        concepts: list[_Concept] = []
        seen: set[str] = set()

        # Phase 1: multi-word phrase expansion.
        query_lower = " " + re.sub(r"[^a-z0-9 ]", " ", query.lower()) + " "
        for phrase, expansion_tokens in self.tax.phrase_expansions.items():
            if f" {phrase} " not in query_lower:
                continue
            forms = {f for f in expansion_tokens if f in self.vocab}
            if not forms:
                continue
            key = "\x01".join(sorted(forms))
            if key in seen:
                continue
            seen.add(key)
            doc_freq = sum(1 for e in self.entries if forms & self._entry_terms(e))
            concepts.append(_Concept(forms, self._idf(doc_freq)))

        # Phase 2: per-token concept building (with single-token expansion).
        for tok in raw:
            if not self.tax.is_searchable_token(tok):
                continue
            forms = {tok}
            if "-" in tok:
                forms.update(
                    p for p in tok.split("-") if self.tax.is_searchable_token(p)
                )
            if tok.endswith("s") and tok[:-1] in self.vocab:
                forms.add(tok[:-1])
            if f"{tok}s" in self.vocab:
                forms.add(f"{tok}s")

            expansion = self.tax.token_expansions.get(tok)
            if expansion:
                forms.update(expansion)

            if tok not in self.vocab:
                forms.update(self._indic_vocab.variants(tok))

            gated = {f for f in forms if f in self.vocab}
            forms = gated if gated else {tok}

            key = "\x01".join(sorted(forms))
            if key in seen:
                continue
            seen.add(key)

            doc_freq = sum(1 for e in self.entries if forms & self._entry_terms(e))
            concepts.append(_Concept(forms, self._idf(doc_freq)))

        return concepts

    def _keyword_score_idf(self, entry: SchemeEntry, concepts: list[_Concept]) -> float:
        score = 0.0
        for tokens, weight in self._searchable_fields(entry):
            tokset = set(tokens)
            for concept in concepts:
                if concept.forms & tokset:
                    score += weight * concept.idf
        return score

    def _treds_score(
        self, entry: SchemeEntry, query_tags: dict[str, list[str]]
    ) -> float:
        sp = self._search_profile_of(entry)
        entry_treds = _to_string_set(sp.get("tredsTags"))
        query_treds = set(query_tags["treds"])
        if not entry_treds or not query_treds:
            return 0.0
        score = 0.0
        if entry_treds & query_treds:
            score += 1.0
        if entry_treds & self.tax.expand_related(query_treds):
            score += 0.3
        return score

    def _category_score(
        self, entry: SchemeEntry, query_tags: dict[str, list[str]]
    ) -> float:
        sp = self._search_profile_of(entry)
        score = 0.0
        if set(query_tags["industries"]) & _to_string_set(sp.get("industryTags")):
            score += 1.0
        if set(query_tags["communities"]) & _to_string_set(sp.get("communityTags")):
            score += 1.0
        score += self._treds_score(entry, query_tags)
        return score

    def _eligibility_score(
        self, entry: SchemeEntry, query_tags: dict[str, list[str]]
    ) -> float:
        sp = self._search_profile_of(entry)
        elig = {s.lower() for s in _to_string_set(sp.get("eligibilityKeywords"))}
        if not elig:
            return 0.0  # neutral -- unrecorded, not "matches all"
        query_terms = set(query_tags["communities"]) | set(query_tags["industries"])
        return 1.0 if elig & query_terms else 0.0

    def _benefit_score(
        self, entry: SchemeEntry, query_tags: dict[str, list[str]]
    ) -> float:
        sp = self._search_profile_of(entry)
        benefit_tags = _to_string_set(sp.get("benefitTags"))
        intent_tags = _to_string_set(sp.get("userIntentTags"))
        score = 0.0
        if set(query_tags["benefits"]) & benefit_tags:
            score += 1.0
        if set(query_tags["intents"]) & intent_tags:
            score += 1.0
        collateral_status = _to_string_list(sp.get("collateralStatus"))
        entry_collateral_concepts = {
            self.tax.status_to_concept[s]
            for s in collateral_status
            if s in self.tax.status_to_concept
        }
        if set(query_tags["collateral"]) & entry_collateral_concepts:
            score += 1.0
        return score

    def _semantic_score(
        self, entry: SchemeEntry, query_tags: dict[str, list[str]]
    ) -> float:
        codes = self._semantic_codes.get(entry.id)
        if not codes:
            return 0.0
        concepts: set[str] = set()
        for group in self.tax.semantic_query_groups:
            concepts.update(query_tags.get(group, []))
        if not concepts:
            return 0.0
        covered = len(concepts & codes)
        return covered / len(concepts)

    def _explain_reasons(
        self,
        entry: SchemeEntry,
        query_tags: dict[str, list[str]],
        concepts: list[_Concept],
    ) -> list[str]:
        reasons: list[str] = []
        entry_terms = self._entry_terms(entry)
        hits: list[tuple[str, float]] = []
        for concept in concepts:
            matched = sorted(concept.forms & entry_terms)
            if matched:
                hits.append((matched[0], concept.idf))
        if hits:
            hits.sort(key=lambda h: (-h[1], h[0]))
            reasons.append(f"Matches: {', '.join(h[0] for h in hits)}")

        sp = self._search_profile_of(entry)
        ind = [
            t
            for t in query_tags["industries"]
            if t in _to_string_set(sp.get("industryTags"))
        ]
        if ind:
            reasons.append(f"Industry match: {', '.join(ind)}")

        comm = [
            t
            for t in query_tags["communities"]
            if t in _to_string_set(sp.get("communityTags"))
        ]
        if comm:
            reasons.append(f"Community match: {', '.join(comm)}")

        elig = {s.lower() for s in _to_string_set(sp.get("eligibilityKeywords"))}
        elig_hits = [
            t
            for t in dict.fromkeys(
                [*query_tags["communities"], *query_tags["industries"]]
            )
            if t in elig
        ]
        if elig_hits:
            reasons.append(f"Eligibility match: {', '.join(elig_hits)}")

        ben = [
            t
            for t in query_tags["benefits"]
            if t in _to_string_set(sp.get("benefitTags"))
        ]
        if ben:
            reasons.append(f"Benefit match: {', '.join(ben)}")

        intent = [
            t
            for t in query_tags["intents"]
            if t in _to_string_set(sp.get("userIntentTags"))
        ]
        if intent:
            reasons.append(f"Intent match: {', '.join(intent)}")

        collateral_status = _to_string_list(sp.get("collateralStatus"))
        entry_collateral = {
            self.tax.status_to_concept[s]
            for s in collateral_status
            if s in self.tax.status_to_concept
        }
        collateral_hit = [t for t in query_tags["collateral"] if t in entry_collateral]
        if collateral_hit:
            reasons.append(f"Collateral match: {', '.join(collateral_hit)}")

        codes = self._semantic_codes.get(entry.id) or set()
        if codes:
            semantic_concepts: set[str] = set()
            for group in self.tax.semantic_query_groups:
                semantic_concepts.update(query_tags.get(group, []))
            covered = [c for c in semantic_concepts if c in codes]
            if covered:
                reasons.append(f"Semantic match: {', '.join(covered)}")

        return reasons

    def _score_entry(
        self,
        entry: SchemeEntry,
        query_tags: dict[str, list[str]],
        concepts: list[_Concept],
    ) -> float:
        kw = self._keyword_score_idf(entry, concepts)
        cat = self._category_score(entry, query_tags)
        elig = self._eligibility_score(entry, query_tags)
        ben = self._benefit_score(entry, query_tags)
        semantic = self._semantic_score(entry, query_tags)
        w = self.tax.weights
        raw = (
            w["keyword"] * kw
            + w["semantic"] * semantic
            + w["category"] * cat
            + w["eligibility"] * elig
            + w["benefit"] * ben
        )
        status_factor = self.tax.status_factor.get(entry.status, 1.0)
        final_score = raw * status_factor
        return round(final_score * 10000) / 10000

    def search(self, query: str, top_n: int | None = None) -> list[ScoredResult]:
        """Deterministic: score desc, then schemeId asc as a total-order
        tiebreak (matches search_engine.ts / hybrid_scheme_search.dart)."""
        query_tags = self.tax.normalize(query)
        concepts = self._query_concepts(query)

        scored: list[ScoredResult] = []
        for entry in self.entries:
            score = self._score_entry(entry, query_tags, concepts)
            if score <= 0:
                continue
            scored.append(ScoredResult(entry.id, entry.name_en, score))

        scored.sort(key=lambda r: (-r.score, r.scheme_id))
        limited = scored[:top_n] if top_n is not None else scored

        by_id = {e.id: e for e in self.entries}
        for r in limited:
            r.reasons = self._explain_reasons(by_id[r.scheme_id], query_tags, concepts)
        return limited
