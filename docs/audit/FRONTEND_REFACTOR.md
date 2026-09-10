# Frontend Refactor — Tracking Doc

**Started:** 2026-09-10 · **Branch:** `chore/onboarding-restructure` · **Driver:** user-directed extension of Stage 2 (combines folder cleanup "B" + decomposition "C").

This is **not** the prompt pack's move-only Stage 2 — it deliberately changes code structure. Prompt-pack Stages 3–4 are paused until this reaches a stopping point.

---

## Baseline (2026-09-10, commit `ca0ea49`)

| Check | Result |
|---|---|
| `flutter analyze` | clean — 0 issues |
| `flutter test` | **434 pass · 1 skip · 6 fail** |
| Device | `24094RAD4I` — Android 16 / API 36 (connected) |
| Flutter | 3.44.2 stable |

**Regression gate for every commit:** `flutter analyze` clean **AND** no test failures beyond the baseline 6 **AND** device smoke-test for anything visual.

### The 6 pre-existing failures — diagnosed as test rot (C4 scope, not blockers)

All in the `basic_profile_screen.dart` onboarding area; assertions encode a stale UI shape:

| Test | Stale assumption |
|---|---|
| `production_surface_accessibility_test.dart` — "profile onboarding controls validate safely on narrow phone / wide tablet" | `find.textContaining('Date of Birth (DOB)')` — field now rendered/localized differently or on an unreached step (ARB key `dateOfBirth` still = "Date of Birth (DOB)"). |
| `profile_onboarding_overflow_test.dart` — "Step 1 DOB field shows the DD/MM/YYYY placeholder" | `find.text('DD/MM/YYYY')` — placeholder since localized/changed. |
| `profile_onboarding_overflow_test.dart` — "Step 2 Continue disabled until pincode 6 digits" / "pincode rejects non-digits, caps at 6" | `find.byType(TextFormField).at(4)` — Step 2 now has only 4 `TextFormField`s. |

Fix these when C4 reaches `basic_profile_screen.dart` — update assertions to the current UI (and localized finders), don't chase them as bugs.

---

## Plan (agreed scope for this pass: B1 + B2 + C1, then reassess)

### Track B — folder sub-grouping (mechanical; gate = `flutter analyze`)

- [ ] **B1 — `lib/services/` (25 files -> 6 folders)**
  - `catalog/` — scheme_repository, mss_catalog_bundle, scheme_catalog_store, scheme_catalog_sync_service, mss_scheme_adapter, centralized_translator
  - `search/` — hybrid_scheme_search, intelligent_scheme_search, scheme_understanding_engine, official_grounded_search, private_ai_knowledge_base
  - `voice/` — livekit_voice_agent_controller, voice_agent_controller, voice_agent_preferences, voice_agent_preview_service, voice_recognition_controller, speech_output_controller, assistant_session_controller
  - `edge_ai/` — edge_model_pack, edge_slm_runtime, edge_slm_understanding_engine
  - `chat/` — sarvam_chat_service, chat_log_service
  - `account/` — auth_service, session_cache_service, support_ticket_service
- [ ] **B2 — `lib/widgets/` (15 files -> 4 folders)**
  - `scheme/` — scheme_card, category_card, filter_panel, catalog_freshness_footer
  - `legal/` — legal_document_modal, legal_consent_section, data_processing_consent_modal
  - `assistant/` — voice_assistant_overlay, smart_assessment_bottom_sheet
  - `common/` — app_toast, custom_button, custom_confirm_dialog, gradient_scaffold, standard_page_header, floating_logo, anti_gravity_hero_section
  - Also normalise `lib/features/beta_gate/` (lone feature-first outlier) — TBD in B2.

Imports: `lib/` uses ~281 relative import lines / 55 files; `test/` uses ~245 `package:frontend/...` lines / 79 files. Every move rewrites the file's own relative imports + all references. `flutter analyze` (currently clean) is the miss-detector.

### Track C — decomposition (incremental; gate = analyze + test + device)

- [ ] **C1 — `app_state_provider.dart` (1977 lines, 23 lib consumers, ~48 test files)**
  Extract cohesive controllers; keep `AppProvider` as a **thin facade** delegating to them so consumers/tests don't churn. Candidate slices: Auth/Session · Profile+Sync · Language · Tab/Nav · Bookmarks · SearchState · Filters · Wizard · Announcements · Notifications · CatalogSync. ~3–5 commits.

### Backlog (not this pass — user prioritises)

C2 `categories_screen.dart` 4822 · C3 `voice_assistant_overlay.dart` 3907 · C4 `basic_profile_screen.dart` 2209 + fix the 6 reds · C5 `smart_assessment_bottom_sheet.dart` 2118 / `saarthi_home_screen.dart` 2360 / `home_screen.dart` 1965 / `msme_module_details_screen.dart` 1973 / `scheme_details_screen.dart` 1798 / `search_screen.dart` 1738 / `profile_screen.dart` 1422 / `notifications_screen.dart` 1302 / `help_support_screen.dart` 1272 · C6 `centralized_translator.dart` 1050 (dictionary -> JSON asset) · C7 `mss_scheme_adapter.dart` 1041 + `scheme_understanding_engine.dart` 1333 (parity-risk — characterization tests first; may defer).

---

## Progress log

| Date | Phase | Commit | analyze | test (pass/skip/fail) | device | notes |
|---|---|---|---|---|---|---|
| 2026-09-10 | baseline | `ca0ea49` | clean | 434 / 1 / 6 | — | 6 reds = test rot in basic_profile onboarding (C4) |
