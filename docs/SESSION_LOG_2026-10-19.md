# Session log — 2026-10-18/19 (handoff for the next stage)

Everything below is **uncommitted** on branch `feat/hindi-ui-sweep` (working tree
at `C:\development\MSS App\MSS_App`; Flutter app in `frontend/`). Nothing is pushed.

## 1. What was done (in order)

1. **Catalog migration** to `schemes_json_only` (406 schemes: 274 central, 53 TN,
   79 MH), split into bundle-format-3 packs (`catalog_core.json.gz` + one pack per
   state). Details: memory `mss-2026-scheme-catalog-migration`, `docs/catalog_2026_mapping.md`.
2. **saarthi-agent speaks the user's language** (en/ta/hi/mr): app → token body
   `language` → agent metadata → `saarthi-agent/src/agent_language.py`. Tests pass (48).
3. **Supabase removed** from app + agent. REST client/auth/profile/notifications/
   promotions/catalog wired to `https://api.msmeschemes.org` (override
   `--dart-define=API_BASE_URL`). All remaining Supabase files archived in
   `docs/old_supabase/` (README marks OLD; delete the folder to drop it all).
   `tools/db_inspect.py` moved there; release build/gate use the local
   `catalog.content` cache only (gate self-tests T1–T9 pass).
4. **Local-catalog-only rule**: the app never queries schemes on the server. Only
   `GET /v1/catalog/current` (+ `bundle_url`) is used, scheduled by
   `CatalogRefreshScheduler` (every start; every 30 min of active use; foreground/
   reconnect at most once a minute). The state-schemes API client was deleted.
5. **Request layer** `frontend/lib/services/network/`: `RequestManager`
   (single flight, freshness window, offline gate, backoff, Retry-After),
   `Debouncer`, `ForegroundPoller`, `ConnectivityService` (phone's own status via
   `connectivity_plus`, now a direct dependency). Notifications: poll 5 min active,
   reuse 2 min, writes batched 1.5 s. Promotions: reuse 30 min. Profile edits
   coalesced 2 s. AppProvider is the single lifecycle observer.
6. **Aligned with `backend/New API Ref/API_DOCUMENTATION.txt`** (central reference,
   48 operations): Google login (`/auth/google/start {code_challenge}`,
   `/auth/exchange {code, code_verifier}`, no redirect_uri), `DELETE /v1/me`
   (403 REAUTHENTICATION_REQUIRED messaging), support tickets (`/v1/support-tickets`,
   Idempotency-Key, guest session), favorites + eligibility-results sync
   (`lib/services/library/`), bodyless requests send no Content-Type, profile
   `language` only en|ta (Hindi stays local).
7. **Legal consent (user decided)**: the sign-in agreement is the consent. Documents
   must be scrolled to the end before Accept works (hint + alert in en/ta/hi; my own
   ta/hi wording, needs human review). After sign-in
   `LegalConsentStore.recordFromLoginAgreement` stores the server's 4 current versions;
   only then is `PUT /me/onboarding` sent. Gap: login shows only Terms + Privacy Policy.
8. **Docs written**: `docs/backend/LOCAL_DATA_AND_SYNC.md` (how the app uses local
   data / what it expects from the server), `docs/backend/PENDING_ENDPOINTS.md`
   (assumed routes + consent + language), `docs/old_supabase/README.md`.
9. **Emulator**: AVD `Pixel_7` restarted with `-gpu host`; Windows per-app GPU
   preference set to high-performance for `emulator.exe` and
   `qemu-system-x86_64.exe`; SurfaceFlinger reports **NVIDIA GeForce RTX 5050**.
   adb: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`; device `emulator-5554`.
   The debug APK is built with `flutter build apk --debug --no-pub
   --dart-define-from-file=dart_defines.json` (local `dart_defines.json` holds only
   `API_BASE_URL`).

## 2. Test status

* `flutter analyze --no-pub`: only 6 pre-existing notes (mss_contract, api_exception,
  hindi_search_quality_test).
* Last FULL `flutter test --no-pub` run: 1061 passed, 2 skipped, 2 failed
  (`guards/color_tokens`, `guards/type_scale`: my modal edit used raw colour/GoogleFonts).
  **Fixed afterwards**; guards + login + legal tests pass. **A full rerun is still
  required** before declaring green.
* Agent: `saarthi-agent` pytest 48 pass (excluding 3 live-LLM evals).
* Never run `dart format` over the whole repo (moves `// style-ok` markers; if it
  happens restore them on the same line as `styleFrom(`). Don't run `flutter pub get`
  without care (churns pubspec.lock SDK pins).

## 3. Tonight's brief from the user (NOT done yet) and findings so far

User asked: fix endpoints per the docs (**mark anything unsure for their review**),
stress-test and exceptional-case the app, run on the emulator and visually check that
all scheme details load, **sign in with Google using their account**, and if all is
production-ready **create a branch, push everything, resolve merge conflicts**; use GPU
acceleration for the emulator (done).

### 3a. Endpoint audit result (all routes used by the app vs API_DOCUMENTATION.txt)
Match the doc: `/auth/google/start`, `/auth/exchange`, `/auth/refresh`,
`/auth/password/login`, `/auth/logout`, `/auth/logout-all`, `/me`, `/me/sessions[/:id]`,
`/me/password` (PUT body password/current_password; DELETE needs body
`{current_password}`), `/me/profile`, `/me/legal-documents`, `/me/legal-acceptances`
(`{acceptances}`), `/me/notifications*`, `/promotions` (language en|ta), `/catalog/*`,
`/me/favorites*`, `/me/eligibility-results`, `/support-tickets*`, `/health`, `DELETE /me`.
**Not in the doc → mark for user review** (kept as assumed, in
`lib/services/backend/pending_endpoints.dart`): `/beta-gate/verify`,
`/me/chat-sessions`, `/chat`, `/voice/token`. Not used on purpose: schemes list/search/
sync, notification SSE, push devices (FCM).

### 3b. KNOWN BUG TO FIX FIRST — onboarding body (`profile_cloud_sync.dart`)
`PUT /v1/me/onboarding` currently sends `profile` with `email` (NOT writable →
validation error) and is missing required fields: `city, house, education_level,
community, annual_income` (server requires name, dob, gender, phone, state, district,
city, house, pincode, applicant_type, education_level, community, annual_income +
4 consents). Also `phone` must be exactly 10 digits and `pincode` exactly 6 (sanitize).
Fix: build the full writable profile from `UserProfile`; if a required field is
missing, do not send onboarding (profile stays PATCH-only) and log it; check
`BusinessProfileDto` keys (profile_name, industry, applicant_type, business_stage in
Idea|Prototype|Registered|Operational|Expansion, business_registered,
funding_required_amount, registration_numbers, is_first_generation_entrepreneur) and
the STUDENT_WITHOUT_VENTURE rule. Update `test/profile/profile_and_onboarding_test.dart`.

### 3c. Remaining to do (in order)
1. Fix 3b; re-audit request bodies/headers (Idempotency-Key, X-Profile-If-Match).
2. Write a "needs your review" list (assumed routes, ta/hi strings, consent gap,
   OTA catalog format below) — e.g. in `docs/backend/PENDING_ENDPOINTS.md`.
3. Stress / exceptional cases: automated (request manager + sync under flaky/slow/
   erroring server, 429 Retry-After, expired token mid-flight, offline/online flips,
   rapid taps) and on the emulator (airplane mode, background/foreground, rotation,
   `adb shell monkey`, check `logcat` for FATAL/exceptions).
4. Emulator visual check: browse central + TN + MH schemes, open details in en/ta/hi,
   confirm eligibility/benefits/documents/steps load; Google sign-in with the user's
   account (system browser → deep link `com.inschemes.app://login-callback/`); verify
   profile load, notifications, promotions, favorites sync, support ticket, consent
   flow. Take screenshots (`adb exec-out screencap -p`).
5. Full `flutter test --no-pub` + analyze green, then git: `git fetch`; current
   branch `feat/hindi-ui-sweep` is based before squash-merge PR #112 (origin/main
   `d9aa010`), so expect conflicts (l10n, providers, tests, pubspec.lock, docs).
   Create a new branch (e.g. `feat/rest-backend-migration`), commit in logical
   commits (attribution line from the system reminder), merge/rebase `origin/main`,
   resolve conflicts, rerun tests, push, open PR if asked. Check no secrets
   (`dart_defines.json`, `.env*` are git-ignored; `graphify-out/` and big files:
   confirm what is tracked). The user earlier asked to HOLD back some modified
   `tools/*.py` files; now said "push all the latest changes" — mention what was
   included.

## 4. Open items to tell the user
* **OTA catalog format**: server publishes ONE gzip but the app ships core + per-state
  packs and rejects older releases → new catalogs can't install over the air until the
  backend publishes packs. Bundled catalog is used meanwhile.
* The six assumed routes (beta gate, chat sessions, text chat, voice token) have no
  contract; voice agent / chat were separate (old Supabase) systems.
* Google sign-in and all server calls are untested against the real server so far.
* Hindi/Tamil strings I wrote need human review (consent scroll alert, schemeSection*,
  etc.). Marathi has no UI selector.
* Memory: `mss-rest-backend-wiring.md` (+ this log) hold the durable facts.
