# Catalog v3.1 Migration: Formal Decision Record

**Date:** 2026-10-05  
**Branch:** `data/catalog-v3-1-migration`  
**Status:** Approved by User  

---

## 1. Authority Catalog Allocation: Option A (Approved)

### Context
Ten newly added central schemes in v3.1 (`SCH000275`, `SCH000278`, `SCH000279`, `SCH000286`, `SCH000288`, `SCH000289`, `SCH000290`, `SCH000291`, `SCH000299`, `SCH000300`) belong to central ministries outside the 124 authorities initially present in `authority_catalog.json`.

In the mobile app, `SchemeHeaderResolver.resolve()` checks `gov['ministryId'] != null` to render the ministry badge. Leaving `ministryId: null` resulted in missing ministry badges in the UI.

### Decision
**Option A Approved:** Add the 7 Central Ministries to `authority_catalog.json` (`AUTH000125`–`AUTH000131`) and map them in `content.classification.government.ministryId` across the 10 schemes.

### Authority Mapping Table
| Authority ID | Ministry Name | Short Code | Mapped Scheme IDs |
| :--- | :--- | :--- | :--- |
| `AUTH000125` | Ministry of Electronics and Information Technology | MeitY | `SCH000275` (Production Linked Incentive Scheme 2.0 for IT Hardware) |
| `AUTH000126` | Ministry of Labour and Employment | MoLE | `SCH000278` (Pradhan Mantri Rojgar Protsahan Yojana - PMRPY) |
| `AUTH000127` | Ministry of Corporate Affairs | MCA | `SCH000279` (PM Internship Scheme in Top Companies) |
| `AUTH000128` | Ministry of Fisheries, Animal Husbandry and Dairying | MoFAHD | `SCH000286` (AHIDF), `SCH000299` (FIDF), `SCH000300` (PMMSY) |
| `AUTH000129` | Ministry of New and Renewable Energy | MNRE | `SCH000288` (PM-KUSUM), `SCH000289` (PM Surya Ghar: Muft Bijli Yojana) |
| `AUTH000130` | Ministry of Heavy Industries | MHI | `SCH000290` (Production Linked Incentive (PLI) Scheme for Automobile and Auto Component Industry) |
| `AUTH000131` | Ministry of Tribal Affairs | MoTA | `SCH000291` (Pradhan Mantri Janjati Adivasi Nyaya Maha Abhiyan - PM-JANMAN) |

**Result:** `authority_catalog.json` expanded from 124 to 131 authorities. All 10 schemes successfully link to their governing central ministry.

---

## 2. Duplicate & Legacy Scheme Status: Decisions D1, D2, D3 & PMRY (Approved)

### Context
Audit identified redundant / duplicate schemes across the catalog:
- `SCH000055`: Entrepreneurship Development Programme (duplicate of `SCH000095` ESDP)
- `SCH000064`: Credit Guarantee Scheme for Micro and Small Enterprises (duplicate of `SCH000038` CGTMSE)
- `SCH000082`: Mahila Coir Yojana (component under `SCH000035` Coir Vikas Yojana)
- `SCH000168`: Prime Minister's Rozgar Yojana (PMRY - defunct legacy scheme subsumed into `SCH000005` PMEGP in 2008)

### Decision ("ok and log it somewhere")
Confirmed:
1. **D1 (ESDP):** Keep `SCH000095` as the canonical active scheme. Keep `SCH000055` as archived duplicate (`status='ARCHIVED'`, `is_active=false`, `identity.status='closed'`). Create `duplicate_of` / `merged_into` relationship to `SCH000095`.
2. **D2 (CGTMSE):** Keep `SCH000038` as the canonical active scheme. Keep `SCH000064` as archived duplicate (`status='ARCHIVED'`, `is_active=false`, `identity.status='closed'`). Create `duplicate_of` / `merged_into` relationship to `SCH000038`.
3. **D3 (Mahila Coir Yojana):** Retain `SCH000082` as a child component of `SCH000035` (Coir Vikas Yojana). Ensure symmetric `child_of` / `parent_of` relationships.
4. **PMRY (`SCH000168`):** Keep `SCH000168` as archived duplicate (`status='ARCHIVED'`, `is_active=false`, `identity.status='closed'`). Subsumed by `SCH000005` PMEGP.

---

## 3. Staging and Security Decisions D6 & D7 (Approved)

1. **D6 (Staging Tables):** Drop the four staging tables `catalog.scheme_new_v3_1`, `catalog.applicability_matrix_new_v3_1`, `catalog.search_index_new_v3_1`, and `catalog.relationships_new_v3_1`. Retain `catalog.scheme_source_v3_1` as a permanent provenance record with `FORCE ROW LEVEL SECURITY`.
2. **D7 (Security Hardening):** Revoke public/anon execute permissions on `public.create_scheme_draft` in Phase F.
