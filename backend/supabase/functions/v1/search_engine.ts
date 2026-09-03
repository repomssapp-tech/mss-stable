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

export interface QueryTags {
  industries: string[];
  benefits: string[];
  collateral: string[];
  treds: string[];
  communities: string[];
  intents: string[];
}

const SHORT_TOKEN_VOCAB = new Set(["sc", "st", "tn"]);

function isSearchableToken(token: string): boolean {
  const t = token.toLowerCase();
  return t.length >= 3 || SHORT_TOKEN_VOCAB.has(t);
}

const TAXONOMY = {
  industries: {
    textile: ["textile", "cloth", "garment", "weaving", "power loom", "handloom", "apparel", "fabric", "yarn", "spinning"],
    auto: ["auto", "automobile", "automotive", "vehicle", "auto component", "auto parts"],
    leather: ["leather", "tannery", "footwear", "tanning"],
    printing: ["printing", "press", "publication", "packaging print"],
    manufacturing: ["manufacturing", "manufacture", "factory", "production", "plant and machinery"],
    service: ["service", "services sector", "service enterprise"],
    food_processing: ["food processing", "food product", "food products", "agro processing", "agro-based", "agro based", "food industry", "food safety"],
  },
  benefits: {
    loan: ["loan", "business loan", "msme loan", "term loan", "capital loan", "working capital", "credit", "borrow", "financing", "finance", "funding"],
    subsidy: ["subsidy", "subsidies", "subsidised", "subsidized"],
    grant: ["grant", "grant-in-aid"],
    guarantee: ["guarantee"],
    training: ["training", "skill development", "capacity building", "workshop"],
    export_support: ["export", "export incentive", "export assistance", "duty exemption"],
  },
  collateral: {
    collateral_free: ["collateral free", "collateral-free", "without collateral", "no collateral", "security free", "security-free", "no security required"],
    guarantee_backed: ["credit guarantee", "guarantee backed", "guarantee-backed", "backed by guarantee", "cgtmse", "cgss", "credit guarantee fund"],
  },
  treds: {
    treds_platform: ["treds", "trade receivables discounting system", "rxil", "m1xchange", "m1 xchange", "invoicemart", "invoice mart", "receivables exchange of india"],
    invoice_discounting: ["invoice discounting", "invoice financing", "bill discounting"],
    receivables_financing: ["receivables financing", "receivable financing", "msme receivables"],
  },
  communities: {
    women: ["women", "woman", "female", "mahila"],
    sc: ["sc entrepreneur", "scheduled caste", " sc "],
    st: ["st entrepreneur", "scheduled tribe", " st "],
    differently_abled: ["differently abled", "disability", "disabled", "pwd"],
    transgender: ["transgender"],
    minority: ["minority"],
    ex_servicemen: ["ex-servicemen", "ex servicemen", "veteran"],
  },
  intents: {
    LOAN_REQUEST: ["loan", "borrow", "credit", "money to start", "money for", "funding", "finance my"],
    SUBSIDY_REQUEST: ["subsidy", "subsidised", "subsidized"],
    GRANT_REQUEST: ["grant"],
    TRAINING_REQUEST: ["training", "skill development", "workshop", "capacity building"],
    REGISTRATION_REQUEST: ["register", "registration", "udyam", "how to register"],
    EXPORT_REQUEST: ["export", "iec", "dgft"],
    TAX_REQUEST: ["gst", "tax", "income tax", "exemption"],
    WOMEN_SUPPORT: ["women", "female", "mahila", "woman entrepreneur"],
    STARTUP_SUPPORT: ["startup", "start up", "new business", "start a business", "start my"],
    CLUSTER_SUPPORT: ["cluster", "common facility centre", "common facility center"],
  },
} as const;

// Partial (not full) credit across related-but-distinct concepts.
const RELATED_CONCEPTS: Record<string, string[]> = {
  treds_platform: ["invoice_discounting", "receivables_financing"],
  invoice_discounting: ["treds_platform", "receivables_financing"],
  receivables_financing: ["treds_platform", "invoice_discounting"],
  collateral_free: [],
  guarantee_backed: [],
};

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

const TOKEN_RE = /[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}/g;

function stripEdges(s: string, chars: string): string {
  let start = 0;
  let end = s.length;
  while (start < end && chars.includes(s[start])) start++;
  while (end > start && chars.includes(s[end - 1])) end--;
  return s.slice(start, end);
}

const STATUS_FACTOR: Record<string, number> = { active: 1.0, unknown: 1.0, closed: 0.72 };
const STATUS_TO_CONCEPT: Record<string, string> = { not_required: "collateral_free", guarantee_covered: "guarantee_backed" };
const WEIGHTS = { keyword: 1.0, semantic: 0.6, category: 0.8, eligibility: 0.5, benefit: 0.9 };
const SEMANTIC_QUERY_GROUPS: (keyof QueryTags)[] = ["industries", "benefits", "communities", "collateral", "treds"];

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
// Mirrors frontend/assets/search/query_expansion.json field-for-field.
// All expansion target tokens have been verified against the catalog vocab.
const QUERY_EXPANSIONS: Record<string, string[]> = {
  // Scheme acronyms
  pmegp: ["prime", "minister", "employment", "generation", "programme"],
  mudra: ["pradhan", "mantri", "mudra", "yojana"],
  pmmy: ["mudra", "pradhan", "mantri", "yojana"],
  cgtmse: ["credit", "guarantee", "fund", "micro"],
  needs: ["entrepreneur", "enterprise", "development"],
  tread: ["trade", "entrepreneurship", "assistance", "development", "women"],
  wep: ["women", "entrepreneurship", "platform"],
  uyegp: ["unemployed", "youth", "employment", "generation", "programme"],
  tanseed: ["startup", "seed", "fund", "grant"],
  clcss: ["credit", "linked", "capital", "subsidy"],
  pmfme: ["food", "processing", "enterprises", "micro"],
  pmkvy: ["kaushal", "vikas", "skill", "training"],
  // Institutional abbreviations
  momsme: ["msme", "ministry", "enterprises"],
  kvic: ["khadi", "village", "industries"],
  sidbi: ["small", "industries", "development", "bank"],
  dpiit: ["industry", "trade", "promotion"],
  tansim: ["startup", "tamil", "nadu", "innovation"],
  // Tamil transliterations (Tanglish)
  kadan: ["loan", "credit", "கடன்"],
  udavi: ["subsidy", "grant", "assistance", "உதவி"],
  thozhil: ["business", "enterprise", "industry", "employment", "தொழில்"],
  magalir: ["women", "மகளிர்"],
  maniyam: ["subsidy", "மானியம்"],
  thittam: ["scheme", "programme", "திட்டம்"],
  vivasayi: ["agriculture", "agricultural", "farm"],
  velai: ["employment", "skill", "training"],
  // Multi-word phrases
  "stand up india": ["stand-up", "women", "enterprise"],
  "street vendor": ["svanidhi", "street", "vendor", "vendors"],
  "tea stall": ["svanidhi", "vendor", "micro", "street"],
  "student startup": ["student", "innovation", "youth", "startup"],
  handicraft: ["craftspeople", "artisans"],
  handloom: ["artisans"],
};

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
