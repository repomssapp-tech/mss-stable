# API usage, what is left, and the catalog bundle (for the backend engineer)

Status date: 2026-10-19. App branch: `feat/rest-backend-migration`.
Base URL: `https://api.msmeschemes.org` (app override: `--dart-define=API_BASE_URL`).
All routes are under `/v1`. Reference: `backend/New API Ref/API_DOCUMENTATION.txt`.
Related: `LOCAL_DATA_AND_SYNC.md` (how local data is used),
`PENDING_ENDPOINTS.md` (assumed routes, consent, language),
`SERVER_SIDE_ISSUES.md`.

## 1. What the app calls today

| Area | Routes | How / when |
|---|---|---|
| Sign-in | `GET /auth/google/start {code_challenge}`, `POST /auth/exchange {code, code_verifier}`, `POST /auth/refresh`, `POST /auth/password/login`, `POST /auth/logout`, `POST /auth/logout-all` | Google PKCE through the system browser, deep link `com.inschemes.app://login-callback/`. No `redirect_uri` is sent. Refresh happens on 401. |
| Account | `GET /me`, `GET/DELETE /me/sessions[/:id]`, `PUT/DELETE /me/password` (DELETE body `{current_password}`), `DELETE /me` | Delete expects `204`; `403 REAUTHENTICATION_REQUIRED` (login older than 5 min) is shown to the user. |
| Profile | `GET /me/profile`, `PATCH /me/profile` (drafts, `X-Profile-If-Match`) | Edits are coalesced for 2 s. `language` carries `en`, `ta`, `hi` or `mr` (see section 5). |
| Onboarding | `PUT /me/onboarding` with `Idempotency-Key` + `X-Profile-If-Match` | Sent once, when the profile is complete and all four legal acceptances are recorded. Body: `profile` (all 13 required fields, never empty), `business` (or `null`), `legal_acceptances` (4 items). |
| Legal | `GET /me/legal-documents`, `POST /me/legal-acceptances` | The app reads the current versions after sign-in. The user sees 3 documents; 4 server types are recorded (see `PENDING_ENDPOINTS.md`). |
| Notifications | `GET/PATCH/DELETE /me/notifications*` | Poll every 5 min while the app is active, reuse a result for 2 min, writes batched 1.5 s. |
| Promotions | `GET /promotions` | Reused for 30 min. `language` sent as `en` or `ta`. |
| Catalog | `GET /catalog/current`, `GET /catalog/releases/:tag/bundle` | The only scheme data the app takes from the server. See section 4. |
| Library | `GET/PUT/DELETE /me/favorites*`, `/me/eligibility-results` | Queued on the device, batched every 2 s, pulled at most every 15 min. |
| Support | `POST /support-tickets`, `GET /support-tickets*` | `Idempotency-Key` on create; guest session supported. |
| Health | `GET /health` | Connectivity check. |

Request behaviour (all routes): one request in flight per resource, freshness
windows, offline gate (the phone's own connectivity status), exponential backoff
(30 s, 60 s, 120 s ... capped at 15 min), `Retry-After` on `429` always honoured,
bodyless requests send no `Content-Type`.

## 2. What the app deliberately does not call

* `GET /v1/schemes`, `/schemes/:id`, `/schemes/sync`, ... (state schemes API):
  scheme search and browse run on the local catalog only.
* Notification SSE stream and push devices (FCM).

## 3. Routes the app assumes but the reference does not define

`POST /beta-gate/verify`, `POST /me/chat-sessions`, `POST /chat`,
`POST /voice/token`. Request/response shapes and the behaviour while they are
missing are in `PENDING_ENDPOINTS.md`.

## 4. Catalog bundle: how the server must build and serve the zip

The app downloads **one gzip file** that holds every scheme, verifies it, and
installs it over the bundled copy. Follow these rules exactly; the app rejects a
release that breaks any of them and keeps the previous catalog.

### 4.1 The file

* One **gzip** (RFC 1952) of **one UTF-8 JSON object** (no BOM). Not a `.zip`
  archive, not several files, not a tarball.
* Top level is the same layout as the bundled catalog: each key is a section file
  name and its value is `{ "metadata": {...}, "data": [ ... ] }`, for example
  `scheme_catalog.json`, `common_catalog.json`, `search_index.json`,
  `manifest.json`, `migrations.json` (this one has `schemeIdMap` instead of
  `data`). Look at `frontend/assets/catalog/catalog_core.json.gz` for the exact
  shape.
* `scheme_catalog.json.data` must be a **non-empty array**. Every scheme names
  its own jurisdiction (central / state); the app groups them by state after
  loading. No per-state pack files are needed for a downloaded release.
* `manifest.json.data[0]` should carry `catalogRelease`, `releasedAt`,
  `bundleFormat` (the app understands up to **3**; a higher number is refused as
  "update the app") and `recordCounts` (`{"scheme_catalog.json": 406, ...}`).
  For every section listed in `recordCounts` the `data` length must equal the
  count, and `metadata.recordCount` (if present) must agree. A mismatch rejects
  the whole release, so a truncated build never becomes an empty catalog.

### 4.2 Compressing it

* Serialize compact: `json.dumps(obj, ensure_ascii=False, separators=(",", ":"))`
  then UTF-8 encode. `ensure_ascii=False` keeps Tamil/Hindi readable and the file
  smaller than `\uXXXX` escapes.
* Compress with gzip level **9**, with the **header mtime set to 0** and no file
  name, so the same data always gives the same bytes and the same SHA-256:

  ```python
  import gzip, hashlib
  raw = json.dumps(bundle, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
  blob = gzip.compress(raw, compresslevel=9, mtime=0)
  sha256 = hashlib.sha256(blob).hexdigest()
  byte_size = len(blob)
  ```

  Node: `zlib.gzipSync(raw, { level: 9 })` (Node writes mtime 0 by default). Both
  are what `tools/catalog_packs.py` and `tools/build_catalog_release.py` do.
* Hash and size are over the **gzip bytes exactly as downloaded**, not over the
  JSON. Never re-compress, re-chunk or re-wrap a published release; a new build
  is a new release tag.
* Size limits: the app refuses to expand a download beyond **256 MiB** of JSON
  (zip-bomb guard) and aborts a download larger than **1.2 x
  `package_byte_size`**. The shipped catalog packs are about 1.6 MB compressed in
  total, so a single bundle is a few MB.

### 4.3 Publishing

1. Build the gzip, compute `sha256` and `byte_size`, validate it by decompressing
   it yourself and checking the rules in 4.1.
2. Store it immutably under the release tag.
3. Only then move the `GET /v1/catalog/current` pointer to it, in one atomic
   step (a pointer to a bundle that is not yet downloadable would fail every
   phone).

`GET /v1/catalog/current` returns `release_version`, `schema_version`,
`package_sha256` (64 hex), `package_byte_size` (exact), `record_counts`,
`published_at` and `bundle_url` (`/v1/catalog/releases/<tag>/bundle`). It answers
`200 null` when nothing is published (the app keeps the shipped catalog) and
supports `ETag` / `If-None-Match` with a bodyless `304`.
`bundle_url` must be an API-relative path starting with `/v1/catalog/`; the app
refuses absolute URLs and `..`.

### 4.4 Serving it (the common mistake)

* `Content-Type: application/gzip`, **no `Content-Encoding: gzip`**. The file
  itself is the gzip. If the response is marked `Content-Encoding: gzip`, an HTTP
  stack may decompress it on the way, the app then hashes different bytes and
  rejects the release with `CHECKSUM_MISMATCH`.
* Switch automatic compression **off** for this route in every layer in front of
  the file (nginx `gzip off;` and no `gzip_static`, CDN "compress objects"
  disabled, Brotli off). Do not let a proxy transform the body.
* Send `Content-Length`, `ETag: "<sha256>"` and
  `Cache-Control: public, max-age=31536000, immutable` for the bundle; the
  `current` pointer stays `public, max-age=60, must-revalidate`.
* `404 {"error":"RELEASE_NOT_FOUND"}` for an unknown tag,
  `503 {"error":"CATALOG_UNAVAILABLE"}` if the pointer cannot be read.
* No authentication on either catalog route.

### 4.5 Checks to run before publishing a release

* `gzip -t bundle.json.gz` passes; `sha256sum` equals `package_sha256`; file size
  equals `package_byte_size`.
* `curl -sI .../bundle` shows `application/gzip` and no `Content-Encoding`.
* `curl -s .../bundle | sha256sum` equals `package_sha256` (this catches a proxy
  that transforms the body).
* Decompressed JSON: object, every `recordCounts` section matches, schemes
  non-empty, `bundleFormat` <= 3.

### 4.6 Single-zip issues for the backend to resolve

* **One file, not packs.** The app used to ship `catalog_core` plus one pack per
  state (format 3). A downloaded release is now one gzip with every scheme and
  the app assigns schemes to states from each scheme's own jurisdiction. Every
  scheme therefore needs a correct jurisdiction field; a scheme without one
  cannot be placed under a state.
* **Embedded `manifest.json` must be honest.** If it lists `recordCounts` they
  must equal the real row counts, otherwise the app rejects the whole download
  and keeps the old catalog (the user sees no update and nothing says why).
* **`/catalog/current` fields.** The app tolerates `package_sha256`,
  `package_byte_size`, `record_counts` missing, but then skips the matching check.
  Always send all of them.
* **Release tag.** Plain tags only (`1.37.0`); the app sanitises anything else,
  so a tag with odd characters will not map to its folder.
* **Pointer before file.** Moving `current` before the bundle is downloadable
  makes every phone fail and back off (30 s up to 15 min), so publish the file
  first.
* **No automatic compression in front of the file** (section 4.4), or the
  checksum fails on every phone.
* **Size.** Keep the uncompressed JSON well under 256 MiB; the app refuses more.
* **Format number.** `bundleFormat` above 3 is refused until the app is updated.
* **Update cadence.** The app checks on every cold start, every 30 min of active
  use, and on foreground / reconnect at most once a minute, so `current` must
  answer `304` cheaply.

## 5. Contract changes the backend needs to make

* **Profile `language` must accept `en`, `ta`, `hi`, `mr`.** The server currently
  answers `PATCH /me/profile` with
  `400 VALIDATION_ERROR, details: [{field: language, code: INVALID_VALUE}]` when
  the language is `hi` (seen on the device, request id in section 7). The app
  works around it (below), but until the server accepts the value the user's
  Hindi/Marathi choice is not stored on the server.
* **Configure the legal documents.** `GET /me/legal-documents` answers
  `configured: false` with no items, so onboarding can never complete (section 7).
* Legal acceptances: the app records `terms` and `privacy_policy` at sign-in and
  `privacy_notice` and `consent` when the profile is completed, then sends all
  four in `PUT /me/onboarding`. Confirm this is acceptable.
* Define the four assumed routes in section 3.

## 6. Where things stand

Confirmed on the Pixel 7 emulator against `https://api.msmeschemes.org`
(2026-10-19):

* Sign-in screen: no consent checkbox. Terms of Use and Privacy Policy each open,
  scroll to the end and accept; "Continue with Google" unlocks only after both.
* Google sign-in through the system browser: deep link received, code exchange
  succeeded, profile loaded from the server (name, email, phone, age).
* Profile steps 1-4 complete and the profile saves (`PATCH /me/profile`); the app
  then opens the main screen. The profile page shows the "Privacy & Data" notice
  and the "Read how your data is used" link, with no checkbox.
* "Use current location" fills a readable address (for example `83/36, Sardar
  Patel Road, Adyar`), the city, state and pincode; a Google plus code such as
  `22QV+VVC` is never used.
* The local catalog works (MSME 321, Startup 65, Women Entrepreneurs 91 schemes)
  and "For Me" reports matching schemes. Scheme details open with overview,
  benefits, eligibility, documents, services and application sections, and Save
  Scheme adds the scheme to Saved Schemes.
* Home shows promotions; Notifications opens with an empty list and no error.
* The language menu offers English, Tamil and Hindi (Marathi has no selector).
  Hindi applies across Home, Search, the tabs and the scheme-detail labels and
  survives an app restart; the signed-in session survives a restart too.
* A scheme's own text (name, description, benefits) stays English in Hindi mode
  when the catalog has no Hindi text for it. This is expected: Tamil Nadu
  schemes are not expected to be used in Hindi.
* The data-use page opens read-only with a single Close button.
* The draft profile (gender, address, pincode) is restored when the profile is
  reopened.

Fixed in the app in this round:

| Problem | Fix |
|---|---|
| Saved gender came back empty on the profile screen | Restored for any saved gender, not only for completed profiles |
| "Saved Scheme" label clipped on the scheme page | Button padding reduced so two lines fit; the label now shows in full |
| Address came back as a plus code (`22QV+VVC`) | Plus codes are discarded; the address is built from street, neighbourhood and town; empty geocoder fields fall back correctly (district) |
| `google_fonts` "Inter-Regular not found" errors | Inter files bundled under the names `google_fonts` looks for (`assets/google_fonts/`); no font errors in the log |
| Profile save failed with "Unable to save profile" after the language was set to Hindi | The server rejects `language: hi`; the app now retries the save once without `language` so the rest of the profile is stored (see section 7) |
| The save error was invisible in the log | The submit screen and `ApiException` now log the status, error code and the server's field details |

Left:

| # | Item | Owner |
|---|---|---|
| 1 | Configure the four legal documents so `GET /me/legal-documents` returns `configured: true` (section 7, issue 1) | Backend |
| 2 | Accept `hi` / `mr` in profile `language` (section 7, issue 2) | Backend |
| 3 | Publish a single-gzip catalog release following section 4 and move `GET /catalog/current` off `null` (section 7, issue 5) | Backend |
| 3a | Add promotions (the endpoint returns an empty list) and decide whether `hi` / `mr` banners are wanted (issue 6) | Backend |
| 3b | Publish the allowed values for `applicant_type`, `education_level`, `community`, `annual_income`, `gender` (issue 7) | Backend |
| 4 | Define the assumed routes (section 3) | Backend |
| 5 | Confirm the four consent types may be accepted as described in section 5 | Backend |
| 6 | After 1: confirm onboarding completes, then notifications, promotions, favorites, support tickets and account deletion against the real server | App + backend |
| 7 | Confirm the favorites and language writes reach the server (no request log for them yet) | App |
| 8 | Check central / TN / MH scheme details in en and ta on the device | App |
| 9 | Human review of the Hindi and Tamil strings written for the consent flow, scheme section labels and the profile-page notice | Reviewer |
| 10 | Commit in logical commits, merge `origin/main`, resolve conflicts, push, PR | App |

## 7. Server call issues found by the app (log)

Seen on the device with the debug build, 2026-10-19. The app logs these lines
(`adb logcat -s flutter`).

### Issue 1: `GET /me/legal-documents` is not configured

* App log: `[LegalConsent] Server legal documents: configured=false, types=[]`,
  then `[AppProvider] Onboarding not sent: consent not recorded.`
* Effect: the app records the user's acceptance only for the document versions
  the server lists, so with none listed `PUT /me/onboarding` is never sent. The
  profile is saved as drafts only, `is_profile_complete` stays false on the
  server, and after every app restart the user is sent back to "Complete your
  profile" (it resumes at step 2 with the draft filled in).
* Needed: configure the four current documents (`terms`, `privacy_policy`,
  `privacy_notice`, `consent`, each with a version) for this environment.

### Issue 2: `PATCH /me/profile` rejects `language: "hi"`

* Server answer: `400 {"error":"VALIDATION_ERROR","details":[{"field":"language","code":"INVALID_VALUE"}]}`
  (request id `8e1fb3ac-eac0-4d65-a413-6e3ec739fdff`).
* Effect before the workaround: the whole patch was refused, the user saw "Unable
  to save profile. Please check connection and try again." and could not finish
  the profile in Hindi.
* App workaround: on exactly this error (400, `VALIDATION_ERROR`, field
  `language`) the app sends the same patch once more without `language`. App log:
  `[ProfileApiService] Server rejected language "hi"; saving the rest without it.`
  Each profile write in Hindi therefore costs one extra request until the server
  accepts `hi` and `mr`.
* Needed: accept `en`, `ta`, `hi`, `mr`.

### Issue 3: Intermittent connection failures from the emulator

* App log: `NETWORK_ERROR ... Connection refused (errno = 111)`,
  `HandshakeException: Connection terminated during handshake`, and
  `Connection reset by peer (errno = 104)` for calls to `api.msmeschemes.org`,
  for a few minutes while `ping api.msmeschemes.org` from the same emulator
  worked (about 60-330 ms). The same calls succeeded before and after.
* Not confirmed as a server fault (it could be the emulator's network). Worth a
  look at the server or CDN logs around 17:44-17:49 IST on 2026-10-19 for
  refused or reset TLS connections. The app retries with backoff.

### Issue 4: Short-lived access token

* After about 15 minutes idle the stored access token answered
  `401 {"error":"UNAUTHORIZED"}` on `GET /me/legal-documents`, as expected for a
  short-lived token; the app refreshes on 401.

### Issue 5: No catalog release is published

* `GET /v1/catalog/current` answers `200` with the body `null` (checked directly
  against `https://api.msmeschemes.org`, 2026-10-19 12:40 UTC, request id
  `7036a01f-1270-4658-bdd3-e3bf8a973d18`), and `GET /v1/catalog/releases/1.37.0-alpha`
  answers `404 RELEASE_NOT_FOUND`.
* Effect: no phone can receive a catalog update. The app always shows its bundled
  catalog (footer: "Local catalog vOct 18, 2026 • updated 1.37.0-alpha"), so new
  or corrected schemes never reach users.
* Needed: publish a release following section 4 and move the `current` pointer
  to it.

### Issue 6: Promotions are empty and `hi` is rejected

* `GET /v1/promotions?language=en` and `?language=ta` answer
  `200 {"items":[],"next_cursor":null}`: the server has no promotions, so the
  Home banners the app shows are its built-in defaults, not server content.
* `GET /v1/promotions?language=hi` answers `400 {"error":"INVALID_PROMOTIONS_REQUEST"}`.
  The app therefore asks for `en` when the app language is Hindi (or any language
  other than Tamil).
* Needed: add promotions for the home banners; if Hindi banners are wanted,
  accept `hi` (and `mr`).

### Issue 7: Allowed values are not documented

The app sends these values; the server's accepted lists are not published, so a
rejection (as with `language`) only shows up at run time:

| Field | App sends |
|---|---|
| `applicant_type` | `Student`, `Entrepreneur`, `Business`, `MSME Owner`, `Farmer`, `Artisan / SHG Member` (API sample shows `Individual`) |
| `education_level` | `School`, `Diploma`, `Undergraduate`, `Postgraduate`, `Ph.D.` (sample shows `Graduate`) |
| `community` | `General`, `OBC`, `SC`, `ST`, `EWS`, `Minority` |
| `annual_income` | one number per band (for example `450000` for the 3-6 lakh band) |
| `gender` | `Male`, `Female`, `Other` |
| `language` | `en`, `ta`, `hi`, `mr` (only `en` and `ta` accepted today, issue 2) |

* Needed: publish the allowed values for `PUT /me/onboarding` and
  `PATCH /me/profile`, or return the allowed list in the `VALIDATION_ERROR`
  details.

### Issue 8: New-account profile reports `language: "en"`

* A fresh profile reports `language: "en"`, which looks like the user's choice
  but is only the default. The app keeps the language picked before sign-in
  while the profile is incomplete, so there is no user impact; a nullable or
  absent `language` until the user sets one would be clearer.

### Issue 9: Draft fields after a restart (resolved in the app)

* Earlier a reopened profile showed phone, gender and age empty. The server did
  return the drafts; the app was not restoring the gender (fixed). Phone, age,
  address, city, state and pincode come back correctly from
  `GET /me/profile`. Qualification, community and income of an incomplete
  profile are not pre-selected on step 4 by design.

### Issue 10: Assumed routes are untested and undocumented

* `POST /beta-gate/verify`, `POST /me/chat-sessions`, `POST /chat` and
  `POST /voice/token` are not in the reference, and I did not call them. Their
  request and response shapes are in `PENDING_ENDPOINTS.md`. Until they exist the
  text assistant shows a connection error, the voice assistant falls back to the
  on-device one and chat sessions stay queued on the phone.

### Issue 11: Not yet exercised against the real server

* The favorites save (`PUT /me/favorites/...`), notifications (`GET /me/notifications`
  returned an empty list), eligibility-results, support tickets and account
  deletion: no request/response log yet. Check the server's request log for the
  test account.
