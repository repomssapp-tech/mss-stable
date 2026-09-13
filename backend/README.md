# IN Schemes backend

Supabase backend, administration contracts, and Tamil voice research for the
IN Schemes Flutter application. The existing citizen-facing scheme,
recommendation, and search schema remains intact; the additive administration
foundation introduces tenant-aware staff roles, region assignments,
taxonomies, and append-only audit storage.

## Layout

```text
backend/
├── openapi/openapi.yaml     Draft `/v1` administration and sync contract
├── catalog/                 Canonical search_taxonomy.json & search_parity_golden.json
├── supabase/
│   ├── functions/           Active Edge Functions: v1, livekit-token, publishCatalog,
│   │                        rollbackRelease, sarvam-chat, db-change-notify;
│   │                        Retired (410 GONE): recommend, search
│   │   └── _shared/         Shared CORS handling and search taxonomy
│   ├── migrations/          76 forward-only database migrations
│   ├── seed/                Scheme data and organization fixtures
│   └── tests/database/      pgTAP schema and RLS tests
├── package.json             Pinned Supabase and OpenAPI tooling
└── README.md
```

Architecture documentation lives at the repository root in `docs/` (e.g. `docs/DATABASE_ARCHITECTURE.md`, `docs/SEARCH_AND_CATALOG_ARCHITECTURE.md`). Offline Tamil ASR research tooling lives at `tools/voice-lab/`.

## Local database

Requirements: Node.js 20.19.x or 22.12+ and Docker Desktop using Linux
containers.
Run commands from `backend/`:

```powershell
npm ci
npm run supabase:start
npm run db:validate
npm run openapi:lint
```

Stop the local services without deleting their data:

```powershell
npm run supabase:stop
```

To deploy functions after linking the intended Supabase project:

```powershell
npx supabase db push
npx supabase functions deploy v1
npx supabase functions deploy livekit-token
npx supabase functions deploy publishCatalog
npx supabase functions deploy rollbackRelease
npx supabase functions deploy sarvam-chat
npx supabase functions deploy db-change-notify
```

> **Note:** `recommend` and `search` are retired (`410 GONE`) and superseded by `v1` (see `docs/runbooks/CUTOVER.md`).

## Published mobile scheme catalog

The relational scheme tables are the editorial source of truth. The mobile app
reads a validated, immutable release snapshot (`1.34.3-alpha`, 219 schemes / 1,220 entities)
and keeps the bundled JSON (`catalog_bundle.json.gz`) as its factory fallback.

Bundles are compiled by `tools/generate_catalog_bundle.py` and published to the
Supabase Storage bucket `catalogs` under `releases/<release_version>/catalog_bundle.json.gz`.

After publishing an artifact, broadcast the catalog sync notification via the
`publishCatalog` Edge Function:

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/publishCatalog \
  -H "Authorization: Bearer $SUPABASE_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d '{"releaseTag": "1.34.3-alpha"}'
```

To roll back to a previous release without altering release contents, invoke the
`rollbackRelease` Edge Function or call the `public.mss_rollback_release(uuid)` RPC.

## Administration foundation

The `20260727000100_admin_foundation.sql` migration builds on the existing
`public.users` identity table. Staff access is represented by protected
organization memberships, roles, and recursive region assignments. Anonymous
access is revoked only for these administration tables so the Flutter app's
public scheme reads continue to work.

The organization seed currently contains synthetic Tamil Nadu fixtures. It is
safe for local development and must be replaced with authoritative codes before
production use.

## Tamil voice lab

Offline Tamil ASR benchmarks (Whisper vs. AI4Bharat) and deterministic
scheme-vocabulary tests live in `tools/voice-lab/`. See [`tools/voice-lab/README.md`](../tools/voice-lab/README.md)
for setup, benchmark results, and model limitations.

## Product status

The administration and offline-sync endpoints in `openapi/openapi.yaml` are a
draft contract; their Edge Function implementations are future milestones. See
`docs/DATABASE_ARCHITECTURE.md` and `docs/SEARCH_AND_CATALOG_ARCHITECTURE.md`
for authoritative system specifications.
