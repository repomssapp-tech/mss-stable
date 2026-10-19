# SEO & Metadata — a genuinely new concern, not in the mobile app

The Flutter app has zero SEO surface — it's an installed app, not a crawlable site. The website changes that: scheme-discovery pages are exactly the kind of content (government scheme names, eligibility, benefits) people search for directly on Google, so treat SEO as a real requirement, not an afterthought bolted on after launch.

## Pages worth indexing

From 05-ROUTING-MAP.md, the public, content-bearing pages are the ones that should be crawlable and shareable:

- `/scheme/[id]` — the highest-value page. Someone searching "PMEGP eligibility" or a scheme's full name should land here.
- `/discover`, `/discover/category|ministry|state/[slug]` — category/browse pages are natural landing pages for broader searches ("MSME loan schemes Tamil Nadu").
- `/` (home) — the site's own entry point.

Pages that should **not** be indexed: anything behind auth (profile, saved, settings, notifications, onboarding wizard) — mark these `noindex` via Next.js metadata.

## Per-page metadata (Next.js App Router `generateMetadata`)

For `/scheme/[id]`, generate metadata from the scheme's own localized content (02-DATA-MODEL.md's `Scheme` model) rather than a static title/description:

```ts
export async function generateMetadata({ params }): Promise<Metadata> {
  const scheme = await getScheme(params.id);
  return {
    title: `${scheme.name} — MSS`,
    description: scheme.overview?.slice(0, 155) ?? scheme.benefits?.slice(0, 155),
    openGraph: {
      title: scheme.name,
      description: scheme.overview,
      images: ['/logo/Logo.webp'], // or a per-scheme image if one exists later
    },
  };
}
```

Truncate descriptions to ~155 characters (standard meta-description length) — don't dump the full overview text in.

## Structured data (JSON-LD)

Government scheme pages map reasonably well to schema.org's `GovernmentService` type. Adding this doesn't require new data — it's a re-shaping of fields already in the `Scheme` model:

```json
{
  "@context": "https://schema.org",
  "@type": "GovernmentService",
  "name": "<scheme.name>",
  "description": "<scheme.overview>",
  "provider": {
    "@type": "GovernmentOrganization",
    "name": "<scheme.ministry or scheme.implementingAgency>"
  },
  "areaServed": "<scheme.state, or 'India' if nationwide>",
  "url": "<canonical scheme detail page URL>"
}
```

Emit this via a `<script type="application/ld+json">` in the scheme detail page. This is what lets Google show rich results (eligibility, provider, region) directly in search, not just a blue link.

## Sitemap

Generate `app/sitemap.ts` dynamically from the catalog (all active, published scheme IDs) plus the static discover/category pages — don't hand-maintain a static sitemap for a catalog with ~1220 entities that changes with every release (02-DATA-MODEL.md's release manifest). Regenerate it whenever the catalog release version changes, not on every build if that's expensive.

## Localized SEO

If path-based locale routing is chosen (10-I18N.md), emit `hreflang` alternate tags between `/en/scheme/[id]` and `/ta/scheme/[id]` so search engines serve the right language version to the right searcher, rather than treating them as duplicate content.

## Things that will hurt SEO if copied uncritically from the app

- The mobile app's stale-docstring problem (comments claiming "online-first" search when it's actually offline-only, per the main repo's audit) has a web-SEO analog: **don't let `generateMetadata` silently serve stale titles/descriptions from a cached catalog bundle** after a new release publishes — tie metadata generation to the same release-version check used for data freshness (02-DATA-MODEL.md's manifest `sha256`/`releaseVersion`), not an independent cache with its own TTL.
- Client-only rendering of scheme detail pages (no SSR/SSG) means crawlers may see an empty shell — use Next.js Server Components / static generation for `/scheme/[id]` and `/discover/*` specifically, even if the rest of the authenticated app is client-rendered.
