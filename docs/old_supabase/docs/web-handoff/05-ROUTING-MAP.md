# Proposed Next.js App Router Structure

This is a **proposed** mapping from the Flutter screen inventory (04-FEATURE-INVENTORY.md) to Next.js App Router file paths — not extracted from the app (the app has no URL-based routing at all, per 04). Adjust freely; the point is to give the web team a concrete starting structure rather than a blank page.

```
app/
├── (auth)/
│   ├── login/page.tsx                 -- login_screen.dart
│   ├── language/page.tsx              -- language_selection_screen.dart (first-run only)
│   └── beta/page.tsx                  -- beta_gate_screen.dart (if the site also gates on a beta password)
│
├── onboarding/
│   ├── navigation-mode/page.tsx       -- navigation_mode_screen.dart
│   ├── profile/
│   │   ├── step-1/page.tsx            -- basic_profile_screen.dart (name/email/phone/gender/age + consent)
│   │   ├── step-2/page.tsx            -- location step (address/city/district/state)
│   │   ├── step-3/page.tsx            -- role selection (Student/Entrepreneur/Business/MSME Owner/Farmer/Artisan)
│   │   └── step-4/page.tsx            -- eligibility details (qualification/community/income)
│   └── results/page.tsx               -- eligibility_results_screen.dart
│
├── (main)/                            -- authenticated shell, persistent nav (mirrors the 5-tab IndexedStack)
│   ├── layout.tsx                     -- MainTabsContainer equivalent: persistent header/nav + language/session context
│   ├── page.tsx                       -- Home (tab 0, Regular mode)
│   ├── companion/page.tsx             -- Home (tab 0, Companion mode) -- or a client-side mode switch on the same route
│   ├── search/page.tsx                -- Search (tab 1) -- accepts ?q= for pre-filled queries from Home/category taps
│   ├── discover/
│   │   ├── page.tsx                   -- Discover/Categories (tab 2)
│   │   ├── category/[slug]/page.tsx   -- category-scoped results
│   │   ├── ministry/[slug]/page.tsx   -- ministry-scoped results
│   │   └── state/[slug]/page.tsx      -- state-scoped results
│   ├── saved/page.tsx                 -- Saved (tab 3)
│   └── profile/
│       ├── page.tsx                   -- Profile (tab 4)
│       ├── settings/page.tsx          -- language, nav mode, notifications, privacy/terms, delete account
│       └── help/page.tsx              -- FAQs, feedback, report-issue
│
├── scheme/[id]/page.tsx               -- scheme_details_screen.dart, with tab query param (?tab=benefits|eligibility|documents|services|process)
├── msme/page.tsx                      -- msme_module_details_screen.dart hub
├── msme/[panel]/page.tsx              -- export / gov-hierarchy / institutions / tax-gst / treds sub-panels
├── notifications/page.tsx             -- notifications_screen.dart
├── chat/page.tsx                      -- sarvam_chat_screen.dart ("Ask AI")
├── legal/[doc]/page.tsx               -- terms / privacy full text
│
└── tools/                             -- the "Business Utilities & Tools" bottom-sheet set, as full pages on web
    ├── udyam-classifier/page.tsx
    ├── subsidy-estimator/page.tsx
    ├── gst-calculator/page.tsx
    ├── emi-calculator/page.tsx
    ├── dpiit-eligibility/page.tsx
    ├── valuation-estimator/page.tsx
    └── document-checklist/page.tsx
```

## Notes on this mapping

- **Mobile bottom sheets → full pages.** Things like the calculators and checklists are modal bottom sheets on mobile; on a wider web viewport these read better as dedicated pages (or modals launched from `/discover`, your call) rather than forcing a mobile bottom-sheet pattern onto desktop.
- **The 5-tab shell → a persistent layout, not 5 separate route trees.** `app/(main)/layout.tsx` should hold whatever plays the role of `AppProvider` context (auth state, profile, language, catalog) so all tab pages share it, mirroring how `MainTabsContainer` wraps all 5 tabs in one provider today.
- **Companion mode** is modeled here as a separate route (`/companion`) rather than a client-side toggle on `/`, since a distinct URL is more web-native (shareable, bookmarkable) than the mobile app's in-place mode switch. Either works — this is a call for the team, not a hard requirement from the source app.
- **Query-driven search** (`/search?q=...`) replaces the mobile app's practice of calling `Navigator.push` with a pre-filled controller — much more natural on the web, and gives you shareable/bookmarkable search-result URLs for free, which the mobile app has no equivalent of.
- **No named routes existed in the app to carry over 1:1** — this structure is a fresh design informed by the screen inventory, not an extraction. Treat 04-FEATURE-INVENTORY.md as the source of truth for *what* needs a page; treat this file as one reasonable *how*.

## Router usage conventions

Next.js has three distinct "routing" surfaces — `app/**/page.tsx`, `app/**/layout.tsx`, and `app/api/**/route.ts` (Route Handlers) — plus Server Actions. Don't reach for all of them by default; the rule mirrors the same "one router unless you genuinely need a boundary" principle the main app's backend already follows for `v1` (`docs/RULES.md` §2 in the main repo):

1. **Default path: call Supabase directly from the client, no Next.js API route in between.** Every `page.tsx`/component that needs `profiles`, catalog reads, or an Edge Function (`sarvam-chat`, `livekit-token`, `/v1/*`) calls `@supabase/supabase-js` directly, same as the mobile app calls Supabase directly rather than routing through an intermediary. Adding a Next.js Route Handler as a pass-through proxy for something Supabase's client SDK already does adds a hop and a second place for auth/error-handling to drift out of sync — don't do it by default.
2. **Only add a Route Handler (`app/api/.../route.ts`) when there's a real reason a browser can't make the call directly**, e.g.:
   - A server-only secret is involved (there shouldn't be any beyond what Supabase's publishable key already covers — flag it if one comes up).
   - You need to enforce the search call-budget guard (06-API-CONTRACT.md's time-windowed de-dupe/cache) **server-side** as a second line of defense in addition to the client-side guard — optional hardening, not required for the initial build.
   - Aggregating multiple Supabase calls into one response to reduce client round-trips for a specific slow page.
3. **One shared client module for the search call-budget guard, not one per page.** The de-dupe/cooldown/cache logic from 06-API-CONTRACT.md belongs in a single `lib/search-client.ts` (or equivalent) that every page calling `/v1/search` imports — copy-pasting the guard into each page it's needed defeats the point, since a query fired from two different pages within the cooldown window still needs to share state to actually reduce calls.
4. **Layouts hold shared context, not shared fetching logic.** `app/(main)/layout.tsx` (auth/profile/language/catalog context, per the notes above) should provide *state*, not itself make the per-page data calls — keep fetching in the page/component that actually needs the data, so pages stay independently testable and don't all re-fetch on every layout re-render.

## Screen folder structure

Next.js's App Router requires fixed filenames (`page.tsx`, `layout.tsx`) inside `app/`, so a screen's actual implementation is colocated in a parallel `screens/` directory, one folder per screen, and the `app/` route file just re-exports it. This keeps every screen self-contained (implementation, markup, and styles together) and keeps `app/**/page.tsx` files as thin, uniform route declarations:

```
screens/
└── search/
    ├── index.tsx        -- barrel export: `export { default } from './SearchScreen'`
    ├── SearchScreen.tsx -- the actual component: JSX/TSX markup + logic
    └── style.module.css -- CSS Modules, scoped to this screen only
```

```
app/(main)/search/page.tsx
──────────────────────────
export { default } from '@/screens/search';
```

Rules:
1. **One folder per screen**, named to match the screen (e.g. `screens/search/`, `screens/scheme-details/`, `screens/saved/`), mirroring 04-FEATURE-INVENTORY.md's screen list.
2. **`index.tsx` is a barrel file only** — it re-exports the real component, it doesn't contain markup itself. This gives every screen the same clean import path (`@/screens/search`) regardless of what the component file inside is actually named.
3. **The component file holds the JSX/TSX** — name it after the screen (`SearchScreen.tsx`, not a second `index.tsx`), so multiple open editor tabs don't all read "index.tsx."
4. **`style.module.css` is for the exception, not the default.** This project is Tailwind-utility-first (01-DESIGN-SYSTEM.md) — reach for the CSS Module file only for things Tailwind genuinely can't express cleanly (complex keyframe animations, third-party widget style overrides), not as a place to restate spacing/color utilities that belong as Tailwind classes in the JSX itself. If a screen never needs one, omit the file rather than shipping an empty one.
5. **Screen-local sub-components live in the same folder**, not back in a global `components/` directory, unless they're reused by more than one screen — e.g. `screens/scheme-details/BenefitsTab.tsx` stays local until a second screen needs it, at which point it graduates to the shared `components/` library from 01-DESIGN-SYSTEM.md's component inventory.
