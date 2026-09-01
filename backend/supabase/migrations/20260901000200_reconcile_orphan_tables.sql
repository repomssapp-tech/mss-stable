-- ===========================================================
-- Migration: reconcile_orphan_tables
-- Project : IN Schemes (MSS App)
-- Purpose : Bring two tables that exist ONLY on the hosted DB (created
--           out-of-band, absent from every migration) under source control
--           so `supabase db reset` reproduces the production shape.
--
--   public.chat_logs   -- referenced by NO code anywhere in this repo
--       (frontend, backend, edge functions, voice agent all grep-clean).
--       Adopted here as a write-only telemetry sink with the SAME hardened
--       policy set that 20260901000000 applies to the live table.
--
--       !!! RECONCILE: the column list below is a best-effort canonical
--       shape. Replace it with the real definition -- run against the live
--       DB and paste the result over the CREATE TABLE below:
--
--         select 'create table if not exists public.chat_logs (' ||
--           string_agg(
--             format('%I %s%s', column_name, udt_name,
--                    case when is_nullable = 'NO' then ' not null' else '' end),
--             ', ' order by ordinal_position) || ');'
--         from information_schema.columns
--         where table_schema = 'public' and table_name = 'chat_logs';
--
--       On the hosted DB the CREATE is a no-op (IF NOT EXISTS); a wrong
--       guess here only affects fresh local/CI databases, where nothing
--       reads or writes the table anyway.
--
--   public.auth_user_id -- 1 column, no PK/FK/comment, in no migration,
--       referenced by no code. Treated as cruft: dropped, but ONLY if
--       empty. If it holds rows the drop is skipped with a warning so a
--       human decides.
-- ===========================================================

begin;

-- ---------------------------------------------------------------------------
-- public.chat_logs -- adopt (create-if-absent) + harden identically to
-- 20260901000000_lockdown_chat_logs_and_profiles_anon.sql.
-- ---------------------------------------------------------------------------
create table if not exists public.chat_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  session_id  text,
  role        text,
  message     text,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

alter table public.chat_logs enable row level security;

do $$
declare
  has_user_id boolean;
begin
  execute 'drop policy if exists "Allow read chat logs" on public.chat_logs';
  execute 'drop policy if exists "Allow log insertion" on public.chat_logs';
  execute 'drop policy if exists "chat_logs client insert" on public.chat_logs';

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'chat_logs' and column_name = 'user_id'
  ) into has_user_id;

  if has_user_id then
    execute 'create policy "chat_logs client insert" on public.chat_logs '
         || 'for insert to authenticated with check (user_id = auth.uid())';
  else
    execute 'create policy "chat_logs client insert" on public.chat_logs '
         || 'for insert to authenticated with check (true)';
  end if;
end $$;

revoke all on table public.chat_logs from anon;
revoke select, update, delete, truncate, references, trigger
  on table public.chat_logs from authenticated;
grant insert on table public.chat_logs to authenticated;

comment on table public.chat_logs is
  'Write-only client telemetry sink. Adopted into migrations 2026-09-01 '
  'after being found un-migrated on the hosted DB. No repo code reads it.';

-- ---------------------------------------------------------------------------
-- public.auth_user_id -- drop if present and empty.
-- ---------------------------------------------------------------------------
do $$
declare
  n bigint;
begin
  if to_regclass('public.auth_user_id') is null then
    raise notice 'public.auth_user_id absent -- nothing to do';
    return;
  end if;

  execute 'select count(*) from public.auth_user_id' into n;
  if n = 0 then
    execute 'drop table public.auth_user_id';
    raise notice 'dropped empty public.auth_user_id';
  else
    raise warning 'public.auth_user_id has % row(s) -- NOT dropped. Inspect and remove manually.', n;
  end if;
end $$;

commit;

-- ===========================================================
-- Rollback (manual): chat_logs should stay adopted. Re-create
-- public.auth_user_id only if you can supply its original definition --
-- there is no automatic reverse.
-- ===========================================================
