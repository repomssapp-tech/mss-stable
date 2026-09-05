-- MSS_App table archival -- Phase 3 cleanup (audit_fix.md)
-- All targets verified at 0 rows and 0 code references at execution time.
-- Rename is reversible: ALTER TABLE public._deprecated_x RENAME TO x;

BEGIN;

-- Questionnaire scaffold (never shipped)
ALTER TABLE public.question_options        RENAME TO _deprecated_question_options;
ALTER TABLE public.user_responses          RENAME TO _deprecated_user_responses;

-- Multi-tenant admin scaffold (never shipped)
ALTER TABLE public.organization_memberships RENAME TO _deprecated_organization_memberships;
ALTER TABLE public.user_roles              RENAME TO _deprecated_user_roles;
ALTER TABLE public.regions                 RENAME TO _deprecated_regions;
ALTER TABLE public.user_regions            RENAME TO _deprecated_user_regions;
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
