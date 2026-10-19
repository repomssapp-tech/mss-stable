# Skills — Quick-Orientation Reference

A practical cheat sheet for any AI assistant or new developer picking up this repo cold. For rules you must follow, see `docs/RULES.md`. For current known-good/known-broken state, see `docs/audit/AUDIT.md`.

## The one gotcha that wastes everyone's first 10 minutes

If you're working from a checkout at `C:\development\MSS App\`, the actual git repo and all real code is **one level down**, in `C:\development\MSS App\MSS_App\`. The outer folder only holds editor tooling (`.agents/skills/`). `cd MSS_App` first.

## Monorepo map

- **`frontend/`** — Flutter app (Dart). `lib/` is layer-first: `models/`, `providers/` (+ `providers/controllers/` sub-state), `screens/` (split `regular_mode/` vs `companion_mode/`), `services/` (sub-packaged by domain: `catalog/`, `search/`, `recommendation/`, `beta_gate/`, `voice/`, `account/`, `chat/`), `utils/`, `widgets/`. Single data gateway: `SchemeRepository` (`frontend/lib/services/scheme_repository.dart`).
- **`backend/`** — REST API references (`New API Ref/`), `catalog/` (search taxonomy and catalog sources), `openapi/` (spec — currently aspirational). The old hosted backend is archived under `docs/old_supabase/`.
- **`saarthi-agent/`** — Python LiveKit voice agent. `src/agent.py` is the entrypoint; ships its own local copy of the search engine.
- **`docs/`** — canonical architecture/spec docs (flat, one level, by domain). `docs/audit/` holds the live audit and the per-developer change log. `docs/archive/` holds retired/historical docs — don't treat anything there as current.

## First files to read for a given task

| If you're touching... | Start here |
|---|---|
| Search/ranking/catalog | `frontend/lib/services/scheme_repository.dart`, `frontend/lib/services/hybrid_scheme_search.dart`, `docs/OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md` |
| App-wide state | `frontend/lib/providers/app_state_provider.dart` + `providers/controllers/*` |
| Backend API | `backend/New API Ref/` (the server itself lives in the separate `mss-backend` project) |
| Database schema | Owned by `mss-backend`; the retired schema is archived in `docs/old_supabase/backend/supabase/` |
| Voice agent | `saarthi-agent/src/agent.py` |
| UI styling | `frontend/lib/utils/app_spacing.dart` (design tokens — never hardcode numeric padding/margins) |

## How the governance docs fit together

- **`AGENTS.md`** (root) — canonical build/lint/test commands and architecture invariants. `CLAUDE.md` is now just a pointer here.
- **`docs/RULES.md`** — index into all the domain specs plus a handful of rules not written down anywhere else (decomposition ceiling, API routing pattern).
- **`docs/audit/AUDIT.md`** — current known state, refreshed in place as things are re-verified. Check this before trusting an older doc's claims.
- **`docs/old_supabase/docs/audit/CODEBASE_AUDIT.md`** — the original deep-dive (2026-09-10), frozen as a historical baseline; useful for "how did we get here" but not for "what's true today."
- **`docs/audit/DEV_LOG.md`** — auto-appended on every merged PR, keyed by GitHub username (via `.github/workflows/dev-log.yml`). This is the answer to "who changed this and when."

## Known trouble spots (so you don't have to re-discover them)

- **Search ranking is implemented three times** — Dart (`hybrid_scheme_search.dart`), TypeScript (`v1/search_engine.ts`), Python (`saarthi-agent/src/hybrid_search.py`) — kept in sync only by parity tests. If you change ranking logic, check all three.
- **God objects persist despite decomposition passes**: `app_state_provider.dart`, `voice_assistant_overlay.dart`, `saarthi_home_screen.dart` are still well over the ~500-line ceiling after sub-modules were extracted; `basic_profile_screen.dart` wasn't decomposed at all. See `docs/audit/AUDIT.md` for specifics before assuming a "decomposed" file is actually small.
- **Docs drift silently** — several past architecture docs described features or endpoints that no longer exist (or never existed) in code. Prefer code + `docs/audit/AUDIT.md` over any single prose doc when they conflict, per the authority order in `docs/RULES.md`.
- **`v1` Edge Function has zero client callers today** — this is intentional (reserved for a future voice-agent search path), not a bug; don't "fix" it by wiring it up without checking `docs/audit/AUDIT.md` and `OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md` first.
