#!/usr/bin/env python3
"""
MSS Taxonomy Engine — Phase 1, Step 5.

A controlled vocabulary + a deterministic normalizer. Purpose: turn free-form
user language ("cloth business loan") into a fixed set of tags (industry,
benefit, intent) that the rest of the search pipeline can filter/score on.

Deliberately NOT an LLM call — SEARCH_ENGINE_IMPROVEMENT_PLAN.md requires
query-time intent detection to be deterministic, so this is a keyword/pattern
matcher over a versioned table, reviewable and testable on its own.
"""
import re
from collections import OrderedDict

# ---- Controlled short-token vocabulary (Round 3) ------------------------------
# The tokenizer floor is >=3 characters, which silently destroyed legitimate MSS
# domain terms before ranking ever saw them. This allowlist is the ONLY way a
# <3-character token becomes searchable -- the floor is not lowered globally,
# so arbitrary two-character noise ("to", "is", "of", "by", "an") stays out.
#
# DERIVED, not invented. Re-derive by scanning these controlled sources for
# alphanumeric values of length <= 2:
#     taxonomy_engine INDUSTRIES/BENEFITS/COLLATERAL/TREDS/COMMUNITIES/INTENTS
#     scheme_catalog  content.eligibility.structured.{gender,community,specialCategory}.values
#     scheme_catalog  ai.semanticTags[].code
#     scheme_catalog  content.classification.government.states[]  (ISO 3166-2 suffix)
#     common_catalog  content.code / content.aliases
#
# ACCEPTED -- each is domain-meaningful AND not a common English function word:
SHORT_TOKEN_VOCAB = {
    "sc",   # Scheduled Caste. Sources: taxonomy COMMUNITIES, eligibility
            # .specialCategory (7 schemes), common_catalog code.
    "st",   # Scheduled Tribe. Same three sources (7 schemes).
    "tn",   # Tamil Nadu. Source: government.states ISO code "IN-TN" (36 schemes);
            # the catalog is TN-centric so this is a real retrieval axis.
}
#
# REJECTED, with reasons (documented so they are not silently re-added):
#   "go"  -- derived from common_catalog glossary "Government Order (G.O.)", but
#            collides with the high-frequency English verb "go" and users do not
#            search by document type. Noise cost far exceeds retrieval value.
#   "it"  -- ZERO occurrences as a domain term in scheme names or sectorsText;
#            collides with the English pronoun. Not MSS vocabulary in this corpus.
#   "ai"  -- ZERO occurrences in scheme names or sectorsText.
#   "ites"-- ZERO occurrences. (Offered as examples in the brief; the corpus
#            does not support them. Measured, not assumed.)
#
# Short tokens are ordinary terms once admitted: they take the same IDF formula,
# the same field weights, the same concept grouping and the same explanation
# path. Nothing here grants a boost for being short.


def is_searchable_token(token):
    """True if `token` survives tokenization: normal length, or an explicitly
    allowed domain short token. Single source of truth shared by the index
    builder and the query tokenizer so the two can never drift apart."""
    t = token.lower()
    return len(t) >= 3 or t in SHORT_TOKEN_VOCAB


# ---- Industries -------------------------------------------------------------
INDUSTRIES = OrderedDict([
    ("textile", ["textile", "cloth", "garment", "weaving", "power loom", "handloom",
                 "apparel", "fabric", "yarn", "spinning"]),
    ("auto", ["auto", "automobile", "automotive", "vehicle", "auto component", "auto parts"]),
    ("leather", ["leather", "tannery", "footwear", "tanning"]),
    ("printing", ["printing", "press", "publication", "packaging print"]),
    ("manufacturing", ["manufacturing", "manufacture", "factory", "production", "plant and machinery"]),
    ("service", ["service", "services sector", "service enterprise"]),
    # Phase E.2: corpus-checked before adding, same discipline as Round 3's
    # sc/st/tn additions. Only 1/217 schemes (SCH000065, food safety/quality
    # assurance) mentions food processing in any form -- added anyway because
    # it is a real, distinct industry a real user searches for, and because a
    # single-document term is exactly what IDF (Fix #2) already handles
    # correctly (a rare term scores higher, not lower). Not expected to move
    # aggregate benchmark metrics much given N=1 -- see
    # MSS_USER_SEARCH_QUALITY_REPORT.md for the isolated before/after.
    ("food_processing", ["food processing", "food product", "food products", "agro processing",
                          "agro-based", "agro based", "food industry", "food safety"]),
])

# ---- Benefits -----------------------------------------------------------------
BENEFITS = OrderedDict([
    ("loan", ["loan", "business loan", "msme loan", "term loan", "capital loan",
              "working capital", "credit", "borrow", "financing", "finance", "funding"]),
    ("subsidy", ["subsidy", "subsidies", "subsidised", "subsidized"]),
    ("grant", ["grant", "grant-in-aid"]),
    # Bare "guarantee" only -- the nuanced collateral/guarantee phrases live in
    # COLLATERAL below as their own distinct concepts, not duplicated here.
    ("guarantee", ["guarantee"]),
    ("training", ["training", "skill development", "capacity building", "workshop"]),
    ("export_support", ["export", "export incentive", "export assistance", "duty exemption"]),
])

# ---- Collateral concepts --------------------------------------------------------
# Two DISTINCT concepts, deliberately not merged: a lender waiving security
# ("collateral_free") is not the same fact as a third party covering default
# risk ("guarantee_backed") -- see enrich_finance_collateral.py's docstring
# for the full reasoning. A query matching one must not be silently treated
# as matching the other; scoring applies partial, not full, credit across them.
COLLATERAL = OrderedDict([
    ("collateral_free", ["collateral free", "collateral-free", "without collateral",
                          "no collateral", "security free", "security-free",
                          "no security required"]),
    ("guarantee_backed", ["credit guarantee", "guarantee backed", "guarantee-backed",
                           "backed by guarantee", "cgtmse", "cgss", "credit guarantee fund"]),
])

# ---- TReDS / receivables-financing concepts --------------------------------------
# Three related but DISTINCT concepts: TReDS is a specific RBI-regulated
# platform mechanism; "invoice discounting" and "receivables financing" are
# the broader financial concepts TReDS implements. A scheme can be about
# receivables financing without being on a TReDS platform (e.g. a direct
# bank invoice-discounting product) -- so these are not collapsed into one
# tag, but ARE marked related for scoring purposes (see RELATED_CONCEPTS).
TREDS = OrderedDict([
    ("treds_platform", ["treds", "trade receivables discounting system", "rxil",
                         "m1xchange", "m1 xchange", "invoicemart", "invoice mart",
                         "receivables exchange of india"]),
    ("invoice_discounting", ["invoice discounting", "invoice financing", "bill discounting"]),
    ("receivables_financing", ["receivables financing", "receivable financing",
                                "msme receivables"]),
])

# Concepts that partially reinforce each other without being identical.
# Used by hybrid_search.py to give partial (not full) credit across related-
# but-distinct concepts, per the explicit "do not treat as automatically
# identical" instruction.
RELATED_CONCEPTS = {
    "treds_platform": ["invoice_discounting", "receivables_financing"],
    "invoice_discounting": ["treds_platform", "receivables_financing"],
    "receivables_financing": ["treds_platform", "invoice_discounting"],
    "collateral_free": [],       # deliberately NOT auto-related to guarantee_backed
    "guarantee_backed": [],      # -- see COLLATERAL comment above
}

# ---- Special categories / communities ------------------------------------------
# Vocabulary matched to values actually observed in scheme_catalog.json's
# eligibility.structured.specialCategory/gender facets (see intelligence_resolver
# validation run) -- not invented, aligned to what the catalog already asserts.
COMMUNITIES = OrderedDict([
    ("women", ["women", "woman", "female", "mahila"]),
    ("sc", ["sc entrepreneur", "scheduled caste", " sc "]),
    ("st", ["st entrepreneur", "scheduled tribe", " st "]),
    ("differently_abled", ["differently abled", "disability", "disabled", "pwd"]),
    ("transgender", ["transgender"]),
    ("minority", ["minority"]),
    ("ex_servicemen", ["ex-servicemen", "ex servicemen", "veteran"]),
])

# ---- User intents -------------------------------------------------------------
# Matches SEARCH_ENGINE_IMPROVEMENT_PLAN.md's enum exactly -- do not diverge.
INTENTS = OrderedDict([
    ("LOAN_REQUEST", ["loan", "borrow", "credit", "money to start", "money for", "funding", "finance my"]),
    ("SUBSIDY_REQUEST", ["subsidy", "subsidised", "subsidized"]),
    ("GRANT_REQUEST", ["grant"]),
    ("TRAINING_REQUEST", ["training", "skill development", "workshop", "capacity building"]),
    ("REGISTRATION_REQUEST", ["register", "registration", "udyam", "how to register"]),
    ("EXPORT_REQUEST", ["export", "iec", "dgft"]),
    ("TAX_REQUEST", ["gst", "tax", "income tax", "exemption"]),
    ("WOMEN_SUPPORT", ["women", "female", "mahila", "woman entrepreneur"]),
    ("STARTUP_SUPPORT", ["startup", "start up", "new business", "start a business", "start my"]),
    ("CLUSTER_SUPPORT", ["cluster", "common facility centre", "common facility center"]),
])


def _find(text_lower, table):
    hits = []
    for tag, terms in table.items():
        for t in terms:
            if t in text_lower:
                hits.append(tag)
                break
    return hits


def normalize(text):
    """Deterministic: same text always returns the same tags in the same
    order (table-declaration order, not match order), so results are stable
    regardless of input phrasing variance.

    Returns {"industries": [...], "benefits": [...], "intents": [...]}."""
    text_lower = " " + re.sub(r"[^a-z0-9 ]", " ", text.lower()) + " "
    return OrderedDict([
        ("industries", _find(text_lower, INDUSTRIES)),
        ("benefits", _find(text_lower, BENEFITS)),
        ("collateral", _find(text_lower, COLLATERAL)),
        ("treds", _find(text_lower, TREDS)),
        ("communities", _find(text_lower, COMMUNITIES)),
        ("intents", _find(text_lower, INTENTS)),
    ])


def expand_related(concepts):
    """Given a list of matched concept tags (from COLLATERAL or TREDS),
    return the set of tags that partially reinforce them per
    RELATED_CONCEPTS -- used for partial-credit scoring, never full-credit
    merging. Does not mutate `concepts`."""
    expanded = set()
    for c in concepts:
        expanded.update(RELATED_CONCEPTS.get(c, []))
    return expanded


if __name__ == "__main__":
    tests = [
        "user wants cloth business loan",
        "I need money to start textile business",
        "women entrepreneur loan",
        "textile subsidy",
        "SC entrepreneur scheme",
        "startup funding",
        "export assistance",
        "collateral free business loan",
        "GST benefit",
    ]
    for t in tests:
        print(f"{t!r:45} -> {dict(normalize(t))}")
