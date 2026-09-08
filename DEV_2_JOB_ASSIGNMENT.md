# Developer 2 Work Package: Navigation, Companion Ergonomics, Typography & Accessibility

> **Assigned Scope:** Main Shell Navigation, Text Scale Accessibility, Companion Mode Usability, Widget Typography & Touch Targets  
> **Target Module/Files (Exclusive to Dev 2):**
> 1. `frontend/lib/main.dart`
> 2. `frontend/lib/screens/companion_mode/saarthi_home_screen.dart`
> 3. `frontend/lib/widgets/scheme_card.dart`
> 4. `frontend/lib/screens/profile_screen.dart`
> 5. `frontend/lib/screens/regular_mode/help_support_screen.dart` (star rating semantics)
>
> ⚠️ **Merge Collision Prevention Guarantee:** Dev 2 only touches global navigation structure, text scaler limits, widget aesthetics/touch targets, and companion UI. Dev 2 **does NOT** touch `eligibility_results_screen.dart`, `splash_screen.dart`, `login_screen.dart`, `basic_profile_screen.dart`, or `app_state_provider.dart`.

---

## 1. Context & Codebase Reality Check (Pre-Analysis)

Before starting work, review the verified audit status of your target files:
* **`main.dart` Text Scaling Clamp:** **UNFIXED.** Currently lines 179–182 hardcode:
  ```dart
  final boundedScale = deviceScale.clamp(
    isTamil ? 1.0 : 1.20,
    isTamil ? 1.12 : 1.30,
  );
  ```
  This violates WCAG 2.2 AA (1.4.4 Resize Text) and blocks elderly or low-vision users from scaling up to 2.0x.
* **`main.dart` Companion Mode Stripping Bottom Bar:** **UNFIXED.** Line 435 has `provider.navigationMode == 'companion' ? null : Container(...)`. When in companion mode, the bottom navigation bar is completely removed, stranding users if voice fails.
* **`saarthi_home_screen.dart` Hardcoded Greeting `"Praveen"`:** **UNFIXED.** Lines 1020–1022:
  ```dart
  final userName = provider.profile.name.isNotEmpty
      ? provider.profile.name.split(' ')[0]
      : 'Praveen';
  ```
  If profile has no name, it arbitrarily addresses the user as "Praveen" instead of a friendly neutral greeting.
* **`saarthi_home_screen.dart` Non-Interactive Language Pill:** **UNFIXED.** Line 1091 has a language display container with no `InkWell` or `GestureDetector` to toggle language.
* **`widgets/scheme_card.dart` Micro-Typography & Touch Targets:** **UNFIXED.** Uses 8.5sp and 9.0sp text (lines 266, 311) and 30x30dp bookmark button (line 333) with missing `Semantics` tags.
* **`screens/profile_screen.dart` Camera Avatar Touch Target:** **UNFIXED.** Line 577 uses a small 24x24dp camera icon.

---

## 2. Task Breakdown for Developer 2

### Task 2.1: WCAG Text Scaling Un-clamping (`main.dart`)
* **Objective:** Allow low-vision users to use up to 2.0x text scaling as required by WCAG 1.4.4.
* **Implementation Details:**
  1. In `main.dart` (lines 178–187):
     - Update text scale clamping:
       ```dart
       final boundedScale = deviceScale.clamp(0.85, 2.0);
       ```
     - Ensure layout flex and auto-wrapping widgets do not overflow. Check responsive constraints.

### Task 2.2: Retain Bottom Navigation in Companion Mode (`main.dart`)
* **Objective:** Give voice users an immediate escape hatch to regular tabs (Search, Discover, Saved, Profile).
* **Implementation Details:**
  1. In `main.dart`:
     - Remove the `provider.navigationMode == 'companion' ? null : ...` condition on `bottomNavigationBar`.
     - Keep the bottom navigation visible in both regular and companion mode.
     - Ensure clicking any bottom nav tab (e.g. Tab 1 Search or Tab 2 Discover) seamlessly switches tab and provides full navigation freedom.

### Task 2.3: Companion Mode Polish & Language Toggle (`saarthi_home_screen.dart`)
* **Objective:** Eliminate hardcoded mock data and fix dead touch targets.
* **Implementation Details:**
  1. In `saarthi_home_screen.dart`:
     - Replace hardcoded fallback `'Praveen'` with localized generic greeting:
       ```dart
       final defaultGreeting = provider.selectedLanguage == 'ta' ? 'நண்பரே' : 'Friend';
       final userName = provider.profile.name.trim().isNotEmpty
           ? provider.profile.name.trim().split(' ')[0]
           : defaultGreeting;
       ```
     - Wrap the Language Pill container (line 1091) in an `InkWell` / `GestureDetector` that calls `provider.changeLanguage(provider.selectedLanguage == 'ta' ? 'en' : 'ta')` with feedback.

### Task 2.4: SchemeCard Typography Floor & Touch Target Expansion (`widgets/scheme_card.dart`)
* **Objective:** Eliminate sub-11sp unreadable fonts, expand touch targets to minimum 48x48dp, and add screen reader semantics.
* **Implementation Details:**
  1. In `scheme_card.dart`:
     - Replace `fontSize: 8.5` with minimum `fontSize: 11.0`.
     - Replace `fontSize: 9.0` / `9.5` with minimum `fontSize: 11.0`.
     - Increase the bookmark touch target: expand tap area of the container to minimum 48x48dp (using padding or `BoxConstraints(minWidth: 48, minHeight: 48)`).
     - Wrap the card in `Semantics(button: true, label: 'Scheme: ${locScheme.name}', child: ...)` so TalkBack / VoiceOver announces it properly.

### Task 2.5: Minor Accessibility Fixes (`profile_screen.dart` & `help_support_screen.dart`)
* **Objective:** Improve small touch targets and screen reader ratings.
* **Implementation Details:**
  1. In `profile_screen.dart`:
     - Expand avatar camera icon tap container to 44x44dp (or add touch target padding).
  2. In `help_support_screen.dart`:
     - Add explicit `Semantics(label: '$starRating of 5 stars', child: IconButton(...))` to feedback dialog star buttons.

---

## 3. Verification & Testing Checklist for Developer 2
- [ ] Run `flutter test test/chat_log_service_test.dart` and ensure existing tests pass.
- [ ] Test text scaling: simulate 1.8x and 2.0x system font scaling to verify app text scales properly without breaking.
- [ ] Switch to Companion Mode in settings/home: verify the bottom navigation bar remains accessible and allows switching tabs.
- [ ] Check Saarthi greeting when profile has no name: verify it displays "Friend" / "நண்பரே" instead of "Praveen".
- [ ] Tap the Language Pill on Saarthi screen: verify it immediately toggles between English and Tamil.
- [ ] Check `SchemeCard`: verify touch target of bookmark button is easily tappable (>= 48x48dp) and font sizes are legible.
