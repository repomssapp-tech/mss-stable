================================================================================
GATE D DELIVERABLE REPORT: SCHEMA_MIGRATIONS & LIVE PRODUCTION RE-AUDIT
================================================================================

================================================================================
GATE D DELIVERABLE 1: SCHEMA_MIGRATIONS AUDIT
================================================================================
Total Local Migration Files: 82
Total Recorded in DB schema_migrations: 82
Local files not recorded in DB: 0
Remote versions with no local file: 0

--> [PASS] 100% PARITY: Every local migration file is recorded in schema_migrations (82/82 files)!

Complete Recorded Migrations Listing (Remote vs Local):
| # | Version | Local Migration Filename | Status in DB |
|:---|:---|:---|:---|
| 01 | `20260714061757` | `20260714061757_001_extensions.sql` | `applied` |
| 02 | `20260714061803` | `20260714061803_002_users.sql` | `applied` |
| 03 | `20260714061808` | `20260714061808_003_startup_profiles.sql` | `applied` |
| 04 | `20260714061812` | `20260714061812_004_schemes.sql` | `applied` |
| 05 | `20260714061815` | `20260714061815_005_documents.sql` | `applied` |
| 06 | `20260714061819` | `20260714061819_006_questionnaire.sql` | `applied` |
| 07 | `20260714061823` | `20260714061823_007_services.sql` | `applied` |
| 08 | `20260714061831` | `20260714061831_008_recommendations.sql` | `applied` |
| 09 | `20260714061835` | `20260714061835_009_search.sql` | `applied` |
| 10 | `20260714061839` | `20260714061839_010_notifications.sql` | `applied` |
| 11 | `20260714061844` | `20260714061844_011_admin.sql` | `applied` |
| 12 | `20260714061847` | `20260714061847_012_indexes.sql` | `applied` |
| 13 | `20260714061850` | `20260714061850_013_rls.sql` | `applied` |
| 14 | `20260714061855` | `20260714061855_functions.sql` | `applied` |
| 15 | `20260714061860` | `20260714061860_hardening.sql` | `applied` |
| 16 | `20260714061865` | `20260714061865_profile_extensions.sql` | `applied` |
| 17 | `20260727000100` | `20260727000100_admin_foundation.sql` | `applied` |
| 18 | `20260727000200` | `20260727000200_fix_recommend_schemes.sql` | `applied` |
| 19 | `20260727000300` | `20260727000300_api_table_grants.sql` | `applied` |
| 20 | `20260728150000` | `20260728150000_create_profiles.sql` | `applied` |
| 21 | `20260728160000` | `20260728160000_unify_user_profiles.sql` | `applied` |
| 22 | `20260730090000` | `20260730090000_catalog_releases.sql` | `applied` |
| 23 | `20260731120000` | `20260731120000_create_promo_alerts.sql` | `applied` |
| 24 | `20260805000000` | `20260805000000_database_architecture_v2.sql` | `applied` |
| 25 | `20260806113000` | `20260806113000_self_delete_user.sql` | `applied` |
| 26 | `20260812112500` | `20260812112500_profiles_self_insert_policy.sql` | `applied` |
| 27 | `20260815120000` | `20260815120000_enable_realtime_profiles_notifications.sql` | `applied` |
| 28 | `20260816130000` | `20260816130000_recreate_promo_alerts.sql` | `applied` |
| 29 | `20260816140000` | `20260816140000_catalog_meta_function.sql` | `applied` |
| 30 | `20260817000000` | `20260817000000_catalog_parity_closure.sql` | `applied` |
| 31 | `20260817010000` | `20260817010000_catalog_meta_function_v2.sql` | `applied` |
| 32 | `20260817020000` | `20260817020000_search_and_scheme_detail_rpcs.sql` | `applied` |
| 33 | `20260817030000` | `20260817030000_remaining_api_rpcs.sql` | `applied` |
| 34 | `20260817040000` | `20260817040000_eligibility_rpc.sql` | `applied` |
| 35 | `20260817050000` | `20260817050000_release_artifact_columns.sql` | `applied` |
| 36 | `20260817060000` | `20260817060000_current_release_rpc.sql` | `applied` |
| 37 | `20260817070000` | `20260817070000_release_byte_size.sql` | `applied` |
| 38 | `20260818000000` | `20260818000000_restore_orphaned_rls_policies.sql` | `applied` |
| 39 | `20260818010000` | `20260818010000_add_profile_religion_and_first_gen.sql` | `applied` |
| 40 | `20260827000000` | `20260827000000_optimize_search_rpc_and_security.sql` | `applied` |
| 41 | `20260827010000` | `20260827010000_free_tier_resource_limits.sql` | `applied` |
| 42 | `20260828000000` | `20260828000000_persistent_rate_limiter.sql` | `applied` |
| 43 | `20260828100735` | `20260828100735_revoke_public_search_rpc_execute.sql` | `applied` |
| 44 | `20260828160000` | `20260828160000_create_chat_logs_table.sql` | `applied` |
| 45 | `20260828160500` | `20260828160500_lock_down_remaining_catalog_rpcs.sql` | `applied` |
| 46 | `20260828170000` | `20260828170000_lock_down_catalogs_storage_bucket.sql` | `applied` |
| 47 | `20260829160000` | `20260829160000_harden_exposed_functions.sql` | `applied` |
| 48 | `20260901000000` | `20260901000000_lockdown_chat_logs_and_profiles_anon.sql` | `applied` |
| 49 | `20260901000100` | `20260901000100_rls_policy_cleanup_relationships_admin_promo.sql` | `applied` |
| 50 | `20260901000200` | `20260901000200_reconcile_orphan_tables.sql` | `applied` |
| 51 | `20260901000300` | `20260901000300_normalize_delete_user_search_path.sql` | `applied` |
| 52 | `20260901000400` | `20260901000400_force_row_level_security.sql` | `applied` |
| 53 | `20260901000500` | `20260901000500_rls_drift_guard.sql` | `applied` |
| 54 | `20260904000000` | `20260904000000_catalog_row_checksum_trigger.sql` | `applied` |
| 55 | `20260904010000` | `20260904010000_rpc_status_filter_and_indexes.sql` | `applied` |
| 56 | `20260904020000` | `20260904020000_chat_logs_user_id_binding.sql` | `applied` |
| 57 | `20260905000000` | `20260905000000_fix_mistagged_scheme_intent_tags.sql` | `applied` |
| 58 | `20260905000100` | `20260905000100_create_voice_chat_sessions_table.sql` | `applied` |
| 59 | `20260905061021` | `20260905061021_require_auth_for_voice_sessions.sql` | `applied` |
| 60 | `20260905061235` | `20260905061235_archive_legacy_chat_logs.sql` | `applied` |
| 61 | `20260905080538` | `20260905080538_archive_zero_row_scaffold_tables.sql` | `applied` |
| 62 | `20260905080758` | `20260905080758_revoke_catalog_defense_in_depth_grants.sql` | `applied` |
| 63 | `20260905081606` | `20260905081606_index_search_index_scheme_id.sql` | `applied` |
| 64 | `20260905111658` | `20260905111658_restore_load_bearing_rbac_tables.sql` | `applied` |
| 65 | `20260905122008` | `20260905122008_populate_and_sync_entity_registry.sql` | `applied` |
| 66 | `20260905143106` | `20260905143106_rollback_catalog_release_rpc.sql` | `applied` |
| 67 | `20260905143830` | `20260905143830_add_msme_privilege_and_business_enablement_entries.sql` | `applied` |
| 68 | `20260906000000` | `20260906000000_create_support_tickets_table.sql` | `applied` |
| 69 | `20260906000100` | `20260906000100_document_voice_chat_transcript_recommendations.sql` | `applied` |
| 70 | `20260906010000` | `20260906010000_add_profile_education_level_and_address.sql` | `applied` |
| 71 | `20260906020000` | `20260906020000_drop_redundant_profile_address_columns.sql` | `applied` |
| 72 | `20260907000000` | `20260907000000_ensure_profiles_columns.sql` | `applied` |
| 73 | `20260907100000` | `20260907100000_create_beta_gate_config.sql` | `applied` |
| 74 | `20260907132318` | `20260907132318_add_legal_acceptance_to_profiles.sql` | `applied` |
| 75 | `20260908120000` | `20260908120000_scheme_url_and_drop_funding_columns.sql` | `applied` |
| 76 | `20261004185000` | `20261004185000_catalog_v3_1_status_corrections.sql` | `applied` |
| 77 | `20261004192000` | `20261004192000_catalog_v3_1_enrich_existing.sql` | `applied` |
| 78 | `20261004193500` | `20261004193500_catalog_v3_1_add_schemes.sql` | `applied` |
| 79 | `20261004200000` | `20261004200000_catalog_v3_1_staging_and_source.sql` | `applied` |
| 80 | `20261004201500` | `20261004201500_catalog_v3_1_rewire_to_production.sql` | `applied` |
| 81 | `20261005010000` | `20261005010000_catalog_v3_1_fix_relationships_and_status.sql` | `applied` |
| 82 | `20261005011500` | `20261005011500_catalog_v3_1_reshape_new_records.sql` | `applied` |

================================================================================
PHASE A QUERY 1: KEY-SHAPE DIFF (depth <= 4) ON SCHEME RECORD_JSON
================================================================================
Old schemes in DB: 219, New schemes in DB: 83
Keys present in ALL 219 old schemes but MISSING in any new scheme (14):
  - ai.sectionSummaries.eligibility
  - provenance.translations.ta
  - provenance.translations.ta.dictionaryVersion
  - provenance.translations.ta.engine
  - provenance.translations.ta.fieldMethods
  - provenance.translations.ta.fieldsContextual
  - provenance.translations.ta.fieldsPending
  - provenance.translations.ta.fieldsTranslated
  - provenance.translations.ta.generatedAt
  - provenance.translations.ta.isApproved
  - provenance.translations.ta.method
  - provenance.translations.ta.note
  - provenance.translations.ta.reviewRequired
  - provenance.translations.ta.status
Keys EXTRA in new schemes (never present in old schemes) (0):

================================================================================
PHASE A QUERY 2: RELATIONSHIP SYMMETRY
================================================================================
Query:
SELECT 
        (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'child_of') as total_child_of,
        (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'parent_of') as total_parent_of,
        (SELECT count(*) FROM catalog.relationships c 
         WHERE c.relationship_type = 'child_of' 
         AND NOT EXISTS (
             SELECT 1 FROM catalog.relationships p 
             WHERE p.relationship_type = 'parent_of' 
             AND p.source_id = c.target_id 
             AND p.target_id = c.source_id
         )) as asymmetric_child_of,
        (SELECT count(*) FROM catalog.relationships p 
         WHERE p.relationship_type = 'parent_of' 
         AND NOT EXISTS (
             SELECT 1 FROM catalog.relationships c 
             WHERE c.relationship_type = 'child_of' 
             AND c.source_id = p.target_id 
             AND c.target_id = p.source_id
         )) as asymmetric_parent_of;

Raw Output:
{
  "asymmetric_child_of": 0,
  "asymmetric_parent_of": 0,
  "total_child_of": 85,
  "total_parent_of": 85
}
--> [PASS] 0 Asymmetric relationships! (100% symmetric pair verification)

================================================================================
PHASE A QUERY 3: COLUMNS ON NEW SCHEMES (SCH000220 - SCH000302)
================================================================================
Query:
SELECT 
        count(*) as total_new,
        count(*) FILTER (WHERE scheme_type IS NULL) as null_scheme_type,
        count(*) FILTER (WHERE government_level IS NULL) as null_government_level,
        count(*) FILTER (WHERE ministry IS NULL) as null_ministry,
        count(*) FILTER (WHERE department IS NULL) as null_department,
        count(*) FILTER (WHERE name_ta IS NULL) as null_name_ta
    FROM catalog.scheme 
    WHERE id >= 'SCH000220' AND id <= 'SCH000302';

Raw Output:
{
  "null_department": 0,
  "null_government_level": 0,
  "null_ministry": 0,
  "null_name_ta": 83,
  "null_scheme_type": 0,
  "total_new": 83
}
--> [PASS] All relational columns populated! Exactly 0 nulls across scheme_type, government_level, ministry, department.

================================================================================
PHASE A QUERY 4: STATUS MATRIX (All 302 schemes)
================================================================================
Query:
SELECT 
        status, 
        is_active, 
        record_json->'identity'->>'status' as json_identity_status,
        count(*) as count
    FROM catalog.scheme 
    GROUP BY status, is_active, record_json->'identity'->>'status'
    ORDER BY count DESC;

Raw Output:
  PUBLISHED    | is_active=True  | json=active   | count=155
  DRAFT        | is_active=False | json=unknown  | count=131
  ARCHIVED     | is_active=False | json=closed   | count=16

--> [PASS] Status matrix has ONLY the three allowed combinations: {PUBLISHED/true/active, DRAFT/false/unknown, ARCHIVED/false/closed}

================================================================================
PHASE A QUERY 6: GIT STATE
================================================================================
Git Status:
 M .gitattributes
 M CLAUDE.md
 M backend/catalog/search_parity_golden.json
 M backend/scripts/generate_catalog_import_sql.js
 M frontend/assets/catalog/catalog_bundle.json.gz
 M frontend/assets/catalog/release.json
 M frontend/lib/l10n/app_localizations_ta.dart
 M frontend/test/discover_counts_test.dart
 M frontend/test/fixtures/scheme_search_rank_stability_expected.json
 M frontend/test/mss_catalog_bundle_test.dart
 M frontend/test/mss_catalog_mapping_test.dart
 M saarthi-agent/data/scheme_catalog.json
 M saarthi-agent/data/search_index.json
 M tools/publish_catalog_release.py
?? .claude/
?? backend/supabase/migrations/20261004185000_catalog_v3_1_status_corrections.sql
?? backend/supabase/migrations/20261004192000_catalog_v3_1_enrich_existing.sql
?? backend/supabase/migrations/20261004193500_catalog_v3_1_add_schemes.sql
?? backend/supabase/migrations/20261004200000_catalog_v3_1_staging_and_source.sql
?? backend/supabase/migrations/20261004201500_catalog_v3_1_rewire_to_production.sql
?? backend/supabase/migrations/20261005010000_catalog_v3_1_fix_relationships_and_status.sql
?? backend/supabase/migrations/20261005011500_catalog_v3_1_reshape_new_records.sql
?? backend/tmp.sql
?? backend/tmp_check_effects.sql
?? backend/tmp_check_mig.sql
?? backend/tmp_test_migration.sql
?? backend/tmp_test_reshape.sql
?? docs/APP_OVERVIEW.md
?? "docs/MSS Software Development Document V2.pdf"
?? "docs/MSS Software Development Document V3.pdf"
?? "docs/MSS Software Development Document.pdf"
?? docs/PRODUCT_DESIGN.md
?? docs/SOFTWARE_DEVELOPMENT_DOCUMENT.md
?? docs/audit/ANTIGRAVITY_FIX_PROMPT.md
?? docs/audit/CATALOG_V3_1_AUDIT.md
?? docs/audit/GATE_B_REVIEW.md
?? docs/backend/ANTIGRAVITY_FIX_PROMPT.md
?? docs/backend/ANTIGRAVITY_PROMPT.md
?? docs/backend/CATALOG_V3_1_AUDIT.md
?? docs/backend/CATALOG_V3_1_MIGRATION_REPORT.md
?? docs/backend/mss_scheme_data_v3_1/
?? docs/catalog_v3_1_mapping.md
?? docs/web-handoff/
?? graphify-out/
?? reports/
?? scripts/
?? skills-lock.json

Commits on branch above main: 35
