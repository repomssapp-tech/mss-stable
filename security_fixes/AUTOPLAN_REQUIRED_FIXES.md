# Auto-Reviewed Implementation Plan: Next-Phase Required Fixes & Enhancements

**Date:** August 27, 2026  
**Pipeline:** `/autoplan` (Sequential CEO → Design → Eng → DX Review with Auto-Decisions)  
**Target:** MSS App Ecosystem (`frontend/`, `backend/`, `saarthi-agent/`)  
**Status:** Awaiting User Gate Approval  

---

## Executive Intake Summary

- **Context Analyzed:**
  - `git diff` & `git log`: Remediated 8 security breaches (RLS, Auth config, Prompt injection, CI secrets, Android backup) + 5 design/UX fixes (Tamil line-heights, card elevation, document links, zero-match recovery, DPDPA notice).
  - Codebase: Supabase PostgreSQL backend, Flutter Material mobile client, Python LiveKit/Sarvam AI voice agent.
- **Scope Detection:**
  - **UI Scope:** **YES** (Navigation mode unification, choice chip ergonomics in 4-step profile, voice visualizer state indicators).
  - **DX Scope:** **YES** (Remote migration deployment runbook, automated scheme link health-check utility, WebRTC audio fallback handler).

---

## 1. Phase 1: CEO Review (Strategy & Scope)

### 1.1. Premise Challenge (0A)
- **Premise 1:** *Citizens should choose between "Regular" and "Companion" navigation during onboarding.*
  - **Challenge:** Forcing a binary choice before showing any value increases cognitive drop-off. Most users don't know what "Companion" means until they experience voice assistance.
  - **Decision (Auto-decided via P5 - Explicit & P1 - Completeness):** Unify onboarding into a single high-conversion path. Home dashboard presents traditional visual browsing with an ambient, floating conversational Saarthi pill. The dedicated full-screen Companion Mode remains directly accessible via a toggle.
- **Premise 2:** *External scheme application portals and document links are reliable.*
  - **Challenge:** Indian state government portals frequently change URL routing, undergo maintenance, or deprecate pages without notice. Broken links cause severe trust erosion.
  - **Decision (Auto-decided via P2 - Boil Lakes):** Add a lightweight, scheduled URL validation script in `backend/` that scans `AppConstants.documentLinks` and active scheme URLs to flag broken links before citizens hit 404 errors.

### 1.2. Dream State Delta (0C)

```
CURRENT STATE (Local Hardening Complete)
  [Supabase Local Migrations] ──> [Flutter Client with DPDPA & Links] ──> [Saarthi Agent Isolated]
            │
            ▼ (THIS PLAN: Production Readiness & UX Unification)
  [Live DB Migration Push] ──> [Unified Home + Ambient Voice Pill] ──> [Automated URL Health Verifier]
            │
            ▼ (12-MONTH IDEAL)
  [1-Click DigiLocker Auto-Fill] ──> [Full Offline Voice Edge TTS] ──> [Direct DBT Benefit Tracking]
```

### 1.3. Implementation Alternatives Table (0C-bis)

| Approach | Effort | Risk | Pros | Cons | Decision |
|---|---|---|---|---|---|
| **A: Full Production Readiness (Recommended)** | 3-4 days | Low | Deploys live RLS migration, unifies home navigation, adds chip inputs, and deploys URL validator. | Touches 5 files across backend and frontend. | **ACCEPTED (P1: Completeness)** |
| **B: UI Only (Defer Live DB & URL Tooling)** | 1 day | High | Fast frontend cosmetic updates. | Leaves live remote Supabase unpatched; citizen links still risk 404s. | **REJECTED (Violates P2: Boil Lakes)** |
| **C: Minimal Patch (DB Push Only)** | 2 hours | Medium | Solves remote database compliance only. | Leaves UX friction on profile and navigation screens. | **REJECTED (Violates P1: Completeness)** |

---

## 2. Phase 2: Design Review (UI & Visual Hierarchy)

### 2.1. Information Hierarchy & Navigation Wayfinding
1. **Omnipresent Ambient Voice Pill:**
   - On `home_screen.dart`, add a persistent, elevated bottom pill:
     `[ 🎙️ Ask Saarthi in தமிழ் or English ]` with animated audio waveform dots.
   - Tapping it smoothly launches `VoiceAssistantOverlay` or expands into full-screen `SaarthiHomeScreen`.
2. **Choice Chip Simplification (4-Step Profile Wizard):**
   - In `basic_profile_screen.dart`, `location_profile_screen.dart`, and `about_you_profile_screen.dart`:
   - Replace dropdown selectors for fields with ≤ 5 options (Gender: Male, Female, Other; Education: 10th, 12th, Graduate, Post-Graduate) with horizontal wrap chips.
   - Eliminates modal bottom-sheet friction.

### 2.2. Design Litmus Scorecard

| Dimension | Target Score | Solution in this Plan |
|---|---|---|
| **Visual Hierarchy** | 9/10 | Ambient voice pill anchors bottom without obscuring the bottom navigation bar. |
| **Interaction States** | 9/10 | Added tactile spring animation when tapping chips and visualizer status during speech. |
| **Accessibility & Spacing** | 9.5/10 | All interactive chips maintain 48dp touch targets and 8dp spatial gaps. |

---

## 3. Phase 3: Engineering Review (Architecture & Failure Modes)

### 3.1. Data Flow & Network State Machine

```
[Citizen Input]
       │
       ▼
[Offline/2G Detection] ──(Slow/No Audio)──> [Fallback to HTTP Text Stream]
       │ (High Speed)
       ▼
[LiveKit WebRTC Audio] ──> [Sarvam AI Pipeline] ──> [TTS Playback]
```

### 3.2. Error & Rescue Registry

| Codepath | Failure Mode | Trigger | Catching Handler | User Feedback |
|---|---|---|---|---|
| `MssApiClient.supabase` | Live DB RLS denial | User queries profile of another user | PostgREST HTTP 403 (PGRST301) | Handled in repository: returns null safely; never crashes UI. |
| `LiveKit WebRTC` | Rural 2G packet loss | Cell tower handover in Tier 2/3 districts | `RoomEvent.disconnected` / timeout | Client automatically switches to streaming text mode: *"Voice connection low. Switching to text."* |
| `External URL Check` | Official portal down | State government server maintenance | Health check script HTTP status != 200 | Admin notification; in-app card displays: *"Government portal currently undergoing scheduled maintenance."* |

---

## 4. Phase 4: Developer Experience (DX) & Deployment Runbook

### 4.1. Remote Supabase Deployment Protocol
Runbook for applying verified migrations to production:
```bash
# Step 1: Link to live project
cd backend
npx supabase link --project-ref houpzsxmwemoztpuigmo

# Step 2: Dry-run migration diff
npx supabase db diff

# Step 3: Push pending migrations (including 20260818000000_restore_orphaned_rls_policies.sql)
npx supabase db push
```

### 4.2. Automated URL Health-Checker Script (`backend/scripts/verify_scheme_links.ts`)
- Script reads `frontend/lib/utils/constants.dart` (`documentLinks`) and schemes catalog.
- Performs asynchronous `HEAD` / `GET` requests with a 5-second timeout.
- Generates a markdown report `docs/PORTAL_HEALTH_REPORT.md` listing active vs broken URLs.

---

## 5. Final Approval Gate: Taste Decisions & User Challenges

The 6 principles auto-decided all mechanical engineering choices. The following taste decisions and strategic choices are surfaced for your explicit confirmation:

### Taste Decision 1: Ambient Saarthi Voice Pill Placement
- **Option A (Recommended):** Persistent floating pill docked at the bottom center of `home_screen.dart`, right above the bottom navigation bar. (Maximum accessibility, effortless discovery).
- **Option B:** Top header banner pill next to profile avatar. (Slightly less prominent, keeps bottom canvas 100% clear).
- *Autoplan Recommendation:* **Option A** because voice-first civic tech should be thumb-accessible.

### Taste Decision 2: Automated Portal Health Check Execution
- **Option A (Recommended):** Scheduled weekly GitHub Actions workflow that executes `verify_scheme_links.ts` and opens a GitHub issue if government URLs break.
- **Option B:** Local manual npm script run by developers before releases.
- *Autoplan Recommendation:* **Option A** because government URLs rot silently in production.

---

## Proposed File Changes for Execution

| Component | Target File | Action | Summary of Change |
|---|---|---|---|
| **Frontend** | `frontend/lib/screens/regular_mode/home_screen.dart` | `[MODIFY]` | Add ambient floating Saarthi voice pill above bottom navigation. |
| **Frontend** | `frontend/lib/screens/regular_mode/basic_profile_screen.dart` | `[MODIFY]` | Convert modal dropdowns to horizontal choice chips for Gender & Age bracket. |
| **Frontend** | `frontend/lib/screens/regular_mode/location_profile_screen.dart` | `[MODIFY]` | Add responsive scroll padding so keyboards never cover District/State controls. |
| **Backend** | `backend/scripts/verify_scheme_links.ts` | `[NEW]` | Automated URL validation utility checking all external portal and document links. |
| **Backend** | `backend/package.json` | `[MODIFY]` | Add script `"verify:links": "ts-node scripts/verify_scheme_links.ts"`. |
| **Workflow** | `.github/workflows/url-health-check.yml` | `[NEW]` | Weekly automated portal uptime validation workflow. |

---

## Verification Plan
1. **Flutter Analysis:** `flutter analyze` in `frontend/` (0 issues).
2. **Link Verifier Test:** Run `npm run verify:links` in `backend/` to ensure all government portal links respond.
3. **UI Verification:** Test ambient voice pill launch and chip selection responsiveness in Flutter.
