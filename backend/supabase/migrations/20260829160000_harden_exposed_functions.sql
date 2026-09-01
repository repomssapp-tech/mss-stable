-- ===========================================================
-- Migration: harden_exposed_functions
-- Project : IN Schemes (MSS APP)
-- Purpose : Clear the remaining Supabase security-advisor findings that
--           relate to the exposed PostgREST surface.
--
--           Companion to the Edge Function change flipping `v1` to
--           verify_jwt = true. Together these mean: no route into this
--           project answers an unauthenticated caller.
-- ===========================================================

-- 1. public.rls_auto_enable() -----------------------------------------
-- This is an EVENT TRIGGER function: it calls pg_event_trigger_ddl_commands(),
-- which raises unless invoked by the event trigger manager, and it only ever
-- ENABLES row level security (never disables). So a direct RPC call is
-- harmless today -- but it has no business being reachable at
-- /rest/v1/rpc/rls_auto_enable by an anonymous caller. Revoke outright; the
-- event trigger continues to fire because triggers run as the trigger owner,
-- not via EXECUTE privilege.
revoke all on function public.rls_auto_enable() from public, anon, authenticated;

-- 2. public.delete_user() ---------------------------------------------
-- Guarded internally (raises unless auth.uid() is present), so anon calls
-- already fail closed. Still, account deletion should not be an anonymous
-- entry point at all -- signed-in users only, which is the sole caller
-- (providers/app_state_provider.dart -> rpc('delete_user')).
revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;

-- 3. Pin search_path on the remaining flagged functions ----------------
-- All four are SECURITY INVOKER, so a mutable search_path is not a
-- privilege-escalation route here -- they run with the caller's rights.
-- Pinning it is still correct hygiene and clears the advisor warning.
-- This is a config-only change: function bodies are untouched, and the
-- resolution order below is the one they already relied on implicitly.
alter function public.safe_cast_to_numeric(text)
  set search_path = public, extensions;

alter function catalog.mss_localized_text(jsonb, text)
  set search_path = catalog, public, extensions;

alter function catalog.mss_search_document(jsonb)
  set search_path = catalog, public, extensions;

alter function catalog.mss_search(text, text, text[], integer, integer)
  set search_path = catalog, public, extensions;
