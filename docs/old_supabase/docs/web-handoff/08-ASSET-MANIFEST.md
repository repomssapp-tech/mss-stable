# Asset Manifest — everything in `frontend/assets/`, and what's copied here

Full inventory of the Flutter app's asset directory, so the web team knows what exists before recreating anything from scratch. **Binary image assets are intentionally NOT duplicated into this handoff package** (large, and this repo already has them) — pull each one from `frontend/assets/` in the main repo directly as each page is built. Only small, load-bearing config/data files and the two core logo files were copied into `assets/` alongside this doc set, since those are what the search/branding code actually needs verbatim.

## Copied into this handoff package (`docs/web-handoff/assets/`)

| File | Source | Why it's copied here |
|---|---|---|
| `logo/Logo.webp` | `frontend/assets/images/Logo/Logo.webp` | Primary brand mark, needed immediately for any header/nav |
| `logo/Logo-icon.webp` | `frontend/assets/images/Logo/Logo icon.webp` | Favicon/compact-mark equivalent |
| `data/search_taxonomy.json` | `frontend/assets/search/search_taxonomy.json` | Canonical search weights/vocab — must be read verbatim, not retyped (03-SEARCH-ALGORITHM.md) |
| `data/query_expansion.json` | `frontend/assets/search/query_expansion.json` | Tanglish/regional query-expansion table — same reason |
| `data/release.sample.json` | `frontend/assets/catalog/release.json` | Real example of the catalog release manifest shape (02-DATA-MODEL.md) |

## Not copied — pull from `frontend/assets/` directly when needed

### `images/Background/` (12 files) — screen-specific banners
`Home_screen_bg.webp`, `Login_bg.webp`, `alert banner.webp`, `companion intro bg.webp`, `mode selection bg.webp`, `new scheme banner.webp`, `notification banner.webp`, `onboarding_bg.webp`, `profile process banner.webp`, `search_banner.webp`, `splash_screen.webp`, `suggestion banner.webp`, `tip banner.webp`.

Each is used by exactly one screen — pull the specific file as that screen is built rather than bulk-copying all 12 up front.

### `images/Logo/` (remaining files) — partner branding, not needed for the site itself
`TN Chapter_20260805_153104_0000.{png,webp}`, `TN Chapter_20260805_153307_0000.{png,webp}`, `compoanion bot.webp` (companion-mode avatar, out of scope per README), `rit_logo.webp`, `rit_logo_white.png`, `sss_tn_chapter_logo.webp` — these are institutional/partner logos (RIT, SSS TN Chapter) shown in the mobile splash screen's "developed by" footer. Only pull these if the website needs the same attribution footer.

### `images/States assets/` (57 files) — state emblems and outline maps
- `Indian emblem.webp` — national emblem.
- `State Emblem/` — 28 files, one per state, filenames are the state's proper English name (e.g. `Tamil Nadu.webp`), mostly consistent, with one typo to fix if reused: `Maghalaya.webp` (should be `Meghalaya`).
- `States/` — 28 outline-map files, filenames are **inconsistently cased and contain more typos** than the emblem set: `Anrunachal pradhesh.webp` (Arunachal Pradesh), `Chhatishgar.webp` (Chhattisgarh), mixed casing throughout (`Kerala.webp` vs `andhra pradesh.webp`). **Recommendation: rename to a consistent slug scheme (e.g. `tamil-nadu.webp`, matching the `state` facet codes from 03-SEARCH-ALGORITHM.md) when porting, rather than propagating the inconsistent source names to the website's asset pipeline.**

Only needed if the website implements a "browse by state" visual grid (05-ROUTING-MAP.md's `/discover/state/[slug]`) — pull on demand.

### `images/saarthi/`, `images/supporting assets/` — companion/voice-mode art
`saarthi/sarathi.webp` (companion avatar), `supporting assets/support_agent.webp`, `supporting assets/user_avatar.webp` (chat avatars). Out of scope for the initial web port per the README (voice/companion UI) — revisit if that scope changes.

### `catalog/catalog_bundle.json.gz`, `catalog/translation_dictionary.json`
The full offline catalog bundle (~1220 entities, gzipped) and the English→Tamil runtime translation dictionary. **Do not copy these into a web project's static assets as-is** — per the README's open decision, the web architecture should serve catalog data via CDN + versioned releases or via the live API, not by shipping the same gzip blob a mobile app install would. Use `assets/data/release.sample.json` in this package to understand the manifest shape, then fetch the real current bundle/manifest from wherever the team decides to host it (Supabase Storage, a CDN bucket) rather than from this static copy, which will go stale.

## Fonts

No font files to copy — everything is loaded from Google Fonts by family name at runtime (Poppins, Inter for English; Noto Sans Tamil, Arima for Tamil). Use `next/font/google` with the same family names; see 01-DESIGN-SYSTEM.md for which style uses which family/weight.

## Icons

No icon asset files — the app uses Material Icons exclusively (no custom icon font). Use `@mui/icons-material` or `lucide-react` on the web; there's nothing to extract here beyond picking equivalent icon names per use (01-DESIGN-SYSTEM.md's component table names the semantic icon for each spot that has one, where obvious from the widget name).
