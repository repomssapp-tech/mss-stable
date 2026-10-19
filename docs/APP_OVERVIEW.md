# MSS (MSME Schemes Search) — App Overview, UI/UX Philosophy & Feature Architecture

**Document Version:** 1.0.0  
**Target Audience:** Product managers, designers, frontend/backend engineers, and stakeholders.  
**Related Documents:**
- [Product Design Rationale](file:///c:/development/MSS%20App/MSS_App/docs/PRODUCT_DESIGN.md)
- [UI/UX Design System & Screen Flows](file:///c:/development/MSS%20App/MSS_App/docs/UI_UX_DESIGN_SYSTEM.md)
- [Offline Discovery & Search Architecture](file:///c:/development/MSS%20App/MSS_App/docs/OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md)
- [Software Development Document](file:///c:/development/MSS%20App/MSS_App/docs/SOFTWARE_DEVELOPMENT_DOCUMENT.md)

---

## 🏛️ 1. Executive Summary & Problem Statement

**MSS (MSME Schemes Search)** is an offline-first, multilingual civic-tech application engineered to democratize access to Central and State Government schemes, subsidies, grants, and credit facilities for Indian citizens—with special emphasis on **Micro, Small & Medium Enterprises (MSMEs), rural artisans, women entrepreneurs, and students**.

### The Problem It Solves
1. **Information Fragmentation:** Government welfare programs and business subsidies are distributed across dozens of disparate central and state portals with no single, unified source of truth.
2. **Bureaucratic Opacity & High Reading Grade:** Schemes are written in dense administrative language, leaving citizens uncertain whether they qualify or what documents are needed.
3. **Connectivity & Device Constraints:** Rural entrepreneurs and small workshop owners frequently operate in bandwidth-constrained environments where cloud-dependent applications fail.
4. **Digital Literacy & Language Barriers:** Complex forms and English-centric navigation exclude non-tech-savvy citizens and regional language speakers.

### The Solution
MSS provides a unified, transparent, and resilient platform: **a user can find every scheme they plausibly qualify for, understand it in plain language (English or Tamil), verify their eligibility offline with sub-250ms latency, compute business metrics with embedded utilities, and follow an actionable step-by-step application guide.**

---

## 🎨 2. UI / UX Design Philosophy & Focus

The UI/UX architecture of MSS is built on the core emotional posture of **"Civic Authority + Consumer Warmth"**—delivering the trustworthiness of an official government portal alongside the polish, speed, and usability of modern consumer fintech applications.

### 2.1 Dual Interaction Modes
Rather than enforcing a single interaction paradigm, MSS bifurcates into two tailored experiences during onboarding:

```
                              ┌────────────────────────┐
                              │    Choose Mode Flow    │
                              └───────────┬────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
      ┌───────────────────────┐                       ┌───────────────────────┐
      │     Regular Mode      │                       │ Companion Mode (Saarthi)│
      ├───────────────────────┤                       ├───────────────────────┤
      │ • Visual, 5-tab hub   │                       │ • Voice-first & guided│
      │ • Self-directed search│                       │ • High-contrast cards │
      │ • Data calculators    │                       │ • Oversized tap zones │
      │ • Advanced filters    │                       │ • Spoken Tamil/English│
      └───────────────────────┘                       └───────────────────────┘
```

1. **Regular Mode (Visual / Self-Directed):**
   - Designed for MSME owners, accountants, consultants, and researchers comfortable with digital navigation.
   - Features 5 bottom navigation tabs: **Home**, **Search**, **Discover (Categories & Utilities)**, **Saved**, and **Profile**.
   - Rich interactive cards, swipeable carousels, expandable accordions, and bottom-sheet filters.

2. **Companion Mode — "Saarthi" (Voice-First / Accessibility):**
   - Tailored for seniors, rural artisans, and users with lower digital or English literacy.
   - High-contrast, minimal-distraction UI with large touch targets ($\ge 56\text{ dp}$).
   - Voice-prompted question flow allowing users to state their situation naturally in spoken Tamil or English.
   - Narrated guidance explaining matching results and prerequisite checklists aloud.

---

### 2.2 Canonical Design System & Semantic Tokens

The visual foundation follows **Material 3 Civic-Tech** guidelines with contrast ratios calibrated to exceed **WCAG 2.1 AA** standards ($\ge 8.5:1$ on text elements) for outdoor sunlight readability:

| Semantic Token | Hex Code | Role & Usage | Contrast Ratio |
|:---|:---|:---|:---|
| **`primaryColor`** | `#2563EB` | Primary CTA buttons, active tabs, selected states (Royal Blue) | 4.8:1 on white |
| **`secondaryColor`** | `#1565C0` | Secondary links, active drawer accents (Azure Blue) | 6.2:1 on white |
| **`accentColor`** | `#FF9933` | Saffron accents, national emblem highlights, badge pills | 3.2:1 (Graphic) |
| **`successColor`** | `#047857` | Eligible match tags, approved statuses (Emerald Green) | 5.8:1 on white |
| **`warningColor`** | `#D97706` | Pending items, expiry warnings (Amber Gold) | 4.9:1 on white |
| **`errorColor`** | `#D32F2F` | Form errors, validation alerts, destructive CTAs (Crimson) | 5.5:1 on white |
| **`backgroundColor`** | `#F8FAFC` | Scaffold base (Slate 50 Ice White) | Base Canvas |
| **`surfaceColor`** | `#FFFFFF` | Elevated cards, dialogs, sheets (Pure White) | Card Surface |
| **`primaryText`** | `#0F172A` | Headlines, titles, active input labels (Slate 900) | 16.1:1 on white |
| **`secondaryText`** | `#374151` | Subtitles, metadata, form helper text (Slate 700) | 8.5:1 on white |
| **`borderNeutral`** | `#E2E8F0` | Card borders, dividers, chip outlines (Slate 200) | Subtle Contour |

---

### 2.3 Strict 8pt Spatial Grid & Haptic Micro-Interactions

- **Spatial Harmony:** Zero hardcoded visual spacing literals. All margins and paddings are bound to `AppSpacing` tokens (`2px`, `4px`, `8px`, `12px`, `16px`, `24px`, `32px`, `48px+`), validated via automated regression tests (`spacing_scale_test.dart`).
- **Tactile Haptics:**
  - `AppFeedback.selection()` on tab navigation, segmented control toggles, and filter chips.
  - `AppFeedback.light()` on card expansion and search clearing.
  - `AppFeedback.medium()` on scheme bookmarking and successful profile save actions.

---

### 2.4 Multilingual Typography Scaling & Glyph Protection

- **Type Families:**
  - **English:** `GoogleFonts.inter` for body, tables, and controls; `GoogleFonts.poppins` for headers, numbers, and stats.
  - **Tamil:** `GoogleFonts.notoSansTamil` for body and labels; `GoogleFonts.arima` for distinctive accents.
- **Glyph Clipping Prevention Rule:** Tamil typography features conjunct glyphs with extended ascenders and descenders (e.g., `ஸ்ரீ`, `க்ஷ`). The typography engine enforces an **automatic 15% line-height expansion** on Tamil text blocks to prevent glyph clipping inside cards and badges.

---

### 2.5 Cognitive Load Management & Progressive Disclosure

- **Anti-Form Fatigue:** The app avoids overwhelming first-time users with 20+ form inputs. Onboarding captures only 4 lightweight criteria (Name, State, District, Occupation/Stage). Users can explore recommendations immediately, while a "Profile Completion" card on the Home screen gently nudges incremental additions (Income, Community, Udyam No.) to refine matches over time.
- **Hierarchical Scheme Details:** Scheme detail views place immediate citizen value up front ("Why You Qualify" match box, financial subsidies/benefits), keeping procedural steps, nodal agency contacts, and office locations collapsed in accessible accordions.

---

## ⚡ 3. Comprehensive Feature Architecture

```
                               ┌───────────────────────────┐
                               │   MSS Feature Ecosystem   │
                               └─────────────┬─────────────┘
      ┌────────────────────┬─────────────────┼─────────────────┬────────────────────┐
      ▼                    ▼                 ▼                 ▼                    ▼
┌─────────────┐    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌────────────────┐
│Offline-First│    │300ms Hybrid  │   │Saarthi Voice │   │MSME Business │   │MSME Ecosystem  │
│Catalog & RLS│    │Search Engine │   │Agent (LiveKit│   │Utilities (7) │   │& Institutions  │
│Rules Engine │    │& Filters     │   │+ Sarvam AI)  │   │Calculators   │   │Directory       │
└─────────────┘    └──────────────┘   └──────────────┘   └──────────────┘   └────────────────┘
```

### 3.1 Verified Offline-First Catalog & Rules Engine
- **Pre-bundled Release `1.34.3-alpha`:** Ships with **219 verified schemes**, **1,220 catalog entities**, and **971 search-indexed profiles** packaged in a gzip-compressed archive (`catalog_bundle.json.gz`).
- **Sub-250ms Offline Evaluation:** Eliminates server roundtrips; executes scheme matching, keyword search, and filtering entirely on-device with zero telemetry leakage.
- **Deterministic Rules Evaluation:** Analyzes demographic criteria (age boundaries, gender restrictions, community/caste categories, annual income ceilings, landholdings, enterprise turnover, and industry sector).
- **Explainability Layer:** Formulates plain-language rationales explaining *why* an applicant matches (e.g., *"Eligible because your annual turnover is under ₹5 Cr, you hold an active Udyam registration, and your unit is situated in an eligible backward taluk"*).
- **Over-The-Air (OTA) Updates:** Secure catalog updates from the MSS backend (`GET /v1/catalog/current`) with SHA-256 cryptographic verification and automatic fallback to bundled assets if validation fails.

---

### 3.2 300ms Real-Time Hybrid Search & Faceted Filtering
- **Debounced Real-Time Search:** 300ms debouncing balances responsiveness with frame stability on budget Android hardware.
- **Query Expansion & Typo Tolerance:** Maps colloquial and transliterated queries (e.g., "magalir loan", "subsidy for tractor", "mudra") to formal scheme titles.
- **Faceted Bottom-Sheet Filters:**
  - Geographic jurisdiction (Central vs. State Government departments).
  - Scheme Type (Capital Subsidy, Interest Subvention, Direct Grant, Soft Loan, Skill Training).
  - Target Demographic (Women, SC/ST, Minority, Youth, Differently-Abled, Artisan).
  - Application Channel (Online portal, Common Service Centre / e-Seva, District Industries Centre).

---

### 3.3 Saarthi: Multilingual AI Voice Assistant
- **Real-Time Voice Streaming:** Powered by **LiveKit Agents SDK** over WebRTC for low-latency full-duplex conversational audio.
- **Indic Language Understanding:** Integrates **Sarvam AI** for specialized Indian accent speech recognition (STT) and natural text-to-speech (TTS) synthesis in Tamil and English.
- **Resilient Fallback:** Automatically switches to on-device speech recognition and native Android/iOS TTS engines when network connectivity drops.
- **Context-Aware Intent Mapping:** Translates natural spoken statements (e.g., *"I want to open a small bakery in Madurai, what government help can I get?"*) directly into pre-filtered scheme candidates and guided application checklists.

---

### 3.4 7 MSME Business Utility Tools & Financial Calculators
Integrated into the **Discover** module ([`CategoriesBusinessUtilitiesSection`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/screens/regular_mode/categories/categories_business_utilities_section.dart)), these tools empower small business owners to compute real financial metrics:

1. **Udyam Enterprise Classifier:** Implements the official MSMED Act criteria (Plant & Machinery Investment + Annual Turnover) to classify businesses into **Micro**, **Small**, or **Medium** categories.
2. **Capital Subsidy Estimator:** Calculates estimated capital subsidies, margin money contributions, and maximum eligible grant ceilings across general and special categories.
3. **GST Tax Calculator:** Performs forward and reverse GST computations across standard tax slabs (5%, 12%, 18%, 28%) with CGST/SGST breakdowns.
4. **Business Loan EMI Calculator:** Amortization calculator showing monthly EMI, total interest payable, and yearly payoff schedules.
5. **DPIIT Startup Checklist:** An interactive readiness assessment evaluating startup criteria for official DPIIT recognition and Section 80-IAC tax exemption eligibility.
6. **Business Valuation Estimator:** Early-stage valuation calculator using revenue multiples and discounted cash flow guidelines for emerging MSMEs.
7. **Document Checklist Generator:** Dynamic checklist assessing readiness for mandatory documents (Aadhaar, PAN, Udyam Certificate, Nativity Certificate, Community Certificate, Bank Statement, Detailed Project Report).

---

### 3.5 MSME Ecosystem, Institutional Directory & State Map
- **TReDS Guide:** Dedicated informational panel for the Trade Receivables Discounting System, educating suppliers on resolving delayed payments from corporate and PSU buyers.
- **Export Facilitation:** Step-by-step guidance on obtaining an Importer Exporter Code (IEC), registering with Export Promotion Councils (EPCs), and availing freight subsidies.
- **Institutional Directory:** Structured contact channels and mandates for key nodal agencies:
  - **DIC:** District Industries Centres (district-level execution)
  - **SIDBI:** Small Industries Development Bank of India (refinancing & credit)
  - **NSIC:** National Small Industries Corporation (marketing & raw materials)
  - **MSME-DFO:** MSME Development and Facilitation Offices
- **Interactive State Map:** Custom vector-rendered map ([`state_map_painter.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/screens/regular_mode/categories/state_map_painter.dart)) allowing users to tap and explore district-level schemes across Tamil Nadu.

---

### 3.6 Bookmarks, History & Cross-Device Cloud Sync
- **Instant Offline Storage:** Bookmarked schemes, generated document checklists, and eligibility results persist locally via SQLite / shared preferences.
- **Google OAuth Sync:** Optional sign-in (Google OAuth with PKCE against the MSS backend) synchronizes the profile across devices.

---

## 💻 4. Technology Stack Matrix

| Architecture Layer | Core Technologies | Responsibility / Purpose |
|:---|:---|:---|
| **Mobile Frontend** | Flutter 3.44.2 (Dart 3.5+) | Cross-platform client for Android, iOS, and Web |
| **State Management** | `provider: ^6.1.2` | Clean reactive state separation without heavy boilerplate |
| **Typography** | `google_fonts: ^6.2.1` | Inter, Poppins, Noto Sans Tamil, and Arima typography |
| **Voice Streaming** | `livekit_client: ^2.4.3` | Real-time WebRTC audio channel to the voice agent |
| **Backend & Auth** | MSS REST API (`/v1`) | Google OAuth (PKCE), profile, notifications, promotions, catalog releases |
| **Voice Worker** | Python 3.12, LiveKit Agents, Sarvam AI | STT, conversational LLM intent extraction, and Indic TTS |
| **Testing & CI/CD** | Flutter Test, GitHub Actions | 480+ unit/widget tests, token linting, and RLS drift checks |

---

## 📋 5. Summary & Competitive Advantage

| Traditional Government Portals | MSS (MSME Schemes Search) |
|:---|:---|
| Scattered across 50+ departmental websites | Single unified central and state catalog |
| Requires constant high-speed internet | 100% functional offline with bundled verified catalog |
| Dense legalistic jargon and confusing forms | Plain-language summaries with explicit "Why You Qualify" breakdown |
| English-only or low-quality machine translations | Native English & Tamil with voice-guided conversational assistant |
| No financial planning or eligibility aids | 7 integrated business calculators and compliance checklists |
