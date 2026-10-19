# Hindi / Tamil UI sweep — progress and handoff

Last updated: 2026-10-17. Working branch at the time: `feat/hindi-localization` (3 commits ahead of
`origin/main`). **Nothing from this sweep is committed yet** — see "Not done yet".

## Ground rules from the user
- Scheme data and scheme logic are out of scope ("only schemes can be skipped for now").
- Goal: no English where Hindi should show, then the same for Tamil; hardcoded text gets fixed at its
  source, loaded data gets fixed where it loads.
- After everything: create a branch and run the PR checks.

## What is done

### Access / testing
- `--dart-define=MSS_SKIP_BETA_GATE=true` skips the beta screen (default unchanged: gate is on).
  Run on the emulator: `flutter run -d emulator-5554 --dart-define-from-file=dart_defines.json --dart-define=MSS_SKIP_BETA_GATE=true`.
- Google sign-in could not be completed on this emulator (Chrome stops responding); the app side works
  up to the browser hand-off and nothing in the sign-in code depends on language.

### Hindi availability
- Hindi is now active in the release: `ACTIVE_LANGUAGES` in `tools/build_catalog_release.py` and
  `frontend/assets/catalog/release.json` (only `activeLanguages` + `languagePacks.hi.isActive` changed).
- New migration `backend/supabase/migrations/20261017000000_activate_hindi_language.sql`
  (flips `catalog.language.is_active` for `hi`). **Written, not applied.**
- Home header has a language menu (`home_language_button.dart`): English / தமிழ் / हिन्दी, gated by the
  same "is Hindi supported" check as the picker (kill switch still works).
- Language picker bug fixed: opened from Settings in Hindi it previewed English.
- Settings / Profile show the current language in its own script (`utils/language_names.dart`).

### Typography
- Noto Sans Devanagari bundled (`assets/fonts`, `pubspec.yaml`), added to `AppFonts.fallback`;
  Hindi gets the same +0.10 line-height bump as Tamil (`app_text.dart`).

### Translation mechanism
- `CentralizedTranslator` is now language aware: `localize()`, `localizeTag()`, `localizeFor(lang, ...)`,
  `localizeTagFor(lang, ...)`, `activeLanguage`. `AppProvider`'s `_selectedLanguage` setter keeps
  `activeLanguage` in sync; `main.dart` also sets it. `translate()`/`translateTag()` are still Tamil-only.
- Exact dictionary matches now win over the "protected text" (URL) check, for Tamil and Hindi.
- New `assets/catalog/translation_dictionary_hi.json` (same keys as the Tamil dictionary) plus extra
  entries added to **both** dictionaries (voice/chat messages, MSME blurb, institution names, legal text).
- ~55 call sites converted from `isTa ? translate(x) : x` to `localize(x)` (MSME module, categories
  utilities, calculators, notifications toasts, voice widgets, etc.); unused `isTa` locals removed.
- Service messages (voice recognition, Saarthi chat, account deletion) go through `localize()`.

### Hardcoded strings moved to the ARBs (en/ta/hi)
- About dialog, location-services dialog, catalog freshness footer, login consent sentence, form hints,
  tooltips, legal link titles, Home update title, Settings fallback name.
- Legal text (Terms, Privacy Notice, Privacy Policy, consent modal and the two full-screen pages) is
  localized through the dictionaries (167 strings, Hindi + Tamil). **Machine-drafted — needs legal review.**
- Guided assessment follows the active language (Hindi from the existing ARB strings).
- Voice assistant chrome shows Hindi for Hindi users unless they speak Tamil.
- Two wrong existing strings fixed: `schemesAvailableCount` (ta dropped `{count}`; hi missing a space).

### Layout
- Notification cards: rows made flexible (Tamil overflowed in 4 places, English had 1).
- Valuation sheet dropdown `isExpanded` (1.6 px overflow).

### Tests added
- `arb_parity_test.dart`, `centralized_translator_hi_test.dart` (incl. "every localize() literal has a
  Hindi entry"), `home_language_button_test.dart`, Devanagari case in `bundled_fonts_test.dart`.
- `hindi_ui_audit_test.dart` + `test/fixtures/ui_audit_allowlist.json`: renders 30 screens + 17
  dialogs/sheets in hi and ta; fails on any English text or layout error not on the reviewed allowlist.
  Report mode: `--dart-define=AUDIT_LANG=hi --dart-define=AUDIT_OUT=<file.json>`.
- Updated: `translation_dictionary_parity_test` (phrases `>= 428`), `explore_msme_module_localization_test`
  (ignores domain names), `tools/test_gate_suite.py` T5 fixture.

## Last verified state (2026-10-17)
- `flutter test`: 665 passed, 1 skipped, **1 failed** — `guards/color_tokens_test` (raw colour literals in
  `language_selection_screen.dart`: 26 vs baseline 24). Pre-existing, not touched by this work.
- `flutter analyze`: 6 issues, all pre-existing (`language_pack_manager.dart`, `hindi_search_quality_test.dart`).
- `tools/test_gate_suite.py`: T1-T9 behave as expected.
- Backend: `npm run functions:test` 18 passed; `npm run openapi:lint` valid. DB checks (`db:reset`,
  `db:test`, `db:lint`) need Docker, which was not running — **not run**. No DB test references
  language activation.

## Not done yet
1. **Create the branch, commit, run the PR checks, open the PR** (user asked for this at the end).
   - Suggested branch from current HEAD: `feat/hindi-ui-sweep`.
   - The user had uncommitted work in `tools/build_catalog_release.py`, `generate_catalog_bundle.py`,
     `release_gate.py`, `test_gate_suite.py` and many untracked docs/PDFs before this session. Do **not**
     sweep those in. My hunks in the two tools files: `ACTIVE_LANGUAGES` const + `is_active` line +
     `activeLanguages` line (build script), and the T5 `activeLanguages` line (gate suite) — stage only
     those (filtered `git diff -U0` + `git apply --cached --unidiff-zero`).
   - Do not push without asking.
2. Apply the migration to the real Supabase project and re-publish the release manifest (production
   activation; runbook in `docs/FINAL_HINDI_LOCALIZATION_REPORT.md` section 6). The Supabase MCP here only
   sees an unrelated empty project.
3. Run the Docker-based backend checks when Docker is available.

## Known gaps / decisions for later
- Voice assistant understands and answers English/Tamil only (reply engine, STT/TTS tags); Hindi
  speech is feature work.
- Scheme content, scheme-card tags, eligibility-evaluator labels, assessment profile matcher text were
  skipped on purpose.
- "Google User" fallback name is stored in the profile, so it stays English.
- Audit allowlist still holds legitimate Latin text (acronyms, programme/institution names) and one
  pre-existing Flutter ListTile advisory on the institutions panel.
- Pre-existing: `GoogleFonts.inter()` logs "font Inter-* not found in application assets" on first
  launch (text still renders); not investigated.
- Cold start on the emulator shows "No internet connection" until Retry (all languages).
- Hindi legal text and Hindi/Tamil voice/chat messages should be reviewed by a human.

## On-device verification (2026-10-17, emulator-5554, Hindi and Tamil)
Toured Home, Search + results, Scheme details, Explore, Notifications, Profile, Settings in both languages.
Found and fixed: glued ARB placeholders (hi), time-ago units, Tamil bottom-nav label wrapping, stored
profile values (e.g. gender saved as a Hindi label) shown in another language, notification card
overflow. Remaining English is scheme data only (tags, authority lines), skipped by request.
Incident: the temporary debug harness wrote a sample name/district to the signed-in profile (synced to
Supabase) and switched its saved language; name/state/district were restored, language was left at the
last tested one (ta). The harness was deleted and is not in the repo.
