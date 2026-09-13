-- ===========================================================
-- Migration: harden_exposed_functions
-- Project  : MSS - MSME Schemes Search (MSS APP)
-- Purpose : Clear the remaining Supabase security-advisor findings that
--           relate to the exposed PostgREST surface.
--
--           Companion to the Edge Function change flipping `v1` to
--           verify_jwt = true. Together these mean: no route into this
--           project answers an unauthenticated caller.
--
--           Every function touched below (except public.delete_user) was
--           created OUT OF BAND on the hosted project and is defined by no
--           migration -- rls_auto_enable, catalog.mss_search,
--           catalog.mss_localized_text, catalog.mss_search_document. So each
--           statement is guarded on the object actually existing; on a fresh
--           `supabase db reset` it simply logs and skips. Reconciling those
--           definitions into migrations is tracked with chat_logs /
--           auth_user_id.
-- ===========================================================

-- 1. public.rls_auto_enable() -----------------------------------------
-- EVENT TRIGGER function: calls pg_event_trigger_ddl_commands() (raises
-- unless invoked by the event trigger manager) and only ever ENABLES row
-- level security. A direct RPC call is harmless, but it has no business
-- being reachable at /rest/v1/rpc/rls_auto_enable by an anonymous caller.
-- Revoke outright; the event trigger keeps firing because triggers run as
-- the trigger owner, not via EXECUTE privilege.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke all on function public.rls_auto_enable() from public, anon, authenticated';
  else
    raise notice 'public.rls_auto_enable() absent -- skipping (out-of-band object)';
  end if;
end $$;

-- 2. public.delete_user() ---------------------------------------------
-- Guarded internally (raises unless auth.uid() is present), so anon calls
-- already fail closed. Still, account deletion should not be an anonymous
-- entry point at all -- signed-in users only, which is the sole caller
-- (providers/app_state_provider.dart -> rpc('delete_user')).
revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;

-- 3. Pin search_path on the remaining flagged functions ----------------
-- All are SECURITY INVOKER, so a mutable search_path is not a
-- privilege-escalation route here -- they run with the caller's rights.
-- Pinning it is still correct hygiene and clears the advisor warning.
-- Bodies are untouched; the resolution order below is the one they already
-- relied on implicitly.
do $$
begin
  if to_regprocedure('public.safe_cast_to_numeric(text)') is not null then
    execute 'alter function public.safe_cast_to_numeric(text) set search_path = public, extensions';
  end if;

  if to_regprocedure('catalog.mss_localized_text(jsonb, text)') is not null then
    execute 'alter function catalog.mss_localized_text(jsonb, text) set search_path = catalog, public, extensions';
  else
    raise notice 'catalog.mss_localized_text(jsonb, text) absent -- skipping (out-of-band object)';
  end if;

  if to_regprocedure('catalog.mss_search_document(jsonb)') is not null then
    execute 'alter function catalog.mss_search_document(jsonb) set search_path = catalog, public, extensions';
  else
    raise notice 'catalog.mss_search_document(jsonb) absent -- skipping (out-of-band object)';
  end if;

  if to_regprocedure('catalog.mss_search(text, text, text[], integer, integer)') is not null then
    execute 'alter function catalog.mss_search(text, text, text[], integer, integer) set search_path = catalog, public, extensions';
  else
    raise notice 'catalog.mss_search(text, text, text[], integer, integer) absent -- skipping (out-of-band object)';
  end if;
end $$;
