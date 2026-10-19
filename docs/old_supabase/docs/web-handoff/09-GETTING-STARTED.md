# Getting Started — step 0 for mss-web

A concrete first-commit checklist tying the rest of this handoff package together. Do these in order.

## 1. Scaffold the project

```bash
npx create-next-app@latest mss-web --typescript --tailwind --app --src-dir=false --import-alias "@/*"
cd mss-web
```

## 2. Install core dependencies

```bash
npm install @supabase/supabase-js
npm install lucide-react          # icon set — see 01-DESIGN-SYSTEM.md
npm install next-intl             # i18n — see 10-I18N.md
```

Add LiveKit/voice packages later, only if/when companion-mode scope is picked up (out of scope for the initial build per the README).

## 3. Copy the design tokens

```bash
cp path/to/docs/web-handoff/tailwind.config.seed.js ./tailwind.config.js
```

Review `01-DESIGN-SYSTEM.md` alongside it — the seed file covers colors/spacing/type scale/radii; fonts still need registering via `next/font/google` (Poppins + Inter for English, Noto Sans Tamil + Arima for Tamil, per that doc).

## 4. Copy the reusable assets

```bash
mkdir -p public/logo
cp path/to/docs/web-handoff/assets/logo/*.webp public/logo/
```

Pull anything else from `frontend/assets/` on demand per `08-ASSET-MANIFEST.md` — don't bulk-copy the rest.

## 5. Environment variables

Create `.env.local` (never commit this):

```
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<the publishable/anon key>
```

Get the actual values from whoever holds them for the `houpzsxmwemoztpuigmo` Supabase project (per the main repo's `docs/audit/AUDIT.md`) — do not create a second Supabase project for the website; it should read the same `profiles`/catalog data as the mobile app.

Commit a `.env.local.example` with placeholder values (mirroring the main repo's `dart_defines.example.json` pattern) so the next developer isn't stuck guessing what variables exist.

## 6. Initialize the Supabase client

```ts
// lib/supabase.ts
import { createBrowserClient } from '@supabase/ssr'; // or createClient from @supabase/supabase-js

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

Use `@supabase/ssr`'s browser/server client split if any pages end up server-rendered with auth-aware data — plain `@supabase/supabase-js` is enough for a fully client-rendered first pass.

## 7. Wire up the pieces, in this order

1. Auth (04-FEATURE-INVENTORY.md's flow + 06-API-CONTRACT.md's OAuth note) — get login working before anything else, since everything downstream needs a session.
2. The root `(main)/layout.tsx` shell holding auth/profile/language context (05-ROUTING-MAP.md).
3. Home page, then Search (with the call-budget guard from 06-API-CONTRACT.md built as a shared module from day one, not bolted on later).
4. Scheme details page.
5. Everything else, in whatever order matches the team's priorities — 04-FEATURE-INVENTORY.md has the full list.

## 8. Set up the dev log

Copy the templates from `assets/dev-log/` in this handoff package into the new repo's `.github/` — see `12-DEV-LOG-SETUP.md` for the one manual edit required (the log's file path) before it works.

## 9. Make the search-architecture decision explicit

Before writing the Search page, confirm the team has actually decided (not just defaulted into) the call-budget-constrained approach in `06-API-CONTRACT.md` — write it down as a one-line note in the new repo's own README or an ADR, so it doesn't get silently re-litigated mid-build.
