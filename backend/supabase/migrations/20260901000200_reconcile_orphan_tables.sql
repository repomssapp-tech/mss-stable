-- ===========================================================
-- Migration: reconcile_orphan_tables
-- Project : IN Schemes (MSS App)
-- Purpose : Drop public.auth_user_id -- a 1-column, no-PK/FK/comment table
--           that exists only on the hosted DB, is defined by no migration,
--           and is referenced by no code anywhere in this repo. Dropped only
--           if empty; if it holds rows the drop is skipped with a warning so
--           a human decides.
--
--           public.chat_logs was the other out-of-band table this migration
--           originally adopted. After the rebase onto main it is defined by
--           20260828160000_create_chat_logs_table.sql and hardened by
--           20260901000000_lockdown_chat_logs_and_profiles_anon.sql, so
--           there is nothing left to do for it here.
-- ===========================================================

begin;

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
-- Rollback (manual): re-create public.auth_user_id only if you can supply
-- its original definition -- there is no automatic reverse.
-- ===========================================================
