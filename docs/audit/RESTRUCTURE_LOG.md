# Stage 2 — Restructure Log (Pass 2 executed)

**Date:** 2026-09-10 · **Branch:** `chore/onboarding-restructure` · **Plan:** `docs/audit/RESTRUCTURE_PLAN.md`

Scope executed exactly as approved: move loose root docs into `docs/` subtrees, ignore the stray CLI scratch dir, fix the doc-path references that broke. **No source code, imports, or build config changed.**

---

## 1. Files moved  (`git mv` — full history preserved, shown as `R` renames)

| Old path | New path |
|---|---|
| `WORK_STATUS.md` | `docs/worklog/WORK_STATUS.md` |
| `STALE_DOCS.md` | `docs/worklog/STALE_DOCS.md` |
| `Search_Index_Count_Bug_Context.md` | `docs/worklog/Search_Index_Count_Bug_Context.md` |
| `SPACING.md` | `docs/worklog/SPACING.md` |
| `DEV_2_JOB_ASSIGNMENT.md` | `docs/worklog/DEV_2_JOB_ASSIGNMENT.md` |
| `SEARCH_OPTIONS.md` | `docs/design/SEARCH_OPTIONS.md` |
| `Query_Expansion.md` | `docs/design/Query_Expansion.md` |
| `CUTOVER.md` | `docs/runbooks/CUTOVER.md` |
| `UI_UX_AUDIT_REPORT.md` | `docs/audit/UI_UX_AUDIT_REPORT.md` |

New folders created: `docs/worklog/`, `docs/design/`.

**Repo root after the move** — the only tracked `.md` files left are `README.md` and `CLAUDE.md` (both kept at root by tooling convention); other root files unchanged (`.mcp.json`, `.gitignore`, `.gitattributes`, `analysis_options.yaml`, `package.json`, `package-lock.json`).

---

## 2. Removed / ignored  (no project content deleted)

| Path | Action | Notes |
|---|---|---|
| `supabase/` (repo root, untracked) | Added `/supabase/` to root `.gitignore` (2-line rule + comment). **The physical directory was NOT deleted by this session** — the environment's safety gate blocked `rm -rf`. It is now git-ignored so it cannot be committed accidentally. Remove it manually if desired: `rm -rf supabase/` (it is disposable Supabase CLI scratch — `.temp/` markers duplicated in `backend/supabase/.temp/`). | — |

No files were deleted. Nothing was archived (the loose docs were *relocated within `docs/`*, not retired; `docs/archive/` already holds the genuinely historical artifacts).

---

## 3. Link references updated  (doc-path fixes only — not logic)

Three references pointed at `CUTOVER.md` "at the repo root"; updated to the new path:

| File | Line | Before | After |
|---|---|---|---|
| `backend/.env.example` | 22 | `see CUTOVER.md at the repo root.` | `see docs/runbooks/CUTOVER.md.` |
| `backend/README.md` | 56 | `` `(DEAD)` row in `CUTOVER.md`. `` | `` `(DEAD)` row in `docs/runbooks/CUTOVER.md`. `` |
| `saarthi-agent/README.md` | 97 | `` (see `CUTOVER.md` at the repo root). `` | `` (see `docs/runbooks/CUTOVER.md`). `` |

### References intentionally left as-is
- `docs/design/Query_Expansion.md` -> mentions `SEARCH_OPTIONS.md`: now a co-located sibling in `docs/design/`, prose reference still resolves.
- `docs/worklog/Search_Index_Count_Bug_Context.md` -> mentions `STALE_DOCS.md`: now a co-located sibling in `docs/worklog/`.
- `docs/worklog/WORK_STATUS.md` -> mentions `SEARCH_OPTIONS.md` / `SPACING.md` / `STALE_DOCS.md`: these are **historical commit-log entries** ("`c256fc0` `docs: STALE_DOCS.md`") describing past commits, not live links — rewriting them would falsify the log.

---

## 4. Build / verification

**No build step required and none run** — zero source files, zero `import`/`package:` statements, zero `pubspec.yaml` / `l10n.yaml` / `deno.lock` / `config.toml` entries were touched. Only Markdown docs moved and three doc-path strings in a comment + two READMEs changed. Nothing the Flutter analyzer, `deno check`, or `supabase db lint` looks at was modified.

`git status` after Pass 2: 9 renames + 3 modified non-source files + `.gitignore` modified. (`frontend/pubspec.lock` shows as modified but that predates this work and is unrelated.)

---

## 5. Decision items completed (Section 5 follow-ups)

| Item | Old location | Action taken |
|---|---|---|
| Legacy in-code i18n map | `frontend/lib/utils/constants.dart` | Removed dead `AppConstants.translations` and `AppConstants.get()` (superseded by ARB). |
| Orphaned migration scripts | `scripts/{migrate_chat_logs,test_migration}.js` | Archived to `docs/archive/superseded-scripts/` via `git mv`; empty `scripts/` directory removed. |
| Superseded catalog import | `backend/scripts/import_catalog.mjs` | Archived to `docs/archive/superseded-scripts/` via `git mv`; removed broken `catalog:import\|validate\|bootstrap` from `backend/package.json`. |
| Dead nested CI workflows | `saarthi-agent/.github/workflows/` | Removed dead nested workflow files (`ruff.yml`, `tests.yml`, `tag-version.yml`, `template-check.yml`); added active root CI workflow `.github/workflows/saarthi-agent.yml` running ruff and pytest on changes to `saarthi-agent/**`. |

---

## 6. Stage 3 — Documentation Reconciliation (Executed 2026-09-13)

Reconciled project documentation across the 3-tier monorepo to accurately match production source code and architecture (resolving audit findings §12):

| Document | Location | Reconciliation performed |
|---|---|---|
| Root `README.md` | `README.md` | Replaced obsolete Hindi/OTP prototype text with true 3-tier architecture, dual UX modes (Regular + Companion), offline-first catalog `1.34.3-alpha`, Sarvam AI voice pipeline, and verified setup commands. |
| Root `CLAUDE.md` | `CLAUDE.md` | Replaced stale `MssApiClient` / 15-endpoint claims with active developer guide: directory layout, invariants (`AppSpacing`, ARB localization, parity tests), build/test commands, and monolithic size guardrails. |
| Database architecture | `docs/DATABASE_ARCHITECTURE.md` | Reconciled schema changes (`catalog.scheme` columns updated, deprecated tables documented, `voice_chat_sessions`, `support_tickets`, `beta_gate_config` added). |
| Offline-first architecture | `docs/OFFLINE_FIRST_AND_RECOMMENDATION_ARCHITECTURE.md` | Updated version to `1.34.3-alpha` (219 schemes / 1,220 entities / 971 search records) and updated module map paths to match decomposed folders. |
| Search & catalog architecture | `docs/SEARCH_AND_CATALOG_ARCHITECTURE.md` | Updated `hybrid_scheme_search.dart` path to `services/search/`, added `rollbackRelease` and `sarvam-chat` to Edge Functions inventory. |
| Scheme repository doc-comments | `frontend/lib/services/catalog/scheme_repository.dart` | Corrected doc-comments on `searchSchemes()` and `searchSchemeMatches()` from "online-first via POST /v1/search" to 100% on-device search with CPU memoization. |
| Backend README | `backend/README.md` | Fixed directory layout (docs at repo root, voice lab at `tools/voice-lab/`), updated Edge Functions list, removed obsolete npm script references, updated catalog version to `1.34.3-alpha`. |
| Saarthi agent README | `saarthi-agent/README.md` | Corrected LLM model to `sarvam-105b-conversations` (removed leftover Gemma template text); updated Supabase section from deprecated chat logging to OTA catalog sync. |

---

## 7. Product decisions resolved (Cleaned Up & Archived)

Both discretionary items flagged during the audit have received product sign-off and were cleaned up:

1. **Retired Edge Functions (`backend/supabase/functions/{search,recommend}/`)**:
   - Archived to `docs/archive/superseded-edge-functions/search/` and `docs/archive/superseded-edge-functions/recommend/` preserving git history.
   - Removed 410 GONE stubs from active Edge Functions deployment directory.

2. **On-Device SLM Experimental Code (`edge_slm_*` & `llama_flutter_android`)**:
   - Removed `llama_flutter_android: 0.2.6` dependency from `frontend/pubspec.yaml` and refreshed lockfile.
   - Removed ~60 lines of OpenMP/NDK runtime copy workarounds from `frontend/android/app/build.gradle.kts`.
   - Wired `VoiceAssistantOverlay` to default cleanly to `const LocalSchemeUnderstandingEngine()`.
   - Archived `frontend/lib/services/edge_ai/` services and tests (`edge_slm_understanding_engine_test.dart`, `edge_model_pack_test.dart`) to `docs/archive/experimental-edge-slm/`.
   - Archived Python edge parser tools (`train_edge_parser.py`, `evaluate_edge_parser.py`, `export_edge_parser.py`, `evaluate_edge_gguf.py`) to `docs/archive/experimental-edge-slm/tools/`.
   - Updated `docs/EDGE_AI.md` to note formal retirement in favor of rule-based `LocalSchemeUnderstandingEngine` + `HybridSchemeSearch`.

---

## 8. Stale & Unused Markdown Documentation Cleanup (Executed 2026-09-13)

Removed 36 unused, obsolete, and historical markdown files across three categories:

1. **Temporary Worklogs & Sprint Notes (`docs/worklog/`)**:
   - Removed `DEV_2_JOB_ASSIGNMENT.md`, `Search_Index_Count_Bug_Context.md`, `SPACING.md`, `STALE_DOCS.md`, and `WORK_STATUS.md`. Removed empty `docs/worklog/` directory.

2. **Obsolete API & Flutter Handoff Documents (`docs/handoff/`)**:
   - Removed `api_docs/` (`API_CONTRACT.md`, `API_ENDPOINT_REFERENCE.md`, `ERROR_HANDLING_GUIDE.md`, `LOCALIZATION_IMPLEMENTATION_GUIDE.md`, `PAGINATION_AND_FILTER_GUIDE.md`, `SEARCH_IMPLEMENTATION_GUIDE.md`) which described the obsolete 15-endpoint online architecture.
   - Removed `flutter_docs/` (`FLUTTER_INTEGRATION_PLAN.md`, `MODEL_MAPPING_GUIDE.md`, `SCREEN_DATA_MAPPING.md`, `STATE_MANAGEMENT_GUIDE.md`).
   - Removed `HANDOFF_README.md` and `data/MSS_API_DATA_PACKAGE/README.md`.
   - Preserved `architecture_docs/` (`DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md`, `HASH_VERIFICATION_SPECIFICATION.md`, `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`, `RELEASE_MANIFEST_SPECIFICATION.md`, `UPDATE_FLOW_SPECIFICATION.md`) which serve as active catalog release architecture specifications.

3. **Historical Point-in-Time Audit Reports from August 2026 (`docs/archive/`)**:
   - Removed `backend-reports-2026-08/` (7 files).
   - Removed `security-2026-08/` (10 files).
   - Removed `design-review-2026-08.md` and `l10n-notes/companion_mode_string_inventory.md`.
   - Preserved code archives in `docs/archive/` (`experimental-edge-slm/`, `superseded-edge-functions/`, `superseded-scripts/`).

## 9. Documentation Flattening, Wrong File Removal & Architecture Reconciliation (Executed 2026-09-13)

### 9.1 Removal of Broken, Superseded & Scratchpad Files
1. `docs/handoff/data/MSS_API_DATA_PACKAGE/validate_package.py` — deleted (broken validation script for dead 15-endpoint API).
2. `docs/design/SEARCH_OPTIONS.md` — deleted (obsolete options memo contradicted by production implementation).
3. `docs/audit/FRONTEND_REFACTOR.md` & `docs/audit/RESTRUCTURE_PLAN.md` — deleted (stale temporary planning scratchpads).
4. `docs/archive/verification-harnesses/` (7 files) — deleted (broken standalone verification scripts with unresolvable relative imports and duplicate contract models).

### 9.2 Flattening to Strictly 1 Level of Subdirectories
Flattened all subdirectories inside `docs/` so that every directory is exactly 1 level deep with zero nested subdirectories:
1. `docs/handoff/architecture_docs/*` -> moved to `docs/specs/*`. Empty `docs/handoff/` removed.
2. `docs/backend/decisions/*` and `docs/backend/product/*` -> moved directly to `docs/backend/*`. Empty subdirectories removed.
3. `docs/archive/*/*` -> flattened directly to `docs/archive/*` (all 28 archived files now live directly in `docs/archive/` without nested subdirectories).
4. `docs/EDGE_AI.md` -> moved to `docs/archive/EDGE_AI.md`.

### 9.3 Code & Documentation Link Reconciliation
1. Updated `tools/publish_catalog_release.py` and `docs/SEARCH_AND_CATALOG_ARCHITECTURE.md` to point to `docs/specs/`.
2. Updated `frontend/lib/models/catalog_manifest.dart`, `frontend/lib/services/catalog/scheme_catalog_store.dart`, and `frontend/lib/services/catalog/mss_catalog_bundle.dart` to point to `docs/specs/`.
3. Updated `backend/supabase/seed/seed.sql` to reference `docs/specs/`.
4. Updated `docs/runbooks/CUTOVER.md` to reference `docs/archive/` and clarify retired functions.
5. Updated `docs/design/Query_Expansion.md` to decouple from deleted `SEARCH_OPTIONS.md`.
6. Updated `docs/DEPLOYMENT_ARCHITECTURE.md` to document the active production region (`ap-southeast-2` Sydney) and fix reference to `docs/specs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`.
7. Updated `docs/UX.md` to eliminate phantom OCR/standalone screens and accurately describe Flutter components.

