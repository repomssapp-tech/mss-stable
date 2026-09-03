# Production Readiness & Codebase Audit Report: MSS (Micro & Small Scheme) App

**Audit Date:** 2026-09-04  
**Audit Scope:** Full Codebase (Frontend `lib/`, Backend `supabase/`, Tools `tools/`, Assets, Tests)  
**Overall Production Readiness Rating:** **8.7 / 10** (Production Candidate)

---

## 1. Executive Summary & Purpose of the Application

### 1.1 Purpose & Domain
The **MSS (Micro & Small Scheme / IN Schemes)** mobile application is an offline-first enterprise discovery and eligibility platform designed for Indian entrepreneurs, MSMEs, artisans, and small business owners (specifically tailored for Tamil Nadu and Central Indian schemes).

Key capabilities:
1. **Catalog Exploration:** 219 government schemes categorized by industry, finance type, benefits, and demographics.
2. **Hybrid Offline Search:** Deterministic TF-IDF keyword search + query expansion (acronyms, Tamil transliteration/Tanglish, phrases) running 100% offline from a compressed bundle (`catalog_bundle.json.gz`).
3. **Personalized "For Me" Filter:** Additive multi-facet scoring assessing eligibility based on user profile (turnover, sector, community, gender, location).
4. **Voice Assistant / "Saarthi":** LiveKit real-time voice integration + local rule-based understanding (`SchemeUnderstandingEngine`).
5. **Bilingual UX:** English and Tamil language localization with fallback dictionary translation.

---

## 2. Dead Code & Unused Code Inventory

| Category | File / Component | Details & Recommendation |
| :--- | :--- | :--- |
| **Dormant Edge AI SLM** | `frontend/lib/services/edge_slm_runtime.dart`<br>`frontend/lib/services/edge_model_pack.dart`<br>`frontend/lib/services/edge_slm_understanding_engine.dart`<br>`pubspec.yaml` (`llama_flutter_android: 0.2.6`) | **Dormant / Deprecated Path:** Replaced by Phase 4 Option A (pure lexical search) and `SchemeUnderstandingEngine`. Contains a 396MB model pack download pointing to an external GitHub URL (`https://github.com/Roger-Chris/IN_Schemes/...`). **Recommendation:** Keep as optional experimental feature or isolate into a separate plugin to shed APK weight and binary dependencies. |
| **Superseded Edge Functions** | `backend/supabase/functions/`<br>• `buildCatalog`<br>• `downloadCatalog`<br>• `exportCatalog`<br>• `generateManifest`<br>• `publishCatalog`<br>• `rollbackRelease`<br>• `validateCatalog`<br>• `schemes-api`<br>• `search`<br>• `recommend` | **Legacy Deno Functions:** These 10 functions predate the unified `v1` Edge Function (`/v1/search`, `/v1/categories`, `/v1/schemes`) and the Python publishing CLI (`tools/publish_catalog_release.py`). **Recommendation:** Archive or remove from production Supabase deployment to reduce attack surface. |
| **Superseded Scripts** | `docs/archive/superseded-scripts/bootstrap_v2.mjs` | Legacy bootstrap script referencing outdated 969-entity schema. Kept in archive (informational only). |
| **Dual Data Model Overlap** | `frontend/lib/models/scheme_model.dart`<br>vs `frontend/lib/models/localized_scheme.dart`<br>vs `frontend/lib/models/mss_entity.dart` | `SchemeModel` is a legacy flat model; `MssEntity` is the raw catalog wrapper; `LocalizedScheme` is the UI presentation model. Adapters bridge them cleanly, but having 3 distinct representations increases cognitive load. |

---

## 3. Logical Errors, Architectural Gaps & Edge Cases

### 3.1 State Management & Routing Discrepancy
* **Issue:** Project guidelines specify `Riverpod` and `go_router`, but the codebase is fully built with `provider: ^6.1.2` (`AppProvider`) and traditional `Navigator` 1.0 with persistent BottomNavigationBar (`MainTabsContainer`).
* **Impact:** Does not cause runtime bugs (the app functions properly and tests pass), but represents a tooling divergence from team conventions.
* **Recommendation:** If migrating to Riverpod/GoRouter is desired, do it as a planned milestone; otherwise, update project guidelines to reflect `Provider`.

### 3.2 Cloud Region Latency Mismatch (`STALE_DOCS.md` Item C1)
* **Issue:** The live Supabase instance (`houpzsxmwemoztpuigmo.supabase.co`) is hosted in `ap-southeast-2` (Sydney, Australia), while target users are in India (`ap-south-1` Mumbai).
* **Impact:** Adds ~120–150ms unnecessary network round-trip time for online API calls (`/v1/search`, auth, LiveKit token exchange).
* **Recommendation:** Migrate the Supabase project to `ap-south-1` (Mumbai) before production release.

### 3.3 Text Scale Clamping Floor
* **Location:** `frontend/lib/main.dart:86-88`
* **Code:** `final boundedScale = deviceScale.clamp(1.20, 1.30);`
* **Analysis:** Forcing a minimum `1.20` scale factor prevents Tamil diacritic clipping, but on extremely narrow screens (320dp width), a 1.20x minimum text scale makes dense UI elements tighter.
* **Recommendation:** Ensure all cards and buttons use `Flexible`/`Expanded` and `SingleChildScrollView` (already well-handled by `AppSpacing` rollout).

### 3.4 Hardcoded Government Source URLs
* **Locations:** `constants.dart:34-48`, `private_ai_knowledge_base.dart:299-553`
* **Analysis:** Hardcoded links to government portals (`tnesevai.tn.gov.in`, `udyamregistration.gov.in`, `startupindia.gov.in`).
* **Risk:** Government URLs occasionally change endpoints or domain paths.
* **Recommendation:** Move portal URLs to a dynamic catalog or remote config key so updates don't require an app store release.

### 3.5 Fallback Translation Scalability
* **Location:** `frontend/lib/services/centralized_translator.dart` (87 KB static mapping)
* **Analysis:** Contains thousands of static Tamil translations. If a new dynamic term is added to the catalog, it won't be translated unless added to this dictionary.
* **Recommendation:** Maintain an automated audit test (e.g. `comprehensive_tamil_localization_audit_test.dart`) in CI to catch missing keys when catalog updates are released.

---

## 4. Production Readiness Scoring

| Dimension | Score | Assessment & Findings |
| :--- | :---: | :--- |
| **1. Offline-First Architecture** | **9.8 / 10** | Exceptional. Shipped catalog bundle with Gzip + SHA-256 verification, local fallback on timeout (2500ms), zero cloud dependency for core functions. |
| **2. Search & Retrieval Engine** | **9.5 / 10** | High precision TF-IDF, verified 1,840-token vocabulary gating, Phase 4 Option A query expansion, online/offline field-for-field parity. |
| **3. Code Quality & Formatting** | **9.2 / 10** | Clean static analysis (`flutter analyze` has 0 warnings/errors), no raw `print()` statements, modular components, strict type safety. |
| **4. Automated Test Coverage** | **9.0 / 10** | 247+ automated unit, widget, and integration tests covering checksums, localization, corpus recall (`>= 0.92`), and spacing scale. |
| **5. UI/UX & Responsive Layout** | **8.8 / 10** | Complete repo-wide `AppSpacing` rollout, overflow-safe layouts tested against 320dp to 800dp tablet viewports. |
| **6. Security & Authentication** | **8.2 / 10** | Supabase Auth with Google OAuth, public key separation, RLS policies. Sydney region migration needed. |
| **7. Architecture Convention Parity** | **7.5 / 10** | Clean Provider-based architecture, though diverges from Riverpod/GoRouter specification. |
| **Overall Score** | **8.7 / 10** | **Ready for Production Testing & Staging Deployment.** |

---

## 5. Recommended Production Action Items (Prioritized)

1. **P1 (Infrastructure):** Migrate live Supabase project from `ap-southeast-2` (Sydney) to `ap-south-1` (Mumbai) to reduce RTT by ~150ms.
2. **P2 (Cleanup):** Deprecate legacy Supabase edge functions (`search`, `recommend`, etc.) in favor of `/v1/`.
3. **P3 (Edge AI Isolation):** Decide whether on-device Qwen3-0.6B SLM remains an optional download or is archived to reduce native binary surface area.
4. **P4 (Remote Config):** Externalize government portal links from `constants.dart` into the catalog release bundle for zero-downtime updates.
