# MSS Backend Baseline Report — Phase B0

**Generated:** 2026-08-16
**Scope:** MSS intelligence backend (catalog pipeline, Supabase, API layer) — explicitly not Flutter/UI.
**Rule followed:** read-only inspection only; no code, schema, or data changes made while producing this report.

---

## 0. How to read this report

Per the roadmap this baseline is being written under, backend work should proceed from an honest snapshot of *actual* current state — not a fresh-start fiction. Two of the roadmap's standing rules were already crossed **before** this report was requested, during the same session, at explicit user instruction:

- **"DO NOT TOUCH FLUTTER"** — `frontend/lib/services/mss_api_client.dart`'s `defaultBaseUrl` was changed from `http://localhost:8000` to the live Supabase Edge Function gateway. This is the only Flutter change made.
- **"DO NOT CONNECT SUPABASE UNTIL SCHEMA IS APPROVED"** — the `catalog.*`/`admin.*` schema (already fully specified in `MSS_ANTIGRAVITY_HANDOFF/architecture_docs/DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md`, previously undeployed) was deployed to the live project, and 10 of the 15 current catalog files were imported into it.

Both are recorded below as part of the baseline, not hidden or rolled back. Everything from here forward should treat this as the starting line.

---

## 1. Catalog Version

| Field | Value |
|---|---|
| `releaseTag` (offline bundle) | `1.33.0-alpha` |
| `schemaVersion` | `1.0.0` |
| Offline bundle `releasedAt` | `2026-08-15T18:09:12Z` |
| Offline bundle `entityCount` | **1216** |
| Offline bundle `bundleSha256` | `ccc3251ae2dccaf04039b4148a719717e6f0593d85dc4b1e6a223695896ee9d7` |
| Offline bundle size (compressed / uncompressed) | 830,274 bytes / 10,763,417 bytes |
| Supabase `catalog.*` live entity count | **971** |
| Supabase `catalog_version` (`mss_catalog_meta()`, live at report time) | `771c5c63cf4debf2` |
| Supabase `catalog_checksum` (full) | `771c5c63cf4debf279a2ba197d06d1fe286e08696b1be9a34949feb4e78a88ba` |

### ⚠️ Finding: offline bundle and Supabase are no longer the same dataset

The offline bundle was regenerated (18:09 UTC) with **5 catalog files that were never imported into Supabase**:

| File | Entities | In Supabase? |
|---|---:|:---:|
| `applicability_matrix_catalog.json` | 219 | ❌ no table exists |
| `enterprise_classification_catalog.json` | 11 | ❌ no table exists |
| `msme_privilege_catalog.json` | 1 | ❌ no table exists |
| `business_enablement_catalog.json` | 4 | ❌ no table exists |
| `cluster_assistance_catalog.json` | 10 | ❌ no table exists |
| **Total missing** | **245** | |

971 (Supabase) + 245 (missing) = 1216 (offline bundle) — reconciles exactly. The 10 catalogs that *are* in Supabase (`common`, `authority`, `institution`, `scheme`, `finance`, `tax`, `treds`, `csr`, `export`, `knowledge`) match the offline bundle's per-file counts exactly for those 10 — no drift there, only the 5 newer catalogs are absent. This is the immediate, concrete violation of the roadmap's "Identical Dataset Guarantee" (§1.2) to resolve in B4/B5.

---

## 2. Package / File Hashes

SHA-256 of each current source file in `Plan/catalog/` (the canonical pipeline output directory), computed directly from disk at report time:

| File | SHA-256 | Bytes |
|---|---|---:|
| `common_catalog.json` | `518d0ea18a22f3d8e549875531d8a8b29c722e77af181cf232a3f1eccf2985cd` | 2,230,621 |
| `authority_catalog.json` | `8ab4f75ccb610b3df5b2b9e300ddcc1dde793c670367bc040d29067bfdf5abd9` | 1,095,398 |
| `institution_catalog.json` | `1d2a4c82e69be9f30123598eca03d7ac8508b1013fadb5f085a6e547e4227919` | 649,267 |
| `scheme_catalog.json` | `a4abac629b641cc04c26f929f8d07f95e96a11176e99cabc26729f4e544888b9` | 7,368,610 |
| `finance_catalog.json` | `c6c44dbb3352944928a985f498f942aa723fe8bc500076e728778698d8ec6670` | 1,423,747 |
| `tax_catalog.json` | `94b1a6f422c51f1850297df675e1cb92c016ae8e0639974b076d6ff4bbb5aaf4` | 125,388 |
| `treds_catalog.json` | `b757bc4efbc42d48502a010e458021dda5b4f5f77260ec286139e0d2936dd0a2` | 132,578 |
| `csr_catalog.json` | `9869be253dda2f6e8e00feb2519577aea1064e0482b0033956e62f397779b36c` | 138,184 |
| `export_catalog.json` | `a23bf20b470a15e6d021b8a746c2705aacec649d9b5e64c09f24b552680552d9` | 141,797 |
| `knowledge_catalog.json` | `5e989164f61e9ccb64adc3d07ea56594669fdd9a9413afbf8d8b3cf888ff569d` | 265,643 |
| `applicability_matrix_catalog.json` | `53a801913a249180b5f085863e56ed4b12c3a8f0d724a062a43f2916eac3c65e` | 894,710 |
| `enterprise_classification_catalog.json` | `906e0bbd49e30c1a8b06933bda2d7ce2aa87786db176a369f79b23ab7e1bfcf2` | 47,739 |
| `msme_privilege_catalog.json` | `92208bfaa9cebb5130fa52b5addb320df73bccc25c5c5ba281ba194604ce1c95` | 8,813 |
| `business_enablement_catalog.json` | `f8cfabf5227215ec8e88c2ae336b790b70648ec19bc273562873df3e629f6f30` | 24,577 |
| `cluster_assistance_catalog.json` | `70cd4def3795be99067596728dfd70e0e621bba4072091544642686cb7f6553e` | 77,260 |
| `search_index.json` | `5fb4d8213a041928497179367d018e33acd8a6aba441d08af23227e633d32eee` | 2,054,551 |

No `perFileSha256` field exists yet in `release.json` (only the aggregate `bundleSha256` over the compressed asset) — this is the B2 gap: the manifest schema needs the per-file hash map added.

---

## 3. API Endpoint Status

Live-tested against `https://houpzsxmwemoztpuigmo.supabase.co/functions/v1` at report time:

| Documented route | Status | Notes |
|---|---|---|
| `GET /v1/schemes` | ❌ 404 | Not implemented anywhere |
| `GET /v1/schemes/{id}` | ❌ 404 | Not implemented anywhere |
| `GET /v1/search` | ❌ 404 | Not implemented anywhere |
| `GET /v1/finance-products` (finance) | ❌ 404 | Not implemented anywhere |
| `GET /v1/tax` | ❌ 404 | Not implemented anywhere |
| `GET /v1/clusters` | ❌ 404 | Not implemented anywhere |
| `GET /v1/relationships/{id}` | ❌ 404 | Not implemented anywhere |
| `GET /v1/localization/{id}` | ❌ 404 | Not implemented anywhere |
| `GET /v1/privileges` | ❌ 404 | Not implemented anywhere |
| `GET /v1/meta` | ✅ 200 | Built this session; live-computed from `catalog.*` checksums |
| `GET /v1/health` | ✅ 200 | Built this session |

**Deployed Edge Functions** (`supabase functions list`): only `v1` (built this session) and `livekit-token` (unrelated voice feature) are actually live. `schemes-api` and the 8 placeholder functions (`buildCatalog`, `checkCatalogVersion`, `downloadCatalog`, `exportCatalog`, `generateManifest`, `publishCatalog`, `rollbackRelease`, `validateCatalog`) exist only as source files in `backend/supabase/functions/` — **none of them have ever been deployed**. `schemes-api` 404s because it isn't deployed, not because of a runtime error (correcting an earlier session note that assumed it would 500).

**Net finding for B1**: essentially the entire documented `/v1/*` API contract needs to be built from scratch. `/v1/meta` and `/v1/health` are the only functioning parts of it today.

---

## 4. Search Benchmark

Source: `Plan/catalog/benchmark_v1_results.json`, last generated **2026-08-15T23:37** (most recent of 8 dated result snapshots on disk — `_BASELINE`, `_FIX1`, `_FIX2`, `_D5_FIX3`, `_ROUND3`, etc. — history exists but is not summarized here).

| Metric | Value |
|---|---:|
| Total queries | 210 |
| Scored | 177 |
| Data gap | 29 |
| Unscored | 4 |
| **Top-1 relevance** | **80.2%** |
| Top-1 exact | 74.0% |
| **Top-5 recall** | **92.1%** |
| Generic domination | 1.1% |
| Closed-scheme apply leakage | 0 |
| Closed at Top-1 | 6/210 |
| Closed in Top-5 | 28/210 |
| Unexplained results | 0 |
| Trap total / data-gap / pass | 10 / 3 / 57.1% |

This matches the roadmap's stated non-regression targets (~80% Top-1, ~92% Top-5) almost exactly — **use these two numbers as the literal B10 regression floor**, not the roadmap's rounded approximations.

This benchmark was run against the **offline Python search engine** (`hybrid_search.py`), not any backend service — B6 (backend search service) does not exist yet to benchmark separately.

---

## 5. Validator Status

Present in `Plan/catalog/`: `validate_base.py`, `validate_catalog.py`, `validate_cross_catalog.py`, `validate_i18n.py`, `validate_provenance.py`.

**Not executed as part of this report.** This environment has no Python runtime available (`python3` / `python` both fail to resolve), and B0 is scoped to read-only inspection — installing a runtime was judged out of scope for a baseline snapshot. No historical validator-run log/report file was found on disk to cite instead. **This is a real gap**: validator pass/fail state is currently unknown and should be established as an early B1 or B10 task (in an environment with Python available) rather than assumed.

---

## 6. Supabase Schema & Migration State

28 migrations applied, most recent 6 from this session:

1. `20260731120000_create_promo_alerts.sql`
2. `20260805000000_database_architecture_v2.sql` — the `catalog.*`/`admin.*` schema (see §0)
3. `20260806113000_self_delete_user.sql`
4. `20260812112500_profiles_self_insert_policy.sql` *(pre-existing, applied out-of-order before this session)*
5. `20260815120000_enable_realtime_profiles_notifications.sql`
6. `20260816130000_recreate_promo_alerts.sql` — fixes a bug where migration #2 above drops `promo_alerts` without recreating it
7. `20260816140000_catalog_meta_function.sql` — adds `public.mss_catalog_meta()`

`public.profiles` currently has permanent, non-nullable-by-default columns for `gender`, `community`, `disability`, `veteran` with no anonymization or explicit-opt-in gating mechanism. Flagged for B9 — conflicts with the roadmap's stated privacy rule ("never store caste/gender/personal profile permanently unless user explicitly chooses").

`admin.catalog_releases` / `admin.catalog_files` (the spec's release-snapshot tables) exist but are **empty** — this session's `/v1/meta` uses a live-recompute approach instead (see §3), not a versioned release/publish workflow. B2/B5 need to decide whether to adopt the release-snapshot model or formalize the live-recompute model.

---

## 7. Flutter / Client State (for context only — not a target of backend work)

- `flutter analyze`: clean, no issues.
- `flutter test`: 141 passing, 4 pre-existing failures unrelated to any change made across this or prior sessions (sandbox/network `SchemeRepository.instance` construction issues in the test harness itself).
- `MssApiClient.defaultBaseUrl` now points at the live `/v1` gateway (see §0). No other Flutter file has been touched in service of backend work.
- The full `/v1/*` client contract (schemes, search, finance, clusters, tax, privileges, relationships, localization) is coded and ready to consume a real backend the moment B1 delivers one — no client-side blocking work expected for those routes.

---

## 8. Summary — What B0 establishes as "current state"

- Offline bundle: 1216 entities, versioned, hashed, working (this is what the shipped app actually runs on).
- Supabase: 971/1216 entities mirrored (80% by count), 5 catalog types entirely missing, schema deployed but unpopulated for those 5, no release/version-snapshot workflow, live-checksum `/v1/meta` working.
- API: 2 of ~11 documented routes live (`meta`, `health`); 0 deployed functions beyond that; 9 function stubs exist as source only.
- Search: 80.2% Top-1 / 92.1% Top-5 on the offline engine, most recent benchmark 2026-08-15T23:37 — this is the number every later phase must not regress.
- Validators: exist, unexecuted, unknown pass state.
- Privacy: one real gap identified (permanent sensitive profile columns) for B9 to address.

No code, schema, or data was changed in producing this report.
