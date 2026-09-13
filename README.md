# IN Schemes: AI-Powered Government Scheme Platform

An intelligent, self-contained multi-platform application designed to simplify the discovery, eligibility verification, and documentation requirements of Central and State Government schemes for Indian entrepreneurs, MSMEs, women, and students.

Built with an **offline-first architecture**, bilingual **English & Tamil (`en`/`ta`)** localization, and an integrated **multilingual voice assistant (Saarthi)** powered by LiveKit and Sarvam AI.

---

## 🏛️ Monorepo Architecture

The repository is structured into three self-contained, production-grade components:

```
MSS_App/
├── frontend/             # Flutter Multi-Platform Application (Android, iOS, Web)
├── backend/              # Supabase Infrastructure (PostgreSQL, RLS, Edge Functions)
├── saarthi-agent/        # LiveKit Python Multilingual Voice Agent Worker
├── tools/                # Catalog bundling, seed data, and ML evaluation utilities
├── docs/                 # System architecture, database schemas, runbooks, and audit logs
└── .github/workflows/    # Automated CI/CD pipelines (Flutter, Backend, Voice Agent)
```

---

## 🚀 Key Features

### 1. Dual User Experience (UX) Modes
- **Regular Mode**: Standard modern mobile experience featuring 5 persistent navigation tabs:
  - **Home**: Personalized recommendations, profile completion metrics, MSME support widgets, and trending announcements.
  - **Search**: 300ms debounced real-time hybrid search with query expansion, multi-attribute filter bottom sheets, and instant facet counting.
  - **Discover**: State schemes explorer (interactive Tamil Nadu map), central ministries, and 7 business utility calculators (Udyam Classifier, Subsidy Estimator, GST Calculator, EMI Calculator, DPIIT Checklist, Valuation Estimator, and Document Checklist).
  - **Saved Schemes**: Fast offline access to bookmarked schemes, recently viewed items, and cached eligibility assessments.
  - **Profile**: Comprehensive eligibility profile management (personal, location, education, community, business details) with Google OAuth account sync.
- **Companion Mode (Saarthi)**: Simplified, high-contrast, accessibility-focused interface designed for seniors, non-tech-savvy users, and rural entrepreneurs:
  - Large-target touch cards with prominent voice prompts.
  - Full Tamil audio guidance and automatic speech recognition.
  - Streamlined step-by-step questionnaire flow.

### 2. Verified Offline-First Catalog Engine
- Bundles release **`1.34.3-alpha`** with **219 verified schemes**, **1,220 catalog entities**, and **971 search-indexed profiles** in a compressed gzip archive (`frontend/assets/catalog/catalog_bundle.json.gz`).
- Guaranteed sub-250ms query evaluation with zero network requests and zero user telemetry leakage.
- Automatic SHA-256 integrity verification with safe rollback to bundled assets if OTA updates fail.
- Over-the-air (OTA) catalog updates via Supabase Storage releases without requiring an app store update.

### 3. Intelligent Scheme Understanding & Reasoning
- **Deterministic Rules Engine**: Offline matching engine analyzing applicant age boundaries, gender restrictions, community categories, income ceilings, landholdings, and occupation criteria.
- **Explainability**: Plain-language justification for every recommendation explaining *why* the user qualifies.
- **Interactive Document Checklists**: Prerequisite document tracking (Aadhaar, Udyam, Nativity, Income Certificate) with direct links to official government issuance portals.

### 4. Saarthi Voice Agent (LiveKit + Sarvam AI)
- Real-time conversational voice assistant supporting English and Tamil.
- Ultra-low latency voice streaming using WebRTC (LiveKit Cloud).
- Domain-specific speech recognition (STT) and expressive text-to-speech (TTS) via Sarvam AI.
- Local on-device fallback for speech recognition and synthesized voice when offline.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|:---|:---|
| **Frontend** | Flutter 3.44.2 (Dart 3.5+), Material 3, Provider, Flutter Localizations (ARB) |
| **Backend** | Supabase (PostgreSQL 15+), Supabase Auth (Google OAuth), PostgREST, Deno Edge Functions |
| **Voice Agent** | Python 3.12+, LiveKit Agents SDK, Sarvam AI Voice APIs, `uv` Package Manager |
| **CI / CD** | GitHub Actions (Matrix builds, RLS drift checks, automated function deployments) |

---

## 💻 Getting Started

### Prerequisites
- **Flutter SDK**: 3.44.2 stable ([Installation Guide](https://flutter.dev/docs/get-started/install))
- **Node.js**: >= 20.19.0 ([nodejs.org](https://nodejs.org/))
- **Python**: >= 3.10, < 3.15 with `uv` ([astral.sh/uv](https://astral.sh/uv))
- **Supabase CLI**: Pinned via npm in `backend/`

---

### 1. Running the Flutter App

```bash
# Navigate to the frontend
cd frontend

# Fetch dependencies
flutter pub get

# Run static analysis (must be 0 issues)
flutter analyze

# Run full automated test suite (480+ tests)
flutter test

# Launch on connected device or emulator
flutter run
```

---

### 2. Running the Backend Locally

```bash
# Navigate to backend
cd backend

# Install dependencies (pinned supabase CLI)
npm ci

# Start local Supabase containers (excluding heavy analytics)
npm run supabase:start

# Reset and seed local database
npm run db:reset

# Run database tests and RLS linter
npm run db:test
npm run db:lint

# Run Edge Function tests
npm run functions:test
```

---

### 3. Running the Saarthi Voice Agent Worker

```bash
# Navigate to saarthi-agent
cd saarthi-agent

# Install dependencies using uv
uv sync --dev

# Run linter and formatter checks
uv run ruff check .
uv run ruff format --check .

# Run agent unit tests
uv run pytest -v

# Start the agent worker locally (requires local or cloud LiveKit server)
uv run python src/main.py dev
```

---

## 🧪 Testing & Code Quality Gates

Every commit in this repository enforces strict regression standards:

- **Static Analysis**: `flutter analyze` must report **0 errors and 0 warnings**.
- **Design Tokens**: `flutter test test/spacing_scale_test.dart` enforces 100% adherence to `AppSpacing` tokens with zero hardcoded visual spacing literals.
- **Regression Suite**: `flutter test` must pass 100% (480 passed, 0 failed).
- **Security & RLS**: All PostgreSQL tables must have Row Level Security enabled with automated drift detection via `.github/workflows/rls-drift-check.yml`.

---

## 📄 License & Compliance

All government scheme data bundled in this repository is sourced from verified official Central and State government portals (PIB, MSME, Startup India, and Government of Tamil Nadu). Content is intended for public awareness and entrepreneurship enablement.
