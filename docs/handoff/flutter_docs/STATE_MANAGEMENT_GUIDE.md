# State Management Guide

Framework-agnostic guidance on what state shape the API's behavior
requires -- applies whether the app uses Provider, Riverpod, Bloc, or
anything else. **No state-management library is chosen or implemented
here.**

---

## 1. Required states per data-fetching screen

Every screen backed by an API call (see `SCREEN_DATA_MAPPING.md`) needs
to represent at least these 5 states, because the API itself
distinguishes them and collapsing any two together loses information
the contract requires you to preserve:

| State | Trigger | Must NOT be confused with |
|---|---|---|
| `loading` | Request in flight | `empty` |
| `loaded` (with results) | Success, `resultCount > 0` | -- |
| `empty` (zero results) | Success, `resultCount == 0` -- e.g. a `no_matching_domain` warning | `error` -- this is a valid, informative outcome, not a failure |
| `error` (retryable) | `CATALOG_UNAVAILABLE` / `INTERNAL_ERROR` / network failure | `invalidInput` -- retrying an invalid request identically will fail identically |
| `invalidInput` | `INVALID_REQUEST` / `UNKNOWN_SCHEME` / `UNKNOWN_ENTITY` | `error` -- this is a client-side bug, not a transient condition; see `ERROR_HANDLING_GUIDE.md` |

`CURSOR_STALE` is a 6th, pagination-specific state -- see §3.

## 2. Warnings are part of the loaded state, not a separate error state

A successful response can carry `warnings[]` (e.g. `filter_scope`,
`sparse_catalog`, `unofficial_translation`, `data_gap`) alongside real
`data`. **These are not errors** -- the state shape for a screen should
have a `warnings: List<ResponseWarning>` field on its `loaded` state,
not a separate branch. A screen showing search results with a
`filter_scope` warning is still in the `loaded` state; the warning
drives a banner/chip, not a state transition.

## 3. Pagination state

Pagination needs its own sub-state, independent of the loading/loaded/
error states above, since "loading page 2" while "page 1 is still
displayed" is a real, common UI state (e.g. infinite scroll) that isn't
just "loading" (which would blank the existing results):

```
idle (page 1 loaded, more available: page.nextCursor != null)
  → loadingMore (user scrolled to bottom, page 2 request in flight)
    → idle (page 2 appended, results list grown)
    → error (page 2 request failed -- page 1 results stay visible)
    → cursorStale (restart required -- see below)
exhausted (page.nextCursor == null -- no more pages)
```

**`cursorStale` handling:** per `ERROR_HANDLING_GUIDE.md`, the correct
recovery is restarting from page 1, not retrying the stale cursor. Model
this as its own transition (back to the initial `loading` state with a
fresh, cursor-less request), not as a generic pagination error the user
has to manually retry into a broken loop.

## 4. Profile and filter state -- privacy-scoped

The `profile` object (gender, community, etc.) that feeds search and
eligibility is, per `PRIVACY_RULES.md`, **never to be persisted or
logged server-side.** On the client:

- It's fine to hold `profile` in in-memory app state for the duration
  of a session (the user picking filters and seeing results update).
- **Do not** wire it into any state-persistence mechanism that survives
  app restart (e.g. a `SharedPreferences`/local-DB-backed state
  container) without a deliberate, separate decision to do so -- the
  same sensitivity that keeps it out of server logs applies to
  on-device storage. If the product wants "remember my profile," that
  is an explicit choice to make once, not a default behavior of
  whichever state-management library is chosen.
- Never include `profile` in analytics/crash-reporting event payloads
  attached to state-management action logs (e.g. Bloc's action history,
  Redux devtools-style loggers) -- these often serialize full state or
  action payloads for debugging, which would leak it exactly the way
  `PRIVACY_RULES.md` prohibits.

## 5. Language state

`language`/`lang` (naming differs by endpoint -- see
`api_docs/LOCALIZATION_IMPLEMENTATION_GUIDE.md`) should be derived from
the app's existing locale state, not duplicated as separate
per-screen state. One source of truth (the app's locale setting) feeds
every API call's language parameter; don't let individual screens carry
their own, potentially-inconsistent copy of "current language."

## 6. Cache invalidation

Per `api_docs/API_ENDPOINT_REFERENCE.md` §8, `/v1/meta`'s
`catalogVersion` is the signal for "the underlying data changed, refresh
your cache/bundle." If the app caches any API response
(recommended for the offline-first design `API_CONTRACT.md` describes),
the cache-invalidation state should key off a comparison against the
last-seen `catalogVersion`, not a time-based TTL alone -- the catalog
can be correct and unchanged for a long time, or change between two
consecutive app opens; version comparison is the reliable signal either
way.
