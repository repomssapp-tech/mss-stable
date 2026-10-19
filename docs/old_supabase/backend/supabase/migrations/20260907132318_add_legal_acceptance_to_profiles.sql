-- ===========================================================
-- Migration: add_legal_acceptance_to_profiles
-- Project  : MSS
-- Purpose  : Record per-account acceptance of legal documents
--            (Terms & Conditions, Privacy Policy, Privacy Notice,
--            Consent) with the document version accepted and when.
--            A version change in the app re-prompts the user.
-- ===========================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS terms_accepted_version TEXT,
  ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS privacy_policy_accepted_version TEXT,
  ADD COLUMN IF NOT EXISTS privacy_policy_accepted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS privacy_notice_accepted_version TEXT,
  ADD COLUMN IF NOT EXISTS privacy_notice_accepted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS consent_accepted_version TEXT,
  ADD COLUMN IF NOT EXISTS consent_accepted_at TIMESTAMPTZ;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
