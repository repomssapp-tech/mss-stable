-- 3.6 (audit_fix.md): catalog.mss_search, catalog.mss_localized_text,
-- catalog.mss_search_document, and catalog.mss_recompute_row_checksum
-- still carried the implicit default PUBLIC EXECUTE grant every Postgres
-- function gets at creation unless explicitly revoked. They are already
-- unreachable via PostgREST (catalog schema is not exposed), so this is
-- defence-in-depth, not a live-vulnerability fix: a future schema-exposure
-- change would otherwise make them directly callable with no additional
-- review. mss_recompute_row_checksum is a trigger function (invoked by
-- the table owner at trigger time, not by a caller's EXECUTE privilege)
-- and should never have carried a caller-facing grant at all. Verified
-- no other migration or Edge Function calls any of these directly.

-- catalog.mss_search, catalog.mss_localized_text and catalog.mss_search_document
-- are out-of-band objects (never created by any tracked migration -- see
-- 20260829160000_harden_exposed_functions.sql's identical guard for the same
-- three functions). They exist in production today but not on a from-scratch
-- migration replay (local dev, CI db:reset), so each statement is guarded.
do $$
begin
  if to_regprocedure('catalog.mss_search(text, text, text[], integer, integer)') is not null then
    execute 'revoke execute on function catalog.mss_search(text, text, text[], integer, integer) from public, anon, authenticated';
    execute 'grant execute on function catalog.mss_search(text, text, text[], integer, integer) to service_role';
  else
    raise notice 'catalog.mss_search(text, text, text[], integer, integer) absent -- skipping (out-of-band object)';
  end if;

  if to_regprocedure('catalog.mss_localized_text(jsonb, text)') is not null then
    execute 'revoke execute on function catalog.mss_localized_text(jsonb, text) from public, anon, authenticated';
    execute 'grant execute on function catalog.mss_localized_text(jsonb, text) to service_role';
  else
    raise notice 'catalog.mss_localized_text(jsonb, text) absent -- skipping (out-of-band object)';
  end if;

  if to_regprocedure('catalog.mss_search_document(jsonb)') is not null then
    execute 'revoke execute on function catalog.mss_search_document(jsonb) from public, anon, authenticated';
    execute 'grant execute on function catalog.mss_search_document(jsonb) to service_role';
  else
    raise notice 'catalog.mss_search_document(jsonb) absent -- skipping (out-of-band object)';
  end if;
end $$;

-- mss_recompute_row_checksum() is created by 20260904000000_catalog_row_checksum_trigger.sql,
-- so it is always present on a tracked replay -- no guard needed.
revoke execute on function catalog.mss_recompute_row_checksum() from public, anon, authenticated;
