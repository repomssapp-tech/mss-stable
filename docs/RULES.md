# Rules — MSS App Contributor Rulebook

This is the single entry point for "what rules apply here." It does not restate content that already lives elsewhere and would drift out of sync — it points to the authoritative doc for each concern, and adds the few rules that don't exist anywhere yet.

**Authority order** when docs disagree: the code itself → the relevant domain spec below → `AGENTS.md` → everything else (loose root `.md` files, comments, older docs). `docs/audit/AUDIT.md` records the currently-known gaps between docs and code; check it before trusting a claim in an older doc.

## Where each concern is governed

| Concern | Authoritative doc |
|---|---|
| Build, lint, and test commands (Flutter/backend/agent) | `AGENTS.md` |
| Coding standards & architecture invariants (offline-first, design tokens, i18n, decomposition, RLS) | `AGENTS.md` |
| Search/discovery/recommendation architecture, catalog sync, API routing | `docs/OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md` |
| UI/UX design system, typography, spacing tokens | `docs/UI_UX_DESIGN_SYSTEM.md` |
| Database schema, migrations, RLS, ADRs | `docs/backend/BACKEND_SPECIFICATION.md` |
| Catalog data contract, release manifest, sync state machine | `docs/specs/CATALOG_SPECIFICATIONS.md` |
| Deployment topology & CI | `docs/DEPLOYMENT_ARCHITECTURE.md` |
| Production catalog publish / key-rotation runbooks | `docs/runbooks/OPERATIONS_RUNBOOK.md` |
| Current known-good vs known-broken state | `docs/audit/AUDIT.md` (live) / `docs/audit/CODEBASE_AUDIT.md` (deep historical baseline) |
| Repo orientation for a new dev or AI assistant | `docs/SKILLS.md` |
| Who changed what, and when | `docs/audit/DEV_LOG.md` |

## Rules not written down anywhere else

### 1. File-size ceiling applies to the coordinator too
"Keep files small, under ~500 lines" (`AGENTS.md` §Monolithic Decomposition) means the ceiling applies **after** decomposition, not just before it. Extracting a few sub-widgets into a subdirectory while the parent coordinator stays at 1000+ lines does not satisfy the rule — the coordinator itself must shrink to roughly that ceiling, retaining only wiring/lifecycle logic and delegating rendering/state to the sub-modules. `docs/audit/AUDIT.md` lists the files currently over this ceiling; new PRs must not add to that list.

### 2. API routing pattern
- New backend HTTP routes go into the existing `v1` single-router (`backend/supabase/functions/v1/index.ts`) unless the route needs a genuinely distinct auth model or runtime boundary — that's why `sarvam-chat`, `livekit-token`, `publishCatalog`, `rollbackRelease`, and `db-change-notify` are separate Edge Functions instead of `v1` routes. Don't create a new top-level function for something that's just another authenticated catalog/search lookup.
- `backend/openapi/openapi.yaml` must be updated in the same PR that adds, removes, or changes a `/v1/*` route. If a documented route is aspirational (not yet implemented), it must say so explicitly in the spec rather than being presented as live — the current file was found to document a fictional admin/sync API with zero overlap with the real routes (see `docs/audit/AUDIT.md`).
- Comments referencing specific caller files (e.g. a service class name) must be checked for staleness when that file is deleted or renamed — `backend/supabase/config.toml` was found referencing a Flutter service class that no longer exists.

### 3. Decomposition doesn't leave orphans
When splitting a file, delete or fully repurpose the original monolith — never leave both the old and new versions in the tree. Verify every new sub-module is actually imported and delegated to by the coordinator, not just created alongside it.

### 4. Every merged PR gets a `docs/audit/DEV_LOG.md` entry
See `docs/audit/DEV_LOG.md` and `.github/workflows/dev-log.yml` — this is automatic on merge to `main`, keyed by GitHub username, so no manual step is required. Fill in the PR template's "Area" and "Summary" fields so the auto-logged entry is meaningful, not just a PR number.

### 5. Decided: stop decomposing state-coupled coordinators — keep them as one file
Three files (`app_state_provider.dart`, `saarthi_home_screen.dart`, `voice_assistant_overlay.dart`) were decomposed as far as safely possible; what's left reads/writes many private `State`/class fields across the same methods, so splitting further would require either `part`/`part of` files (unused elsewhere in this repo) or extracting the coupled logic into an injected/callback-driven controller — a real architecture change, not a file move, with real risk of breaking behavior.

**Decision (2026-09-13): don't do either.** These three stay as single files above the ~500-line ceiling. This is a deliberate, accepted exception — not a violation to "fix" in a future pass. Do not introduce `part` files or a controller-injection rewrite on these files without a fresh, explicit decision to revisit this. New code added to these files should still avoid growing them further where avoidable, but correctness and stability take priority over the line-count rule here.

### 6. Audit refresh, not audit rewrite
When re-verifying the codebase, update `docs/audit/AUDIT.md` in place (mark items Verified/Needs work, add new findings) rather than replacing it wholesale. `docs/audit/CODEBASE_AUDIT.md` stays frozen as the original deep-dive baseline for historical comparison.
