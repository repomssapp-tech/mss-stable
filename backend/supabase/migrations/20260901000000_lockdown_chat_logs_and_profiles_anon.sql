-- ===========================================================
-- Migration: lockdown_chat_logs_and_profiles_anon
-- Project  : MSS - MSME Schemes Search
-- Purpose : Close two confirmed-live RLS gaps found in the 2026-09-01 audit.
--
--   C1. public.profiles still carries table-level SELECT/INSERT/UPDATE/DELETE
--       grants to `anon`. The tightened self-row SELECT *policy* from
--       20260818000000 did land (verified: no anon policy on profiles, RLS
--       on), but that migration's `revoke all ... from anon` did NOT --
--       same "recorded as applied, absent live" drift its own header warns
--       about. Not exploitable while RLS + no-anon-policy holds, but it is a
--       loaded gun: one bad USING(true) policy or an RLS toggle and anon has
--       full CRUD over PII (email, phone, dob, gender, disability,
--       annual_income, address). Re-assert the revoke.
--
--   C2/new. public.chat_logs is world-open via the publishable key that
--       ships in the APK:
--         "Allow read chat logs"  -> SELECT USING (true)  to {anon,authenticated}
--         "Allow log insertion"   -> INSERT (no WITH CHECK) to {anon,authenticated}
--       i.e. anyone can read the entire table and inject arbitrary rows.
--       The user-facing chat store is public.ai_conversations /
--       public.ai_messages (own-row RLS); chat_logs is a write-only
--       telemetry sink. Lock client SELECT off entirely and give INSERT a
--       real check. chat_logs is NOT defined in any migration -- it was
--       created out-of-band -- so this migration also brings its policy
--       state under source control. Reconciling the table DEFINITION itself
--       into a migration is left for the owner (tracked with auth_user_id).
-- ===========================================================

begin;

-- ---------------------------------------------------------------------------
-- C1. public.profiles -- strip residual anon grants.
-- ---------------------------------------------------------------------------
-- Leaves `authenticated` untouched (self-row SELECT / INSERT / UPDATE
-- policies + the "Profiles delete access" policy already exist and were
-- verified correct in the audit).
revoke all on table public.profiles from anon;

-- ---------------------------------------------------------------------------
-- C2. public.chat_logs -- deny client reads, check client writes.
-- ---------------------------------------------------------------------------
-- Guarded on table presence: on the hosted DB chat_logs already exists (it
-- was created out-of-band) and is hardened here. On a fresh
-- `supabase db reset` the table does not exist at this point -- it is
-- created AND hardened identically by
-- 20260901000200_reconcile_orphan_tables.sql, so this block no-ops.
do $$
declare
  has_user_id boolean;
begin
  if to_regclass('public.chat_logs') is null then
    raise notice 'public.chat_logs absent -- hardening deferred to 20260901000200_reconcile_orphan_tables';
    return;
  end if;

  execute 'drop policy if exists "Allow read chat logs" on public.chat_logs';
  execute 'drop policy if exists "Allow log insertion" on public.chat_logs';
  execute 'drop policy if exists "chat_logs client insert" on public.chat_logs';

  -- If chat_logs has a user_id column, bind rows to the caller; otherwise a
  -- presence check (still closes the anon hole and the no-WITH-CHECK hole).
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

  -- authenticated keeps INSERT only; anon loses everything. service_role
  -- (Edge Functions / analytics) bypasses RLS and is unaffected.
  execute 'revoke all on table public.chat_logs from anon';
  execute 'revoke select, update, delete, truncate, references, trigger on table public.chat_logs from authenticated';
  execute 'grant insert on table public.chat_logs to authenticated';
end $$;

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   grant select, insert, update, delete on table public.profiles to anon;
--   drop policy if exists "chat_logs client insert" on public.chat_logs;
--   create policy "Allow read chat logs" on public.chat_logs
--     for select to anon, authenticated, service_role using (true);
--   create policy "Allow log insertion" on public.chat_logs
--     for insert to anon, authenticated, service_role with check (true);
--   grant select, insert on table public.chat_logs to anon, authenticated;
--   commit;
-- ===========================================================
