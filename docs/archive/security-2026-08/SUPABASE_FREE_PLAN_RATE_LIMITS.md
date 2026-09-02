# Supabase Free Tier Rate Limits & Resource Optimization Guide

**Project:** MSS App (`IN_Schemes`)  
**Target Architecture:** Supabase Free Plan  
**Purpose:** Enforce multi-layer rate limiting, quota protection, and connection conservation so the application stays strictly within free-tier thresholds without service disruption or surprise downgrades.

---

## 1. Supabase Free Plan Quota vs Configured Protections

| Metric / Service | Supabase Free Plan Quota | Configured Safety Limit | Implementation Layer |
|---|---|---|---|
| **Edge Functions Invocations** | 500,000 / month (~11.5 / min avg) | **15 searches/min/IP**, **40 total requests/min/IP** | `backend/supabase/functions/v1/index.ts` |
| **Edge Function Search Engine** | Cold start loads DB | **1-hour in-memory cache TTL**, **Singleflight coalescing** | `index.ts` (`getSearchEngine`) |
| **API Egress / Bandwidth** | 5 GB / month | **`max_rows = 100`** (was 1000) | `backend/supabase/config.toml` |
| **Database Compute / CPU** | 2 vCPU (shared micro-instance) | **5s statement timeout (anon)**, **8s (auth)** | `20260827010000_free_tier_resource_limits.sql` |
| **Database Lock Contention** | Shared memory | **3s lock timeout (anon)**, **5s (auth)** | `20260827010000_free_tier_resource_limits.sql` |
| **Idle Transactions** | Shared connection pool | **10s idle session abort (anon)**, **15s (auth)** | `20260827010000_free_tier_resource_limits.sql` |
| **Auth: Email Deliverability** | ~3-4 emails/hr (Supabase default SMTP) | **3 emails / hour** | `backend/supabase/config.toml` (`[auth.rate_limit]`) |
| **Auth: Sign-in / Sign-up** | Unprotected = credential stuffing risk | **15 requests / 5 mins / IP** | `backend/supabase/config.toml` |
| **Auth: Token Verifications** | OTP brute-force risk | **15 requests / 5 mins / IP** | `backend/supabase/config.toml` |
| **Auth: Token Refresh** | Re-auth loops risk | **60 refreshes / 5 mins / IP** | `backend/supabase/config.toml` |
| **Realtime Connections** | 200 concurrent connections | **Only connects if authenticated**, unsubscribes on logout | `frontend/lib/providers/app_state_provider.dart` |
| **Storage Checks & Releases** | 5 GB storage egress / month | **1-hour client throttle** (was 15 min) | `frontend/lib/services/scheme_catalog_sync_service.dart` |
| **PostgREST Promo Polling** | Uncached queries on tab switches | **30-minute client cache** | `frontend/lib/providers/app_state_provider.dart` |
| **Client Search Debounce** | Rapid typing parallel calls | **15s query memoization + in-flight deduplication** | `frontend/lib/services/scheme_repository.dart` |

---

## 2. Layer 1: Edge Function Gateway Rate Limiting (`index.ts`)

Located in [`backend/supabase/functions/v1/index.ts`](file:///c:/development/MSS%20App/MSS_App/backend/supabase/functions/v1/index.ts):

```typescript
// Free Tier Limits
const MAX_SEARCH_REQUESTS_PER_WINDOW = 15; // Max 15 searches / 60s per client IP
const MAX_GLOBAL_REQUESTS_PER_WINDOW = 40; // Max 40 total gateway requests / 60s per client IP
const RATE_LIMIT_WINDOW_MS = 60 * 1000;

// Global check before invoking heavy business logic
if (route !== 'health' && isGlobalRateLimited(clientIp)) {
  return new Response(JSON.stringify({
    error: 'TOO_MANY_REQUESTS',
    message: 'Rate limit exceeded for Free Tier quota protection. Please wait before retrying.',
  }), {
    status: 429,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '10' },
  });
}
```

- **HTTP 429 Responses:** Return a standard `Retry-After: 10` (or `Retry-After: 5` for search) header so clients know when they can retry.
- **Memory Self-Cleaning:** The sliding-window map automatically purges expired IP entries once the map exceeds 1,000 unique client IPs, avoiding Deno runtime memory leaks.

---

## 3. Layer 2: Supabase Auth & PostgREST Limits (`config.toml`)

Located in [`backend/supabase/config.toml`](file:///c:/development/MSS%20App/MSS_App/backend/supabase/config.toml):

```toml
[api]
# Restricts query result sets to 100 rows, preserving the 5GB monthly egress quota
max_rows = 100

[auth.rate_limit]
# Matches Supabase Free Tier default SMTP cap (3-4/hour)
email_sent = 3
sms_sent = 10
anonymous_users = 0
token_refresh = 60
sign_in_sign_ups = 15
token_verifications = 15
web3 = 10
```

---

## 4. Layer 3: Database Compute & Concurrency (`20260827010000_free_tier_resource_limits.sql`)

Located in [`backend/supabase/migrations/20260827010000_free_tier_resource_limits.sql`](file:///c:/development/MSS%20App/MSS_App/backend/supabase/migrations/20260827010000_free_tier_resource_limits.sql):

```sql
-- Abort long-running queries before they saturate micro-instance compute
alter role anon set statement_timeout = '5s';
alter role authenticated set statement_timeout = '8s';

-- Abort blocked lock acquisitions to prevent cascading transaction backlogs
alter role anon set lock_timeout = '3s';
alter role authenticated set lock_timeout = '5s';

-- Automatically disconnect abandoned transactions
alter role anon set idle_in_transaction_session_timeout = '10s';
alter role authenticated set idle_in_transaction_session_timeout = '15s';
```

---

## 5. Layer 4: Flutter Mobile Client Polling & Egress Protections

1. **Catalog Release Checking (`SchemeCatalogSyncService`):**
   - Default check throttle increased from 15 minutes to **1 hour** (`Duration(hours: 1)`).
   - Prevents frequent app reopenings from repeatedly pulling release manifests from Supabase Storage.
2. **Promotional Alerts Query Throttling (`AppStateProvider`):**
   - Added a 30-minute memoization timer (`_promoFetchThrottle = Duration(minutes: 30)`).
   - Eliminates redundant PostgREST `SELECT * FROM promo_alerts` calls when users switch tabs or trigger state updates.
3. **Search Keystroke Deduplication (`SchemeRepository`):**
   - 15-second client-side cache and singleflight in-flight request deduplication prevents duplicate queries to `/v1/search`.
4. **Realtime Channel Pruning (`AppStateProvider`):**
   - Subscriptions to `profiles` are only established when an authenticated user exists, and are immediately cancelled on `logout()`.

---

## 6. How to Deploy to Supabase Cloud

To apply these rate limits to your live Supabase project:

1. **Deploy Edge Function:**
   ```bash
   cd backend
   supabase functions deploy v1 --project-ref houpzsxmwemoztpuigmo
   ```

2. **Apply Database Migration:**
   Paste the contents of [`backend/supabase/migrations/20260827010000_free_tier_resource_limits.sql`](file:///c:/development/MSS%20App/MSS_App/backend/supabase/migrations/20260827010000_free_tier_resource_limits.sql) into the **Supabase Dashboard -> SQL Editor** and click **Run**.

3. **Verify Auth Rate Limits in Dashboard:**
   In **Supabase Dashboard -> Authentication -> Rate Limits**, verify that:
   - Email rate limit is set to `3` per hour.
   - Sign up / sign in is set to `15` per 5 minutes.
