# Task: Migrate scheme data v3.1 into the MSS App catalog (Supabase + offline bundle)

You are working in the MSS App repo (github.com/Roger-Chris/MSS_App) with Supabase project `houpzsxmwemoztpuigmo`.
Your input is the unzipped folder `mss_scheme_data_v3_1/` (this file is in it). Do the work in **phases**. **STOP at the end of every phase**, write the report asked for, and wait for Kishaunjith to say "continue". Do not start the next phase on your own.

## Hard rules (read twice)

1. **Audit before you edit.** Before changing a table, file or function, read it and write down what is there now. Every claim in your reports must come from a command you ran or a file you read. Paste the query or command next to the result. Never write "verified", "tested" or "works" unless you ran the check and show the output.
2. **The DB and the offline bundle must stay in sync.** Every catalog change follows the existing pattern: **data migration file in `supabase/migrations/` → catalog JSON bundle regenerated → `catalogRelease` version bump → publish release → cache-bust**. Do not edit `catalog.*` rows by hand in the dashboard or with ad-hoc SQL. Find how releases `1.34.0-alpha` to `1.34.3-alpha` were made (migrations `publish_release_1_34_*`, `admin.catalog_releases`, the bundle build script in the repo) and copy that pattern exactly. The current release is **1.34.3-alpha**, with 219 schemes. Use **1.35.0-alpha** for this work.
3. **Stay in scope.** Touch only catalog data, the migration and bundle files it needs, and the release record. No refactors. No Flutter UI changes, except a schema/model change that is needed to read a new field, and only if Kishaunjith approves it in Phase 1. Do not touch auth, RLS, rate limiting, voice, or `AppStateProvider`.
4. **Never invent data.** Use only values that are in `data/msme_schemes_v3_1.json` or the worklists. If a field has no value, leave it `null` and add it to `verification.missingFields` the same way existing records do. Do not "fix" amounts from memory or the web.
5. **Money is numeric.** Store INR as integers in the `*AmountInr` fields. Keep `*Text` fields for display, in Indian lakh/crore format (e.g. "₹25 lakh", "₹10 crore").
6. **Work on a branch:** `data/catalog-v3-1-migration`. Test the migrations on a Supabase **branch database** (or local `supabase db reset`) first. Apply to production only in Phase 6, after approval.
7. **The decisions marked "DECISION FOR KISHAUNJITH"** in the worklists are not yours to make. List them and wait.

## Using agents and skills

**Skills (load before Phase 0):**
- Check which skills the workspace already has (`.agent/skills/`, the global Antigravity skills folder, any `SKILL.md` in the repo). List them in the Phase 0 report, then read and follow the ones that apply: Supabase/Postgres, migrations, catalog/bundle release, Flutter build.
- If the Supabase agent skills are not installed, propose `npx skills add supabase/agent-skills` and wait for approval before running it. When a skill applies, follow its guidance on migrations, RLS and grants.
- Skills say *how* to do things. They do not widen scope. If a skill's advice conflicts with the hard rules above, the hard rules win. Report the conflict.

**Agents (parallel work):**
- Only read-only or file-generating work may run in parallel. Good candidates:
  - Phase 0 audit split by area: DB tables / bundle + release scripts / Dart model + fallback code.
  - Phase 1 building the 3 example records.
  - Phase 3 and Phase 4 building `record_json` in batches (e.g. by `01_new_scheme_actions.csv` row ranges, keeping each parent with its children in the same batch).
  - Phase 6 URL HEAD checks.
- **One agent only, the main one, applies migrations, touches the database, regenerates the bundle or publishes a release.** Sub-agents never run SQL that writes, never run `supabase db push`, and never publish.
- Give every sub-agent:
  - the hard rules section
  - its exact input rows or files
  - one output file path under `reports/` or `scripts/catalog_v3_1/out/`
  - the instruction to put problems in a `flags` list instead of guessing
- The main agent merges the sub-agent outputs, then re-validates the merged result itself: schema check, id uniqueness, parent/child pairs, no overwritten verified fields. It never trusts a sub-agent's "done" without checking.
- Name each agent and its task in the phase report. Keep it to about 5 agents per phase.
- If an agent fails or is rate-limited, re-run only its batch. Do not regenerate everything.

## What is in the folder

| Path | What it is |
|---|---|
| `data/msme_schemes_v3_1.json` | 393 records. `meta` + `schemes[]`. Ids `MSME2015-*` = 2015 Hindi compendium (historical, official Hindi). `MSME2526-*` = Ministry of MSME Schemes Booklet 2025-26. `NEW2026-*` = other new central schemes (web research, sources in each record). |
| `data/new_schemes_2025_26.json` | The 114 `MSME2526-*` / `NEW2026-*` records only. Main input for Phases 2–4. |
| `data/msme_schemes_v3_1.schema.json` | JSON Schema (Draft 2020-12) for the above. Validate before using. |
| `worklists/01_new_scheme_actions.csv` | One row per new record: `action` = `ENRICH_EXISTING` / `ADD_NEW` / `ADD_CHILD` / `SKIP_CLOSED`, plus `proposed_record_status` (PUBLISHED / DRAFT). |
| `worklists/02_catalog_corrections.csv` | Status fixes and duplicates for existing catalog rows (DAY-NULM, IES, SFURTI, Khadi Vikas Yojana, Coir MCY, ESDP and Stand-Up India duplicates, CGTMSE). |
| `worklists/03_enrich_existing_map.csv` | Catalog id → our record to enrich from (30 rows). |
| `worklists/04_hindi_backfill.csv` | Hindi for `record_json.localization.hi` (currently null for every scheme). |
| `worklists/05_open_issues.csv` | 282 flags (uncertain status, unverified amounts, agent notes). These must survive into `verification` / `provenance` notes. |
| `docs/CHANGELOG_v3_1.md`, `docs/CHANGELOG_v3.md` | Background: what was found and how the data was built. |

Key fields in a v3.1 record: `name{hi,en}`, `ministry`, `division`, `source_current{document_url, as_of, page_book, description/benefits/eligibility {hi[],en[]}, application_steps[{step, action{hi,en}, mode, where, url, documents[]}], hi_is_machine_translation}`, `benefit_facts[{type, max_amount_inr, min_amount_inr, percent, percent_of, condition_en, source_quote_en, quote_verified, as_of}]`, `targeting{beneficiary_types, target_groups, sectors, age_min, age_max, min_education}`, `contacts[]`, `status{value, confidence, note_en, verified_on, source_url}`, `current{...official_url, sources[]}`, `parent_id`, `children_ids`, `mss_catalog_ids`, `catalog_match`, `app_relevance`, `agent_flags[]`.

---

## Phase 0: Audit (read-only)

1. Validate both JSON files against the schema (`python -m jsonschema` or ajv). Report the error count.
2. Read the existing catalog setup and report what you find (file paths, function names, row counts):
   - `catalog.scheme` columns and the full `record_json` shape (use SCH000124 as the reference record)
   - `catalog.relationships` (relationship types in use: `child_of`, `parent_of`, `related_to`, …)
   - `catalog.applicability_matrix` (one row per scheme today: 219)
   - `catalog.search_index`
   - `catalog.entity_registry`
   - the checksum trigger
   - `admin.catalog_releases` / `admin.catalog_release_history`
   - the bundle JSON files (`scheme_catalog.json`, `applicability_matrix_catalog.json`, `search_index.json`, `release.json`)
   - the script that builds and publishes the bundle
3. Report how scheme ids are allocated (max today is `SCH000219`), how `identity.code` and `legacyCodes` are set, and how Tamil (`localization.ta`, `name_ta`) is generated today (script? manual?).
4. For every catalog id in `02_catalog_corrections.csv` and `03_enrich_existing_map.csv`, show the current `status`, `is_active`, `identity.status` and `verification.status`.

**STOP. Report:** findings, a proposed field mapping (Phase 1), and any field in v3.1 that has no home in `record_json`. Ask whether storing the 2015 compendium as reference data (Phase 5) is wanted.

## Phase 1: Mapping spec (no DB writes)

Write `docs/catalog_v3_1_mapping.md` in the repo. It maps each v3.1 field to a `record_json` path. Start from this, and correct it against what you found in Phase 0:

| v3.1 | record_json |
|---|---|
| `name.en` / `name.hi` | `identity.name`, `localization.en.name` / `localization.hi.name`; column `name_en` |
| `source_current.description.en[]` | `content.overview.summary` (first point), `content.overview.description` (joined), `content.objectives[]` |
| `source_current.benefits.en[]` | `content.benefits.summary`, `localization.en.benefitsText` |
| `benefit_facts[]` | typed buckets in `content.benefits`. Mapping: grant→`grant`, loan→`loan`, subsidy→`capitalSubsidy` (or `marginMoney` if the quote/condition says margin money), interest_subvention→`interestSubvention`, guarantee→`guarantee` (`coveragePercent`, `maxCoverInr`), insurance→`insurance`, reimbursement→`reimbursement`, tax_concession→`taxBenefit`, training/stipend→`trainingSupport`, facility/other→description text only. Set `applicable=true`, `benefitTypes[]`, `conditions[]` from `condition_en`. If one bucket gets several facts, keep the main one in the numeric fields and the rest in `conditions[]` / `variesBy`. |
| `source_current.eligibility.en[]` + `targeting` | `content.eligibility.narrative.criteria`. `structured`: age_min/max→`age`, women→`gender.values`, sc/st/obc/minority→`community.values`, pwd/ex_serviceman→`specialCategory.values`, rural/urban→`location.areaTypes`, ner→`location.states` (8 NE states), sectors→`sector.included`, micro/small/medium_enterprise→`enterprise.types`; `content.targetBeneficiaries.*` |
| `source_current.application_steps[]` | `content.applicationProcess.steps[]`, `mode`, `onlineUrl`; documents→`content.requiredDocuments[]` (match `documentTypeId` from `common_catalog` by exact alias only) |
| `contacts[]` | `content.contacts.national[]` / `helplines[]` |
| `current.official_url` | column `scheme_url`, `content.schemeUrl` |
| `source_current.document_url`, `current.sources[]` | `content.sources[]` (booklet = primary for `MSME2526-*`, `publisherText` "MSME Schemes 2025-26") |
| `status` | `identity.status` (active/closed/unknown/announced), `verification.status/confidence/verifiedAt/notes` |
| `agent_flags[]`, `05_open_issues.csv` | `verification.notes` + `verification.disputedFields` (for `quote_verified=false` amounts) + `provenance.transformationNotes` |
| `id` (our id) | `identity.legacyCodes += {system: "mss_v3_1", code: "<our id>"}` |
| `parent_id` / `children_ids` | `catalog.relationships` `child_of` / `parent_of` + `record_json.relationships.references` |
| `related_v3_ids` / successors | `related_to` relationships (and successor for DAY-NULM / IES) |
| Hindi | `localization.hi.*` from `04_hindi_backfill.csv`. Add a `provenance.translations.hi` block shaped like the `ta` one: `status` "machine" or "official_2015_name_only", `reviewRequired: true` |

Rules for the mapping:
- `ENRICH_EXISTING` **only fills empty/null fields and appends** sources, steps and notes. It never overwrites a field that is already `verified` in `verification.verifiedFields`. Where our value differs from an existing non-null value, do not overwrite it. Put it in a conflicts list for review.
- `metadata.catalogVersion` = `1.35.0-alpha`; bump `metadata.revision`; `schemaVersion` unchanged unless Phase 0 shows it must change.

**STOP. Report:** the mapping doc, plus 3 fully built example `record_json` objects (one `ADD_NEW` = `NEW2026-001`, one `ADD_CHILD` = `MSME2526-002`, one `ENRICH_EXISTING` diff for `SCH000124` from `MSME2526-078`). Wait for approval.

## Phase 2: Corrections to existing rows (migration, branch DB only)

From `02_catalog_corrections.csv`:
- Apply the rows marked high/medium confidence that are **not** "DECISION FOR KISHAUNJITH": SCH000043 → closed with successor link; SCH000070 → closed/merged with link to the Export Promotion Mission record; SCH000144, SCH000076 and SCH000035 → active/PUBLISHED; SCH000168 → ARCHIVED, `related_to` SCH000218.
- SCH000064 vs SCH000038: audit only, report.
- ESDP duplicate (SCH000055/SCH000095) and Mahila Coir Yojana (SCH000082): list the options, do nothing.
- Each changed row gets a `provenance.transformationNotes` entry naming the reason and source, and `verification` updated with the date and source URL.

Write one migration: `<timestamp>_catalog_v3_1_status_corrections.sql`.

**STOP. Report:** before/after for each row (query output).

## Phase 3: Enrich existing schemes (30 rows in `03_enrich_existing_map.csv`) + Hindi backfill (61 rows)

- Build the enriched `record_json` with a script (Python or Node, committed under `scripts/catalog_v3_1/`). Do not hand-edit JSON.
- Hindi: fill `localization.hi.*` and `name_hi` **if a `name_hi` column exists; do not add columns without approval**. Rows with `translation_status = none` are skipped and listed. 2015 Hindi is **name only**; never copy 2015 amounts.
- Produce `reports/enrich_conflicts.csv` (catalog_id, field, existing_value, v3_1_value).

Migration: `<timestamp>_catalog_v3_1_enrich_existing.sql`.

**STOP. Report:** counts filled per field, the conflicts file, and 3 sample diffs.

## Phase 4: Add new schemes (`ADD_NEW` + `ADD_CHILD`, 83 rows; skip `SKIP_CLOSED`)

- Allocate ids `SCH000220` upward in the order of `01_new_scheme_actions.csv`. Write `reports/id_map.csv` (our_id → SCH id).
- Insert parents before children. Create `child_of` / `parent_of` relationship pairs. Group headers (`is_group_header=true`, e.g. Export Promotion Mission, Niryat Protsahan, Niryat Disha) become parent scheme rows.
- `status` column = `proposed_record_status` (PUBLISHED or DRAFT); `is_active` accordingly; `government_level='central'`; `scheme_type` from the existing vocabulary only (pick from the `benefit_facts` types; if unclear, null + missingFields).
- `ministry` → resolve `classification.government.ministryId` against `authority` by **exact normalised name** (the existing rule R1). If no match, use text only; do not create authorities.
- For each new scheme also create its `applicability_matrix` row and `search_index` row, in the same way existing ones were made (find the generator; do not invent embeddings — if embeddings are produced by a job, list the rows needing it).
- Tamil: if a Tamil generation script exists, report it and **ask** before running it. Otherwise leave `localization.ta` null and `name_ta` null, list the rows, and confirm the app falls back to English (check the Dart code, show the line).
- `entity_registry`: sync using the existing mechanism (`populate_and_sync_entity_registry`).

Migration: `<timestamp>_catalog_v3_1_add_schemes.sql` (data generated by the committed script).

**STOP. Report:** inserted counts by status, the id map, relationship counts, and any rows the script rejected.

## Phase 5 (only if approved in Phase 0): store the source datasets as reference data

Create a non-public reference table (proposal: `catalog.scheme_source_v3_1(id text pk, source text, record jsonb, imported_at timestamptz)`) holding all 393 v3.1 records as-is. Put it in the **admin/catalog schema with no anon/authenticated grants**, following the existing lockdown migrations. Do **not** add it to the app bundle. Purpose: provenance, Hindi text and history (2015 records with merged/discontinued status) for later use.

**STOP. Report.**

## Phase 6: Validate, bundle, release (production only after approval)

1. On the branch DB, check and show the query output for each:
   - scheme count = 219 + (Phase 4 inserts) − 0 deletions
   - every `child_of` has a matching `parent_of`
   - no orphan relationship ids
   - checksums updated by the trigger
   - every new PUBLISHED row has `name_en`, `scheme_url` or `applicationProcess.onlineUrl`, and at least one `content.sources[]`
   - the eligibility RPC and search RPC return a few new schemes (e.g. "PM Surya Ghar", "credit guarantee exporters", "MCGS")
2. Regenerate the bundle with the existing build script. `release.json` `searchIndexCount` must equal the record count in `search_index.json` (known past issue: check it). Record counts in `admin.catalog_releases.record_counts` must match the files.
3. Publish **1.35.0-alpha** via the existing release mechanism and cache-bust as previous releases did.
4. Build the Android app in debug, open a new scheme (NEW2026-001 / its SCH id) and an enriched one (SCH000124). Report what shows, including the Hindi locale if the app supports it. Screenshots or logs, not claims.

**STOP before applying to production.** After approval, apply the migrations to production in order. Re-run the step-1 checks on production and paste the results.

## Final deliverable

A PR from `data/catalog-v3-1-migration` containing:
- the migrations
- `scripts/catalog_v3_1/`
- `docs/catalog_v3_1_mapping.md`
- `reports/` (id_map, enrich_conflicts, rejected rows, open decisions)
- the regenerated bundle

The PR description lists every DECISION FOR KISHAUNJITH still open and every row left as DRAFT, with the reason.

## Known data caveats (carry them into `verification.notes`, don't hide them)

- **Booklet text was extracted through a summarising fetch tool, not raw PDF text.** 9 key amounts were checked against the PDF: 7 matched; CGTMSE (booklet ₹5 crore vs ₹10 crore from 01.04.2025) is kept with dates; PMEGP's general-category split is not cleanly stated, so keep the 15–35% range.
- `source_current.*.hi` is **machine-translated** (`hi_is_machine_translation=true`). Mark translation status "machine", `reviewRequired: true`.
- **Statuses to treat as uncertain** (verification confidence low/medium):
  - PMEGP: approved to 31.03.2026, continuation not confirmed.
  - MSME Champions: period 2021-22 to 2025-26.
  - Skill India, PM-DAKSH, NAMASTE, Samarth, Silk Samagra-2, AHIDF: period ended Mar 2026.
  - NEW2026-017 Credit Cards for Micro Enterprises: news-sourced.
  - NEW2026-018 First-time women/SC/ST entrepreneurs: announced only, so DRAFT.
- **Several official portals timed out during research.** `official_url` values for kviconline, scsthub, aspire, pmvishwakarma, coirboard and cgtmse were not live-checked; check them with a HEAD request in Phase 6 and report.
