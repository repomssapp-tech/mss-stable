-- ============================================================================
-- Migration: 20261005020000_revoke_create_scheme_draft_and_harden.sql
-- Description: Phase F Security Hardening (Decision D7)
--              1. Revoke EXECUTE on public.create_scheme_draft from anon, authenticated, public
--              2. Grant EXECUTE on public.create_scheme_draft exclusively to service_role
--              3. Set fixed search_path = public, pg_temp on public.create_scheme_draft
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT p.oid::regprocedure AS func_sig
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'create_scheme_draft'
    LOOP
        -- 1. Revoke public/anon/authenticated execution
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', r.func_sig);
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', r.func_sig);
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', r.func_sig);

        -- 2. Restrict to internal/service role only
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', r.func_sig);

        -- 3. Set secure, immutable search_path to prevent search_path hijacking
        EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', r.func_sig);
    END LOOP;
END $$;
