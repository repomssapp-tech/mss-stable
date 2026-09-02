# MSS App — Deployment Architecture Plan

**Status:** Planning / design only. No infrastructure, CI, or config changes have been made from this document. Nothing here is authorized to be implemented until reviewed component-by-component with the user, per the project's standing rule that Supabase/CI changes require explicit per-step authorization.

**Date:** 2026-08-17 (supersedes no prior deployment-architecture doc — this is the first one).

---

## 1. What currently exists (verified, not assumed)

| Component | Current deployment reality |
|---|---|
| Supabase project | **One project, no staging.** `backend/supabase/config.toml` defines a single local dev config; all V2-Bn migrations were applied by hand (CLI) directly against what is effectively the production project. There is no second Supabase project for pre-prod testing. |
| Supabase Edge Functions (`v1`) | Deployed manually via `supabase functions deploy` during prior sessions. No CD pipeline deploys them automatically on merge. |
| Supabase Storage (`catalogs` bucket) | Exists, holds one published release (`releases/1.33.0-alpha/`). Publishing was done manually (`supabase storage cp`), not via a script or pipeline. |
| CI: `.github/workflows/backend-database.yml` | **Validation only, on PR/push to `main`/`codex/**`.** Spins up local Supabase, runs `db:reset`, `db:test` (pgTAP), `db:lint`, `openapi:lint`, and the Python `voice` unit tests. It does **not** deploy anything — no `supabase db push`, no `functions deploy`, no Storage publish step. |
| Flutter app (`frontend/`) | No CI workflow at all. No build/signing pipeline, no Play Store / App Store track. Presumed to be run locally / via emulator only so far. |
| Catalog release pipeline | `tools/generate_catalog_bundle.py` produces `release.json` + per-file SHA-256 + the gzipped bundle, shipped as a Flutter asset. Publishing a new release to Supabase Storage + `admin.catalog_releases`/`catalog_files` is currently a **manual** multi-step process (confirmed from the V2-B2/B6 session work). |
| `saarthi-agent/` (LiveKit voice service) | Has its own `Dockerfile` (multi-stage, non-root user, UV-based) and `livekit.toml` pointing at a real **LiveKit Cloud** project (`subdomain = "mss-kqp2428o"`, `agent.id = "CA_a4N8HNfzMHUt"`) — this is LiveKit Cloud's own hosted agent-deploy mechanism (`lk agent deploy`), not a generic container host. It has its own CI (`ruff.yml`, `tests.yml`, `tag-version.yml`, `template-check.yml`) but **no deploy-on-merge workflow** — deployment to LiveKit Cloud appears to be a manual `lk agent deploy` today. |
| Secrets | `saarthi-agent/.env.example` lists `LIVEKIT_URL/API_KEY/API_SECRET`, `SARVAM_API_KEY` — real values live only in local `.env` / LiveKit Cloud's own secret store (not found in the repo, which is correct). No GitHub Actions secrets were found wired to any deploy step, because no deploy step exists yet. |

**Net picture:** this is currently a set of independently, manually deployed pieces (one live Supabase project, one live LiveKit Cloud agent, a Flutter app that isn't shipped anywhere yet) that happen to work together, not a designed deployment architecture. The rest of this doc proposes one, without changing anything yet.

---

## 2. Proposed architecture (target state)

```
                        ┌─────────────────────────────┐
                        │   GitHub (single repo,       │
                        │   MSS_App)                   │
                        └──────────────┬───────────────┘
                                        │ push / PR
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
        backend/supabase/**    frontend/**             saarthi-agent/**
                 │                      │                      │
                 ▼                      ▼                      ▼
        ┌────────────────┐    ┌─────────────────┐    ┌──────────────────┐
        │ CI: db:test,    │    │ CI: flutter      │    │ CI: ruff, pytest  │
        │ db:lint,        │    │ analyze, test,   │    │ (already exists)  │
        │ openapi:lint    │    │ build (new)      │    │                    │
        │ (already exists)│    └────────┬─────────┘    └─────────┬──────────┘
        └────────┬────────┘             │                        │
                  │ on merge to main     │ on tag/release         │ on merge to main
                  ▼                      ▼                        ▼
        ┌────────────────────┐  ┌──────────────────┐   ┌───────────────────────┐
        │ CD: supabase db    │  │ CD: fastlane/     │   │ CD: docker build →     │
        │ push + functions   │  │ codemagic → Play  │   │ lk agent deploy         │
        │ deploy (new)       │  │ Store track (new) │   │ (new)                   │
        └──────────┬──────────┘  └──────────────────┘   └───────────┬─────────────┘
                   │                                                 │
                   ▼                                                 ▼
        ┌─────────────────────────────┐                  ┌─────────────────────┐
        │ Supabase project             │                  │ LiveKit Cloud        │
        │  - Postgres (catalog/admin/  │◄─────────────────┤  agent worker         │
        │    public schemas)           │  reads catalog/   │  (mss-kqp2428o)      │
        │  - Edge Functions (v1 API)   │  scheme data via  └──────────────────────┘
        │  - Storage (catalogs bucket, │  v1 API
        │    releases/<version>/)      │
        └───────────┬───────────────────┘
                    │ mss_current_release() RPC + Storage download
                    ▼
        ┌─────────────────────────────┐
        │ Flutter app (device)         │
        │  - ships baseline bundle     │
        │  - hot-swaps to newer        │
        │    verified release via      │
        │    SchemeCatalogSyncService  │
        └─────────────────────────────┘
```

Three independently deployable components, one shared release artifact (the catalog), one shared data contract (`/v1/*` API + `mss_current_release()`).

---

## 3. Component-by-component plan

### 3.1 Supabase backend (highest priority — everything else depends on it)

**Environments.** Introduce a second Supabase project for staging before any CD writes to prod automatically. This is the single biggest gap today: migrations currently land directly on the project the live app/agent both depend on, with no rehearsal environment. Decision point for the user — options, cheapest to most rigorous:
1. Keep one project, gate deploys on the existing CI validation job passing (current de facto state, formalized).
2. Add a `staging` Supabase project; CD deploys to staging on every merge to `main`, promotion to prod is a manual, explicit step (`workflow_dispatch` or a tag).
3. Full environment parity (dev/staging/prod), each with its own catalog release cycle.

Recommendation: **option 2** — matches the project's existing "gated, validated, reversible" pattern (per your standing roadmap rules) without the overhead of a third environment for a project this size.

**CD pipeline (new).** Extend `.github/workflows/backend-database.yml` (or a new `backend-deploy.yml`) with a job that runs only on push to `main` after the existing validation job passes:
- `supabase link --project-ref <staging-or-prod-ref>`
- `supabase db push` (migrations are already written as immutable, ordered files — safe to push in order)
- `supabase functions deploy v1`
- A separate, explicitly manual (`workflow_dispatch`, not automatic) job for catalog release publishing — this should stay a deliberate act, not something that fires on every merge, since it changes what every installed app fetches.

**Secrets needed in GitHub Actions:** `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` (staging/prod), `SUPABASE_DB_PASSWORD`. None of these exist in the repo today (correct) — they'd need to be added to the GitHub repo's Actions secrets, which is an infrastructure change requiring your explicit go-ahead.

**Backup & disaster recovery — use Supabase-native.** No external backup tooling. Enable Supabase's built-in **daily automated backups**, and enable the **Point-in-Time Recovery (PITR)** add-on once the project is on a plan tier that supports it (PITR requires Pro or above — confirm current plan before assuming it's available). RPO/RTO target: not yet set by the user — default to "whatever Supabase's PITR window provides" unless a tighter target is specified later. Restore testing (actually running a restore in staging to confirm backups are usable) should be a checklist item in D2, not assumed to work untested.

**Observability — use Supabase-native.** No separate tool (e.g. Sentry) for now. Use Supabase's built-in **Logs** (Postgres logs, Edge Function invocation logs, API logs) and the project's built-in **usage/error alerting** (e.g. alerts on Edge Function error rate, database CPU/connection thresholds) from the Supabase dashboard. Revisit if 500-user scale later shows this isn't enough signal.

**Region.** Target Tamil Nadu users now, all-India later. Supabase has no Tamil Nadu/Chennai region; closest available is **`ap-south-1` (Mumbai, AWS)** — use that for the single project now. When expanding pan-India, the realistic lever (once on a plan that supports it) is a **read replica** in a second region for read-heavy `/v1/*` traffic, not a project migration — writes stay in `ap-south-1`. Not needed until usage data justifies it.

**Capacity — sized for 500 users.** At this scale, Supabase's default connection pooler (Supavisor, transaction mode) and default Edge Function concurrency are sufficient — no dedicated pooler tuning, no reserved compute add-on needed yet. Re-evaluate only if actual usage approaches limits; don't pre-provision for a scale that isn't happening yet.

**Access control on deploys.** Production deploy access is restricted to the **production team (RIT)** only. Implement via GitHub's **Environments** feature: a `production` environment with required reviewers set to the RIT team, gating the prod-deploy job in the CD workflow (§5, D5) — staging deploys can run without that gate since staging is non-production.

**Staging data policy.** Staging is for testing only, not a production-facing environment — it must **not** contain real user data (especially not `public.profiles`' gender/community/disability/veteran fields, already flagged as a privacy gap in prior sessions). Seed staging from `backend/generate_seed_data.py` (synthetic data) or the catalog data alone, never a copy/export of prod rows.

**Deferred, not covered now (per user):** RLS/security hardening audit (item 3), API versioning/evolution strategy for `/v1/*` (item 8). Both remain open for a later pass.

### 3.2 Catalog release pipeline

Formalize the currently-manual publish sequence (`generate_catalog_bundle.py` → Storage upload → `admin.catalog_releases`/`catalog_files` insert) into a single script, e.g. `backend/scripts/publish_catalog_release.js`, that:
1. Runs the existing bundle generator.
2. Uploads all artifacts to `releases/<version>/` in the `catalogs` bucket.
3. Inserts/updates the `admin.catalog_releases` + `catalog_files` rows.
4. Verifies byte-identical SHA-256 post-upload (the check already done manually in the V2-B6 session).

Triggered manually (`workflow_dispatch` with a version input), never automatically — catalog content changes are editorial/data decisions, not code deploys. Rollback is already designed correctly: `SchemeCatalogStore` never deletes the previous release directory, so a bad release can be rolled back by re-pointing `admin.catalog_releases.current` without an app update.

### 3.3 Flutter app release

Currently has no CI or release pipeline at all. Proposed, in order of what unblocks what:
1. **CI first** (safe, no store impact): `flutter analyze` + `flutter test` on every PR touching `frontend/**`, mirroring the pattern already used for `backend/` and `saarthi-agent/`.
2. **Build pipeline**: Android App Bundle signing via a GitHub Actions workflow (keystore as a base64 secret) or a managed service (Codemagic/fastlane) if you'd rather not hand-roll signing in Actions.
3. **Release channel strategy**: Play Store internal testing → closed testing → production, gated manually at each promotion (not auto-promoted). App version should carry the `catalogVersion`/`releaseVersion` it was built against for support/debugging, since the app and catalog now version independently (per the offline/cloud sync architecture already documented in `MSS_ANTIGRAVITY_HANDOFF/architecture_docs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`).

No UI/UX work is implied by any of this — it's packaging and CI only.

### 3.4 saarthi-agent (LiveKit voice service)

Already the most "deployment-ready" piece — it has a production-grade Dockerfile and is registered with LiveKit Cloud. Gap is just automation:
- Add a `deploy.yml` workflow, triggered on merge to `main` for `saarthi-agent/**` changes (mirroring the existing `ruff.yml`/`tests.yml` triggers), that runs `lk agent deploy` (or the Docker build + LiveKit Cloud's deploy API, whichever `lk` uses under the hood) after `ruff` + `pytest` pass.
- Confirm whether `mss-kqp2428o` is meant to be the permanent prod LiveKit Cloud project or a temporary/dev one — same staging-vs-prod question as §3.1, worth deciding once rather than per-component.
- `SARVAM_API_KEY`, `LIVEKIT_API_KEY/SECRET` need to move from local `.env` into GitHub Actions secrets (or stay in LiveKit Cloud's own secret manager if `lk agent deploy` reads from there — needs checking against LiveKit Cloud's actual deploy docs before implementing).

---

## 4. Decision points

**Resolved by user (2026-08-17):**
1. Backup/DR — Supabase-native (daily backups + PITR). See §3.1.
2. Observability — Supabase-native (Logs + built-in alerting), no external tool for now. See §3.1.
3. Security/RLS hardening audit — deferred, not needed now.
4. Region — `ap-south-1` (Tamil Nadu-nearest available), pan-India expansion later via read replica. See §3.1.
5. Capacity — plan for 500 users, no special pooler/scaling config yet. See §3.1.
6. Access control — production deploys restricted to the production team (RIT), enforced via GitHub Environments. See §3.1.
7. Staging Supabase project — **yes**, but strictly for testing (not a production feature); must use synthetic/seed data, never real user data. See §3.1.
8. API versioning strategy for `/v1/*` — deferred, can leave for now.

**Still open:**
- Is `mss-kqp2428o` (LiveKit Cloud) the permanent production project?
- Flutter release channel: Play Store only, or also iOS/App Store?
- Automation aggressiveness for backend CD: auto-deploy to staging on merge is implied by decision #7 now being "yes" — but prod promotion should still be manual given decision #6 (RIT-gated), consistent with the standing "validation + report + rollback" rule.

## 5. Suggested phased execution (once decisions above are made)

1. **D1** — Flutter CI (analyze + test on PR). Zero risk, no infra changes, closes the biggest CI gap.
2. **D2** — Backend CD to staging (requires decision #1). Formalizes what's already being done by hand.
3. **D3** — saarthi-agent CD to LiveKit Cloud (requires decision #2).
4. **D4** — Catalog release script (formalizes the manual publish sequence; still manually triggered).
5. **D5** — Backend CD promotion-to-prod workflow (requires decision #4).
6. **D6** — Flutter build/signing + first Play Store internal-track release (requires decision #3).

Each phase should get its own validation + rollback note before merging, consistent with how the B-phase backend roadmap has been run so far.
