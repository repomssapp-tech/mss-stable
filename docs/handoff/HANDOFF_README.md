# MSS → Antigravity Handoff

**Scope of this handoff: Flutter integration only.** The catalog, its
data, and the API's business logic are complete and validated;
Antigravity's job is to connect an existing Flutter app to this API --
not to build catalog features, not to touch Supabase, not to touch
GraphQL (neither exists in this project), and not to redesign any
screen.

**You should be able to integrate MSS APIs by reading the documents in
this folder, without reading any catalog-internals code.** If something
here is ambiguous or contradicts something else, that is a documentation
bug -- check `../FINAL_HANDOFF_VALIDATION_REPORT.md` and
`../FINAL_PACKAGE_FILE_AUDIT.md` first; both were written specifically
to catch and flag exactly that kind of gap rather than let you guess.

---

## Architecture correction (2026-08-17) -- read before anything else about sync/updates

A prior planning pass considered assembling a catalog download payload
on demand from Supabase tables. **That is not the architecture.** The
corrected, final architecture uses two synchronized representations of
the same verified release:

1. **Supabase Tables** -- the online API/query layer only (search,
   scheme lookup, finance, tax, clusters, relationships, localization,
   eligibility). This is what `API_CONTRACT.md` and
   `API_ENDPOINT_REFERENCE.md` describe and is unaffected by this
   correction.
2. **Supabase Storage** -- immutable release artifacts the Flutter app
   downloads for offline sync. Distinct from Tables; never rebuilt from
   them on demand.
3. **Flutter local catalog** -- the offline copy, downloaded from
   Storage and activated only after full validation.

Full detail: `architecture_docs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`,
`architecture_docs/HASH_VERIFICATION_SPECIFICATION.md`,
`architecture_docs/RELEASE_MANIFEST_SPECIFICATION.md`,
`architecture_docs/UPDATE_FLOW_SPECIFICATION.md`. If you are working on
anything related to catalog updates, offline sync, or release
publishing, read those four documents first -- this correction
supersedes any earlier informal description of that flow.

---

## Where to start

1. **`api_docs/API_CONTRACT.md`** -- the wire-level contract: every
   response envelope, every field's meaning, every client obligation.
   Read this first.
2. **`api_docs/API_ENDPOINT_REFERENCE.md`** -- every live endpoint, one
   by one, with real request/response examples and Flutter usage notes.
   This is the day-to-day reference while building the API client
   (Phase 1 of `flutter_docs/FLUTTER_INTEGRATION_PLAN.md`).
3. **`flutter_docs/FLUTTER_INTEGRATION_PLAN.md`** -- the 6-phase build
   order. Start here for "what do I build first."
4. **`flutter_docs/SCREEN_DATA_MAPPING.md`** -- for each app screen,
   exactly which API field feeds which piece of UI. Two screens (AI
   Companion, Saved Schemes) have no backing API today -- documented
   honestly, not glossed over.

## Folder structure

```
MSS_ANTIGRAVITY_HANDOFF/
├── data/MSS_API_DATA_PACKAGE/   16 JSON files -- the catalog itself.
│                                  Self-contained; run validate_package.py
│                                  inside it to verify independently.
├── api_docs/                    Wire contract, endpoint reference,
│                                  search/localization/error/pagination
│                                  guides.
├── flutter_docs/                Integration plan, model mapping,
│                                  screen mapping, state-management guide.
├── examples/                    Real (not hand-written) request/response
│                                  JSON, generated from a live call to the
│                                  reference implementation this phase.
└── HANDOFF_README.md            This file.
```

## What is NOT in this handoff, and why

- **No Flutter/Dart code.** `flutter_models/mss_contract.dart` already
  exists in the wider project (outside this handoff folder) and already
  implements most response models -- see `flutter_docs/MODEL_MAPPING_GUIDE.md`
  for what's there and what's still missing. Nothing here duplicates or
  modifies it.
- **No API backend code.** The reference implementation
  (`mss_api.py`/`mss_api_rc1.py`) lives in the wider project's `catalog/`
  folder, not in this handoff. It is documented, not shipped, here --
  see `api_docs/API_ENDPOINT_REFERENCE.md`'s intro for why (transport
  layer is a deployment decision this handoff doesn't make).
- **No GraphQL, no Supabase.** Neither exists anywhere in this project.
  Every mention of either term in this handoff's documents is an
  explicit exclusion statement.

## A note on accuracy over an earlier draft

An earlier version of the API contract documentation understated what
this API already does -- it marked several endpoints (finance-product
detail, cluster/tax/privilege, relationships, filters/sorting/pagination)
as "not yet built" when they are, in fact, live and tested. This handoff
corrects that. If you encounter another MSS document elsewhere in the
project (outside this folder) that still says "SPEC, not implemented"
for one of those, trust `api_docs/API_ENDPOINT_REFERENCE.md` in this
folder instead -- it was verified by reading the actual server code
directly, not copied from the earlier draft.

Two smaller, similarly-verified corrections worth knowing before you
start:
- The search request's language field is **`language`**, not `lang` --
  the two aren't interchangeable, and one dedicated endpoint
  (`/v1/localization`) actually does use `lang` instead, which is a real
  inconsistency in the API, not a typo in this doc.
- Tamil-script search queries return real, ranked results, but the
  `detectedIntent` tagging that powers "why matched" explanations only
  works for English-language queries today -- tested directly, not
  assumed.

## Questions this handoff should already answer

If you find yourself needing to ask "does the API support X," check
`api_docs/API_ENDPOINT_REFERENCE.md` first -- every endpoint that exists
is documented there with a real example, and the one place that lists
what does *not* exist (AI Companion, Saved Schemes, a few missing Dart
models) is `flutter_docs/SCREEN_DATA_MAPPING.md` and
`flutter_docs/MODEL_MAPPING_GUIDE.md`'s closing sections. That combination
was written specifically so a "does X exist" question has a documented
answer before you need to ask it.
