-- ===========================================================
-- Migration: catalog_row_checksum_trigger
-- Project : IN Schemes (MSS App)
-- Purpose : `catalog.*` row `checksum` (see HASH_VERIFICATION_SPECIFICATION.md
--           §2) was only ever set by the Node import pipeline
--           (backend/scripts/generate_catalog_import_sql.js's
--           sha256(JSON.stringify(record))) -- there is no DB-side
--           mechanism keeping it in sync with `record_json`. A direct edit
--           via the Supabase Table Editor (or any future ad-hoc update)
--           changes `record_json` but silently leaves `checksum` stale,
--           which corrupts public.mss_catalog_meta()'s drift-detection
--           aggregate for every row in that table, not just the edited one.
--
--           Fix: a BEFORE INSERT OR UPDATE trigger recomputes `checksum`
--           from the row's own `record_json` on every write, on all 16
--           catalog tables that carry both columns (matches the table list
--           generate_catalog_import_sql.js populates). This intentionally
--           uses a different, Postgres-native formula
--           (sha256(record_json::text)) than the Node pipeline's
--           sha256(JSON.stringify(...)) -- jsonb's on-disk key ordering
--           doesn't reproduce JS's insertion-order JSON.stringify byte-for-
--           byte, so bit-identical reproduction of the original import-time
--           hash isn't achievable from inside Postgres. That's fine per
--           HASH_VERIFICATION_SPECIFICATION.md §2: this checksum is
--           "table-layer drift detection only", self-consistency over time
--           is what matters, not equality with packageSha256/bundleSha256
--           or any specific historical value. A full backfill below
--           re-baselines every row to the new formula in one pass so the
--           whole table is internally consistent again.
--
--           catalog.entity_registry also has a `checksum` column but no
--           `record_json` (never populated by the import pipeline, appears
--           unused) -- excluded, nothing to compute it from.
-- ===========================================================

begin;

create or replace function catalog.mss_recompute_row_checksum()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.checksum := encode(extensions.digest(new.record_json::text, 'sha256'), 'hex');
  return new;
end;
$$;

comment on function catalog.mss_recompute_row_checksum() is
  'Keeps catalog.*.checksum in sync with record_json on every write (table-editor edits included). See public.mss_catalog_meta() and HASH_VERIFICATION_SPECIFICATION.md §2.';

do $$
declare
  t text;
  tables text[] := array[
    'common', 'authority', 'institution', 'scheme', 'finance', 'tax',
    'export', 'csr', 'treds', 'knowledge', 'applicability_matrix',
    'enterprise_classification', 'msme_privilege', 'business_enablement',
    'cluster_assistance', 'search_index'
  ];
begin
  foreach t in array tables loop
    execute format(
      'drop trigger if exists trg_recompute_checksum on catalog.%I', t
    );
    execute format(
      'create trigger trg_recompute_checksum
         before insert or update on catalog.%I
         for each row execute function catalog.mss_recompute_row_checksum()',
      t
    );
    -- Backfill: re-baseline every existing row to the new formula so the
    -- whole table is internally consistent immediately, not just future
    -- writes. Direct UPDATE (not relying on the trigger firing on a no-op
    -- touch) so the intent is explicit and unaffected by any planner
    -- decision to skip a no-op assignment.
    execute format(
      'update catalog.%I set checksum = encode(extensions.digest(record_json::text, ''sha256''), ''hex'')',
      t
    );
  end loop;
end $$;

commit;

-- ===========================================================
-- Rollback (manual):
--   do $$
--   declare t text;
--   begin
--     foreach t in array array['common','authority','institution','scheme',
--       'finance','tax','export','csr','treds','knowledge',
--       'applicability_matrix','enterprise_classification','msme_privilege',
--       'business_enablement','cluster_assistance','search_index'] loop
--       execute format('drop trigger if exists trg_recompute_checksum on catalog.%I', t);
--     end loop;
--   end $$;
--   drop function if exists catalog.mss_recompute_row_checksum();
--   -- (checksum backfill is not reversible -- original import-time values
--   -- are not recoverable from the DB; re-import from source if truly needed)
-- ===========================================================
