# MSS Web Handoff — Foundation Docs

This directory is the foundation for building **mss-web**, a React/Next.js + Tailwind website that replicates the Flutter app's functionality. Everything here was extracted directly from the shipping Flutter/Supabase codebase (`frontend/`, `backend/`) on 2026-09-13, not re-derived from memory or guesswork — treat it as ground truth for that date, and re-verify against the app if it's been a while since this was written.

## Reading order

1. **[01-DESIGN-SYSTEM.md](01-DESIGN-SYSTEM.md)** — every color, spacing token, type scale, and component pattern, plus a ready-to-use `tailwind.config.seed.js`.
2. **[02-DATA-MODEL.md](02-DATA-MODEL.md)** — the catalog bundle contract, the `Scheme` and `UserProfile` shapes, and the Supabase table columns a web client will read/write.
3. **[03-SEARCH-ALGORITHM.md](03-SEARCH-ALGORITHM.md)** — the exact ranking formula (Tier-0 exact match, scored search, query expansion, "For Me" eligibility scoring) so it can be ported to TypeScript with matching output.
4. **[04-FEATURE-INVENTORY.md](04-FEATURE-INVENTORY.md)** — every screen in the app, its purpose, and where it sits in the user flow.
5. **[05-ROUTING-MAP.md](05-ROUTING-MAP.md)** — a proposed Next.js App Router page structure mirroring the feature inventory.
6. **[06-API-CONTRACT.md](06-API-CONTRACT.md)** — every backend endpoint and Supabase table the site will call, plus the decided call-budget strategy for staying inside the existing `/v1/search` rate limit.
7. **[07-UX-FLOW.md](07-UX-FLOW.md)** — the user journey as a flowchart, screen-by-screen, mapped to the routes in 05-ROUTING-MAP.md.
8. **[08-ASSET-MANIFEST.md](08-ASSET-MANIFEST.md)** — every asset file in the app, what's copied into this package vs. pulled on demand, and naming issues to fix rather than propagate.
9. **[09-GETTING-STARTED.md](09-GETTING-STARTED.md)** — the actual step-0 checklist: scaffold the project, install dependencies, copy the tokens/assets, set env vars, wire up auth first.
10. **[10-I18N.md](10-I18N.md)** — the two separate localization systems (UI strings vs. per-entity catalog content) and how to keep them from being conflated on the web.
11. **[11-SEO.md](11-SEO.md)** — metadata, structured data, and sitemaps for the public scheme-discovery pages — a genuinely new concern the mobile app has no equivalent of.
12. **[12-DEV-LOG-SETUP.md](12-DEV-LOG-SETUP.md)** — installs the same per-developer, GitHub-username-keyed change log already live in the main app's repo, via the templates in `assets/dev-log/`.

## Reusable assets (`assets/`)

- `assets/logo/Logo.webp`, `Logo-icon.webp` — the real production logo files, copied verbatim from `frontend/assets/images/Logo/`.
- `assets/data/search_taxonomy.json` — the canonical search-tuning config (weights, vocab, related-concepts) that all three existing runtimes (Dart/TS/Python) already share. The web port should read this same file, not hardcode its own weights.
- `assets/data/query_expansion.json` — the Tanglish/regional-term expansion table used by query expansion (see 03-SEARCH-ALGORITHM.md).
- `assets/data/release.sample.json` — a real example of the catalog release manifest shape, for reference when writing the catalog-fetch/versioning code.
- `assets/dev-log/` — the per-developer change-log templates (`dev-log.yml`, `pull_request_template.md`, `DEV_LOG.seed.md`) — see 12-DEV-LOG-SETUP.md before copying these in.

For the full offline catalog bundle itself (`catalog_bundle.json.gz`, ~1220 entities), pull the current one from `frontend/assets/catalog/catalog_bundle.json.gz` directly rather than duplicating a large binary here — it changes with every catalog release.

## How the website searches, without hitting the existing rate limit

The Flutter app's search is **100% on-device**: it ships the full catalog bundle in the app binary/OTA and ranks locally, so `POST /v1/search` on the backend has *zero* callers today, and its rate limits are sized for occasional voice-agent use, not a live web search box. A website can't ship an offline bundle the way a mobile app does, and the backend team isn't resizing those limits for web traffic — so the decided approach (06-API-CONTRACT.md has the full detail) is a **split-workload, call-budget-constrained** strategy rather than porting the whole ranking engine to a fourth runtime:

- Only genuine free-text search hits `/v1/search`, and only on submit (not per-keystroke).
- Category/ministry/state browsing and instant name-match suggestions are served client-side from the CDN-hosted catalog JSON — no ranking call needed for those at all.
- A time-windowed in-flight de-dupe + result cache (mirroring the mobile app's own 15s memo pattern) keeps repeat/rapid submissions from burning extra calls.

Porting the full ranking algorithm to TypeScript (03-SEARCH-ALGORITHM.md has the spec either way) stays the fallback if real usage later shows this isn't enough headroom — not the starting design.

## What this handoff does NOT cover

- Visual mockups / Figma — these docs describe tokens and structure, not pixel-perfect screens. Pair with whatever design files the team has.
- The voice/companion-mode experience (LiveKit + Sarvam AI) — flagged in 04/06 as present in the app, but porting a voice-first conversational UI to the web is a distinct, larger effort not scoped in this initial handoff.
- Admin/back-office tooling — this is a citizen-facing site handoff only.
