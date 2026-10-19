# Data Model — catalog, scheme, and user profile shapes

Source: `frontend/lib/models/mss_entity.dart`, `catalog_manifest.dart`, `scheme_model.dart`, `mss_contract.dart`, `user_profile.dart`, `docs/specs/CATALOG_SPECIFICATIONS.md`.

## 1. Catalog bundle contract

The offline catalog is **15 files**, each shaped `{ metadata: { catalogName }, data: [...] }`, plus one extra top-level file for search:

```
common_catalog.json
authority_catalog.json
institution_catalog.json
scheme_catalog.json
finance_catalog.json
tax_catalog.json
treds_catalog.json
csr_catalog.json
export_catalog.json
knowledge_catalog.json
applicability_matrix_catalog.json
enterprise_classification_catalog.json
msme_privilege_catalog.json
business_enablement_catalog.json
cluster_assistance_catalog.json
search_index.json   -- separate: tokens.{en,ta} + schemeSearchProfile per entity
```

### Raw entity shape (one record per catalog `data[]` item)

| Field | Type | Meaning |
|---|---|---|
| `identity.id` | string | Entity id |
| `identity.entityType` | string | e.g. `"scheme"` |
| `identity.code` | string | Short code (e.g. `TN130`) |
| `identity.status` | string | Falls back to top-level `status`, default `'unknown'` |
| `identity.name` | string | Fallback name if no localization present |
| `content` | object | Main body fields — free-form per entity type (benefits, `schemeUrl`, etc.) |
| `relationships.references[]` | array | Links to other entities |
| `search` | object | Search-tuning sub-fields |
| `metadata` | object | Provenance/misc |
| `localization.<lang>.name` / `.<lang>.<key>` | object | **Per-language overrides** |

**Localized name lookup order:** `localization[preferredLang].name` → `localization[altLang].name` → `identity.name` → `identity.code`.

**Generic localized attribute lookup** (`getLocalizedAttribute(key, lang)`): `localization[lang][key]` → `localization.ta[key]` → `localization.en[key]` → `''`.

### Release manifest shape

Two source shapes get reconciled into one model — a web client fetching the manifest should handle both, or normalize to one internally:

```ts
// Canonical (local/legacy shape)
interface CatalogManifest {
  id: string;
  version: number;
  schemaVersion: number;
  sha256: string;          // 64-hex
  byteSize: number;
  schemeCount: number;
  documentCount: number;
  serviceCount: number;
  publishedAt: string;     // ISO 8601
  releaseVersion?: string;
}

// Newer RPC shape (fromReleaseRpc) — same data, different keys
interface CatalogReleaseRpcResponse {
  release_version: string;
  package_sha256: string;
  package_byte_size: number;
  record_counts: Record<string, number>; // keyed by catalog file
  schema_version: number;
  published_at: string;
}
```

Identity for "is this the same release as what I have cached" = `releaseVersion + sha256` (fall back to `id` for legacy rows). A real example is in `assets/data/release.sample.json` in this handoff package.

## 2. UI-facing `Scheme` model

This is the shape the Flutter UI actually renders from (`scheme_model.dart`), assembled from the raw catalog entity at load time. It's large (60+ fields) — the key ones a web port needs first:

| Field | Type | Notes |
|---|---|---|
| `id`, `schemeCode` | string | Identity |
| `name`, `nameTa` | string | Display name, English/Tamil |
| `shortName`, `fullSchemeName` | string | |
| `ministry`, `department`, `implementingAgency` | string | |
| `matchScore` | number | Set by the search engine, not stored data |
| `governmentLevel` | `'Central' \| 'State'` | |
| `sponsoringBody`, `issuingBody`, `state`, `sector` | string | |
| `targetBeneficiary`, `schemeType`, `category` | string | |
| `overview`, `overviewTa`, `objectives` | string | |
| `benefits`, `benefitsTa` | string | |
| `subsidyPercentage`, `maxFunding`, `minFunding`, `interestSubventionRate` | number \| null | |
| `applicationMode` | string | |
| `officialWebsite`, `applicationUrl`, `guidelinesUrl`, `sourceUrl`, `schemeUrl` | string | `schemeUrl` is the canonical "Apply Now" URL |
| `status`, `isActive` | string / boolean | |
| `glanceChips[]`, `benefitTypesList[]`, `supportTypes[]` | string[] | Quick-glance tag chips |
| `specialCategories[]` | string[] | **Facet codes** — see 03-SEARCH-ALGORITHM.md filter facets |
| `eligibilityMinAge`, `eligibilityMaxAge` | number \| null | Typed facets used by the recommendation engine (distinct from display-text eligibility fields) |
| `eligibilityGenderValues[]`, `eligibilityBusinessStageValues[]` | string[] | Same — typed, not prose |
| `eligibilityCriteria[]`, `requiredDocuments[]`, `applicationProcess[]` | string[] | Detail-view content |
| `documents: SchemeDocument[]`, `requiredServices: SchemeService[]` | array | |
| `faqs: {q, a}[]` | array | |
| `helplineContactsMap` | object | |

There's also a **separate, richer contract** in `mss_contract.dart` — `SchemeResult`, `MSSSearchResponse`, `EligibilityMatch`, `FinanceBenefit`, `Citation` — used by the `/v1/search` and `/v1/eligibility` **API responses**, including fields the offline `Scheme` model doesn't have: `rankingSignals`, `matchReasons`, `confidence`, `nextActions`, `applicationState`.

**Important for the web port:** if you go with option (A) from the README (call `/v1/search` directly), implement against this **API contract** (`mss_contract.dart`'s shapes), not the offline `Scheme` model — they're not identical.

## 3. `UserProfile`

Full field list (`user_profile.dart`):

```ts
interface UserProfile {
  name: string;
  dob: string | null;          // ISO date
  gender: string;
  mobile: string;
  email: string;
  state: string;
  district: string;
  city: string;
  pinCode: string;
  community: 'General' | 'OBC' | 'EWS' | 'SC' | 'ST' | 'Others';
  religion: string;
  educationLevel: string;
  firstGenGraduate: boolean;
  annualIncome: number;
  employmentStatus: string;
  profileCompleted: boolean;
  disability: string;          // default 'None'
  veteran: boolean;
  house: string;
  area: string;
  qualification: string;
  existingBusiness: boolean;
  businessStage: string;
  businessIndustry: string;
  fundingRequired: number;
  registrationNumbers: string;
  googleUserId: string;
  emailVerified: boolean;
  provider: string;             // default 'google'
  lastLoginTime: string | null;
  updatedAt: string | null;
  language: string;             // default 'en'
  notificationsEnabled: boolean; // default true
  theme: string;                 // default 'light'
  profilePhoto: string;
  navigationMode: string;        // default 'regular'
}
```

**Three serializations exist in the Dart model — replicate the same key-mapping on the web client, since it reads/writes the same Supabase tables:**

- `toJson()` — camelCase, used for local cache.
- `toSupabase()` — snake_case DB row, with these key renames: `pinCode → pincode`, `employmentStatus → applicant_type`, `profileCompleted → is_profile_complete`, `mobile → phone`.
- `fromJson()` — accepts either casing.

**Merge policy (`mergeFrom(remote)`):** when reconciling a local profile against one just read from Supabase, the remote value wins **per-field only if it's non-blank/non-zero**, otherwise the local value is kept. This exact policy must be replicated by any web client syncing against the same `profiles` table, or local and mobile clients can fight over which value "wins" after a sync.

## 4. Supabase tables touched directly (not via the `/v1/*` API)

- **`profiles`** — the row above, keyed by the authenticated user.
- **`startup_profiles`** — business-specific fields split out from `profiles`: `existingBusiness`, `businessStage`, `businessIndustry`, `fundingRequired`, `registrationNumbers`.
- **Realtime channels**: `profiles` (own-row echo — see the reconciler-guard pattern in the main repo's `frontend/lib/providers/controllers/{language,navigation_mode}_reconciler.dart` if the web client also needs to survive a stale realtime echo overwriting a just-made local change), plus `notifications` and `catalog_sync`. Confirm exact subscription filters against `frontend/lib/providers/app_state_provider.dart` before building the web realtime layer — not independently re-verified for this handoff.
