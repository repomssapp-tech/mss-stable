# MASTER PLAN: Hindi (and future languages) for MSS App catalog

**Revision 3 (2026-10-06).** Antigravity has executed P0-P3 and a follow-up; Claude reviewed it. Changes since revision 1: D2 (the local pipeline source is the master); D15 decided (move the source into the repo now); D16 no longer tracks the exposed key (owner will handle it later); D17 now applies to every language and every change; P7 rewritten. Everything not mentioned here is unchanged.

Planner/reviewer: Claude. Executor: Antigravity. Owner: Roger.
This plan covers the whole feature end to end. `00_TASK_language_tables.md` (+ its `lang_*.sql` files) is the fully specified detail for **P0-audit and P1**. Everything after P1 is specified at behaviour level and gets a file-level design note from you before any work.

## 1. How to work (applies to every phase)

1. **One phase at a time, in order P0 → P8.** Start a phase only when the owner writes `START P<n>`.
2. **Design Note first** (P2 onward): max 1 page, no code: files you will change, tables/functions touched, test list, open questions. Post it and wait for `APPROVED P<n>`. P0 and P1 are already fully specified and need no note.
3. **Report last:** use the report template in `00_TASK` §"Report template" and add the phase's acceptance results (pass/fail per line, verbatim output). Then stop and wait for review.
4. Rules in `00_TASK` §1 apply to every phase: additive only, verbatim evidence, no secrets in files/chat, STOP on unexplained errors, `NOT RUN` when not run, keep scratch files.
5. **If this plan says "OPEN" or "owner decision" and the item is not marked DECIDED in §2, stop and ask. Do not choose.**
6. The live Supabase project is the only environment known so far. Anything that publishes a release, changes `is_current`, or writes to the DB needs the explicit approval named in the phase.

## 2. Decisions register

| ID | Decision | Status |
|---|---|---|
| D1 | Table layout: **ONE table `catalog.content`, one row per entity + language** (`en`, `ta`, `hi`, ...). A row exists only where a translation exists (no empty copies; Tamil Nadu schemes have no `hi` row). Adding a language = insert into `catalog.language` + rows, no DDL. A language pack is just `WHERE lang = '<code>'`, so it maps 1:1 to a JSON file later. | **DECIDED (owner)** |
| D2 | **The master is the local pipeline source** (the `Plan/catalog` JSON files + the tools that build, import and publish). Supabase (`catalog.scheme`, `catalog.content`, storage, `admin.catalog_*`) is **derived storage**. Every text change is made in the source, then flows source → build → DB import → release. **Nobody hand-edits `catalog.content`, `record_json` or storage objects.** A DB migration that changes catalog text is allowed only when it is generated from the same source change. | DECIDED (owner, 2026-10-06) |
| D3 | Fallback is **per field**: preferred language, else English. Detail-screen sections fall back independently. | DECIDED (Claude default, owner may veto) |
| D4 | **No "machine translated" label** in the UI for v1. `verified` and `origin` are still stored and shipped in the pack so a label can be turned on later with no data change. | DECIDED (owner) |
| D5 | Engine: Google Cloud Translation (v3 with glossary). **Prerequisite owner action:** a GCP project + credentials provided through an environment variable / secret store, never a file in the repo. | Engine DECIDED, prerequisite OPEN |
| D6 | Hindi scope v1: schemes with `government_level = central` (confirm with P0 query D) + the authority/institution/common names those schemes use. State (TN) schemes stay en/ta. | DECIDED, confirm with P0-D |
| D7 | Hindi text uses **Western digits 0-9** (no Devanagari digits). | DECIDED |
| D8 | Translation **never overwrites** a non-empty existing value. | DECIDED |
| D9 | A translated field that **fails the number check is not written**; it stays English-fallback and is recorded in `admin.translation_jobs` as `needs_review`. | DECIDED |
| D10 | The Hindi pack ships **disabled** (`catalog.language.is_active=false`) and is enabled by flipping the flag after the new app build is live. Same flag is the kill switch. | DECIDED |
| D11 | **Legacy compat:** until the minimum supported app version is one that reads packs, the bundle build keeps emitting the old `localization` blocks inside `record_json`, regenerated from the source by the build. Old app builds keep working and keep receiving Tamil updates. | Claude recommends. Owner confirms in P3 Design Note |
| D12 | Hindi search approach. | OPEN. Decide after P0 finding 6 (see P5) |
| D13 | **Stale translation** (stored `source_checksum` ≠ checksum of current English) is **excluded from the pack** (English shows) until re-translated or re-verified. | DECIDED (Claude default, owner may veto) |
| D14 | Adding a language (inserting into `catalog.language`) is done **only inside a migration file**, never by hand in the dashboard, so the change is in migration history; the language's text goes into the source first (D2). | DECIDED |
| D15 | **Move the source into the repo now.** It currently lives in a OneDrive folder outside git, so a rewrite (as happened with `scheme_catalog.json`) has no history, review or backup. Default location: `backend/catalog/source/` (the repo already has `backend/catalog/`); Antigravity may propose another path only if this one conflicts with something, and must say why. One-time move (P7 item 1): dated backup copy with sha256 of every file, copy into the repo, prove every hash identical, switch the tools' default `--source` to the repo path (keep the override), commit. Do not delete the OneDrive folder until the owner says so. After the move, source edits happen only through committed scripts, never ad-hoc `python -c`. | DECIDED (owner) |
| D16 | **Release and secret guards.** A published release version is **immutable**: the publish tool refuses an existing version and never deletes objects under a published/current version's folder; a failed publish gets a new version. Any destructive storage operation needs owner approval. Secrets are read from the environment inside scripts and never typed inline, printed, logged or committed. | DECIDED |
| D17 | **Pre-publish gate for every release, every language, every change.** One committed script, run on every candidate release, with no hard-coded language or entity list: it loops over every active row of `catalog.language`, every pack in the build, every entity type and every field in the bundle. A new language is covered automatically. It checks: (G1) drift, source ↔ `catalog.*`/`catalog.content` ↔ built core bundle and packs; (G2) **release diff**, previous current release vs candidate, per file, entity, field and language (added / removed / changed); (G3) every change must appear in the release's committed **declared-change list**, anything outside it blocks; (G4) values that existed in the previous release stay identical unless declared (this replaces the old en/ta-only E1), and a language or entity that disappears blocks unless declared as a removal; (G5) sha256 of every uploaded object equals `admin.catalog_files`, and per-language counts equal `record_counts`; (G6) the last released app build loads the candidate (E4, manual, reported). Flow: publish non-current → gate → owner approval in chat → separate `--is-current` step. The tool refuses to flip `is_current` unless the gate report for that exact candidate is PASS. Rollback = make the previous release current. | DECIDED (owner) |

## 3. Scope

**In v1:** Hindi for the 8 scheme text fields (name, shortName, summary, objective, description, benefitsText, eligibilityText, applicationText) + aliases/keywords; authority, institution and `common` term names; Hindi app UI strings; language-pack download/cache/fallback; Hindi search; verification tooling; "add a language" runbook.

**Out of v1 (do not build, do not "helpfully" add):** voice agent prompts/TTS language; `promo_alerts`, notifications, support/feedback text; per-scheme document remarks, application steps, FAQs, `classification.*Text` labels (these stay English, document *type* names come from `common` and ARE translated); Tamil for central schemes; Devanagari digits; RTL; any change to money/percentage/date fields; merging the facet tables (finance, tax, export, ...).

## 4. Target architecture

```
SOURCE (MASTER, versioned): Plan/catalog JSON + tools  --build/import-->  derived copies below
catalog.scheme / authority / institution / common   language-neutral facts (ids, status, numbers, dates, relations)  [derived]
catalog.content (entity_type, entity_id, lang)       translatable text + origin / engine / verified / source_checksum  [derived]
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
5. **Write** passing fields into the **source** (Hindi localization blocks), then import so `catalog.content` is filled from it. Values: `origin='machine'`, `engine` = the engine id, `verified=false`, `source_checksum` computed from the current English (D8: only into empty fields).
6. Same pipeline for authority / institution / `common` names once P0 finding 7 is known.
7. **Report:** counts (translated, written, `needs_review` by reason, errors), API usage, and **30 random rows (English | Hindi) per text field** for human spot-check.

**Acceptance:** re-running the number check over the whole Hindi content = 0 violations; every in-scope English field has a Hindi value or a `needs_review` job; pre-existing Hindi rows identical to before (fingerprint); no credential appears in the repo or logs. **Gate 2:** owner reviews the sample.

### P3 — Build and release pipeline

Goal: the bundle build produces core + language packs + manifest from `catalog.content`, safely, and old apps keep working.
- The build input is the **source** (D2). `catalog.content` is not a build input; it is checked against the source and the built packs by the drift check (D17a). English goes in the core file.
- Emit one pack per active language following the format conventions found in P0 (compression, naming). Contents per §4.
- Manifest and registration: add a nullable `lang` column to `admin.catalog_files` (migration), one row per pack, per-language counts in `record_counts`. Bump `schema_version` only if the core format changes.
- **D11 legacy compat:** regenerate the old `localization` blocks in `record_json` from the source so old builds are unaffected.
- **Rehearsal:** build to a local folder first; publish only as a non-current release (per P0 finding 2). Owner approval needed to publish anything `is_current`.

**Acceptance (all pasted verbatim):**
- **E1 equivalence:** for every entity x every field x every language that exists in the previous current release (read from the data, not a fixed list), the value the new pipeline yields equals what the previous release yields. Zero diffs unless declared (D17 G4); any diff is listed. (This protects existing users of every language.)
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

- **Verification loop (this is what makes "verify later" real):** export unverified Hindi rows to CSV/Sheet (English next to Hindi, ordered by `app_relevance` high → low from the v3.1 data); reviewer edits; an import tool re-runs the number check and writes the corrected Hindi plus `verified`, `verified_by`, `verified_at` and a refreshed `source_checksum` **into the source**; then the normal import → build → release (P3 process, D17 gate).
- **Stale report** (D13) and **drift report** (content vs `localization`, used until P7) as saved queries.
- **Runbook "add a language"**: one migration inserting the language row → seed → translate (P2 process) → build → verify → flip `is_active`.
- Optional counters (no personal data): pack download success/failure, fallback rate, only if the app already has an analytics path (P0 finding 3/10).

### P7 — Source hygiene and release gates (replaces "Cutover and cleanup")

There is no cutover to a database master: the source stays the master (D2). **Items 1-4 run next, before any further publish.**

1. **Move the source into the repo (D15).** Steps in order: (a) read-only inventory of the OneDrive folder: every file with size, last-modified, sha256, and which tools read it; flag any file over 50 MB; (b) dated backup copy outside OneDrive with its sha256 list; (c) copy to the repo path and prove every sha256 identical; (d) switch the tools' default source path (keep a `--source` override); (e) rebuild to a **scratch** folder and compare the **decompressed** bundle/pack JSON hashes (not the .gz bytes, which contain a timestamp) with the published release, explaining every difference; (f) commit. No publish, no deletion of the OneDrive folder.
2. **Release gate script (D17).** Committed, language- and entity-agnostic, one report per candidate: PASS/FAIL per check G1-G6, counts per language and entity type, the full diff list, and the candidate's identity (core bundle sha256 + every pack sha256). Declared-change list: a small committed machine-readable file per release (entity type, entity id or `*`, language or `*`, fields or `*`); wildcards are allowed but the report prints how many rows each wildcard matched.
3. **Publish guards (D16) and the separate `--is-current` step (D17):** the publish tool refuses an existing version, has no delete-under-a-published-version path, uploads as non-current, and flips `is_current` only in a separate command that checks the gate report for that exact candidate.
4. **Gate self-tests (acceptance for the gate itself).** Run against a local or dry candidate, never against production, output pasted verbatim:
   - T1 an unchanged candidate: PASS, empty diff.
   - T2 change one Hindi name and declare it: PASS, diff shows exactly that entity, language, field.
   - T3 the same change undeclared: FAIL naming it.
   - T4 modify a pack file after the build: FAIL on hash mismatch (G5).
   - T5 add a fixture language `te` as data only, one row, active: it appears in G1-G5 with **no code change**; remove the fixture afterwards.
   - T6 change a non-text fact in the core data (e.g. a benefit percentage), undeclared: FAIL.
   - T7 drop an existing language or an entity from the candidate, undeclared: FAIL.
5. **Template-leakage test:** for records generated from a skeleton, a test fails if a new record holds a non-empty skeleton value it should not have (the "PM Vishwakarma alias on 84 schemes" bug class).
6. **Cleanup is a later, separate approval,** only once the minimum supported app version reads packs: stop emitting legacy `localization` in `record_json`, retire `name_ta` and other duplicated columns, bump `schema_version`.

### P8 — Rollout

Internal build → owner QA → staged rollout if the store supports it → flip Hindi `is_active` → watch the counters/crash reports → **rollback = flip `is_active` off and republish** (no app update needed).

## 6. Production-ready definition (all must be true)

- E1-E4 pass; fingerprint unchanged by P1; tests in P4 green in CI or run and pasted.
- No Hindi field with a number mismatch; stale and unverified counts reported.
- Old app build verified against the new release; kill switch tested (flag off → app shows English, no errors).
- No secrets in the repo; new tables deny-by-default until access is deliberately mirrored (separate approved step).
- Pack size within the owner's budget; Hindi renders correctly on the QA devices.
- A named person owns verification of Hindi text and the runbook exists.
- The source is in git (D15); the drift check passes (D17a); the publish tool refuses existing versions and has no delete-under-current path (D16); the release gate (D17) passes for every language.

## 7. Risks the owner has accepted or should watch

- **Unverified machine-translated eligibility/benefit text with no label (D4).** Wrong text can mislead applicants. Mitigations built in: number check (D9), stale exclusion (D13), `verified` shipped, priority-ordered verification loop, kill switch.
- **Seed baseline is optimistic:** at seed time each translation's checksum is set against the current English, so existing Tamil/Hindi can be older than that without anyone knowing. Stale detection only works from here on.
- **Single-machine source (until D15 is done)** and a published release that went `is_current` before E1/E4 were shown. Both are being closed by the verification prompt.
- **Only one environment is known.** Publishing mistakes hit real users. Hence non-current rehearsal releases and explicit approvals.
- **Search and voice in Hindi are unproven** until P5.
- Findings in P0 may change P3-P5. This plan is then updated before they start.
