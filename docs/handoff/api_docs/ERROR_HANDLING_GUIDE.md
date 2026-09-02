# Error Handling Guide

Every error code below was found by reading `mss_api.py`/`mss_api_rc1.py`
directly (`grep`'d for every `MssApiError(...)` call site) -- this is
the complete, exhaustive list, not a guess at what "should" exist.

---

## 1. Error envelope

```json
{
  "contractVersion": "1.0.0",
  "contract": "error",
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Unknown value for profile.enterpriseType.",
    "field": "profile.enterpriseType",
    "detail": "got 'huge'; expected one of: medium, micro, small"
  }
}
```
See `examples/error_response.json` for a real, live-generated example.

`field` and `detail` are present when the error is field-specific
(most `INVALID_REQUEST` cases); absent for catalog-level errors.
**`data` and `error` never appear in the same response** -- always
check for `contract == "error"` (or the presence of the `error` key)
before reading `data`.

## 2. Complete error code list

| Code | Raised when | Recommended HTTP status |
|---|---|---|
| `INVALID_REQUEST` | Malformed request: missing required field, wrong type, unknown key, unknown enum value, query too long, bad cursor, sort changed mid-pagination, unsupported `lang`/`language` | 400 |
| `UNKNOWN_SCHEME` | `schemeId` not found (scheme-specific endpoints) | 404 |
| `UNKNOWN_ENTITY` | An id not found on a non-scheme lookup (finance product, cluster, tax, privilege, relationships, localization) | **404 -- not defined in the reference `HTTP_STATUS` dict; see gap below** |
| `CURSOR_STALE` | A pagination cursor's embedded catalog version no longer matches the live catalog (the catalog was updated mid-pagination) | **409 -- not defined in the reference `HTTP_STATUS` dict; see gap below** |
| `CATALOG_UNAVAILABLE` | Server-side catalog load failure | 503 (retryable) |
| `INTERNAL_ERROR` | Unhandled server exception | 500 (retryable) |

**Only 503 and 500 are retryable.** Every other code means the request
itself is wrong or the resource doesn't exist -- retrying identically
will fail identically.

## 3. Gap found in the reference implementation (verified, not guessed)

`mss_api.py`'s `HTTP_STATUS` dict (the reference mapping for whoever
builds the HTTP transport layer) only defines 4 entries:
```python
HTTP_STATUS = {"INVALID_REQUEST": 400, "UNKNOWN_SCHEME": 404,
               "CATALOG_UNAVAILABLE": 503, "INTERNAL_ERROR": 500}
```
`UNKNOWN_ENTITY` and `CURSOR_STALE` **are both actually raised** by
`mss_api_rc1.py` (confirmed by reading `finance_products()`,
`_generic_list()`, `relationships()`, `localization()` for the former,
and `_decode_cursor()` for the latter) but have no entry in this dict.
**When implementing the HTTP transport layer (Phase 1 of
`FLUTTER_INTEGRATION_PLAN.md`), extend `HTTP_STATUS` with:**
```python
HTTP_STATUS["UNKNOWN_ENTITY"] = 404   # matches UNKNOWN_SCHEME's pattern
HTTP_STATUS["CURSOR_STALE"] = 409     # matches the original API contract's documented mapping
```
This is a one-line fix for the backend implementer, not something
Flutter needs to work around -- flagged here so it isn't missed, since
an unmapped code would otherwise default to whatever the framework's
"unknown status" fallback is (commonly 500, which is misleading for
what is actually a 404/409-shaped condition).

## 4. Handling each code in Flutter

| Code | Flutter behavior |
|---|---|
| `INVALID_REQUEST` | This is a client bug (bad request construction) -- log it, don't show a generic "something went wrong" to the user without detail; use `error.field`/`error.detail` to identify what was wrong during development |
| `UNKNOWN_SCHEME` / `UNKNOWN_ENTITY` | Show a "not found" state for that specific item -- e.g. a deleted-scheme-in-cache scenario after a catalog update. Not a network error. |
| `CURSOR_STALE` | Restart pagination from page 1 (offset 0, no cursor) -- do not retry with the same stale cursor. This means the catalog was updated while the user was paging; a fresh first page reflects current data. |
| `CATALOG_UNAVAILABLE` | Retryable -- show a transient error state, retry with backoff |
| `INTERNAL_ERROR` | Retryable -- show a transient error state, retry with backoff; also worth client-side logging/telemetry since this indicates a real server bug |

## 5. What NOT to do

- Don't parse `error.message` for logic -- it's human-readable prose,
  not a machine contract. Branch on `error.code` only.
- Don't treat a 4xx as retryable. Only 500/503 are.
- Don't silently swallow `CURSOR_STALE` and keep using the old cursor --
  it will keep failing identically; the fix is always "restart from page 1."
- Don't assume every endpoint can return every code above -- e.g. `/v1/meta`
  and `/v1/health` take no meaningful input and realistically only ever
  return `CATALOG_UNAVAILABLE`/`INTERNAL_ERROR`, never `INVALID_REQUEST`.
