-- Migration: 20260827010000_free_tier_resource_limits.sql
-- Description: Enforces aggressive statement & lock timeouts on database roles
--              to protect shared micro-compute and prevent query runaway on the
--              Supabase Free Tier (500MB DB, 5GB bandwidth, shared 2 vCPU).

-- 1. Statement timeouts: Abort runaway queries before they saturate shared compute
alter role anon set statement_timeout = '3s';
alter role authenticated set statement_timeout = '8s';

-- 2. Lock timeouts: Prevent contention and transaction backlogs
alter role anon set lock_timeout = '3s';
alter role authenticated set lock_timeout = '5s';

-- 3. Idle in transaction session timeout: Auto-terminate abandoned client sessions
alter role anon set idle_in_transaction_session_timeout = '10s';
alter role authenticated set idle_in_transaction_session_timeout = '15s';

comment on schema public is 'Public schema with Free-Tier aligned statement and lock timeouts.';
