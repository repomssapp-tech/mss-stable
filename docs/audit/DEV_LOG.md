# Developer Change Log

Append-only log of merged PRs, keyed by GitHub username. Rows below "Automated entries start here" are appended automatically by `.github/workflows/dev-log.yml` when a PR merges into `main` — do not edit them by hand; fix mistakes with a follow-up PR instead. Rows above that line are a manual backfill from git history, added when this log was created.

See `docs/RULES.md` §4 for the rule this log enforces.

| Date | GitHub user | PR # | Area | Summary |
|---|---|---|---|---|
| 2026-09-12 | Roger-Chris | #100 | onboarding | Onboarding restructure (merge 1 of 2). |
| 2026-09-13 | Roger-Chris | #101 | onboarding | Onboarding restructure (merge 2 of 2). |
| 2026-09-13 | Roger-Chris | #102 | backend/edge-functions | Cleanup of on-device SLM experiment and superseded edge functions. |
| 2026-09-13 | Roger-Chris | #103 | docs | Removed 36 unused, obsolete, and historical markdown files. |
| 2026-09-13 | Roger-Chris | #104 | docs | Flattened docs structure to one level; reconciled architecture docs against code. |
| 2026-09-13 | Roger-Chris | #105 | backend/tooling | Removed redundant root `package.json`/`package-lock.json`. |

<!-- Automated entries start here — .github/workflows/dev-log.yml appends below this line -->
| 2026-09-13 | Roger-Chris | #107 | unspecified | Chore/audit rules skills devlog |
| 2026-09-17 | PaulBrytonRaj18 | #109 | frontend/companion_mode | Replaced the static marketing welcome screen with an accessible, zero-keyboard 6-step Assisted Profile Creation wizard for AI Companion Mode that feeds directly into the scheme recommendation engine, and resolved PostgreSQL check-constraint failures during cloud profile submission. |
| 2026-10-02 | Roger-Chris | #110 | unspecified | Production readiness: correctness, design system, accessibility (Phases 1–2, partial 3) |
| 2026-10-05 | Roger-Chris | #111 | unspecified | This PR delivers the complete, verified, and locked remediation of **MSME Catalog v3.1** (promoted to **Release `1.35.1-alpha`**), resolving all audit findings from `docs/audit/CATALOG_V3_1_AUDIT.md`, executing all remediation phases from `docs/audit/ANTIGRAVITY_FIX_PROMPT.md`, and completing the final verification housekeeping items from `docs/FINAL_VERIFICATION_1_35_1.md`. |
| 2026-10-17 | praveen-ofl | #113 | unspecified | feat(api): integrate MSS REST backend client, auth PKCE flow, and pro… |
| 2026-10-18 | Roger-Chris | #112 | unspecified | - Hindi UI localization across the app: language-aware translator + Hindi dictionary, ARB moves for hardcoded strings (en/ta/hi), Devanagari font, Home language menu, Hindi in the picker/Settings, Hindi activated in the release manifest. |
| 2026-10-19 | Roger-Chris | #114 | unspecified | - Replace Supabase with the MSS REST backend (`https://api.msmeschemes.org`) for auth, profile, onboarding, notifications, promotions, favorites and support tickets. Old Supabase material is archived in `docs/old_supabase/`. |
| 2026-10-19 | Roger-Chris | #115 | unspecified | fix(saarthi-agent): sort imports and apply ruff format to pass CI |
| 2026-10-20 | Roger-Chris | #116 | unspecified | Feat/multilingual search recommendations |
| 2026-10-20 | Roger-Chris | #117 | unspecified | Feat/multilingual search recommendations |
| 2026-10-20 | praveen-ofl | #118 | unspecified | feat(api): integrate push and sse notifications, password dialogs, an… |
| 2026-10-20 | nyxri0f8 | #119 | docs | Redesigns the root README with a centred header, badges, an overview table and five Mermaid diagrams (system architecture, user journey, offline catalog sync, Saarthi voice pipeline, quality gates). Also corrects stale details: adds Hindi localization, Dart 3.11+ per `pubspec.yaml`, Push/SSE notifications, and drops the hard-coded test count. |
| 2026-10-20 | nyxri0f8 | #120 | docs | Adds `LICENSE-MIT` and `LICENSE-APACHE` (official texts from GitHubs license API) so the code is dual-licensed under MIT or Apache-2.0 at the users option, and updates the README License section to explain this and the contribution terms. Bundled third-party assets (e.g. OFL fonts) keep their own licenses. |
| 2026-10-20 | Roger-Chris | #121 | unspecified | Feat/multilingual search recommendations |
| 2026-10-20 | nyxri0f8 | #122 | docs | Adds a papercraft-style app banner (`docs/assets/mss-banner.png`, 1600x600) to the top of the README, built from real screens of release 1.2.1 (Discover, Search with the new Not applicable to you pill, Scheme Details). Also adds Marathi to the Languages badge, since Saarthi speaks Tamil, English, Hindi and Marathi. |
| 2026-10-21 | nyxri0f8 | #132 | unspecified | Fix QA bugs from the 1.2.1 / 1.3.0 test reports; security hardening; app 1.4.0+8 |
| 2026-10-21 | nyxri0f8 | #133 | unspecified | Fix onboarding loop after signing in again (#123) |
| 2026-10-21 | nyxri0f8 | #134 | unspecified | chore(release): app 1.4.1+9 |
| 2026-10-21 | Roger-Chris | #135 | unspecified | fix(profile): adopt ETag from every profile write, serialize saves, f… |
| 2026-10-21 | Roger-Chris | #136 | unspecified | Fix/login consent links |
| 2026-10-21 | Roger-Chris | #137 | unspecified | fix(a11y): label the remaining close buttons; guard test |
| 2026-10-21 | Yogeeshwar-project | #138 | frontend/hindi-qa | Fix the remaining frontend findings from the Hindi QA report: translate PMEGP beneficiary/amount/document content, make scheme tabs scroll to distant sections, run typed searches with no-match feedback, align the Profile completion badge with Settings, and correct the Hindi EMI total label and eligibility FAQ. Add regression coverage and a finding-by-finding Markdown fix log. |
| 2026-10-21 | Roger-Chris | #139 | unspecified | Fix/hindi test report |
| 2026-10-21 | nyxri0f8 | #140 | unspecified | chore(release): app 1.4.2+10 |
| 2026-10-21 | Anto-Merary | #141 | unspecified | Replace LiveKit with accessible Sarvam voice conversations |
| 2026-10-21 | nyxri0f8 | #142 | unspecified | chore(release): app 1.4.3+11 |
| 2026-10-22 | nyxri0f8 | #146 | unspecified | Fix toasts behind sheets, filter counts at startup, catalog coverage, and #145 UI findings |
| 2026-10-22 | nyxri0f8 | #147 | unspecified | fix(hindi): resolve Hindi QA findings (#144) |
| 2026-10-22 | nyxri0f8 | #154 | frontend/profile, frontend/catalog | Finishes the items #146 and #150 left open: the three #145 decisions (district picker, avatar, password rule) and the `CEN2026-090` coverage gap that #143/#152 require, plus the lint #150 introduced. |
| 2026-10-22 | Roger-Chris | #151 | frontend/ui (onboarding, home, search, discover, saved, profile) | One commit per section of the issue. Onboarding shows a progress overlay while the profile is saved. The Explore MSME pages lose the duplicate top title (back arrow kept) and show the institutions list inline, with Tamil names translated. Search gets a pulsing mic and Listening… hint, a single shared shimmer skeleton, and no skeleton flash while refining results. Discover drops Ministry of Health and the DPIIT checklist is corrected. Saved recents are newest-first and manage mode no longer carries across tabs. Profile completion accepts the single address line, and Settings and About share one version label. |
| 2026-10-22 | Roger-Chris | #156 | frontend/catalog (bundled packs), tools | Two changes to the bundled catalog packs, each made by a repeatable, idempotent tool: |
| 2026-10-23 | Roger-Chris | #158 | unspecified | Nav bar, Google avatar, startup speed, Home View All (on top of #155) |
| 2026-10-23 | nyxri0f8 | #159 | .github/workflows (build-app.yml) | The signed app build took about 25 minutes because its steps ran one after another: about 10 minutes of tests, then about 13 minutes of APK with every Gradle dependency downloaded fresh, then 2 minutes of web. Now `verify` (analyze + test), `build` (APK) and `web` run as parallel jobs, and `setup-java` caches `~/.gradle`. That cache holds the dependencies, the wrapper, and the build cache that `org.gradle.caching=true` already fills. A final `promotable` job needs all three, so a build is still only promotable when analyze and test pass. Signing, version checks and artifacts are unchanged. |
| 2026-10-23 | nyxri0f8 | #160 | frontend/tests | `AppConstants.getTimeGreeting` returns `greetingLateNight` (Hello,) before 05:00, but `home_greeting_and_search_pills_test` and `l10n_misc_batch5_test` expected Good Evening. They failed whenever the suite ran between 00:00 and 05:00, which broke signed build run 39886084706 at 01:52 UTC. Both tests now follow the same brackets as the app code. The app code is unchanged. |
| 2026-10-23 | nyxri0f8 | #161 | .github/workflows (build-app.yml) | The `promotable` job added in #159 has no checkout, so the workflow-wide default `working-directory: frontend` does not exist and the job failed. That happened in run 39887313807 even though verify, build and web all passed. It now runs from the workspace root. |
| 2026-10-23 | nyxri0f8 | #162 | frontend/notifications (Android) | The launcher logo has a transparent background, so it disappeared in the notification panel. Notifications shown by the app now use the MSS logo on a white rounded square as the large icon (`res/drawable-nodpi/ic_notification_large.png`). The small status-bar icon is tinted brand blue (`AppColors.primary`): for FCM pushes through `default_notification_color`, and for local notifications through `color`. |
| 2026-10-23 | nyxri0f8 | #164 | frontend/home, frontend/saved, frontend/navigation | These are the home screen, Saved and nav bar changes from device feedback on 1.4.5. |
| 2026-10-23 | Roger-Chris | #165 | unspecified | Login loading overlay, on-device notification translation, floating nav bar fixes |
| 2026-10-23 | Roger-Chris | #166 | unspecified | QA pass: Tamil bold titles, Hindi login text, translated scheme titles, label fixes |
| 2026-10-23 | Roger-Chris | #167 | unspecified | fix: logout persistence and account deletion progress flow |
| 2026-10-23 | nyxri0f8 | #169 | frontend/auth | When the Google code exchange fails, the app now shows Unable to complete Google sign in. Please try again. instead of silently returning to the login screen (requested in the backend bug report for the 23 Oct `/v1/auth/exchange` 500). |
| 2026-10-23 | nyxri0f8 | #170 | frontend/release | Bump the app version to 1.4.8+16 for the next release APK, which ships the 30-day account-deletion grace with the reactivate prompt (#168), the sign-in failure message (#169) and the logout/account-deletion fixes (#167). 1.4.7+15 is already tagged (`app-v1.4.7+15`), so the build must go up to install as an update. |
| 2026-10-24 | Roger-Chris | #172 | frontend/performance (app shell, Discover tab, bottom nav bar) | Removes the UI freeze on tab switches and trims per-frame and per-tap work. Measured with p50/p90/p99 frame timings on an emulator: `main` froze the UI thread for 8–12 s across 18 tab taps; this branch froze it for 0–41 ms. |
| 2026-10-24 | nyxri0f8 | #173 | frontend/updates, .github/workflows (build-app.yml), release | This builds on #171 (Roger-Chriss update notice) and includes its commit, merged with the latest `main`. Merging this also lands #171. It fixes #171s blocker: `Roger-Chris/MSS_App` is private, so its releases return 404 for users. |
| 2026-10-24 | nyxri0f8 | #175 | frontend/android (build config) | The 2.2.0+18 signed build failed compiling permission_handler_android 14.1.0 (added with the permissions screen), which needs compileSdk 37; the root `android/build.gradle.kts` forced all plugins to 36. The app and the plugin override now compile against SDK 37. `targetSdk` stays 36, so runtime behaviour is unchanged. |
| 2026-10-24 | nyxri0f8 | #176 | frontend (nav bar, Saarthi header, Settings) | The bottom bar is now a white pill with outline icons in soft lavender circles; the active tab is a frosted purple glass bubble that is a plain circle at rest and stretches into a droplet with a trailing tail while it moves (tap or finger drag). Icons only, fixed 64dp, every tab still announced with its label. Saarthis header says "Powered by Sarvam AI" (en/ta/hi). Settings no longer repeats the profile card and Edit Profile group shown right after the Profile tabs banner (kept in companion mode, which has no tab bar). |
| 2026-10-24 | nyxri0f8 | #177 | frontend (release 2.2.1+19) | Version 2.2.1+19 and its CHANGELOG entry (the Unreleased items from PR 176: white nav bar with a round frosted purple bubble, Powered by Sarvam AI, Settings no longer repeating the profile card). The in-app update notice shows this entry. |
| 2026-11-03 | Roger-Chris | #178 | frontend/l10n, frontend/catalog, frontend/search, tools/translation | Adds Marathi as a fourth app language for Maharashtra schemes through one shared content path, and carries the Tamil corrections from the catalogue audit. Scheme content no longer needs per-language code, and the translation pipeline is merged in. |
| 2026-11-03 | Roger-Chris | #179 | unspecified | fix(language): translate the remaining Marathi screen text |
| 2026-11-03 | Roger-Chris | #180 | unspecified | chore(release): 2.3.1+21 |
| 2026-11-03 | Roger-Chris | #181 | unspecified | fix(language): correct Hindi, Tamil and Marathi screen text |
| 2026-11-04 | Roger-Chris | #182 | frontend/UI | Applies the app design tokens across regular screens and onboarding, removes unreachable screens and widgets, and corrects scheme labels and amount displays. |
| 2026-11-04 | Anto-Merary | #183 | unspecified | Fix Saarthi suggestions to match spoken and typed replies |
| 2026-11-04 | Roger-Chris | #184 | release | Bumps the app to 2.4.0+23 and adds the changelog entry for the redesign (#182) and Saarthi scheme-card matching (#183). The full test suite passed on the merged tree (1,757 passed, 3 skipped). |
| 2026-11-05 | Roger-Chris | #185 | frontend/saarthi | The Saarthi screens drifted from the Saarathi redesign canvas: a later commit swapped its Ashoka navy, saffron and green for the apps generic blue, and regular Homes Ask Saarthi still opened the old v2 Type screen. This restores the canvas look on Home, Conversation, Listening, Typing and Old sessions, routes Ask Saarthi to the redesigned home, and removes the unreachable old Type screen. |
| 2026-11-05 | Roger-Chris | #186 | release | Bumps the app to 2.4.1+24 with the changelog entry for the Saarthi design fix (#185). The full test suite passed on that change (1,748 passed, 3 skipped). |
| 2026-11-05 | Anto-Merary | #187 | Flutter UI, localization, notifications | Updates the navigation, MSME, Saved and Profile screens, localizes app copy and keeps opened notifications read across refreshes and restarts. |
| 2026-11-05 | Anto-Merary | #188 | Developer Change Log workflow | Apostrophes in the app's PR summary now survive the developer log parser. Restore the missing entry for #187. |
| 2026-11-05 | Anto-Merary | #189 | Android release | Prepare MSS 2.4.2 build 25 for the UI, localization, and notification read fixes in #187. |
| 2026-11-05 | Anto-Merary | #190 | unspecified | Fix profile layout, MSME headers, and Android navigation |
| 2026-11-05 | Anto-Merary | #191 | unspecified | Release MSS app 2.4.3+26 |
| 2026-11-05 | Anto-Merary | #192 | unspecified | Pin the Android APK release verifier |
| 2026-11-05 | Anto-Merary | #193 | unspecified | Keep Android navigation buttons legible on dark startup screens |
| 2026-11-05 | Anto-Merary | #194 | unspecified | Disable legal acceptance until the end and release 2.4.4+27 |
| 2026-11-05 | Anto-Merary | #195 | unspecified | Update the sign-in consent test for disabled Accept |
| 2026-11-06 | Roger-Chris | #196 | frontend/search, frontend/home, frontend/profile, frontend/l10n | Home "Recommended for you" and Search "For Me" now share one picker, so they always agree. A usable profile with no strong match sees its closest partial matches under "No perfect match yet". Back-button headers across screens now match the search results header. The profile card's Edit button and titles stay on one line in every language. Marathi strings that kept English names now match Hindi and Tamil. |
| 2026-11-06 | Roger-Chris | #197 | release | Bump to 2.4.5+28 and add its changelog entry for the changes in #196 (matching recommendations, consistent headers, profile Edit button, Marathi strings). |
