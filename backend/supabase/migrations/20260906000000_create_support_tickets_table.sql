-- ===========================================================
-- Migration: create_support_tickets_table
-- Project  : IN Schemes (MSS App)
-- Purpose  : Create dedicated table for user bug reports and support tickets
--            with anti-bot rate limiting and strict RLS policies.
-- ===========================================================

begin;

-- 1. Create table for support tickets
create table if not exists public.support_tickets (
    id            uuid        primary key default gen_random_uuid(),
    user_id       uuid        references auth.users(id) on delete set null,
    category      text        not null,
    contact_email varchar(255) not null,
    description   text        not null,
    status        varchar(50) not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
    created_at    timestamptz not null default timezone('utc'::text, now())
);

comment on table public.support_tickets is
    'Stores user-reported issues, bugs, and inquiries submitted via Help & Support.';

-- 2. Indexes for efficient triage, lookup, and rate limiting
create index if not exists idx_support_tickets_user_id
    on public.support_tickets (user_id);

create index if not exists idx_support_tickets_created_at
    on public.support_tickets (created_at desc);

create index if not exists idx_support_tickets_status
    on public.support_tickets (status);

create index if not exists idx_support_tickets_lower_email
    on public.support_tickets (lower(contact_email));

-- 3. Enable Row Level Security (RLS)
alter table public.support_tickets enable row level security;

-- 4. RLS Policies
-- INSERT:
-- - Anonymous users can only submit guest tickets (user_id is null).
-- - Authenticated users can submit tickets with their own user_id or as guest (user_id is null).
drop policy if exists "support_tickets_insert_policy" on public.support_tickets;
create policy "support_tickets_insert_policy"
on public.support_tickets
for insert
to anon, authenticated
with check (
    (auth.role() = 'anon' and user_id is null)
    or
    (auth.role() = 'authenticated' and (user_id is null or user_id = auth.uid()))
);

-- SELECT:
-- Authenticated users may only view tickets they personally submitted.
-- Anonymous users cannot read any tickets (prevents email/description scraping).
drop policy if exists "support_tickets_select_policy" on public.support_tickets;
create policy "support_tickets_select_policy"
on public.support_tickets
for select
to authenticated
using (user_id = auth.uid());

-- 5. Role Grants (Principle of Least Privilege)
-- Anonymous: write-only (INSERT)
-- Authenticated: write (INSERT) and read own (SELECT)
-- Service Role: full admin CRUD
revoke all on table public.support_tickets from anon, authenticated;
grant insert on table public.support_tickets to anon;
grant select, insert on table public.support_tickets to authenticated;
grant all on table public.support_tickets to service_role;

-- 6. Anti-Bot Rate Limiting Trigger
-- Enforces:
-- a) Cooldown: Minimum 30 seconds between consecutive submissions per email.
-- b) Cap: Maximum 5 tickets per hour per email.
create or replace function public.check_support_ticket_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_recent_count int;
    v_last_submitted timestamptz;
begin
    -- Check consecutive submission cooldown (at least 30 seconds between submissions for same email)
    select created_at into v_last_submitted
    from public.support_tickets
    where lower(contact_email) = lower(new.contact_email)
    order by created_at desc
    limit 1;

    if v_last_submitted is not null and (clock_timestamp() - v_last_submitted) < interval '30 seconds' then
        raise exception 'Too many requests. Please wait at least 30 seconds before submitting another ticket.'
            using errcode = 'P0001';
    end if;

    -- Check window limit (maximum 5 tickets per hour for this email)
    select count(*) into v_recent_count
    from public.support_tickets
    where lower(contact_email) = lower(new.contact_email)
      and created_at > (clock_timestamp() - interval '1 hour');

    if v_recent_count >= 5 then
        raise exception 'Hourly ticket limit reached for this email. Please try again later.'
            using errcode = 'P0001';
    end if;

    return new;
end;
$$;

drop trigger if exists trg_check_support_ticket_rate_limit on public.support_tickets;
create trigger trg_check_support_ticket_rate_limit
    before insert on public.support_tickets
    for each row
    execute function public.check_support_ticket_rate_limit();

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   drop trigger if exists trg_check_support_ticket_rate_limit on public.support_tickets;
--   drop function if exists public.check_support_ticket_rate_limit();
--   drop policy if exists "support_tickets_select_policy" on public.support_tickets;
--   drop policy if exists "support_tickets_insert_policy" on public.support_tickets;
--   drop table if exists public.support_tickets cascade;
--   commit;
-- ===========================================================
