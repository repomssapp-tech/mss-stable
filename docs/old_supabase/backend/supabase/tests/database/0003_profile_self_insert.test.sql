begin;

select plan(2);

select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'Profiles insert access'
      and cmd = 'INSERT'
      and 'authenticated' = any (roles)
  ),
  'authenticated users have an insert policy on public.profiles'
);

select ok(
  has_table_privilege('authenticated', 'public.profiles', 'INSERT'),
  'authenticated role has INSERT privilege on public.profiles'
);

select * from finish();

rollback;
