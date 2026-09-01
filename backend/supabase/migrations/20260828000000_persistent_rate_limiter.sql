-- ===========================================================
-- Migration: persistent_rate_limiter
-- Project : IN Schemes
-- Purpose : Replace the Edge Function's in-memory rate limiter with a
--           database-backed one.
--
--           The in-memory limiter added in bbc8b7c never limited anything:
--           Supabase Edge Function isolates cold-boot per request on this
--           project (function_logs shows ~2571 "Listening on :9999" boots
--           for ~2736 invocations), so every request got a fresh, empty
--           Map and passed the check. Counters must outlive the isolate.
--
--           Also adds a GLOBAL daily budget bucket, which is the actual
--           stop against another 5GB egress overrun: per-IP limits do not
--           bound total project egress, a global counter does.
-- ===========================================================

-- 1. Counter storage ----------------------------------------------------
-- One row per (bucket, identifier). Fixed-window counters: cheap, atomic,
-- and survives isolate death. Deliberately NOT a sliding window -- a
-- sliding window needs per-request timestamp arrays, which costs more
-- storage and IO than the extra boundary burst is worth here.
create table if not exists public.api_rate_limits (
  bucket        text        not null,
  identifier    text        not null,
  window_start  timestamptz not null default now(),
  request_count integer     not null default 0,
  updated_at    timestamptz not null default now(),
  primary key (bucket, identifier)
);

comment on table public.api_rate_limits is
  'Edge Function rate-limit counters. Written only by service_role via mss_check_rate_limit().';

-- RLS on with zero policies: anon/authenticated can never read or write.
-- service_role bypasses RLS, which is the only caller.
alter table public.api_rate_limits enable row level security;

revoke all on table public.api_rate_limits from anon, authenticated;

create index if not exists api_rate_limits_updated_at_idx
  on public.api_rate_limits (updated_at);

-- 2. Atomic check-and-increment ----------------------------------------
-- Returns TRUE when the caller is over the limit (i.e. should be blocked).
-- The INSERT ... ON CONFLICT is a single atomic statement, so concurrent
-- isolates cannot race past the limit.
create or replace function public.mss_check_rate_limit(
  p_bucket         text,
  p_identifier     text,
  p_max_requests   integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now    timestamptz := clock_timestamp();
  v_cutoff timestamptz;
  v_count  integer;
begin
  v_cutoff := v_now - make_interval(secs => p_window_seconds);

  insert into public.api_rate_limits as l
    (bucket, identifier, window_start, request_count, updated_at)
  values
    (p_bucket, p_identifier, v_now, 1, v_now)
  on conflict (bucket, identifier) do update
    set request_count = case
          when l.window_start < v_cutoff then 1
          else l.request_count + 1
        end,
        window_start = case
          when l.window_start < v_cutoff then v_now
          else l.window_start
        end,
        updated_at = v_now
  returning l.request_count into v_count;

  -- Opportunistic GC (~1% of calls) so the table cannot grow unbounded
  -- without needing pg_cron on the free tier.
  if random() < 0.01 then
    delete from public.api_rate_limits
     where updated_at < v_now - interval '2 days';
  end if;

  return v_count > p_max_requests;
end;
$$;

-- 3. Read-only introspection for ops -----------------------------------
create or replace function public.mss_rate_limit_status(p_bucket text)
returns table (
  identifier    text,
  request_count integer,
  window_start  timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select l.identifier, l.request_count, l.window_start
    from public.api_rate_limits l
   where l.bucket = p_bucket
   order by l.request_count desc
   limit 100;
$$;

-- 4. Lock both functions to service_role -------------------------------
-- These must never be callable with the publishable key that ships inside
-- the APK, or a client could inflate/inspect its own counters.
revoke all on function public.mss_check_rate_limit(text, text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.mss_check_rate_limit(text, text, integer, integer)
  to service_role;

revoke all on function public.mss_rate_limit_status(text)
  from public, anon, authenticated;
grant execute on function public.mss_rate_limit_status(text)
  to service_role;
