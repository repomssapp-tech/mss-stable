-- ===========================================================
-- Migration: chat_logs_user_id_binding
-- Project : IN Schemes (MSS App)
-- Purpose : public.chat_logs' INSERT policy is `with check (true)` for
--           authenticated -- any signed-in user can insert a row and
--           attribute it to any conversation_uid, including someone else's.
--           Add a user_id column defaulting to auth.uid() (so no Edge
--           Function/client change is needed for it to populate) and bind
--           the INSERT policy to it.
-- ===========================================================

begin;

alter table public.chat_logs
  add column if not exists user_id uuid default auth.uid() references auth.users(id) on delete set null;

create index if not exists idx_chat_logs_user_id on public.chat_logs (user_id);

drop policy if exists "chat_logs client insert" on public.chat_logs;
create policy "chat_logs client insert"
on public.chat_logs
for insert
to authenticated
with check (user_id = auth.uid());

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   drop policy if exists "chat_logs client insert" on public.chat_logs;
--   create policy "chat_logs client insert" on public.chat_logs
--     for insert to authenticated with check (true);
--   drop index if exists idx_chat_logs_user_id;
--   alter table public.chat_logs drop column if exists user_id;
--   commit;
-- ===========================================================
