# Localization Implementation Guide

How Flutter should handle English/Tamil display. Full policy detail is
in `LOCALIZATION_CONTRACT.md` (also in `api_docs/`... actually in the
root integration package -- see note at the end); this document is the
practical "what to build" version for the Flutter side specifically.

---

## Rule 1 -- Never translate in Flutter

All Tamil content is pre-generated and stored server-side, in the
catalog's `localization.ta` fields. **Flutter must never call a
translation API, a dictionary lookup, or any client-side translation
logic.** Every string the app displays in Tamil comes from the backend,
verbatim.

## Rule 2 -- Use backend Tamil fields

When the user's locale is Tamil, request `language: "ta"` and read the
Tamil-language values the API returns -- do not maintain a parallel
client-side string table for catalog content (app UI chrome strings --
button labels, nav titles -- are a separate, normal Flutter
localization concern, not covered by this document).

**Wire shape, corrected from an earlier draft:** individual API
responses do **not** return both languages side-by-side as
`{"name": {"en": "...", "ta": "..."}}`. Verified directly against the
live `search()`/`scheme_detail()` implementations: each endpoint returns
**one language's values**, selected by the `language` (search) or
`lang` (localization endpoint -- see the naming inconsistency noted in
`API_ENDPOINT_REFERENCE.md`) request parameter. The only place both
languages appear together is the dedicated `/v1/localization/{id}`
endpoint's `fields` object, and even there it's one language at a time
per request (call it once per language if you need both).

**Practical shape a client actually receives**, per language:
```json
// language: "en"
{"schemeId": "SCH000021", "name": "Bhamashah Techno Fund - Women-led Startup Fund"}

// language: "ta"  (same scheme, requested in Tamil)
{"schemeId": "SCH000021", "name": "பாமாஷா டெக்னோ நிதி - பெண்கள் தலைமையிலான தொடக்க நிதி"}
```
(Illustrative -- confirm the exact Tamil string against a live call;
this document does not fabricate catalog content.)

## Rule 3 -- Fallback: Tamil missing → English fallback

```
Request language: "ta"
   ↓
Field has Tamil? ──yes──→ render Tamil value
   ↓ no
Fall back to English value for THAT FIELD ONLY
   ↓
Mark the field (subtly) as "not yet translated" if the UI wants to
show this -- optional, not required by the contract
```

**Field-level, never record-level.** If a scheme's `eligibilityText` has
no Tamil but its `benefitsText` does, render Tamil for `benefitsText` and
English for `eligibilityText` on the same screen -- never decide "this
whole scheme has no Tamil" and drop the entire record to English. This
is the single most important rule in this document; violating it is the
exact failure mode `LOCALIZATION_CONTRACT.md` was written to prevent.

**Current real coverage** (verified this phase, not estimated): 219/219
schemes and 12 of 13 other catalogs are 100% Tamil-complete at the field
level. The one exception: `knowledge_catalog.json`'s `body` field is
missing Tamil on 18 of 28 records (titles are complete). Flutter's
fallback logic will trigger there, routinely -- build and test against
it, don't treat it as a rare edge case.

## Tamil switching

1. User changes app locale to Tamil (however the app's existing locale
   mechanism works -- out of scope here, not a catalog concern).
2. Every subsequent API call includes `language: "ta"` (or `lang: "ta"`
   for the dedicated localization endpoint).
3. Responses come back with Tamil values where available, English where
   not (Rule 3).
4. **No re-fetch or re-render logic beyond the normal locale-change
   rebuild is needed** -- the API does the field-level fallback
   server-side; Flutter doesn't need its own fallback logic on top,
   only correct handling of whatever the API returned (which may
   legitimately mix languages within one record, per Rule 3).

## Caching

- Cache API responses **keyed by `(endpoint, params, language)`** --
  never share a cache entry between `language: "en"` and `language:
  "ta"` requests for the same otherwise-identical query, since the
  response content differs.
- The bundled catalog data (`MSS_API_DATA_PACKAGE/`, if the app ships an
  offline copy per the offline-first design in `API_CONTRACT.md` §2)
  already contains both `localization.en` and `localization.ta` for
  every field -- a fully offline Tamil-language read is possible without
  any network call, by reading `localization.ta[field] ??
  localization.en[field]` directly from the bundle. This is the same
  Rule 3 fallback, applied client-side against the bundle instead of a
  live response.

## Missing translation handling

Do not:
- Show an empty string or `null` literally.
- Hide the field entirely (a user who can't read English still benefits
  from seeing *something*, per the fallback rule).
- Silently substitute English text without any indication, if the app's
  design calls for a "not yet translated" affordance -- this is a UX
  choice, not a contract requirement, but if built, it must be driven by
  comparing the Tamil and English values (or checking the
  `/v1/localization/{id}` endpoint's `available`/`fallbackLang` fields),
  not guessed.

Do:
- Fall back to English for that field, per Rule 3.
- If displaying translation provenance (optional), use
  `/v1/localization/{id}`'s `provenance.isApproved`/`.official` --
  **both are `false` for every record in this catalog today.** Do not
  label any Tamil content as "official" or "verified" -- it is all
  machine-generated, explicitly marked as requiring human review before
  that claim could be made.

## Protected terminology

Certain terms are never translated or are handled specially:

**Transliterated, not translated** (Category A -- common enough to
render in Tamil script for readability): `MSME` → `எம் எஸ் எம் ஈ`,
`GST` → `ஜி எஸ் டி`, `EMI` → `இ எம் ஐ`.

**Preserved verbatim** (Category B -- official scheme/institution
abbreviations, never transliterated or translated): `PMEGP`, `PMMY`,
`CGTMSE`, `SIDBI`, `TReDS`, `DPIIT`, `PMFME`, `ODOP`, and the full list in
`translation_terminology_dictionary.json` (inside
`data/MSS_API_DATA_PACKAGE/`... **not currently included** -- see note
below). These already come pre-handled correctly in every Tamil string
the API returns; Flutter does not need to detect or protect them itself.

**Note on the terminology dictionary file:** `translation_terminology_dictionary.json`
and `translation_dictionary.json` are build-time tooling, not runtime
data -- they are correctly excluded from `MSS_API_DATA_PACKAGE/` (see
`FINAL_PACKAGE_FILE_AUDIT.md`). Flutter never needs to consult them; the
Tamil content they produced is already baked into every catalog record's
`localization.ta` fields, which the API/bundle already serves.

## What Flutter must NOT do (summary)

1. Never run any translation logic client-side.
2. Never assume a wire response contains both languages together (Rule 2).
3. Never fall back at the whole-record level (Rule 3).
4. Never label Tamil content as official/verified.
5. Never cache across the `language` dimension.
6. Never build UI that special-cases protected terms -- they arrive
   already correctly handled.
