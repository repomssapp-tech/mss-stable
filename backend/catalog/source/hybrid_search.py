#!/usr/bin/env python3
"""
Hybrid Search Ranking — Phase 1, Step 6.

FinalScore = w1*KeywordRelevance + w2*SemanticSimilarity + w3*CategoryRelevance
           + w4*EligibilityRelevance + w5*BenefitRelevance + w6*UserProfileRelevance

Per SEARCH_ENGINE_IMPROVEMENT_PLAN.md. Deterministic: sort key is
(-round(score, 4), entityId) -- score descending, entityId as a total-order
tiebreak so floating point ties never depend on iteration/hash order.

UserProfileRelevance is 0 in this module (no user profile system exists in
this repo -- that's Flutter-side, per MSS_Execution_Plan.md §3.10). w6 is
kept in the formula for completeness and future wiring, not omitted.
"""
import json, math, os, re, sys
from collections import Counter, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, CAT)
from taxonomy_engine import (normalize as taxonomy_normalize, expand_related,
                             is_searchable_token)
from intelligence_resolver import IntelligenceResolver

WEIGHTS = OrderedDict([
    ("keyword", 1.0), ("semantic", 0.6), ("category", 0.8),
    ("eligibility", 0.5), ("benefit", 0.9), ("profile", 0.0),
])

# ---- Fix #3: status-aware ranking (Phase D5) -------------------------------
#
# Applies AFTER the weighted sum, as a uniform multiplicative factor keyed
# only on identity.status -- never a scheme-specific penalty, never a
# per-query rule. No date field exists anywhere in scheme_catalog.json
# (checked: content has no validity/closureDate) so this is the only real
# status evidence available; nothing was invented to extend it.
#
# "closed" is discounted, never zeroed or filtered -- an explicitly relevant
# closed scheme (e.g. a query naming it, or matching its unique terms) still
# outranks an unrelated active one, satisfying "explicitly requested
# historical/closed schemes remain searchable." "unknown" (112/217 schemes --
# more than half the catalog) gets NO penalty: absence of a confirmed status
# is not evidence of closure, and treating it as such would suppress the
# majority of the catalog on a data gap rather than a fact. See
# SEARCH_STATUS_RANKING_REPORT.md for the factor-value exploration.
STATUS_FACTOR = {"active": 1.0, "unknown": 1.0, "closed": 0.72}


def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))


class HybridSearch:
    def __init__(self):
        self.index = load("search_index.json")["data"]
        self.scheme_entries = [e for e in self.index if e["entityType"] == "scheme"]
        scheme_cat = load("scheme_catalog.json")["data"]
        self.by_id = {r["identity"]["id"]: r for r in scheme_cat}

        # Per-candidate semantic representation: the controlled-vocabulary
        # term codes the catalog already resolved for each scheme. This is the
        # ONLY input to _semantic_score besides the query itself.
        self._semantic_codes = {
            r["identity"]["id"]: {t.get("code") for t in (r.get("ai", {}).get("semanticTags") or [])
                                   if t.get("code")}
            for r in scheme_cat
        }

        self._entry_term_cache = {}
        self._build_idf()

        # ai.relatedEntities: scheme<->scheme similarity. Deliberately NOT a
        # ranking input any more -- it is inherently candidate-to-candidate
        # and was the source of the self-reinforcement bug. Retained only as
        # data a caller may use for an explicit "related schemes" feature.
        self.related = {r["identity"]["id"]: {x["entityId"]: x["similarity"]
                         for x in r.get("ai", {}).get("relatedEntities", [])}
                         for r in scheme_cat}
        # Reused for explain()'s citations -- resolves a scheme's linked
        # finance/tax/etc. records so a collateral/benefit match can cite the
        # actual official source instead of a bare "matched" label. Not a
        # second graph-walk implementation (MIGRATION_PLAN.md non-negotiable
        # 15) -- this IS the one resolver, called from the search layer.
        self.resolver = IntelligenceResolver()

    # ---- Fix #2: corpus IDF / term-rarity weighting -----------------------
    #
    # Mirrors build_search_index.py's tokenise() regex so a query term and an
    # index term have the same surface form. Punctuation the old naive
    # `split()` + `strip(",.")` left attached (?, !, ', etc.) is now dropped,
    # and the >=3 char floor matches the index.
    # Round 3: {1,} admits 2-char candidates; is_searchable_token() then gates
    # them against the controlled short-token vocabulary. Identical regex and
    # identical gate as build_search_index.py, so query and index cannot drift.
    _TOKEN_RE = re.compile(r"[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}")

    def _searchable_fields(self, entry):
        """Every field _keyword_score consults, with its existing weight.
        Single source of truth so IDF is computed over exactly the terms that
        can actually be matched -- weights unchanged from Fix #1."""
        prof = entry.get("schemeSearchProfile") or {}
        return [
            (entry["tokens"]["en"], 1.0),
            (entry["tokens"]["ta"], 1.0),
            ([str(t).lower() for t in prof.get("loanType", [])], 0.9),
            ([str(t).lower() for t in prof.get("subsidyType", [])], 0.9),
            ([str(t).lower() for t in prof.get("taxBenefits", [])], 0.7),
            ([str(t).lower() for t in prof.get("clusters", [])], 0.7),
            ([str(t).lower() for t in prof.get("industryTags", [])], 0.8),
            ([str(t).lower() for t in prof.get("benefitTags", [])], 0.8),
        ]

    def _build_idf(self):
        """Document frequency over the ACTUAL searchable corpus -- every term
        reachable by _keyword_score, across all scheme candidates. No manual
        rarity values, no per-term overrides: one mechanism for every term."""
        self._n_docs = len(self.scheme_entries)
        df = Counter()
        vocab = set()
        for entry in self.scheme_entries:
            terms = set()
            for tokens, _w in self._searchable_fields(entry):
                terms.update(tokens)
            for t in terms:
                df[t] += 1
            vocab.update(terms)
        self._df = df
        self._vocab = vocab

    def _idf(self, doc_freq):
        """Smoothed IDF:  ln((N + 1) / (df + 1)) + 1

        Natural log. Smoothing keeps an unseen term finite and keeps every
        value >= 1, so a matched term can never score below the pre-Fix-#2
        weight of 1.0 -- IDF only ever *raises* a rare term relative to a
        common one, it never suppresses a match below its old value."""
        return math.log((self._n_docs + 1) / (doc_freq + 1)) + 1

    def _query_concepts(self, query):
        """Query -> list of (surface-form set, idf) 'concepts'.

        A concept groups the equivalent surface forms of one query term:
          * hyphenation -- 'women-led' also matches 'women' / 'led'
          * plural/singular -- gated on the corpus vocabulary, so only forms
            the corpus actually contains are added (no blind stemming, no
            synonym expansion -- that is explicitly a later round)
        DF is the number of documents containing ANY form, and a document
        scores the concept at most once, so grouping cannot inflate a hit
        into several."""
        raw = [m.group(0).strip("-&").lower()
               for m in self._TOKEN_RE.finditer(query)]
        concepts, seen = [], set()
        for tok in raw:
            if not is_searchable_token(tok):
                continue
            forms = {tok}
            if "-" in tok:
                forms.update(p for p in tok.split("-") if is_searchable_token(p))
            # vocabulary-gated plural/singular equivalence
            if tok.endswith("s") and tok[:-1] in self._vocab:
                forms.add(tok[:-1])
            if (tok + "s") in self._vocab:
                forms.add(tok + "s")
            forms = frozenset(f for f in forms if f in self._vocab) or frozenset({tok})
            if forms in seen:
                continue
            seen.add(forms)
            doc_freq = sum(1 for e in self.scheme_entries
                           if forms & self._entry_terms(e))
            concepts.append((forms, self._idf(doc_freq)))
        return concepts

    def _entry_terms(self, entry):
        cached = self._entry_term_cache.get(entry["entityId"])
        if cached is None:
            cached = set()
            for tokens, _w in self._searchable_fields(entry):
                cached.update(tokens)
            self._entry_term_cache[entry["entityId"]] = cached
        return cached

    def _keyword_score_idf(self, entry, concepts):
        """Fix #1's field weighting, unchanged -- the only difference from the
        previous implementation is that a matched term contributes its IDF
        instead of a flat 1.0."""
        score = 0.0
        for tokens, weight in self._searchable_fields(entry):
            tokset = set(tokens)
            for forms, idf in concepts:
                if forms & tokset:
                    score += weight * idf
        return score

    def _keyword_score(self, entry, query_tokens):
        prof = entry.get("schemeSearchProfile", {})
        fields_weighted = [
            (entry["tokens"]["en"], 1.0),
            (entry["tokens"]["ta"], 1.0),
            ([t.lower() for t in prof.get("loanType", [])], 0.9),
            ([t.lower() for t in prof.get("subsidyType", [])], 0.9),
            ([t.lower() for t in prof.get("taxBenefits", [])], 0.7),
            ([t.lower() for t in prof.get("clusters", [])], 0.7),
            ([t.lower() for t in prof.get("industryTags", [])], 0.8),
            ([t.lower() for t in prof.get("benefitTags", [])], 0.8),
        ]
        score = 0.0
        for tokens, weight in fields_weighted:
            tokset = set(tokens)
            hits = sum(1 for qt in query_tokens if qt in tokset)
            score += weight * hits
        return score

    def _category_score(self, entry, query_tags):
        prof = entry.get("schemeSearchProfile", {})
        score = 0.0
        if set(query_tags["industries"]) & set(prof.get("industryTags", [])):
            score += 1.0
        if set(query_tags["communities"]) & set(prof.get("communityTags", [])):
            score += 1.0
        score += self._treds_score(entry, query_tags)
        return score

    def _eligibility_score(self, entry, query_tags):
        # tri-state rule: only a POSITIVE match counts. Absence of data
        # (empty eligibilityKeywords) is neutral, never treated as a match.
        prof = entry.get("schemeSearchProfile", {})
        elig = set(k.lower() for k in prof.get("eligibilityKeywords", []))
        if not elig:
            return 0.0  # neutral -- unrecorded, not "matches everything"
        query_terms = set(query_tags["communities"]) | set(query_tags["industries"])
        return 1.0 if elig & query_terms else 0.0

    # collateral.status (finance_catalog.json, structured) -> the matching
    # taxonomy_engine.COLLATERAL concept tag. "required" and "not_specified"
    # have no free-search concept to map to -- they signal absence of a
    # collateral-free/guarantee claim, not presence of one.
    STATUS_TO_CONCEPT = {"not_required": "collateral_free", "guarantee_covered": "guarantee_backed"}

    def _benefit_score(self, entry, query_tags):
        prof = entry.get("schemeSearchProfile", {})
        benefit_tags = set(prof.get("benefitTags", []))
        intent_tags = set(prof.get("userIntentTags", []))
        score = 0.0
        if benefit_tags & set(query_tags["benefits"]):
            score += 1.0
        if intent_tags & set(query_tags["intents"]):
            score += 1.0

        # Collateral concept: EXACT match only, full credit. collateral_free
        # and guarantee_backed are never cross-credited (RELATED_CONCEPTS
        # deliberately leaves both empty) -- a scheme verified only as
        # guarantee_backed does not get boosted for a collateral_free query,
        # because that would be exactly the "collateralRequired=false merely
        # because it's a guarantee scheme" inference the data layer refused
        # to make. The distinction is preserved all the way through scoring.
        entry_collateral_concepts = {self.STATUS_TO_CONCEPT[s] for s in prof.get("collateralStatus", [])
                                       if s in self.STATUS_TO_CONCEPT}
        if entry_collateral_concepts & set(query_tags["collateral"]):
            score += 1.0

        return score

    def _treds_score(self, entry, query_tags):
        """TReDS/receivables-financing concepts. Unlike collateral, these ARE
        allowed partial credit across related-but-distinct concepts
        (treds_platform / invoice_discounting / receivables_financing) --
        see taxonomy_engine.RELATED_CONCEPTS for why that's a legitimate
        taxonomy relationship rather than a merge."""
        prof = entry.get("schemeSearchProfile", {})
        entry_treds = set(prof.get("tredsTags", []))
        query_treds = set(query_tags["treds"])
        if not entry_treds or not query_treds:
            return 0.0
        score = 0.0
        if entry_treds & query_treds:
            score += 1.0
        if entry_treds & expand_related(query_treds):
            score += 0.3   # partial credit for a related-but-not-identical concept
        return score

    # Query concept groups compared against a candidate's own semantic tags.
    # `intents` is excluded on purpose: intent tags (LOAN_REQUEST, …) are a
    # different vocabulary from the catalog's controlled term codes, and
    # intent is already scored by _benefit_score. Including it here would
    # double-count the same evidence.
    _SEMANTIC_QUERY_GROUPS = ("industries", "benefits", "communities",
                              "collateral", "treds")

    def _semantic_score(self, entry, query_tags):
        """QUERY -> CANDIDATE ONLY.

        Fraction of the query's normalised concepts that THIS candidate's own
        controlled-vocabulary semantic tags (ai.semanticTags) cover. No other
        candidate participates in this score in any way.

        Replaces the previous formula, which summed Jaccard similarity between
        the candidate and every OTHER matched candidate
        (ai.relatedEntities). That was candidate->candidate reinforcement: a
        family of near-identical records mutually inflated each other, so a
        trivial match on a common token like "scheme" was amplified into the
        top result (BENCHMARK_V1_FAILURE_ANALYSIS.md, Defect 2 -- a widow
        remarriage scheme ranked #1 for 22 of 210 queries, including
        "khadi scheme").

        Bounded to 0.0..1.0 by construction, so the existing w2 weight (0.6)
        caps the semantic contribution at 0.6 instead of the ~2.7 the summed
        form could reach. No new weight is introduced.
        """
        codes = self._semantic_codes.get(entry["entityId"])
        if not codes:
            return 0.0
        concepts = set()
        for group in self._SEMANTIC_QUERY_GROUPS:
            concepts.update(query_tags.get(group, []))
        if not concepts:
            return 0.0
        return len(concepts & codes) / len(concepts)

    # ---- explainability ---------------------------------------------------

    def _collateral_citation(self, scheme_id, concept):
        """Find the fieldSources[] citation on the linked finance record whose
        collateral concept matches, via the ONE resolver (self.resolver),
        never a fresh graph-walk. Returns None if not found -- no citation is
        invented when the concrete record can't be located."""
        resolved = self.resolver.resolve(scheme_id)
        for f in resolved["finance"]:
            rec = f["record"]["content"]
            collateral = rec.get("collateral") or {}
            if self.STATUS_TO_CONCEPT.get(collateral.get("status")) == concept:
                for fs in f["record"]["provenance"].get("fieldSources", []):
                    if fs["field"] == "content.collateral":
                        return {"organization": fs.get("organization"), "url": fs.get("url"),
                                "retrievedAt": fs.get("retrievedAt"), "sourceId": f["id"]}
        return None

    def _mode_citation(self, scheme_id):
        rec = self.by_id.get(scheme_id)
        if not rec:
            return None
        for fs in rec.get("provenance", {}).get("fieldSources", []):
            if fs["field"] == "content.applicationProcess.mode":
                return {"organization": fs.get("organization"), "url": fs.get("url"),
                        "retrievedAt": fs.get("retrievedAt")}
        return None

    def explain_reasons(self, entry, query_tokens, query_tags, matched_ids,
                        concepts=None):
        """Structured, per-dimension reasons for why a scheme scored the way
        it did -- recomputes the same overlaps the scoring methods use (cheap,
        deterministic, no new logic invented) but keeps the SPECIFIC matched
        values and, where available, a citation from the record's own
        provenance.fieldSources[] rather than a bare boolean."""
        prof = entry.get("schemeSearchProfile", {})
        sid = entry["entityId"]
        reasons = []

        # Keyword reason must mirror what _keyword_score_idf actually scored,
        # including IDF-normalised forms (plural/hyphen variants). Deriving it
        # from the raw query string instead would leave results that scored on
        # a normalised form with no reason at all -- which is exactly what
        # happened when Fix #2 first landed (100 unexplained results).
        if concepts:
            entry_terms = self._entry_terms(entry)
            hits = []
            for forms, idf in concepts:
                matched = forms & entry_terms
                if matched:
                    hits.append((sorted(matched)[0], idf))
            if hits:
                hits.sort(key=lambda x: (-x[1], x[0]))
                detail = ", ".join(f"{t} (idf {idf:.2f})" for t, idf in hits)
                reasons.append({"dimension": "keyword",
                                 "detail": f"matched term(s) by rarity: {detail}",
                                 "citation": None})
        else:
            kw_hits = sorted(set(query_tokens) & set(entry["tokens"]["en"]))
            if kw_hits:
                reasons.append({"dimension": "keyword",
                                 "detail": f"matched keyword(s): {', '.join(kw_hits)}",
                                 "citation": None})

        ind = sorted(set(query_tags["industries"]) & set(prof.get("industryTags", [])))
        if ind:
            reasons.append({"dimension": "category",
                             "detail": f"industry match: {', '.join(ind)}", "citation": None})
        comm = sorted(set(query_tags["communities"]) & set(prof.get("communityTags", [])))
        if comm:
            reasons.append({"dimension": "category",
                             "detail": f"community match: {', '.join(comm)}", "citation": None})

        elig = set(k.lower() for k in prof.get("eligibilityKeywords", []))
        elig_hits = sorted(elig & (set(query_tags["communities"]) | set(query_tags["industries"])))
        if elig_hits:
            reasons.append({"dimension": "eligibility",
                             "detail": f"eligibility facet match: {', '.join(elig_hits)}",
                             "citation": None})

        ben = sorted(set(query_tags["benefits"]) & set(prof.get("benefitTags", [])))
        if ben:
            reasons.append({"dimension": "benefit",
                             "detail": f"benefit type match: {', '.join(ben)}", "citation": None})
        intent = sorted(set(query_tags["intents"]) & set(prof.get("userIntentTags", [])))
        if intent:
            reasons.append({"dimension": "benefit",
                             "detail": f"intent match: {', '.join(intent)}", "citation": None})

        entry_collateral = {self.STATUS_TO_CONCEPT[s] for s in prof.get("collateralStatus", [])
                             if s in self.STATUS_TO_CONCEPT}
        collateral_hit = entry_collateral & set(query_tags["collateral"])
        for concept in sorted(collateral_hit):
            reasons.append({"dimension": "benefit",
                             "detail": f"collateral concept match: {concept}",
                             "citation": self._collateral_citation(sid, concept)})

        # Semantic reason is now QUERY -> CANDIDATE: which of the query's own
        # concepts this candidate's controlled-vocabulary tags cover. The old
        # "similar to already-matched scheme(s)" reason is gone with the bug
        # that produced it -- it explained a score that should never have
        # existed.
        codes = self._semantic_codes.get(sid) or set()
        if codes:
            concepts = set()
            for group in self._SEMANTIC_QUERY_GROUPS:
                concepts.update(query_tags.get(group, []))
            covered = sorted(concepts & codes)
            if covered:
                reasons.append({"dimension": "semantic",
                                 "detail": f"catalog semantic tag(s) match query concept(s): "
                                            f"{', '.join(covered)}",
                                 "citation": None})

        return reasons

    def explain(self, result):
        """Turn one search() result (must include `reasons`, from explain()'s
        caller in search()) into a single plain-language, cited sentence.
        Deterministic: same input always produces the same string (reasons
        are already sorted; this only joins them)."""
        if not result.get("reasons"):
            return f"{result['name']} matched with no specific explainable signal (score {result['score']})."
        parts = [r["detail"] for r in result["reasons"]]
        sentence = f"{result['name']} (score {result['score']}): " + "; ".join(parts) + "."
        cites = [r["citation"] for r in result["reasons"] if r.get("citation")]
        if cites:
            cite_strs = []
            for c in cites:
                label = c.get("organization") or c.get("url")
                if not label:
                    # tier-2 fill (structured from an already-held record's own text,
                    # no external fetch performed) -- say so honestly, never fake a
                    # source name. See enrich_finance_collateral.py's own docstring.
                    cite_strs.append(f"internal record {c.get('sourceId', '')} "
                                      f"(no external source cited; retrieved {c.get('retrievedAt')})")
                else:
                    cite_strs.append(f"{label} (retrieved {c.get('retrievedAt')})")
            sentence += " Source: " + "; ".join(cite_strs) + "."
        return sentence

    def search(self, query, top_n=10):
        query_lower = query.lower()
        query_tokens = set(w.strip(",.") for w in query_lower.split())
        query_tags = taxonomy_normalize(query)

        # Fix #2: term-rarity weighting. Concepts are computed ONCE per query,
        # not per candidate.
        concepts = self._query_concepts(query)

        raw_scores = {}
        for entry in self.scheme_entries:
            kw = self._keyword_score_idf(entry, concepts)
            cat = self._category_score(entry, query_tags)
            elig = self._eligibility_score(entry, query_tags)
            ben = self._benefit_score(entry, query_tags)
            raw_scores[entry["entityId"]] = {
                "keyword": kw, "category": cat, "eligibility": elig, "benefit": ben,
            }

        # Retained ONLY so explain_reasons keeps its existing signature; it no
        # longer feeds any score. Semantic no longer depends on which other
        # candidates matched -- that dependency was the bug.
        matched_ids = {sid for sid, s in raw_scores.items()
                        if s["keyword"] or s["category"] or s["benefit"]}

        results = []
        for entry in self.scheme_entries:
            sid = entry["entityId"]
            s = raw_scores[sid]
            semantic = self._semantic_score(entry, query_tags)
            raw = (WEIGHTS["keyword"] * s["keyword"]
                   + WEIGHTS["semantic"] * semantic
                   + WEIGHTS["category"] * s["category"]
                   + WEIGHTS["eligibility"] * s["eligibility"]
                   + WEIGHTS["benefit"] * s["benefit"]
                   + WEIGHTS["profile"] * 0.0)
            status_factor = STATUS_FACTOR.get(entry.get("status"), 1.0)
            final = raw * status_factor
            if final <= 0:
                continue
            results.append({
                "schemeId": sid, "name": entry["name"]["en"], "score": round(final, 4),
                "components": {**s, "semantic": round(semantic, 4)},
                "status": entry.get("status"), "statusFactor": status_factor,
                "_entry": entry,
            })

        # deterministic sort: score desc, then entityId asc as a total-order tiebreak
        results.sort(key=lambda r: (-r["score"], r["schemeId"]))
        top = results[:top_n]

        # reasons/explanations computed only for the returned top-N -- cheap,
        # and keeps search() itself unchanged in cost for callers who only
        # want scores (explain_reasons/explain are opt-in per result below).
        for r in top:
            r["reasons"] = self.explain_reasons(r.pop("_entry"), query_tokens,
                                                 query_tags, matched_ids, concepts)
            r["explanation"] = self.explain(r)
        for r in results[top_n:]:
            r.pop("_entry", None)

        return {"query": query, "detectedTags": dict(query_tags), "results": top}


if __name__ == "__main__":
    hs = HybridSearch()
    queries = sys.argv[1:] or [
        "women entrepreneur loan", "textile subsidy", "SC entrepreneur scheme",
        "startup funding", "export assistance", "collateral free business loan",
        "GST benefit", "TReDS support", "manufacturing subsidy",
    ]
    for q in queries:
        out = hs.search(q)
        print(f"\nQUERY: {q!r}")
        print(f"  detectedTags: {out['detectedTags']}")
        if not out["results"]:
            print("  (no results)")
        for r in out["results"][:5]:
            print(f"  {r['score']:7.3f}  {r['schemeId']}  {r['name'][:60]}  {r['components']}")
