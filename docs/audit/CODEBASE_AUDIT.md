# MSS App — Codebase Audit

**Date:** 2026-09-10 · **Branch:** `main` · **Repo root:** `C:\development\MSS App\MSS_App` (note: nested one level under `C:\development\MSS App\`)

**Method:** Read-only investigation by five parallel agents, each verifying claims against source code. Every pre-written document (`README.md`, `CLAUDE.md`, `docs/*ARCHITECTURE.md`, the loose root `.md` files) was treated as an **unverified claim** and checked against the code. Divergences are consolidated in [§12](#12-doc-claims-vs-reality).

**Not verifiable from here:** the live Supabase project `houpzsxmwemoztpuigmo` cannot be queried from this environment. Database findings rely on the migration files under `backend/supabase/migrations/` and the `backend/supabase/schema.sql` snapshot (dated ~2026-09-04, itself stale). Flutter/agent builds were not run.

---

## One-Page Onboarding Summary

**What it is.** MSS ("My Scheme Search") is a Tamil-first mobile app that helps citizens and MSMEs in Tamil Nadu find government schemes. Three deployables in one repo: a **Flutter app** (`frontend/`), a **Supabase backend** (`backend/` Deno edge functions + Postgres migrations), and a **Python LiveKit voice agent** ("Saarthi", `saarthi-agent/`).

**The one fact that reframes everything: scheme search is 100% on-device.** The app ships a gzipped catalog bundle (`frontend/assets/catalog/catalog_bundle.json.gz`, ~219 schemes / 1220 entities) and ranks results in-process with `HybridSchemeSearch` (a parity-locked IDF scorer). The Supabase `POST /v1/search` edge function exists, is deployed, and has **zero callers** — it is reserved for a future voice path. The **only** network dependency near search is a best-effort hourly catalog-refresh (Supabase Storage + one RPC) that silently falls back to the shipped bundle. Supabase is used for **auth (Google OAuth), the `profiles` table, realtime, and storage** — nothing else on the hot path.

**Stack.** Flutter (Dart SDK `^3.11.1`, bleeding-edge channel), `provider` for state (one ~1977-line `AppProvider` `ChangeNotifier`), `supabase_flutter`. Backend: Deno 2 edge functions on a 2.5-year-old `std@0.168.0` `serve`, `@supabase/supabase-js@2.39.0`, Postgres 17 with 76 forward-only migrations across 4 schemas (`public`, `catalog`, `admin`, `private`). Agent: Python 3.10–3.14, `uv`, `livekit-agents~=1.7`, Sarvam AI for STT/LLM/TTS.

**Where truth lives.** The code, then `docs/OFFLINE_FIRST_AND_RECOMMENDATION_ARCHITECTURE.md` (the most accurate doc). **Do not trust** root `README.md` (describes a different, older app — Hindi/OTP), and treat `CLAUDE.md` and `docs/DATABASE_ARCHITECTURE.md` as partly stale (see §12).

**Biggest risks.** (1) A **live Supabase secret key sits in plaintext** in two untracked working-tree files (`backend/.env`, `saarthi-agent/.env.sarvam`) — not in git, but full DB admin. (2) **No CI on PRs** for Flutter or the agent. (3) Search ranking is implemented **three times** (Dart/TS/Python) with 4 copies of a taxonomy JSON, kept in sync only by parity tests. (4) Several DB objects and a `catalog.search_index.search_doc` column exist only in production, not in any migration — a fresh replay diverges from prod. (5) God-object `AppProvider`; 4000–4800-line screen files.

**First 5 files to read:** `frontend/lib/main.dart`, `docs/OFFLINE_FIRST_AND_RECOMMENDATION_ARCHITECTURE.md`, `frontend/lib/providers/app_state_provider.dart`, `frontend/lib/services/scheme_repository.dart`, `backend/supabase/functions/v1/index.ts`.

---

## 1. Tech Stack & Framework Versions

### Frontend — `frontend/` (Flutter/Dart)
- **SDK:** `sdk: ^3.11.1` (`frontend/pubspec.yaml:21-22`); `pubspec.lock` resolves `dart >=3.11.1 <4.0.0`, `flutter >=3.38.4` — a bleeding-edge channel. App `version: 1.0.2+3`.
- **State:** `provider ^6.1.2` (no Riverpod/Bloc/hooks — grep-confirmed zero hits).
- **Backend client:** `supabase_flutter ^2.8.0` (auth + `profiles`/`startup_profiles` + Storage + RPC only).
- **HTTP:** `http ^1.5.0` (no dio/chopper); used in exactly one file (`official_grounded_search.dart`).
- **Other direct deps:** `intl ^0.20.2`, `shared_preferences ^2.2.3`, `google_fonts ^8.1.0` (suspiciously ahead — verify it resolves), `geolocator ^12.0.0`, `geocoding ^3.0.0`, `google_maps_flutter ^2.18.0`, `url_launcher ^6.3.2`, `speech_to_text ^7.4.0`, `image_picker ^1.2.3`, `path_provider ^2.1.6`, `crypto ^3.0.7`, `livekit_client ^2.8.0`, `archive ^3.6.1` (4.x exists), `cached_network_image ^3.4.1`, `flutter_cache_manager ^3.4.1`, `confetti ^0.8.0`, `cupertino_icons ^1.0.8` (**unused** — app is Material-only), `llama_flutter_android 0.2.6` (**exact pin, no caret**; Android-only on-device LLM).
- **Dev deps:** only `flutter_test` + `flutter_lints ^6.0.0`. **No** `mockito`/`mocktail`, `build_runner`, or `integration_test` despite ~80 test files (they use hand-rolled fakes + constructor injection).
- `pubspec.yaml:1-2` still carries the template `name: frontend` / `description: "A new Flutter project."`.

### Backend — `backend/` (Deno + Node tooling)
- **Edge functions:** Deno 2 (`backend/supabase/config.toml` `[edge_runtime] deno_version = 2`). Pins from `backend/deno.lock` (v5): `npm:@supabase/supabase-js@2.39.0`, `npm:livekit-server-sdk@2.17.0`, Deno **`std@0.168.0`** (Dec 2022) for `http/server.ts`. **No import map** — pins are inline per file.
- **Tooling:** Node `>=20.19 <21 || >=22.12` (`backend/package.json:27-29`). Dev deps only: `supabase 2.109.1` (CLI), `@redocly/cli 2.39.0`. **No runtime npm dependencies.**
- **No application server** — Postgres + edge functions + Storage only.

### Database — Postgres 17 (`backend/supabase/`)
- `config.toml`: `major_version = 17`, API exposes only `public` + `graphql_public`.
- 76 forward-only migrations, `20260714061757` → `20260908120000`.
- Extensions: `pgcrypto` (used), `vector`/pgvector (used — `vector(1536)`, HNSW index), `pg_trgm` (**enabled, unused**), `uuid-ossp` (**enabled, unused**).

### Agent — `saarthi-agent/` (Python)
- `requires-python = ">=3.10, <3.15"` (`pyproject.toml:8`); `Dockerfile` builds Python **3.14**; dead nested CI targets 3.12; `backend-database.yml` voice job uses 3.11. **Nothing pins one version.**
- Package manager **uv**, `uv.lock` committed.
- Runtime deps: `livekit-agents[sarvam]~=1.7`, `livekit-plugins-ai-coustics~=0.2`, `python-dotenv`. Dev: `pytest`, `pytest-asyncio`, `ruff`. Constraint workaround `yarl<1.24`.

### Root
- `package.json` (root): single dep `@supabase/supabase-js ^2.115.0`, no scripts; only consumer is `scripts/migrate_chat_logs.js`.
- `.mcp.json`: one MCP server `supabase` pinned to `project_ref=houpzsxmwemoztpuigmo`.

---

## 2. System Architecture

```
                          ┌─────────────────────────────────────────────┐
                          │            Flutter app (frontend/)          │
                          │                                             │
  Google OAuth  ◄─────────┤  auth_service.dart → Supabase Auth          │
                          │                                             │
  ON-DEVICE SEARCH:       │  SearchScreen → SchemeRepository            │
   (no network)           │    → HybridSchemeSearch.rank()              │
                          │    → MssCatalogBundle (assets/catalog/      │
                          │        catalog_bundle.json.gz, ~219 schemes)│
                          │                                             │
                          │  profiles CRUD ───────────┐                 │
                          │  realtime (profiles,      │                 │
                          │    notifications) ────────┤                 │
                          │  catalog OTA sync ────────┤                 │
                          │  chat (sarvam-chat fn) ───┤                 │
                          │  voice (livekit-token fn) ┤                 │
                          └───────────────────────────┼─────────────────┘
                                                      │
                       ┌──────────────────────────────▼──────────────────────────┐
                       │        Supabase project  houpzsxmwemoztpuigmo           │
                       │                                                         │
                       │  Auth (Google OAuth)                                     │
                       │  Postgres 17  ── public / catalog / admin / private     │
                       │     RLS on every table; catalog.* only via              │
                       │     SECURITY DEFINER mss_* RPCs (service_role)          │
                       │  Storage bucket "catalogs" (private) ── release bundles  │
                       │  Realtime ── profiles, notifications, catalog_sync       │
                       │  Edge Functions (Deno 2):                                │
                       │     v1          POST /v1/search + catalog/finance/...    │
                       │                 (DEPLOYED, NO CLIENT CALLER)             │
                       │     sarvam-chat → api.sarvam.ai (text chatbot)          │
                       │     livekit-token → mints LiveKit tokens                 │
                       │     publishCatalog / rollbackRelease / db-change-notify  │
                       │     search / recommend → 410 GONE (retired)             │
                       └───────────┬───────────────────────────┬─────────────────┘
                                   │                           │
                     ┌─────────────▼──────────┐    ┌───────────▼─────────────────┐
                     │  LiveKit Cloud         │    │  Saarthi voice agent        │
                     │  mss-kqp2428o          │◄──►│  (saarthi-agent/, Python)   │
                     │  realtime media plane  │    │  LiveKit worker             │
                     └────────────────────────┘    │  find_schemes() = LOCAL     │
                                                   │    HybridSearchEngine over  │
                                                   │    bundled data/*.json      │
                                   ┌───────────────┤  STT/LLM/TTS → Sarvam AI    │
                                   │               │  catalog sync ← Supabase    │
                     ┌─────────────▼──────────┐    └─────────────────────────────┘
                     │  Sarvam AI             │
                     │  saaras:v3 / sarvam-   │
                     │  105b / bulbul:v3      │
                     └────────────────────────┘
```

**Key point:** the app and the agent each ship their **own** copy of the catalog and their **own** search implementation. Neither calls the server for search. The server search pipeline is exercised only by tests and `benchmark_search_pipeline.mjs`.

---

## 3. Major Services / Modules

### `frontend/lib/`
| Folder | Responsibility |
|---|---|
| `config/` | `app_config.dart` — build-time config from `String.fromEnvironment` (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`) + a `validationError` startup gate. |
| `engine/` | `recommendation_engine.dart` (~750 lines) — pure, explainable "For Me" eligibility scorer over `UserProfile` × `Scheme`. |
| `features/beta_gate/` | The only feature-first module: password gate (config/service/screen) backed by a Supabase table with local unlock state. |
| `l10n/` | ARB source (`app_en.arb`, `app_ta.arb`) + **committed** generated Dart (`app_localizations*.dart`, ~232 KB) + `context.l10n` extension. |
| `models/` | Flat data models: `scheme_model.dart` (UI `Scheme`), `mss_entity.dart`/`mss_contract.dart`/`mss_models.dart` (raw catalog contract), `user_profile.dart`, `scheme_filter.dart`, `catalog_manifest.dart`. |
| `providers/` | `app_state_provider.dart` — **one** `ChangeNotifier` (`AppProvider`, ~1977 lines) owning auth, profile, language, tabs, bookmarks, search state, filters, wizard, announcements, notifications, catalog sync. |
| `screens/` | Top-level screens + `regular_mode/` (main product) and `companion_mode/` ("Saarthi" voice shell). |
| `services/` | 25 files — `scheme_repository.dart` (sole data gateway), catalog bundle/sync/store, 5 overlapping search/understanding engines, translator, auth, chat log, LiveKit/voice controllers, edge-SLM runtime. |
| `utils/` | `constants.dart` (colors/gradients + legacy en-only translation map), `app_spacing.dart`, `app_theme.dart`, `responsive.dart`, permission/location helpers. |
| `widgets/` | 17 shared widgets incl. `scheme_card.dart`, `filter_panel.dart`, `voice_assistant_overlay.dart` (3907 lines), `smart_assessment_bottom_sheet.dart` (2118 lines). |

There is **no** `routes/`, `di/`, or `state/` folder — routing is imperative `Navigator.push`, DI is constructor params.

### `backend/`
| Path | Responsibility |
|---|---|
| `supabase/functions/v1/` | 684-line HTTP router: `/v1/health`, `/v1/meta`, `/v1/search`, `/v1/cache-bust`, `/v1/schemes/{id}[/finance]`, `/v1/finance-products`, `/v1/clusters\|tax\|privileges`, `/v1/relationships/{id}`, `/v1/eligibility`, `/v1/localization/{id}`. Warm-isolate engine cache (1 h TTL), DB-backed rate limiting. Helpers: `search_engine.ts`, `api_mappers.ts`. |
| `supabase/functions/sarvam-chat/` | Proxies the regular-mode chatbot to `api.sarvam.ai` (model `sarvam-105b-conversations`), bounds history, injects a fixed system prompt. |
| `supabase/functions/livekit-token/` | Validates the caller's Supabase session, mints a LiveKit `AccessToken` (10 min) with a `RoomAgentDispatch` for `saarthi-agent`. |
| `supabase/functions/publishCatalog/`, `rollbackRelease/`, `db-change-notify/` | Realtime broadcast on `catalog_sync` after a publish; atomic release pointer-flip via `mss_rollback_release(uuid)`; generic table-change broadcaster. |
| `supabase/functions/search/`, `recommend/` | **Retired** — return `410 GONE`. |
| `supabase/migrations/` | 76 forward-only SQL migrations — the authoritative schema (`docs/backend/decisions/0002`). |
| `supabase/schema.sql` | 132 KB generated snapshot — "point-in-time reference, not a migration"; **stale** (see §12). |
| `catalog/` | `search_taxonomy.json` (canonical search-tuning params) + `search_parity_golden.json` (25-query golden fixture). No catalog data. |
| `openapi/openapi.yaml` | OpenAPI 3.1 draft for an **unbuilt** admin/sync API — does not describe the live routes (see §12). |
| `scripts/` | `import_catalog.mjs` (**dead** — calls dropped RPCs), `generate_catalog_import_sql.js` (real catalog-load path), `benchmark_search_pipeline.mjs`, `verify_scheme_links.mjs` (weekly CI). |

### `saarthi-agent/src/`
`agent.py` (entry, ~670 lines), `catalog_sync.py` (only Supabase client — read-only), `scheme_catalog.py`, `hybrid_search.py` (3rd parity copy of the ranker), `search_taxonomy.py`. That is the entire source tree.

### `tools/` (all Python, manual except `voice-lab`)
Edge-parser LoRA pipeline (`train_/evaluate_/export_edge_parser.py`, `evaluate_edge_gguf.py`), catalog build/publish (`generate_catalog_bundle.py`, `inject_scheme_url.py`, `publish_catalog_release.py`), `seed-data/` (Excel → seed JSON), `voice-lab/` (offline Tamil ASR benchmark lab — the only `tools/` code in CI).

---

## 4. Entry Points

### Frontend
- **`frontend/lib/main.dart:39-105` — `main()`** (async): lock portrait + edge-to-edge UI → **config gate** (`AppConfig.validationError` at `main.dart:65`; missing/invalid `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` → `_StartupErrorApp`, nothing else runs) → `Supabase.initialize` (`main.dart:73-76`) → fire-and-forget `ChatLogService.syncPendingOfflineQueue()` + `LiveKitClient.initialize` → `runApp(ChangeNotifierProvider(create: (_) => AppProvider(), child: InSchemesApp()))`.
- **`InSchemesApp`** (`main.dart:152-295`): `MaterialApp`, locale from `AppProvider`, text-scale clamp (`main.dart:169-188`), M3 theme with GoogleFonts Poppins/Inter, `home: SplashScreen()`.
- **Routing:** **no named-route table.** `onGenerateRoute: (_) => null` (`main.dart:280`); `onUnknownRoute` (`main.dart:281-292`) exists **only** to absorb the Supabase OAuth deep-link (`com.inschemes.app://login-callback/?code=...`) that the platform pushes as a named route — it renders nothing and pops. All navigation is imperative; main shell is a 5-tab `IndexedStack` in `MainTabsContainer` driven by `AppProvider.currentTabIndex`.
- **`SplashScreen`** (`frontend/lib/screens/splash_screen.dart`): pure `resolveStartupDestination({hasSession, hasCachedLanguage, profileCompleted})` → `home`/`navigationMode`/`language`/`login`; validates the Supabase session server-side but keeps the cached session on `AuthRetryableFetchException` (offline); routes through the beta gate.
- **Config injection:** `--dart-define-from-file=dart_defines.json` via `run.sh`/`run.ps1` (subcommands `run|run-release|apk|apk-release|appbundle|web|analyze|test`), `.vscode/launch.json`, and `.github/workflows/build-app.yml`. `dart_defines.json` is git-ignored. **`MSS_API_BASE_URL` is defined there but read nowhere in `lib/`** — dead config.
- **l10n:** `frontend/l10n.yaml` (`arb-dir: lib/l10n`, template `app_en.arb`); `pubspec.yaml:77` `generate: true`; generated Dart is committed.

### Backend edge functions
Invoked at `https://<ref>.supabase.co/functions/v1/<name>/…`. The function literally named `v1` is an internal router (client base URL `.../functions/v1` + hardcoded `/v1/…` path → Supabase invokes fn `v1` with path `/v1/<route>`, parsed at `v1/index.ts:14-18,244-249`). Gateway `verify_jwt = true` pinned in `config.toml` for `v1`, `livekit-token`, `sarvam-chat`; the others inherit the platform default.

### Agent
`saarthi-agent/src/agent.py:669-670` — `if __name__ == "__main__": cli.run_app(server)`. `server = AgentServer()` with `setup_fnc = _sync_catalog_before_startup`; handler `@server.rtc_session(agent_name="saarthi-agent")`. Docker `CMD ["uv", "run", "src/agent.py", "start"]`.

### CI
6 active workflows in **repo-root** `.github/workflows/` (the nested `saarthi-agent/.github/workflows/` are **never run**):
- `backend-database.yml` — PR + push, path-filtered to `backend/supabase|openapi/**`, `tools/voice-lab/**`, `backend/package*.json`. The **only** PR gate.
- `build-app.yml`, `deploy-edge-functions.yml`, `deploy-voice-agent.yml` — `workflow_dispatch` only, `dry_run` default true.
- `rls-drift-check.yml` (cron Mon 04:30 UTC), `url-health-check.yml` (cron Mon 04:00 UTC).

---

## 5. One Full Request Trace — "User searches for a government scheme"

**The entire live path is in-process Dart. No Supabase endpoint, edge function, RPC, or socket is touched.**

| Hop | What | File:line |
|---|---|---|
| 1 | `TextField` (`TextInputAction.search`) `onSubmitted` → `_triggerSearch(text)`. Also reached from quick pills, voice dictation final result, the "try…" banner, and the voice-assistant overlay. | `frontend/lib/screens/regular_mode/search_screen.dart:827-833, 751-807, 316-356` |
| 2 | `_triggerSearch` (async): empty+no-filter → `SearchState.idle`; race guard `final requestGeneration = ++_searchGeneration` (stale results dropped); `SearchState.loading` (shimmer). Query normalized `toLowerCase().trim()`. Sentinel queries (`''`, `all`, `suitable schemes`, `for me`) → `getAllSchemes()`; else → `SchemeRepository.instance.searchSchemes(query)`. Comment at `:505-508` states regular search is a pure relevance lookup, **never** profile-weighted. | `search_screen.dart:484-520` |
| 3 | `SchemeRepository.searchSchemes(query, langCode='en')` — singleton (`:18-23`). 15 s TTL memo cache keyed `'$langCode:$query'` (`:39, 274-280`); in-flight singleflight (`:283-297`); `_executeSearchSchemes` → `searchSchemeMatchesOffline` → `.map((m) => m.scheme)`. **No HTTP import in this file.** Its docstrings at `:265`/`:311` still say *"Online-first via POST /v1/search with offline fallback"* — **stale; there is no network path.** | `frontend/lib/services/scheme_repository.dart:267-306, 363-375` |
| 4 | **Transport: none.** The `SupabaseClient` held at `scheme_repository.dart:23` is used only for `profiles`/`startup_profiles` (`:855-946`). `frontend/lib/services/mss_api_client.dart` **does not exist** (removed in the 2026-09-04 offline-first refactor). | — |
| 5 | `MssCatalogBundle.load()` — lazy singleton. Prefers an OTA-installed release (re-verifies SHA-256) else the shipped asset `assets/catalog/catalog_bundle.json.gz` + `release.json`. Checks `release.json:"bundleSha256"` against actual SHA-256; mismatch → throws. Gzip inflate + `jsonDecode` offloaded via `compute()`. Builds in-memory indexes `byId`, `byCatalog` (15 catalog files), `searchProfiles` from `search_index.json`. | `frontend/lib/services/mss_catalog_bundle.dart:95-100, 146-343` |
| 6 | `HybridSchemeSearch.rank(query, bundle, limit, langCode)` — `await SchemeSearchTaxonomy.ensureLoaded()` (loads `assets/search/search_taxonomy.json`). **Tier 0** exact-entity match (full name / curated acronym / ≥60% name-token coverage) → returns just that scheme, score `1.0`. Otherwise **scored search**: taxonomy-normalize → query-concept expansion (phrase then per-token, vocab-gated) → per-scheme weighted sum `w.keyword·kwIdf + w.semantic·sem + w.category·cat + w.eligibility·elig + w.benefit·ben`, `× statusFactor[status]`, rounded 1e-4. IDF `ln((N+1)/(df+1))+1`, `N = entries.length`. Deterministic sort: score desc, then id asc. Post-filters: proper-name query ≥3 tokens but top score `< 4.0` → **empty**; else relative floor `maxScore × 0.35`; hard cap 25. `w6·UserProfile` is always 0 (server parity). | `frontend/lib/services/hybrid_scheme_search.dart:672-788, 611-655, 275-346, 836-884` |
| 6′ | Each kept result → `SchemeSearchMatch(scheme: MssSchemeAdapter.toScheme(entry, bundle, langCode), score, reasons)`. Back in `SearchScreenState`: `_masterSearchResults = results`, then `_applyFiltersAndSort()` — client-side facet filters (`applySchemeFilters`), the opt-in "For Me" eligibility gate (`computeForMeView`, only if the chip is on), and sort mode (`Relevance` keeps ranker order / `Best match for me` re-sorts by `RecommendationEngine.evaluate().percentage` / `A-Z`). | `search_screen.dart:159-247, 522-525` |
| 7 | Render `_buildResultsList` — header count + `SchemeCard` per result. Four distinct empty states (For-Me-sparse-profile / For-Me-nothing-qualifies / text-query-0-hits / filter-only-0-hits). Search exceptions → `debugPrint` + empty results, **no error toast**. Tap a card → `Navigator.push(SchemeDetailsScreen)` (also served offline from the same bundle). | `search_screen.dart:1180-1322, 526-534` |

**Background catalog sync (the only network dependency search has):** on startup after first render and on every `AppLifecycleState.resumed`, `AppProvider.syncSchemeCatalog` → `SchemeCatalogSyncService.syncIfNeeded` (1 h throttle, 8 s timeout, in-flight dedup) → RPC `mss_current_release` + Storage download `catalogs/releases/<ver>/catalog_bundle.json.gz` → SHA-256-verified install. Any failure → outcome `offline`/`rejected`/`incompatible`; the app keeps serving the previous/shipped bundle. **Search degrades to "possibly stale", never to "broken", with no user-visible signal.** (`frontend/lib/services/scheme_catalog_sync_service.dart:36-164`, `app_state_provider.dart:810-915`)

**Deployed-but-dormant server path** (`POST /v1/search` in fn `v1`): rate-limit (per-IP 15/min + 200/day, global 40/min, project-wide 500/day, all fail **closed**) → `supabase.rpc('mss_search_data')` (SECURITY DEFINER, `service_role` only; returns the whole pruned corpus, no WHERE/FTS/vector) → `HybridSearchEngine` (TS port of the Dart ranker, parity-tested) → `{query, results:[{rank, schemeId, name, matchScore, score, matchReasons, explanation.summary}], metadata}`. (`backend/supabase/functions/v1/index.ts:1-12, 61-95, 365-412`)

---

## 6. External Integrations

| Integration | Type | Called from | Purpose | Blast radius if down |
|---|---|---|---|---|
| **Supabase Auth** (Google OAuth) | Auth | `frontend/lib/services/auth_service.dart:45-58`; code-exchange `splash_screen.dart:136-160` | Sign-in / session | New sign-in fails; existing users keep the cached session (`splash_screen.dart:101-113`). Search/browse unaffected. |
| **Supabase Postgres — `public.profiles` / `startup_profiles`** | DB (PostgREST) | `scheme_repository.dart:855-946` (all `.timeout(8s)`) | Persist/load user profile | Profile edits don't persist to cloud; "For Me" falls back to the locally cached profile. Search unaffected. |
| **Supabase Realtime** (`profiles`, `notifications`, `catalog_sync`) | WebSocket | `app_state_provider.dart:901-902`; `publishCatalog`/`db-change-notify` | Live profile/notification push; new-release ping | No live updates; hourly polling still catches new releases. Non-critical. |
| **Supabase Storage — bucket `catalogs`** (private since `20260828170000`) | Object storage | `scheme_catalog_sync_service.dart:63-65` | OTA-deliver fresher catalog | Catalog can't refresh; app serves last-installed/shipped bundle. Search works on stale data. |
| **Supabase RPC `mss_current_release`** | Postgres RPC (anon+authenticated) | `scheme_catalog_sync_service.dart:45` | Advertise current release identity/hash | Sync reports `offline`; same as Storage down. |
| **Supabase Edge fn `v1`** (`/v1/search` + catalog/finance/tax/cluster/eligibility/localization) | Edge fn (Deno) | **No Flutter caller.** Intended future caller: Saarthi voice path. | Server-side search + catalog lookups | Zero user-facing impact today. |
| **Supabase Edge fn `sarvam-chat`** → **Sarvam AI** (`api.sarvam.ai/v1/chat/completions`, `sarvam-105b-conversations`) | Edge fn → 3rd-party LLM | `frontend/lib/services/sarvam_chat_service.dart:60-61` | Text chat assistant ("Ask IN AI") | Chat screen shows retry/error state. Search/browse unaffected. |
| **Supabase Edge fn `livekit-token`** → **LiveKit Cloud** (`mss-kqp2428o`) | Edge fn → realtime/WebRTC | `frontend/lib/services/livekit_voice_agent_controller.dart:14,192`; warm-up `main.dart:89-97` | Mint LiveKit room token; voice transport | Voice agent can't connect. Text app unaffected. |
| **Saarthi voice agent** (`saarthi-agent/`, Python LiveKit worker) | Backend service | Out-of-process; ships its own bundle + `hybrid_search.py` | Voice-driven scheme lookup | Voice answers degrade/fail. On-device app search is separate and unaffected. |
| **Sarvam AI** (STT `saaras:v3`, LLM `sarvam-105b`, TTS `bulbul:v3`) | 3rd-party | `saarthi-agent/src/agent.py:35-37,195`; `sarvam-chat/index.ts` | Voice pipeline + text chat | Voice + chat answers fail. Core discovery unaffected. |
| **Supabase table `chat_logs`** (now `_deprecated_chat_logs`) | DB | `main.dart:84` (`ChatLogService.syncPendingOfflineQueue`) | Upload queued transcripts | Transcripts stay queued locally; retried next launch. |
| **Device speech recognizer** (`speech_to_text`, Android `SpeechRecognizer`) | On-device OS API | `search_screen.dart:98-99,316-356` | Search-bar voice dictation | Mic button warns; typing still works. |
| **Google Fonts CDN** (`google_fonts`) | 3rd-party CDN (runtime fetch) | throughout UI | Poppins/Inter typefaces | First offline run falls back to platform fonts; cosmetic. |
| **`url_launcher`** | OS handoff | scheme detail / "Apply Now" | Open official portal URLs | External links don't open; in-app data unaffected. |
| **Government portals** (e-Sevai, NSDL, UIDAI, Udyam, Startup India…) | HTTP (CI only) | `backend/scripts/verify_scheme_links.mjs` | Weekly link-health check | CI flags broken links; no runtime impact. |

**Not present in the Flutter client:** analytics, crash reporting, email, SMS, queue. No `firebase_*`, `sentry`, `posthog`, `amplitude`, `mixpanel`. Twilio/SendGrid/hCaptcha blocks in `config.toml` are `enabled = false` / commented out. The **retired `search` function** formerly spent an **OpenAI embeddings call per request**; `config.toml` still wires `openai_api_key` for Studio only.

---

## 7. Config & Secrets

### How config is loaded
- **Frontend:** compile-time `String.fromEnvironment` — `AppConfig.supabaseUrl` / `AppConfig.supabasePublishableKey` only (`frontend/lib/config/app_config.dart:17-23`), consumed at `main.dart:65-81`. Missing/invalid → visible `_StartupErrorApp`, not a blank screen. Source: `frontend/dart_defines.json` (git-ignored; template `dart_defines.example.json`).
- **Backend edge functions:** `Deno.env.get(...)`, never hard-coded. `SB_SECRET_KEY ?? SUPABASE_SERVICE_ROLE_KEY` (renamed because the `SUPABASE_` prefix is CLI-reserved — see `CUTOVER.md`), `SB_PUBLISHABLE_KEY ?? SUPABASE_ANON_KEY`, plus `LIVEKIT_*` and `SARVAM_API_KEY`. **Validation is ad-hoc** — each function does inline `if (!x) return 500/503`; no shared config loader or schema validation.
- **Agent:** `python-dotenv` loads `.env.sarvam` then `.env.local` (`agent.py:31-32`). Env **is** validated in code — model allow-list, bounded numeric parsing (`_bounded_env_float`/`_bounded_env_int`), clamps. Missing Supabase creds → `SyncOutcome.OFFLINE`, never fatal.
- **CI:** GitHub Actions secrets + a reviewer-gated `production` environment.

### ⚠️ Secrets on disk (NOT in git — gitignored, `git log --all -S` negative — but plaintext on this machine)
| Value | File | Risk |
|---|---|---|
| `SUPABASE_SECRET_KEY` — **live full-admin key, bypasses RLS**, project `houpzsxmwemoztpuigmo` (value present in file) | `backend/.env:3` **and** `saarthi-agent/.env.sarvam:6` (same value, duplicated) | **High.** Anyone with filesystem access to this repo folder has full DB admin. **Recommend: rotate and move to a secret manager.** |
| `SUPABASE_PUBLISHABLE_KEY` | `backend/.env:4`, `saarthi-agent/.env.sarvam` | Low — publishable keys are RLS-gated and designed to ship in clients. |

### Committed / tracked credential hits (all low-risk)
- `.github/workflows/deploy-edge-functions.yml:129` — the **publishable** key hardcoded as a `${{ vars.X || 'sb_publishable_…' }}` fallback (tracked). Rotating it means editing this file.
- `frontend/test/chat_log_integration_test.dart:21` — same publishable key in a test.
- `.gstack/security-reports/20260827-090200.json:42` — a **different** publishable key inside an example-exploit narrative → implies the publishable key was rotated since 2026-08-27. Dir is gitignored; file on disk. Housekeeping.
- `backend/supabase/.temp/pgdelta/*.json` — hundreds of `"grantee": "service_role"` lines: Postgres **role names** in CLI diff scratch, not credentials.
- Project ref `houpzsxmwemoztpuigmo` appears widely (`.mcp.json`, workflows, `CUTOVER.md`, docs, scripts) — not secret.
- `git grep` for `sb_secret_` / `service_role` JWTs across tracked files → only `.env.example` placeholders. **No committed service-role key or JWT.** No AWS keys, PEM blocks, or DB connection strings with embedded passwords in tracked files.

### In-database secret (design smell)
- `public.beta_gate_config.beta_password` — plaintext gate password committed in migration `20260907100000` **and** the table is `SELECT ... USING (true)` to **anon** — readable by anyone holding the publishable key.

---

## 8. Design Patterns

### Frontend (each with a file example)
| Pattern | Example |
|---|---|
| Singleton via private ctor + static `instance` | `SchemeRepository._()` / `.instance` (`scheme_repository.dart:19-21`); also `CentralizedTranslator`, `SchemeCatalogSyncService`. |
| Repository (single gateway) | `SchemeRepository` — every screen's scheme-data entry point (`scheme_repository.dart:11-18`). |
| Adapter | `MssSchemeAdapter.toScheme()` maps raw `MssEntity` → UI `Scheme` (`mss_scheme_adapter.dart`, ~1041 lines). |
| Pure, deterministic, explainable engine | `RecommendationEngine.evaluate(profile, scheme)` (`engine/recommendation_engine.dart:20+`); `HybridSchemeSearch.search()`. |
| Result object + outcome enum | `CatalogSyncResult` + `CatalogSyncOutcome {unchanged,updated,offline,incompatible,rejected,throttled}` (`scheme_catalog_sync_service.dart:9-26`); `GroundedSearchOutcome`. |
| Constructor-param DI (test seams) | `SchemeCatalogSyncService({source, store, clock})`, `BetaGateService({client})`, `AppProvider({syncService})`. |
| Extension method for ergonomics | `AppLocalizationsX` → `context.l10n` (`l10n/l10n.dart:4-7`). |
| In-flight de-dup + TTL memo | `_inFlightSchemeSearches` / `_searchSchemesCache` (15 s) in `scheme_repository.dart:32-39`. |
| Off-isolate compute | `MssCatalogBundle` gzip+parse via `compute()`. |
| Cached-derivation `StatefulWidget` (perf workaround for the god provider) | `_SchemeCardState` caches `_loc/_tags/_subtitle`, invalidates in `didUpdateWidget` (`scheme_card.dart:38-55`). |
| Thin re-export widgets | `AboutYouProfileScreen` → `BasicProfileScreen(initialStep: 3)`. |
| Global `ChangeNotifier` + surgical `context.select` | `AppProvider` at root (`main.dart:100-104`), consumed via `context.select` / `Provider.of(..., listen: false)`. |

### Backend
- **HTTP router in a single function** (`v1/index.ts`) rather than one Supabase function per route.
- **`SECURITY DEFINER` RPC boundary** — `catalog.*` / `admin.*` never exposed to PostgREST; all reads go through `public.mss_*` functions executed with the service-role client, `EXECUTE` revoked from `public/anon/authenticated`.
- **Warm-isolate cache + singleflight** for the search corpus (1 h TTL, `POST /v1/cache-bust` to invalidate).
- **Fail-closed rate limiting** backed by `public.api_rate_limits` (atomic `INSERT ... ON CONFLICT` fixed-window counter).
- **Service-role key as a bearer credential** for privileged mutating routes (`/cache-bust`, `publishCatalog`, `rollbackRelease`), compared with `timingSafeEqual` (except `rollbackRelease`, which uses a hand-rolled non-constant-time `safeEqual`).
- **Cross-runtime parity** — the ranker is ported Dart↔TS↔Python and locked by `search_engine_parity_test.ts` + `search_parity_golden.json`.

### Database
- **Hybrid `record_json jsonb` + mirrored relational columns** on every `catalog.*` table (id `text` PK, `status` enum, `checksum`).
- **RLS on every table**, enforced at migration time by `private.rls_coverage_violations()` and weekly by `rls-drift-check.yml`.
- **Checksum + entity-registry sync triggers** on 15–16 catalog tables (`sha256(record_json::text)`).
- **Append-only audit** (`private.prevent_audit_mutation()` trigger).

### Agent
- **Prompt-injection hardening** — user profile scrubbed (`UserProfileContext._text`), seeded as a `<citizen_facts>` user turn, never into the system prompt.
- **Local search tool** — `find_schemes()` over a bundled `HybridSearchEngine`, results also pushed to the app as a LiveKit participant attribute.
- **Best-effort catalog self-sync** before jobs; never raises.

---

## 9. Coding Standards & Directory Structure (inferred from code)

### Dart / Flutter
- **Files** `snake_case.dart`; role suffixes carry meaning: `_screen`, `_service`, `_engine`, `_controller`, `_helper`, `_modal`, `_card`, `_sheet`.
- **Classes/widgets** `PascalCase`; private `State` classes `_XScreenState`; private ctors `ClassName._()`.
- **Layout is layer-first** (`models/`, `services/`, `providers/`, `engine/`, `widgets/`, `utils/`); screens split by product mode (`regular_mode/` vs `companion_mode/`); `models/` and `services/` are flat (no sub-namespacing). One exception: `features/beta_gate/` is feature-first.
- **Docs:** heavy dartdoc header blocks with box-drawing rules on nearly every service/model; rationale comments are extensive and current.
- **Modern API discipline:** `Color.withValues(alpha:)` used 152×, `withOpacity(` 0× (fully migrated); `WidgetStateProperty` not `MaterialStateProperty`.
- **No file-size discipline** — median service/model 200–600 lines, but extreme outliers: `categories_screen.dart` 4822, `voice_assistant_overlay.dart` 3907, `saarthi_home_screen.dart` 2360, `basic_profile_screen.dart` 2209, `smart_assessment_bottom_sheet.dart` 2118, `app_state_provider.dart` 1977, `centralized_translator.dart` ~1050 (88 KB). Total `lib/` (excl. generated l10n) ≈ 56k lines.
- **Lint:** `frontend/analysis_options.yaml` = `include: package:flutter_lints/flutter.yaml` **only** — the custom `linter: rules:` block is entirely commented out. Root `analysis_options.yaml` just excludes archived/build dirs.
- **Constants** centralized: `AppConstants` (colors/gradients, `utils/constants.dart:5-32`), `AppSpacing` tokens used pervasively.

### TypeScript / Deno
- One function per directory `functions/<name>/index.ts` + colocated `*_test.ts` (except `v1/`, which has **only** a parity test — the 684-line router is untested).
- **Import-style inconsistency:** `esm.sh/@supabase/supabase-js@2.39.0` in `v1`/`publishCatalog`/`rollbackRelease` vs `npm:` in `db-change-notify`; std http pinned `@0.168.0` everywhere; no import map.
- Hand-rolled `safeEqual` reimplemented in 3 functions.

### SQL migrations
- 14-digit `YYYYMMDDhhmmss_snake_case_description.sql`, forward-only, idempotent guards (`if exists`, `IF NOT EXISTS`, `to_regprocedure(...) IS NOT NULL`).
- 4 schemas: `public` (user/app state), `catalog` (scheme data), `admin` (release/publish machinery), `private` (helper functions, no tables).

### Python (agent + tools)
- `ruff` (targets `py39` selectors); `pytest` + `pytest-asyncio`; `uv` with committed lock.
- Bounded env parsing, model allow-lists, explicit clamps.

### i18n
- Locales **`en` + `ta` (Tamil)** only — no Hindi. Keys are `camelCase` semantic names in `app_en.arb` (~1258 lines) / `app_ta.arb`.
- Referenced as `context.l10n.<key>` (544 sites) via the extension; generated Dart committed.
- **Dynamic catalog content is deliberately not in ARB** — `CentralizedTranslator` translates at runtime, preferring the catalog JSON's own `localization.ta` values.
- Known hardcoded user-facing strings: `utils/constants.dart:54-81` (legacy en-only map, superseded by ARB), `app_state_provider.dart:76-130` (`_defaultAnnouncements` / `_notificationsList` English seed data — the production fallback), `legal_document_modal.dart` + `data_processing_consent_modal.dart` (legal doc titles/headings), two `TODO(review-tamil-register)` / `TODO(review-seed-content)` markers.

---

## 10. Top 10 Files to Read First

| # | File | Why |
|---|---|---|
| 1 | `frontend/lib/main.dart` | Bootstrap, config gate, Supabase/LiveKit init, single-provider wiring, theme, the 5-tab `IndexedStack` shell, and the deep-link `onUnknownRoute` hack. |
| 2 | `docs/OFFLINE_FIRST_AND_RECOMMENDATION_ARCHITECTURE.md` | The most accurate architecture doc; §11 module map is the fastest route into the data/search/recommendation layer (ignore the one-patch-stale version string). |
| 3 | `frontend/lib/providers/app_state_provider.dart` | The god `ChangeNotifier` — app state, auth flow, profile sync/merge, filters, catalog sync all live here. |
| 4 | `frontend/lib/services/scheme_repository.dart` | The single data gateway; shows the offline-only discovery model and the Supabase-only-for-profile split. (Ignore its stale "online-first" docstrings.) |
| 5 | `backend/supabase/functions/v1/index.ts` | The whole server API surface: routing, JWT + service-role auth, fail-closed rate limiting, response envelopes. Header explains why `/v1/search` has no caller. |
| 6 | `frontend/lib/services/mss_catalog_bundle.dart` | How the offline catalog is loaded, SHA-256-integrity-checked vs `release.json`, and swapped for a runtime-synced newer release. |
| 7 | `frontend/lib/services/hybrid_scheme_search.dart` | The parity-locked ranker; header comments spell out the invariants you must not break. |
| 8 | `frontend/lib/engine/recommendation_engine.dart` | The pure "For Me" eligibility scorer; the weight design and `forMeThreshold` gate. |
| 9 | `backend/supabase/migrations/20260805000000_database_architecture_v2.sql` | The v2 rewrite — drops 24 tables and rebuilds into 4 schemas. Everything current descends from here. (Note: it was edited a day after commit — see §12.) |
| 10 | `saarthi-agent/src/agent.py` | The voice agent end-to-end: Sarvam pipeline, LiveKit session, profile injection hardening, `find_schemes` local search, pre-job catalog sync. |

Runners-up: `frontend/lib/screens/splash_screen.dart`, `frontend/lib/config/app_config.dart`, `frontend/lib/models/user_profile.dart`, `CUTOVER.md`, `backend/supabase/functions/v1/search_engine.ts`.

---

## 11. Technical Debt / Risk Areas

### Security / secrets
1. **Live Supabase secret key in plaintext on disk** — `backend/.env:3` and `saarthi-agent/.env.sarvam:6` (same `sb_secret_…` value). Not in git; full DB compromise if the machine/dir is shared. **Rotate + secret manager.**
2. **`beta_gate_config`** — plaintext gate password committed in migration `20260907100000` and `SELECT ... USING (true)` to anon.
3. **`db-change-notify` has no caller-authorization logic** — relies entirely on the implicit gateway default; fully open if `verify_jwt` is ever disabled for it. Also still on legacy `SUPABASE_SERVICE_ROLE_KEY`/`SUPABASE_ANON_KEY` env names (absent from `CUTOVER.md`).
4. **`rollbackRelease`** uses a hand-rolled non-constant-time `safeEqual` (timing-oracle inconsistency vs the `timingSafeEqual` used by `v1`/`publishCatalog`).
5. **CORS production origin is still a `TODO`** (`_shared/cors.ts:15`) — any real web client is blocked until edited.

### CI / process
6. **No CI on PRs for Flutter or the agent.** `build-app.yml` (`flutter analyze`/`test`) is `workflow_dispatch`-only; `saarthi-agent/.github/workflows/` are nested and **never run** by GitHub, so the agent's `pytest` (incl. `test_hybrid_search_parity.py`) and `ruff` gate nothing. `template-check.yml` would *fail* if it ran (it forbids the now-tracked `uv.lock`/`livekit.toml`).
7. **All three deploy workflows are manual, dry-run-first, never promoted** — deployment is effectively a human process; no CD.
8. **Untracked root `supabase/` dir** (CLI scratch from running `supabase link` at repo root instead of `backend/`) is **not** in `.gitignore` — a careless `git add .` would commit it. Delete it or ignore it.

### Architecture / duplication
9. **Search ranking implemented 3× in 3 languages** (`hybrid_scheme_search.dart`, `v1/search_engine.ts`, `saarthi-agent/src/hybrid_search.py`) + **4 physical copies** of `search_taxonomy.json`, kept in sync only by parity tests. Already drifted once (the `tax`/`exemption` query-expansion bug).
10. **`AppProvider` god object** (1977 lines) — auth, profile, tabs, bookmarks, search, filters, wizard, announcements, notifications, catalog sync behind one `notifyListeners()`; mitigated only by `context.select` and per-widget caching (`scheme_card.dart` comment complains about exactly this).
11. **Five overlapping search/understanding engines** in `frontend/lib/services/` — `hybrid_scheme_search` (primary), `intelligent_scheme_search` (separate voice ranker, duplicates normalization logic), `scheme_understanding_engine` (1333 lines), `official_grounded_search`, `private_ai_knowledge_base`.
12. **On-device SLM ambiguity** — `edge_model_pack.dart` / `edge_slm_runtime.dart` / `edge_slm_understanding_engine.dart` + the `llama_flutter_android: 0.2.6` dep are all present, but newer docs imply the offline path is lexical-only. Status undocumented; dead-code risk.
13. **`openapi/openapi.yaml` is fiction** — documents an unbuilt admin/sync API; none of the 12 live `/v1/*` routes appear in it; `/v1/health` shape mismatches. `openapi:lint` gives false confidence.
14. **`backend/scripts/import_catalog.mjs` is dead** — calls RPCs (`admin_import_scheme_catalog` / `admin_publish_scheme_catalog`) dropped in `20260818000000:276,279` and reads a non-existent input file. `npm run catalog:import|validate|bootstrap` all broken.

### Database
15. **Out-of-band DB objects not in any migration** — `catalog.mss_search`, `catalog.mss_search_document`, `catalog.mss_localized_text`, `public.rls_auto_enable`, and the `catalog.search_index.search_doc` **column** that `catalog.mss_search` queries (defined nowhere). A fresh replay silently skips these → **local dev / CI never has `catalog.mss_search`**, and its schema diverges from prod.
16. **Migrations edited after commit / after apply** — `20260805000000_database_architecture_v2.sql` was edited a day later (`fd01991`) to **strip `NOT NULL` / `UNIQUE` / FK constraints** from `catalog.authority.code`, `institution.code`, `scheme.scheme_code`, `scheme.government_level`, and the `finance/tax/export/csr/treds.scheme_id` FKs; the `primary_authority_id`/`primary_institution_id` FKs on `catalog.scheme` were **deleted** (now plain `text`, no referential integrity). `20260905080538` had 4 `ALTER TABLE ... RENAME` lines removed after they broke prod; its header states the committed file **no longer matches what ran**.
17. **Consecutive-migration contradiction** — `20260906020000` drops `profiles.street`/`village`/`address`; `20260907000000` re-adds `street`/`village` the next day.
18. **Malformed version strings** — `20260714061855/60/65` have invalid clock-seconds (`55/60/65`); work only because Supabase treats the 14 digits as an opaque key.
19. **`schema.sql` snapshot is stale even for its own stated date** — claims "through `20260904000000`" but is missing `20260904010000` and 19 later migrations; contains the broken `catalog.mss_search`.
20. **The 2026-08-18→09-01 hardening series (16 migrations) was committed but not applied to prod until 2026-09-04**; while unresolved, `chat_logs` (carrying profile PII from agent prompts) was world-readable via the app's publishable key. Now fixed; the recurrence guard `20260818000000` adds is in place.
21. **`pg_trgm` and `uuid-ossp` enabled but unused**; a GIN FTS expression index (`catalog_scheme_search_idx`) and an HNSW vector index exist but **nothing queries them** — the live search path is on-device.

### Code hygiene
22. **Massive screen/widget files** (see §9) — hard to review and untestable.
23. **`centralized_translator.dart`** — an 88 KB hand-maintained English→Tamil dictionary/sentence converter in code; brittle and unbounded.
24. **Swallowed exceptions** — `splash_screen.dart:214` `} catch (_) {}`, `auth_service.dart:102` `} catch (_) {}` (no log).
25. **Shipped mock data as production fallback** — `_defaultAnnouncements` / `_notificationsList` in `app_state_provider.dart:76-130`.
26. **Deep-link handling is a workaround, not a design** — `onGenerateRoute: (_) => null` + a no-op `onUnknownRoute`. Adding real deep links / web URLs later will hurt.
27. **`saarthi-agent/README.md` documents a "Supabase chat logging" feature with no code behind it** — the source tree is only `agent.py` + 4 catalog/search modules; `catalog_sync.py` is the only Supabase client and it is read-only. Git log shows a "Chat Logging System made" commit then a later refactor — appears reverted/relocated. Meanwhile `scripts/migrate_chat_logs.js` still assumes `chat_logs` is populated.
28. **Retired `search`/`recommend` functions remain deployed** (410 GONE); `README.md` warns not to redeploy them.
29. **`scripts/` is orphaned** — `migrate_chat_logs.js` + `test_migration.js` referenced by neither `package.json` nor CI; legacy env-var names.
30. **Python runtime spread** — 3.10–3.14 supported, Docker 3.14, dead CI 3.12, voice-lab CI 3.11; nothing pinned.
31. **`tools/` has no automated coverage except `voice-lab`**; the torch/peft/transformers deps for the edge-parser tools are unpinned (no `tools/requirements.txt`).
32. **Recurring count confusion** (217 / 219 / 1216 / 971) across code comments, `import_catalog.mjs` (`--expect-schemes=217`), and docs. Shipped `release.json` is authoritative: `1.34.3-alpha`, `entityCount 1220`, `scheme_catalog.json 219`, `searchIndexCount 971`, all 15 catalog files.

---

## 12. Doc Claims vs. Reality

Consolidated from all five investigations. **Bold verdict** = confidence after code check.

### Root `README.md` — describes a different, older app (**REFUTED wholesale**)
| Claim | Reality |
|---|---|
| "English & Hindi localization" | Locales are **`en` + `ta` (Tamil)**; `app_ta.arb` present, no Hindi ARB. |
| "Quick login via mobile number + OTP" | Auth is **Google OAuth** (`auth_service.dart`, Supabase OAuth deep-link `com.inschemes.app://login-callback`). No OTP code in `lib/`. |
| File structure: `profile_setup_screen.dart`, `find_my_schemes_screen.dart`, "17 core pages", "22 category cards", `splash_screen.png`, "Phase 1 seed data" | None exist. Onboarding is `basic_profile_screen.dart` (+ thin step re-exports); screens split `regular_mode/` + `companion_mode/`; assets are `.webp`; data comes from the catalog bundle. |
| "Thematic indigo-gradient background" | Palette is Royal Blue `#2563EB` + light-blue `blueGradient` (`utils/constants.dart:7,22-26`). `gradient_scaffold.dart` comment still says "indigo" but colors are blue. |

### `CLAUDE.md` — materially stale on the data layer (**partly REFUTED / OUTDATED**)
| Claim | Reality |
|---|---|
| "API client — `frontend/lib/services/mss_api_client.dart`. All 15 endpoints mapped" (Phase 2, "done") | **No such file exists** (grep-confirmed). The online API client was removed in the 2026-09-04 offline-first refactor; `SchemeRepository` is now offline-only. |
| Open issue #1: "`MssApiClient.defaultBaseUrl` defaults to `http://localhost:8000` … set nowhere" | Class gone. `dart_defines.json` now defines `MSS_API_BASE_URL` but **nothing in `lib/` reads it** — dead config. |
| Open issue #1: "every 'online-first' call silently falls back to the offline bundle" | There is no online-first path. Discovery reads `MssCatalogBundle` unconditionally. Offline-first is the **intended** design per the 2026-09-04 constraint amendment inside `CLAUDE.md` itself. |
| Open issue #2: "969 entities / 217 schemes", "bundle missing 5 of 15 catalog files", "217-vs-219 gap unexplained" | `frontend/assets/catalog/release.json` now lists **all 15** files, `entityCount 1220`, `scheme_catalog.json 219`, tag `1.34.3-alpha`. `mss_catalog_bundle.dart` `catalogKeys` enumerates all 15. **Issue resolved in the shipped asset** (in-code doc-comments and `CLAUDE.md` not updated). |
| Investigation notes: flat `models/`, `SchemeRepository` singleton, `package:http` only | **Confirmed.** |

### `docs/OFFLINE_FIRST_AND_RECOMMENDATION_ARCHITECTURE.md` — most accurate, one patch stale
| Claim | Reality |
|---|---|
| "Current release: `1.34.2-alpha` … 971 search-index records" | Shipped `release.json` is **`1.34.3-alpha`** (`releasedAt 2026-09-08`). Counts (1220 / 219 / 971) match. |
| §9 "The bundled asset is `1.34.0-alpha` (217 schemes)" | Shipped asset is `1.34.3-alpha` / 219. Stale note. |
| §11 module map lists `intelligent_scheme_search.dart` as "separate" | Confirmed — but the map understates the sprawl (`scheme_understanding_engine.dart`, `private_ai_knowledge_base.dart` also participate, not listed). |
| "`POST /v1/search` … planned path for the Saarthi voice agent" | Accurate as intent. The agent does **not** currently call it — `find_schemes` uses a **local** `HybridSearchEngine` over bundled JSON. |

### `docs/SEARCH_AND_CATALOG_ARCHITECTURE.md`
| Claim | Reality |
|---|---|
| §1 diagram: `v1` "reads `catalog.scheme` / `catalog.search_index` directly via SQL on every request" | It calls `SECURITY DEFINER` RPC `mss_search_data()` (`v1/index.ts:74`), which does the join — `catalog.*` is not exposed to PostgREST. Result equivalent; the RPC boundary is real. |
| Canonical taxonomy at `backend/catalog/search_taxonomy.json`; copies byte-identical | Confirmed (`_shared/search_taxonomy.json` sha1-identical). But there are **3** copies (+ the Dart app reads `frontend/assets/search/search_taxonomy.json`, a synced copy, not the canonical file). |
| Function inventory: `v1`, `livekit-token`, `publishCatalog`, `db-change-notify`, `search`+`recommend` retired | **Incomplete** — omits `sarvam-chat` and `rollbackRelease`, both live. |
| Rate limiting "persistent, backed by `public.api_rate_limits`", search fails closed | **Confirmed** (`20260828000000_persistent_rate_limiter.sql`). |

### `docs/DATABASE_ARCHITECTURE.md` (self-dated 2026-09-04) — high-level accurate, table detail substantially stale
| # | Doc says | Reality |
|---|---|---|
| D1 | `catalog.scheme.max_funding_amount` / `minimum_funding_amount NUMERIC(15,2)` | Column is `maximum_funding_amount`; **both dropped** by `20260908120000:49-50`. **Refuted.** |
| D2 | (no mention of `catalog.scheme.scheme_url`) | Added + mirrored to `record_json.content.schemeUrl` by `20260908120000`; "Apply Now" depends on it. **Missing.** |
| D3 | `authority.code` / `institution.code` / `scheme.scheme_code` are `TEXT (Unique)` | After `fd01991`: nullable, **not unique**; `scheme_code` also not `NOT NULL`. **Overstated.** |
| D4 | `catalog.search_index.scheme_id` is `Unique FK`; ERD implies 1:1 | `references catalog.scheme(id) deferrable initially deferred` — **no `UNIQUE`** (1:many possible). **Overstated.** |
| D5 | `catalog.finance/tax/export/csr/treds.scheme_id` mandatory FK | FKs are `DEFERRABLE INITIALLY DEFERRED` **and nullable**. **Partially refuted.** |
| D6 | ERD links `scheme` → `authority`/`institution` via `primary_*_id` FKs | `primary_authority_id` / `primary_institution_id` are **plain `text`, no FK** (`fd01991` removed them). **Refuted — no referential integrity.** |
| D7 | `public.chat_logs` is a current, locked-down table | Renamed `public._deprecated_chat_logs` by `20260905061235`; superseded by `voice_chat_sessions`. **Stale.** |
| D8 | `catalog.ai_metadata` is a live table | Renamed `catalog._deprecated_ai_metadata` by `20260905080538`. **Stale.** |
| D9 | `recent_schemes`, `ai_conversations`/`ai_messages`, `sync_history`, `search_logs`, `bug_reports`, `feature_requests`, `user_responses`, `question_options`, `beneficiary_categories` are current | **All 11 renamed `_deprecated_*`** by `20260905080538`. **Stale.** |
| D10 | (no mention of) `voice_chat_sessions`, `support_tickets`, `beta_gate_config`, `admin.permissions` | Created by `20260905000100` / `20260906000000` / `20260907100000` / `20260805000000:147`. **Missing.** |
| D11 | "known open item": `mss_scheme_detail()` etc. don't filter `status='PUBLISHED'` in the SQL body | **Fixed** by `20260904010000` (status filters added to 5 RPCs). **Outdated (closed).** |
| D12 | "known open item": missing FK/RLS-filter indexes | **Fixed** by `20260904010000:176-216`. **Outdated (closed).** |
| D13 | "one deliberate trigger exception" (only the row-checksum trigger) | **At least 5 trigger families**: `mss_recompute_row_checksum` (16 tables), `sync_entity_registry` (15 tables, `20260905122008`), `check_support_ticket_rate_limit`, `set_updated_at` (5 tables), `prevent_audit_mutation`. **Understated.** |
| D14 | `catalog.entity_registry` is the populated canonical index | `20260904000000` header: "never populated … appears unused"; `20260905122008` then backfills 1216 rows + adds the sync trigger. Doc mentions neither. **Incomplete.** |
| D15 | `FORCE RLS` set on `profiles`, `startup_profiles`, RBAC set incl. `beneficiary_categories` | `beneficiary_categories` was FORCE'd then renamed `_deprecated_*` by `20260905080538`; `rls_coverage_violations()` still names it → a permanently dead check. **Stale detail.** |
| D16 | `schema.sql` is "the resulting confirmed-live snapshot"; "all 16 were pushed" | `schema.sql` header says "through `20260904000000`"; missing `20260904010000` + 19 later migrations; contains broken `catalog.mss_search`. **Snapshot stale even for its own date.** |
| D17 | (no extension list) | `pg_trgm` + `uuid-ossp` enabled, both unused. **Missing / latent cruft.** |
| D18 | `admin.catalog_releases` "Immutable release manifestations" | The v1 immutability trigger was on the **dropped** `public.catalog_releases`; `admin.catalog_releases` has no such trigger and `mss_rollback_release` mutates `is_current`. **Overstated.** |
| — | High-level architecture (4 schemas, hybrid `record_json`, RLS-coverage guard, storage lockdown, RPC-layer pattern) | **Accurate.** |

### `backend/README.md`
| Claim | Reality |
|---|---|
| `backend/docs/` and `backend/voice/` directories exist | Neither exists. Docs are repo-root `docs/`; voice lab is `tools/voice-lab/`. |
| Deploy list: `v1`, `livekit-token`, `publishCatalog`, `db-change-notify` | Also live: `sarvam-chat`, `rollbackRelease`. |
| Publish via `select private.publish_scheme_catalog(...)`; roll back via `private.promote_catalog_release(...)` | Both **dropped** (`20260818000000:277-278`). Rollback is now `public.mss_rollback_release(uuid)` via the `rollbackRelease` function. |
| `npm run catalog:validate` / `catalog:bootstrap` for production import | `import_catalog.mjs` calls dropped RPCs and reads a non-existent input file. Non-functional. |
| OpenAPI admin/sync endpoints are "future milestones" | Correct — none implemented. |

### `backend/openapi/openapi.yaml`
| Claim | Reality |
|---|---|
| `GET /v1/health` → `{status:"ok", version}` | Code returns `{status: "ok"\|"degraded", db, catalog}`, no `version`. **Shape mismatch.** |
| `/v1/admin/schemes`, `/v1/admin/revisions/*`, `/v1/sync/schemes`, `/v1/sync/snapshot`, `/v1/admin/imports`, `/v1/admin/audit` | **No handler for any** in `v1/index.ts`. |
| — | Every actually-served route (`/v1/meta`, `/v1/search`, `/v1/schemes/{id}`, …) is **undocumented** in OpenAPI. The spec describes a different, unbuilt product. |

### `config.toml` inline comment
| Claim | Reality |
|---|---|
| "the Flutter client now sends apikey + Authorization on every call (see `frontend/lib/services/mss_api_client.dart`)" | That file **does not exist** and no Flutter code calls any `/v1/*` route. `v1/index.ts:1-12` correctly notes "no caller yet". |

### `docs/DEPLOYMENT_ARCHITECTURE.md` (dated 2026-08-17)
| Claim | Reality |
|---|---|
| "No CD pipeline deploys functions… Flutter app: no CI workflow at all… CI does not deploy anything" | Stale. `deploy-edge-functions.yml`, `deploy-voice-agent.yml`, `build-app.yml` exist (added ~2026-09-07, `workflow_dispatch`-only). `backend-database.yml` runs `supabase start` + `db:reset/test/lint` + `openapi:lint` + a `voice` job. |
| Edge functions deployed "manually via `supabase functions deploy`" | Now automatable via `deploy-edge-functions.yml` (still manual-trigger). |
| Recommends region `ap-south-1` (Mumbai) | `SEARCH_OPTIONS.md` and `Query_Expansion.md` state the project is on **`ap-southeast-2` (Sydney)**. Doc-vs-doc conflict; actual region not verifiable here. Capacity "sized for 500 users" has no recorded source (`STALE_DOCS.md` D1). |

### `docs/EDGE_AI.md`
| Claim | Reality |
|---|---|
| Active on-device Qwen3-0.6B parser as the offline path | Edge-SLM code + `llama_flutter_android 0.2.6` are in the tree, but newer docs imply the offline path is lexical-only. **Unreconciled — no authoritative status** (`STALE_DOCS.md` E1/E2). Gguf artifact distributed via GitHub Releases `github.com/Roger-Chris/IN_Schemes` tag `edge-ai-v1` (not verifiable here). This is a Flutter/Android feature, **not** part of `saarthi-agent`. |

### `saarthi-agent/README.md`
| Claim | Reality |
|---|---|
| Default LLM "Gemma 4 31B, hosted by LiveKit" | `agent.py:36,157,195` hardwire Sarvam `sarvam-105b-conversations`. Un-deleted `agent-starter-python` template boilerplate. |
| "Each conversation turn is written to Supabase `public.chat_logs`" | **No chat-logging code in `saarthi-agent/src/`** at HEAD. Only `catalog_sync.py` touches Supabase, read-only. Feature appears reverted/relocated. |

### `frontend/lib/services/scheme_repository.dart` doc-comments (in-code)
| Claim | Reality |
|---|---|
| `:265`, `:311`: "Online-first via POST /v1/search with offline fallback … memoized for 15s to prevent redundant network calls" | The code (`:300-306, 363-375`) has **no network path** — it calls `searchSchemeMatchesOffline` → `HybridSchemeSearch.rank` only. The memo/singleflight guards CPU work, not network. **Comment contradicts both the code and `OFFLINE_FIRST…md`.** |

### Loose root `.md` files — triage
| File | What it is | Status |
|---|---|---|
| `WORK_STATUS.md` (2026-09-04) | Session log for branch `fix/discover-counts-and-search-filter` | **Stale** — in-flight branch snapshot, a task tracker. |
| `STALE_DOCS.md` (2026-09-04) | Punch list of wrong numbers in architecture docs | **Report-only, partly actioned.** Its A1–A3 items vs `CLAUDE.md` remain unfixed. Still a useful checklist. |
| `CUTOVER.md` (2026-09-03) | Supabase legacy→new API-key migration runbook | **Current** — code still has `SERVICE_ROLE` fallbacks, matching the "staged, not deactivated" state. Its blast-radius table omits `db-change-notify`, `rollbackRelease`, `sarvam-chat`, and names a non-existent `schemes-api` function. |
| `SPACING.md` (2026-09-04) | Inventory of 1157 hardcoded spacing literals → `AppSpacing` rollout | **Historical** — rollout complete per last commit. |
| `SEARCH_OPTIONS.md` (2026-09-03) | Scoping of semantic-search options A/B/C; baseline 80.2% top-1 | **Current as rationale**; Option A has shipped. |
| `Query_Expansion.md` (2026-09-04) | Design + impl of Phase-4 Option A lexical query expansion | **Current** — documents the shipped feature. |
| `DEV_2_JOB_ASSIGNMENT.md` (2026-09-08) | Work package for "Developer 2" (shell nav, text-scale a11y, companion UI, typography) | **Possibly active.** Cites `main.dart` text-scale clamp at "lines 179–182"; `UI_UX_AUDIT_REPORT.md` cites "main.dart:L118-L135" for the same clamp — at least one is stale. Verify against current `main.dart`. |
| `Search_Index_Count_Bug_Context.md` (2026-09-04) | Context for the `release.json` `searchIndexCount` 1216-vs-971 bug | **Historical** — `WORK_STATUS` B1 marks it DONE (corrected to 971). No backend code reads `searchIndexCount`. |
| `UI_UX_AUDIT_REPORT.md` (2026-09-08) | 34 KB forensic UI/UX/a11y audit dated 2026-09-07 | **Mixed** — recent, but no fix-status tracking; some findings already addressed. File paths reference another author's machine (`c:/Users/paul/...`). |

### Confirmed accurate
- `.mcp.json` project ref `houpzsxmwemoztpuigmo` matches the real Supabase project (consistent with `CUTOVER.md`, workflows, memory).
- `frontend/README.md` mechanics (`run.sh`/`run.ps1` subcommands, `.vscode/launch.json` config names) match the files exactly.
- `SEARCH_AND_CATALOG_ARCHITECTURE.md` claims about persistent fail-closed rate limiting, the 3× search implementation, and byte-identical taxonomy copies — all confirmed against code.
- `CLAUDE.md`'s core investigation notes (flat `models/`, `SchemeRepository` singleton, `http` only) — confirmed.

---

## Appendix — Investigation Coverage

| Area | Verified against | Not covered / caveats |
|---|---|---|
| Flutter frontend | `pubspec.yaml`/`.lock`, `lib/**`, `analysis_options.yaml`, `l10n.yaml`, ARB files, `run.*` | Build not executed; `flutter analyze`/`test` not run. |
| Supabase backend | `functions/**`, `config.toml`, `deno.lock`, `package.json`, `openapi/`, `catalog/`, `scripts/` | Functions not executed; live deployment state not observable. |
| Database | 76 migration files, `schema.sql`, `seed/`, pgTAP tests | **Live project `houpzsxmwemoztpuigmo` not queryable from here.** Prod may differ from tracked migrations (documented drift). |
| saarthi-agent + tooling | `pyproject.toml`, `uv.lock`, `src/**`, `Dockerfile`, `.github/workflows/**`, `tools/**`, `scripts/**`, root config | Agent not run; GitHub repo branch-protection settings not inspectable. |
| End-to-end trace | Followed code `frontend/lib/**` → `backend/supabase/**` for the scheme-search flow | Chose scheme search as the canonical flow; other flows (sign-in, voice session) traced only where they intersect. |
