# Supabase table inventory: project `houpzsxmwemoztpuigmo`

**Generated:** 2026-10-05, from live queries against `pg_class` / `information_schema`.

**How rows were counted:** exact `count(*)` per table, not estimates.

**Scope:** every table, partition and view in every schema, except PostgreSQL's own internals (`pg_catalog`, `information_schema`, `pg_toast`).

## Where each table came from

| Origin | Meaning |
|---|---|
| 🟦 **You / team** | Created by the MSS App migrations (`backend/supabase/migrations/`) |
| 🟪 **Claude / Antigravity** | Created during the catalog v3.1 work (Oct 2026) |
| ⬜ **Supabase default** | Managed by Supabase or an extension (auth, storage, realtime, vault, pg_net, …). Don't edit or drop |
| 🟥 **Deprecated** | Renamed `_deprecated_*` by earlier clean-up migrations, kept for one release, can be dropped |

## Summary

| Schema | Origin | Tables | Rows | Notes |
|---|---|---:|---:|---|
| `catalog` | 🟦 (1 🟪, 1 🟥) | 20 | 6,130 | Scheme catalog: what the app bundle is built from |
| `public` | 🟦 (12 🟥) | 33 | 119 | User data, profiles, voice sessions, support |
| `admin` | 🟦 | 15 | 131 | Catalog releases and back-office RBAC |
| `auth` | ⬜ | 27 | 246 | Supabase Auth (18 users) |
| `storage` | ⬜ | 8 | 181 | Supabase Storage (1 bucket, 107 objects) |
| `realtime` | ⬜ | 8 (1 partitioned + 5 daily partitions + 2) | 87 | Supabase Realtime |
| `supabase_migrations` | ⬜ | 1 | 83 | Migration history |
| `net` | ⬜ (pg_net) | 2 | 0 | HTTP-from-Postgres extension |
| `vault` | ⬜ (supabase_vault) | 1 + 1 view | 0 | Encrypted secrets |
| `extensions` | ⬜ (pg_stat_statements) | 0 + 2 views | – | Query stats |
| **Total** | | **115 tables + 3 views** | **6,977** | |

**Totals by origin:**
- 🟦 You / team: 54 tables
- 🟪 Claude / Antigravity: 1 table
- 🟥 Deprecated: 13 tables
- ⬜ Supabase default: 47 tables + 3 views

---

## 🟦 `catalog`: scheme catalog

All of these have RLS on. Only `scheme_source_v3_1` has FORCE RLS.

| Table | Origin | Rows | Cols | Size | Columns (PK = primary key, NN = not null) |
|---|---|---:|---:|---:|---|
| `scheme` | 🟦 | 302 | 20 | 5.5 MB | id text PK, version, status, checksum, updated_at, published_at, record_json jsonb, scheme_code, name_en NN, name_ta, government_level, scheme_type, state, ministry, department, search_keywords, primary_authority_id, primary_institution_id, is_active bool, scheme_url |
| `applicability_matrix` | 🟦 | 302 | 12 | 2.0 MB | id PK, version, status, checksum, updated_at, published_at, record_json, scheme_id, government_level, department_authority_id, sector_text, district_text |
| `search_index` | 🟦 | 1,061 | 10 | 3.4 MB | id PK, version, status, checksum, updated_at, published_at, record_json, scheme_id, content NN, embedding vector |
| `relationships` | 🟦 | 1,890 | 8 | 1.5 MB | id uuid PK, source_type, source_id, target_type, target_id, relationship_type, metadata jsonb, created_at |
| `entity_registry` | 🟦 | 1,393 | 12 | 552 KB | entity_id PK, entity_type, catalog_name, current_version, status, validation_status, is_deleted, deleted_at, deleted_reason, checksum, created_at, updated_at |
| `common` | 🟦 | 344 | 7 | 2.1 MB | id PK, version, status, checksum, updated_at, published_at, record_json |
| `authority` | 🟦 | 131 | 10 | 1.0 MB | id PK, version, status, checksum, updated_at, published_at, record_json, code, name_en NN, name_ta |
| `finance` | 🟦 | 115 | 10 | 1.4 MB | … + scheme_id, interest_subvention_rate numeric, max_loan_amount numeric |
| `institution` | 🟦 | 83 | 11 | 688 KB | … + code, name_en NN, name_ta, authority_id |
| `knowledge` | 🟦 | 28 | 10 | 416 KB | … + title NN, item_type, category |
| `csr` | 🟦 | 16 | 9 | 320 KB | … + scheme_id, focus_areas text[] |
| `treds` | 🟦 | 16 | 9 | 312 KB | … + scheme_id, interest_rate_range |
| `export` | 🟦 | 13 | 9 | 312 KB | … + scheme_id, target_countries text[] |
| `tax` | 🟦 | 13 | 9 | 328 KB | … + scheme_id, exemption_percentage numeric |
| `enterprise_classification` | 🟦 | 11 | 11 | 216 KB | … + code, dimension, investment_max_inr, turnover_max_inr |
| `cluster_assistance` | 🟦 | 10 | 10 | 272 KB | … + cluster_name, sector, administering_authority_id |
| `business_enablement` | 🟦 | 7 | 10 | 176 KB | … + enablement_type, provider_authority_id, online_url |
| `msme_privilege` | 🟦 | 2 | 9 | 104 KB | … + privilege_type, statute |
| `scheme_source_v3_1` | 🟪 | 393 | 4 | 1.4 MB | id PK, source, record jsonb, imported_at. Raw v3.1 dataset (2015 Hindi compendium + 2025-26 booklet + new schemes), FORCE RLS, no app access |
| `_deprecated_ai_metadata` | 🟥 | 0 | 7 | 16 KB | entity_id PK, summary_en, summary_ta, keywords text[], embedding_status, generated_at, approved |

"…" stands for the standard catalog columns: `id, version, status, checksum, updated_at, published_at, record_json`.

Rows that came from the v3.1 work in tables you own:
- `scheme`: +83 (SCH000220–302)
- `authority`: +7 (AUTH000125–131)
- `applicability_matrix`: +83
- `search_index`: +83
- `relationships`: new child/parent, successor and duplicate links
- `entity_registry`: synced

The four staging tables (`*_new_v3_1`) have been dropped.

## 🟦 `public`: app and user data

| Table | Origin | Rows | Cols | RLS / FORCE | Columns |
|---|---|---:|---:|---|---|
| `profiles` | 🟦 | 17 | 40 | ✅ / ✅ | id PK, email NN, name, photo_url, language, navigation_mode, applicant_type, state, district, pincode, is_profile_complete, dob, gender, disability, veteran, house, area, street, village, city, qualification, education_level, annual_income, community, religion, first_gen_graduate NN, notifications, theme, phone, terms/privacy/consent accepted version+at (×4), created/updated/last_login_at |
| `voice_chat_sessions` | 🟦 | 36 | 7 | ✅ / – | session_id PK, user_id, status, transcript jsonb, session_metrics jsonb, created_at, ended_at |
| `api_rate_limits` | 🟦 | 31 | 5 | ✅ / – | bucket+identifier PK, window_start, request_count, updated_at (service_role only) |
| `notifications` | 🟦 | 8 | 7 | ✅ / – | id PK, user_id, title, message, notification_type, is_read, created_at |
| `roles` | 🟦 | 5 | 4 | ✅ / ✅ | id smallint PK, code, description, created_at |
| `promo_alerts` | 🟦 | 2 | 15 | ✅ / – | id PK, title, badge_*, bg_gradient_*, btn_*, target_route, graphic_type, target_gender/state/community, created_at |
| `support_tickets` | 🟦 | 2 | 7 | ✅ / – | id PK, user_id, category, contact_email, description, status, created_at |
| `beta_gate_config` | 🟦 | 1 | 3 | ✅ / – | id PK, beta_password **(plain text)**, s.no |
| `startup_profiles` | 🟦 | 1 | 16 | ✅ / ✅ | id PK, user_id, profile_name, description, industry, applicant_type, business_stage, business_registered, funding_required_amount, funding_purpose, is_first_generation_entrepreneur, is_active, registration_numbers, last_used_at, created_at, updated_at |
| `saved_schemes` | 🟦 | 0 | 4 | ✅ / – | id PK, user_id, scheme_id text, created_at |
| `recommendations` | 🟦 | 0 | 7 | ✅ / – | id PK, startup_profile_id, scheme_id **uuid**, match_score, recommendation_rank, recommendation_reason, generated_at |
| `questions` | 🟦 | 0 | 10 | ✅ / – | id PK, question_text, description, field_name, input_type, is_required, display_order, is_active, created_at, updated_at |
| `questionnaire_sessions` | 🟦 | 0 | 6 | ✅ / – | id PK, startup_profile_id, status, completed_percentage, started_at, completed_at |
| `feedback` | 🟦 | 0 | 5 | ✅ / – | id PK, user_id, rating, comment, created_at |
| `audit_log` | 🟦 | 0 | 12 | ✅ / – | id PK, organization_id, actor_user_id, action, target_type, target_id, request_id, reason, before/after_revision_id, metadata, created_at |
| `organizations` | 🟦 | 0 | 6 | ✅ / ✅ | id PK, code, name, active, created_at, updated_at |
| `organization_memberships` | 🟦 | 0 | 6 | ✅ / ✅ | user_id+organization_id PK, display_name, active, created_at, updated_at |
| `departments` | 🟦 | 0 | 7 | ✅ / ✅ | id PK, organization_id, code, name, active, created_at, updated_at |
| `regions` | 🟦 | 0 | 9 | ✅ / ✅ | id PK, organization_id, code, name, level region_level, parent_id, active, created_at, updated_at |
| `user_regions` | 🟦 | 0 | 5 | ✅ / ✅ | user_id+region_id PK, organization_id, assigned_by, assigned_at |
| `user_roles` | 🟦 | 0 | 5 | ✅ / ✅ | user_id+organization_id+role_id PK, granted_by, granted_at |
| `_deprecated_chat_logs` | 🟥 | 16 | 9 | ✅ / – | Superseded by `voice_chat_sessions` (comment: droppable after one release) |
| `_deprecated_ai_conversations` | 🟥 | 0 | 5 | ✅ / – | id, user_id, title, created_at, updated_at |
| `_deprecated_ai_messages` | 🟥 | 0 | 5 | ✅ / – | id, conversation_id, role, content, created_at |
| `_deprecated_beneficiary_categories` | 🟥 | 0 | 7 | ✅ / ✅ | id, organization_id, code, name, active, created_at, updated_at |
| `_deprecated_bug_reports` | 🟥 | 0 | 7 | ✅ / – | id, user_id, title, description, device_info, status, created_at |
| `_deprecated_feature_requests` | 🟥 | 0 | 7 | ✅ / – | id, user_id, title, description, upvotes, status, created_at |
| `_deprecated_question_options` | 🟥 | 0 | 7 | ✅ / – | id, question_id, option_label, option_value, next_question_id, display_order, created_at |
| `_deprecated_recent_schemes` | 🟥 | 0 | 4 | ✅ / – | id, user_id, scheme_id, viewed_at |
| `_deprecated_search_logs` | 🟥 | 0 | 5 | ✅ / – | id, user_id, query, results_count, created_at |
| `_deprecated_sync_history` | 🟥 | 0 | 10 | ✅ / – | id, user_id, device_id, platform, previous/synced_release_version, status, error_message, duration_ms, synced_at |
| `_deprecated_user_memory` | 🟥 | 0 | 6 | ✅ / – | id, user_id, key, value jsonb, created_at, updated_at |
| `_deprecated_user_responses` | 🟥 | 0 | 5 | ✅ / – | id, session_id, question_id, answer, answered_at |

## 🟦 `admin`: releases and back office

| Table | Rows | Cols | Columns |
|---|---:|---:|---|
| `catalog_files` | 112 | 11 | id PK, release_id, file_name, checksum, byte_size, storage_path, compression, mime_type, etag, download_count, last_downloaded_at |
| `catalog_releases` | 8 | 14 | id PK, version, schema_version, minimum/maximum_app_version, status, is_current, notes, published_by, published_at, release_version, package_sha256, record_counts jsonb, package_byte_size |
| `catalog_release_history` | 6 | 5 | id PK, release_id, action, actor_id, timestamp |
| `roles` | 5 | 4 | id smallint PK, code, description, created_at |
| `admins` | 0 | 3 | id uuid PK, role_id, created_at |
| `permissions` | 0 | 3 | id PK, code, description |
| `catalog_change_log` | 0 | 10 | id PK, entity, entity_id, field_path, previous_value, new_value, reason, changed_by, approved_by, timestamp |
| `catalog_publish_jobs` | 0 | 3 | id PK, release_id, status |
| `catalog_validation_runs` | 0 | 6 | id PK, started_at, completed_at, status, errors, run_by |
| `event_log` | 0 | 5 | id PK, event_type, actor_id, metadata, created_at |
| `import_batches` | 0 | 7 | id PK, file_name, batch_status, records_count, errors, imported_by, imported_at |
| `job_queue` | 0 | 7 | id PK, job_type, payload, status, error_log, created_at, updated_at |
| `record_locks` | 0 | 4 | entity_type+entity_id PK, checked_out_by, locked_until |
| `translation_jobs` | 0 | 12 | id PK, source/target_lang, entity_type, entity_id, field_name, status, source_text, translated_text, errors, created_at, updated_at |
| `translation_memory` | 0 | 4 | id PK, english_text, tamil_text, created_at |

All `admin` tables have RLS on and FORCE off.

## ⬜ Supabase-managed schemas (don't modify)

**`auth` (27 tables, 246 rows)**

| Table | Rows |
|---|---:|
| `schema_migrations` | 82 |
| `flow_state` | 72 |
| `refresh_tokens` | 22 |
| `users` | 18 |
| `identities` | 18 |
| `mfa_amr_claims` | 17 |
| `sessions` | 17 |

The other 20 have 0 rows: `audit_log_entries`, `custom_oauth_providers`, `instances`, `mfa_challenges`, `mfa_factors`, `mfa_recovery_code_sets`, `mfa_recovery_codes`, `oauth_authorizations`, `oauth_client_states`, `oauth_clients`, `oauth_consents`, `one_time_tokens`, `saml_providers`, `saml_relay_states`, `scim_tokens`, `scim_users`, `sso_domains`, `sso_providers`, `webauthn_challenges`, `webauthn_credentials`.

**`storage` (8 tables, 181 rows)**

| Table | Rows |
|---|---:|
| `objects` | 107 (catalog release files) |
| `migrations` | 73 |
| `buckets` | 1 (`catalogs`) |

The other 5 have 0 rows: `buckets_analytics`, `buckets_vectors`, `s3_multipart_uploads`, `s3_multipart_uploads_parts`, `vector_indexes`.

**`realtime` (87 rows)**
- `schema_migrations`: 87
- `subscription`: 0
- `messages`: 0. It's a partitioned table, with daily partitions `messages_2026_10_01` … `_05` (0 each).

**Other managed schemas**

| Schema | Contents |
|---|---|
| `supabase_migrations` | `schema_migrations`: 83 (your migration history) |
| `net` (pg_net) | `_http_response`: 0, `http_request_queue`: 0 |
| `vault` (supabase_vault) | `secrets`: 0; view `decrypted_secrets` |
| `extensions` (pg_stat_statements) | views `pg_stat_statements`, `pg_stat_statements_info` |

---

## Things worth knowing from this inventory

1. **`public.beta_gate_config` stores the beta password in plain text** (its own table comment says so). RLS is on, but anyone with dashboard or service access can read it. Consider hashing it or moving it to `vault.secrets`.
2. **The 13 `_deprecated_*` tables are all empty except `_deprecated_chat_logs` (16 rows, already copied into `voice_chat_sessions`).** They're safe to drop in one migration once you confirm nothing references them.
3. **`public.recommendations.scheme_id` is `uuid`, but scheme ids are text (`SCH000124`).** It's 0 rows and unused today, but any insert would fail. Fix the type or drop the table if recommendations stay client-side.
4. **`public.saved_schemes` has 0 rows.** Saved schemes are stored only on the device, so they don't sync across devices or survive a reinstall.
5. **The `organizations`, `departments`, `regions`, `user_*`, `questions`, `questionnaire_*`, `audit_log` and most `admin.*` tables are empty scaffolding** from the original design.
6. **Several counts differ from what earlier reports said:**
   - `catalog.relationships` is 1,890; the Antigravity report said 1,956.
   - `catalog.search_index` is 1,061 in the database; the app bundle has 930 because drafts are left out.
   - `catalog.entity_registry` is 1,393.
7. **Auth has 18 users and 17 profiles**, so one user has no profile row.

## Query used (re-runnable)

```sql
select n.nspname as schema, c.relname as name,
  case c.relkind when 'r' then 'table' when 'p' then 'partitioned' when 'v' then 'view' when 'm' then 'matview' end kind,
  case when c.relkind in ('r','p','m') then
    (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', n.nspname, c.relname), false, true, '')))[1]::text::bigint end as row_count,
  c.relrowsecurity rls, c.relforcerowsecurity force_rls, pg_total_relation_size(c.oid) bytes,
  obj_description(c.oid) comment
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('r','p','v','m','f')
  and n.nspname not in ('pg_catalog','information_schema','pg_toast')
order by 1, 3, 2;
```
