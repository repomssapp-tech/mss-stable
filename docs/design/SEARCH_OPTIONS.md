# Semantic search — options scoping (Phase 4, report only)

**Baseline:** `HybridSchemeSearch` — lexical keyword + field-weighted IDF. Measured **80.2% top-1** (vs `IntelligentSchemeSearch` 64.4%). No embedding model, no vector index anywhere in the project. `SchemeRepository` is online-first (`/v1/search`, 2500 ms timeout) with offline fallback to `HybridSchemeSearch`. Catalog: 219 schemes; bundle ~830 KB gzip / ~10.7 MB raw. Supabase region: **`ap-southeast-2` (Sydney)** — India → Sydney RTT ≈ 140–180 ms.

**The contract that must not break:** online-first / offline-fallback with *equivalent* results. A user must not get materially different answers for the same query depending on connectivity, and the app must never quietly become online-only.

**Existing hook:** `frontend/lib/services/hybrid_scheme_search.dart:154-175` already has `SchemeSearchTaxonomy.normalize()` / `expandRelated()` / `relatedConcepts` — a partial query-tag layer that Option A extends rather than invents.

---

## Option A — query expansion over the existing lexical engine

Synonym / alias / abbreviation / transliteration dictionary applied at query time, before tokenisation, in `SchemeSearchTaxonomy` (client) and mirrored in `search_engine.ts` (server) so both paths expand identically.

| Aspect | Assessment |
|---|---|
| Files touched | `frontend/lib/services/hybrid_scheme_search.dart` (extend `SchemeSearchTaxonomy`); new `frontend/assets/search/query_expansion.json` (the dictionary, shipped/updated with the catalog bundle); `backend/supabase/functions/v1/search_engine.ts` (mirror the same expansion — it is a field-for-field port of the Dart engine, so it stays in sync); one search-corpus test addition |
| Offline behaviour | **Identical to online.** Pure query-time string transform inside the same lexical engine. Zero connectivity dependence. |
| Bundle-size delta | +20–80 KB (one JSON dictionary). Negligible against the 830 KB bundle. |
| Needs a model | **No.** |
| Accuracy movement | Recovers queries lexical currently misses *on vocabulary*, not on concept. For Indian government-scheme vocabulary the miss surface is concrete: short-name ↔ full-name ("PMEGP" ↔ "Prime Minister's Employment Generation Programme"; "Mudra" ↔ "Pradhan Mantri MUDRA Yojana"; NEEDS, TREAD, WEP, Stand-Up India); ministry/body abbreviations (MoMSME, DPIIT, SIDBI, NABARD, KVIC, TANSIM); Tamil/Hindi transliteration variants ("kadan"/"கடன்"/"loan", "udavi"/"உதவி"/"assistance", "thozhil"/"employment"); colloquial ↔ formal ("money for women to start business" → subsidy/grant/loan + women-entrepreneur; "old age pension" → social_assistance). **Honest estimate:** +4–10 pts top-1 on the vocabulary-miss subset, no change on queries that already hit; small precision risk if the dictionary over-expands (mitigation: expansions add *optional* lower-weight tokens, never replace the original query). Net realistic: **80.2% → ~84–88%.** |
| Contract impact | **None.** Online and offline expand identically; no new dependency, no per-query cost, no region latency. |

Ceiling: A cannot solve true conceptual paraphrase ("help starting a tea stall" → PMEGP/Mudra). Roughly: abbreviations ~40% of current misses (mostly recoverable), transliteration ~25% (recoverable with a curated list), conceptual paraphrase ~35% (only partly recoverable — needs B or C).

---

## Option B — pgvector in Supabase, online path only

Scheme embeddings stored server-side in `catalog.scheme_embedding` (hnsw index), exposed via a new `SECURITY DEFINER` RPC `mss_semantic_search(query_embedding, limit)` alongside `mss_search_data`. `/v1/search` embeds the query (external embedding-provider call), then vector-searches; offline stays lexical.

| Aspect | Assessment |
|---|---|
| Files touched | new migration (`catalog.scheme_embedding` table + hnsw index + RPC + grants); `backend/supabase/functions/v1/index.ts` + `search_engine.ts` (add semantic route + query-embedding call + a blend/rerank step); a `tools/embed_catalog.py` generation script; embedding-provider secret wiring (`SB_SECRET_KEY`-style, not `SUPABASE_`-prefixed) |
| Offline behaviour | **Falls back to lexical (80.2%).** Same user, same query: semantic on wifi, lexical on mobile data → results differ by connectivity. |
| Bundle-size delta | 0 (server-side). |
| Needs a model | No on-device model, but a **hosted embedding model** (external provider) is now on the critical path for every online search. |
| Accuracy movement | Semantic genuinely helps the conceptual/paraphrase misses A cannot ("support after my husband died" → widow pension). Online top-1 plausibly **~88–92%**. But *experienced* accuracy is bimodal — offline users see no improvement. |
| Latency | query-embedding call (~100–300 ms to the provider) + vector search + Sydney RTT (~160 ms) → **+300–500 ms** vs today's lexical `/v1/search`. Inside the 2500 ms client timeout, but a real felt cost and a new failure mode (provider down → silent fallback to lexical mid-session). |
| Contract impact | **Breaks "results don't silently depend on connectivity."** Adds an external embedding-provider dependency + per-search cost + a new secret. The offline-first premise is undermined — semantic becomes a wifi-only bonus. Acceptable only if surfaced explicitly (a visible "Smart search — needs internet" control), never as the silent default. |

---

## Option C — bundled embeddings + on-device query encoder

Precompute 219 scheme vectors, ship them in the catalog bundle. The query side needs an on-device sentence encoder — **this reintroduces an edge model**, the class the project deliberately removed (Qwen3 0.6B). Note the contradiction to resolve first: `pubspec.yaml` still declares `llama_flutter_android: 0.2.6` and `edge_slm_*` code still exists, so "there is no on-device SLM" is already only half-true in the tree.

| Aspect | Assessment |
|---|---|
| Files touched | `tools/generate_catalog_bundle.py` (emit vectors into the bundle); a new on-device encoder wrapper + model download/verify service (a rebuild of the removed edge-model-pack pattern); `hybrid_scheme_search.dart` (blend lexical + cosine); `pubspec.yaml` (an ONNX/tflite runtime dependency) |
| Offline behaviour | Fully offline **after the encoder model is fetched.** Consistent online/offline once installed. |
| Bundle-size delta | Vectors: 219 × 384 dims × fp16 ≈ **170 KB** (or ~340 KB fp32) — modest. **Encoder model: 20–90 MB** (MiniLM-class) — either bundled (APK bloat) or downloaded on first run. |
| Needs a model | **Yes** — an on-device sentence encoder. Directly contradicts the edge-model-removal decision. |
| Cold start | First launch (or first search) blocks on a 20–90 MB download → **~30–90 s on a slow Indian mobile connection** — the exact UX regression the edge-model removal was meant to avoid. |
| Accuracy movement | Similar ceiling to B (~88–92%), and *consistent* offline. |
| Contract impact | Preserves online-first/offline-fallback (both paths work). But reintroduces the edge-model class, its download/verify/fallback machinery, its maintenance burden, and a first-run cold start. |

---

## Recommended order

1. **Ship Option A first.** Cheap, offline-safe, zero contract risk, extends an existing hook, and targets the *concrete* Indian-scheme vocabulary problem (abbreviations, transliteration, colloquialisms). Re-measure top-1 against the fixed corpus afterwards.
2. **If A's ceiling (~84–88%) is not enough for conceptual-paraphrase misses**, add **Option B behind an explicit user-visible "Smart search (online)" toggle** — so connectivity-dependence is a stated feature, not a silent inconsistency. Not the default.
3. **Option C last, only if offline semantic search becomes a hard product requirement** and the team explicitly accepts a new on-device model, its APK/first-run cost, and the reversal of the edge-model decision.

No implementation code in this phase.
