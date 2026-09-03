# Stale / unreconciled documentation (Phase 7 — report only)

Ground truth used below:
- **`frontend/assets/catalog/release.json`** (`1.33.0-alpha`): `entityCount` 1216,
  `recordCounts` lists **all 15** catalog files, `scheme_catalog.json` = **219**.
- `search_index.json` SHA `5fb4d821...` = **971** records (per
  `BACKEND_PRE_B1_RECONCILIATION.md`, same SHA as the shipped file).
- Live Supabase pooler host (provided this session):
  `aws-0-ap-southeast-2.pooler.supabase.com` -> region **`ap-southeast-2` (Sydney)**.
- `/v1/meta` returns `scheme: 219`.
- Edge SLM code is present: `frontend/lib/services/edge_model_pack.dart`,
  `edge_slm_runtime.dart`, `edge_slm_understanding_engine.dart`;
  `frontend/pubspec.yaml:56` `llama_flutter_android: 0.2.6`.

**Nothing below has been edited.** Architecture docs need sign-off before rewrite.

---

## A. Wrong numbers (safe to correct)

| # | Location | Says | Should say |
|--|----------|------|-----------|
| A1 | `CLAUDE.md:94` | "`catalog_bundle.json.gz` (969 entities/217 schemes)" | 1216 entities / 219 schemes |
| A2 | `CLAUDE.md:100` heading + `:102` | "offline bundle is missing 5 of 15 catalog files" / "packages 11 of the 15" | all 15 files are in the bundle (`release.json.recordCounts`) |
| A3 | `CLAUDE.md:116` | "investigate the 217-vs-219 scheme gap" | resolved — 219 is correct; the 217 was a pre-`+2` example |
| A4 | `docs/handoff/architecture_docs/DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md:72-73, 83, 116-117` | `entityCount` / `searchIndexCount` / `search_index.json` = **969** | example manifest predates the +2 schemes and the count fix — 1216 / 971 |
| A5 | `docs/archive/backend-reports-2026-08/LOCALIZATION_AUDIT.md:5, 22` | "969 entities", "632 KB gz / 9.1 MB raw" | 1216 entities; bundle is now ~830 KB gz / ~10.7 MB raw (point-in-time archive — low priority) |
| A6 | Various `docs/archive/backend-reports-2026-08/*` | mix of 969 / 971 / 1216 | point-in-time archives; leave as historical record, don't retro-edit |

## B. Shipped-artifact bug (not just docs)

| # | Location | Issue |
|--|----------|-------|
| B1 | `frontend/assets/catalog/release.json:11` | `searchIndexCount: 1216` — copied from `entityCount`. The actual `search_index.json` (same SHA) has **971** records. Consumers that trust this field over-count the index by 245. Fix belongs in the bundle generator, out of scope for this report. |

## C. Region mismatch (needs sign-off — doc or infra is wrong)

| # | Location | Says | Reality |
|--|----------|------|---------|
| C1 | `docs/DEPLOYMENT_ARCHITECTURE.md:100, 144` | "closest available is **`ap-south-1` (Mumbai)** — use that for the single project" | the live project is in **`ap-southeast-2` (Sydney)**. Either the doc was never updated after provisioning, or the project sits in a non-preferred region. India->Sydney adds ~120-150 ms RTT vs Mumbai. Decide: move the project, or update the doc + accept the latency (also feeds Phase 4 Option B's latency math). |

## D. Capacity claim with no basis

| # | Location | Issue |
|--|----------|-------|
| D1 | `docs/DEPLOYMENT_ARCHITECTURE.md:98, 102, 145` | "sized for 500 users" / "plan for 500 users" stated 3x, no source. `docs/backend/decisions/0001-backend-governance-baseline.md:40` records expected launch load as **still unsupplied** ("Must be supplied before Sprint 3... Prevents credible capacity sign-off today"). The 500 figure is an unvalidated placeholder presented as a sizing decision. Needs a real number or an explicit "assumed, unverified" tag. |

## E. Unreconciled: on-device SLM status

| # | Location | Issue |
|--|----------|-------|
| E1 | `docs/EDGE_AI.md` (whole doc) | Describes a quantized **Qwen3-0.6B** on-device parser as the active offline path, with a llama.cpp conversion pipeline and `llama_flutter_android` integration notes. |
| E2 | Newer narrative (`CLAUDE.md` "Two open issues", handoff briefs) | Implies the offline path is lexical / `IntelligentSchemeSearch` only and treats an on-device model as *not present*. |
| | Reality | Both the dependency (`pubspec.yaml:56`) and the code (`edge_model_pack.dart`, `edge_slm_runtime.dart`, `edge_slm_understanding_engine.dart`) are still in the tree. So `EDGE_AI.md` is not "removed-feature stale" — the project's own docs disagree on whether the edge SLM is **shipped, dormant, or deprecated**. One authoritative status line is needed (and it directly gates Phase 4 Option C). |

---

## Recommended handling

1. **A1-A3** (`CLAUDE.md`): safe factual corrections + move the two "open issues"
   (missing catalogs, 217/219 gap) to a "Resolved" section. Low risk.
2. **A4**: mark the `DUAL_COPY...` manifest block as an illustrative example with a
   note that live values are 1216 / 971, or regenerate it from `release.json`.
3. **B1**: file a bug against the bundle generator; don't hand-edit the shipped
   `release.json`.
4. **C1 + D1 + E1/E2**: do **not** edit `DEPLOYMENT_ARCHITECTURE.md` or
   `EDGE_AI.md` here. Each needs a decision:
   - C1 — infra owner confirms region (move vs. document).
   - D1 — product supplies a launch-load number or the doc labels 500 as assumed.
   - E1/E2 — architecture owner states the edge-SLM lifecycle status; then the
     losing document is corrected or archived.
5. **A5/A6**: leave archived reports as historical; do not retro-edit.
