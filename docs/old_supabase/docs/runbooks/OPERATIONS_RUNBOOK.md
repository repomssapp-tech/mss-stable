# MSS Operational Runbooks & Deployment Procedures

**Audience:** Platform engineers, release managers, and operators maintaining production Supabase services and publishing catalog releases.

## Table of Contents
1. [Part 1: Production Catalog Publish Checklist & Runbook](#part-1-production-catalog-publish-checklist--runbook)
2. [Part 2: Supabase API Key Cutover Runbook](#part-2-supabase-api-key-cutover-runbook)

---

# Part 1: Production Catalog Publish Checklist & Runbook

# Production Catalog Publish Checklist

Prepared after a full staging validation of `tools/publish_catalog_release.py`
against a local Supabase stack (`supabase start`, exact schema mirror of
production via the same migrations) on 2026-08-16. See "Staging validation
results" below for what was actually exercised and confirmed. **This
checklist has not yet been run against production `--target linked`.**

## What this does, in one sentence

Publishes an edited `Plan/catalog/` (or `--source PATH`) as the new catalog
release: every already-installed app picks it up automatically on its next
open/resume -- no Play Store release, no user action.

## Pre-flight (do this before touching production)

1. Edit the source data under `Plan/catalog/` (or your `--source` path).
2. Bump `catalogRelease` in `Plan/catalog/manifest.json` to a new value.
   The script refuses to publish a release_version that's already live --
   this is the safety net against accidentally re-publishing an unchanged
   tag.
3. Run a dry run first:
   ```
   python tools/publish_catalog_release.py --target linked --dry-run
   ```
   This regenerates the bundle locally and prints `bundleSha256`,
   `bundleBytes`, and `recordCounts` -- **no Supabase calls are made**.
   Sanity-check the record counts match what you expect (e.g. did you
   actually add the scheme you meant to add? did any catalog's count drop
   unexpectedly, which usually means a source file got truncated?).
4. Review `git diff` / `git status` -- a dry run does not touch any repo
   file, so if anything under `frontend/assets/catalog/` shows as modified
   at this point, something is wrong; stop and investigate before
   proceeding.

## Execution

```
python tools/publish_catalog_release.py --target linked
```

You'll be asked to confirm (`About to publish release_version=... to ALL
live users`). Read the currently-live version shown and make sure it's the
one you expect to be replacing. Pass `--yes` only for scripted/CI use where
a human already reviewed the dry run.

The script then, in order:
1. Confirms `release_version` differs from what's currently live.
2. Regenerates and applies `catalog.*` import SQL (keeps the live `/v1/*`
   API in sync with the same source data) -- ~24 chunked SQL files, applied
   via `supabase db query --linked --file`.
3. Builds the release bundle and copies it into
   `frontend/assets/catalog/` (so the next app build also ships current
   data). **This modifies a tracked repo file** -- commit it as part of the
   same change that prompted the data update, or `git checkout` it back if
   you don't want the shipped-asset copy to move yet.
4. Uploads the merged bundle + all 16 individual source files to Storage
   under `releases/<version>/`.
5. Inserts the new `admin.catalog_releases` row (current) + 16
   `admin.catalog_files` rows + an `admin.catalog_release_history`
   'published' entry, and demotes the previous current release (demoted,
   never deleted).
6. Verifies live `mss_current_release()` matches what was just built, plus
   `admin.catalog_files` row count and referential integrity.

If any step fails, **nothing after it has run** -- e.g. a failure at step 4
means the pointer was never flipped, so production keeps serving the old
release untouched.

## Post-publish verification (do this regardless of how confident you are)

1. `mss_current_release()` returns the new `release_version` and a
   `package_sha256` that matches what the script printed.
2. Spot-check one changed record via the live API (e.g.
   `mss_scheme_detail` for a scheme you edited) to confirm the *content*
   change is visible, not just the version tag.
3. If you have a spare device/emulator with the app already installed and
   signed in: force-stop and relaunch it, then confirm (via `adb logcat`
   filtering for `MssCatalogBundle`) that it installs and loads the new
   release. Not required for every publish, but worth doing for anything
   beyond a trivial text fix.
4. Keep an eye on your Supabase project's logs/error rate for a few
   minutes after publishing -- a bad `record_json` shape wouldn't fail the
   publish script (it doesn't validate business logic, only structural
   things like file existence and hashes) but could break a specific
   scheme's detail page.

## Rollback (if something looks wrong after publishing)

```
python tools/publish_catalog_release.py --target linked --rollback-to <previous-version>
```

This only flips `is_current`/`status` on `admin.catalog_releases` -- it does
**not** touch `catalog.*` row content or Storage. So a rollback restores
which release *new syncs* pull, but doesn't undo the `catalog.*` upserts
from the bad publish (those already had correct checksums for whatever
content you gave the script -- if the *content itself* was wrong, e.g. a
typo in a scheme name, you need to fix the source and publish again with a
new version, not just roll back the pointer).

Any device that already fully downloaded and installed the bad release
before you rolled back will re-sync down to the restored version on its
next open (same detection mechanism as any other version change) -- the
[`SchemeCatalogStore`](frontend/lib/services/scheme_catalog_store.dart)
keeps the previous release's files on disk until a new install fully
succeeds, so this downgrade is exactly as safe as any other publish.

## Known constraints

- **Windows + `npx`**: the script shells out via `cmd.exe` on Windows for
  `npx supabase ...` calls -- this is already handled, not something you
  need to do manually.
- **`admin.catalog_files.checksum`/`storage_path` are per-release** -- a
  rollback doesn't delete the bad release's `catalog_files` rows or Storage
  objects, it just stops it being current. They stay around as a normal
  historical (`status='published'`, `is_current=false`) release, not an
  "orphan" -- nothing references them as broken, and nothing deletes them
  automatically. Clean up manually via the Supabase dashboard if a
  particular test/bad release needs to be fully removed from Storage.
- **`--target` has no default** -- you must always type `local` or `linked`
  explicitly. There is no footgun where omitting a flag accidentally hits
  production.

## Staging validation results (2026-08-16)

Run against a `supabase start` local stack (Docker-based, exact schema
mirror via the same migrations `--linked` production runs), seeded with a
byte-for-byte baseline matching production (`package_sha256` matched
production's real hash exactly: `ccc3251ae2dccaf...`).

Published test release `1.33.0-alpha-script-test1` with `--target local`,
then confirmed:

| Check | Result |
|---|---|
| Release pointer update | `mss_current_release()` returned the new version/hash immediately after publish |
| `catalog_files` generation | 16/16 rows inserted, `checksum` verified against a downloaded object's actual SHA-256 |
| Storage artifact creation | All 17 objects present (16 source files + merged bundle); bundle downloaded and hash-matched |
| SHA-256 generation | Bundle hash + all 16 per-file hashes verified against re-downloaded bytes |
| Manifest correctness | `admin.catalog_releases` row fields match `CatalogManifest.fromReleaseRpc()`'s expected shape exactly |
| Row reconciliation | All 15 `catalog.*` tables summed to 1216 rows post-publish (no loss/duplication) |
| Flutter sync compatibility | Bundle's 17 top-level keys and `mss_current_release()`'s field names match what the Dart client code parses, byte-identical structure to the real production bundle verified earlier this session |
| Rollback process | `--rollback-to 1.33.0-alpha` restored the original pointer; verified via live RPC |
| Previous release pointer restored | Confirmed `is_current=true` back on `1.33.0-alpha` |
| No catalog content changed | `catalog.scheme` row checksum for a spot-checked record matched production's real value exactly |
| Hashes unchanged | Same as above |
| No orphan releases | Both releases present with valid, non-null, correctly-scoped `catalog_files` |
| No broken references | Explicit `catalog_files -> catalog_releases` LEFT JOIN check found zero dangling rows |
| Production untouched | `mss_current_release()` against production showed the exact same `published_at` timestamp before and after this entire staging exercise |

One real bug was found and fixed during this validation: `supabase db query
--file` cannot execute multi-statement SQL scripts against `--local` or
`--db-url` connections (only against the managed `--linked` API endpoint --
confirmed by testing both). The script now routes local execution through
`docker exec <db_container> psql` instead, which has no such restriction.
This is a `--target local`-only code path; `--target linked` was always
using the working CLI path and is unaffected.

---

# Part 2: Supabase API Key Cutover Runbook

# Supabase API key cutover

Migration from the **legacy** Supabase keys (`anon` / `service_role` JWTs) to
the **new** keys (`sb_publishable_...` / `sb_secret_...`). The code change
(branch `chore/supabase-new-api-keys`) is **staged**: every runtime reads the
new env var first and falls back to the legacy one, so nothing breaks until the
legacy keys are deactivated. Deactivation is the **last** step and is a manual
Supabase dashboard action.

Project ref: `houpzsxmwemoztpuigmo`.

## Blast radius

| Runtime | Old source | New env var | Tier | Set where |
|---|---|---|---|---|
| Flutter app | hardcoded `sb_publishable_...` literal | `SUPABASE_PUBLISHABLE_KEY` | publishable | `--dart-define-from-file=dart_defines.json` at build |
| Edge fn `v1` (x2 sites) | injected `SUPABASE_SERVICE_ROLE_KEY` | `SB_SECRET_KEY` | secret | project function secret |
| Edge fn `publishCatalog` | injected `SUPABASE_SERVICE_ROLE_KEY` (dropped a wrong anon fallback) | `SB_SECRET_KEY` | secret | project function secret |
| Edge fn `livekit-token` | injected `SUPABASE_ANON_KEY` | `SB_PUBLISHABLE_KEY` | publishable | project function secret |
| Edge fns `recommend` / `schemes-api` / `search` (RETIRED) | archived in `docs/archive/` | `SB_PUBLISHABLE_KEY` | publishable | retired / superseded |
| Agent `saarthi-agent` (chat logging) | env `SUPABASE_SERVICE_ROLE_KEY` | `SUPABASE_SECRET_KEY` | secret | `.env.sarvam` -> `lk agent update-secrets` |
| `backend/scripts/import_catalog.mjs` (superseded) | `SUPABASE_SECRET_KEY` (already) | `SUPABASE_SECRET_KEY` | secret | `docs/archive/` |
| `backend/scripts/benchmark_search_pipeline.mjs` | hardcoded `sb_publishable_...` | `SUPABASE_PUBLISHABLE_KEY` | publishable | `backend/.env` / local |
| `tools/publish_catalog_release.py` | hardcoded `sb_publishable_...` | `SUPABASE_PUBLISHABLE_KEY` | publishable | `backend/.env` / local |

`SUPABASE_DB_URL` (in `.github/workflows/rls-drift-check.yml`) is a Postgres
connection string, **not an API key** -- out of scope for this cutover.

## Swap order

1. **Create the new keys** in the Supabase dashboard -> Project Settings -> API
   Keys. Both legacy and new keys are now active simultaneously.
2. **Set the Edge Function project secrets.** The Supabase CLI reserves the
   `SUPABASE_` prefix (`supabase secrets set SUPABASE_* ...` is silently
   skipped), so the Edge Functions read `SB_SECRET_KEY` / `SB_PUBLISHABLE_KEY`.
   These are project-scoped -- one setting applies to every function:
   ```
   supabase secrets set SB_SECRET_KEY=sb_secret_REPLACE --project-ref houpzsxmwemoztpuigmo
   supabase secrets set SB_PUBLISHABLE_KEY=sb_publishable_REPLACE --project-ref houpzsxmwemoztpuigmo
   supabase secrets list --project-ref houpzsxmwemoztpuigmo
   ```
   (Only the Edge Functions use `SB_*`. The backend scripts, the agent, and the
   Flutter build read `SUPABASE_SECRET_KEY` / `SUPABASE_PUBLISHABLE_KEY` from a
   plain `.env` / dart-define -- not `supabase secrets` -- so the reserved-name
   check does not apply to them.)
3. **Redeploy the live functions** so they pick up the new secrets:
   ```
   supabase functions deploy v1 livekit-token publishCatalog --project-ref houpzsxmwemoztpuigmo
   ```
4. **Provision the agent secret.** In `saarthi-agent/.env.sarvam` set
   `SUPABASE_URL` and `SUPABASE_SECRET_KEY=sb_secret_...`, then:
   ```
   lk agent update-secrets --secrets-file .env.sarvam --overwrite
   lk agent deploy
   ```
5. **Rebuild / redeploy the Flutter app.** Copy `frontend/dart_defines.example.json`
   to `frontend/dart_defines.json`, put the `sb_publishable_...` key in
   `SUPABASE_PUBLISHABLE_KEY`, and build with
   `--dart-define-from-file=dart_defines.json`.
6. **Update backend script env.** Put `SUPABASE_SECRET_KEY` and
   `SUPABASE_PUBLISHABLE_KEY` in `backend/.env` (and the CI secret store if the
   catalog import runs in CI).
7. **Soak.** Leave both legacy and new keys active for a bounded window (a few
   days) and confirm every runtime below is green on the new keys.
8. **Deactivate the legacy keys** (dashboard -> API Keys -> disable the legacy
   `anon` / `service_role` keys). This is the last step. Do NOT rotate the JWT
   secret as part of this.

## Verify each runtime (do before step 8)

- **Edge Functions:**
  - `curl https://houpzsxmwemoztpuigmo.supabase.co/functions/v1/v1/health` -> `200 {"status":"ok"}`
  - `curl -H "apikey: <publishable>" https://houpzsxmwemoztpuigmo.supabase.co/functions/v1/v1/meta`
    -> `200` with catalog counts (proves the **secret** client works).
  - `supabase functions logs v1 --project-ref houpzsxmwemoztpuigmo` -> no
    "Supabase environment variables are missing".
- **`livekit-token`:** from the app, request a token with a valid signed-in
  session -> `200` (not `503 "not configured"`, not `401`).
- **Flutter:** app initializes (no `StateError: SUPABASE_PUBLISHABLE_KEY is not
  set`), a scheme search returns results.
- **Agent:** run one voice session, then
  `psql "$SUPABASE_DB_URL" -c "select count(*), max(created_at) from public.chat_logs;"`
  -> a new row. A single `ChatLogger requires SUPABASE_SECRET_KEY ...` ERROR
  line means the agent secret did not land.
- **Scripts:** `SUPABASE_PUBLISHABLE_KEY=... npm run benchmark:search` runs;
  `SUPABASE_SECRET_KEY=... npm run catalog:validate` runs.

## Rollback

Removing the new function secrets makes every function fall back to the injected
legacy vars (the `?? SUPABASE_SERVICE_ROLE_KEY` / `?? SUPABASE_ANON_KEY`
chains):
```
supabase secrets unset SB_SECRET_KEY SB_PUBLISHABLE_KEY --project-ref houpzsxmwemoztpuigmo
supabase functions deploy v1 livekit-token publishCatalog --project-ref houpzsxmwemoztpuigmo
```
For the agent, remove `SUPABASE_SECRET_KEY` and set `SUPABASE_SERVICE_ROLE_KEY`
instead. For Flutter, rebuild with the old publishable key value. A legacy key
that was deactivated in step 8 can be re-activated in the dashboard (reversible).
No source revert is needed to roll back -- only the secret values.
