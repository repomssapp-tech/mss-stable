-- ===========================================================
-- Migration: create_beta_gate_config
-- Project  : IN Schemes (MSS App)
-- Purpose  : Beta Tester Password Gate table storing plain-text
--            password to gate app access before user login.
-- ===========================================================

BEGIN;

-- 1. Create table for beta gate configuration
CREATE TABLE IF NOT EXISTS public.beta_gate_config (
    beta_password TEXT NOT NULL
);

COMMENT ON TABLE public.beta_gate_config IS
    'Stores configuration and plain-text password for beta tester access gate.';

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.beta_gate_config ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policy: Allow anon and authenticated users to read the password
DROP POLICY IF EXISTS "allow_read_beta_password" ON public.beta_gate_config;
CREATE POLICY "allow_read_beta_password"
ON public.beta_gate_config
FOR SELECT
TO anon, authenticated
USING (true);

-- 4. Grant SELECT permission to anon and authenticated Postgres roles
GRANT SELECT ON public.beta_gate_config TO anon, authenticated;

-- 5. Insert single default row with password '300708' if table is empty
INSERT INTO public.beta_gate_config (beta_password)
SELECT '300708'
WHERE NOT EXISTS (
    SELECT 1 FROM public.beta_gate_config
);

COMMIT;
