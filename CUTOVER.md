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
| Edge fn `v1` (x2 sites) | injected `SUPABASE_SERVICE_ROLE_KEY` | `SUPABASE_SECRET_KEY` | secret | project function secret |
| Edge fn `publishCatalog` | injected `SUPABASE_SERVICE_ROLE_KEY` (+ wrong `\|\| ANON_KEY`) | `SUPABASE_SECRET_KEY` | secret | project function secret |
| Edge fn `livekit-token` | injected `SUPABASE_ANON_KEY` | `SUPABASE_PUBLISHABLE_KEY` | publishable | project function secret |
| Edge fns `recommend` / `schemes-api` / `search` (DEAD) | injected `SUPABASE_ANON_KEY` | `SUPABASE_PUBLISHABLE_KEY` | publishable | project function secret |
| Agent `saarthi-agent` (chat logging) | env `SUPABASE_SERVICE_ROLE_KEY` | `SUPABASE_SECRET_KEY` | secret | `.env.sarvam` -> `lk agent update-secrets` |
| `backend/scripts/import_catalog.mjs` | `SUPABASE_SECRET_KEY` (already) | `SUPABASE_SECRET_KEY` | secret | `backend/.env` / CI |
| `backend/scripts/benchmark_search_pipeline.mjs` | hardcoded `sb_publishable_...` | `SUPABASE_PUBLISHABLE_KEY` | publishable | `backend/.env` / local |
| `tools/publish_catalog_release.py` | hardcoded `sb_publishable_...` | `SUPABASE_PUBLISHABLE_KEY` | publishable | `backend/.env` / local |

`SUPABASE_DB_URL` (in `.github/workflows/rls-drift-check.yml`) is a Postgres
connection string, **not an API key** -- out of scope for this cutover.

## Swap order

1. **Create the new keys** in the Supabase dashboard -> Project Settings -> API
   Keys. Both legacy and new keys are now active simultaneously.
2. **Set the Edge Function project secrets** (project-scoped -- one setting
   applies to every function; you run these, they are not run by tooling):
   ```
   supabase secrets set SUPABASE_SECRET_KEY=sb_secret_REPLACE --project-ref houpzsxmwemoztpuigmo
   supabase secrets set SUPABASE_PUBLISHABLE_KEY=sb_publishable_REPLACE --project-ref houpzsxmwemoztpuigmo
   ```
   If `supabase secrets set` rejects the `SUPABASE_` prefix as reserved, rename
   the new vars to `SB_SECRET_KEY` / `SB_PUBLISHABLE_KEY` across the edits
   (`backend/supabase/functions/**`, `chat_logger.py`, the two scripts,
   `dart_defines.example.json`, this file) -- one follow-up commit -- and re-run.
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
supabase secrets unset SUPABASE_SECRET_KEY SUPABASE_PUBLISHABLE_KEY --project-ref houpzsxmwemoztpuigmo
supabase functions deploy v1 livekit-token publishCatalog --project-ref houpzsxmwemoztpuigmo
```
For the agent, remove `SUPABASE_SECRET_KEY` and set `SUPABASE_SERVICE_ROLE_KEY`
instead. For Flutter, rebuild with the old publishable key value. A legacy key
that was deactivated in step 8 can be re-activated in the dashboard (reversible).
No source revert is needed to roll back -- only the secret values.
