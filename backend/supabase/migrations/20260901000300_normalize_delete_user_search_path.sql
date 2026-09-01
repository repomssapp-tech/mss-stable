-- ===========================================================
-- Migration: normalize_delete_user_search_path
-- Project : IN Schemes (MSS App)
-- Purpose : L9 -- public.delete_user() is SECURITY DEFINER but still runs
--           with `SET search_path = public` (from 20260806113000). It is
--           already safe in practice (revoked from anon in 20260829160000;
--           body only touches auth.*), but every other DEFINER function in
--           this project uses the hardened convention `SET search_path = ''`
--           with fully-qualified names. Bring it in line. Behaviour is
--           identical.
-- ===========================================================

begin;

create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    delete from auth.users where id = auth.uid();
  else
    raise exception 'Only authenticated users can delete their account';
  end if;
end;
$$;

-- Re-assert the access posture from 20260829160000 (idempotent).
revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;

commit;

-- ===========================================================
-- Rollback (manual):
--   create or replace function public.delete_user() ... set search_path = public ... ;
-- ===========================================================
