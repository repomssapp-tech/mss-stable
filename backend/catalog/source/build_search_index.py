#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase 2 priority 8 — search_index.json.

Parent spec §4 calls this "lightweight search data": entity IDs, keywords,
synonyms, aliases, cross references, search ranking, catalog references.

It is an INDEX, not an entity catalog. It carries no BaseEntity records and no
`content` block, so the base validator (which scans *_catalog.json) correctly
does not apply to it. It still uses the mandated {metadata, data} envelope.

Rules:
  S1  built ENTIRELY from the generated catalogs. No source document is re-read,
      so the index can never disagree with the catalogs.
  S2  every entry points back by id; no content is duplicated beyond the display
      name and the tokens needed to find it.
  S3  searchRank stays null. No ranking specification exists, and inventing a
      weighting would be an unstated editorial judgement. Instead each entry
      carries explainable `signals` a client may rank on.
  S4  Tamil tokens are included where the catalogs already hold them; nothing is
      translated here.
  S5  no inverted map is written to disk. 969 entries build one in O(n) at load,
      and a second on-disk structure would be a second thing to keep in sync.
"""
import json, os, re, hashlib, sys
from collections import OrderedDict, Counter

CAT = os.path.dirname(os.path.abspath(__file__))
from datetime import datetime, timezone
AT = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
SV = "1.0.0"

sys.path.insert(0, CAT)
from intelligence_resolver import IntelligenceResolver
from taxonomy_engine import normalize as taxonomy_normalize, is_searchable_token

CATALOGS = ["common_catalog.json", "authority_catalog.json", "institution_catalog.json",
            "scheme_catalog.json", "finance_catalog.json", "tax_catalog.json",
            "treds_catalog.json", "csr_catalog.json", "export_catalog.json",
            "knowledge_catalog.json"]
# NOT indexed: applicability_matrix_catalog.json -- it's a derived filter index with
# no display content of its own (MSME_GRAPH_SCHEMA.md §3), not a searchable entity.

STOP = {"the", "and", "for", "with", "that", "this", "from", "under", "their", "which",
        "shall", "have", "been", "are", "was", "will", "can", "may", "not", "any", "all"}

def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

def as_list(v, key):
    """search.keywords/aliases may be a plain list (older shape) or {en, ta}."""
    if isinstance(v, dict): return v.get(key) or []
    return v or [] if key == "en" else []

def content_text_blob(content):
    """Pull free-text description fields that exist directly on `content` for
    several catalogs (treds/csr/tax's 'summary', finance's 'description') but
    were never fed into tokenise() -- root cause of TReDS search returning
    poor results despite the records actually holding substantive text (see
    SEARCH_ENGINE_VALIDATION_REPORT.md, TReDS issue investigation: the
    catalog was never as empty as the first read suggested; the indexer was
    just not reading `summary`). Scheme records are deliberately excluded --
    their `content.overview.summary` is already surfaced via `search.keywords`
    at authoring time, and folding in the full overview text here would
    change 217 records' token sets as an unplanned side effect of a TReDS-
    scoped fix."""
    if not isinstance(content, dict):
        return ""
    parts = [content.get("summary"), content.get("description")]
    return " ".join(p for p in parts if isinstance(p, str))


def tokenise(*parts):
    toks = set()
    for p in parts:
        if not p: continue
        # Round 3: the {1,} quantifier admits 2-char candidates so the
        # controlled short-token vocabulary can be applied. The >=3 floor is
        # NOT lowered globally -- is_searchable_token() gates every short
        # token against the documented allowlist in taxonomy_engine.
        for w in re.findall(r"[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}", str(p)):
            w = w.strip("-&").lower()
            if is_searchable_token(w) and w not in STOP:
                toks.add(w)
            # NOTE: index-side hyphen decomposition ("sc-st" -> sc, st) was
            # implemented and then REVERTED in Round 3. It added ~240 token
            # variants corpus-wide to gain exactly ONE scheme carrying a bare
            # "sc" token -- a broad, ranking-shifting change bundled into a
            # round meant to isolate the short-token variable. It is a
            # legitimate improvement, but it belongs in its own measured
            # round. See SEARCH_OPT_ROUND3_SHORT_TOKEN_REPORT.md §Remaining.
    return sorted(toks)

def build_scheme_search_profile(resolver, scheme_rec):
    """Phase 1, Step 4 — Scheme Search Intelligence Profile.

    Derived entirely from the scheme's own fields plus a resolver walk over
    already-declared edges (finance/tax) and the applicability_matrix 1:1
    lookup. Nothing here is a new fact -- every value traces to an existing
    field on an existing record. Regenerable: re-running this on an
    unchanged catalog set produces an identical result."""
    idn, c = scheme_rec["identity"], scheme_rec["content"]
    resolved = resolver.resolve(idn["id"])

    financial_benefits = list(c["benefits"]["benefitTypes"])
    loan_type, subsidy_type = [], []
    collateral_statuses, guarantee_schemes = [], []
    for f in resolved["finance"]:
        rec = f["record"]["content"]
        product = rec.get("productFamilyText") or rec.get("productType")
        if product:
            if rec.get("isRepayable"):
                loan_type.append(product)
            else:
                subsidy_type.append(product)
        # Collateral status kept as its own field, distinct from loan/subsidy
        # type -- "collateral-free" and "guarantee-covered" are different
        # concepts (see enrich_finance_collateral.py) and must not merge.
        collateral = rec.get("collateral")
        if collateral and collateral.get("status") != "not_specified":
            collateral_statuses.append(collateral["status"])
            if collateral.get("guaranteeSchemeText"):
                guarantee_schemes.append(collateral["guaranteeSchemeText"])

    tax_benefits = []
    for t in resolved["tax"]:
        rec = t["record"]["content"]
        tax_benefits.extend(rec.get("matchTerms") or [])

    am = resolved["applicability"]
    am_content = am["content"] if am else {}

    beneficiary_text = c["targetBeneficiaries"]["description"] or ""
    summary_text = c["overview"]["summary"] or ""
    # Include the scheme's own benefits.summary in taxonomy tagging too, not
    # just overview.summary. Real gap found and fixed here: SCH000166
    # (Special Capital Subsidy for Thrust Sector Enterprises) lists its 24
    # eligible sectors -- including "technical textiles" and "readymade
    # garments" -- only in content.benefits.summary; overview.summary never
    # mentions them. A sector-specific query like "textile subsidy" could
    # not detect this scheme's relevance at all because that text was never
    # read into industryTags. Same "index across catalogs/fields" principle
    # already applied to finance_text below.
    benefits_summary_text = c.get("benefits", {}).get("summary") or ""
    # Include resolved finance-product text in taxonomy tagging, not just the
    # scheme's own summary. Real gap found and fixed here: PM Vishwakarma
    # (SCH000124) states "collateral-free enterprise-development credit" only
    # on its FINANCE record (FIN000075), never in its own overview.summary
    # ("Integrated support programme for traditional artisans...") -- so
    # tagging from scheme text alone missed a loan/collateral-free scheme
    # entirely. This mirrors the same "index across catalogs" principle
    # already applied to search_index.json's tokens.
    finance_text = " ".join(
        f["record"]["content"].get("description") or "" for f in resolved["finance"]
    )
    combined_text = " ".join([idn["name"], beneficiary_text, summary_text,
                               benefits_summary_text, finance_text])
    tags = taxonomy_normalize(combined_text)

    eligibility_keywords = []
    struct = c["eligibility"]["structured"]
    for facet in ("enterprise", "businessStage", "specialCategory", "gender"):
        f = struct.get(facet, {})
        if f.get("applies") is True:
            eligibility_keywords.extend(f.get("values") or f.get("types") or [])

    return OrderedDict([
        ("schemeId", idn["id"]),
        ("name", idn["name"]),
        ("aliases", [idn.get("code")] if idn.get("code") else []),
        ("keywords", (scheme_rec.get("search", {}).get("keywords") or {}).get("en", [])),
        ("sector", c["classification"].get("sectorsText")),
        ("beneficiary", beneficiary_text or None),
        ("financialBenefits", sorted(set(financial_benefits))),
        ("loanType", sorted(set(loan_type))),
        ("subsidyType", sorted(set(subsidy_type))),
        ("taxBenefits", sorted(set(tax_benefits))),
        ("clusters", []),   # [] until cluster_assistance_catalog.json + supports_cluster edges exist
        ("districts", am_content.get("districtText") and [am_content["districtText"]] or []),
        ("enterpriseType", am_content.get("enterpriseType", [])),
        ("userIntentTags", tags["intents"]),
        ("industryTags", tags["industries"]),
        ("benefitTags", tags["benefits"]),
        ("communityTags", tags["communities"]),
        # Collateral concept is structured (from finance_catalog.json's
        # content.collateral, added by enrich_finance_collateral.py), not
        # text-matched -- more reliable than pattern matching the scheme's
        # own prose, and keeps "collateral_free" and "guarantee_backed"
        # correctly distinct per taxonomy_engine.py's COLLATERAL table.
        ("collateralStatus", sorted(set(collateral_statuses))),
        ("guaranteeSchemes", sorted(set(guarantee_schemes))),
        ("tredsTags", tags["treds"]),   # [] on every scheme today -- see REMAINING_DATA_COVERAGE_GAPS.md
        ("eligibilityKeywords", sorted(set(eligibility_keywords))),
        ("financialKeywords", sorted(set(loan_type) | set(subsidy_type) | set(financial_benefits))),
    ])


def main():
    resolver = IntelligenceResolver()
    scheme_by_id = {r["identity"]["id"]: r for r in (resolver.catalogs.get("scheme") or {"data": []})["data"]}

    entries, per_catalog, missing = [], Counter(), Counter()
    for fname in CATALOGS:
        path = os.path.join(CAT, fname)
        if not os.path.exists(path):
            missing[fname] += 1
            continue
        cat = load(fname)
        for r in cat["data"]:
            idn, s = r["identity"], r.get("search", {})
            kw_en = as_list(s.get("keywords"), "en")
            kw_ta = as_list(s.get("keywords"), "ta")
            al_en = as_list(s.get("aliases"), "en")
            al_ta = as_list(s.get("aliases"), "ta")
            refs = r.get("relationships", {}).get("references", [])
            loc_ta = (r.get("localization", {}).get("ta") or {})
            ta_name = loc_ta.get("name") or loc_ta.get("label") or loc_ta.get("title")

            entries.append(OrderedDict([
                ("entityId", idn["id"]),
                ("entityType", idn["entityType"]),
                ("catalog", fname),
                ("name", OrderedDict([("en", idn["name"]), ("ta", ta_name)])),
                ("code", idn.get("code")),
                ("acronym", idn.get("acronym")),
                ("slug", idn.get("slug")),
                ("status", idn.get("status")),
                ("keywords", OrderedDict([("en", kw_en), ("ta", kw_ta)])),
                ("aliases", OrderedDict([("en", al_en), ("ta", al_ta)])),
                ("synonyms", s.get("synonyms") or []),
                ("tokens", OrderedDict([
                    ("en", tokenise(idn["name"], idn.get("acronym"), idn.get("code"),
                                    " ".join(kw_en), " ".join(al_en),
                                    content_text_blob(r.get("content"))
                                    if idn["entityType"] != "scheme" else None)),
                    ("ta", tokenise(ta_name, " ".join(kw_ta), " ".join(al_ta)))])),
                ("crossReferences", [OrderedDict([("entityId", x["entityId"]),
                                                  ("entityType", x["entityType"]),
                                                  ("relationType", x["relationType"])])
                                     for x in refs]),
                # S3 — explainable signals, no invented weighting
                ("signals", OrderedDict([
                    ("referenceCount", len(refs)),
                    ("verificationStatus", r.get("verification", {}).get("status")),
                    ("isVerified", r.get("verification", {}).get("isVerified")),
                    ("missingFieldCount", len(r.get("verification", {}).get("missingFields", []))),
                    ("hasTamil", bool(ta_name)),
                ])),
                ("searchRank", None),
            ]))
            if idn["entityType"] == "scheme":
                entries[-1]["schemeSearchProfile"] = build_scheme_search_profile(resolver, r)
            per_catalog[fname] += 1

    def sortkey(e): return (e["catalog"], e["entityId"])
    entries.sort(key=sortkey)

    # Derived from the live scheme_catalog.json version rather than hardcoded --
    # a hardcoded release tag here previously went stale across phases (same
    # class of bug fixed in stage_b.py's apply step for the same reason).
    scheme_meta = (resolver.catalogs.get("scheme") or {}).get("metadata", {})
    rel = scheme_meta.get("catalogVersion", "unknown") + "+searchprofile"

    idx = OrderedDict([
        ("metadata", OrderedDict([("catalogName", "search_index"), ("schemaVersion", SV),
                                  ("catalogVersion", rel), ("generatedAt", AT),
                                  ("language", "en"), ("recordCount", len(entries)),
                                  ("checksum", "sha256:" + hashlib.sha256(canon(entries).encode()).hexdigest())])),
        ("data", entries)])
    json.dump(idx, open(os.path.join(CAT, "search_index.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)

    # ---- integrity: every indexed id must exist, every cross-ref must resolve
    known = set()
    for f in CATALOGS:
        p = os.path.join(CAT, f)
        if os.path.exists(p):
            known |= {r["identity"]["id"] for r in load(f)["data"]}
    bad_id = [e["entityId"] for e in entries if e["entityId"] not in known]
    bad_ref = [(e["entityId"], x["entityId"]) for e in entries
               for x in e["crossReferences"] if x["entityId"] not in known]
    dupes = [k for k, v in Counter(e["entityId"] for e in entries).items() if v > 1]

    tok_en = Counter(t for e in entries for t in e["tokens"]["en"])
    tok_ta = Counter(t for e in entries for t in e["tokens"]["ta"])

    stats = OrderedDict([
        ("generatedAt", AT), ("catalog", "search_index.json"),
        ("indexedEntities", len(entries)),
        ("catalogsIndexed", len(per_catalog)),
        ("perCatalog", dict(per_catalog)),
        ("catalogsMissing", dict(missing)),
        ("distinctTokensEn", len(tok_en)), ("distinctTokensTa", len(tok_ta)),
        ("totalTokenPostingsEn", sum(tok_en.values())),
        ("totalTokenPostingsTa", sum(tok_ta.values())),
        ("entriesWithTamilName", sum(1 for e in entries if e["name"]["ta"])),
        ("entriesWithTamilTokens", sum(1 for e in entries if e["tokens"]["ta"])),
        ("crossReferences", sum(len(e["crossReferences"]) for e in entries)),
        ("duplicateEntityIds", len(dupes)),
        ("unknownEntityIds", len(bad_id)),
        ("unresolvedCrossReferences", len(bad_ref)),
        ("searchRankPopulated", 0),
        ("rankingNote", "searchRank intentionally null — no ranking specification exists. "
                        "Clients may rank on `signals`."),
        ("invertedIndexOnDisk", False),
        ("invertedIndexNote", "Built by the client in O(n) from `tokens`; a second on-disk "
                              "structure would need separate synchronisation."),
        ("topTokensEn", tok_en.most_common(12)),
    ])
    json.dump(stats, open(os.path.join(CAT, "search_index_statistics.json"), "w",
                          encoding="utf-8"), indent=2, ensure_ascii=False)
    for k, v in stats.items():
        if k != "topTokensEn": print(f"   {k:28} {v}")
    print("   topTokensEn                 ", [t for t, _ in stats["topTokensEn"]])
    if bad_id or bad_ref or dupes:
        print("   INTEGRITY FAILURE"); raise SystemExit(1)

if __name__ == "__main__":
    main()
