# Hindi QA report fixes

Date: 21 October 2026

Source: `MSS-Hindi-Testing-Report.pdf`, app 1.2.1 (build 6), baseline `b9b2b9b`.

PR integration base: `34cf495` (main, app 1.4.1+9). Newer main changes were preserved while applying the remaining report fixes. Rows below distinguish fixes inherited from main from changes in this PR.

This change addresses the findings in the supplied Hindi testing report. Changes are limited to frontend presentation, the reported frontend behavior, localization resources, regression tests, and this document. Backend code, API contracts, endpoint configuration, the Saarthi agent, and canonical scheme catalog bundles are unchanged.

## Finding-by-finding status

“Fixed” below means implemented and checked in frontend automated tests/source review. It does not mean the new build has been manually retested on the Samsung phone.

| ID | Reported issue / original screenshots | Status and change |
| --- | --- | --- |
| HI-01 | English password sign-in dialog — 002 | Superseded on main: password sign-in was removed by the newer login flow. This PR preserves that removal and does not restore the old dialog. |
| HI-02 | English sign-in validation/authentication messages — 003, 004, 006 | Superseded on main: these messages belonged to the removed password sign-in dialog. The current authentication and consent flow is preserved. |
| HI-03 | English PMEGP beneficiary, amount note, and documents — 007–009 | Fixed: missing Hindi exact-match translations added for the reported PMEGP content, including “Current project-cost ceiling applies.” The Hindi scheme view translates document names, explanations, fee notes, authorities, and remarks. Conditional badges use the existing localized label. Canonical document flags and URLs are preserved; portal lookup uses the original catalog name so translating the name retains the existing portal button. |
| FN-01 | Scheme tab selection does not scroll to its section — 010, 011 | Fixed: the finite set of scheme section anchors stays mounted, allowing distant tabs and Overview to scroll to their targets even after lengthy content is expanded. |
| HI-04 | English clipboard confirmation — 012 | Already fixed on main: native sharing and its localized clipboard fallback are preserved. |
| FN-02 | Empty Recently Viewed after opening a scheme — 013 | Already fixed on main: entering the scheme details screen records its ID in viewing history. Regression coverage retained. |
| FN-03 | Obsolete Udyam limits and wrong classification — 014, 015 | Already fixed on main: shared limits in crore are Micro ≤2.5/≤10, Small ≤25/≤100, and Medium ≤125/≤500. Both limits must be met. This PR preserves the shared classifier and tests its boundaries. |
| OBS-01 | EMI rejects zero interest — 016 | Already supported on main: an explicitly entered 0% rate uses principal ÷ months. This PR retains that implementation and additionally rejects non-finite inputs. Blank and negative rates remain invalid. |
| HI-05 | EMI total label says integer instead of interest — 017 | Fixed: Hindi label is “कुल राशि (मूलधन + ब्याज)”. |
| HI-06 | Entrepreneur value remains English in Profile — 018 | Fixed: the stored English role and corresponding localized labels render through the existing Entrepreneur localization key. |
| HI-07 | English password-settings validation — 019 | Main already localizes validation and hints. This PR also replaces the remaining raw server-error fallback with the existing localized update-failure message. Password rules and backend requests are unchanged. |
| HI-08 | English Active/Auth labels in sessions — 020 | Already fixed on main: localized status, authentication time, device labels, and feedback are preserved and regression-tested. |
| FN-04 | Settings shows 100% while Profile says incomplete — 021, 022 | Fixed: the Profile badge uses the same existing completion percentage as Settings, instead of a separate persisted onboarding flag. No stored profile or backend completion value is rewritten. |
| HI-09 | FAQ refers to absent Find My Schemes tab — 023 | Fixed: the answer directs users to complete Profile, open Search, select For Me, and review the scheme's eligibility criteria. Matching localized instructions are present in all supported resource files. |
| FN-05 | Typed unmatched query leaves browse content visible — 024 | Fixed: text changes run the existing offline search after a 300 ms debounce. Unmatched queries reach the existing localized no-results view without needing keyboard submission. Clearing the query restores idle browsing; older search responses are invalidated when text changes. |
| FN-06 | Saarthi Hindi prompt and Retry fail — 025, 026 | **Unresolved; requires service investigation.** The client uses `PendingEndpoints.chat` (`POST /v1/chat`), which the repository documents as an assumed route without an authoritative contract. This is evidence of a service dependency, not proof of the original runtime failure's cause. No backend, route, credentials, retry semantics, or fallback answers were changed. |
| EXT-01 | Official PMEGP site rejects fresh applications — 027 | **External restriction; unchanged.** The report confirms the app's link handoff worked. The app cannot change the official portal's application-availability notice. |

Udyam reference: [official Udyam registration portal](https://udyamregistration.gov.in/), classification effective 1 April 2025. Limits were checked against the official portal during this work.

Original screenshot numbers above refer to the supplied PDF. No original evidence was overwritten. Local evidence remains in `qa-evidence/MSS-Hindi-QA.md` outside the repository; the source PDF is at `C:\Users\sethu\Downloads\MSS-Hindi-Testing-Report.pdf`.

## Final PR verification on current main

- Base: `34cf495` (app 1.4.1+9), with the remaining Hindi report fixes applied.
- `flutter analyze --no-pub`: **no issues found**.
- `flutter test --no-pub --reporter expanded`: **1274 passed, 3 skipped, 0 failures**.
- `git diff --check`: passed.
- Backend, Saarthi-agent, API routes, catalog bundles, app version, and dependency files are unchanged relative to current main.
- Current-main tests replace the obsolete password-login test because that dialog was removed upstream. They retain coverage for password settings, sessions, calculator boundaries, Hindi scheme details, profile status, viewing history, scrolling, typed search, and clearing.

These results supersede the historical pre-integration results below. The newer main already resolved the old style-guard failures; they do not fail on this PR branch.

## Verification before integration with newer main (historical)

Targeted checks:

```powershell
cd frontend
flutter test --no-pub test/hindi_report_fixes_test.dart test/scheme_details_screen_test.dart test/profile_value_formatters_test.dart --reporter expanded
flutter test --no-pub test/search_debounce_test.dart test/search_screen_filter_strip_test.dart --reporter expanded
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

- Targeted regression run: **26 passed**.
- Existing search debounce/filter tests updated for automatic search: **6 passed**. Fake-clock tests assert debounce/loading/clear behavior without waiting indefinitely for offline asset loading; the Hindi regression separately checks the actual no-results message using the real event loop.
- Static analysis: **no issues found**.
- The tests exercise Hindi login/password validation, session labels, PMEGP document translations and preserved flags/portal buttons, profile completion, Entrepreneur rendering, real tab-scroll geometry, viewing-history recording, typed no-result search and clearing, seven Udyam boundary samples, and four EMI rate samples.
- Udyam boundary samples: 2/8 and 2.5/10 → Micro; 2.5/10.01 and 25/100 → Small; 25.01/100 and 125/500 → Medium; 125/500.01 → beyond MSME limits.
- EMI samples: 120000 over 12 months gives 10000.00 at 0%, and 10661.85 at 12%. Blank and negative rates are rejected.
- Final full frontend suite: **1206 passed, 3 skipped, 4 failed**. The four failures are existing style guards: `button_style_test.dart`, `color_tokens_test.dart`, `radius_tokens_test.dart`, and `type_scale_test.dart`. They report pre-existing button styling, color, radius, and typography literals in the login, password-management, and active-session dialogs. These style findings were already present in the baseline run and are outside the Hindi report's scope. The existing i18n-literals guard now passes. No new failing tests remain.
- `git diff --check`: passed. Git comparison confirms no changes under `backend/` or `saarthi-agent/`, and no canonical catalog bundle changes.

## Scope and remaining verification

No backend or Saarthi-agent files, API routes, scheme eligibility rules, or catalog bundles were edited by this PR. The newer main's shared calculator constants, localized settings dialogs, native sharing, consent flow, and removal of password sign-in are preserved. FAQ wording is updated in all supported locales; no redundant authentication localization keys are added.

Live authentication, password changes, session revocation, Saarthi service recovery, and official application submission were not performed as part of these fixes. Microphone tests remain skipped as requested. A new phone-build walkthrough is still needed to confirm device-specific layout and interaction behavior; the original screenshots describe the pre-fix build only.
