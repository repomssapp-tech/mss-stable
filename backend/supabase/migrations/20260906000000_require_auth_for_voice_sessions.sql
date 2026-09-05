-- ===========================================================
-- Migration: require_auth_for_voice_sessions
-- Project  : IN Schemes (MSS App)
-- Purpose  : Close the anonymous write surface on
--            public.voice_chat_sessions, bind every row to its owner,
--            and bound the JSONB payload size.
--
-- Context  : 20260905000100 created this table with INSERT granted to
--            `anon` and a policy admitting `user_id IS NULL` rows. That
--            combination let anyone holding the publishable key (which
--            ships inside the APK) write unbounded voice transcripts, and
--            it bypassed the Edge Function rate limiter entirely because
--            these are direct PostgREST inserts. Rows written that way
--            were also unreadable by anyone but service_role and could
--            never be reached by public.delete_user().
--
-- Note     : The policy dropped here is `voice_chat_sessions_insert_policy`
--            -- the actual name created by 20260905000100. It permitted
--            BOTH an anon branch and an authenticated `user_id IS NULL`
--            branch; the replacement admits neither.
-- ===========================================================

begin;

-- 1. Drop the permissive insert policy (anon branch + null-owner branch).
drop policy if exists "voice_chat_sessions_insert_policy"
    on public.voice_chat_sessions;

-- 2. Remove the anon INSERT grant added by 20260905000100.
revoke insert on table public.voice_chat_sessions from anon;

-- 3. Replace with an authenticated-only policy tied to the actual user.
--    No null-owner branch: an unattributable transcript is not a row we
--    are willing to store.
create policy "voice_chat_sessions_insert_policy"
    on public.voice_chat_sessions
    for insert
    to authenticated
    with check (user_id = auth.uid());

-- 4. Bound the payload even for legitimate authenticated clients -- a
--    buggy or compromised client is still a cost/DoS vector. Largest
--    transcript in production at time of writing is 1713 bytes, so these
--    ceilings leave roughly 29x headroom.
alter table public.voice_chat_sessions
    add constraint transcript_size_limit
    check (pg_column_size(transcript) < 50000);

alter table public.voice_chat_sessions
    add constraint metrics_size_limit
    check (pg_column_size(session_metrics) < 20000);

-- 5. Remove the orphaned rows the old policy permitted. These are
--    unowned and can never be legitimately claimed, read by their
--    subject, or deleted on request. Both known rows are single-turn
--    "(Session ended)" markers (~170 bytes) produced by a startup race
--    in which ChatLogService.syncPendingOfflineQueue() flushed before
--    Supabase auth restore completed -- that race is fixed in
--    frontend/lib/services/chat_log_service.dart in the same change.
delete from public.voice_chat_sessions where user_id is null;

commit;

-- ===========================================================
-- Rollback (manual, NOT recommended -- reopens the anon write surface):
--   begin;
--   alter table public.voice_chat_sessions drop constraint if exists metrics_size_limit;
--   alter table public.voice_chat_sessions drop constraint if exists transcript_size_limit;
--   drop policy if exists "voice_chat_sessions_insert_policy" on public.voice_chat_sessions;
--   create policy "voice_chat_sessions_insert_policy"
--     on public.voice_chat_sessions for insert to anon, authenticated
--     with check (
--       (auth.role() = 'anon' and user_id is null)
--       or (auth.role() = 'authenticated' and (user_id is null or user_id = auth.uid()))
--     );
--   grant insert on table public.voice_chat_sessions to anon;
--   commit;
--   -- Deleted orphan rows are NOT recoverable by this rollback.
-- ===========================================================
