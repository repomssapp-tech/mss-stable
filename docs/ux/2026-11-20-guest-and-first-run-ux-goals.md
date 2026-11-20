# Guest and first-run UX: goals, issues and plan

Written 2026-11-20, against `main` at `c502a55` (after PR #205). App only: the backend (DEV 1 tasks 1.2–1.4) is another dev's work.

Each goal below has four parts: what done looks like, the current issue with file references, and the proposed change. Decisions that need an answer are collected at the end.

---

## Goal 1. A guest chooses Regular or Saarthi mode; voice is locked behind sign-in

**Done when**
- A guest sees the same mode choice as a signed-in user.
- In Saarthi mode, typing to Saarthi works and voice shows a lock with a sign-in prompt.

**Issues now**
- Guests skip the mode screen entirely, in three places:
  - `resolveStartupDestination` sends a guest straight home (`lib/screens/splash_screen.dart`).
  - Login's `_continueAsGuest` goes to `MainTabsContainer`.
  - The navigation-mode Continue button skips ahead for guests.
- Companion mode is forced off for guests: `_buildTabs` in `lib/main.dart` uses `navigationMode == 'companion' && !provider.isGuest`.
- **Typed chat also needs an account today**, not only voice:
  - Both go through `HttpVoiceAgentController`, which is only available when `AppSession.instance.isSignedIn` (`lib/services/voice/http_voice_agent_controller.dart:32-38`).
  - `SarvamChatService.complete` throws "Sign in to chat with Saarthi." for signed-out users (`lib/services/chat/sarvam_chat_service.dart:60`).
- So "typed open, voice locked" cannot work on the server until DEV 1 task 1.4's guest token exists (decision D1).

**Change**
- Show the mode screen to guests, without sending them to the profile form afterwards.
- Allow companion mode for guests.
- In the Saarthi screen, show the mic as locked for a guest, and make tapping it open the sign-in sheet.
- Typed chat for guests depends on D1.

## Goal 2. App tour for everyone, once, shown with the home screen

**Done when**
- Every user sees the tour on their first home visit: guest or signed-in, regular or Saarthi mode.
- Signing out and back in to the same account does not show it again.
- The tour appears together with home, not after home has finished drawing.

**Issues now**
- **Sign-out brings the tour back.**
  - The tour is stored in SharedPreferences under `home_tour_v1_<userId>` (`lib/services/onboarding/home_tour_store.dart`).
  - Sign-out calls `SessionCacheService.clearSession()`, which runs `prefs.clear()` and deletes that key. So the same account sees the tour again.
- **A guest never sees it.**
  - `HomeTour.maybeStart` returns `notApplicable` when there is no user id (`lib/widgets/onboarding/home_tour.dart:40-43`).
  - `HomeTourStore.isDone('')` returns true.
- **It arrives late.**
  - `_showHomeTourWhenReady` in `lib/main.dart` waits a fixed 1800 ms, then retries every 1000 ms up to 8 times.
  - So home is drawn and usable first, and the overlay drops on top later.
- **Saarthi mode gets no tour.** The loop skips `navigationMode == 'companion'`.

**Change**
- Keep tour records out of `prefs.clear()`: `clearSession` keeps the `home_tour_v1_*` keys.
- Add a device-level record for guests, `home_tour_v1_guest`.
- After a guest signs in on the same phone, don't show the tour again. The device record counts (decision D2).
- Start the tour on the first frame where its targets are laid out, with no fixed delay. Home is covered by the tour scrim from its first frame, so the user never sees a bare home and then a jump.
- Saarthi mode gets its own short tour: mic, typing, history.

## Goal 3. Realistic use in both cases

**Done when** each screen is designed around what a guest and a signed-in user really do there.

Expected first sessions:
- **Guest:** find a scheme for my business in my state, open it, check whether I qualify, maybe save it (sign-in prompt).
- **Signed-in:** see what's new or matched for me, continue where I left off.

**Issues now**
- Guest home puts the 0% "Profile incomplete / Sign in" card above the schemes (`home_screen.dart`, the `HomeProfileCompletionCard` block). The first thing a guest sees asks them to sign in before they've found any value.
- A guest has no eligibility check of their own. The questionnaire (26 fields, PR #201) has no UI yet; that is DEV 2's work. Today's "For me" is hidden for guests, so a guest gets no way to ask "do I qualify?"

**Change**
- For guests, move the sign-in card below "Top schemes in {state}".
- Add a "Check my eligibility" entry that leads into the questionnaire. Answers are stored on the phone (Goal 8) and moved to the account on sign-up.

## Goal 4. Guest and signed-in get equal visual weight

**Done when** a guest never sees a smaller, greyed or second-class version of a screen. Locked features look like features with a lock, not like errors.

**Issues now**
- **Login:**
  - "Continue as guest" is a plain `TextButton` under a full-width "Continue with Google" `OutlinedButton` (`lib/screens/login_screen.dart`, `_buildLoginForm`).
  - It reads as a fallback link, not an equal choice.
  - It is greyed until Terms and Privacy are read, but nothing next to it says so.
- **Greeting:** guest home says "User" / "वापरकर्ता" with a smaller title style. `home_header_section.dart` picks `titleMedium` for guests and `headline` for signed-in users.
- **Hidden features:** Settings and Search hide account features for guests (PR #205). Hiding is right for account-only rows (delete account). But features that sign-in would unlock, such as For me and Saarthi voice, should show with a lock so the guest knows they exist.

**Change**
- **Login:** two equal buttons, "Continue with Google" and "Continue as guest", the same size and style. A short line under each says what you get.
- **Greeting:** guest home uses the same headline style, with a neutral greeting such as "Welcome" instead of "User".
- **Locked features:** keep them visible with a lock icon; tapping one opens the sign-in sheet.

## Goal 5. The first action is the most prominent; no screen is a dead end

**Done when**
- Each screen has one clear primary action, the visually strongest element.
- Each screen has a visible, sensible way out: back, home, or the next step.

**Issues now (found in code; still to be checked on a device)**
- **Navigation mode screen:**
  - Its back arrow replaces the route with `LanguageSelectionScreen` (`navigation_mode_screen.dart`, the `AppIconButton` at about line 80).
  - It's a reset rather than a back, and from guest or settings entry it goes somewhere unexpected.
- **Sign-in sheet:** "Sign in" runs `pushAndRemoveUntil(LoginScreen)`. If the user backs out of login, there is nothing to return to, so they can't get back to their guest session without the "Continue as guest" button.
- **Login screen:** reached from guest mode it has no back or close, only the two continue buttons.
- **Guest home:** the strongest element is the sign-in card, not "find a scheme" (see Goal 3).

**Change**
- Do a per-screen audit on a device, for guest and signed-in. For each screen, record:
  - its primary action,
  - its way out,
  - any dead end.
- Fix in this order: login (from guest), sign-in sheet, navigation mode, home.
- Login opened from guest mode gets a close button that returns to the guest session.

## Goal 6. Design and UX that build traction

**Done when** a new user reaches value fast and is asked to sign in at a moment of value, not at a wall.

**Measures to track:**
- time to the first scheme opened,
- % of guests who open a scheme,
- % of guests who sign in, and from which prompt,
- tour completion versus skip.

**Issues now**
- There is no analytics event for any of these, so traction can't be measured.
- Sign-in prompts come up when an action is blocked (save, bell, Saarthi). Good, but the sheet text is the same for every feature.

**Change**
- **Sign-in sheet:** per-feature copy, for example "Sign in to save this scheme".
- **Moment of value:** after a guest finishes the eligibility questions, show their matches first, then offer to save them by signing in.
- **Analytics:** add events, using whatever analytics the app already has, or decide on one (decision D4).

## Goal 7. Proper user personas

**Done when** the personas cover today's audience and every screen decision above can point to one.

**Issues now**
- `docs/PRODUCT_DESIGN.md` §2 has three personas: MSME Owner, Rural / First-time Applicant, Explorer.
- There is no guest or trying-it-out persona.
- There is no Maharashtra or Marathi user, even though the Maharashtra questionnaire is the new focus.
- There is no aspiring entrepreneur, though `business_age = not_started_yet_aspiring` drives CMEGP and PMEGP.
- They mention Tamil or English only.

**Change.** Add these personas to `PRODUCT_DESIGN.md` §2:

| Persona | Who | First need | Mode | Signs in when |
|---|---|---|---|---|
| **Trying-it-out guest** | Heard of the app, unwilling to share Google or a phone number yet | See real schemes for my state fast | Regular | Wants to save, or wants voice |
| **Aspiring entrepreneur (Maharashtra)** | No business yet, Marathi first, considering CMEGP/PMEGP | "Can I get a loan or subsidy to start?" | Saarthi typed, or Regular | After seeing matches, to keep them |
| **Existing MSME owner** | Running a unit, Udyam-registered, time-poor | "What can I get for expansion or machinery?" | Regular | First visit, to sync |
| **Low-literacy rural applicant** | Prefers speaking, Marathi/Hindi/Tamil | Guided, spoken help | Saarthi voice | Needs it for voice |
| **Facilitator (DIC / bank / CA)** | Helps several clients | Browse and compare, share a scheme | Regular, search first | Rarely; mostly as a guest |

The last one is a guess, flagged so the officials can confirm whether facilitators are a target.

## Goal 8. A backbone to collect guest profile data

**Done when**
- A guest's answers to the 26 Maharashtra questions are stored on the phone, using the `questionnaire.json` value keys and answer shapes.
- They survive restarts, are validated, and are sent once on sign-up.
- DEV 2's questionnaire UI reads and writes through this one store.

**Issues now**
- No on-device answers store exists. `PendingEndpoints.guestUpgrade` documents the upload, but nothing calls it.
- `questionnaire.json` is only on PR #201 (open). `main` does not ship the asset yet.
- A guest's old-style `UserProfile` (name, state, and so on) is kept in SharedPreferences and sent through the existing profile write on sign-in. The 26 new fields are not in `UserProfile`.

**Change** (after PR #201 is merged)
- `QuestionnaireAnswersStore`:
  - stores `{field_id: value}` exactly as in DEV-SHARED's answer shape,
  - is versioned by `questionnaire.json` `schema_version`,
  - validates each answer against the asset: value keys, age 18–99, `{resident, district}`, `{total, women}`.
- It is kept on sign-out until uploaded, then cleared.
- **Upload on sign-up:**
  - Mark pending with the existing `guestAnswersUploadPending` marker.
  - Call `PendingEndpoints.guestUpgrade` once the backend route exists.
  - Until then, keep the answers on the phone.
- Hand-off to DEV 2: the store's API is the contract for their questionnaire UI.

---

## Decisions needed

| # | Question | Options |
|---|---|---|
| **D1** | Guest typed chat with Saarthi needs the server, which needs a guest token (task 1.4, other dev). What happens until then? | (a) Lock both typed and voice for guests until 1.4. (b) Typed answers come from the on-device catalog search (scheme cards, no AI), and AI replies arrive with 1.4. (c) Wait for 1.4 before shipping guest Saarthi mode. |
| **D2** | A guest saw the tour, then signs in on the same phone. Show it again? | Proposed: no. The device record counts for anyone on this phone. |
| **D3** | Does the Saarthi-mode tour ship in the same release as the home tour? | Proposed: yes, short (3 steps). |
| **D4** | Analytics for the traction measures. The app has none today: no analytics package in `pubspec.yaml`, no event calls. | (a) Add one (Firebase Analytics fits; FCM is already planned for push). (b) Count events on our own backend. (c) Skip measurement for now. |
| **D5** | Facilitator persona | Confirm with the officials whether facilitators are a target. |

## Proposed build order

1. **Tour fixes** (Goal 2): survive sign-out, include guests, show with home. Small, no dependencies.
2. **Equal weight and the first action** (Goals 4, 5 and 3): login buttons, guest greeting, guest home order, login close button, navigation mode back.
3. **Guest mode choice** (Goal 1): mode screen for guests, companion allowed, mic locked. Typed chat per D1.
4. **Answers backbone** (Goal 8): after PR #201 is merged, then hand the API to DEV 2.
5. **Personas** (Goal 7): doc update.
6. **Traction** (Goal 6): per-feature sheet copy now; analytics per D4.

Each step is one PR, with a device check of guest and signed-in.
