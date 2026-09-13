-- ===========================================================
-- Migration: ensure_profiles_columns
-- Project  : MSS - MSME Schemes Search
-- Purpose  : Ensure all expected columns exist on public.profiles and reload PostgREST schema cache
-- ===========================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS dob DATE,
  ADD COLUMN IF NOT EXISTS gender VARCHAR(50),
  ADD COLUMN IF NOT EXISTS disability VARCHAR(100),
  ADD COLUMN IF NOT EXISTS veteran BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS house TEXT,
  ADD COLUMN IF NOT EXISTS street TEXT,
  ADD COLUMN IF NOT EXISTS area TEXT,
  ADD COLUMN IF NOT EXISTS village TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS qualification TEXT,
  ADD COLUMN IF NOT EXISTS annual_income NUMERIC(15,2) DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS community VARCHAR(100),
  ADD COLUMN IF NOT EXISTS notifications BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS theme VARCHAR(20) DEFAULT 'light',
  ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
  ADD COLUMN IF NOT EXISTS religion TEXT,
  ADD COLUMN IF NOT EXISTS first_gen_graduate BOOLEAN DEFAULT FALSE;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
