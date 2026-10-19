-- ===========================================================
-- Migration: archive_legacy_chat_logs
-- Project  : MSS - MSME Schemes Search
-- Purpose  : Retire the superseded flat public.chat_logs table by rename,
--            per the archive-not-drop rule (a rename is reversible for a
--            release cycle; a drop is not).
--
-- Verification performed before writing this migration:
--   * No code reference remains. `git grep chat_logs` across
--     frontend/lib, backend/supabase/functions and saarthi-agent/src
--     returns nothing -- the app writes only to voice_chat_sessions
--     (chat_log_service.dart flushSessionLogs / syncPendingOfflineQueue).
--   * The data is ALREADY migrated. chat_logs' 16 rows are the same 4
--     sessions present in voice_chat_sessions, matched by
--     conversation_uid = session_id with identical timestamps:
--       3dfb401f... 1 row   de04d1b6... 1 row
--       7ab80768... 9 rows  cd948c99... 5 rows
--     so scripts/migrate_chat_logs.js has nothing left to move. It is
--     kept in-tree as the record of how the transform was defined.
--
-- Rows are retained, not deleted: the two single-row sessions here are
-- "(Session ended)" markers (43-45 bytes, no transcript content) whose
-- corresponding orphan rows were removed from voice_chat_sessions in
-- 20260906000000. Keeping them under the archived name preserves the
-- trail of what happened without leaving them client-reachable -- the
-- table is already service_role-only (anon and authenticated hold no
-- SELECT or INSERT privilege).
--
-- Drop only after one release cycle has passed with no regression.
-- ===========================================================

begin;

alter table public.chat_logs rename to _deprecated_chat_logs;

comment on table public._deprecated_chat_logs is
    'DEPRECATED 20260906. Superseded by public.voice_chat_sessions; all 16 rows already represented there as 4 sessions. Retained one release cycle, then droppable. No code references this table.';

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   alter table public._deprecated_chat_logs rename to chat_logs;
--   commit;
-- ===========================================================
