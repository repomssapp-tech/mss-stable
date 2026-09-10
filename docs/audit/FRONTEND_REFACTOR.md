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

### Track B — folder sub-grouping (mechanical; gate = `flutter analyze`)  — DONE (`e1e6f85`)

- [x] **B1 — `lib/services/` (26 files -> 6 folders)** — done via codemod; analyze clean; 434/1/6
- [x] **B2 — `lib/widgets/` (16 files -> 4 folders)** — done via codemod; analyze clean; 434/1/6
- Decision: `lib/features/beta_gate/` left as-is (cohesive feature module, not a defect).

<details><summary>original B1 spec</summary>

- **B1 — `lib/services/` (25 files -> 6 folders)**
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

</details>

### Track C — decomposition (incremental; gate = analyze + test + device)

- **C1 — `app_state_provider.dart` (was 1977 lines, 23 lib consumers, ~29 test files)**
  - [x] **C1.1** (`1ccdaac`) — extracted seed data (`kDefaultAnnouncements` / `kSeedNotifications` / `kDefaultPromoAlerts`) to `app_state_seed_data.dart`. 1978 -> 1829. Pure data move; analyze clean; 434/1/6.
  - [x] **C1.2** (`80ea968`) — extracted `extractGooglePhoto` / `extractGoogleName` (pure static) to `services/account/google_identity.dart`; folded the two key-scan loops into one helper; updated `google_profile_photo_test.dart`. 1829 -> 1769. analyze clean; 434/1/6.
  - [ ] **C1.3** (next, safe) — extract device-location resolution (`fetchLocationAndPopulate` + `_getFallbackLocation`, ~130 lines of Geolocator/geocoding) to a resolver returning the address fields + locData; provider keeps a thin wrapper that applies the patch + notify/save/sync. Check for a covering test first.
  - [ ] **C1.4 — DEFERRED to a dedicated session.** The remaining core (~1640 lines) is *tangled*: `_setupAuthListener` / `_subscribeToProfile` / `logout` / `deleteAccount` / `changeLanguage` each mutate profile + language + navMode + recommendations + subscriptions + promos + drafts + notifications together. A clean controller split is genuine design work (threading listeners between controllers, preserving `notifyListeners` topology for 23 `context.select` sites) and the safety net is weak (6 pre-existing reds, no PR CI). **Do it only with: (a) the 6 reds fixed first, (b) characterization tests for auth/logout/language-reconcile/lifecycle-resume, (c) device smoke of each state transition.**

### Backlog (not this pass — user prioritises)

C2 `categories_screen.dart` 4822 · C3 `voice_assistant_overlay.dart` 3907 · C4 `basic_profile_screen.dart` 2209 + fix the 6 reds · C5 `smart_assessment_bottom_sheet.dart` 2118 / `saarthi_home_screen.dart` 2360 / `home_screen.dart` 1965 / `msme_module_details_screen.dart` 1973 / `scheme_details_screen.dart` 1798 / `search_screen.dart` 1738 / `profile_screen.dart` 1422 / `notifications_screen.dart` 1302 / `help_support_screen.dart` 1272 · C6 `centralized_translator.dart` 1050 (dictionary -> JSON asset) · C7 `mss_scheme_adapter.dart` 1041 + `scheme_understanding_engine.dart` 1333 (parity-risk — characterization tests first; may defer).

---

## Progress log

| Date | Phase | Commit | analyze | test (pass/skip/fail) | device | notes |
|---|---|---|---|---|---|---|
| 2026-09-10 | baseline | `ca0ea49` | clean | 434 / 1 / 6 | — | 6 reds = test rot in basic_profile onboarding (C4) |
| 2026-09-10 | B1+B2 | `e1e6f85` | clean | 434 / 1 / 6 | not needed (no behaviour change) | services/ -> 6 folders, widgets/ -> 4; 42 renames via codemod |
| 2026-09-10 | C1.1 | `1ccdaac` | clean | 434 / 1 / 6 | not needed (pure data move) | seed lists -> app_state_seed_data.dart; provider 1978 -> 1829 |
| 2026-09-10 | C1.2 | `80ea968` | clean | 434 / 1 / 6 | not needed (pure static helpers) | extractGoogle{Photo,Name} -> services/account/google_identity.dart; provider 1829 -> 1769 |
