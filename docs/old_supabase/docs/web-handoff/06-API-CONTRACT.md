# API Contract — backend endpoints and Supabase tables the website will call

Source: `backend/supabase/functions/v1/index.ts`, `frontend/lib/services/chat/sarvam_chat_service.dart`, `frontend/lib/services/voice/livekit_voice_agent_controller.dart`.

## `v1` router (single Edge Function, path-routed)

Base URL: `<project-ref>.supabase.co/functions/v1/v1/<route>` (the function is literally named `v1`, so the client's base path plus the hardcoded `/v1/...` route both need to be present — don't drop the duplication, it's intentional). All routes go through `SECURITY DEFINER` RPCs, never direct table access.

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/v1/health` | none | Liveness check |
| POST | `/v1/cache-bust` | Service-role secret | Admin-only; invalidates the warm-isolate corpus cache. Not needed by the website. |
| GET | `/v1/meta` | JWT | Catalog metadata |
| POST | `/v1/search` | JWT + fail-closed rate limit (per-minute, per-day, and global caps) | **See the open decision below — currently has zero callers from the mobile app.** |
| GET | `/v1/schemes/{id}` | JWT | Single scheme detail |
| GET | `/v1/schemes/{id}/finance` | JWT | Finance sub-resource for a scheme |
| GET | `/v1/finance-products[/{id}]` | JWT | |
| GET | `/v1/clusters[/{id}]` | JWT | |
| GET | `/v1/tax[/{id}]` | JWT | |
| GET | `/v1/privileges[/{id}]` | JWT | |
| GET | `/v1/relationships/{id}` | JWT | |
| POST | `/v1/eligibility` | JWT | |
| GET | `/v1/localization/{id}?lang=` | JWT | |

Request/response bodies for `/v1/search` and `/v1/eligibility` follow the `mss_contract.dart` shapes documented in 02-DATA-MODEL.md (`MSSSearchResponse`, `EligibilityMatch`, etc.) — those are the API's actual JSON shapes, richer than the offline `Scheme` model.

## Decided: how the website searches, within the current `/v1/search` rate limit

The mobile app's search is **100% on-device** — it ships the full catalog bundle and ranks locally with `HybridSchemeSearch`, so `/v1/search` is deployed but has zero real callers today. A website can't ship an offline gzip bundle inside itself the way a mobile app binary can, and the backend team is not resizing `/v1/search`'s rate limits for web traffic — so the site is built to stay inside the existing per-IP per-minute/day and global caps, using a **split-workload** approach:

1. **Split by workload, not just by throttling.** Only genuinely free-text, ambiguous queries hit `POST /v1/search`. Everything else is served from the CDN-hosted catalog JSON client-side, with zero calls to the endpoint:
   - Category / ministry / state / facet browsing (`/discover/*` in 05-ROUTING-MAP.md) — pure filters over the static catalog, never needs the ranking algorithm.
   - Instant "quick suggestions" while typing — a local prefix/substring match against the catalog's pre-tokenized `search_index.json` (02-DATA-MODEL.md), so exact scheme names and the quick-pill queries (e.g. "PMEGP") resolve without a network call at all.
2. **Search-on-submit only.** `/v1/search` fires on button press / Enter, never per-keystroke. This is the single biggest reduction in call volume.
3. **Minimum query length gate** — reject/no-op below ~2 characters client-side so a stray Enter on an empty/near-empty box never becomes a call.
4. **Time-windowed in-flight de-dupe, not identity-only.** A single submit-handler guard keyed on a short cooldown window (mirror the mobile app's 15s TTL in `scheme_repository.dart`), not just "is this the exact same query string again":
   - While a request for query Q is in flight, a repeat submit of Q within the window reuses the pending promise instead of firing a second call.
   - Once a query resolves, its result is cached for the same TTL window; a resubmit of Q (or a return via back button) within that window is served from cache, not re-fetched — regardless of whether anything is currently in flight.
   - A new submit for a *different* query cancels/ignores the previous window's relevance (no stacking of stale in-flight guards), so the cooldown is per-query, not a single global lock that would block a legitimately different search.
   - This needs no server changes — it's purely a client-side call-budget guard sized to stay inside the existing limits, not a request to raise them.

If real usage later shows the split-workload approach still isn't enough headroom, porting the ranking algorithm to TypeScript for full client-side search (03-SEARCH-ALGORITHM.md has the complete spec) is the fallback — revisit only if needed, since it adds a 4th copy of the search engine to keep in sync (Dart, backend-TS, Python already exist).

## Other live Edge Functions

| Function | Purpose | Contract |
|---|---|---|
| `sarvam-chat` | Text chat ("Ask AI") | `supabase.functions.invoke('sarvam-chat', { body: { language: 'en'\|'ta', messages: [{ role, content }] } })` → `{ reply: string, usage?: object }`. Requires a live/refreshed Supabase session. Directly callable the same way from a web client via `@supabase/supabase-js` — no mobile-specific pieces. |
| `livekit-token` | Mints a LiveKit access token for voice sessions | `supabase.functions.invoke('livekit-token')` after ensuring a fresh session → LiveKit access token, consumed by LiveKit's client SDK (a JS SDK exists — same contract works for web, out of scope for the initial site per the README). |

## Supabase tables/channels touched directly by the client (not via `v1`)

| Table/channel | Purpose | Key columns |
|---|---|---|
| `profiles` | Primary user profile row | See 02-DATA-MODEL.md's `UserProfile` — remember the snake_case renames in `toSupabase()` (`pinCode→pincode`, `employmentStatus→applicant_type`, `profileCompleted→is_profile_complete`, `mobile→phone`) |
| `startup_profiles` | Business-specific profile fields | `existingBusiness`, `businessStage`, `businessIndustry`, `fundingRequired`, `registrationNumbers` |
| Realtime: `profiles` | Own-row echo (profile edited on another device syncs here) | Replicate the reconciler-guard pattern (02-DATA-MODEL.md §4) if the web client also writes to fields the mobile app can race against |
| Realtime: `notifications` | Push-style in-app alerts | Not independently re-verified for this handoff — confirm exact subscription filter against `app_state_provider.dart` before building |
| Realtime: `catalog_sync` | New catalog release notifications | Same caveat — confirm before building |

## Auth

Use `@supabase/supabase-js`'s standard Google OAuth flow (`signInWithOAuth({ provider: 'google', options: { redirectTo: '<site-url>/auth/callback' } })`) — this is simpler than the mobile app's deep-link + `isOAuthPending` polling dance (see 04-FEATURE-INVENTORY.md), since a browser redirect just lands back on the site directly with the session already established.
