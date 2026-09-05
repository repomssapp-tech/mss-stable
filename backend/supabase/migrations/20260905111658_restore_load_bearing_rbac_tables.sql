-- Corrects 20260905080538_archive_zero_row_scaffold_tables.sql: that
-- migration's re-verification grep covered app code (backend/supabase/functions,
-- frontend/lib, saarthi-agent/src, scripts) but never covered SQL function
-- bodies defined in earlier migrations. Four of the archived tables are
-- referenced by fully-qualified name (SET search_path = '') inside
-- SECURITY DEFINER functions private.has_role(), private.has_region(), and
-- private.belongs_to_organization() -- calling any of those now throws
-- "relation does not exist". Zero live rows anywhere means today's blast
-- radius is zero (this admin/multi-tenant surface has never been used),
-- but it is a landmine for whenever it is, and it already breaks the
-- pgTAP test suite. Un-archiving exactly these four; the other 12
-- archived tables (including beneficiary_categories, which appears only
-- as a string literal in a coverage-check list, never queried) are
-- confirmed safe and stay archived.

-- Guarded: on a fresh install, 20260905080538 (as fixed) never renamed these
-- four away in the first place, so there is nothing to undo here.
DO $$
BEGIN
  IF to_regclass('public._deprecated_organization_memberships') IS NOT NULL THEN
    ALTER TABLE public._deprecated_organization_memberships RENAME TO organization_memberships;
  END IF;
  IF to_regclass('public._deprecated_user_roles') IS NOT NULL THEN
    ALTER TABLE public._deprecated_user_roles RENAME TO user_roles;
  END IF;
  IF to_regclass('public._deprecated_regions') IS NOT NULL THEN
    ALTER TABLE public._deprecated_regions RENAME TO regions;
  END IF;
  IF to_regclass('public._deprecated_user_regions') IS NOT NULL THEN
    ALTER TABLE public._deprecated_user_regions RENAME TO user_regions;
  END IF;
END $$;
