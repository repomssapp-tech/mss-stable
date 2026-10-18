# MASTER PLAN: Hindi (and future languages) for MSS App catalog

Planner/reviewer: Claude. Executor: Antigravity. Owner: Kishaunjith.
This plan covers the whole feature end to end. `00_TASK_language_tables.md` (+ its `lang_*.sql` files) is the fully specified detail for **P0-audit and P1**. Everything after P1 is specified at behaviour level and gets a file-level design note from you before any work.

## 1. How to work (applies to every phase)

> **Execution Directive (Owner, 2026-10-06):** Complete all phases autonomously without waiting for owner approval after any single phase. Complete them all end-to-end, validating acceptance criteria at each step.

1. **Phases executed in order P0 → P8.**
2. **Design Notes & Validation:** Compile design specs, execute tests, verify integrity constraints at each phase gate.
3. **Report:** Generate reports with verbatim outputs and evidence.
4. Rules in `00_TASK` §1 apply to every phase: additive only, verbatim evidence, no secrets in files/chat, STOP on unexplained errors, `NOT RUN` when not run, keep scratch files.
5. Decisions already locked in §2 or user instructions govern execution.
6. Supabase project `houpzsxmwemoztpuigmo` is the target environment.

## 2. Decisions register

| ID | Decision | Status |
|---|---|---|
| D1 | Table layout: **ONE table `catalog.content`, one row per entity + language** (`en`, `ta`, `hi`, ...). A row exists only where a translation exists (no empty copies; Tamil Nadu schemes have no `hi` row). Adding a language = insert into `catalog.language` + rows, no DDL. A language pack is just `WHERE lang = '<code>'`, so it maps 1:1 to a JSON file later. | **DECIDED (owner)** |
| D2 | After cutover **`catalog.content` is the source of truth** for translatable text. Until P7, `record_json.localization` is frozen (no edits). | DECIDED |
| D3 | Fallback is **per field**: preferred language, else English. Detail-screen sections fall back independently. | DECIDED (Claude default, owner may veto) |
| D4 | **No "machine translated" label** in the UI for v1. `verified` and `origin` are still stored and shipped in the pack so a label can be turned on later with no data change. | DECIDED (owner) |
| D5 | Engine: Google Cloud Translation (v3 with glossary). **Prerequisite owner action:** a GCP project + credentials provided through an environment variable / secret store, never a file in the repo. | Engine DECIDED, prerequisite OPEN |
| D6 | Hindi scope v1: schemes with `government_level = central` (confirm with P0 query D) + the authority/institution/common names those schemes use. State (TN) schemes stay en/ta. | DECIDED, confirm with P0-D |
| D7 | Hindi text uses **Western digits 0-9** (no Devanagari digits). | DECIDED |
| D8 | Translation **never overwrites** a non-empty existing value. | DECIDED |
| D9 | A translated field that **fails the number check is not written**; it stays English-fallback and is recorded in `admin.translation_jobs` as `needs_review`. | DECIDED |
| D10 | The Hindi pack ships **disabled** (`catalog.language.is_active=false`) and is enabled by flipping the flag after the new app build is live. Same flag is the kill switch. | DECIDED |
| D11 | **Legacy compat:** until the minimum supported app version is one that reads packs, the bundle build keeps emitting the old `localization` blocks inside `record_json`, regenerated from `catalog.content`. Old app builds keep working and keep receiving Tamil updates. | Claude recommends. Owner confirms in P3 Design Note |
| D12 | Hindi search approach. | OPEN. Decide after P0 finding 6 (see P5) |
| D13 | **Stale translation** (stored `source_checksum` ≠ checksum of current English) is **excluded from the pack** (English shows) until re-translated or re-verified. | DECIDED (Claude default, owner may veto) |
| D14 | Adding a language (inserting into `catalog.language`) is done **only inside a migration file**, never by hand in the dashboard, so the change is in migration history. | DECIDED |

## 3. Scope

**In v1:** Hindi for the 8 scheme text fields (name, shortName, summary, objective, description, benefitsText, eligibilityText, applicationText) + aliases/keywords; authority, institution and `common` term names; Hindi app UI strings; language-pack download/cache/fallback; Hindi search; verification tooling; "add a language" runbook.

**Out of v1 (do not build, do not "helpfully" add):** voice agent prompts/TTS language; `promo_alerts`, notifications, support/feedback text; per-scheme document remarks, application steps, FAQs, `classification.*Text` labels (these stay English, document *type* names come from `common` and ARE translated); Tamil for central schemes; Devanagari digits; RTL; any change to money/percentage/date fields; merging the facet tables (finance, tax, export, ...).

## 4. Target architecture

```
catalog.scheme / authority / institution / common   language-neutral facts (ids, status, numbers, dates, relations)
catalog.content (entity_type, entity_id, lang)       translatable text + origin / engine / verified / source_checksum
            |                                              |
            +------------- bundle build (script) ----------+   (pack = rows WHERE lang = '<code>')
                   core file  = facts + ENGLISH text            (bundled in APK, always works offline)
                   pack file  = one per ACTIVE language          (downloaded on demand)
                   manifest   = per file: name, language, sha256, bytes, row count; catalogRelease
                   registered in admin.catalog_files / catalog_releases, stored in bucket `catalogs`
                                   |
App:  APK has English core + all UI strings  ->  user picks Hindi  ->  download pack  ->  verify sha256  ->  cache
      Resolver(entity, field, language): pack value if non-empty, else English value, else hide the section
```

Behaviour rules (the contract between P3 and P4):
- English is always available offline. UI strings for **all** languages ship in the APK.
- Preferred language set but pack not downloaded: show English, offer a non-blocking "Download Hindi content" action. No crash, no empty screens.
- Download fails or sha256 mismatch: discard the partial file, keep the previous pack if one exists else English, retry later. **Never half-apply a pack.**
- Pack updates when the manifest hash for that language differs from the cached one.
- Filtering/sorting/search ranking use ids and enums, never translated display text.
- Pack rows contain: entity type + id, the 8 text fields, aliases, keywords, `verified`. They do **not** contain audit columns (`engine`, `source_checksum`, `verified_by`, timestamps).
- Pack only contains entities whose parent scheme is publishable under today's bundle rule, and only for languages with `is_active=true`.

## 5. Phases

### P0 — Discovery and audit (read-only)

Run `00_TASK` **Part A** (A1-A4) and answer these 12 questions in a single `DISCOVERY.md` (facts with file paths, no opinions, `UNKNOWN` if not found):
1. Which script(s) build the release files from the catalog tables: inputs, outputs, file format, compression, naming, how they are run.
2. Release publish flow: how rows reach `admin.catalog_releases`/`catalog_files`, storage upload, `package_sha256`, what `is_current` and min/max app version do. Is there a non-current/test channel?
3. App side: which Dart classes download, parse, cache the bundle; every place `localization` / `name_ta` is read; which interface screens use (`ISchemeRepository`?); how a cached older bundle is upgraded.
4. Language setting: where stored (`profiles.language`, local prefs), how UI language vs content language is chosen, allowed values, any constraint on `profiles.language`.
5. ARB/i18n setup: location, languages present, number of keys, any Hindi strings already.
6. Search: what `HybridSchemeSearch` indexes (which files/fields), embedding model and whether it handles Hindi, how the voice path feeds it.
7. `catalog.common`: structure and which fields are display text (from `lang_a2` G1/G2).
8. Where the existing 128 Hindi names/fields came from (human or machine) per `provenance`.
9. Environments: is there any staging/branch project, or only the live one?
10. Existing tests and CI layout.
11. Fonts: any custom font setup; one screenshot of a Devanagari string rendering in the current app, if feasible.
12. Size baseline: gzip size of each current release file and total.

**Acceptance:** all 12 answered; A1-A3 outputs posted per the `00_TASK` flag table. **Gate 0:** Claude reviews, then finalizes the file-level detail of P3-P5. Owner answers D1.

### P1 — Database foundation (tables only, nothing reads them yet)

Exactly `00_TASK` Parts B and C (dry run, then apply after the owner types `APPLY`). Additions to that document:
- Expect the Supabase advisor to report **"RLS enabled, no policy"** on the new tables. That is intended. **Do not add policies or grants in this phase.**
- New languages are added only by a migration that inserts into `catalog.language` (D14); no DDL is ever needed.
- Do not bump `catalogRelease`, do not publish.
- Acceptance: the Part C checks; fingerprint identical to A3; `git status` shows only the new migration file.

### P2 — Hindi content

Goal: every in-scope entity has Hindi for every English field it has, or a recorded reason why not.
1. **Gap list** (Design Note): per entity type and field, count rows where English is non-empty and Hindi is empty. Scope = D6.
2. **Glossary / do-not-translate list** (proposed in the Design Note, owner approves): acronyms (PMEGP, MSME, CGTMSE, ZED, ...), ₹ and numerals, portal and scheme proper names.
3. **Translate in resumable batches** within the API's limits. Job states in `admin.translation_jobs`: `pending → translated → checked → written | needs_review | error`. Re-running must be safe (idempotent) and must skip finished jobs.
4. **Checks per field (before writing):**
   - *Number check (blocking):* normalise digits (incl. Devanagari), %, ₹, years, "lakh/crore" ↔ "लाख/करोड़"; the multiset of numbers must be equal in English and Hindi.
   - *Script check (blocking):* output is predominantly Devanagari (acronyms excepted).
   - *Length ratio (flag only):* Hindi shorter than 0.4x or longer than 3x the English goes to the report, not blocked.
5. **Write** passing fields into Hindi content: `origin='machine'`, `engine` = the engine id, `verified=false`, `source_checksum` computed from the current English (D8: only into empty fields).
6. Same pipeline for authority / institution / `common` names once P0 finding 7 is known.
7. **Report:** counts (translated, written, `needs_review` by reason, errors), API usage, and **30 random rows (English | Hindi) per text field** for human spot-check.

**Acceptance:** re-running the number check over the whole Hindi content = 0 violations; every in-scope English field has a Hindi value or a `needs_review` job; pre-existing Hindi rows identical to before (fingerprint); no credential appears in the repo or logs. **Gate 2:** owner reviews the sample.

### P3 — Build and release pipeline

Goal: the bundle build produces core + language packs + manifest from `catalog.content`, safely, and old apps keep working.
- Read **all text from `catalog.content`**, not from `localization`. English goes in the core file.
- Emit one pack per active language following the format conventions found in P0 (compression, naming). Contents per §4.
- Manifest and registration: add a nullable `lang` column to `admin.catalog_files` (migration), one row per pack, per-language counts in `record_counts`. Bump `schema_version` only if the core format changes.
- **D11 legacy compat:** regenerate the old `localization` blocks in `record_json` from `catalog.content` so old builds are unaffected.
- **Rehearsal:** build to a local folder first; publish only as a non-current release (per P0 finding 2). Owner approval needed to publish anything `is_current`.

**Acceptance (all pasted verbatim):**
- **E1 equivalence:** for all schemes x 8 fields x {en, ta}, the value the new pipeline yields equals the value the current bundle yields today. Zero diffs; any diff is listed. (This protects existing Tamil users.)
- **E2:** pack row counts equal the `catalog.content` counts for that language.
- **E3:** manifest sha256 matches each file.
- **E4:** the last released app build loads the new release correctly (manual test, report the build/version used).
- **Size report:** gzip size of core and each pack vs the P0 baseline. Owner sets a budget; if the Hindi pack exceeds it, split list/detail then, not before.

### P4 — App

- Language picker offers Hindi; `profiles.language` accepts `hi` (migration if P0 finding 4 shows a constraint).
- **Hindi UI strings:** every ARB key translated (machine first, owner reviews). A script lists keys in English missing in Hindi; must be **0**.
- A **content resolver** behind the existing repository interface implements §4. After this phase **no screen reads `localization` directly**.
- **Pack manager:** download on switch, sha256 verify, atomic replace, cache, update-on-manifest-change, failure handling per §4, offline first launch.
- UI for download progress/failed state. Fallback is silent per D3.
- **Devanagari QA:** no clipped conjuncts or line-height issues on cards, chips, buttons, dialogs; works at 1.3x text scale; checked on at least one low-end and one recent Android device.

**Tests required:** unit (per-field fallback, language switch, bad sha256 rejected, interrupted download leaves previous pack intact); widget/golden for key screens in `hi`; integration (offline first launch in Hindi falls back to English cleanly; online switch downloads and shows Hindi). **Gate 4:** owner device QA.

### P5 — Hindi search (needs D12)

Options, decide after P0 finding 6: **A** (Claude recommends first) add Hindi name/summary/keywords to the on-device search index so Devanagari queries match; **B** English-only index plus query transliteration/translation (weaker); **C** multilingual embeddings (only if the current model supports Hindi and cost allows).
Voice path: Hindi transcript goes through the same index as typed text.
**Acceptance:** the owner supplies ~20 real Hindi queries (include "कारीगर", "ऋण", "सब्सिडी") **and sets the pass mark before the test**; report which queries hit the expected scheme and rank.

### P6 — Verification and operations

- **Verification loop (this is what makes "verify later" real):** export unverified Hindi rows to CSV/Sheet (English next to Hindi, ordered by `app_relevance` high → low from the v3.1 data); reviewer edits; an import tool re-runs the number check, sets `verified`, `verified_by`, `verified_at`, refreshes `source_checksum`; then a normal release (P3 process).
- **Stale report** (D13) and **drift report** (content vs `localization`, used until P7) as saved queries.
- **Runbook "add a language"**: one migration inserting the language row → seed → translate (P2 process) → build → verify → flip `is_active`.
- Optional counters (no personal data): pack download success/failure, fallback rate, only if the app already has an analytics path (P0 finding 3/10).

### P7 — Cutover and cleanup

1. Freeze edits to `localization` (D2). 2. Drift report must be **0 differences** or each one reviewed; if not, re-seed in a migration. 3. Publish the first `is_current` release built from `catalog.content` (owner approval). 4. From then on, text edits happen only in `catalog.content`.
**Cleanup is a separate, later approval and only once the minimum supported app version reads packs:** stop emitting `localization` in `record_json`, retire `name_ta` and other duplicated columns, bump `schema_version`. Never earlier.

### P8 — Rollout

Internal build → owner QA → staged rollout if the store supports it → flip Hindi `is_active` → watch the counters/crash reports → **rollback = flip `is_active` off and republish** (no app update needed).

## 6. Production-ready definition (all must be true)

- E1-E4 pass; fingerprint unchanged by P1; tests in P4 green in CI or run and pasted.
- No Hindi field with a number mismatch; stale and unverified counts reported.
- Old app build verified against the new release; kill switch tested (flag off → app shows English, no errors).
- No secrets in the repo; new tables deny-by-default until access is deliberately mirrored (separate approved step).
- Pack size within the owner's budget; Hindi renders correctly on the QA devices.
- A named person owns verification of Hindi text and the runbook exists.

## 7. Risks the owner has accepted or should watch

- **Unverified machine-translated eligibility/benefit text with no label (D4).** Wrong text can mislead applicants. Mitigations built in: number check (D9), stale exclusion (D13), `verified` shipped, priority-ordered verification loop, kill switch.
- **Seed baseline is optimistic:** at seed time each translation's checksum is set against the current English, so existing Tamil/Hindi can be older than that without anyone knowing. Stale detection only works from here on.
- **Only one environment is known.** Publishing mistakes hit real users. Hence non-current rehearsal releases and explicit approvals.
- **Search and voice in Hindi are unproven** until P5.
- Findings in P0 may change P3-P5. This plan is then updated before they start.
