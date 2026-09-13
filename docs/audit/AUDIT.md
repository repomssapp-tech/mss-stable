# MSS App — Current-State Audit

**Date:** 2026-09-13 · **Branch:** `main` · **Method:** targeted re-verification against the code by three read-only investigations, following the 2026-09-12/13 decomposition and docs-flattening commits. This supersedes `docs/audit/CODEBASE_AUDIT.md` as the **live status doc** — that file stays in place as a frozen, much deeper historical baseline from 2026-09-10 and is still the best single narrative introduction to the whole system.

**Not re-verified this pass** (carried forward unchanged from the 2026-09-10 baseline, not re-checked here): live Supabase project state (`houpzsxmwemoztpuigmo`), `saarthi-agent` runtime behavior, secrets-on-disk findings, and the full database-migration content review (§4/§7/§11/§12 of `CODEBASE_AUDIT.md`). `flutter analyze` and `flutter test` **were** run as part of the 2026-09-13 decomposition follow-up below (full ~470-test suite, clean analyze) — that coverage is current as of this doc's date. Treat this document as scoped to: recent decomposition integrity, `v1` API routing, and docs/governance hygiene.

---

## 0. Manual full-app QA pass (2026-09-13, English, on `emulator-5554`)

Full flow tested end-to-end: beta gate → language selection → Google sign-in → Home, Search + filters, scheme details, Save/Saved, Discover, Notifications, Profile, edit-profile wizard (all 4 steps), Settings incl. Navigation Mode, Help & Support. Found and fixed 4 real bugs; 2 apparent bugs during testing turned out to be tap-precision artifacts, not defects (though one was hardened anyway).

| # | Issue | Root cause | Fix |
|---|---|---|---|
| 1 | Discover's "Business Utilities & Tools" section stayed in Tamil indefinitely after switching to English | `categories_business_utilities_section.dart:20` read `AppProvider.selectedLanguage` via `Provider.of(context, listen: false)`, and the widget is instantiated `const` with zero params by its parent (`categories_screen.dart:280`) — so it never registered an `InheritedWidget` dependency and never rebuilt on a language change, regardless of the parent rebuilding. Audited all 17 other files with the same `selectedLanguage == 'ta'` pattern; all 17 were already safe (a listening call exists somewhere in their rebuild chain). | Changed the read to a listening `Provider.of(context)` — one-line fix, verified this is the only file of the 18 that needed it. |
| 2 | Switching "Navigation Mode" to "AI Companion (Saarthi)" in Settings silently reverted to "Regular" | `app_state_provider.dart`'s realtime profile-echo handler unconditionally overwrote `_navigationMode = dbProfile.navigationMode;` with no guard — unlike `language`, which has a `LanguageReconciler` 20s grace-window guard for exactly this race. | Added `NavigationModeReconciler` (`providers/controllers/navigation_mode_reconciler.dart`), mirroring `LanguageReconciler`; wired into `changeNavigationMode()` (`markPending`) and the realtime handler (`reconcile`), plus `reset()` on logout/delete-account. |
| 3 | Filter sheet's "Show N schemes" button count ignored the active text search — showed the filter's whole-catalog count (e.g. 31) while actually applying it yielded far fewer (2) | `FilterPanel` always computed counts against `provider.allSchemes` (the full catalog), with no visibility into the caller's active search-scoped list. | Added an optional `FilterPanel.baseSchemes` param; `search_screen.dart` now passes `_masterSearchResults` and `search_results_screen.dart` passes `_baseSchemes`, so counts and the button label are scoped to what's actually being filtered. |
| 4 | (Hardened, not a confirmed bug) Profile wizard's consent checkbox felt hard to hit precisely during scripted testing | The checkbox's own 24×24 box + label had separate/smaller tap targets than the equivalent login-screen consent row, which already wraps the whole row in an opaque `GestureDetector`. | Wrapped the whole consent row (checkbox + label) in one `GestureDetector` with `HitTestBehavior.opaque`, matching `legal_consent_section.dart`'s pattern. |

Two things investigated and ruled out as **not bugs**: (a) the login screen's own consent checkbox was already correctly gated on "view both Terms and Privacy" before enabling, working as designed; (b) an apparent 83%→94% profile-completion mismatch between Home and Settings was traced to both screens reading the exact same `provider.profileCompletionPercentage` (single formula in `profile_completion.dart`) — the jump was from live wizard-field edits during testing, not two different calculations.

All fixes verified: `flutter analyze` clean, full ~470-test suite passing (0 new failures) after each fix.

---

## 1. Frontend decomposition — verified per component

| Component | Status | Notes |
|---|---|---|
| `search_screen.dart` → `screens/regular_mode/search/` | ✅ Verified | All sub-modules exist and are imported; coordinator delegates correctly. |
| `categories_screen.dart` → `screens/regular_mode/categories/` | ✅ Verified | Shrunk to 291 lines; sub-modules resolve. |
| `scheme_details_screen.dart` → `screens/regular_mode/scheme_details/` | ✅ Verified | 551 lines; all 10 sub-modules present and imported. |
| `profile_screen.dart` → `screens/profile/` | ✅ Verified | 124 lines; cards/dialogs/handlers all present. |
| `help_support_screen.dart` → `screens/regular_mode/help_support/` | ✅ Verified | 41 lines; delegates via `help_support_sections.dart`. |
| `smart_assessment_bottom_sheet.dart` → `widgets/assistant/smart_assessment/` | ✅ Verified | 248 lines; 5 sub-modules present. |
| `scheme_understanding_engine.dart` → rules/extractor/evaluator | ✅ Verified | All 6 sub-modules present alongside sibling search engines. |
| `document_checklist_sheet.dart` | ✅ Verified | 389 lines under `categories/`; no leftover top-level duplicate. |
| **`voice_assistant_overlay.dart`** | ✅ Follow-up done (2026-09-13) | 1837 → **1750 lines**. Extracted `voice_fact_dialogs.dart` (118 lines) into `widgets/assistant/voice/`; also removed 2 now-dead imports/symbols the extraction exposed. Hit the same structural wall as the other two (below) on the bulk of the remaining logic — the two giant widget-tree builders plus ~15 event handlers cross-reference ~25 private `State` fields. Public API unchanged. `flutter analyze` clean; full 470-test suite passes. |
| **`saarthi_home_screen.dart`** | ✅ Follow-up done (2026-09-13) | 982 → **920 lines**. Extracted `saarthi_voice_animations.dart` (44 lines) and `saarthi_response_helpers.dart` (77 lines) into `screens/companion_mode/saarthi_home/`. Hit a real structural wall on the rest — see below. `flutter analyze` clean, 47/47 related tests pass. |
| **`app_state_provider.dart`** | ✅ Follow-up done (2026-09-13) | 1095 → **917 lines**. Extracted `language_reconciler.dart` (44 lines), `profile_completion.dart` (103 lines), `profile_cloud_sync.dart` (81 lines) into `providers/controllers/`. Same structural wall hit (below). Public API unchanged. `flutter analyze` clean; full 469-test suite passes (one test that grepped source text for a since-moved code marker was repointed at the new file, not a behavior regression). |
| **`basic_profile_screen.dart`** | ✅ Follow-up done (2026-09-13) | 794 → **622 lines**. Extracted `profile_progress_indicator.dart` (71 lines), `profile_continue_button.dart` (93 lines), `location_geocoding.dart` (91 lines) into `basic_profile/`. Remainder is 4-step wizard state/validation/lifecycle wiring — inherent complexity, not further-splittable boilerplate. Public API unchanged (9 call sites checked). `flutter analyze` clean; 28/28 related tests pass. |

**Cross-cutting check (original decomposition pass):** a full sweep of every relative import across `frontend/lib` resolved 100% to existing files — **zero dangling imports, zero orphaned monoliths, zero `*_old`/`*_backup` files** anywhere in the tree. The decomposition work that *was* done is structurally sound; the remaining problem is incompleteness (files not shrunk enough, or not touched at all), not breakage.

**Rule going forward:** see `docs/RULES.md` §1 — the ~500-line ceiling applies to the coordinator after decomposition, not just before it.

### 2026-09-13 follow-up: structural wall found in all 4 files

All four follow-up passes reduced their target file (see line-count deltas above), but three of the four (`saarthi_home_screen.dart`, `app_state_provider.dart`, `voice_assistant_overlay.dart`) independently hit the same wall on what remained: the leftover logic (voice/session lifecycle callbacks, auth/profile/realtime-subscription handling, giant widget-tree builders + event handlers) reads and writes many private `State`/class fields across the same methods. Pulling that into separate-file helper classes without changing behavior isn't possible with this codebase's current conventions — it would require either Dart `part`/`part of` files (not used anywhere else in this repo) or restructuring the logic into an injected/callback-driven controller (an architecture change, not a pure file-layout refactor). All three independent passes stopped short of making that call unilaterally rather than force it.

**Decision (2026-09-13):** don't push further on these three — the risk of a `part`-files or controller-injection rewrite breaking behavior outweighs the benefit of getting under the line-count ceiling. They stay as single files at their current (reduced) size as a deliberate, accepted exception; see `docs/RULES.md` §5. `basic_profile_screen.dart` was the exception to the exception: its remainder (622 lines) is inherent 4-step-wizard state, not blocked by this wall, just judged not worth fragmenting further either.

None of the four follow-up passes changed any public API, and each was verified with a clean `flutter analyze` plus passing tests (up to and including the full ~470-test suite for the provider and overlay changes).

---

## 2. Backend API routing — verified route-by-route

`backend/supabase/functions/v1/index.ts` (684 lines) — current live route table, verified line-by-line against the code and cross-checked against `config.toml` auth settings:

| Method | Path | Auth |
|---|---|---|
| GET | `/v1/health` | none (rate-limit exempt) |
| POST | `/v1/cache-bust` | service-role secret |
| GET | `/v1/meta` | JWT |
| POST | `/v1/search` | JWT + 3-tier fail-closed rate limit |
| GET | `/v1/schemes/{id}[/finance]` | JWT |
| GET | `/v1/finance-products[/{id}]` | JWT |
| GET | `/v1/clusters\|tax\|privileges[/{id}]` | JWT |
| GET | `/v1/relationships/{id}` | JWT |
| POST | `/v1/eligibility` | JWT |
| GET | `/v1/localization/{id}?lang=` | JWT |
| * | anything else | 404 |

✅ **Verified accurate** — matches the router's own header doc comment and `config.toml`'s per-function `verify_jwt` settings exactly. No functional routing bugs found.

**Function inventory:** `_shared`, `db-change-notify`, `livekit-token`, `publishCatalog`, `rollbackRelease`, `sarvam-chat`, `v1` — all present and match `AGENTS.md`'s list. `search` and `recommend` are **genuinely deleted** (moved to `docs/archive/superseded-edge-functions/` by commit `caa7704`), not dangling 410-stubs — clean removal, no follow-up needed.

**Client callers confirmed:**
- `sarvam-chat` ← `frontend/lib/services/chat/sarvam_chat_service.dart:60-66` ✅
- `livekit-token` ← `frontend/lib/services/voice/livekit_voice_agent_controller.dart:192-195` ✅
- `v1` — zero callers, confirmed by grep across `frontend/lib`. **This is intentional**, not a bug: the router's own header comment documents it as reserved for a future Saarthi voice-agent search path.

**Migrations:** 75 files, latest `20260908120000` — unchanged since the last full audit, nothing new to verify.

### Issues found (doc drift, not functional bugs)

| # | Issue | Location | Fix needed |
|---|---|---|---|
| 1 | Stale comment references a deleted Flutter class | `backend/supabase/config.toml:388-392` — cites `frontend/lib/services/mss_api_client.dart`, deleted in commit `aef431b` | Update or remove the comment; `v1` currently has no Flutter caller at all. |
| 2 | API spec has zero overlap with real routes | `backend/openapi/openapi.yaml` — documents an admin/sync API (`/v1/admin/schemes`, `/v1/sync/*`, `/v1/admin/audit`, etc.) with **zero overlap** with the real `/v1/*` routes above. It does self-disclose as "planned contracts until their Edge Functions are implemented" (line 8-10), so it isn't presented as live — but it also doesn't document any of the routes that *are* live, so it's not useful as API documentation today. | Per `docs/RULES.md` §2: either add the real live routes to this spec, or rename/relocate it to make clear it's a future-API design doc, not current API documentation. |

---

## 3. Docs & governance hygiene

| Item | Status | Action taken |
|---|---|---|
| `AGENTS.md` vs `CLAUDE.md` duplication | ⚠️ Found → ✅ Resolved this pass | `AGENTS.md` confirmed as canonical; the 4 items it was missing (`npm run db:test`/`db:lint`, `flutter run -d emulator-5554`, the Monolithic Decomposition rule) were merged in. `CLAUDE.md` reduced to a pointer at `AGENTS.md`. |
| No contributor rulebook index | ⚠️ Found → ✅ Resolved this pass | Created `docs/RULES.md`. |
| No quick-orientation reference | ⚠️ Found → ✅ Resolved this pass | Created `docs/SKILLS.md`. |
| No per-developer change log | ⚠️ Found → ✅ Resolved this pass | Created `docs/audit/DEV_LOG.md` + `.github/workflows/dev-log.yml` + `.github/pull_request_template.md`. See §4 below. |
| `docs/` domain-spec set (architecture, UI/UX, backend spec, runbooks, catalog specs) | ✅ Verified current | Confirmed to already cover architecture/API/schema/design-token concerns in depth — `docs/RULES.md` indexes these rather than duplicating them. |

---

## 4. Per-developer change log

Added because the repo is expanding to multiple developers with no existing mechanism to attribute changes. See `docs/audit/DEV_LOG.md` for the log itself and `docs/RULES.md` §4 for the rule. The log is appended automatically by `.github/workflows/dev-log.yml` on every PR merged to `main`, keyed by the merging PR author's real GitHub username (`github.event.pull_request.user.login`) rather than local git email, which was found to vary per developer machine and isn't a reliable identity key.

---

## Summary

- **Frontend:** all 4 flagged files received a follow-up decomposition pass on 2026-09-13 (`voice_assistant_overlay.dart` 1837→1750, `app_state_provider.dart` 1095→917, `saarthi_home_screen.dart` 982→920, `basic_profile_screen.dart` 794→622), each verified with `flutter analyze` + tests, no public API or behavior changes. Three of the four hit a genuine architectural wall (private-field coupling); the decision made was to accept them as single files above the ~500-line ceiling rather than risk a `part`-files or controller-injection rewrite (`docs/RULES.md` §5). None of the working tree has been committed yet.
- **Backend:** API routing is correct and fast (warm-isolate cache, fail-closed rate limiting, RPC boundary intact per the 2026-09-10 baseline) — only two stale-doc issues, no functional defects.
- **Governance:** the four requested artifacts (this audit, `docs/RULES.md`, `docs/SKILLS.md`, `docs/audit/DEV_LOG.md` + automation) are now in place.
