# GATE C VERIFICATION REPORT: RELATIONSHIPS & STATUS FIXES

**Date:** 2026-10-05  
**Target:** Supabase Linked Database (`houpzsxmwemoztpuigmo`)  
**Branch:** `data/catalog-v3-1-migration`  
**Migration File:** `backend/supabase/migrations/20261005010000_catalog_v3_1_fix_relationships_and_status.sql`  

---

## 1. Executive Gate C Verdict

| Check Item | Target Requirement | Measured Live DB Result | Status |
| :--- | :--- | :--- | :--- |
| **Relationship Symmetry** | Asymmetric count = 0 | **`asymmetric_child_of`: 0, `asymmetric_parent_of`: 0** (85 symmetric pairs) | **PASS (100%)** |
| **Status Matrix** | Only 3 allowed combinations | **Exactly 3 combinations across 302 schemes: 155 PUBLISHED / 131 DRAFT / 16 ARCHIVED** | **PASS (100%)** |
| **Successor Links** | 2 bidirectional successor pairs | **4 rows in `catalog.relationships` with `relation: successor`** | **PASS (100%)** |
| **CGTMSE (SCH000038)** | Ceiling ₹10 Cr, conditions, note | **`maxCoverInr = 100000000`, condition added, notes appended** | **PASS (100%)** |
| **Staging Cleanup** | Drop 4 staging tables + preview view | **0 staging tables, 0 staging views, `force_rls = true` on `scheme_source_v3_1`** | **PASS (100%)** |

---

## 2. Gate C Raw Query Outputs & Proofs

### Check 1: Relationship Symmetry (Asymmetric Count = 0)
**Live Query:**
```sql
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
```

**Raw Database Output:**
```json
{
  "total_child_of": 85,
  "total_parent_of": 85,
  "asymmetric_child_of": 0,
  "asymmetric_parent_of": 0
}
```

---

### Check 2: Status Matrix (Only 3 Allowed Combinations)
**Live Query:**
```sql
SELECT 
    status, 
    is_active, 
    record_json->'identity'->>'status' as json_identity_status,
    count(*) as count,
    array_agg(id ORDER BY id) as ids
FROM catalog.scheme 
GROUP BY status, is_active, record_json->'identity'->>'status'
ORDER BY count DESC;
```

**Raw Database Output:**
```text
  PUBLISHED    | is_active=True  | json=active   | count=155
  DRAFT        | is_active=False | json=unknown  | count=131
  ARCHIVED     | is_active=False | json=closed   | count=16
```
*(Total schemes: 155 + 131 + 16 = 302 schemes. Exactly 0 rows outside the 3 allowed combinations).*

---

### Check 3: Successor Relationships
**Live Query:**
```sql
SELECT source_id, target_id, relationship_type, metadata
FROM catalog.relationships
WHERE (source_id = 'SCH000043' AND target_id = 'SCH000302')
   OR (source_id = 'SCH000302' AND target_id = 'SCH000043')
   OR (source_id = 'SCH000070' AND target_id = 'SCH000258')
   OR (source_id = 'SCH000258' AND target_id = 'SCH000070')
ORDER BY source_id;
```

**Raw Database Output:**
```json
[
  {
    "source_id": "SCH000043",
    "target_id": "SCH000302",
    "relationship_type": "related_to",
    "metadata": {
      "relation": "successor",
      "entityId": "SCH000302",
      "entityType": "scheme",
      "relationType": "related_to"
    }
  },
  {
    "source_id": "SCH000070",
    "target_id": "SCH000258",
    "relationship_type": "related_to",
    "metadata": {
      "relation": "successor",
      "entityId": "SCH000258",
      "entityType": "scheme",
      "relationType": "related_to"
    }
  },
  {
    "source_id": "SCH000258",
    "target_id": "SCH000070",
    "relationship_type": "related_to",
    "metadata": {
      "relation": "successor",
      "entityId": "SCH000070",
      "entityType": "scheme",
      "relationType": "related_to"
    }
  },
  {
    "source_id": "SCH000302",
    "target_id": "SCH000043",
    "relationship_type": "related_to",
    "metadata": {
      "relation": "successor",
      "entityId": "SCH000043",
      "entityType": "scheme",
      "relationType": "related_to"
    }
  }
]
```

---

### Check 4: CGTMSE (SCH000038) Guarantee Ceiling & Conditions
**Live Query:**
```sql
SELECT 
    id, 
    record_json->'content'->'benefits'->'guarantee'->'maxCoverInr' as max_cover_inr,
    record_json->'content'->'benefits'->'guarantee'->'conditions' as conditions,
    record_json->'verification'->'notes' as verification_notes
FROM catalog.scheme 
WHERE id = 'SCH000038';
```

**Raw Database Output:**
```json
{
  "id": "SCH000038",
  "max_cover_inr": 100000000,
  "conditions": [
    "Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025"
  ],
  "verification_notes": "[agent_flag] Booklet text obtained via WebFetch extraction (fetch model declined full verbatim reproduction); quotes are short phrases returned as evidence, not checked against the PDF by eye.; [agent_flag] Booklet coverage table (category x slab) came back garbled from WebFetch (inconsistent column mapping) — per-category % not recorded; only 75%-90% range, ICDD +5%, women-led 90%.; [agent_flag] cgtmse.in fetch failed (timeout); specific new AGF rates not captured.; [agent_flag] Catalog SCH000064 'Guarantee Schemes for MSEs' may be the same scheme — not linked.; [reconciliation] Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025 (CGTMSE Circular No. 250 w.e.f. 01.04.2025, https://www.cgtmse.in/)."
}
```

---

### Check 5: Staging Tables Drop & RLS Hardening
**Live Query:**
```sql
SELECT 
    (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'catalog' AND table_name IN ('scheme_new_v3_1', 'applicability_matrix_new_v3_1', 'search_index_new_v3_1', 'relationships_new_v3_1')) as remaining_staging_tables,
    (SELECT count(*) FROM information_schema.views WHERE table_schema = 'catalog' AND table_name = 'v_scheme_all') as remaining_staging_views,
    (SELECT relrowsecurity FROM pg_class WHERE relname = 'scheme_source_v3_1' AND relnamespace = 'catalog'::regnamespace) as source_rls_enabled,
    (SELECT relforcerowsecurity FROM pg_class WHERE relname = 'scheme_source_v3_1' AND relnamespace = 'catalog'::regnamespace) as source_force_rls;
```

**Raw Database Output:**
```json
{
  "remaining_staging_tables": 0,
  "remaining_staging_views": 0,
  "source_rls_enabled": true,
  "source_force_rls": true
}
```

---

### Check 6: Columns on New Schemes (Phase A Query 3 Baseline for Phase D)
**Live Query:**
```sql
SELECT 
    count(*) as total_new,
    count(*) FILTER (WHERE scheme_type IS NULL) as null_scheme_type,
    count(*) FILTER (WHERE government_level IS NULL) as null_government_level,
    count(*) FILTER (WHERE ministry IS NULL) as null_ministry,
    count(*) FILTER (WHERE department IS NULL) as null_department,
    count(*) FILTER (WHERE name_ta IS NULL) as null_name_ta
FROM catalog.scheme 
WHERE id >= 'SCH000220' AND id <= 'SCH000302';
```

**Raw Database Output:**
```json
{
  "total_new": 83,
  "null_scheme_type": 83,
  "null_government_level": 83,
  "null_ministry": 83,
  "null_department": 83,
  "null_name_ta": 83
}
```
*(Note: These 83 new records' relational columns will be populated from `content.classification` during Phase D data migration `<ts>_catalog_v3_1_reshape_new_records.sql`)*.
