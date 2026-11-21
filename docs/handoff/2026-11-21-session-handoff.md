# Session handoff — 2026-11-21

For the next agent or session. Read this file first, then `AGENTS.md`.

## Where things stand

**Branch `feat/login-copy`** (local, **not pushed**), on top of `main` at `4b3198c`:

1. `c932a04` — login screen has less text:
   - Removed "Continue securely", "Use your Google account to sign in or create your MSS account" (there is no separate MSS account), the "I have read and agree…" sentence, and the "secure browser window" line.
   - The "Please review the Terms of Use and Privacy Policy before continuing" line is now at the top of the card, as the user asked.
   - `clearSession()` (sign-out) now also keeps `onboarding_v2_seen`, so the onboarding pages don't come back after sign-out.
2. `af7d019` — wording audit fixes in en/hi/mr/ta, all approved by the user (see the commit message):
   - promises the app doesn't keep,
   - hype,
   - no exclamation marks,
   - home labels in sentence case.
   - The user said **keep "students"** in the onboarding audience line.

**Checks:**
- `flutter analyze`: clean.
- Full `flutter test`: only one failure (`official_terms_test`), now fixed. Its file plus the parity and splash tests pass (18).
- The new login screen was checked on the GPU emulator.
- **The other reworded screens have not been looked at on the device yet.** Those are onboarding, the mode choice, the splash, the Saarthi home greeting, the MSME support page and the home labels.

## Next steps

1. Look at the reworded screens on the emulator (`emulator-5554`, AVD `Pixel_7`). Keep Tamil and Hindi lines from wrapping badly.
2. Push `feat/login-copy`, open a PR, and merge it once gitleaks passes. The user has merged similar PRs themselves after a device check. This repo merges with `gh pr merge --merge`.
3. Optional: remove now-unused ARB keys `continueSecurely`, `googleAccountContinue`, `secureBrowserAuth` and `loginSubtitle` in all 4 languages. Run `flutter gen-l10n` after.

## Analytics plan (added later on 2026-11-21)

- Plan only: `docs/ux/2026-11-21-analytics-backbone-plan.md`.
  - It covers footfall, most searched schemes, and who searched what, cut by the 14 profile features named with questionnaire `field_id`s.
  - It defines events, identity and sessions, an offline queue, a proposed `POST /v1/analytics/events` contract, phases, and decisions A–D: guest demographics, consent, minimum cell size, where reports live.
- Not started in code. Phase 1 waits on decisions A–D and a privacy policy update with legal review.
- §10 of the plan answers the officials' open questions. Points to raise with them:
  - **PSI-2019 may be replaced** by Maharashtra's Industries, Investment and Services Policy 2025.
  - **The CMEGP cap is disputed** (₹50L/₹20L vs ₹1Cr/₹50L).
  - **A dedicated `project_cost_inr` question** is recommended.
- The user re-asked to keep the "Please review…" line at the top of the login card. It already is, in `c932a04`. Open question: should it stay visible after both documents are ticked? Today it hides.

## Adaptive questions plan (added later on 2026-11-21)

- Plan only: `docs/ux/2026-11-21-adaptive-questions-plan.md`.
- Root causes, measured on the 417-scheme catalog:
  - The beneficiary answer is a hard filter, but only 100 schemes have `specialCategories` (71 tagged `women`).
  - The scheme-type keyword filter drops the 85 schemes with no `schemeType`.
  - The filters stack, with no fallback when results are few.
  - Submit overwrites the user's real profile.
- Phase 0 quick fixes are proposed; waiting on the user's decision A.
- PR #207 is open (login text, wording audit, docs): clean, gitleaks passing. PR #201 is clean.

## Context the next agent needs

- **Backend is out of scope.** DEV 1 tasks 1.2–1.4 (`mss-backend`) belong to another dev. The handoff is `docs/handoff/2026-11-20-dev1-backend-tasks-1.2-1.4.md`.
- **Goals doc:** `docs/ux/2026-11-20-guest-and-first-run-ux-goals.md`.
  - Done: goals 1–6.
  - Analytics will be planned separately; events should go to our own DB.
  - Waiting: personas (7) and the guest answers store (8).
- **Merged today:**
  - PR #204: guest follow-up.
  - PR #205: guest UX for Saarthi, Settings, Search and Saved.
  - PR #206: mode choice, tours, equal weight, no dead ends.
- **PR #201** (questionnaire dataset, DEV 1 task 1.1) is still open.
- **Emulator**
  - Start it with `-gpu host -dns-server 8.8.8.8,1.1.1.1`; without the DNS flag, network lookups fail.
  - The **lock PIN is entered by the user**, never by the agent.
  - Don't sleep or wake the display: that re-locks it.
  - The first launch right after `adb install -r` can render blank; a relaunch fixes it.
- **Device data:** install builds only with `adb install -r` (same debug signer). Never uninstall `com.inschemes.app` (AGENTS.md rule 9).
- **Release APK:** `flutter build apk --release --dart-define-from-file=dart_defines.json`.
  - It signs with the local `key.properties` (cert `cc58f15a…`).
  - Hand it over in `~/Downloads`. Never publish to the release feed without being asked.
- **Workflow and style**
  - A gate hook asks for "facts" before the first edit of each file; give them and retry.
  - Running `dart format` moves `// style-ok`, `// tap-ok` and `// spacing-ok` markers. Put them back on the flagged line, or the guard tests fail.
  - The user writes casually; answer tersely (caveman mode is on).
