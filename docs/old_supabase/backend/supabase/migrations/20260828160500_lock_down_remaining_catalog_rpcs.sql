-- ===========================================================
-- Migration: lock_down_remaining_catalog_rpcs
-- Project  : MSS - MSME Schemes Search
-- Purpose : Close the rest of the bulk-catalog scrape surface.
--
--           revoke_public_search_rpc_execute closed mss_search_data, but the
--           sibling catalog RPCs were left executable by PUBLIC/anon. The
--           publishable key ships inside the APK, so anyone holding it could
--           still pull whole catalogs straight from PostgREST, bypassing the
--           Edge Function and therefore bypassing the rate limiter entirely:
--
--             mss_lookup_catalog('finance')              484 kB / call
--             mss_lookup_catalog('applicability_matrix') 424 kB / call
--             mss_lookup_catalog('tax')                   38 kB / call
--             mss_scheme_detail / mss_entity_record /
--             mss_relationships / mss_finance_by_scheme  bounded, enumerable
--
--           At 484 kB a call, ~10k unauthenticated calls drains the 5 GB
--           monthly egress allowance. Rate limiting the Edge Function is
--           pointless while this door stays open.
--
--           Every one of these RPCs is called only by the v1 Edge Function
--           using the service role. The Flutter client calls exactly two RPCs
--           directly -- mss_current_release (catalog sync) and delete_user --
--           so restricting the rest breaks nothing on the client.
-- ===========================================================

-- SECURITY DEFINER functions receive EXECUTE from PUBLIC by default, so PUBLIC
-- must be revoked explicitly; revoking anon/authenticated alone leaves the
-- privilege inherited through PUBLIC.
do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in (
         'mss_lookup_catalog',
         'mss_scheme_detail',
         'mss_entity_record',
         'mss_relationships',
         'mss_finance_by_scheme',
         'mss_catalog_meta'
       )
  loop
    execute format('revoke all on function %s from public, anon, authenticated', fn.signature);
    execute format('grant execute on function %s to service_role', fn.signature);
  end loop;
end;
$$;

-- Deliberately NOT restricted: public.mss_current_release() is called directly
-- by the Flutter client (services/scheme_catalog_sync_service.dart) to decide
-- whether a new catalog bundle needs downloading. It returns one small row
-- (version + sha256 + byte size), so it is not a bulk-extraction vector.
