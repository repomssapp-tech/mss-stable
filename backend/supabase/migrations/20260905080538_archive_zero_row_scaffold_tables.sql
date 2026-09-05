-- MSS_App table archival -- Phase 3 cleanup (audit_fix.md)
-- All targets verified at 0 rows and 0 code references at execution time.
-- Rename is reversible: ALTER TABLE public._deprecated_x RENAME TO x;
--
-- CORRECTION (see 20260905111658_restore_load_bearing_rbac_tables.sql):
-- organization_memberships, user_roles, regions and user_regions were
-- archived here based on a grep sweep that covered app code but not SQL
-- function bodies defined in earlier migrations. They are referenced by
-- fully-qualified name inside private.has_role(), private.has_region()
-- and private.belongs_to_organization() (all SECURITY DEFINER, search_path
-- = ''), so archiving them broke those functions. A later migration
-- restored all four. This file is left as originally applied (never
-- rewrite history a production migration already ran) with those four
-- ALTER TABLE lines removed so a *fresh* install does not reintroduce the
-- same bug -- only beneficiary_categories, confirmed safe (referenced
-- solely as a string literal in a coverage-check list, never queried),
-- stays archived from this original scaffold group.

BEGIN;

-- Questionnaire scaffold (never shipped)
ALTER TABLE public.question_options        RENAME TO _deprecated_question_options;
ALTER TABLE public.user_responses          RENAME TO _deprecated_user_responses;

-- Multi-tenant admin scaffold (never shipped) -- beneficiary_categories only;
-- organization_memberships/user_roles/regions/user_regions are load-bearing,
-- see the correction note above.
ALTER TABLE public.beneficiary_categories  RENAME TO _deprecated_beneficiary_categories;

-- Superseded by public.chat_logs / voice_chat_sessions (live)
ALTER TABLE public.ai_conversations        RENAME TO _deprecated_ai_conversations;
ALTER TABLE public.ai_messages             RENAME TO _deprecated_ai_messages;
ALTER TABLE public.user_memory             RENAME TO _deprecated_user_memory;

-- Structurally obsolete: search executes on-device, so server-side
-- search logging can no longer be populated by any code path.
ALTER TABLE public.search_logs             RENAME TO _deprecated_search_logs;

-- Unshipped product surfaces
ALTER TABLE public.recent_schemes          RENAME TO _deprecated_recent_schemes;
ALTER TABLE public.bug_reports             RENAME TO _deprecated_bug_reports;
ALTER TABLE public.feature_requests        RENAME TO _deprecated_feature_requests;
ALTER TABLE public.sync_history            RENAME TO _deprecated_sync_history;

-- Catalog scaffold
ALTER TABLE catalog.ai_metadata            RENAME TO _deprecated_ai_metadata;

COMMIT;
