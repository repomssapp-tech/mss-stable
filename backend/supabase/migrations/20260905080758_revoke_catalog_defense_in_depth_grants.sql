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

revoke execute on function catalog.mss_search(text, text, text[], integer, integer) from public, anon, authenticated;
revoke execute on function catalog.mss_localized_text(jsonb, text) from public, anon, authenticated;
revoke execute on function catalog.mss_search_document(jsonb) from public, anon, authenticated;
revoke execute on function catalog.mss_recompute_row_checksum() from public, anon, authenticated;

grant execute on function catalog.mss_search(text, text, text[], integer, integer) to service_role;
grant execute on function catalog.mss_localized_text(jsonb, text) to service_role;
grant execute on function catalog.mss_search_document(jsonb) to service_role;
