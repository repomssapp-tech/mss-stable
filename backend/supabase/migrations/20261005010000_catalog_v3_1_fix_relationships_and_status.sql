-- Migration: 20261005010000_catalog_v3_1_fix_relationships_and_status.sql
-- Description: Phase C Relationships & Status Fixes (Migration Audit Remediation)
-- 1. Insert matching parent_of for all 49 child_of rows lacking one and sync record_json references on parent schemes.
-- 2. Add bidirectional successor links between SCH000043 <-> SCH000302 and SCH000070 <-> SCH000258.
-- 3. Transition duplicate schemes (SCH000055, SCH000064, SCH000168) to ARCHIVED / false / closed and link to canonical rows.
-- 4. Update CGTMSE (SCH000038) guarantee ceiling to ₹10 crore with conditions and audit notes.
-- 5. Drop the 4 temporary v3.1 staging tables and staging view; enable FORCE ROW LEVEL SECURITY on scheme_source_v3_1.

-- ============================================================================
-- 1. PARENT_OF RELATIONSHIPS & RECORD_JSON SYNC (49 ROWS ACROSS 13 PARENTS)
-- ============================================================================

-- 1a. Update record_json.relationships.references on the 13 parent schemes
UPDATE catalog.scheme s
SET record_json = jsonb_set(
    s.record_json,
    '{relationships,references}',
    COALESCE(s.record_json->'relationships'->'references', '[]'::jsonb) || mp.new_refs
)
FROM (
    SELECT 
        c.target_id AS parent_id,
        jsonb_agg(
            jsonb_build_object(
                'entityId', c.source_id,
                'entityType', 'scheme',
                'relationType', 'parent_of'
            ) ORDER BY c.source_id
        ) AS new_refs
    FROM catalog.relationships c
    WHERE c.relationship_type = 'child_of'
      AND NOT EXISTS (
          SELECT 1 FROM catalog.relationships p
          WHERE p.relationship_type = 'parent_of'
            AND p.source_id = c.target_id
            AND p.target_id = c.source_id
      )
    GROUP BY c.target_id
) mp
WHERE s.id = mp.parent_id;

-- 1b. Insert the 49 missing parent_of rows into catalog.relationships
INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
SELECT 
    'scheme' AS source_type,
    c.target_id AS source_id,
    'scheme' AS target_type,
    c.source_id AS target_id,
    'parent_of' AS relationship_type,
    jsonb_build_object(
        'entityId', c.source_id,
        'entityType', 'scheme',
        'relationType', 'parent_of'
    ) AS metadata
FROM catalog.relationships c
WHERE c.relationship_type = 'child_of'
  AND NOT EXISTS (
      SELECT 1 FROM catalog.relationships p
      WHERE p.relationship_type = 'parent_of'
        AND p.source_id = c.target_id
        AND p.target_id = c.source_id
  );

-- ============================================================================
-- 2. SUCCESSOR LINKS (SCH000043 <-> SCH000302 and SCH000070 <-> SCH000258)
-- ============================================================================

INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
VALUES
('scheme', 'SCH000043', 'scheme', 'SCH000302', 'related_to', '{"relation": "successor", "entityId": "SCH000302", "entityType": "scheme", "relationType": "related_to"}'::jsonb),
('scheme', 'SCH000302', 'scheme', 'SCH000043', 'related_to', '{"relation": "successor", "entityId": "SCH000043", "entityType": "scheme", "relationType": "related_to"}'::jsonb),
('scheme', 'SCH000070', 'scheme', 'SCH000258', 'related_to', '{"relation": "successor", "entityId": "SCH000258", "entityType": "scheme", "relationType": "related_to"}'::jsonb),
('scheme', 'SCH000258', 'scheme', 'SCH000070', 'related_to', '{"relation": "successor", "entityId": "SCH000070", "entityType": "scheme", "relationType": "related_to"}'::jsonb);

UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000302", "entityType": "scheme", "relationType": "related_to", "relation": "successor"}]'::jsonb
)
WHERE id = 'SCH000043';

UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000043", "entityType": "scheme", "relationType": "related_to", "relation": "successor"}]'::jsonb
)
WHERE id = 'SCH000302';

UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000258", "entityType": "scheme", "relationType": "related_to", "relation": "successor"}]'::jsonb
)
WHERE id = 'SCH000070';

UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000070", "entityType": "scheme", "relationType": "related_to", "relation": "successor"}]'::jsonb
)
WHERE id = 'SCH000258';

-- ============================================================================
-- 3. ARCHIVED DUPLICATE SCHEMES (SCH000055, SCH000064, SCH000168)
-- ============================================================================

-- 3a. Update duplicate scheme statuses to ARCHIVED / false / closed
UPDATE catalog.scheme
SET 
    status = 'ARCHIVED',
    is_active = false,
    record_json = jsonb_set(record_json, '{identity,status}', '"closed"'::jsonb)
WHERE id IN ('SCH000055', 'SCH000064', 'SCH000168');

-- 3b. Insert inverse duplicate links in catalog.relationships
INSERT INTO catalog.relationships (source_type, source_id, target_type, target_id, relationship_type, metadata)
VALUES
('scheme', 'SCH000095', 'scheme', 'SCH000055', 'merged_from', '{"entityId": "SCH000055", "entityType": "scheme", "relationType": "merged_from", "role": "archived_duplicate"}'::jsonb),
('scheme', 'SCH000038', 'scheme', 'SCH000064', 'merged_from', '{"entityId": "SCH000064", "entityType": "scheme", "relationType": "merged_from", "role": "archived_duplicate"}'::jsonb),
('scheme', 'SCH000218', 'scheme', 'SCH000168', 'has_duplicate', '{"entityId": "SCH000168", "entityType": "scheme", "relationType": "has_duplicate", "role": "archived_duplicate"}'::jsonb)
ON CONFLICT DO NOTHING;

-- 3c. Update canonical schemes record_json.relationships.references
UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000055", "entityType": "scheme", "relationType": "merged_from"}]'::jsonb
)
WHERE id = 'SCH000095';

UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000064", "entityType": "scheme", "relationType": "merged_from"}]'::jsonb
)
WHERE id = 'SCH000038';

UPDATE catalog.scheme
SET record_json = jsonb_set(
    record_json,
    '{relationships,references}',
    COALESCE(record_json->'relationships'->'references', '[]'::jsonb) || 
    '[{"entityId": "SCH000168", "entityType": "scheme", "relationType": "has_duplicate"}]'::jsonb
)
WHERE id = 'SCH000218';

-- ============================================================================
-- 4. CGTMSE (SCH000038) GUARANTEE CEILING ENHANCEMENT
-- ============================================================================

UPDATE catalog.scheme
SET record_json = jsonb_set(
    jsonb_set(
        jsonb_set(
            record_json,
            '{content,benefits,guarantee,maxCoverInr}',
            '100000000'::jsonb
        ),
        '{content,benefits,guarantee,conditions}',
        COALESCE(record_json->'content'->'benefits'->'guarantee'->'conditions', '[]'::jsonb) || 
        '["Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025"]'::jsonb
    ),
    '{verification,notes}',
    to_jsonb(
        COALESCE(record_json->'verification'->>'notes', '') || 
        CASE 
            WHEN length(COALESCE(record_json->'verification'->>'notes', '')) > 0 THEN '; ' 
            ELSE '' 
        END || 
        '[reconciliation] Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025 (CGTMSE Circular No. 250 w.e.f. 01.04.2025, https://www.cgtmse.in/).'
    )
)
WHERE id = 'SCH000038';

-- ============================================================================
-- 5. STAGING CLEANUP (D6) & ROW LEVEL SECURITY HARDENING
-- ============================================================================

DROP VIEW IF EXISTS catalog.v_scheme_all;
DROP TABLE IF EXISTS catalog.scheme_new_v3_1;
DROP TABLE IF EXISTS catalog.applicability_matrix_new_v3_1;
DROP TABLE IF EXISTS catalog.search_index_new_v3_1;
DROP TABLE IF EXISTS catalog.relationships_new_v3_1;

ALTER TABLE catalog.scheme_source_v3_1 FORCE ROW LEVEL SECURITY;
