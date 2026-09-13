# Search Ranking & Catalog Data Architecture

**Audience:** any developer picking up this codebase after the 2026-09
audit-fix work. This is the authoritative "how it actually works, and why
it's built this way" reference for two things that used to be duplicated
across the codebase and silently drifted out of sync: **the search ranking
engine** and **the catalog data each service reads**.

If you're about to add a fourth place that declares scheme-search logic, or
a service that reaches into `catalog.*` tables directly instead of going
through the documented paths below — stop and read this first. This exact
mistake already happened once (see "History: what went wrong before" at the
bottom) and cost a multi-session audit to find and fix.

---

## 1. The core principle

There is **one search ranking algorithm**, implemented three times (once per
runtime), and **one catalog release**, consumed by three services in three
different ways. Every place this document says "one X, N copies," the
reason is always the same: **each runtime has a different deployment
model that makes a single shared file physically impossible**, so instead
of fighting that, each copy is kept honest by an automated **parity test**
that fails CI the moment the copies disagree.

```
                    ┌─────────────────────────┐
                    │   Supabase (source of    │
                    │   truth for catalog data)│
                    │  catalog.* tables,       │
                    │  admin.catalog_releases  │
                    └────────────┬─────────────┘
                                 │ publish (Storage bucket `catalogs`)
                                 │ releases/<version>/catalog_bundle.json.gz
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
     Flutter app          v1 edge function     Saarthi voice agent
   (mobile, offline-    (Deno, Supabase Edge   (Python, LiveKit
    first, ships a         Functions, reads      worker process,
    build-time bundle,     catalog.scheme /       ships a build-time
    OTA-syncs a fresher     catalog.search_index    bundle, syncs a
    one at runtime)         directly via SQL)       fresher one at
                                                     startup)
```

Each of the three runtimes above has **its own copy** of:

1. **The search ranking parameters** (taxonomy tables, weights, IDF regex,
   query expansions) — see §2.
2. **The catalog data itself** (scheme records + search-index profiles) —
   see §3.

Both are guarded by parity tests. Never edit one copy without also updating
its siblings and re-running the parity suite (§4).

---

## 2. The search ranking engine

### 2.1 Where it lives

| Runtime | File | Role |
|---|---|---|
| TypeScript (Supabase Edge Function) | `backend/supabase/functions/v1/search_engine.ts` | Server-side `/v1/search` route |
| Dart (Flutter app) | `frontend/lib/services/search/hybrid_scheme_search.dart` | Offline, on-device search — the actual live search path for regular users today |
| Python (Saarthi voice agent) | `saarthi-agent/src/hybrid_search.py` | Voice-driven catalog lookup (`search_scheme_catalog` tool) |

All three implement the **exact same algorithm**: taxonomy-based query
tagging → IDF-weighted keyword scoring → category/eligibility/benefit/
semantic sub-scores → a weighted sum → a status-aware multiplicative factor
→ deterministic sort (score desc, then scheme ID asc as a tiebreak). This is
a direct, field-for-field, method-for-method port across all three
languages. **It is not three independently-tuned rankers that happen to look
similar** — if you find yourself improving the ranking quality in only one
of these files, you are re-introducing the exact bug this session fixed.

### 2.2 The shared parameters (single source of truth)

All of the tunable inputs — `SHORT_TOKEN_VOCAB`, the 6 taxonomy tables
(industries/benefits/collateral/treds/communities/intents),
`RELATED_CONCEPTS`, `WEIGHTS`, `STATUS_FACTOR`, `STATUS_TO_CONCEPT`, the
token regex, `semanticQueryGroups`, and `queryExpansions` — live in exactly
**one canonical JSON file**:

```
backend/catalog/search_taxonomy.json
```

**Never hand-edit a value in `search_engine.ts`, `hybrid_scheme_search.dart`,
or `hybrid_search.py`/`search_taxonomy.py` directly.** Edit the canonical
file, then copy it over each runtime's local copy:

| Runtime | Local copy | Why not just import the canonical file directly? |
|---|---|---|
| TS | `backend/supabase/functions/_shared/search_taxonomy.json` | Supabase Edge Function deployment bundles `supabase/functions/**`; a relative import reaching outside that tree is unverified and risky to rely on for a deployed function. `_shared/` is inside the tree and already proven to deploy correctly (`_shared/cors.ts` uses the same pattern). |
| Dart | `frontend/assets/search/search_taxonomy.json` | Flutter's asset bundler was tested with a `../` path reaching outside the project tree (see the `pubspec.yaml` asset declaration history) — it built for web but landed the file *outside* the normal `assets/` prefix in the output, an inconsistency that isn't safe to assume also works correctly for a real Android/iOS build. A conventional in-tree asset avoids that risk entirely. |
| Python | `saarthi-agent/data/search_taxonomy.json` | The Saarthi Docker image's build context is scoped to `saarthi-agent/`; it cannot see `backend/catalog/` at build time. |

Each runtime keeps `queryExpansions` **inside** `search_taxonomy.json` too
(TypeScript and Python read it from there); Dart continues to read a
parallel `frontend/assets/search/query_expansion.json` for historical
reasons, and a parity test asserts the two stay byte-identical (§2.4).

### 2.3 Updating a shared parameter — the procedure

1. Edit `backend/catalog/search_taxonomy.json` only.
2. Copy it over all three local copies:
   - `backend/supabase/functions/_shared/search_taxonomy.json`
   - `frontend/assets/search/search_taxonomy.json`
   - `saarthi-agent/data/search_taxonomy.json`
3. If you touched `queryExpansions`, also update
   `frontend/assets/search/query_expansion.json` to match.
4. Regenerate the golden parity fixture (§2.4) if the change is intended to
   alter ranking output. If it isn't supposed to change output, the parity
   tests should still pass unmodified — if they don't, you've found a bug.
5. Run all three engines' test suites (Dart, Deno, pytest) before
   committing.

### 2.4 Parity tests — what actually catches drift

Three parity test files, one per language, each doing the same two checks:

| Test file | Checks |
|---|---|
| `frontend/test/search_taxonomy_parity_test.dart` | (1) local `search_taxonomy.json` byte-equals the canonical copy. (2) local `queryExpansions` byte-equals `query_expansion.json`. (3) `HybridSchemeSearch` reproduces the golden fixture. |
| `backend/supabase/functions/v1/search_engine_parity_test.ts` | Same three checks for the TypeScript engine. |
| `saarthi-agent/tests/test_hybrid_search_parity.py` | Same three checks for the Python engine. |

The **golden fixture**, `backend/catalog/search_parity_golden.json`, is a
recorded set of `{query, results: [{schemeId, score}]}` entries for 25 fixed
queries (seeded from `frontend/test/hybrid_search_quality_test.dart`), run
once against real catalog data through one engine (Dart, at the time this
was built) and checked into the repo. All three engines are asserted
against this **same fixture** — not against each other directly — so a
CI failure always names exactly which engine diverged and from what
expected output.

**If you deliberately change the ranking algorithm** (not just the
taxonomy data, the actual scoring logic), you must regenerate this fixture
from whichever engine you consider authoritative, then re-verify the other
two still match it. There is a throwaway-test-based procedure for this in
the commit history (search for `_dump_parity_fixture_test.dart` in git log)
— it loads the real catalog bundle, runs the 25 queries, and writes the
JSON. Do this deliberately, never as a side effect of "the test was
failing so I updated the fixture."

**This exact mechanism already caught one real, pre-existing bug**:
`search_engine.ts`'s hardcoded `QUERY_EXPANSIONS` had silently drifted from
`query_expansion.json`, missing "tax" and "exemption" entries. The
deployed server had been ranking tax-related voice/API queries measurably
worse than the offline app, with zero errors and zero test failures, for
an unknown length of time — because nothing was comparing the two files'
*content*, only their *existence*. Don't remove or weaken these tests to
make a change land faster.

---

## 3. Catalog data: source of truth, publishing, and sync

### 3.1 Source of truth

The canonical catalog data lives in Supabase Postgres, schema `catalog`:
15 per-type tables (`catalog.scheme`, `catalog.authority`,
`catalog.institution`, `catalog.finance`, `catalog.tax`, `catalog.treds`,
`catalog.csr`, `catalog.export`, `catalog.knowledge`,
`catalog.applicability_matrix`, `catalog.enterprise_classification`,
`catalog.msme_privilege`, `catalog.business_enablement`,
`catalog.cluster_assistance`, `catalog.common`), plus
`catalog.search_index` (a derived, flat search-only projection —
`schemeSearchProfile` + tokenized `tokens.en`/`tokens.ta` per entity) and
`catalog.entity_registry` (canonical entity index, kept in sync via
triggers — see `docs/DATABASE_ARCHITECTURE.md` §3.1 for the full schema).

**`catalog.*` is never exposed to PostgREST directly** (no
`Access-Control-Allow-Origin`, no anon/authenticated grants on the schema
itself). All read access goes through `public`-schema `SECURITY DEFINER`
RPC functions (§5) or through the `v1` Edge Function, which queries
`catalog.*` using the service-role client.

A **release** is a point-in-time, immutable snapshot of that data,
tracked in `admin.catalog_releases` (`release_version`, `package_sha256`,
`package_byte_size`, `schema_version`, `record_counts`, `published_at`,
`is_current`, `status`). The current release's identity is exposed
through one lightweight, anon-callable RPC:

```sql
select * from public.mss_current_release();
-- returns: release_version, package_sha256, package_byte_size,
--          schema_version, record_counts, published_at
```

This RPC is intentionally cheap — a single-row lookup, no joins across
the 15 catalog tables — specifically so every consumer can check "is my
local copy current?" without the cost of diffing actual content. **Use
this RPC for any future version-check need; do not invent a second one.**

The actual release **artifact** (`catalog_bundle.json.gz` — a gzip'd JSON
containing all 15 catalogs + `search_index.json` + a manifest) is
published to Supabase Storage:

```
bucket: catalogs
path:   releases/<release_version>/catalog_bundle.json.gz
```

### 3.2 How each consumer gets the data

#### Flutter app (the reference implementation — copy this pattern, don't reinvent it)

- **Build-time bundle**: `frontend/assets/catalog/catalog_bundle.json.gz`,
  declared in `pubspec.yaml`, always present, always the fallback of last
  resort.
- **Runtime sync**: `frontend/lib/services/scheme_catalog_sync_service.dart`
  (`SchemeCatalogSyncService` + `SupabaseCatalogReleaseSource`):
  1. Calls `mss_current_release()`.
  2. Compares the result against the locally installed manifest
     (`SchemeCatalogStore`'s `readActiveManifest()`) by
     `release_version` **and** `sha256` (`CatalogManifest.sameReleaseAs`).
  3. If unchanged: does nothing.
  4. If changed: downloads `releases/<version>/catalog_bundle.json.gz`
     from the `catalogs` Storage bucket, verifies its SHA-256, and installs
     it via `SchemeCatalogStore.install()`.
  5. Throttled to once per hour (`Duration(hours: 1)`), tracked via an
     in-memory `_lastCheck` timestamp on a process-lifetime singleton —
     safe for Flutter because a mobile app process genuinely lives for the
     whole user session.
- **Load path**: `MssCatalogBundle.load()` prefers the installed OTA
  release if present and its checksum re-verifies; falls back to the
  shipped asset on any failure. See §2.4 of
  `docs/handoff/architecture_docs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` for
  the full state machine.

#### `v1` Edge Function (TypeScript)

Does **not** sync a file at all — it's a stateless server function that
queries `catalog.scheme` / `catalog.search_index` directly via SQL on every
request, using the service-role client. There is no "stale copy" problem
here because there is no copy; the query always sees the current
production data. This is the simplest of the three consumers by
construction.

#### Saarthi voice agent (Python)

Mirrors the Flutter pattern almost exactly — see
`saarthi-agent/src/catalog_sync.py` (`CatalogSyncService`):

1. Calls `mss_current_release()` via a direct REST call (`aiohttp`,
   `POST {SUPABASE_URL}/rest/v1/rpc/mss_current_release`) — there's no
   `supabase-py` dependency in this project, so this is a thin manual
   HTTP client, not a SDK wrapper.
2. Compares against a local manifest sidecar file,
   `saarthi-agent/data/catalog_manifest.json` (not committed —
   see `.gitignore`).
3. If unchanged: does nothing. If changed: downloads the same
   `catalog_bundle.json.gz` from the same Storage bucket, verifies SHA-256,
   extracts `scheme_catalog.json` and `search_index.json` (filtered to
   `entityType == 'scheme'`, matching `MssCatalogBundle`'s own filter) and
   overwrites the local files.
4. Throttled to once per hour — but **persisted to disk**
   (`saarthi-agent/data/last_sync_check.json`), not held only in memory.
   This is the one deliberate deviation from the Flutter pattern: LiveKit
   may run each job in its own subprocess (`AgentServer.setup_fnc` receives
   a `JobProcess`), so an in-memory timestamp on a Python object cannot be
   trusted to survive between jobs the way a mobile app's process-lifetime
   singleton can. If you ever confirm the worker process model is
   long-lived and single-instance, the disk persistence is still correct
   (and harmless) — do not remove it without first proving the process
   model has changed.
5. Wired into `agent.py` via `server.setup_fnc`, which LiveKit calls once
   per worker process before it starts accepting jobs — the closest
   equivalent to "at app startup."
6. **Never blocks or crashes startup.** Every failure mode (network,
   timeout, checksum mismatch, schema-version incompatibility) logs a
   warning and leaves whatever's already on disk untouched. The Docker
   image's bundled copy of `scheme_catalog.json`/`search_index.json` is
   always the fallback of last resort, exactly like Flutter's bundled
   asset.

**If you build a fourth consumer of this catalog** (a new service, a new
client), follow this same three-step shape: cheap version check via
`mss_current_release()` → conditional download from the `catalogs` bucket
→ checksum verify before installing → throttled, disk-or-process-lifetime
persisted, never blocking startup on failure. Do not invent a different
sync protocol.

---

## 4. API routing (Supabase Edge Functions)

All HTTP routes are Deno-based Supabase Edge Functions under
`backend/supabase/functions/`:

| Function | Purpose |
|---|---|
| `v1` | The real API gateway — `/v1/meta`, `/v1/health`, `POST /v1/search`, `/v1/schemes/{id}[...]`, etc. Deployed as a function literally named `v1` so the client's hardcoded `/v1/meta` path resolves through Supabase's `.../functions/v1/v1/meta` routing quirk — see the header comment in `v1/index.ts` before renaming anything. |
| `livekit-token` | Issues LiveKit room tokens for the voice agent, after authenticating the caller's Supabase session and attaching their profile as job metadata. |
| `publishCatalog` | Broadcasts a realtime `catalog_sync` channel event after a new release is published — a notification hook, not a data-import function. Requires presenting the service-role key itself (not just a valid user session) since it's meant only for trusted backend/admin callers. |
| `rollbackRelease` | Promotes a previous catalog release by UUID via `public.mss_rollback_release(uuid)` and broadcasts a catalog sync event. Requires service-role authentication. |
| `sarvam-chat` | Proxies conversational queries to Sarvam AI text chat completion API with temperature, token ceiling, and rate limiting. |
| `db-change-notify` | Generic Postgres-trigger-driven realtime broadcaster. |
| `search`, `recommend` | **Retired** (`410 GONE`) — kept only so old clients get a clear error instead of a 404. Do not resurrect these; their target RPCs (`search_schemes`, `recommend_schemes`) were dropped as dead code. |

**Shared code lives in `backend/supabase/functions/_shared/`** — anything
placed there is available to every function (it's inside the deployment
tree, per §2.2's table). Currently: `cors.ts` and `search_taxonomy.json`.

### 4.1 CORS

Every function computes its CORS headers **per request**, not once at
module load, via `_shared/cors.ts`'s `buildCorsHeaders(req)`. It reflects
the request's `Origin` header only if it matches an explicit allowlist
(currently: localhost dev origins; the Flutter app itself sends no
`Origin` header at all, so it needs no entry). Any origin not on the list
gets **no** `Access-Control-Allow-Origin` header at all — not a wildcard.

If a real production web origin needs access, add it to
`ALLOWED_ORIGINS` in `_shared/cors.ts`. **Never revert to `'*'`** — that
was finding 3.1 in the original audit, already fixed once.

### 4.2 Rate limiting

`v1/index.ts` enforces a global per-IP rate limit (`RATE_LIMITS`,
persistent, backed by `public.api_rate_limits`) on every route except
`/v1/health` (exempted so uptime probes never consume budget), plus
tighter per-minute/per-day/global-per-day limits specifically on
`POST /v1/search`, since that route pulls the full corpus and carries
essentially all of the egress cost. All three limits fail **closed**: if
the rate-limit check itself can't be evaluated, the request is rejected,
not allowed through.

---

## 5. DB requesting patterns

### 5.1 The RPC boundary

Nothing outside `public`-schema `SECURITY DEFINER` functions (or the
service-role-authenticated Edge Functions) ever touches `catalog.*`,
`admin.*`, or `private.*` directly. Client code — Flutter, the voice
agent, any future consumer — calls a `public.mss_*` RPC or hits `/v1/*`;
it never runs raw SQL against `catalog.scheme` etc. This is deliberate
defense-in-depth, not an accident: several `catalog.*` functions
(`mss_search`, `mss_localized_text`, `mss_search_document`) are themselves
**out-of-band objects** — created directly against production, not by any
tracked migration (see `20260829160000_harden_exposed_functions.sql`'s
`to_regprocedure(...) is not null` guards, and the correction migration
`20260905080758`/`20260905111658` this session had to write after
discovering that "0 code references" checks that only grep app source
directories miss references living inside SQL function bodies). **If you
write a migration that revokes or alters a function/table based on a
"nothing references this" grep, also grep the migrations directory itself
for `CREATE OR REPLACE FUNCTION` bodies, and check `pg_get_functiondef()`
against production directly** — a source-tree grep is not sufficient
evidence of "unused."

### 5.2 RLS posture

Every `public`-schema table with user data has RLS enabled and **forced**
(`FORCE ROW LEVEL SECURITY`) — see `docs/DATABASE_ARCHITECTURE.md` §5 for
the full policy inventory and the `rls-drift-check.yml` workflow that
guards it weekly. `catalog.*` tables don't need RLS at all (they're never
exposed to PostgREST), but **do** carry triggers
(`catalog.sync_entity_registry`) that keep `catalog.entity_registry` in
sync with the 15 per-type tables automatically — see §3.1 above and the
migration `20260905122008_populate_and_sync_entity_registry.sql` for why
this exists (the originally-planned import function,
`admin_import_scheme_catalog`, does not exist in this database; the
trigger approach was chosen specifically so a manual backfill wouldn't go
stale the next time someone publishes a release through whatever
out-of-band process currently loads the 15 catalog tables).

### 5.3 Table archival is a rename, not a drop — and isn't free

Zero-row, zero-*app-code*-reference tables in this codebase are archived
by `RENAME TO _deprecated_<name>`, never dropped, specifically because a
prior archival pass renamed 4 tables
(`organization_memberships`, `user_roles`, `regions`, `user_regions`) that
turned out to be referenced by `SECURITY DEFINER` RLS-helper functions
(`private.has_role`, `private.has_region`, `private.belongs_to_organization`)
— breaking those functions in production with zero live user impact only
because nothing was calling them yet. **Before archiving any table, grep
`pg_proc` definitions in production (not just the source tree) for its
name.** The migration `20260905111658_restore_load_bearing_rbac_tables.sql`
is the fix-forward correction for this exact mistake; read it before
repeating the pattern.

---

## 6. History: what went wrong before (so it doesn't happen again)

This document exists because, before the 2026-09 audit-fix work:

- **Search ranking** was implemented three times independently, with no
  automated check that they agreed. The TypeScript copy's query-expansion
  dictionary silently drifted from the Dart copy's, degrading server-side
  search quality for an unknown period with zero errors.
- **The voice agent's catalog** was a snapshot frozen at Docker-build
  time, with no sync mechanism at all — the "three-week-stale catalog"
  problem.
- **CORS** was `'*'` everywhere.
- **A table archival pass** archived load-bearing tables because its
  "is this referenced anywhere" check only grepped application source
  code, not SQL function bodies.
- **A migration's own "already-verified `0` references" claim** turned out
  to be based on an incomplete grep scope (missed `backend/supabase/tests/`
  and `backend/supabase/seed/`), breaking `db:reset`/`db:test` in CI.

None of these were caught by manual review at the time they landed. All
of them were eventually caught by either (a) a parity/equality test that
compares two things that are supposed to agree, or (b) actually running
`db:reset`/`db:test`/`pytest`/`flutter test` against a fresh environment
instead of trusting that "it worked before." **When you build something
new that's supposed to have exactly one source of truth across multiple
runtimes, build the parity test in the same change, not as a follow-up.**
