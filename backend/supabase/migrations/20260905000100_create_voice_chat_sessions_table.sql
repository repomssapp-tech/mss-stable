-- ===========================================================
-- Migration: create_voice_chat_sessions_table
-- Project  : IN Schemes (MSS App)
-- Purpose  : Create dedicated structured document table for voice assistant
--            sessions (public.voice_chat_sessions). Replaces legacy flat
--            public.chat_logs table with a single JSONB document per session,
--            including full transcripts, turn counts, and duration metrics.
-- ===========================================================

begin;

-- 1. Create table
create table if not exists public.voice_chat_sessions (
    session_id      uuid        primary key,
    user_id         uuid        references auth.users(id) on delete set null,
    status          text        not null default 'completed' check (status in ('completed', 'interrupted', 'in_progress', 'failed')),
    transcript      jsonb       not null default '[]'::jsonb,
    session_metrics jsonb       not null default '{}'::jsonb,
    created_at      timestamptz not null default timezone('utc'::text, now()),
    ended_at        timestamptz not null default timezone('utc'::text, now())
);

comment on table public.voice_chat_sessions is
    'Stores completed and interrupted voice assistant sessions with full transcript and metrics.';

-- 2. Indexes for performance and query optimization
create index if not exists idx_voice_chat_sessions_user_id
    on public.voice_chat_sessions (user_id);

create index if not exists idx_voice_chat_sessions_created_at
    on public.voice_chat_sessions (created_at desc);

create index if not exists idx_voice_chat_sessions_status
    on public.voice_chat_sessions (status);

-- 3. Enable Row Level Security (RLS)
alter table public.voice_chat_sessions enable row level security;

-- 4. RLS Policies
-- INSERT: Anonymous users can insert guest sessions (user_id is null).
--         Authenticated users can insert sessions belonging to themselves (or null).
drop policy if exists "voice_chat_sessions_insert_policy" on public.voice_chat_sessions;
create policy "voice_chat_sessions_insert_policy"
on public.voice_chat_sessions
for insert
to anon, authenticated
with check (
    (auth.role() = 'anon' and user_id is null)
    or
    (auth.role() = 'authenticated' and (user_id is null or user_id = auth.uid()))
);

-- SELECT: Authenticated users may view their own recorded sessions.
drop policy if exists "voice_chat_sessions_select_policy" on public.voice_chat_sessions;
create policy "voice_chat_sessions_select_policy"
on public.voice_chat_sessions
for select
to authenticated
using (user_id = auth.uid());

-- 5. Role Grants
-- Anonymous client has INSERT only (write-only telemetry sink for guest voice sessions).
-- Authenticated client has SELECT (own sessions) and INSERT.
-- Service role has full CRUD access (bypasses RLS).
revoke all on table public.voice_chat_sessions from anon, authenticated;
grant insert on table public.voice_chat_sessions to anon;
grant select, insert on table public.voice_chat_sessions to authenticated;
grant all on table public.voice_chat_sessions to service_role;

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   drop policy if exists "voice_chat_sessions_select_policy" on public.voice_chat_sessions;
--   drop policy if exists "voice_chat_sessions_insert_policy" on public.voice_chat_sessions;
--   drop table if exists public.voice_chat_sessions cascade;
--   commit;
-- ===========================================================
