# Feature Inventory — every screen, its purpose, and where it sits in the flow

Source: `frontend/lib/main.dart`, `frontend/lib/screens/**`. The app has **no named-route table** — `main.dart`'s `onGenerateRoute` returns null; all navigation is imperative `Navigator.push`. For the web, this maps naturally to Next.js's file-based App Router (see 05-ROUTING-MAP.md).

## Startup / auth chain

Entry point is always `SplashScreen` (`main.dart`), which resolves session/beta/language state and routes accordingly.

| Screen | Purpose | Flow position |
|---|---|---|
| `splash_screen.dart` | Animated splash; resolves session/beta/language and routes to the right next screen | Entry point |
| `beta_gate_screen.dart` | Password gate | Shown before anything else while the app is in beta and not yet unlocked on this device |
| `language_selection_screen.dart` | Choose English/Tamil | First run only (no cached language) |
| `login_screen.dart` | Google OAuth consent + sign-in | Shown when there's no valid session |
| `navigation_mode_screen.dart` | Choose Regular vs. AI Companion nav mode | Session exists but profile isn't complete yet |
| `basic_profile_screen.dart` + `basic_profile/step{2,3,4}_*_form.dart`, `about_you_profile_screen.dart`, `location_profile_screen.dart`, `eligibility_profile_screen.dart` | 4-step onboarding wizard (basic details → location → role → eligibility) | Post-login, pre-profile-completion |
| `eligibility_results_screen.dart` | Shows scored scheme matches right after the wizard | End of onboarding |

## Main app shell — 5-tab bottom navigation

`MainTabsContainer` is a 5-tab `IndexedStack` (all tabs built once and kept alive; back-button intercepted for search-clear → tab-history-pop → app-exit, in that order).

| Tab | Screen | Notes |
|---|---|---|
| 0 — Home | `home_screen.dart` (Regular) **or** `companion_mode/saarthi_home_screen.dart` (Companion) | Switched by the user's `navigationMode` setting; Companion mode hides the bottom nav entirely |
| 1 — Search | `regular_mode/search_screen.dart` | Also reachable from Home's search bar, voice query, and category taps (which cross-navigate here with a pre-filled query) |
| 2 — Discover | `regular_mode/categories_screen.dart` | Category/ministry/state browsing |
| 3 — Saved | `regular_mode/saved_schemes_screen.dart` | Bookmarked schemes |
| 4 — Profile | `profile_screen.dart` | User info, settings, logout |

## Pushed screens (not tabs)

| Screen | Purpose | Reached from |
|---|---|---|
| `regular_mode/scheme_details_screen.dart` (+ `scheme_details/*.dart` tabs: Overview/Benefits/Eligibility/Documents/Services/Process) | Full scheme detail view | Any scheme card, anywhere |
| `regular_mode/msme_module_details_screen.dart` (+ `msme/*_panel.dart`: export, gov hierarchy, institutions, tax/GST, TReDS) | MSME support hub | Home quick-actions / Discover |
| `regular_mode/help_support_screen.dart` (+ `help_support/*.dart`) | FAQs, feedback, report-issue | Profile → Help & Support |
| `notifications_screen.dart` (+ `notifications/*.dart`) | Alerts list | Bell icon on Home/tabs |
| `regular_mode/settings_screen.dart` | Language, navigation mode, notifications toggle, privacy/terms, delete account | Profile → Settings |
| `regular_mode/sarvam_chat_screen.dart` | Text chat ("Ask AI") | Home "Ask AI" button |
| `companion_mode/saarthi_welcome_screen.dart`, `companion_voice_agent_launcher.dart` | Voice session entry (Companion mode) | Companion Home |
| Bottom sheets under `categories/`: `document_checklist_sheet.dart`, `dpiit_checklist_sheet.dart`, `emi_calculator_sheet.dart`, `gst_calculator_sheet.dart`, `subsidy_estimator_sheet.dart`, `udyam_classifier_sheet.dart`, `valuation_estimator_sheet.dart` | Standalone calculator/checklist utilities | Discover → "Business Utilities & Tools" row |
| `regular_mode/legal_screens.dart` | Full Terms/Privacy text | Consent checkboxes, Settings |

## Auth & session flow (replicate for the web, with browser-specific adjustments)

1. Load cached language + profile.
2. Validate the Supabase session: if present, call `auth.getUser()`; treat a network-unreachable error as "trust the cached session" (don't sign out just because the app started offline), treat a 400/403/404/invalid-user error as "session is genuinely invalid."
3. If session is null but an OAuth redirect is pending, wait briefly (mobile app: 12s, watching `onAuthStateChange`) before giving up.
4. **Beta gate interception**: if beta mode is on and not yet unlocked on this device, show the gate before anything else.
5. Route decision (`resolveStartupDestination({hasSession, hasCachedLanguage, profileCompleted})`):
   - `hasSession` → `profileCompleted ? home : navigationModeScreen`
   - else → `hasCachedLanguage ? loginScreen : languageScreen`

**Web-specific differences:**
- Mobile uses `signInWithOAuth(..., redirectTo: 'com.inschemes.app://login-callback/', launchMode: externalApplication)` — a deep link. The web port uses `supabase-js`'s standard browser OAuth redirect (an HTTPS `redirectTo` URL) — no deep-link race condition, no `isOAuthPending` polling needed, since the browser just navigates back to the site directly.
- The mobile app hand-rolls a `SessionCacheService` for language/profile/nav-mode caching on top of Supabase's own session persistence. A web port can likely just rely on normal Supabase session persistence plus `localStorage` for the same small set of cached fields — no need to replicate the mobile-specific caching layer wholesale.
