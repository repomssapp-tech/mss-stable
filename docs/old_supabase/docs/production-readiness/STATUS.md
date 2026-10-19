# Production-readiness sweep — status

**Last updated:** 2026-10-02 · **Branch:** `fix/production-readiness` · **HEAD at hand-off:** `5bb1267`

This directory holds the specs (`spec_design_system.md`, `spec_phase3.md`) that drove Phases 2 and 3, and this status file. Work paused mid-Phase-3 at the user's request; this is the hand-off for whoever picks it up next.

## What Phases 1–3 delivered

### Phase 1 — correctness fixes (`25b5071`..`f875b16`, 12 commits, items 1.1–1.12)
Fixed fabricated/fake data and copy bugs found by an engineering audit: fake match percentages, a "Recently Added" tab that silently created bookmarks, dual bookmark keys (`schemeCode` vs `id`), hardcoded UI strings outside ARB, a saved-count subtitle that never updated, a non-functional "Other state" picker, a push-notification switch wired to nothing, a mislabeled "Profile Verified" badge, a missing AI disclaimer in chat, and unimplemented MSME feature claims.

### Phase 2 — design-system foundation (`74b9bf4`..`4407aaa`, 11 commits, items 2.0–2.7)
Built the token/primitive layer everything else is built on:
- `AppColors`, `AppRadius`, `AppSize`, `AppSpacing`, `AppShadows`, `AppTextStyles` (`context.text.<role>`) in `lib/utils/`.
- Bundled Inter, Poppins, Noto Sans Tamil as local font assets (offline-safe, `GoogleFonts.config.allowRuntimeFetching = false`).
- `AppTheme.light` — the full `ThemeData`, replacing the inline one in `main.dart`.
- Shared primitives `AppIconButton`, `AppTappable`, `AppCard` (`lib/widgets/common/`).
- Ratchet guard tests (`test/guards/*_test.dart` + `test/guards/baseline/*.json`) enforcing the tokens incrementally against ~1600 pre-existing violations, regenerated via `tool/update_guard_baseline.dart`.
- Two performance fixes to `intelligent_scheme_search.dart` (regex caching, alias-check reordering).
- Four fixes from the designer's Phase 2 review (D1 drag-handle, D3 ripple/margin bug, D4 font variations, D5 tap_target scan correction).

### Phase 3 — screen-by-screen sweep (`889234f`..`5bb1267`, partial)
- **3.0** (`889234f`): added all new/changed ARB keys from `spec_phase3.md` §Z/§Z2 to both `app_en.arb`/`app_ta.arb`, reusing existing keys where one already covered the same meaning.
- **3.1** (`b1b6ba9`): Group 0 (`QuickPills`, `formatInr`), the 3 ratchet guards (`button_style`, `fixed_height_text`, `fit_one_line`) + `semantics_test.dart` (deferred to 3.2, see below), `AppTagStyle` field rename (`textSecondary`→`text`) + `styleForTag`, `navigationBarTheme` `surfaceTintColor`/`elevation` fix.
- **3.2** (`792e4c1`): Group 1 (`main.dart` — Material 3 `NavigationBar` replacing the custom bottom bar; **the symmetric 1.0–1.6 text-scale clamp from this commit was later reverted**, see below) + Group 4 (`standard_page_header.dart`, `custom_input_field.dart`, `app_toast.dart`, `custom_confirm_dialog.dart`).
- **3.3** (`d263d90`, `5bb1267`): Group 2 (`login_screen.dart`) and Group 5 (`home_header_section.dart`) only. **Groups 3, 6, 7, 8 were started by subagents and discarded uncommitted** (`git restore`) when work was paused mid-flight — nothing from those groups landed.
- **Post-pause fixes** (commit right after this one): the designer's batch-1 review (`_manager/review_phase3_batch1.md`) flagged two P1 issues, both fixed:
  - **B2** — `AppToast` was truncating messages at 2 lines (the Tamil consent notice needs 4). Now `maxLines: 4`, the action button moves to its own row for messages over 40 chars, and `loginReviewTermsNotice`'s Tamil string was shortened per §Z2 #9.
  - **B3** — `CustomConfirmDialog`'s destructive variant now forces `AppColors.danger`/`dangerSoft` regardless of what colour the caller passed (old raw `#EF4444` was 3.76:1 with white text, below WCAG AA).
  - The P2 items in that review (nav indicator contrast, `AppBottomNav` extraction, `styleForTag` palette fix, `CustomInputField` icon size/ripple/semantics) were **not** done — explicitly skipped per the pause instruction, still open.
- **Text-scale clamp reverted**: Group 1's 1.0–1.6 symmetric clamp in `main.dart` was reverted back to the pre-Phase-3 per-language clamp (English floor-at-1.2/ceiling-1.3, Tamil 1.0–1.12) because the clamp is designed to ship *together with* the screen-by-screen size sweep (unswept screens have ~1267 un-tokenized font-size literals and several fixed-height containers that would overflow or look worse under the wider range before the sweep reaches them). The `NavigationBar` and everything else from Group 1 was kept. See the comment left in `main.dart`'s `MaterialApp.builder` pointing back to `spec_phase3.md` §1a.

## Remaining Phase 3 groups

Not started (file lists and spec sections are in `spec_phase3.md`):

| Group | Files | Spec section |
|---|---|---|
| 3 | `beta_gate_screen.dart`, `widgets/legal/legal_consent_section.dart` | §3 |
| 6 | `home/home_recommended_section.dart` | §6 |
| 7 | `home/{home_msme_support_section,home_promo_carousel_section,home_journey_section,home_updates_section,home_profile_completion_card}.dart`, `home_screen.dart` | §7 |
| 8 | `search/search_input_section.dart`, `search_screen.dart` (also adds `canSortByProfile`/`hasActiveFacets`/`onClearFilters`/`onClearSearch`/`onPillSelected` plumbing that groups 9/10 depend on — **land this one before 9 and 10**) | §8 |
| 9 | `search/search_filter_strip.dart` | §9 |
| 10 | `search/search_results_view.dart`, `search_results_screen.dart` | §10 |
| 11 | `widgets/scheme/scheme_card.dart` (uses `styleForTag` in `app_colors.dart`, not a new file — Phase 2 correction already applied) | §11 |
| 12 | `widgets/scheme/filter_panel.dart` | §12 |
| 13 | `saved_schemes_screen.dart` | §13 |
| 14 | `scheme_details/*`, `scheme_details_screen.dart` | §14 |
| 15 | `companion_mode/saarthi_welcome_screen.dart`, `companion_mode/assisted_profile/*` (except `step1_state_selector.dart`) | §15 |
| 16 | `categories/*`, `categories_screen.dart` | §16 |
| 17 | `settings_screen.dart` | §17 |
| 18 | `screens/profile/*`, `profile_screen.dart` | §18 |
| 19 | `sarvam_chat_screen.dart` | §19 |
| 20 | `msme/*`, `msme_module_details_screen.dart` | §20 |
| 21 | `notifications/*`, `notifications_screen.dart`, `help_support/*` | §21 |
| 22 | Cross-cutting grep check: `grep -rE "isTa(mil)?\s*\?\s*[0-9.]+\s*:\s*[0-9.]+" frontend/lib` must return nothing (**currently returns 2 hits, both reintroduced by the text-scale clamp revert above** — that's expected and intentional until the clamp is reinstated with the full sweep) | §22 |

Also still open from the designer's batch-1 review (P2, explicitly deferred): nav selected-indicator contrast (`primaryTint`, w700 labels), extracting `AppBottomNav` so `semantics_test.dart` exercises the real bar instead of a stand-in, `styleForTag`'s State/UT-vs-Central word-boundary fix, `CustomInputField`'s icon size (20dp not 16dp) + picker ripple visibility + possible double semantics announcement.

## Phase 4 (not started — P2 polish)
Flagged in earlier audits, intentionally deferred past Phase 3:
- General spacing cleanup beyond what the `spacing_scale` guard currently ratchets (105 violations across 54 files, see totals below).
- Dead-code scan (unused private methods/classes left behind as groups land, e.g. anything the Phase 3 sweep orphans).
- 20+ files over 500 lines — candidates for splitting, not touched by this sweep (its rule 1 is "no layout change," which precludes file-splitting refactors).

## Guard baseline totals (current, at hand-off)

| Rule | Files | Violations |
|---|---|---|
| `type_scale` | 105 | 1267 |
| `color_tokens` | 114 | 1784 |
| `radius_tokens` | 92 | 414 |
| `tap_target` | 24 | 36 |
| `i18n_literals` | 13 | 297 |
| `spacing_scale` | 54 | 105 |
| `button_style` | 35 | 48 |
| `fixed_height_text` | 10 | 12 |
| `fit_one_line` | 29 | 48 |

(`contrast_test.dart`, `type_scale_floor_test.dart`, and `semantics_test.dart` are strict/widget tests, not ratcheted — no baseline file.) Regenerate with `dart run tool/update_guard_baseline.dart` after any group lands; the guard tests themselves (`flutter test test/guards/`) fail if any file's count goes *up* from here.

## Owner checklist (things that need a human, not more engineering)

- **Tamil review**: every Tamil string in this sweep (§Z/§Z2 of `spec_phase3.md`, plus anything groups 2/5 touched) is machine-drafted and needs a native-speaker pass before release, especially the newly-shortened strings (`loginReviewTermsNotice`, `aiDisclaimerNotice`, `searchStateOrUtPlaceholder`, the MSME TREDS/Udyam/GST fixes).
- **MSME content claims**: `msmeFeatureFinance5` ("Detailed comparisons of loan interest rates") is flagged in `spec_phase3.md`'s closing note as an open product question — confirm with the product owner whether the feature exists; if not, delete the line in `msme_main_features_section.dart` and its two ARB keys.
- **The skipped live test**: `test/chat_log_integration_test.dart`'s "Live Supabase Chat Logging Integration Test" group has been skipped since 2026-09-06 (anon `INSERT` revoked on `voice_chat_sessions`, RLS now requires `auth.uid()`). Needs a real signed-in test user wired into `setUpAll` to re-enable — the file's own comment explains how; do **not** re-add an anon `INSERT` grant to make it pass.
- **Beta-gate on-device QA**: the designer's reviews of Phases 2 and 3 have all been static (code review only) — "nothing run on a device (beta gate still locked)" is noted in every review doc so far. Device QA (text scale 1.0–1.6×, en/ta, 320–800dp widths — the acceptance bar `spec_phase3.md` rule 6 sets for every item) has not happened yet for anything in this sweep.
