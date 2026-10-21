# Changelog

All notable changes to the MSS app (Flutter, `frontend/`). Versions follow
`frontend/pubspec.yaml` (`versionName+versionCode`, see `docs/APP_VERSIONING.md`).
Each release is tagged `app-v<version>+<build>` and published on GitHub Releases.
Format based on [Keep a Changelog](https://keepachangelog.com/).

How to add an entry: put changes under **Unreleased** as you merge; at release time run
`dart run tool/app_version.dart bump <patch|minor|major>` from `frontend/`, move the
Unreleased items under a new heading, commit, and tag the commit.

## [Unreleased]

## [1.4.0+8] - 2026-10-21

### Fixed
- Udyam classifier and the assessment's business-size question use the 2025 MSME limits (Micro ≤ ₹2.5 Cr investment / ₹10 Cr turnover, Small ≤ ₹25 / ₹100 Cr, Medium ≤ ₹125 / ₹500 Cr) in English, Tamil and Hindi (#124).
- GST calculator uses the GST 2.0 slabs (0 / 5 / 18 / 40 %) and has a within-state (CGST + SGST) / inter-state (IGST) choice (#130).
- A scheme's details page shows its real match score, or "Not applicable to you", instead of a hard-coded "96% Match" (#129).
- A saved scheme the server refuses stays saved on the phone, and a navigation mode chosen on the phone is no longer overwritten by the server copy after a restart (#127).
- Voice search listens in the app's language (Tamil, Hindi, Marathi) instead of always en-IN (#128).
- Saarthi: when cloud voice cannot connect, it switches to the phone's own speech and says so, instead of hanging (#125).
- Settings shows the real app version; "Recently viewed" fills in; the document checklist has a Sole Proprietorship option.
- The password sign-in, password settings and active sessions screens are translated into Tamil and Hindi and follow the design system.
- Share buttons open the Android share sheet instead of only copying (BUG-10).
- Text follows the phone's font-size setting up to 2× instead of stopping at 1.12–1.3× (BUG-11).
- EMI calculator accepts 0% interest and the Udyam classifier accepts ₹0; Udyam results are in Tamil and Hindi (BUG-12, L10N-05).
- A scheme hidden only by the Filter sheet says "Doesn't match your filters" instead of "Not applicable to you", and TalkBack reads the pill (BUG-09, NEW-09).
- Scheme chips keep the same colour and order in every language (L10N-09).
- The Featured "Women Entrepreneurs" card opens the Women Entrepreneurship list (NEW-04).
- The search Filter / For Me / Sort strip wraps instead of cutting off the Tamil Sort chip; Tamil uses one word for "Filter" (L10N-04, L10N-06).
- Hindi wording: होम, विशेष, योजनाएं, खोज साफ़ करें, क्रमबद्ध करें (L10N-03).
- The "who can apply" line is no longer a word-by-word English/Tamil mix (BUG-07).
- The generated "Catalogue status …; verification …" line is no longer shown on scheme pages.
- After midnight the greeting is "Hello," instead of "Good Evening,".
- Login: the Terms of Use and Privacy Policy have full-size buttons with a tick once read (NEW-10).
- The document checklist's copy button is labelled "Copy checklist" for screen readers (A11Y-03).
- The government emblem fits inside its circle ("Government of India" no longer cropped) (UI-05).

### Security
- Access and refresh tokens are stored encrypted (Android Keystore) instead of plain SharedPreferences; sessions from older versions carry over (#131).
- The OAuth callback (with its one-time code) is no longer written to the log (#131).
- Voice agent dependencies: PyJWT 2.15.1, aiohttp 3.14.5, urllib3 2.8.0, yarl 1.25.1 (0 known advisories) (#131).
- CI scans every push and pull request for committed secrets (gitleaks).
- The sign-in PKCE verifier and the account email are stored encrypted too (SEC-02).
- Release builds are obfuscated; the symbol files are kept as a CI artifact (SEC-07).
- CI release builds use the live API host `https://mssapi.msmeschemes.org` by default (the old `api.msmeschemes.org` host is paused).

### Removed
- The retired Supabase backend: the `docs/old_supabase` archive, the `tools/` scripts that queried it, and its SQL migrations. The app uses the MSS REST backend and Firebase.

### Known issues
- Onboarding can repeat after signing in again (#123).
- The Supabase service_role key in git history must still be rotated in the Supabase dashboard (#126).

## [1.3.0+7] - 2026-10-21

### Changed
- Browse pages (Discover category / ministry / state cards, home tiles, the eligible list) are now the Search screen itself, opened on that card's schemes: the same header, search box, Filter / For Me / Sort strip, cards, empty states and "not applicable" pill. There is no second results interface any more.
- Pressing the Home search bar opens a fresh search page (no old results, no leftover filters); results appear only once a query is run.
- A pushed browse page starts with no filters from other screens, and leaves none behind.

### Fixed
- "Business & MSME" showed 83 schemes after the questionnaire while its card said 309: the questionnaire added the card's own category / ministry / state as a second, differently-worded filter. The card is now the base set and only the answers (offer types, beneficiaries) narrow it.
- Six short category titles (Startup, Finance, Artisan, Digital India, Women Entrepreneurs, Student Startups) showed in English in Tamil and Hindi.
- "Clear Filters & Explore Schemes" is available from every empty results page.

### Added
- Catalog-wide tests: every filter (offer type, beneficiary, nationwide, state, and combinations) returns exactly the schemes it describes for all schemes; card counts equal list sizes; every browse title and filter label is translated in Tamil and Hindi.

## [1.2.1+6] - 2026-10-20

### Added
- "Not applicable to you" pill: a scheme typed by exact name or acronym (e.g. PMEGP) now stays in the results, flagged with a distinct outlined pill, when "For Me" or a filter would have hidden it. The "eligible" count excludes these.
- Guard tests: every catalog card chip is translated in Tamil and Hindi; Tamil UI strings never spell MSME in Latin letters; the bottom bar is not inflated by the status-bar padding.

### Changed
- Tamil: MSME is written short, in Tamil letters ("எம்எஸ்எம்இ"), in the UI strings and dictionary; official names (MSMED Act, CGTMSE, MSME-DI/DFO) and the app name are unchanged.
- Tamil and Hindi: all 379 distinct scheme-card chip values (category / scheme type / sector) are translated.
- Sharing results now copies the scheme names in the active language.

### Fixed
- Bottom navigation bar was about 50dp too tall (status-bar padding was added on top of the bar). It is now its own widget, `AppBottomNavBar`.
- State questionnaire inserted the raw English state into Tamil sentences ("Maharashtra மாநிலத்தின்…"); it now uses the Tamil name, and the Tamil word for "resident" is corrected.
- Card chips no longer split a bracketed list at its commas ("services)", "cooperatives)").

## [1.2.0+5] - 2026-10-20 (pre-release)

### Added
- Multilingual search with "Did you mean", Hindi/Tamil stemming, profile canonicalisation
  and voice-agent parity; English scheme text indexed so indirect queries resolve.
- Firebase Cloud Messaging push integration.
- Device audit report: `docs/audit/DEVICE_AUDIT_2026-10-20.md`.

### Changed
- App and voice agent now use the MSS REST backend and the 2026 scheme catalog.
- Default API origin is `https://mssapi.msmeschemes.org` (the Vercel host
  `api.msmeschemes.org` is paused).
- In-app Tamil/Hindi terms aligned with the catalog (MSME, women entrepreneurs, states).
- Home fallback promo carousel shows only the evergreen "For Women Entrepreneurs" card.

### Fixed
- Logout now revokes the session on the server before clearing local tokens (the request
  used to go out without a bearer and the session stayed valid).
- Users were signed out after an expired access token: the refresh lock was per-client, so
  parallel clients reused one refresh token and the server revoked the session. The lock is
  now shared (regression test added).
- "Use my profile" filter treated disability "No" as a disability and collapsed results to
  one scheme.
- Missing accessibility labels: legal-sheet close button, profile notification bell and
  avatar, onboarding step 4 switches.
- Fabricated home promo cards ("PMEGP · 2 days left", "TN Export Promotion Scheme",
  "UDYAM registration process updated") removed.

### Known issues
- Server `LEGAL_DOCUMENT_VERSIONS` is empty, so onboarding is never marked complete on the
  server and re-runs on every cold start (server configuration, not an app bug).
- Full Address is not restored after a restart.
- Default scheme lists are not scoped to the user's state (Filter → Maharashtra coverage
  works).
- Access and refresh tokens are kept in plain SharedPreferences.

Full detail: `docs/audit/DEVICE_AUDIT_2026-10-20.md`.

## [1.1.0+4] - 2026-10-19

### Changed
- Moved the app and voice agent to the MSS REST backend with the 2026 catalog (#114).
- Hindi + Tamil UI sweep, Companion localization and adaptive layouts (#112).

## [1.0.2] - 2026-09-06 (pre-release)

Scheme result engine, single shared filter, redesigned filter sheet, hardened profile
round-trip. See the `v1.0.2` GitHub release for notes.
