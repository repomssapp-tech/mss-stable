-- =========================================================
-- Supabase Seed Script
-- =========================================================
--
-- This file previously seeded public.schemes / public.document_types /
-- public.eligibility_rules / public.scheme_documents -- the legacy
-- pre-v2-architecture tables. Those tables were dropped by
-- 20260805000000_database_architecture_v2.sql in favor of the
-- catalog.* schema (see MSS_ANTIGRAVITY_HANDOFF/architecture_docs/), and
-- this seed script was never updated to match, which broke
-- `supabase db reset` / CI once that migration ran.
--
-- Catalog fixture data is populated separately via
-- scripts/generate_catalog_import_sql.js against the live catalog.*
-- schema; it is not part of the migration-time seed step.

BEGIN;
COMMIT;
