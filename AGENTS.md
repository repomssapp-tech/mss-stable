# AGENTS.md — AI Coding Assistant & Developer Guidelines

This document provides unified guidance for AI coding assistants (Antigravity, Codex, Copilot, Claude) and developers working in the `MSS_App` repository.

---

## 🏛️ Monorepo Structure & Key Directories

- **`frontend/`**: Multi-platform Flutter application (Dart 3.5+, Flutter 3.44.2).
  - `lib/config/`: Routes, theme definitions, and environment config.
  - `lib/l10n/`: Localization ARB templates (`app_en.arb`, `app_ta.arb`) and generated classes.
  - `lib/models/`: Strongly-typed data structures (`scheme_model.dart`, `mss_contract.dart`, `user_profile.dart`).
  - `lib/providers/`: State management (`app_state_provider.dart` with dedicated controller sub-modules).
  - `lib/screens/`: Screen coordinators split by mode (`regular_mode/`, `companion_mode/`, `profile/`, `notifications/`, `beta_gate_screen.dart`).
  - `lib/services/`: Service layer partitioned by domain (`catalog/`, `search/`, `recommendation/`, `beta_gate/`, `voice/`, `account/`, `chat/`).
  - `lib/utils/`: Design tokens (`app_spacing.dart`), helpers, and global constants (`constants.dart`).
  - `lib/widgets/`: Shared UI components organized by category (`buttons/`, `cards/`, `dialogs/`, `inputs/`, `layout/`, `assistant/`).
  - `assets/catalog/`: Canonical offline scheme catalog (`catalog_bundle.json.gz`, `release.json`).
  - `test/`: 480+ widget, unit, and characterization tests.
- **`backend/`**: Supabase infrastructure.
  - `supabase/migrations/`: Immutable, sequential SQL migrations.
  - `supabase/functions/`: Deno-based Edge Functions (`sarvam-chat`, `livekit-token`, `publishCatalog`, `db-change-notify`, `v1`, `rollbackRelease`).
  - `catalog/`: Backend catalog definitions and search taxonomy (`search_taxonomy.json`).
- **`saarthi-agent/`**: Python LiveKit voice agent worker.
  - `src/`: Agent entrypoint (`main.py`, `agent.py`) and hybrid search engine.
  - `tests/`: Pytest suite verifying catalog sync, parity, and voice agent handling.

---

## ⚡ Primary Development Commands

### Flutter Application (`frontend/`)
```bash
# Analyze (must be 0 errors, 0 warnings)
flutter analyze

# Verify design token compliance (must be 0 violations)
flutter test test/spacing_scale_test.dart

# Run entire test suite
flutter test

# Run a single test file
flutter test test/<test_file_name>_test.dart
```

### Backend (`backend/`)
```bash
# Start local Supabase containers
npm run supabase:start

# Reset local database and replay migrations
npm run db:reset

# Test Edge Functions & Parity
npm run functions:test
deno test --allow-read --allow-env supabase/functions/v1/search_engine_parity_test.ts
```

### Saarthi Voice Agent (`saarthi-agent/`)
```bash
# Lint and format checks
uv run ruff check .
uv run ruff format --check .

# Run test suite
uv run pytest -v
```

---

## 🛡️ Architecture Invariants & Coding Standards

1. **Strict Offline-First Data Layer**:
   - `SchemeRepository` reads from `MssCatalogBundle` (`assets/catalog/catalog_bundle.json.gz`).
   - Do not introduce synchronous network calls into the primary scheme browsing, search, or recommendation paths.
   - Catalog updates happen via OTA bundle downloads verified by SHA-256 against `mss_current_release()`.

2. **Design Tokens (`AppSpacing`)**:
   - Never use raw numeric literals for padding, margins, or SizedBox dimensions (e.g., `EdgeInsets.all(16.0)` or `SizedBox(height: 8.0)`).
   - Always use semantic tokens from `package:frontend/utils/app_spacing.dart` (`AppSpacing.xs`, `AppSpacing.sm`, `AppSpacing.md`, `AppSpacing.lg`, `AppSpacing.xl`, `AppSpacing.xxl`, `AppSpacing.gapVerticalSm`, etc.).
   - Guarded by `test/spacing_scale_test.dart`.

3. **Bilingual Localization (`en` & `ta`)**:
   - Never hardcode user-visible UI strings in Dart files.
   - Add keys to both `frontend/lib/l10n/app_en.arb` and `frontend/lib/l10n/app_ta.arb`.
   - Access via `context.l10n.<key>` or `AppLocalizations.of(context)!.<key>`.

4. **Responsive Layout & Overflow Prevention**:
   - Never use fixed heights for pages, cards, or major widgets unless explicitly justified.
   - Use `SafeArea` on screen bodies to handle notches and navigation bars.
   - Use `LayoutBuilder`, `Expanded`, `Flexible`, and `Spacer` instead of large fixed dimensions.
   - Any content that may exceed screen height must be wrapped in a scrollable widget (e.g., `SingleChildScrollView`, `ListView`).
   - Ensure `resizeToAvoidBottomInset: true` on screens with text inputs.
   - All layouts must scale gracefully from 320dp width phones to 800dp+ tablets without `RenderFlex` overflow.

5. **State Management & Navigation**:
   - Use `ChangeNotifierProvider` and `AppProvider` (`lib/providers/app_state_provider.dart`).
   - Keep state logic inside controllers and providers; keep UI widgets focused on presentation.
   - Standard navigation uses vanilla Flutter `Navigator.push` / `Navigator.pop`. (Do not introduce `go_router` or `riverpod`.)

6. **Security & RLS**:
   - All PostgreSQL tables in Supabase must have Row Level Security (RLS) enabled.
   - Secrets (`SARVAM_API_KEY`, `LIVEKIT_API_SECRET`, etc.) must never be committed to source control.

7. **Voice AI Agent Standards (`saarthi-agent/`)**:
   - Manage dependencies and execution strictly via `uv` (`uv sync`, `uv run pytest`, `uv run ruff`).
   - App code resides under `src/` with `agent.py` as entrypoint; maintain test coverage in `tests/`.
   - Never guess LiveKit APIs or behaviors; verify with official LiveKit CLI (`lk docs`) or docs.
