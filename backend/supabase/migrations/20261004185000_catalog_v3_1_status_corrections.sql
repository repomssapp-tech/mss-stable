-- Migration: catalog_v3_1_status_corrections
-- Created At: 2026-10-04T18:50:00Z
-- Purpose: Apply lifecycle status corrections, duplicate archives, and parent-child linkages from v3.1 audit worklist.
-- Conforms to: ANTIGRAVITY_PROMPT.md Phase 2 specifications.
-- Target tables: catalog.scheme, catalog.applicability_matrix, catalog.relationships.
-- Triggers will automatically update catalog.entity_registry and recompute checksums.

BEGIN;

-- ============================================================================
-- 1. SCH000043: Deendayal Antyodaya Yojana - National Urban Livelihoods Mission (DAY-NULM)
-- Ended 30.09.2024 (Lok Sabha reply 03.04.2025). Mark ARCHIVED / closed.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'ARCHIVED',
  is_active = false,
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        record_json,
        '{identity,status}',
        '"closed"'::jsonb
      ),
      '{metadata,catalogVersion}',
      '"1.35.0-alpha"'::jsonb
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%DAY-NULM ended 30.09.2024%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Status corrected to closed in v3.1 migration: DAY-NULM ended 30.09.2024 (Lok Sabha reply 03.04.2025); successor DAY Jan Aajeevika Yojana – Shehari"]'::jsonb
    END
  )
WHERE id = 'SCH000043';

UPDATE catalog.applicability_matrix
SET
  status = 'ARCHIVED',
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000043';

-- ============================================================================
-- 2. SCH000070: Interest Equalisation Scheme
-- Consolidated into Export Promotion Mission (Niryat Protsahan). Mark ARCHIVED / closed.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'ARCHIVED',
  is_active = false,
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        record_json,
        '{identity,status}',
        '"closed"'::jsonb
      ),
      '{metadata,catalogVersion}',
      '"1.35.0-alpha"'::jsonb
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%consolidated into Export Promotion Mission%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Status corrected to closed (merged) in v3.1 migration: Consolidated into Export Promotion Mission (Niryat Protsahan)"]'::jsonb
    END
  )
WHERE id = 'SCH000070';

UPDATE catalog.applicability_matrix
SET
  status = 'ARCHIVED',
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000070';

-- ============================================================================
-- 3. SCH000144: Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI)
-- Listed as active running scheme in Ministry of MSME Booklet 2025-26 p11. Promote to PUBLISHED / active.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'PUBLISHED',
  is_active = true,
  published_at = COALESCE(published_at, NOW()),
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        record_json,
        '{identity,status}',
        '"active"'::jsonb
      ),
      '{metadata,catalogVersion}',
      '"1.35.0-alpha"'::jsonb
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%SFURTI confirmed running%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Status promoted to PUBLISHED (active) in v3.1 migration: SFURTI confirmed running in Ministry of MSME Schemes Booklet 2025-26 p11"]'::jsonb
    END
  )
WHERE id = 'SCH000144';

UPDATE catalog.applicability_matrix
SET
  status = 'PUBLISHED',
  published_at = COALESCE(published_at, NOW()),
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000144';

-- ============================================================================
-- 4. SCH000076: Khadi Vikas Yojana
-- Component I of KGVY in booklet 2025-26 p28. Promote from DRAFT to PUBLISHED / active.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'PUBLISHED',
  is_active = true,
  published_at = COALESCE(published_at, NOW()),
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        record_json,
        '{identity,status}',
        '"active"'::jsonb
      ),
      '{metadata,catalogVersion}',
      '"1.35.0-alpha"'::jsonb
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%Khadi Vikas Yojana is component I of KGVY%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Promoted from DRAFT to PUBLISHED (active) in v3.1 migration: Khadi Vikas Yojana is component I of KGVY in booklet 2025-26 p28"]'::jsonb
    END
  )
WHERE id = 'SCH000076';

UPDATE catalog.applicability_matrix
SET
  status = 'PUBLISHED',
  published_at = COALESCE(published_at, NOW()),
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000076';

-- ============================================================================
-- 5. SCH000035: Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana
-- Component II of Coir Vikas Yojana in booklet 2025-26 p16. Promote from DRAFT to PUBLISHED / active.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'PUBLISHED',
  is_active = true,
  published_at = COALESCE(published_at, NOW()),
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        record_json,
        '{identity,status}',
        '"active"'::jsonb
      ),
      '{metadata,catalogVersion}',
      '"1.35.0-alpha"'::jsonb
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%Component II of Coir Vikas Yojana%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Promoted from DRAFT to PUBLISHED (active) in v3.1 migration: Component II of Coir Vikas Yojana in booklet 2025-26 p16"]'::jsonb
    END
  )
WHERE id = 'SCH000035';

UPDATE catalog.applicability_matrix
SET
  status = 'PUBLISHED',
  published_at = COALESCE(published_at, NOW()),
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000035';

-- ============================================================================
-- 6. SCH000168: Stand-Up India (Duplicate of SCH000218)
-- SCH000218 is canonical PUBLISHED row. Mark SCH000168 ARCHIVED and link to SCH000218.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'ARCHIVED',
  is_active = false,
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          record_json,
          '{identity,status}',
          '"archived"'::jsonb
        ),
        '{metadata,catalogVersion}',
        '"1.35.0-alpha"'::jsonb
      ),
      '{relationships,references}',
      CASE
        WHEN record_json->'relationships'->'references' @> '[{"entityId": "SCH000218"}]'::jsonb THEN record_json->'relationships'->'references'
        ELSE COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || '[{"entityId": "SCH000218", "entityType": "scheme", "relationType": "duplicate_of"}]'::jsonb
      END
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%duplicate of SCH000218%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Marked ARCHIVED as duplicate of canonical SCH000218 in v3.1 migration"]'::jsonb
    END
  )
WHERE id = 'SCH000168';

UPDATE catalog.applicability_matrix
SET
  status = 'ARCHIVED',
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000168';

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000168', 'scheme', 'SCH000218', 'associated_with', '{"note": "duplicate of canonical SCH000218"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000168' AND target_id = 'SCH000218' AND relationship_type = 'associated_with'
);

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000218', 'scheme', 'SCH000168', 'associated_with', '{"note": "canonical for duplicate SCH000168"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000218' AND target_id = 'SCH000168' AND relationship_type = 'associated_with'
);

-- ============================================================================
-- 7. SCH000055: ESDP Duplicate (Canonical is SCH000095)
-- Mark SCH000055 ARCHIVED and link to canonical SCH000095.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'ARCHIVED',
  is_active = false,
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          record_json,
          '{identity,status}',
          '"archived"'::jsonb
        ),
        '{metadata,catalogVersion}',
        '"1.35.0-alpha"'::jsonb
      ),
      '{relationships,references}',
      CASE
        WHEN record_json->'relationships'->'references' @> '[{"entityId": "SCH000095"}]'::jsonb THEN record_json->'relationships'->'references'
        ELSE COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || '[{"entityId": "SCH000095", "entityType": "scheme", "relationType": "merged_into"}]'::jsonb
      END
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%duplicate of canonical SCH000095%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Marked ARCHIVED as duplicate of canonical SCH000095 (ESDP) in v3.1 migration"]'::jsonb
    END
  )
WHERE id = 'SCH000055';

UPDATE catalog.applicability_matrix
SET
  status = 'ARCHIVED',
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000055';

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000055', 'scheme', 'SCH000095', 'associated_with', '{"note": "duplicate of canonical SCH000095"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000055' AND target_id = 'SCH000095' AND relationship_type = 'associated_with'
);

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000095', 'scheme', 'SCH000055', 'associated_with', '{"note": "canonical for duplicate SCH000055"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000095' AND target_id = 'SCH000055' AND relationship_type = 'associated_with'
);

-- ============================================================================
-- 8. SCH000064: Guarantee Schemes for MSEs (Duplicate of SCH000038 CGTMSE)
-- Mark SCH000064 ARCHIVED and link to canonical SCH000038.
-- ============================================================================
UPDATE catalog.scheme
SET
  status = 'ARCHIVED',
  is_active = false,
  version = '1.35.0-alpha',
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          record_json,
          '{identity,status}',
          '"archived"'::jsonb
        ),
        '{metadata,catalogVersion}',
        '"1.35.0-alpha"'::jsonb
      ),
      '{relationships,references}',
      CASE
        WHEN record_json->'relationships'->'references' @> '[{"entityId": "SCH000038"}]'::jsonb THEN record_json->'relationships'->'references'
        ELSE COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || '[{"entityId": "SCH000038", "entityType": "scheme", "relationType": "merged_into"}]'::jsonb
      END
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%duplicate of canonical SCH000038%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Marked ARCHIVED as generic duplicate of canonical SCH000038 (CGTMSE) in v3.1 migration"]'::jsonb
    END
  )
WHERE id = 'SCH000064';

UPDATE catalog.applicability_matrix
SET
  status = 'ARCHIVED',
  version = '1.35.0-alpha',
  updated_at = NOW()
WHERE scheme_id = 'SCH000064';

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000064', 'scheme', 'SCH000038', 'associated_with', '{"note": "duplicate of canonical SCH000038"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000064' AND target_id = 'SCH000038' AND relationship_type = 'associated_with'
);

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000038', 'scheme', 'SCH000064', 'associated_with', '{"note": "canonical for duplicate SCH000064"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000038' AND target_id = 'SCH000064' AND relationship_type = 'associated_with'
);

-- ============================================================================
-- 9. SCH000082 (Mahila Coir Yojana) & SCH000035 (Coir Vikas Yojana) Linking
-- Establish parent-child relationship between SCH000082 and SCH000035.
-- ============================================================================
UPDATE catalog.scheme
SET
  updated_at = NOW(),
  record_json = jsonb_set(
    jsonb_set(
      record_json,
      '{relationships,references}',
      CASE
        WHEN record_json->'relationships'->'references' @> '[{"entityId": "SCH000035"}]'::jsonb THEN record_json->'relationships'->'references'
        ELSE COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || '[{"entityId": "SCH000035", "entityType": "scheme", "relationType": "child_of"}]'::jsonb
      END
    ),
    '{provenance,transformationNotes}',
    CASE
      WHEN (record_json->'provenance'->'transformationNotes')::text LIKE '%child of SCH000035%' THEN record_json->'provenance'->'transformationNotes'
      ELSE COALESCE(record_json->'provenance'->'transformationNotes', '[]'::jsonb) || '["Linked as child of SCH000035 (Coir Vikas Yojana) in v3.1 migration"]'::jsonb
    END
  )
WHERE id = 'SCH000082';

UPDATE catalog.scheme
SET
  updated_at = NOW(),
  record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    CASE
      WHEN record_json->'relationships'->'references' @> '[{"entityId": "SCH000082"}]'::jsonb THEN record_json->'relationships'->'references'
      ELSE COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || '[{"entityId": "SCH000082", "entityType": "scheme", "relationType": "parent_of"}]'::jsonb
    END
  )
WHERE id = 'SCH000035';

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000082', 'scheme', 'SCH000035', 'child_of', '{"note": "component of Coir Vikas Yojana"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000082' AND target_id = 'SCH000035' AND relationship_type = 'child_of'
);

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 'scheme', 'SCH000035', 'scheme', 'SCH000082', 'parent_of', '{"note": "parent of Mahila Coir Yojana"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM catalog.relationships WHERE source_id = 'SCH000035' AND target_id = 'SCH000082' AND relationship_type = 'parent_of'
);

COMMIT;

/*
-- ============================================================================
-- DOWN MIGRATION (ROLLBACK INSTRUCTIONS)
-- To revert this migration, run the following SQL block:
-- ============================================================================

BEGIN;

-- Revert SCH000043 to PUBLISHED
UPDATE catalog.scheme SET status = 'PUBLISHED', is_active = true, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"active"'::jsonb) WHERE id = 'SCH000043';
UPDATE catalog.applicability_matrix SET status = 'PUBLISHED', updated_at = NOW() WHERE scheme_id = 'SCH000043';

-- Revert SCH000070 to PUBLISHED
UPDATE catalog.scheme SET status = 'PUBLISHED', is_active = true, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"active"'::jsonb) WHERE id = 'SCH000070';
UPDATE catalog.applicability_matrix SET status = 'PUBLISHED', updated_at = NOW() WHERE scheme_id = 'SCH000070';

-- Revert SCH000144 to ARCHIVED
UPDATE catalog.scheme SET status = 'ARCHIVED', is_active = false, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"closed"'::jsonb) WHERE id = 'SCH000144';
UPDATE catalog.applicability_matrix SET status = 'ARCHIVED', updated_at = NOW() WHERE scheme_id = 'SCH000144';

-- Revert SCH000076 to DRAFT
UPDATE catalog.scheme SET status = 'DRAFT', is_active = false, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"unknown"'::jsonb) WHERE id = 'SCH000076';
UPDATE catalog.applicability_matrix SET status = 'DRAFT', updated_at = NOW() WHERE scheme_id = 'SCH000076';

-- Revert SCH000035 to DRAFT
UPDATE catalog.scheme SET status = 'DRAFT', is_active = false, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"unknown"'::jsonb) WHERE id = 'SCH000035';
UPDATE catalog.applicability_matrix SET status = 'DRAFT', updated_at = NOW() WHERE scheme_id = 'SCH000035';

-- Revert SCH000168 to DRAFT
UPDATE catalog.scheme SET status = 'DRAFT', is_active = false, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"unknown"'::jsonb) WHERE id = 'SCH000168';
UPDATE catalog.applicability_matrix SET status = 'DRAFT', updated_at = NOW() WHERE scheme_id = 'SCH000168';

-- Revert SCH000055 to PUBLISHED
UPDATE catalog.scheme SET status = 'PUBLISHED', is_active = true, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"active"'::jsonb) WHERE id = 'SCH000055';
UPDATE catalog.applicability_matrix SET status = 'PUBLISHED', updated_at = NOW() WHERE scheme_id = 'SCH000055';

-- Revert SCH000064 to PUBLISHED
UPDATE catalog.scheme SET status = 'PUBLISHED', is_active = true, updated_at = NOW(),
  record_json = jsonb_set(record_json, '{identity,status}', '"active"'::jsonb) WHERE id = 'SCH000064';
UPDATE catalog.applicability_matrix SET status = 'PUBLISHED', updated_at = NOW() WHERE scheme_id = 'SCH000064';

-- Remove created relationship edges
DELETE FROM catalog.relationships WHERE 
  (source_id = 'SCH000082' AND target_id = 'SCH000035') OR
  (source_id = 'SCH000035' AND target_id = 'SCH000082') OR
  (source_id = 'SCH000055' AND target_id = 'SCH000095') OR
  (source_id = 'SCH000095' AND target_id = 'SCH000055') OR
  (source_id = 'SCH000064' AND target_id = 'SCH000038') OR
  (source_id = 'SCH000038' AND target_id = 'SCH000064') OR
  (source_id = 'SCH000168' AND target_id = 'SCH000218') OR
  (source_id = 'SCH000218' AND target_id = 'SCH000168');

COMMIT;
*/

