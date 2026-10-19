-- ==========================================================================
-- MIGRATION: 20261004201500_catalog_v3_1_rewire_to_production.sql
-- Purpose: Merge staged schemes (SCH000220 - SCH000302) into production catalog.
-- ==========================================================================
BEGIN;

-- 1. Insert/Update Staged Schemes into catalog.scheme
INSERT INTO catalog.scheme (
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_code, name_en, name_ta, government_level, scheme_type, state,
    ministry, department, search_keywords, primary_authority_id,
    primary_institution_id, is_active, scheme_url
)
SELECT 
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_code, name_en, name_ta, government_level, scheme_type, state,
    ministry, department, search_keywords, primary_authority_id,
    primary_institution_id, is_active, scheme_url
FROM catalog.scheme_new_v3_1
ON CONFLICT (id) DO UPDATE SET
    version = EXCLUDED.version,
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at,
    published_at = EXCLUDED.published_at,
    record_json = EXCLUDED.record_json,
    scheme_code = EXCLUDED.scheme_code,
    name_en = EXCLUDED.name_en,
    name_ta = EXCLUDED.name_ta,
    government_level = EXCLUDED.government_level,
    scheme_type = EXCLUDED.scheme_type,
    state = EXCLUDED.state,
    ministry = EXCLUDED.ministry,
    department = EXCLUDED.department,
    search_keywords = EXCLUDED.search_keywords,
    primary_authority_id = EXCLUDED.primary_authority_id,
    primary_institution_id = EXCLUDED.primary_institution_id,
    is_active = EXCLUDED.is_active,
    scheme_url = EXCLUDED.scheme_url;

-- 2. Insert/Update Applicability Matrix
INSERT INTO catalog.applicability_matrix (
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_id, government_level, department_authority_id, sector_text, district_text
)
SELECT 
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_id, government_level, department_authority_id, sector_text, district_text
FROM catalog.applicability_matrix_new_v3_1
ON CONFLICT (id) DO UPDATE SET
    record_json = EXCLUDED.record_json,
    updated_at = EXCLUDED.updated_at;

-- 3. Insert/Update Search Index
INSERT INTO catalog.search_index (
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_id, content, embedding
)
SELECT 
    id, version, status, checksum, updated_at, published_at, record_json,
    scheme_id, content, embedding
FROM catalog.search_index_new_v3_1
ON CONFLICT (id) DO UPDATE SET
    record_json = EXCLUDED.record_json,
    content = EXCLUDED.content,
    updated_at = EXCLUDED.updated_at;

-- 4. Insert Relationships
INSERT INTO catalog.relationships (
    id, source_type, source_id, target_type, target_id, relationship_type, metadata, created_at
)
SELECT 
    id, source_type, source_id, target_type, target_id, relationship_type, metadata, created_at
FROM catalog.relationships_new_v3_1
ON CONFLICT (id) DO NOTHING;

COMMIT;
