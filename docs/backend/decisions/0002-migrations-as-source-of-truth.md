# ADR 0002: Migrations are the source of truth for the database

- Status: Accepted
- Date: 2026-09-02
- Supersedes: none
- Related: ADR 0001 (engineering decision 2 — forward-only timestamped migrations)

## Context

Schema, grant, RLS-policy, and `security definer` function changes have been
applied to the live Supabase project by hand (Supabase CLI and the Studio SQL
editor). Several migration headers record fixes that were "marked applied in
`schema_migrations` but absent live"
(`20260818000000_restore_orphaned_rls_policies.sql`,
`20260901000000_lockdown_chat_logs_and_profiles_anon.sql`,
`20260901000200_reconcile_orphan_tables.sql`). A full-PII anon-readable policy
on `public.profiles` was live as recently as 2026-08-27. Dashboard SQL edits
bypass `supabase db reset` and the `backend-database.yml` CI job, so drift is
invisible until an audit or the weekly `rls-drift-check.yml` job finds it.

## Decision

1. The timestamped files in `backend/supabase/migrations/` are the authoritative
   definition and complete change history of the database. Anything not
   represented by a committed migration is not part of the schema.
2. Direct SQL against any hosted project (Studio SQL editor, `psql`, ad-hoc
   scripts) is not a source of truth. It is permitted only for read-only
   inspection and for documented emergency response; an emergency change must be
   captured as a migration in the same working day.
3. Every production database change — schema, grant, RLS policy, function,
   trigger, extension — ships as a forward-only migration through the normal
   review and CI path. No exceptions for "small" changes.
4. Before a deployment that depends on the database, the live project is
   reconciled against the migration set: run `supabase db reset` on a
   non-production project from migrations, `supabase db diff` it against the
   target, and fold any live-only drift back into a migration. The
   `rls-drift-check.yml` workflow (which fails closed when unconfigured) is the
   standing check for RLS/grant drift between reconciliations.
5. No speculative migration tooling. The existing Supabase CLI migration flow
   plus pgTAP tests are sufficient. A declarative-schema rewrite, custom diff
   engines, or a bespoke migration framework are explicitly out of scope unless
   a concrete, demonstrated need arises.

## Consequences

- Schema and RLS changes are reviewable in a PR and reproducible from a clean
  database. Staging (once it exists) can be rebuilt from migrations and trusted.
- The team gives up the convenience of quick Studio edits; every change carries
  migration-authoring overhead.
- This ADR does not itself fix existing undocumented live drift. That drift must
  be found (`select * from private.rls_coverage_violations();` against the live
  project, plus a `db diff`) and reconciled into migrations before the next
  deployment. Tracked as a live-verification task, not closed by this decision.
