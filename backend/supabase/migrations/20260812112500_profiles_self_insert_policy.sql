-- Restore the self-insert policy removed by the v2 architecture migration.
-- PostgREST upsert requires INSERT permission even when the user already has a
-- profile row and the operation ultimately resolves through ON CONFLICT.

alter table public.profiles enable row level security;

grant select, insert, update on table public.profiles to authenticated;

drop policy if exists "Profiles insert access" on public.profiles;
create policy "Profiles insert access"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

