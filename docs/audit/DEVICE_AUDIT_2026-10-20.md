# Device audit — 20 Oct 2026

Scope: Android emulator (`emulator-5554`, Android 17, debug build) driven over adb using
Flutter's accessibility tree. Backend: `https://mssapi.msmeschemes.org` (v0.2.2).
Account: a real Google sign-in, since deleted (see §3).

Legend: **FIXED** = changed in this branch and verified on the device or by a test.
**OPEN** = still needs action. **DECISION** = product choice needed.

---

## 1. Open issues (need action)

### 1.1 OPEN — Server `LEGAL_DOCUMENT_VERSIONS={}` blocks onboarding (blocker)
- `GET /v1/me/legal-documents` returns `{"configured":false,"items":[]}`.
- The app records consent only when documents are configured, so it never submits
  onboarding. Log line: `Onboarding not sent: consent not recorded.`
- Result: server `is_profile_complete` stays `false` with `missing_fields:
  legal.terms, legal.privacy_policy, legal.privacy_notice, legal.consent`. Every cold
  start sends the user back through onboarding, and Profile still shows "Profile complete"
  locally.
- Profile data itself does reach the server (state, district, city, pincode, applicant
  type, qualification, community, income).
- Fix (server): set the four versions in `LEGAL_DOCUMENT_VERSIONS` to the published
  versions and restart the Node service. API doc: "Missing configuration blocks final
  legal onboarding."
- Until fixed, the offline-restart check could only be run on the onboarding screen.

### 1.2 OPEN — Full Address does not survive a restart
- After onboarding step 2 and a restart, City / District / State / Pincode are restored
  but "Full Address" is empty, and the step will not continue until it is re-entered.
- Not investigated further (likely the `house`/`area` fields are not mapped on the
  draft PATCH or on load).

### 1.3 OPEN — Secrets in the chat
- The server `.env` (including `DB_PASSWORD`) was pasted into the session. The client
  never needs it and it was not used. Rotate the database password.

### 1.4 OPEN — Tokens stored in plain SharedPreferences
- `TokenStorage` keeps access and refresh tokens in `shared_preferences`
  (`flutter.mss_auth_*`). Readable on a rooted device or via backup. Consider
  `flutter_secure_storage`.

### 1.5 OPEN — Unrelated modified files in the working tree (not committed)
- `saarthi-agent/data/scheme_catalog.json` and `search_index.json` show about 247,000
  deleted lines. Not touched in this audit; check before anyone commits them.
- Test files modified by earlier work: `catalog/single_gzip_download_test.dart`,
  `google_profile_photo_test.dart`, `language_selection_screen_test.dart`,
  `legal/legal_document_scroll_test.dart`, `login_screen_test.dart`,
  `profile/location_address_test.dart`, `profile/profile_and_onboarding_test.dart`.
- Old URL `api.msmeschemes.org` remains in test fixtures (harmless) and the CI workflow
  `.github/workflows/build-app.yml` writes its own `API_BASE_URL`; confirm it points at
  `mssapi.msmeschemes.org`.

### 1.6 DECISION — Default lists are not scoped to the user's state
- For a Maharashtra profile, *Business & MSME* (after "Skip to Results") listed about 25
  Tamil Nadu schemes plus North East / Sikkim schemes alongside Maharashtra and central
  ones.
- This follows the documented intent that browse/search is not pre-filtered by profile.
  The Filter sheet's Maharashtra coverage works correctly (270 = 191 nationwide + 79
  Maharashtra; the other 39 excluded).
- Decide whether signed-in users should see only central + their state by default.

### 1.7 OPEN (minor) — Onboarding resume granularity
- Fields on a step are saved only when Continue is pressed; a kill mid-step loses that
  step's typed values.
- A restart lands on "Choose Your Experience", then step 1 (pre-filled), not on the last
  step reached.

### 1.8 OPEN — Not covered by this audit
- Hindi and Tamil were checked before login only (language picker, login, Terms,
  Privacy). Post-login screens were not re-checked in those languages.
- Only these screens were checked for unlabeled controls: language, login, legal sheets,
  onboarding step 4, Profile, Settings, Discover. `Icons.close` appears in 20 files
  (calculator sheets, help sheets, search, notifications, voice, assessment); their
  tooltips were not checked.
- Account delete was verified through the API and the app, not by querying the
  database. The backend repo is not on this machine, so its deletion tests were not run.

---

## 2. Fixed in this branch

### 2.1 FIXED — Logout did not revoke the session on the server
- `AppProvider.logout` cleared local tokens before calling `POST /auth/logout`, so the
  request went out with no bearer and failed silently. The old access token kept
  returning 200.
- Fix: call the remote sign-out first, then clear local state
  (`lib/providers/app_state_provider.dart`).
- Verified: old token returns 200 before and 401 after logout from the app.

### 2.2 FIXED — Users signed out after a stale access token
- `ApiClient._inFlightRefresh` was an instance field, and the app builds several clients
  (`ApiClient.instance`, plus private ones in `RestAuthService`, `ProfileApiService`,
  `OnboardingApiService`). On a cold start with an expired access token, several clients
  refreshed at once with the same refresh token. The server rotates the token on every
  use and revokes the whole session on reuse, so the user landed on the login screen.
  Expected after roughly 15 minutes of inactivity.
- Fix: the lock is `static` (`lib/services/network/api_client.dart`). Regression test:
  `separate clients share one refresh flight (no token reuse)` in
  `test/network/api_client_test.dart` (failed before the fix).
- Verified on device: with a rejected access token the app refreshed silently, both
  tokens rotated, the session stayed and `GET /v1/me` returned 200.

### 2.3 FIXED — "Use my profile" filter collapsed results to 1 scheme
- The profile stores disability as `"No"` / `"None"`. The filter sheet treated anything
  other than `"none"` as a disability and added the *Differently-abled* filter.
- Fix: use `ProfileCanonicalizer.isDifferentlyAbled`
  (`lib/widgets/scheme/filter_panel.dart`).
- Verified: chip now gives 270 schemes (central + Maharashtra), and the results list had
  no other-state schemes in 58 sampled titles.

### 2.4 FIXED — Fabricated home promo cards
- The fallback carousel showed "PMEGP · 2 days left", "TN Export Promotion Scheme" and
  "UDYAM registration process updated" to every user. None were true for the user.
- Fix: only the evergreen "For Women Entrepreneurs" card remains
  (`lib/providers/app_state_seed_data.dart`).

### 2.5 FIXED — Backend URL
- `api.msmeschemes.org` (Vercel) answers `503 DEPLOYMENT_PAUSED`, which the app showed as
  "no internet".
- `dart_defines.json` (local, git-ignored), `dart_defines.example.json` and the default
  in `lib/config/app_config.dart` now use `https://mssapi.msmeschemes.org`.

### 2.6 FIXED — Missing accessibility labels
- Close (X) on the Terms / Privacy sheets, Profile notification bell and avatar /
  camera badge, and the three Special Status switches on onboarding step 4 had no
  accessible name. All now labelled; verified no unlabeled clickables remain on those
  screens.

---

## 3. Verified working

| Area | Result |
| --- | --- |
| Session cache | Cold start restores the session; offline cold start keeps it and does not go to login |
| Revoked session | Server-revoked session returns the app to login |
| Mid-onboarding kill | No re-login; onboarding resumes (see 1.7) |
| Logout | Server returns 204, token returns 401 afterwards, local keys cleared (after 2.1) |
| Account delete | Server accepted; old token 401 on `/v1/me` and `/v1/me/profile`; all local keys wiped; app returned to login; re-sign-in gave an empty new account (profile row gone) |
| Pre-login native language | Language picker, login, Terms and Privacy fully in English, Tamil and Hindi; only brand names (Google, MSS) in Latin script |
| Legal gate | Google button stays disabled until both documents are opened and accepted (by design) |
| Backend health | `/v1/health` returns `ok`, `db: ok`, v0.2.2 |
| Tests | Full `flutter test`: 1166 passed |

---

## 4. Reproduction notes

- Drive the app with `adb shell uiautomator dump` for labels and clickable regions;
  pull files with `adb pull` (PowerShell `>` corrupts PNGs).
- Sign-in: tap the saved Google account in the chooser; no password is entered by the
  tooling.
- The emulator was memory-starved at times (about 1.2 GB free host RAM); the app died once
  and needed a force-stop and cold start.
