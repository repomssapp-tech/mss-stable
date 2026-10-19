# How the app uses its local data, and how it talks to the server

Audience: whoever runs the backend (what the app expects) and whoever changes the
app (what must not be broken). Companion docs: `backend/New API Ref/` (the API
references), `docs/backend/PENDING_ENDPOINTS.md` (routes still to be defined) and
`docs/backend/API_USAGE_AND_REMAINING.md` (routes in use, what is left, catalog
bundle rules for the backend).

## 1. The one rule: schemes are read locally, never queried

The app **does not send search or browse queries for schemes to the server**.
Everything the user does with schemes (search, filters, categories, details,
recommendations, saved lists) runs against a **local copy of the catalog** on the
phone. The server is asked for exactly one thing about schemes: *"is there a newer
catalog release, and if so give it to me"*, through the catalog update API.

The state-schemes API (`GET /v1/schemes`, `/:id`, `/sync`, ...) is **not used by
the app**.

## 2. The local catalog copy

| Layer | Where | Role |
|---|---|---|
| Bundled copy | Flutter assets `assets/catalog/`: `catalog_core.json.gz` + one `catalog_<jurisdiction>.json.gz` per state (central, tamil_nadu, maharashtra) | Ships with the app. Always available, works offline, the fallback if anything else fails. |
| Installed copy | App documents directory `mss_catalog_cache/` (versioned release folders + an "active" pointer) | A newer verified release downloaded from the server. Used instead of the bundled copy while it is valid. |
| In-memory index | Built from whichever copy is active | What search and recommendations actually read. Rebuilt when the copy changes. |

Rules that protect the local copy:

* A new release is **verified before it is used**: SHA-256 of the exact downloaded
  gzip bytes, byte size, schema version, bundle format. Anything wrong → the new
  file is discarded and the previous copy keeps working.
* The previous release stays on disk; the "active" pointer only flips after the
  new one is fully installed.
* An installed copy left over from an older app build is purged on app update, so a
  shipped catalog is never shadowed by a stale download.
* The catalog is public data. It is not tied to an account and is **not** cleared
  on sign-out.

## 3. When the app checks for a newer catalog

| Trigger | Rule |
|---|---|
| App start (cold start) | **Always** checks. |
| Every 30 minutes of **active use** | The timer only counts while the app is in the foreground; going to the background pauses it and keeps the elapsed time. |
| Return to the foreground, or the phone regains a network | At most **once a minute** (a quick app switch costs nothing). |
| Phone reports no network | No request is made; it catches up when the network returns. |

A check is the sequence **check → download → use → update**:

1. `GET /v1/catalog/current` (public, conditional with `If-None-Match`; a `304`
   or JSON `null` means "keep what you have").
2. If the release differs (`release_version` + `package_sha256`), `GET` the
   `bundle_url` it names (API-origin-relative, must start with `/v1/catalog/`;
   absolute URLs are refused).
3. Verify and install (section 2). Then the app rebuilds its index and the UI shows
   the new data. Search ranking is recomputed locally.
4. Failures (network, 429, 5xx, bad checksum, unsupported schema) leave the current
   copy untouched; the request layer backs off before trying again.

Code: `CatalogRefreshScheduler` (when), `SchemeCatalogSyncService` +
`HttpCatalogReleaseSource` (how), `SchemeCatalogStore` (where it is kept).

## 4. Live data from the server and how often it is requested

Only data that really changes per user is live. Everything goes through one
request layer (`lib/services/network/`):

* `RequestManager`: single flight per key, a **freshness window** (a recent success is
  reused instead of asking again), an **offline gate**, and **exponential backoff**
  (30 s, 60 s, 120 s ... capped at 15 min). A server `Retry-After` is always
  honoured, even for a forced call. `force` is only for the user's own actions.
* `Debouncer`: collapses bursts of writes into one request.
* `ForegroundPoller`: a timer that counts only active use, pauses in the
  background, and runs one catch-up when the network returns.
* `ConnectivityService`: the **phone's own** network status (Android
  `ConnectivityManager` / iOS path monitor through `connectivity_plus`). It says
  whether *a* network exists, not that our server answers; request failures are
  handled by the backoff above.

| Data | Request | When | Never |
|---|---|---|---|
| Notifications inbox | `GET /v1/me/notifications` | on sign-in/start, then every 5 min of active use, on foreground/reconnect, after the user's changes; **reused for 2 min** | on every screen view |
| Notification changes (mark read / delete) | `PATCH .../read`, `POST .../delete` | the screen updates instantly; **one batched request 1.5 s after the last tap**; sent at once when the app goes to the background; the inbox is reloaded once afterwards (so a rejected change is not kept) | one request per tap |
| Promotions | `GET /v1/promotions` | on start/sign-in, language change, profile change; **reused for 30 min** | on every home screen view |
| Profile | `GET/PATCH /v1/me/profile`, `PUT /v1/me/onboarding` | edits are **coalesced 2 s**; a failed send is kept and retried when the network returns; sent at once when the app goes to the background | for another account (a pending edit is dropped on sign-out) |
| Catalog | section 3 | section 3 | search / browse queries |
| Saved schemes (favorites) | `PUT/DELETE /v1/me/favorites/:id`, `GET /v1/me/favorites` | the device works first; changes are queued (kept across restarts), **batched 2 s after the last change**, sent when the app goes to the background and when the network returns; the server copy is pulled at sign-in/start and at most **every 15 min** | one request per tap |
| Saved eligibility results | `GET/PUT /v1/me/eligibility-results` (ETag `X-Eligibility-If-Match`) | same queue; a version conflict (`412`) reloads the ETag once and writes again | |
| Support ticket | `POST /v1/support-tickets` (+ `/support-tickets/guest-session` when signed out) | when the user submits; one `Idempotency-Key` per submission, reused when the same text is retried | a new key for an automatic retry |
| Delete account | `DELETE /v1/me` | when the user confirms; needs a login within the last 5 minutes (`403 REAUTHENTICATION_REQUIRED` tells the user to sign in again). Local data is cleared only after the server's `204` | |
| Chat sessions | `POST /v1/me/chat-sessions` (assumed) | when a conversation ends; unsent ones are queued on the device and retried on the next start / reconnect | |

Everything is cleared on sign-out: the notifications list, promotion cards, the
request freshness/backoff state, any pending profile edit, the library sync queue
and the recorded legal consent.

How the saved library merges: the first sync of an account keeps everything (local
and server favorites are united and local-only ones are uploaded). After that the
server is authoritative, with this device's unsent changes applied on top. A scheme
the account may not see (`404`) is kept on the device only; a missing profile state
(`409`) keeps the change queued.

Bodyless requests (account deletion, logout, favorites) send no `Content-Type`,
as the reference requires.

Profile language: every language the app offers (`en`, `ta`, `hi`, `mr`) is sent
to the profile API, which must accept all four.

Onboarding: the final `PUT /v1/me/onboarding` is sent only when the user's
acceptance of the current legal documents has been recorded
(`LegalConsentStore`). That acceptance is the agreement given on the sign-in
screen, where each document must be scrolled to its end before it can be accepted;
see `PENDING_ENDPOINTS.md`.

## 5. What the app stores on the device

| Data | Storage | Cleared on sign-out |
|---|---|---|
| Access/refresh token, user id/email/name/picture | `TokenStorage` (shared preferences, keys `mss_auth_*`) | yes |
| Profile, language, navigation mode, saved/recent schemes | `SessionCacheService` / `LibraryController` (shared preferences) | yes (session cache) |
| Catalog (bundled + installed) | assets + documents directory | no (public data) |
| Queued chat sessions | shared preferences (`chat_log_*`) | kept until uploaded for the owner |

The app holds **no database credentials**. Authentication is a bearer token only.

## 6. What the app expects from the server

* **Catalog**: `GET /v1/catalog/current` as in `catalog-update-api.txt` (object, or
  JSON `null`; quoted-SHA `ETag`; `304` on a matching `If-None-Match`); `bundle_url`
  relative to the API origin under `/v1/catalog/`; `package_sha256` and
  `package_byte_size` exact for the downloaded file; gzip served as the raw file
  (no transport re-compression).
* **Catalog format (open item)**: the app now ships a *core file + one pack per
  state* (bundle format 3, hashes of every pack inside the core's manifest). The
  server currently publishes a **single** gzip. The app rejects a release older than
  format 3, so until the backend publishes core + packs (multi-file install), the
  bundled copy is used and only the check runs.
* **Errors**: JSON `{"error":"CODE"}`; `429` with `Retry-After` is honoured;
  `401` triggers one token refresh and a retry.
* **Notifications / promotions / profile**: exactly as in their reference files
  (cursor pagination, `ids`/`all` bodies, ETag on the profile).
* **Rate limits**: the reference quotas (120 requests/min/IP, 60/min/owner) are far
  above what this design sends (a signed-in phone in active use sends on the order
  of a dozen requests an hour).

## 7. Where this lives in the code

| Concern | File |
|---|---|
| Phone connectivity | `lib/services/network/connectivity_service.dart` |
| Freshness, backoff, single flight | `lib/services/network/request_manager.dart` |
| Write batching | `lib/services/network/debouncer.dart` |
| Active-use timer | `lib/services/network/foreground_poller.dart` |
| Catalog check schedule | `lib/services/catalog/catalog_refresh_scheduler.dart` |
| Catalog release client (ETag, safe URL) | `lib/services/catalog/http_catalog_release_source.dart` |
| Notifications | `lib/providers/controllers/notifications_controller.dart` |
| Promotions | `lib/providers/controllers/promo_content_controller.dart` |
| Profile debounce, lifecycle, reconnect catch-up | `lib/providers/app_state_provider.dart` |
| Tests | `test/network/request_handling_test.dart`, `test/notifications/`, `test/catalog/` |
