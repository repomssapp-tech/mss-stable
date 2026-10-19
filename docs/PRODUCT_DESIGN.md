# MSS — Product Design Document

**Product name:** MSS (MSME Schemes Search — Government Scheme Discovery & Eligibility Platform)
**Document version:** 1.0
**Date:** 2026-09-16

### Revision History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-09-16 | Claude (AI assistant), reviewed by project owner | Initial Product Design Document created |

### Relationship to other docs

This document covers the **why** behind product decisions: problem, users, goals, information architecture, and the reasoning behind key UX choices. It does not repeat:
- **Visual tokens, component specs, and the full screen-by-screen spec** → `docs/UI_UX_DESIGN_SYSTEM.md`
- **Technical architecture, data model, tech stack** → `docs/SOFTWARE_DEVELOPMENT_DOCUMENT.md`
- **Deployment/infra** → `docs/DEPLOYMENT_ARCHITECTURE.md`

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Users & Personas](#2-users--personas)
3. [Product Goals & Non-Goals](#3-product-goals--non-goals)
4. [Design Principles](#4-design-principles)
5. [Information Architecture](#5-information-architecture)
6. [Core User Journeys](#6-core-user-journeys)
7. [Key Design Decisions & Rationale](#7-key-design-decisions--rationale)
8. [Content & Language Strategy](#8-content--language-strategy)
9. [Accessibility Commitments](#9-accessibility-commitments)
10. [Success Metrics](#10-success-metrics)
11. [Open Questions](#11-open-questions)

---

## 1. Problem Statement

Indian MSME owners, artisans, and individual citizens are eligible for a wide range of government welfare schemes, subsidies, and loans — but discovering which schemes apply to them, and understanding what to do next, is fragmented across dozens of government portals with inconsistent language, bureaucratic phrasing, and no single source of truth. Most citizens either don't know a scheme exists, don't know if they qualify, or give up navigating the application process.

MSS exists to close that gap: **one app where a citizen can find every scheme they're plausibly eligible for, understand it in plain language (in their own language), and know exactly what to do next.**

---

## 2. Users & Personas

| Persona | Profile | Primary need | Preferred mode |
|---|---|---|---|
| **The MSME Owner** | Runs a small business/workshop, moderate literacy, time-constrained | Fast, targeted answers: "what am I eligible for right now" | Regular mode, eligibility-driven |
| **The Rural / First-time Applicant** | Lower digital/English literacy, may prefer speaking over typing | Guided, conversational discovery in Tamil or English | Companion (voice) mode |
| **The Explorer / Researcher** | Comfortable navigating apps, wants to browse broadly, compare schemes, plan ahead | Precise search and category browsing without being boxed into "matches for me" | Regular mode, search-first |

These three needs are why the app forks into **two navigation modes** (Regular vs. Companion) at onboarding rather than picking one interaction paradigm for everyone — see [Section 7](#7-key-design-decisions--rationale).

---

## 3. Product Goals & Non-Goals

**Goals**
- Let a user go from "I don't know what I qualify for" to "here is my list, here is what to do" in as few steps as possible.
- Support both self-directed search/browse and voice-guided discovery equally well, not as a secondary/fallback path.
- Work offline or on poor connectivity for catalog browsing (see `OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md`).
- Be usable by someone with limited English and limited app literacy — Tamil is a first-class language, not a translation afterthought.

**Non-Goals (current phase)**
- MSS does not submit applications on the user's behalf or integrate with government application portals — it discovers, explains, and guides ("Application Guide"), it does not transact.
- MSS does not verify eligibility with legal certainty; eligibility results are a matching aid, not a determination of entitlement (see disclaimers in `legal_screens.dart`).
- No multi-tenant/business-account model — the app is built around one individual user profile at a time.

---

## 4. Design Principles

These are the product-level principles that the visual/UX design system (`UI_UX_DESIGN_SYSTEM.md`) is built to express:

1. **Civic Authority + Consumer Warmth** — trustworthy like a government portal, easy like a modern consumer app.
2. **Zero dead ends** — every screen has a next action; empty states, errors, and offline states all still point somewhere.
3. **Plain language over bureaucratic language** — scheme content is rewritten for comprehension, not copy-pasted from government notices.
4. **Two ways in, one system underneath** — Regular (self-directed) and Companion (voice-guided) modes share the same catalog, eligibility engine, and scheme detail/application-guide content, so switching modes never loses the user's underlying profile or progress.
5. **Precision before personalization** — search answers the literal query first; eligibility/"for me" personalization is opt-in, never silently applied (see [Section 7](#7-key-design-decisions--rationale)).

---

## 5. Information Architecture

```
Splash
 └─ Language Selection
     └─ Google Sign-In
         └─ Choose Navigation Mode ──────────────┬─────────────────────────┐
                                                   │                         │
                                          Regular Mode                Companion Mode
                                                   │                         │
                                  Minimal Profile Setup          Saarthi Welcome Screen
                                                   │                         │
                        ┌──────────────┬───────────┼─────────────┐   Saarthi Home (voice)
                        │              │           │             │          │
                   Home Dashboard  Search    Categories    Notifications   Voice Agent
                        │              │           │             │        (listen → think → explain)
                 Recommended/Updates   │           │             │
                        │              ▼           ▼             │
                        └────► Search Results / Eligibility Results
                                       │
                                Scheme Details ──► Application Guide
                                       │                │
                                Document Checklist   Saved Schemes
                                       │
                             Profile / Eligibility Profile / Settings / Help & Support
```

**Primary nav (Regular mode):** Home, Search, Categories/Discover, Notifications, Profile.
**Primary nav (Companion mode):** single conversational surface (Saarthi) with voice listening → AI thinking → AI explanation as the core loop, still able to surface the same Scheme Details / Application Guide screens as Regular mode.

Both modes converge on the same terminal screens (Scheme Details, Application Guide, Saved Schemes, Profile) — this is deliberate: mode is an *entry paradigm*, not a separate app.

---

## 6. Core User Journeys

### 6.1 First-time onboarding → first result
Splash → Language Selection → Google Sign-In → Choose Navigation Mode → (Regular: Minimal Profile Setup; Companion: Saarthi Welcome) → first scheme result surfaced within the same session.
*Design intent: a first-time user should see at least one relevant scheme before being asked to complete a full profile — profile depth is earned progressively, not front-loaded as a form wall.*

### 6.2 Targeted search (Regular mode)
Home/Search → type or filter query → Search Results (literal match, unweighted) → optionally apply "For Me" eligibility filter chip → Scheme Details → Application Guide → Document Checklist.

### 6.3 Guided discovery (Companion mode)
Saarthi Home → Voice Listening → AI Thinking → AI Explanation (conversational, references the same catalog/eligibility data) → hands off to Scheme Details / Application Guide when the user wants the full written version.

### 6.4 Eligibility-first browsing
Eligibility Profile Screen (structured questions: business type, location, category, etc.) → Eligibility Results Screen (ranked/filtered by profile) → Scheme Details.

### 6.5 Return visit
Home Dashboard (Recommended Schemes Carousel + Government Updates) and/or Notifications → Saved Schemes as the "where did I leave off" anchor.

---

## 7. Key Design Decisions & Rationale

**Two navigation modes chosen at onboarding, not toggled per-screen.**
Voice-first (Companion) and search-first (Regular) are different mental models, not different themes on the same flow. Forcing users to declare intent once at onboarding avoids a cluttered "mode switch" affordance living permanently in the UI, while still letting both modes read/write the same profile and saved-schemes state underneath.

**Regular search stays literal; "For Me" is an explicit opt-in filter, not automatic personalization.**
Early design considered silently weighting search results by the user's stored profile. This was rejected: a user searching for a specific scheme by name expects that scheme to rank first regardless of whether they're eligible for it, and silent reranking erodes trust in the search bar. Personalization is instead surfaced as a visible, dismissible "For Me" chip on Search/Discover — an eligibility *filter* the user turns on, not a ranking signal applied invisibly.

**Profile setup is minimal at signup, deepened later via Eligibility Profile.**
`basic_profile_screen.dart` collects only what's needed to personalize the home dashboard; `eligibility_profile_screen.dart` is a separate, deliberately longer flow entered only when the user wants ranked eligibility results. This avoids penalizing users who just want to browse/search with an upfront form burden.

**Scheme content is separated from the eligibility engine.**
Scheme Details / Application Guide content is authored/curated catalog content (plain-language rewrite of official scheme text); eligibility matching is a structured, versioned data model (see `SOFTWARE_DEVELOPMENT_DOCUMENT.md` §6). This separation is why catalog content is kept out of the UI localization files — it's content data, not UI chrome, and is localized through the catalog pipeline instead.

**Offline-first catalog browsing.**
Because target users may have unreliable connectivity, scheme browsing/search works against a locally cached catalog bundle rather than requiring a live network call per screen (see `OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md`). This shaped the IA choice to keep Search/Categories/Scheme Details as catalog-driven screens, with only account-specific state (Saved, Notifications, Profile sync) requiring network.

---

## 8. Content & Language Strategy

- Tamil and English are both first-class, not primary/secondary — UI chrome strings live in ARB (`frontend/lib/l10n`) and are kept in sync across both languages.
- Scheme catalog content (names, descriptions, eligibility text, application guides) is authored/localized separately from UI chrome, through the catalog content pipeline, not the ARB files — this keeps content updates decoupled from app releases.
- Voice mode (Saarthi/Sarvam) is the primary accessibility path for users who would struggle with reading dense scheme text, not an add-on feature.

---

## 9. Accessibility Commitments

Full token-level contrast/typography specs live in `UI_UX_DESIGN_SYSTEM.md` §2–3 and §7. At the product level:
- Every discovery path (search, browse, voice) must reach the same underlying scheme data — no path is a degraded/partial experience.
- Empty, offline, loading, and error states are treated as first-class screens (not silent failures), so a user with poor connectivity always knows what's happening and what to do next.
- Minimum outdoor-readable contrast and voice-first affordances are product requirements driven by the rural/low-literacy persona, not aesthetic choices.

---

## 10. Success Metrics

Candidate product-level signals (to be instrumented, not yet formally tracked as of this version):
- Time-to-first-relevant-result from cold start (onboarding → first scheme viewed).
- % of sessions that reach Scheme Details or Application Guide (discovery → action intent).
- Companion vs. Regular mode split, and cross-over rate (users who start in one mode and end in the other's terminal screens).
- Saved Schemes retention (return visits driven by Saved/Notifications vs. fresh search).

---

## 11. Open Questions

- Should mode choice (Regular vs. Companion) be revisitable/switchable post-onboarding, or is a one-time choice sufficient long-term?
- What's the intended behavior when eligibility profile data conflicts with a "For Me" filtered search (e.g., profile says ineligible for a scheme the user explicitly searched by name)?
- Success metrics above are proposed, not instrumented — needs alignment with backend/analytics on what's actually being logged today.
