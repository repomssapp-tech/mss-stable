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
  - [x] **C1.3** (`d179a1a`) — removed dead code: `fetchLocationAndPopulate()` (public, 0 callers/0 tests, orphaned by `b9b0867`) + `_getFallbackLocation()` + the `geolocator`/`geocoding` imports (still used elsewhere, so pubspec deps stay). 1769 -> 1638. analyze clean; 434/1/6.
  - [ ] **C1.4 — the tangled core split (next; user-ordered).** ~1638 lines: `_setupAuthListener` / `_subscribeToProfile` / `logout` / `deleteAccount` / `changeLanguage` each mutate profile + language + navMode + recommendations + subscriptions + promos + drafts + notifications together. Prereqs, in order:
    1. [x] **Fix the red onboarding tests** — done. Was actually **6 reds across 3 files** (the diagnosis below missed the 3rd file). All test rot from pre-branch product changes, re-pointed to the current UI:
       - `production_surface_accessibility_test.dart` (narrow phone + wide tablet): DOB label finder -> `find.text('Age *')`; Step-2 `findsNWidgets(5)` -> `4`; empty-address error `'Please enter your area or locality'` -> `'Please enter your house/street address'`.
       - `profile_onboarding_overflow_test.dart`: "DD/MM/YYYY placeholder" test -> "e.g. 25" (Step 1 is now an Age field, DOB derived); pincode-gating test rewritten to characterize the current 4-field address gating; **"pincode rejects non-digits / caps at 6" test deleted** — the pincode control was removed from Step 2 entirely (pre-branch), nothing to re-point it to.
       - `profile_required_fields_and_defaults_test.dart` — "LocationProfileScreen: required asterisks... not defaulted to Tamil Nadu": dropped the "Pincode below State" positional assertion, replaced with `expect(find.text('Pincode *'), findsNothing)`.
       - Net: baseline **434/1/6 -> 439/1/0** (6 fixed, 1 obsolete test deleted). `flutter analyze` clean.
    2. [x] **Characterization tests** — done. New `test/app_provider_characterization_test.dart` (4 tests, 439/1/0 -> 443/1/0):
       - `logout()` — dirties every session field via the public API, then asserts the full signed-out reset (`_expectSignedOutDefaults`) + `SessionCacheService` wipe. `testWidgets` + `runAsync` (needs a Navigator).
       - `deleteAccount()` with no server session — `currentUser == null` under a stub Supabase, so `delete_user` is skipped and the same reset runs. (The branch where a live RPC throws and state must be *preserved* still needs a mock client — noted in the file.)
       - `changeLanguage()` — `selectedLanguage` / `profile.language` / cache all move to `ta`; then the `_reconcileServerLanguage` stale-echo guard (echo of `en` held off, `ta` confirmation clears the marker, later `en` trusted). Complements `l10n_language_reconcile_batch6_test.dart`.
       - `didChangeAppLifecycleState` — `resumed` triggers exactly one `syncIfNeeded` (via an injected `_RecordingSyncService`); `inactive`/`paused`/`detached` trigger none; a second `resumed` triggers a second.
       - Harness gotchas baked into the file: provider methods do real I/O so these use plain `test()` / `runAsync` (fake-async deadlocks on their timers); every test waits for the constructor's `_loadState()` to settle before mutating (it re-reads `_selectedLanguage` from cache and would clobber); providers are not disposed (the Supabase auth stream's async first emit races `dispose`).
       - **Not covered** (needs a mock Supabase auth stream): the signed-in hydration branch of `_setupAuthListener`. Carry into step 3 as an integration-style fake, or accept device-smoke coverage there.
    3. Split into controllers behind an `AppProvider` facade, one slice per commit, preserving `notifyListeners` topology (23 `context.select` sites). Device-smoke each transition.

#### The 6 red tests — diagnosis (test rot from the Step-4 i18n migration + a Step-2 field-count change)

| Test | Cause | Fix |
|---|---|---|
| `production_surface_accessibility_test.dart` — "profile onboarding controls validate safely on narrow phone / wide tablet" | `find.textContaining('Date of Birth (DOB)')` finds 0 — the visible DOB label/text changed (ARB key `dateOfBirth` still holds the string, but it is no longer rendered as plain matchable text, or the field is on a step the test's `_withSemantics` flow doesn't reach). | Re-point the finder at the current DOB control (by key or by the localized label actually rendered). |
| `profile_onboarding_overflow_test.dart` — "Step 1 date-of-birth field shows the DD/MM/YYYY placeholder" | `find.text('DD/MM/YYYY')` finds 0 — DOB placeholder was localized / changed / replaced by a date-picker affordance. | Assert on the current placeholder (or the date-picker trigger). |
| `profile_onboarding_overflow_test.dart` — "Step 2 Continue disabled until pincode 6 digits" & "pincode rejects non-digits, caps at 6" | `find.byType(TextFormField).at(4)` → RangeError: Step 2 (`LocationProfileScreen`) now renders only **4** `TextFormField`s, not 5. A field was removed/moved or retyped (e.g. state is now a dropdown). | Re-map the address fields to their current widgets; address the pincode field by key/hint rather than index. |

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
| 2026-09-10 | C1.3 | `d179a1a` | clean | 434 / 1 / 6 | not needed (dead-code delete) | removed dead fetchLocationAndPopulate + _getFallbackLocation; provider 1769 -> 1638 |
| 2026-09-10 | C1.4 prereq 1 | `f7244a9` | clean | 439 / 1 / 0 | not needed (test-only) | re-pointed 6 rotten onboarding tests to current UI (DOB->Age, Step-2 pincode removed); deleted 1 obsolete pincode test |
| 2026-09-10 | C1.4 prereq 2 | `<pending>` | clean | 443 / 1 / 0 | not needed (test-only) | new app_provider_characterization_test.dart: logout / deleteAccount reset, changeLanguage + stale-echo guard, lifecycle-resume sync |
