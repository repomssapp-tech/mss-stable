# TASK: per-language content tables (MSS App) — Parts A, B (read-only / rolled back) then C (apply)

Executor: Antigravity. Reviewer: Claude (reads your report and looks for mistakes). Owner: Kishaunjith.
Project: MSS_App, Supabase `houpzsxmwemoztpuigmo` (linked = **the live database**). Run the CLI from `backend/`.
SQL files sit next to this document (`lang_*.sql`). **Copy them unchanged. Do not retype or "improve" them.**

## 0. Goal

Add one text table per language (`catalog.content_en`, `content_ta`, `content_hi`, same shape) holding the translatable text
that today lives inside `catalog.scheme.record_json -> 'localization'` (+ `name_en`/`name_ta` columns, + authority/institution names).
This is **additive**: nothing existing is changed, the app does not read the new tables yet.

## 1. Rules (read first, they override everything below)

1. **Additive only.** Do not alter, drop, rename or update any existing table, column, row or `record_json`.
   Do not touch Dart code, Edge Functions, storage, the catalog bundle, or `catalogRelease`. **No bundle publish, no release bump.**
2. **Nothing is written to the live DB until the user types `APPLY` in chat** (Part C). Parts A and B must leave zero persistent changes.
3. **Evidence rules** (the previous run broke these, so they are strict):
   - Paste command output **verbatim** in fenced blocks. Do not re-format into your own tables, round, or compute percentages.
   - The SQL you report must be the **exact file you ran** (`Get-Content <file>`), not a retyped/shortened version.
   - If output is truncated, say so and give the row count.
   - **Keep every scratch file until the reviewer accepts the report.** Do not delete them. Put them in `backend/scratch/lang/` (do not commit).
   - If you did not run something, write `NOT RUN`. Never write "verified" for something you did not run.
4. **If a command errors:** paste the error. You may fix a typo you can name and re-run (report both runs). Otherwise **STOP and report**.
   Never work around a failure (e.g. a different runner, a different DB, skipping a probe).
5. If the CLI returns only the **last** statement's result for a multi-statement file, split the file at the `-- X.` comment headers and run each
   query separately. Report each one.
6. No secrets in files or chat. SQL files are ASCII; when concatenating files in PowerShell use `Set-Content -Encoding ascii`.

## 2. What is already known (so you can spot surprises)

From the earlier name-coverage run (`catalog.scheme`, 302 rows = 281 `PUBLISHED`/active + 21 `ARCHIVED`):

| | count |
|---|---|
| have an English name | 302 |
| have a Tamil name (`name_ta` column **or** `localization.ta.name`) | 219 |
| have a Hindi name (`localization.hi.name`) | 128 |
| have all three | 45 |

Derived (inclusion–exclusion, **to be confirmed by query D below**): Tamil-only = 174, Hindi-only = 83, both = 45, neither = 0.
These are **name** counts only. Coverage of the other seven fields is unknown. That is what Part A finds out.

## Part A — Read-only audit (no changes)

Run in this order. All are `SELECT`s.

| # | File | Notes |
|---|---|---|
| A1 | `lang_a1_audit.sql` | Queries A–F, H, L. Reviewer-tested on synthetic data. |
| A2 | `lang_a2_audit_untested.sql` | Queries G1, G2, I1, I2, J1, J2, J3. **Not** tested by the reviewer (tables absent from the sandbox). Paste errors as-is. |
| A3 | `lang_a3_fingerprint.sql` | Row counts + md5 of existing scheme/authority/institution data. **Save this output**: Part C must reproduce it exactly. |
| A4 | code audit (below) | Read-only `rg`. |

```
rg -n -g "!*.json" -g "!*.lock" -g "!node_modules" "localization|name_ta|nameTa" .
rg -n -g "!*.json" -g "!*.lock" -g "!node_modules" "preferredLanguage|\.language\b|languageCode" lib
```
For A4 report: the list of files + one line each. Say which file(s) parse `localization` (a) in the app and (b) in the bundle-build scripts. Do not open the JSON bundles.

What to flag in the A1 output (state `MATCH` / `DIFFERENT` next to each, quoting the numbers):

| Query | Expected | If different |
|---|---|---|
| A (field coverage) | `total` = 302 on every row; `hi name` = 128 | say which fields are empty for hi/ta |
| B | **0 rows** | rows = schemes with ta/hi text but no name; the migration would skip them. Report, do not fix |
| C | `both_but_different` = 0 | migration makes `localization` win over the typed column; report the count |
| D | no `neither`; hi-only = 83; ta-only = 174; both = 45; **which `government_level` each group belongs to** | report exactly |
| E | `PUBLISHED`/true = 281, `ARCHIVED`/false = 21 | report |
| F | provenance rows per language | if there is no `hi` provenance, Hindi rows will seed as `origin='imported'` |
| H | policies + grants on `catalog.scheme` | report verbatim (used later to mirror access) |
| L | with_ta counts for authority / institution | needed to predict Part B counts |

## Part B — Dry run (everything is rolled back)

**B1. Atomicity probe.** Proves the CLI runs a file as one transaction.
```
npx supabase db query --linked --file backend/scratch/lang/lang_b1_atomicity_probe.sql
npx supabase db query --linked "select to_regclass('catalog._atomicity_probe') as probe_table"
```
Expected: first command errors with `PROBE: expected failure`; second returns **null**.
If it returns a table name: run `drop table catalog._atomicity_probe;` and **STOP** (the runner is not atomic; do not continue).

**B2. Create the migration file (do NOT push it).**
```
npx supabase migration new content_language_tables
```
Paste the **full contents** of `lang_b2_migration.sql` into the file it creates. Then `Get-Content` the new file and compare line count with the original (199 lines).

**B3. Dry run = migration + a report block that raises on purpose (so everything rolls back).**
```
Get-Content lang_b2_migration.sql, lang_b3_dryrun_report.sql | Set-Content -Encoding ascii backend/scratch/lang/scratch_dryrun.sql
npx supabase db query --linked --file backend/scratch/lang/scratch_dryrun.sql
npx supabase db query --linked "select to_regclass('catalog.content_en') as should_be_null"
```
Expected: an **error** whose text starts `DRYRUN_REPORT (rolled back on purpose): {...}`, then `should_be_null` = **null**.
Paste the whole JSON. If instead you see `ASSERT FAILED [...]`, paste it and STOP: that means a data assumption is wrong, which is useful information, not a failure of yours.

Predicted DRYRUN_REPORT (adjust with A1 results; mismatch is not an error, just report it):
- `content_en`: scheme 302, authority 131, institution 83
- `content_ta`: scheme 219, authority/institution = `with_ta` from query L
- `content_hi`: scheme 128
- `scheme_partition`: has_ta/has_hi = (true,false) 174, (false,true) 83, (true,true) 45, (false,false) 0

### >>> GATE 1 — STOP HERE. Post the Part A + B report (template below) and wait for the user to type `APPLY`. <<<

## Part C — Apply (only after the user types `APPLY`)

C1. `npx supabase db push --linked --dry-run` must list **exactly one** pending migration (the one from B2). Any other pending migration: STOP.
C2. `npx supabase db push --linked`
C3. Run `lang_c1_verify.sql` (V1-V6) and `lang_a3_fingerprint.sql` again.
    **The fingerprint output must be byte-identical to A3.** Any difference: STOP and report immediately.
C4. `git status` and `git diff --stat`: the only change must be the new migration file.
C5. Report (template below). Then stop. Do not start later phases.

Rollback: `lang_z_down.sql` — **only if the reviewer or user says so.** It drops only what this migration created.

## What the migration does (for your understanding, not to be changed)

- Creates `catalog.language` (en, ta active; hi inactive), `content_en/ta/hi`, helper functions, `catalog.add_language(code, native_name)`.
- Seeds: English/Tamil/Hindi **schemes** from `record_json->'localization'` (Tamil falls back to typed `name_ta`, English to `name_en`;
  JSON wins when both exist), plus authority/institution names from typed columns.
- `origin`/`engine`/`verified` come from `record_json->'provenance'->'translations'->'<lang>'` (`machine`->machine, `human`/`verified`/`approved`/`reviewed`->human, anything else or missing->`imported`; `verified` = `isApproved`).
- `source_checksum` = md5 of the English fields the translation sits next to (used later to detect stale translations).
- RLS on, **no policies, all privileges revoked from anon/authenticated** on purpose; access gets mirrored from Query H in a later, separate step.
- Ends with an assertion block; any count mismatch aborts the whole migration.

## Later phases — DO NOT START (each gets its own plan and gate)

2. Fill Hindi gaps via `admin.translation_jobs` + Google Translate (API key from env/secret store only, never in a file), with a digit/₹ consistency check.
3. App/bundle: ship `content_<lang>` as a downloadable pack with per-field fallback to English.
4. Mirror RLS/grants for the new tables; flip `catalog.language.is_active` for `hi`.
5. Cleanup: stop reading `name_ta` / `localization.*` and strip the non-English blocks from `record_json`.

## What the reviewer did / did not test

Tested (throwaway Postgres 16, synthetic rows shaped like the `SCH000008` record you pasted): migration in one transaction; assertion failures on tampered
data and on orphan rows; re-run fails cleanly with no partial state; `add_language` (creates table, RLS on, no anon/auth privileges, bad/duplicate code rejected);
stale-translation query; down script; dry-run-by-exception leaves nothing behind; ASCII-only SQL; queries A–F, H, L, fingerprint and V1–V6 run.
**Not tested:** anything against the real database; whether `supabase db query` is atomic (that is probe B1); queries in `lang_a2_audit_untested.sql`;
Windows/PowerShell command forms.

## Report template (one message, in this order)

```
## Part A / B / C report
### Environment
- git branch + commit, CLI version (`npx supabase --version`), date/time

### Commands run (verbatim, in order)
<each command exactly as typed>

### Raw output (verbatim, one fenced block per command, same order)
<paste>

### Expected vs actual
<one line per row of the flag table: MATCH / DIFFERENT + the two numbers>

### Anomalies / errors / things that surprised you
<list, or "none">

### Not run / skipped
<list, or "none">

### Files created or changed (git status output verbatim)
```
