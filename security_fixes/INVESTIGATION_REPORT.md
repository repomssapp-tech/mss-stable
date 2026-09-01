# Investigation Report: Deep Forensic Audit of `AUTOPLAN_REQUIRED_FIXES.md`

**Date:** August 27, 2026  
**Auditor / Engineer:** Antigravity AI  
**Methodology:** `gstack-investigate` (Systematic Root Cause Investigation: Investigate → Analyze → Hypothesize → Validate)  
**Target:** [`security_fixes/AUTOPLAN_REQUIRED_FIXES.md`](file:///c:/development/MSS%20App/MSS_App/security_fixes/AUTOPLAN_REQUIRED_FIXES.md)  

---

## 1. Executive Investigation Verdict

The autoplan proposal correctly identifies high-impact user problems, but a forensic examination of the actual source code reveals **3 architectural collisions**, **1 factual mischaracterization of existing code**, and **1 dependency runtime mismatch**. 

Without these root cause adjustments, executing the plan as written would cause:
1. Visual collision and content occlusion on `home_screen.dart`.
2. Redundant work in `basic_profile_screen.dart` (fixing a dropdown that does not exist).
3. Severe vertical squishing on `location_profile_screen.dart` when the Android virtual keyboard opens.
4. Broken npm scripts in `backend/` due to missing `ts-node`.

---

## 2. Forensic Findings & Root Cause Analysis

### Finding 1: Dual Voice Widget Collision & Content Occlusion
- **What the Plan Proposed:** Dock an ambient floating Saarthi voice pill at the bottom center of `home_screen.dart` above the bottom navigation bar.
- **Code Reality ([`home_screen.dart:324-326, 1694-1738`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/screens/regular_mode/home_screen.dart#L324-L326)):
  - `home_screen.dart` **already has** a floating circular voice button:
    ```dart
    Positioned(bottom: 30, right: 18, child: _buildAskAiFab(context))
    ```
    This widget renders the circular Saarthi mascot avatar (`assets/images/saarthi/sarathi.webp`) and calls `_openVoiceAssistant()`.
  - Adding a bottom-center pill alongside `_buildAskAiFab` creates visual competition and crowds the bottom viewport.
  - **Critical Layout Bug Discovered:** In `home_screen.dart:315-317`, the scrollable column's bottom spacing is only `const SizedBox(height: 24)`. When users scroll to the bottom, the floating button (height ~78dp + 30dp offset = 108dp) **completely occludes the "Tip of the Day" card**.
- **Root Cause:** Overlaying floating action widgets without sufficient bottom scroll padding in `SingleChildScrollView`.
- **Investigated Fix:** 
  1. Increase the bottom spacer from `24` to `110` so content is never occluded when scrolled to the bottom.
  2. Upgrade `_buildAskAiFab` into an elegant, unified ambient pill (`[ 🎙️ Ask Saarthi in தமிழ் or English ]`) positioned comfortably above the navigation bar.

---

### Finding 2: False Assumption on Gender Dropdown in Profile
- **What the Plan Proposed:** Convert modal dropdowns to horizontal choice chips for Gender in `basic_profile_screen.dart`.
- **Code Reality ([`basic_profile_screen.dart:251-274`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/screens/regular_mode/basic_profile_screen.dart#L251-L274)):
  - Gender is **already implemented** as 3 side-by-side visual boxes:
    ```dart
    _buildGenderBox('Male', Icons.male)
    _buildGenderBox('Female', Icons.female)
    _buildGenderBox('Other', Icons.transgender)
    ```
    There is no dropdown for gender in `basic_profile_screen.dart`.
  - The actual friction point is **Date of Birth (`_dobController`)**: it forces the citizen into the native Android calendar modal (`showDatePicker`), requiring them to navigate years and months even if they just want quick scheme matching.
- **Root Cause:** Review misattributed the calendar modal friction to a dropdown.
- **Investigated Fix:** Keep the existing 3 gender boxes; leave Date of Birth as an optional calendar picker with quick age bracket chips (`< 25`, `25-40`, `40-60`, `60+`) for instant 1-tap entry.

---

### Finding 3: Severe Keyboard Squish in Location Profile
- **What the Plan Proposed:** Add keyboard avoidance padding in `location_profile_screen.dart`.
- **Code Reality ([`location_profile_screen.dart:203-245, 313-322`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/screens/regular_mode/location_profile_screen.dart#L203-L245)):
  - Lines 204–221 render a large header **outside** the card (`complete_your_profile`, `location_subtitle`).
  - Lines 244–310 render a second redundant header **inside** the card (`Where Are You Located?`, `step_2_of_4`, progress stepper).
  - Lines 313–506 place an `Expanded(child: SingleChildScrollView(...))` for the 5 address text fields.
  - Lines 509–525 place a non-scrollable sticky button (`ElevatedButton`) pinned at the bottom of the card.
  - Total non-scrollable height before inputs: ~250px. Sticky button height: ~92px.
  - **Failure Mode:** When the Android virtual keyboard opens (consuming ~300px), a standard 640–720px mobile viewport is reduced to ~340px. Because 250px + 92px = 342px are fixed/non-scrollable, the middle input area is reduced to **< 20px**, causing severe layout overflows and rendering editing impossible.
- **Root Cause:** Redundant dual headers and pin-fixed bottom button outside the scroll view.
- **Investigated Fix:** Merge headers into a single compact progress bar; ensure the bottom CTA button scrolls naturally with the form or uses `resizeToAvoidBottomInset: true` with dynamic collapsing.

---

### Finding 4: Dependency Stack Mismatch in Link Checker Script
- **What the Plan Proposed:** Add `backend/scripts/verify_scheme_links.ts` executed with `ts-node`.
- **Code Reality ([`backend/package.json`](file:///c:/development/MSS%20App/MSS_App/backend/package.json)):
  - `package.json` contains:
    - `"devDependencies": { "@redocly/cli": "2.39.0", "supabase": "2.109.1" }`
  - There is **no TypeScript**, **no `ts-node`**, and **no `@types/node`** in `backend/`.
  - All existing maintenance scripts (such as `scripts/import_catalog.mjs`) are standard Node.js ES modules (`.mjs`).
- **Root Cause:** Proposing a TypeScript file without checking existing backend tooling.
- **Investigated Fix:** Author the verification script as [`backend/scripts/verify_scheme_links.mjs`](file:///c:/development/MSS%20App/MSS_App/backend/scripts/verify_scheme_links.mjs). Native Node 20+ has built-in `fetch`, requiring **0 extra npm dependencies** and executing instantaneously via `node scripts/verify_scheme_links.mjs`.

---

## 3. Revised & Hardened Implementation Blueprint

Based on this investigation, here is the corrected, conflict-free implementation roadmap:

| Step | Component | Target File | Corrected Action |
|---|---|---|---|
| **1** | Layout Fix | `frontend/lib/screens/regular_mode/home_screen.dart` | Increase bottom scroll spacing to `110dp` to fix card occlusion; refine `_buildAskAiFab` into an ambient pill without duplicating buttons. |
| **2** | Keyboard Fix | `frontend/lib/screens/regular_mode/location_profile_screen.dart` | Eliminate redundant duplicate header; make input scroll area resilient to soft keyboard popups. |
| **3** | Script Tooling | `backend/scripts/verify_scheme_links.mjs` | Write zero-dependency ES module checking `AppConstants.documentLinks` and active schemes via native Node 20 `fetch`. |
| **4** | NPM Script | `backend/package.json` | Add `"verify:links": "node scripts/verify_scheme_links.mjs"`. |
| **5** | CI Workflow | `.github/workflows/url-health-check.yml` | Weekly cron running `npm run verify:links`. |
