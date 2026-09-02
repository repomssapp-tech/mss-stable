# MSS (IN Schemes) — Canonical Design System & UI/UX Guidelines

**Version:** 2.0.0  
**Target Platform:** Mobile Flutter (Android & iOS) + Web / PWA  
**Design Paradigm:** Material 3 Civic-Tech + Steve Krug's Laws of Usability + WCAG 2.1 AA Contrast

---

## 🏛️ 1. Brand Identity & The Memorable Thing

> **The Memorable Thing:**  
> *"The simplest, fastest way for any Indian citizen, artisan, or entrepreneur to discover and claim government welfare, subsidies, and loans without bureaucratic confusion."*

### Emotional & Aesthetic Posture
- **Civic Authority + Consumer Warmth:** Feels as official and trustworthy as an Indian Government portal, but as fluid, intuitive, and clean as a modern fintech app.
- **Zero AI-Slop:** No generic cookie-cutter card grids, no empty buzzwords, and no competing hero banners. Every pixel serves citizen enablement.
- **Inclusive By Default:** First-class Tamil and English typography, voice-first search affordances for rural accessibility, and high contrast for outdoor sunlight readability.

---

## 🎨 2. Color System & Semantic Tokens

All color tokens are calibrated to achieve $\ge 8.5:1$ contrast against card and background surfaces (exceeding WCAG 2.1 AA requirements).

| Token Name | Hex Code | Role / Usage | Contrast Ratio |
| :--- | :--- | :--- | :--- |
| **`primaryColor`** | `#2563EB` | Primary CTA buttons, active tabs, selected states (Royal Blue) | 4.8:1 on white |
| **`secondaryColor`** | `#1565C0` | Secondary links, active drawer accents (Azure Blue) | 6.2:1 on white |
| **`accentColor`** | `#FF9933` | Badges, highlight pills, National emblem accents (Saffron) | 3.2:1 (Graphic) |
| **`successColor`** | `#047857` | Eligible match tags, approved statuses (Emerald Green) | 5.8:1 on white |
| **`warningColor`** | `#D97706` | Pending items, expiry warnings (Amber Gold) | 4.9:1 on white |
| **`errorColor`** | `#D32F2F` | Form errors, validation alerts, destructive CTAs (Crimson) | 5.5:1 on white |
| **`backgroundColor`** | `#F8FAFC` | Scaffold background (Ice White / Slate 50) | Base Canvas |
| **`surfaceColor`** | `#FFFFFF` | Elevated cards, bottom sheets, dialogs (Pure White) | Card Surface |
| **`primaryText`** | `#0F172A` | Headlines, titles, active input labels (Slate 900) | 16.1:1 on white |
| **`secondaryText`** | `#374151` | Subtitles, metadata, form helper text (Slate 700) | 8.5:1 on white |
| **`borderNeutral`** | `#E2E8F0` | Card borders, dividers, chip outlines (Slate 200) | Subtle Contour |

---

## ✍️ 3. Typography & Multilingual Scaling System

### Font Families
- **English:** `GoogleFonts.inter` (Body, Controls, Tables) & `GoogleFonts.poppins` (Headlines, Large Numbers)
- **Tamil:** `GoogleFonts.notoSansTamil` (Body, Form Labels) & `GoogleFonts.arima` (Special Accents)

### Type Scale (English vs Tamil Scaling)

| Text Style | English Size / Weight | Tamil Adjusted Size / Line-Height | Tracking / Usage |
| :--- | :--- | :--- | :--- |
| **Display Large** | `28px / Bold (700)` | `26px / 1.35 Line-Height` | Hero greetings, on-boarding titles |
| **Headline Medium** | `22px / Bold (700)` | `20px / 1.35 Line-Height` | Section titles, Scheme detail names |
| **Title Medium** | `16px / SemiBold (600)` | `15px / 1.30 Line-Height` | Card headlines, Category titles |
| **Body Regular** | `14px / Regular (400)` | `13px / 1.45 Line-Height` | Paragraphs, Overview, Benefits |
| **Body Small** | `12px / Medium (500)` | `11.5px / 1.40 Line-Height` | Subtitles, Ministry tags, Timestamps |
| **Label Small** | `10.5px / Bold (700)` | `10px / 1.25 Line-Height` | Status badges ("Eligible", "Central") |

> **Tamil Typography Rule:** Tamil glyphs require 15% more vertical line-height due to conjunct ascenders/descenders (e.g. `ஸ்ரீ`, `க்ஷ`). Never clip Tamil text with tight fixed container heights.

---

## 📐 4. Spacing, Elevation & Layout Grid

### 8pt Spatial Grid
- **`2px` (Micro):** Inner badge padding
- **`4px` (Tight):** Icon-to-text spacing
- **`8px` (Standard):** Spacing between grouped elements / tags
- **`12px` (Medium):** Card inner padding, list item gaps
- **`16px` (Default):** Screen horizontal padding, section margins
- **`24px` (Loose):** Major section separators
- **`32px` (Spacious):** Modal / Dialog outer margin
- **`48px+` (Hero):** Bottom CTA scroll padding to prevent FAB overlap

### Elevation & Corner Radius
- **Cards & Containers:** `BorderRadius.circular(12)` to `16`, `border: Border.all(color: Color(0xFFE2E8F0))`
- **Pills & Filter Chips:** `BorderRadius.circular(20)` to `30`
- **Primary CTA Buttons:** `BorderRadius.circular(12)`, min height `52dp`, elevation `0` (flat modern Material 3)
- **Bottom Navigation Bar:** `elevation: 8`, crisp top border `Color(0xFFE2E8F0)`

---

## ⚡ 5. Micro-Interactions & Haptic Feedback

- **`AppFeedback.selection()`:** Fired on bottom navigation taps, sticky tab switching, and category filter chips.
- **`AppFeedback.light()`:** Fired on card taps, expansion toggles, and search clearing.
- **`AppFeedback.medium()`:** Fired on bookmarking schemes and successful profile save events.
- **Motion Timing:**
  - Micro transitions: `150ms` (`Curves.easeOut`)
  - Page transitions & sheet reveals: `300ms` (`Curves.easeInOut`)

---

## 🔍 6. Comprehensive Audit: Negatives, Drawbacks & Anti-Patterns

### ⚠️ Current Drawbacks & Resolution Matrix

| Category | Identified Drawback / Negative | User Impact | Architecture Fix |
| :--- | :--- | :--- | :--- |
| **Architecture** | Monolithic screen files (>1,500 lines) | High risk of state bleed and regression | Extracted modular components (`SchemeExpandableSection`, `SearchEmptyState`, `HomeQuickPills`). |
| **Cognitive Load** | Visual crowding on Scheme Details (6 tabs + 5 open accordions) | Citizens get overwhelmed trying to find if they qualify | Default **Benefits & Eligibility** to open; keep procedural sections (Services, Process) collapsed. |
| **Navigation** | Search screen pre-query overload (4 competing sections) | First-time users hesitate on what to tap | Progressive disclosure with focused search bar and `SearchEmptyState` suggestions. |
| **Localization** | Untranslated technical bureaucratic jargon in Tamil | Rural artisans cannot understand complex financial terms | Added conversational subtitles and comprehensive `.arb` translation keys. |
| **Performance** | Main-thread catalog decompression on startup | Micro-stutters and frame drops on budget Android phones | Decompression and parsing offloaded to background isolate via `compute()`. |
| **Network** | Unauthenticated background Supabase cloud upserts | Unhandled exceptions and console trace spam in guest mode | Guarded background cloud sync with `_isLoggedIn` and null-safety session checks. |
| **Forms** | Misplaced locality into district on reverse-geocoding | Users blocked with red validation errors | Created `LocationHelper.parsePlacemark` to place villages/sub-localities into Area field. |

---

## 📱 7. Mobile Viewport & Accessibility Rules

1. **SafeArea on Every Viewport:** No UI controls may overlap status bars or gesture bars.
2. **SingleChildScrollView Enclosure:** All pages with form fields or dynamic lists must scroll smoothly to accommodate the virtual keyboard (`resizeToAvoidBottomInset: true`).
3. **Minimum Touch Targets:** All interactive controls (icons, chips, buttons) must meet or exceed **$48 \times 48\text{ dp}$**.
4. **No Magic Numbers:** All padding and typography must derive from `AppConstants` and `Theme.of(context)`.
5. **Offline Resiliency:** Every scheme, filter, and profile screen must remain 100% interactive when network connectivity is lost.
