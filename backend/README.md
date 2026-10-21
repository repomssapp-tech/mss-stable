# MSS - MSME Schemes Search Backend

Contracts and tooling for the MSS REST backend (`https://mssapi.msmeschemes.org`),
which the Flutter app and the Saarthi voice agent talk to. The server itself
lives in the separate `mss-backend` project; this folder holds the shared
reference material.

## Layout

```text
backend/
|-- New API Ref/             Authoritative API references (schemes, catalog update,
|                            notifications, promotions)
|-- openapi/                 Planned, not-yet-built admin/sync contract
|-- catalog/                 Canonical search_taxonomy.json and search_parity_golden.json,
|                            plus the catalog build sources
|-- scripts/                 verify_scheme_links.mjs
+-- package.json             Pinned OpenAPI tooling
```

Routes the app expects that the API references do not define yet are listed in
[`docs/backend/PENDING_ENDPOINTS.md`](../docs/backend/PENDING_ENDPOINTS.md).

## Tooling

Requirements: Node.js 20.19.x or 22.12+. Run from `backend/`:

```powershell
npm ci
npm run openapi:lint
npm run verify:links
```

## Published mobile scheme catalog

The app reads a validated, immutable release snapshot and keeps the bundled
catalog (`catalog_core.json.gz` plus one `catalog_<jurisdiction>.json.gz` per
state) as its factory fallback. Releases are discovered through
`GET /v1/catalog/current` and downloaded from the `bundle_url` it names; see
`backend/New API Ref/catalog-update-api.txt`. Publishing is done by backend
operators with the `mss-backend` tooling, never from the app.

## Tamil voice lab

Offline Tamil ASR benchmarks (Whisper vs. AI4Bharat) and deterministic
scheme-vocabulary tests live in `tools/voice-lab/`. See
[`tools/voice-lab/README.md`](../tools/voice-lab/README.md) for setup, benchmark
results, and model limitations.
