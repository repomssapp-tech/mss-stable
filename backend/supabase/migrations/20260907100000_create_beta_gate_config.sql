-- ===========================================================
-- Migration: create_beta_gate_config
-- Project  : MSS - MSME Schemes Search
-- Purpose  : Beta Tester Password Gate table storing plain-text
--            password to gate app access before user login.
--            Includes Primary Key and single-row check constraint
--            so rows can be easily edited directly in Supabase Table Editor.
-- ===========================================================

BEGIN;

-- 1. Create table for beta gate configuration with primary key
CREATE TABLE IF NOT EXISTS public.beta_gate_config (
    id integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    beta_password TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- If table was already created without the 'id' column, add it safely
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'beta_gate_config' 
          AND column_name = 'id'
    ) THEN
        ALTER TABLE public.beta_gate_config ADD COLUMN id integer PRIMARY KEY DEFAULT 1;
    END IF;
END $$;

-- Enforce single row constraint (id must be 1)
ALTER TABLE public.beta_gate_config DROP CONSTRAINT IF EXISTS beta_gate_config_single_row;
ALTER TABLE public.beta_gate_config ADD CONSTRAINT beta_gate_config_single_row CHECK (id = 1);

COMMENT ON TABLE public.beta_gate_config IS
    'Stores configuration and plain-text password for beta tester access gate. Editable in Table Editor.';

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
INSERT INTO public.beta_gate_config (id, beta_password)
VALUES (1, '300708')
ON CONFLICT (id) DO NOTHING;

COMMIT;
