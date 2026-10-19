// Server-side port of Plan/catalog/hybrid_search.py, mirroring the
// already-validated (210/210 vs Python) Dart port at
// frontend/lib/services/hybrid_scheme_search.dart field-for-field and
// method-for-method. Do not diverge from either without re-validating
// against the Python reference -- this is meant to be the SAME engine in a
// third language, not a fourth independently-tuned one.
//
// Operates over `record_json` columns pulled from Supabase (catalog.scheme,
// catalog.search_index) instead of the Flutter bundle -- the record shapes
// are otherwise identical to what the Dart port reads from
// MssCatalogBundle.schemes / .searchProfiles.

import taxonomyData from "../_shared/search_taxonomy.json" with { type: "json" };

export interface QueryTags {
  industries: string[];
  benefits: string[];
  collateral: string[];
  treds: string[];
  communities: string[];
  intents: string[];
}

// 1.2 (audit_fix.md): every value below is loaded from
// _shared/search_taxonomy.json -- the single source of truth also read by
// hybrid_scheme_search.dart (Dart) and scheme_catalog.py (Python), instead
// of being declared independently in each language. Do not hand-edit these
// values here; edit backend/catalog/search_taxonomy.json (the canonical
// copy) and re-sync all three engines' local copies plus their parity
// tests.
const SHORT_TOKEN_VOCAB = new Set(taxonomyData.shortTokenVocab);

function isSearchableToken(token: string): boolean {
  const t = token.toLowerCase();
  return t.length >= 3 || SHORT_TOKEN_VOCAB.has(t);
}

const TAXONOMY = taxonomyData.taxonomy as {
  industries: Record<string, readonly string[]>;
  benefits: Record<string, readonly string[]>;
  collateral: Record<string, readonly string[]>;
  treds: Record<string, readonly string[]>;
  communities: Record<string, readonly string[]>;
  intents: Record<string, readonly string[]>;
};

// Partial (not full) credit across related-but-distinct concepts.
const RELATED_CONCEPTS: Record<string, string[]> = taxonomyData.relatedConcepts;

function findTags(textLower: string, table: Record<string, readonly string[]>): string[] {
  const hits: string[] = [];
  for (const [key, terms] of Object.entries(table)) {
    for (const term of terms) {
      if (textLower.includes(term)) {
        hits.push(key);
        break;
      }
    }
  }
  return hits;
}

export function taxonomyNormalize(text: string): QueryTags {
  const textLower = ` ${text.toLowerCase().replace(/[^a-z0-9 ]/g, " ")} `;
  return {
    industries: findTags(textLower, TAXONOMY.industries),
    benefits: findTags(textLower, TAXONOMY.benefits),
    collateral: findTags(textLower, TAXONOMY.collateral),
    treds: findTags(textLower, TAXONOMY.treds),
    communities: findTags(textLower, TAXONOMY.communities),
    intents: findTags(textLower, TAXONOMY.intents),
  };
}

export function expandRelated(concepts: Iterable<string>): Set<string> {
  const expanded = new Set<string>();
  for (const c of concepts) {
    for (const r of RELATED_CONCEPTS[c] ?? []) expanded.add(r);
  }
  return expanded;
}

interface Concept {
  forms: Set<string>;
  idf: number;
}

const TOKEN_RE = new RegExp(taxonomyData.tokenRegexSource, "g");

function stripEdges(s: string, chars: string): string {
  let start = 0;
  let end = s.length;
  while (start < end && chars.includes(s[start])) start++;
  while (end > start && chars.includes(s[end - 1])) end--;
  return s.slice(start, end);
}

const STATUS_FACTOR: Record<string, number> = taxonomyData.statusFactor;
const STATUS_TO_CONCEPT: Record<string, string> = taxonomyData.statusToConcept;
const WEIGHTS = taxonomyData.weights;
const SEMANTIC_QUERY_GROUPS = taxonomyData.semanticQueryGroups as (keyof QueryTags)[];

export interface SchemeEntry {
  id: string;
  status: string; // identity.status: active/unknown/closed
  nameEn: string;
  raw: Record<string, unknown>; // full catalog.scheme record_json
  searchProfile: Record<string, unknown>; // full catalog.search_index record_json for this scheme, or {}
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v));
}

function toStringSet(value: unknown): Set<string> {
  return new Set(toStringArray(value));
}

export interface ScoredResult {
  schemeId: string;
  name: string;
  score: number;
  reasons: string[];
}

// ── Query Expansion Dictionary ──────────────────────────────────────────
// 1.2 (audit_fix.md): this used to be a hand-maintained literal that had
// silently drifted from frontend/assets/search/query_expansion.json --
// missing "tax" and "exemption" entries the Dart engine already had, so the
// server ranked tax/exemption queries measurably worse than the offline
// engine with no error, no test failure, nothing. Loaded from the shared
// taxonomy JSON now so the two can never independently drift again;
// hybrid_scheme_search.dart continues to load query_expansion.json
// directly, and a parity test asserts the two stay identical.
const QUERY_EXPANSIONS: Record<string, string[]> = taxonomyData.queryExpansions;

// Pre-split into phrase keys (multi-word) and token keys (single-word)
// at module load time for efficient lookup in queryConcepts().
const PHRASE_EXPANSIONS: Record<string, string[]> = {};
const TOKEN_EXPANSIONS: Record<string, string[]> = {};
for (const [key, value] of Object.entries(QUERY_EXPANSIONS)) {
  if (key.includes(" ")) {
    PHRASE_EXPANSIONS[key] = value;
  } else {
    TOKEN_EXPANSIONS[key] = value;
  }
}

export class HybridSearchEngine {
  private nDocs: number;
  private vocab: Set<string> = new Set();
  private entryTermCache = new Map<string, Set<string>>();
  private semanticCodes = new Map<string, Set<string>>();

  constructor(private entries: SchemeEntry[]) {
    this.nDocs = entries.length;
    for (const entry of entries) {
      const ai = entry.raw["ai"] as Record<string, unknown> | undefined;
      const tags = (ai?.["semanticTags"] as Array<Record<string, unknown>>) ?? [];
      const codes = new Set<string>();
      for (const t of tags) {
        if (typeof t["code"] === "string") codes.add(t["code"] as string);
      }
      this.semanticCodes.set(entry.id, codes);
    }
    this.buildIdf();
  }

  private tokensOf(profile: Record<string, unknown>, path: "en" | "ta"): string[] {
    const tokens = profile["tokens"] as Record<string, unknown> | undefined;
    return toStringArray(tokens?.[path]);
  }

  private searchProfileOf(entry: SchemeEntry): Record<string, unknown> {
    return (entry.searchProfile["schemeSearchProfile"] as Record<string, unknown>) ?? {};
  }

  // Every field the keyword scorer consults, with its field weight. Single
  // source of truth so IDF is computed over exactly the terms that can
  // actually be matched.
  private searchableFields(entry: SchemeEntry): Array<[string[], number]> {
    const sp = this.searchProfileOf(entry);
    const lower = (v: unknown) => toStringArray(v).map((s) => s.toLowerCase());
    return [
      [this.tokensOf(entry.searchProfile, "en"), 1.0],
      [this.tokensOf(entry.searchProfile, "ta"), 1.0],
      [lower(sp["loanType"]), 0.9],
      [lower(sp["subsidyType"]), 0.9],
      [lower(sp["taxBenefits"]), 0.7],
      [lower(sp["clusters"]), 0.7],
      [lower(sp["industryTags"]), 0.8],
      [lower(sp["benefitTags"]), 0.8],
    ];
  }

  private entryTerms(entry: SchemeEntry): Set<string> {
    let cached = this.entryTermCache.get(entry.id);
    if (!cached) {
      cached = new Set<string>();
      for (const [tokens] of this.searchableFields(entry)) {
        for (const t of tokens) cached.add(t);
      }
      this.entryTermCache.set(entry.id, cached);
    }
    return cached;
  }

  private buildIdf() {
    for (const entry of this.entries) {
      for (const [tokens] of this.searchableFields(entry)) {
        for (const t of tokens) this.vocab.add(t);
      }
    }
  }

  private idf(docFreq: number): number {
    return Math.log((this.nDocs + 1) / (docFreq + 1)) + 1;
  }

  private queryConcepts(query: string): Concept[] {
    const raw: string[] = [];
    for (const m of query.matchAll(TOKEN_RE)) {
      raw.push(stripEdges(m[0], "-&").toLowerCase());
    }
    const concepts: Concept[] = [];
    const seen = new Set<string>();

    // ── Phase 1: Multi-word phrase expansion ──────────────────────────
    const queryLower = ` ${query.toLowerCase().replace(/[^a-z0-9 ]/g, " ")} `;
    for (const [phrase, expansionTokens] of Object.entries(PHRASE_EXPANSIONS)) {
      if (!queryLower.includes(` ${phrase} `)) continue;
      const forms = new Set(expansionTokens.filter((f) => this.vocab.has(f)));
      if (forms.size === 0) continue;
      const key = [...forms].sort().join("\x01");
      if (seen.has(key)) continue;
      seen.add(key);
      let docFreq = 0;
      for (const e of this.entries) {
        const terms = this.entryTerms(e);
        for (const f of forms) {
          if (terms.has(f)) {
            docFreq++;
            break;
          }
        }
      }
      concepts.push({ forms, idf: this.idf(docFreq) });
    }

    // ── Phase 2: Per-token concept building (with single-token expansion)
    for (const tok of raw) {
      if (!isSearchableToken(tok)) continue;
      let forms = new Set<string>([tok]);
      if (tok.includes("-")) {
        for (const p of tok.split("-")) {
          if (isSearchableToken(p)) forms.add(p);
        }
      }
      if (tok.endsWith("s") && this.vocab.has(tok.slice(0, -1))) forms.add(tok.slice(0, -1));
      if (this.vocab.has(`${tok}s`)) forms.add(`${tok}s`);

      // ── Single-token expansion ─────────────────────────────────────
      const expansion = TOKEN_EXPANSIONS[tok];
      if (expansion) {
        for (const t of expansion) forms.add(t);
      }

      const gated = new Set([...forms].filter((f) => this.vocab.has(f)));
      forms = gated.size > 0 ? gated : new Set([tok]);

      const key = [...forms].sort().join("\x01");
      if (seen.has(key)) continue;
      seen.add(key);

      let docFreq = 0;
      for (const e of this.entries) {
        const terms = this.entryTerms(e);
        for (const f of forms) {
          if (terms.has(f)) {
            docFreq++;
            break;
          }
        }
      }
      concepts.push({ forms, idf: this.idf(docFreq) });
    }
    return concepts;
  }

  private keywordScoreIdf(entry: SchemeEntry, concepts: Concept[]): number {
    let score = 0;
    for (const [tokens, weight] of this.searchableFields(entry)) {
      const tokset = new Set(tokens);
      for (const concept of concepts) {
        let hit = false;
        for (const f of concept.forms) {
          if (tokset.has(f)) {
            hit = true;
            break;
          }
        }
        if (hit) score += weight * concept.idf;
      }
    }
    return score;
  }

  private tredsScore(entry: SchemeEntry, queryTags: QueryTags): number {
    const sp = this.searchProfileOf(entry);
    const entryTreds = toStringSet(sp["tredsTags"]);
    const queryTreds = new Set(queryTags.treds);
    if (entryTreds.size === 0 || queryTreds.size === 0) return 0.0;
    let score = 0.0;
    if ([...entryTreds].some((t) => queryTreds.has(t))) score += 1.0;
    const related = expandRelated(queryTreds);
    if ([...entryTreds].some((t) => related.has(t))) score += 0.3;
    return score;
  }

  private categoryScore(entry: SchemeEntry, queryTags: QueryTags): number {
    const sp = this.searchProfileOf(entry);
    let score = 0.0;
    const industryTags = toStringSet(sp["industryTags"]);
    if (queryTags.industries.some((t) => industryTags.has(t))) score += 1.0;
    const communityTags = toStringSet(sp["communityTags"]);
    if (queryTags.communities.some((t) => communityTags.has(t))) score += 1.0;
    score += this.tredsScore(entry, queryTags);
    return score;
  }

  private eligibilityScore(entry: SchemeEntry, queryTags: QueryTags): number {
    const sp = this.searchProfileOf(entry);
    const elig = new Set([...toStringSet(sp["eligibilityKeywords"])].map((s) => s.toLowerCase()));
    if (elig.size === 0) return 0.0; // neutral -- unrecorded, not "matches all"
    const queryTerms = new Set([...queryTags.communities, ...queryTags.industries]);
    return [...elig].some((e) => queryTerms.has(e)) ? 1.0 : 0.0;
  }

  private benefitScore(entry: SchemeEntry, queryTags: QueryTags): number {
    const sp = this.searchProfileOf(entry);
    const benefitTags = toStringSet(sp["benefitTags"]);
    const intentTags = toStringSet(sp["userIntentTags"]);
    let score = 0.0;
    if (queryTags.benefits.some((t) => benefitTags.has(t))) score += 1.0;
    if (queryTags.intents.some((t) => intentTags.has(t))) score += 1.0;
    const collateralStatus = toStringArray(sp["collateralStatus"]);
    const entryCollateralConcepts = new Set(
      collateralStatus.map((s) => STATUS_TO_CONCEPT[s]).filter((c): c is string => Boolean(c))
    );
    if (queryTags.collateral.some((t) => entryCollateralConcepts.has(t))) score += 1.0;
    return score;
  }

  private semanticScore(entry: SchemeEntry, queryTags: QueryTags): number {
    const codes = this.semanticCodes.get(entry.id);
    if (!codes || codes.size === 0) return 0.0;
    const concepts = new Set<string>();
    for (const group of SEMANTIC_QUERY_GROUPS) {
      for (const t of queryTags[group]) concepts.add(t);
    }
    if (concepts.size === 0) return 0.0;
    let covered = 0;
    for (const c of concepts) if (codes.has(c)) covered++;
    return covered / concepts.size;
  }

  private explainReasons(entry: SchemeEntry, queryTags: QueryTags, concepts: Concept[]): string[] {
    const reasons: string[] = [];
    const entryTerms = this.entryTerms(entry);
    const hits: Array<[string, number]> = [];
    for (const concept of concepts) {
      const matched = [...concept.forms].filter((f) => entryTerms.has(f)).sort();
      if (matched.length > 0) hits.push([matched[0], concept.idf]);
    }
    if (hits.length > 0) {
      hits.sort((a, b) => (b[1] !== a[1] ? b[1] - a[1] : a[0].localeCompare(b[0])));
      reasons.push(`Matches: ${hits.map((h) => h[0]).join(", ")}`);
    }

    const sp = this.searchProfileOf(entry);
    const ind = queryTags.industries.filter((t) => toStringSet(sp["industryTags"]).has(t));
    if (ind.length > 0) reasons.push(`Industry match: ${ind.join(", ")}`);

    const comm = queryTags.communities.filter((t) => toStringSet(sp["communityTags"]).has(t));
    if (comm.length > 0) reasons.push(`Community match: ${comm.join(", ")}`);

    const elig = new Set([...toStringSet(sp["eligibilityKeywords"])].map((s) => s.toLowerCase()));
    const eligHits = [...new Set([...queryTags.communities, ...queryTags.industries])].filter((t) => elig.has(t));
    if (eligHits.length > 0) reasons.push(`Eligibility match: ${eligHits.join(", ")}`);

    const ben = queryTags.benefits.filter((t) => toStringSet(sp["benefitTags"]).has(t));
    if (ben.length > 0) reasons.push(`Benefit match: ${ben.join(", ")}`);

    const intent = queryTags.intents.filter((t) => toStringSet(sp["userIntentTags"]).has(t));
    if (intent.length > 0) reasons.push(`Intent match: ${intent.join(", ")}`);

    const collateralStatus = toStringArray(sp["collateralStatus"]);
    const entryCollateral = new Set(collateralStatus.map((s) => STATUS_TO_CONCEPT[s]).filter((c): c is string => Boolean(c)));
    const collateralHit = queryTags.collateral.filter((t) => entryCollateral.has(t));
    if (collateralHit.length > 0) reasons.push(`Collateral match: ${collateralHit.join(", ")}`);

    const codes = this.semanticCodes.get(entry.id) ?? new Set<string>();
    if (codes.size > 0) {
      const semanticConcepts = new Set<string>();
      for (const group of SEMANTIC_QUERY_GROUPS) for (const t of queryTags[group]) semanticConcepts.add(t);
      const covered = [...semanticConcepts].filter((c) => codes.has(c));
      if (covered.length > 0) reasons.push(`Semantic match: ${covered.join(", ")}`);
    }

    return reasons;
  }

  private scoreEntry(entry: SchemeEntry, queryTags: QueryTags, concepts: Concept[]): number {
    const kw = this.keywordScoreIdf(entry, concepts);
    const cat = this.categoryScore(entry, queryTags);
    const elig = this.eligibilityScore(entry, queryTags);
    const ben = this.benefitScore(entry, queryTags);
    const semantic = this.semanticScore(entry, queryTags);
    const raw =
      WEIGHTS.keyword * kw + WEIGHTS.semantic * semantic + WEIGHTS.category * cat + WEIGHTS.eligibility * elig + WEIGHTS.benefit * ben;
    const statusFactor = STATUS_FACTOR[entry.status] ?? 1.0;
    const finalScore = raw * statusFactor;
    return Math.round(finalScore * 10000) / 10000;
  }

  /** Deterministic: score desc, then schemeId asc as a total-order tiebreak (matches hybrid_search.py / hybrid_scheme_search.dart). */
  search(query: string, topN?: number): ScoredResult[] {
    const queryTags = taxonomyNormalize(query);
    const concepts = this.queryConcepts(query);

    const scored: ScoredResult[] = [];
    for (const entry of this.entries) {
      const score = this.scoreEntry(entry, queryTags, concepts);
      if (score <= 0) continue;
      scored.push({ schemeId: entry.id, name: entry.nameEn, score, reasons: [] });
    }

    scored.sort((a, b) => (b.score !== a.score ? b.score - a.score : a.schemeId.localeCompare(b.schemeId)));
    const limited = topN != null ? scored.slice(0, topN) : scored;

    const byId = new Map(this.entries.map((e) => [e.id, e]));
    for (const r of limited) {
      const entry = byId.get(r.schemeId)!;
      r.reasons = this.explainReasons(entry, queryTags, concepts);
    }
    return limited;
  }
}
