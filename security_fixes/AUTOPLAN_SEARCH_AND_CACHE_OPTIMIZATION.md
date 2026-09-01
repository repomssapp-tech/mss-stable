# Autoplan: High-Performance Search & Cache Architecture Optimization

**Date:** August 27, 2026  
**Auditor / Architect:** Antigravity AI  
**Disciplines Applied:** `@gstack-autoplan` (CEO, Design, Eng, DevEx) & `@gstack-benchmark` (Performance Baselines)  
**Status:** **PLANNING — PENDING USER APPROVAL**  

---

## 1. Executive Problem Statement & Benchmark Baseline

In our live database audit, we discovered that calling `mss_search_data()` currently takes **3,422ms** and transfers **5,152.3 KB (5.15 MB)** of raw JSON per call. Because the RPC currently executes `select s.record_json, si.record_json`, it dumps full paragraphs, document guidelines, and scheme overview texts across 219 schemes, even though the `HybridSearchEngine` only reads `semanticTags`, `tokens`, and `schemeSearchProfile`.

Furthermore:
1. **Cache Stampede Risk:** If multiple concurrent users submit searches during a cold start or cache reload, the Edge Function triggers parallel multi-second 5.15MB queries to PostgreSQL.
2. **Short Cache Lifetime:** The Edge Function cache expires after only 5 minutes (`const CACHE_TTL_MS = 5 * 60 * 1000`), repeatedly subjecting users to 3.4s latency spikes.
3. **Public Exposure of Bulk Data:** `mss_search_data()` is currently granted to `anon, authenticated`, allowing anyone to dump 5.15MB of catalog index data via PostgREST.
4. **Client-Side Redundant Requests:** Flutter `SchemeRepository.searchSchemes` lacks request deduplication and memoization, firing duplicate parallel HTTP calls on rebuilds and rapid typing.
5. **No Edge Rate Limiting:** `/v1/search` has no abuse protection or rate throttling.

---

## 2. Benchmark Baselines & Target Metrics (`gstack-benchmark`)

| Dimension / Metric | Current Baseline (Unoptimized) | Target Post-Optimization | Projected Gain |
|---|---|---|---|
| **`mss_search_data()` Payload Size** | **5,152.3 KB (5.15 MB)** | **< 250 KB** | **> 95% reduction** |
| **`mss_search_data()` Query Latency** | **3,422 ms** | **< 250 ms** | **~13x faster** |
| **Concurrent Cold-Start Queries (10 users)** | 10 parallel queries (51.5 MB transfer) | 1 shared query (< 250 KB transfer) | **99.5% network & DB load reduction** |
| **Edge Cache TTL** | 5 minutes (frequent cold re-fetches) | 60 minutes + explicit invalidation | **12x longer cache warmth** |
| **Client Cached Search Latency** | ~1,000 ms (network roundtrip) | **< 1 ms** (in-memory memoization) | **Instant UI response** |
| **Public PostgREST Security** | `anon` execution permitted | Revoked (only `service_role`) | **Zero anonymous bulk scraping** |
| **Abuse Protection** | None (unlimited requests) | 60 req/min sliding window per IP (429) | **DoS / scraper resilient** |

---

## 3. Autoplan Cross-Disciplinary Review

### 3.1. CEO / Strategic Review
- **Decision:** **HOLD SCOPE & EXECUTE COMPLETE OPTIMIZATION**.
- **User Impact:** Search is the primary discovery wedge of MSS App. Eliminating the 3.4s cold-start delay transforms the application from feeling sluggish to feeling instant and snappy.
- **Infrastructure Cost:** Cutting payload from 5.15MB to 250KB saves enormous Supabase egress and compute costs, allowing the backend to scale effortlessly under high citizen traffic.
- **Security Boundary:** Locking `mss_search_data()` to `service_role` prevents competitors or unauthorized actors from scraping the proprietary scheme database.

### 3.2. Design & User Experience Review
- **Visual Responsiveness:** With in-flight deduplication and short-term memoization, navigating back to previous search terms displays results with zero flicker or reloading spinners.
- **Debounce Rhythms:** Prevents rapid typing in search inputs from triggering jarring out-of-order UI state swaps.

### 3.3. Engineering Review (Architecture & Implementation)
- **Database Layer (`backend/supabase/migrations/`):**
  - Create migration `20260827000000_optimize_search_rpc_and_security.sql`.
  - Project only `ai.semanticTags`, `identity.status`, `identity.name`, `tokens`, and `schemeSearchProfile`.
  - Revoke execution from `anon, authenticated`; grant strictly to `service_role`.
- **Edge Function Layer (`backend/supabase/functions/v1/index.ts`):**
  - Implement Singleflight loading promise: `loadingPromise: Promise<...> | null` to coalesce concurrent cache misses into a single database fetch.
  - Extend `CACHE_TTL_MS` to 60 minutes (`3,600,000 ms`).
  - Add explicit cache invalidation endpoint (`POST /v1/cache-bust`) protected by service role / admin check.
  - Implement token-bucket / sliding-window rate limiter (60 req/min per IP) returning HTTP 429 with `Retry-After`.
- **Client Layer (`frontend/lib/services/scheme_repository.dart`):**
  - Implement `_inFlightSchemeSearches` and `_searchSchemesCache` in `SchemeRepository`.
  - If an identical query is currently in-flight, return the existing `Future`.
  - Cache results for 15 seconds to eliminate duplicate calls across screen switches and rebuilds.

### 3.4. Developer Experience & Quality (DevEx)
- Write an automated benchmark script `backend/scripts/benchmark_search_pipeline.mjs` to measure and report exact query durations, payload byte counts, and concurrent singleflight deduplication.
- Run `flutter analyze` and `uv run pytest -v` to ensure zero regressions across client and voice agent.

---

## 4. Implementation Steps & File Map

1. **[NEW] Migration `backend/supabase/migrations/20260827000000_optimize_search_rpc_and_security.sql`**:
   - Prunes `mss_search_data()` output to essential search tokens and tags.
   - Revokes permissions from `anon, authenticated` and grants to `service_role`.
2. **[MODIFY] `backend/supabase/functions/v1/index.ts`**:
   - Singleflight loading promise (`loadingPromise`).
   - 1-hour cache TTL + `POST /v1/cache-bust` route.
   - Per-IP rate limiting middleware on `/v1/search`.
3. **[MODIFY] `frontend/lib/services/scheme_repository.dart`**:
   - `_inFlightSchemeSearches` (deduplication).
   - `_searchSchemesCache` (15s query memoization).
   - Debounced search helper.
4. **[NEW] `backend/scripts/benchmark_search_pipeline.mjs`**:
   - Automated benchmark test measuring payload size, singleflight concurrency, and latency.
5. **[MODIFY] `security_fixes/WALKTHROUGH.md` & `walkthrough.md`**:
   - Update walkthrough documentation with performance benchmark before/after metrics.

---

## 5. Verification Plan

- [ ] Execute `backend/scripts/benchmark_search_pipeline.mjs` to confirm payload < 250KB and latency < 300ms.
- [ ] Test 10 concurrent requests to `/v1/search` and verify only 1 DB query is made.
- [ ] Confirm `POST /rest/v1/rpc/mss_search_data` with `anon` key returns `401 Unauthorized` or `403 Forbidden`.
- [ ] Verify rate limiter blocks at 61st request in a minute with HTTP 429.
- [ ] Run `flutter analyze` to guarantee 0 Dart compiler or analyzer issues.
