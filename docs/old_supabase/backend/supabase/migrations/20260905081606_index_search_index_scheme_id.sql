-- 4.8 (audit_fix.md): catalog.search_index.scheme_id (971 rows -- the
-- search hot path) had no supporting index for its FK to catalog.scheme,
-- forcing a sequential scan on join and on parent delete. The other 28
-- unindexed FKs named in the audit are on zero-row scaffold tables
-- archived in 20260905080538 and are not indexed here. Plain (non-
-- concurrent) CREATE INDEX: apply_migration runs inside a transaction,
-- which CONCURRENTLY cannot; at 971 rows the brief lock is immaterial.
create index if not exists search_index_scheme_id_idx
  on catalog.search_index (scheme_id);
