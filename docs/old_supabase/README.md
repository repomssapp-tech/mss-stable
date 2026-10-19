# OLD — retired Supabase backend (reference / one-stop deletion)

**Status: OLD. Nothing in the app, the voice agent, CI or the build tooling uses
anything in this folder.** The project moved to the MSS REST backend
(`https://api.msmeschemes.org`, references in `backend/New API Ref/`). This folder
only keeps the old backend and its paper trail so it can be consulted later
(for example when designing the new database) or deleted in one go.

## Delete it all

```powershell
Remove-Item -Recurse -Force docs\old_supabase
```

Afterwards, the only mentions of the old backend left in the repository are the
pointers in `docs/RULES.md`, `docs/SKILLS.md` and `docs/audit/AUDIT.md`; remove
those lines too if you want zero mentions.

Everything here is also in git history (the commit before the migration), so
deleting the folder loses nothing permanently.

## Layout

Files keep their **original relative path** under this folder, so restoring one is
a plain copy back (`docs/old_supabase/<path>` → `<path>`).

| Path inside this folder | What it is |
|---|---|
| `backend/supabase/` | The whole old backend: 76+ SQL migrations, `schema.sql`, `config.toml`, seed data, pgTAP tests, and the Deno edge functions (`v1`, `sarvam-chat`, `livekit-token`, `publishCatalog`, `rollbackRelease`, `db-change-notify`) |
| `.github/workflows/` | The three workflows that tested or deployed it (`backend-database`, `deploy-edge-functions`, `rls-drift-check`) |
| `.mcp.json`, `backend/deno.lock`, `backend/scripts/` | Its tooling config and two Supabase-only scripts |
| `tools/`, `scripts/` | One-off scripts that read or wrote the old database (catalog import, Hindi pipeline, audits, `publish_catalog_release.py`) |
| `docs/`, `reports/` | Architecture, runbooks, audits and migration reports written against it |
| `_moved_files.txt` | The exact list of files moved here from the working tree |

## Where each old piece went

| Old (Supabase) | Now |
|---|---|
| `profiles` table, RLS | `GET/PATCH /v1/me/profile` (ETag), onboarding `PUT /v1/me/onboarding` |
| `notifications` table + realtime | `GET /v1/me/notifications` etc., polled (see `docs/backend/LOCAL_DATA_AND_SYNC.md`) |
| `promo_alerts` table | `GET /v1/promotions` |
| catalog release RPC + Storage bucket | `GET /v1/catalog/current` + its `bundle_url` |
| Google sign-in via Supabase Auth | `POST /v1/auth/google/start` + `/exchange` (PKCE) |
| `support_tickets`, `voice_chat_sessions`, `beta_gate_config`, `delete_user`, `sarvam-chat`, `livekit-token` | Assumed routes, see `docs/backend/PENDING_ENDPOINTS.md` |
| `questionnaire_sessions`, `startup_profiles` (mirror) | No replacement route (drafts removed; business data goes through onboarding) |

## Known loose ends if the old schema is needed

- `schema.sql` is a snapshot; the migrations are the source of truth (see
  `docs/old_supabase/docs/backend/BACKEND_SPECIFICATION.md`).
- `tools/db_inspect.py` (the helper that queried the hosted database) was moved
  here; the live catalog build and release gate no longer need it and now read the
  local `catalog.content` cache.
