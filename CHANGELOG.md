# Changelog

All notable changes to the MSS app (Flutter, `frontend/`). Versions follow
`frontend/pubspec.yaml` (`versionName+versionCode`, see `docs/APP_VERSIONING.md`).
Each release is tagged `app-v<version>+<build>` and published on GitHub Releases.
Format based on [Keep a Changelog](https://keepachangelog.com/).

How to add an entry: put changes under **Unreleased** as you merge; at release time run
`dart run tool/app_version.dart bump <patch|minor|major>` from `frontend/`, move the
Unreleased items under a new heading, commit, and tag the commit.

## [Unreleased]

## [2.6.4+35] - 2026-11-21 (dev test build)

### Fixed
- Google sign-in follows API_DOCUMENTATION again. Every app returns through the one documented link `com.inschemes.app://login-callback/`, and `/v1/auth/google/start` gets only `code_challenge` (no `redirect_uri`). The per-app return links from 2.6.2 are removed, and the server change for them (mssschemes/backend#7) was reverted in mssschemes/backend#9. With several MSS apps on one phone, Android may ask which app should finish the sign-in.

## [2.6.3+34] - 2026-11-21 (dev test build)

### Fixed
- The first-time home tour no longer opens on top of the profile form or the short survey. It waits until you are back on the home screen. The Saarthi-mode tour waits the same way.

## [2.6.2+33] - 2026-11-21

### Fixed
- Continue as guest now asks for your name and profile details first (kept on this phone), then the short survey, as on the website.
- Guests land on a home screen with schemes for their state and can browse, search and save without signing in (Roger-Chris/MSS_App#204 to #206).
- Google sign-in returns to the app that started it. (Replaced in 2.6.4+35: per-app return links removed, one documented link again.)

### Changed
- App updates now come from the public repository repomssapp-tech/mss-stable. One stable release carries an APK per app (`mss-central-…`, `mss-tn-…`, `mss-mh-…`) and each app downloads only its own. Dev pre-releases stay in the private mss-dev repository and are never offered as updates.
- Login screen text, wording review across the app, and sign-out keeps onboarding seen (Roger-Chris/MSS_App#207).
- Ships the Maharashtra MSME questionnaire dataset (Roger-Chris/MSS_App#201).

### Added
- Editions. One codebase now builds three apps, chosen with `MSS_EDITION` (`--dart-define` locally, the `MSS_EDITION` repository variable in CI):
  - `central` (default): **MSS**, `com.inschemes.app`, unchanged from today, so installed apps keep updating.
  - `tn`: **MSS Tamil Nadu**, `com.inschemes.app.tn`. Central and Tamil Nadu schemes only, English and Tamil, opens in Tamil.
  - `mh`: **MSS Maharashtra**, `com.inschemes.app.mh`. Central and Maharashtra schemes only, English, Hindi and Marathi, opens in Marathi.
  A state edition is fixed to its state from the first frame, with no GPS check, and checks its own releases repository for updates. A dev build of any edition adds `.dev` to the app ID and " Dev" to the name.
- Marathi is back. The app is offered in English, Tamil, Hindi and Marathi again, including voice, search and state names. The app-lock screen and the copyright notice are translated into Marathi. Six leftover English phrases in the Marathi catalogue dictionary are now translated.

## [2.6.1+32] - 2026-11-20 (dev test build only, not released to users)

Test app "MSS Dev" again (`channel=dev`, location lock on). Adds guest mode (PR #202) and the profile questionnaire.

### Added
- Guest mode. "Continue as guest" on the sign-in screen: the guest gives the personal details first (kept only on the phone, with a notice on Profile and Settings that another phone or cleared app data means the guest profile is gone), then a short survey. No recommendations or match scores for guests; a "Complete your profile: sign in with Google" card on Home until they sign in.
- Profile questionnaire (28 questions, English, Hindi, Marathi and Tamil; the same questions as the website) with the state, district, taluka and city lists from the government Local Government Directory (19 Nov 2026), a "Use my current location" button, and "Skip the rest" on the long list for guests. Gender, age and home state come from the personal details and are not asked twice.
- Google sign-in: every question is required. A guest's answers join the account at sign-in (the account's own answers win).
- Answers are sent to the MSS API (`/v1/questionnaire/guest`, `/v1/me/questionnaire`) for the government statistics; guests count too.
- Profile: "My answers".

## [2.6.0+31] - 2026-11-18 (dev test build only, not released to users)

Separate test app "MSS Dev" (`com.inschemes.app.dev`), built with `channel=dev`. It installs next to the real app, never replaces it and never checks for updates; production phones are never offered it. Also has the unreleased Marathi work above.

### Added
- Location lock. At every start the app reads the phone's precise GPS location before showing anything. It blocks the app while location is off or only approximate, while a fake-location (mock) app is in use, while a VPN is on, after a jump faster than anyone can travel, and outside India. It checks again after 15 minutes in the background.
- Schemes follow the GPS state: central schemes plus that state's schemes only. In Maharashtra no Tamil Nadu scheme appears anywhere (lists, search, Discover, Saarthi, links), and the other way round. Discover and Saarthi show only that state; scheme cards show only its emblem and the national one.
- Languages follow the GPS state, with English first: Maharashtra English, Hindi, Marathi; Tamil Nadu English, Tamil; other states English, Hindi. A language the state does not offer switches to English.
- Profile: the GPS address fills in the address, city, district and pincode, which stay editable. The state is set from GPS and cannot be changed.
- Settings shows "Test build" next to the version.

## [2.5.1+30] - 2026-11-10

### Added
- Copyright notice: "© 2026 Swadeshi Shodh Sansthan, Tamil Nadu Chapter & Rajalakshmi Institute of Technology, Chennai. All Rights Reserved." The full notice is in the About dialog and in a new section 11 of the Terms of Use (in English, Tamil and Hindi); the one-line copyright is at the bottom of the sign-in screen and of Settings. The copyright line itself stays in English in every language, as supplied.

## [2.5.0+29] - 2026-11-10

### Added
- App lock by the administrator. When an admin locks the app from the admin panel, every phone shows "The app is locked by the administrator" with the admin's message, and nobody can use the app, sign in, sign out or create an account until it is unlocked. The server refuses everyone but admins while locked, so the lock cannot be got around from the phone; restarting the app or turning the internet off keeps it locked. After the unlock the app opens by itself and users stay signed in.

### Removed
- Marathi. The app is offered in English, Tamil and Hindi; a phone that was set to Marathi switches to English.

## [2.4.5+28] - 2026-11-06

### Changed
- Home "Recommended for you" and Search "For Me" now show the same schemes.
- With a filled profile but no strong match, both show the closest schemes under "No perfect match yet".

### Fixed
- Back buttons and page titles look the same across Settings, Help, Notifications, Privacy, Terms, Scheme details and the profile form.
- On the profile page, the Edit button stays on one line and lines up with the icon and title in every language.
- Marathi screens no longer mix in English words such as Saarthi, Startup India and OBC.

## [2.4.4+27] - 2026-11-05

### Fixed
- Android navigation buttons stay visible while reading the terms or privacy documents.
- Accept stays greyed out until you reach the end of the terms or privacy policy.
- Language badges fit inside their circles with larger text.
- Institution cards show feedback when tapped.

## [2.4.3+26] - 2026-11-05

### Fixed
- The profile photo and Edit profile button stay at the top on narrow screens and with larger text.
- The full camera badge is visible. Tap the photo or the badge to change your profile picture.
- Each MSME support page shows its icon and title in the top bar, with the description below.
- Android Back, Home and Recents buttons have clearer contrast in three-button navigation.

## [2.4.2+25] - 2026-11-05

### Fixed
- Opened notifications stay read after a refresh or app restart. The unread badge updates immediately, and failed syncs retry.
- MSME support pages show their name in the top bar. Saved schemes can be removed from the bookmark on each card.
- The selected bottom navigation tab uses the app's blue palette. Profile headings and scheme benefit cards are easier to read.
- More screen text follows the selected language, and the profile form accepts Hindi and Marathi place names.

## [2.4.1+24] - 2026-11-05

### Fixed
- Saarthi looks the way it was designed again: Ashoka navy text and buttons on white, saffron and green rings round Saarthi's picture, your name in saffron and a saffron glow round the mic. The old sessions list is a plain list with a search box.
- Ask Saarthi on the Home screen opens Saarthi's new home, with the mic and keyboard, instead of the old chat screen.

### Removed
- The old Saarthi chat screen with the Type and Voice switch.

## [2.4.0+23] - 2026-11-04

### Changed
- Every screen has a cleaner, calmer look: one set of colours, text sizes and spacing across the app, larger buttons that are easier to tap, and Tamil and Hindi labels that wrap instead of shrinking on small phones. This covers Home, Scheme details, Search, Saved, Discover and its calculators, Profile, Settings, Help, Legal and the setup screens from launch to the profile steps.
- Saarthi's voice screen has a new design.
- Saarthi shows scheme cards only for the schemes its reply talks about, and none when it says it has no verified details for a scheme.
- Scheme details open with the benefits expanded and show exact amounts, written the Indian way (₹ 10,00,000).

### Fixed
- Scheme details added "Loan" or "Subsidy" tags to schemes whose record has neither.
- Hindi showed "middle" for Central schemes, and two Hindi search shortcuts searched for the wrong words.
- The loan calculator now groups EMI amounts the Indian way.
- Removed a privacy claim the app could not back up.

### Removed
- The old voice assistant overlay and the old eligibility results screen, which the app no longer opened.

## [2.3.2+22] - 2026-11-03

### Fixed
- Hindi, Tamil and Marathi screen text was reviewed line by line against English and about 360 labels were corrected. Examples: Hindi showed "junior" for Undergraduate, "shortcomings" for the export Drawback scheme, "quantity" for Amount, "to start running" for Startup and a literal "push" for Push Notifications; Tamil used "obligation" for customs duty and "private sector" for private data; Marathi gave Undergraduate as "pre-degree" and built the terms-consent sentence wrongly. Many Hindi buttons used infinitives ("to save") instead of instructions ("Save").
- Tamil now writes Saarthi as சாரதி everywhere, and Marathi uses आधार for Aadhaar and one word, तारणमुक्त, for collateral-free.
- A few Hindi document and scheme terms were corrected, for example the community certificate is now the caste certificate (जाति प्रमाण पत्र).

## [2.3.1+21] - 2026-11-03

### Fixed
- In Marathi, the Terms of Use, Privacy Policy, privacy notice and consent screens, the MSME guide panels, the search category tiles and other longer screen texts showed English. They are now in Marathi. Ministry, institution, scheme and Act names stay in English. The translation is AI-written and still needs review by a native speaker.
- On small phones with large text, the Allow button on the permissions screen pushed its row off the screen in Marathi. Its label now wraps.

## [2.3.0+20] - 2026-11-03

### Added
- The app is now available in Marathi, for Maharashtra's 79 schemes. Other schemes stay in English when you use the app in Marathi. The translation is AI-written and still needs review by a native speaker.

### Changed
- Tamil scheme text and document names are corrected across the catalogue, and required documents are marked correctly in Tamil.
- Documents show their translated names and the Required label again when the catalogue has been updated over the air.
- Schemes with unconfirmed application steps now link to the official page below those steps.

### Fixed
- Questions about your state showed the Tamil state name in Hindi. They now use your language.
- In voice conversations, scheme cards showed English for Hindi users. They now follow the app language.
- A scheme's internal status notes no longer appear in its status section.

## [2.2.1+19] - 2026-10-25

### Changed
- The bottom bar is now white, with each icon in a soft circle. The active tab is a round frosted purple bubble that stretches like a drop as it moves between tabs.
- Saarthi now says "Powered by Sarvam AI".

### Fixed
- Settings no longer repeats your profile card, so the Profile tab is the one place your profile is shown (in companion mode, which has no Profile tab, Settings still shows it).

## [2.2.0+18] - 2026-10-24

### Added
- A new four-page welcome tour after the splash on first launch (Meet MSS, One Simple Solution, Know What You Qualify For, Just Ask Saarthi), in English, Hindi and Tamil.
- After sign-in, a one-time screen asks for notifications, microphone, installing updates and photos/documents, explaining why each helps. Nothing is required: Not now and Continue always go on.
- Saarthi is redesigned. Type mode (Ask AI on Home) shows replies as they arrive, with scheme cards for the schemes Saarthi names, follow-up suggestions and Retry. Voice mode (AI tab) shows listening, a "Did I hear you right?" check and a conversation view with scheme cards and a documents checklist.
- Chat history: your Saarthi conversations are saved on your phone (the newest 100), searchable and grouped by Today, Yesterday and Earlier. Typed chats can be continued; spoken ones open as transcripts.
- Voice settings: language, auto-play replies, hands-free and confirm-before-sending, from Settings or the conversation screen.
- For your safety, the app does not open while Developer options or USB debugging is on, while a VPN is on (Tailscale and AdGuard are allowed), or on open or sign-in-page public Wi-Fi. It opens again by itself once fixed.

### Changed
- The bottom bar is a violet bar; the active tab rises out of it as a glass tile. Slide a finger along the bar to move between tabs.

### Fixed
- Home, Saved and search scroll more smoothly: scheme cards are translated once instead of on every redraw, and Tamil and Hindi schemes load about 4x faster the first time.
- Home carousels stop turning while you are on another tab.
- Saarthi history is in time order, the AI disclaimer is easier to read, and the Type/Voice switch fits on narrow phones.

## [2.1.0+17] - 2026-10-24

### Added
- The app tells you when a new version is out: an "Update available" notice with the version and what changed, in English, Hindi and Tamil. Update downloads it; Later hides that version until a newer one comes.
- Settings has "Check for updates", showing your version and the latest release.
- Delete Account now has a 30-day grace period: sign in again within 30 days to reactivate your account.

### Fixed
- Logging out keeps you signed out, even if the app is closed straight after.
- A failed Google sign-in now says "Sign-in failed" instead of hanging.
- Switching tabs is smoother: tabs no longer rebuild on every tap, and Discover no longer freezes while it recounts.
- Scheme details and cards read correctly in Hindi, Tamil and English, and Tamil and Hindi titles keep their bold weight.
- Hindi and Tamil links are no longer underlined through the letters.
- The email field wraps, hints and footers are easier to read, and the bottom bar's droplet is a little smaller and lighter.

## [1.4.7+15] - 2026-10-23

### Added
- After Google account selection, the login screen shows a small "Signing you in…" overlay while sign-in finishes, so a second sign-in cannot be started by mistake.
- Notifications (the inbox, the Home update card and the phone notification) and English-only scheme names on Home are translated to your language with Google's on-device translator. The first use downloads a language model (about 30 MB per language); the app is larger because of the translator.

- A four-step first-time tour on the home screen (search, Saarthi, Discover, Profile) with a spotlight on the real widgets, in English, Hindi and Tamil. It is shown once per account; Finish and Skip are both remembered.

### Fixed
- Confirm dialogs (such as Log out) keep their button labels on one line, stacking the buttons when needed; the bottom bar's labels have more room so Tamil "Profile" does not break mid-word.
- The bottom bar's droplet animation now plays when system animations are off (a short slide instead of a jump), and tabs are prepared after start so the first switch does not stutter.
- The nav bar droplet is wider, so the whole label fits in every language.
- The nav bar floats over the page with no backdrop; the Ask AI button sits above it.
- "User Information" stays on one line on the profile, with Edit Profile at the right.

## [1.4.6+14] - 2026-10-23

### Added
- Home Featured shows the schemes you match best and the newest schemes for your state, full width, changing every 4 seconds.
- Tip of the Day has 10 tips and shows the next one each time you open the app.
- Recommended For You cards show the scheme summary and a faint state or national emblem.
- The bottom bar is liquid glass: the active tab's icon and label sit in a glass droplet. Slide a finger along the bar to move between tabs.

### Changed
- The language and notification buttons on Home are solid blue, so they stand out from the background picture. The search bar sits a little lower.
- The "What would you like to do today?" cards have centred icons and evenly aligned labels.
- Notifications the app shows use the MSS logo on a white background, with a blue status-bar icon.

### Fixed
- Saved and Recently viewed cards no longer run to the screen edges.
- The strip behind the bottom bar matches the page colour.

## [1.4.5+13] - 2026-10-23

### Fixed
- The bottom navigation bar is a floating, light frosted-glass pill again, with the active tab in the brand blue. It sits below the page content instead of over it, and its labels fit in English, Hindi and Tamil at large font sizes.
- Google account profile pictures show on the profile again (a generated placeholder avatar still falls back to the name initial, and a loading or failed picture shows the initial too).
- Home "Latest Updates" has a working View All button that opens the full notification list.

### Changed
- Faster cold start: startup tasks run together, and a tab is built the first time you open it.

## [1.4.4+12] - 2026-10-23

### Added
- Admin broadcasts show as a phone notification with vibration, also while the app is open.
- Tapping a notification opens a details screen with the full message, the time it arrived, and delete.
- A light haptic tick on every tap, with a Haptic feedback switch in Settings (on by default).

### Fixed
- Hindi is offered in the language picker again. Catalogs published from the admin panel carry no language list, and the app read that as "Hindi off".

### Changed
- The notifications panel is one list grouped Today / Yesterday / Earlier; long press to select.
- The bottom navigation bar is a floating frosted-glass blue pill.

## [1.4.3+11] - 2026-10-21

### Changed
- Saarthi voice uses Sarvam through the MSS backend instead of LiveKit (#141).
  - Recorded and reviewed voice turns, plus native live conversations on Android.
  - Answers come in the selected language, with captions, correction, repeat and screen-reader controls.
  - Up to 60 seconds of speech per turn, and listening waits until the reply has finished playing.
  - Chat replies appear gradually.
  - Scheme lookup understands acronyms and titles, including PMEGP/PMEPG.
  - Provider keys and signed URLs stay on the server.
- A failed or slow voice connection shows an error with Retry instead of hanging.

### Removed
- LiveKit voice transport and its package.

## [1.4.2+10] - 2026-10-21

### Fixed (Hindi test report)
- PMEGP and other scheme details read in Hindi: beneficiary, amount notes ("Current project-cost ceiling applies"), documents, services, conditions, fees, timelines and FAQs. About 1,250 new Hindi translations, and Hindi detail text stored in the bundled catalogue (#138, #139).
- EMI total label in Hindi says "कुल राशि (मूलधन + ब्याज)" instead of "पूर्णांक" (#138).
- Profile shows Entrepreneur, Business, MSME Owner and Artisan in Hindi (#138, #139).
- The eligibility FAQ points to tabs that exist (Profile, Search, and the assessment under Discover) in English, Hindi and Tamil (#138, #139).
- Scheme tabs scroll to their section, including distant ones (#138).
- Profile's completion badge matches the percentage in Settings (#138).
- Typing a search runs it automatically after a short pause, so a query with no matches shows "no results" (#138).
- The EMI calculator rejects non-numeric input; the password-update fallback message is translated (#138).

### Changed
- Login: one consent sentence with tappable "Read the …" rows; password sign-in was removed (#136).
- Profile saves are queued and always use the latest version from the server, so two saves never conflict; the live notification stream URL is fixed; religion is no longer collected (#135).
- Every close (X) button has a screen-reader label (#137).

## [1.4.1+9] - 2026-10-21

### Fixed
- Signing in again no longer sends the user through onboarding on every launch (#123). When the server has every profile field but has not recorded legal consent yet, the profile counts as complete and onboarding is retried in the background; saved role, qualification, category and income prefill the profile steps instead of showing blank.

## [1.4.0+8] - 2026-10-21

### Fixed
- Udyam classifier and the assessment's business-size question use the 2025 MSME limits (Micro ≤ ₹2.5 Cr investment / ₹10 Cr turnover, Small ≤ ₹25 / ₹100 Cr, Medium ≤ ₹125 / ₹500 Cr) in English, Tamil and Hindi (#124).
- GST calculator uses the GST 2.0 slabs (0 / 5 / 18 / 40 %) and has a within-state (CGST + SGST) / inter-state (IGST) choice (#130).
- A scheme's details page shows its real match score, or "Not applicable to you", instead of a hard-coded "96% Match" (#129).
- A saved scheme the server refuses stays saved on the phone, and a navigation mode chosen on the phone is no longer overwritten by the server copy after a restart (#127).
- Voice search listens in the app's language (Tamil, Hindi, Marathi) instead of always en-IN (#128).
- Saarthi: when cloud voice cannot connect, it switches to the phone's own speech and says so, instead of hanging (#125).
- Settings shows the real app version; "Recently viewed" fills in; the document checklist has a Sole Proprietorship option.
- The password sign-in, password settings and active sessions screens are translated into Tamil and Hindi and follow the design system.
- Share buttons open the Android share sheet instead of only copying (BUG-10).
- Text follows the phone's font-size setting up to 2× instead of stopping at 1.12–1.3× (BUG-11).
- EMI calculator accepts 0% interest and the Udyam classifier accepts ₹0; Udyam results are in Tamil and Hindi (BUG-12, L10N-05).
- A scheme hidden only by the Filter sheet says "Doesn't match your filters" instead of "Not applicable to you", and TalkBack reads the pill (BUG-09, NEW-09).
- Scheme chips keep the same colour and order in every language (L10N-09).
- The Featured "Women Entrepreneurs" card opens the Women Entrepreneurship list (NEW-04).
- The search Filter / For Me / Sort strip wraps instead of cutting off the Tamil Sort chip; Tamil uses one word for "Filter" (L10N-04, L10N-06).
- Hindi wording: होम, विशेष, योजनाएं, खोज साफ़ करें, क्रमबद्ध करें (L10N-03).
- The "who can apply" line is no longer a word-by-word English/Tamil mix (BUG-07).
- The generated "Catalogue status …; verification …" line is no longer shown on scheme pages.
- After midnight the greeting is "Hello," instead of "Good Evening,".
- Login: the Terms of Use and Privacy Policy have full-size buttons with a tick once read (NEW-10).
- The document checklist's copy button is labelled "Copy checklist" for screen readers (A11Y-03).
- The government emblem fits inside its circle ("Government of India" no longer cropped) (UI-05).

### Security
- Access and refresh tokens are stored encrypted (Android Keystore) instead of plain SharedPreferences; sessions from older versions carry over (#131).
- The OAuth callback (with its one-time code) is no longer written to the log (#131).
- Voice agent dependencies: PyJWT 2.15.1, aiohttp 3.14.5, urllib3 2.8.0, yarl 1.25.1 (0 known advisories) (#131).
- CI scans every push and pull request for committed secrets (gitleaks).
- The sign-in PKCE verifier and the account email are stored encrypted too (SEC-02).
- Release builds are obfuscated; the symbol files are kept as a CI artifact (SEC-07).
- CI release builds use the live API host `https://mssapi.msmeschemes.org` by default (the old `api.msmeschemes.org` host is paused).

### Removed
- The retired Supabase backend: the `docs/old_supabase` archive, the `tools/` scripts that queried it, and its SQL migrations. The app uses the MSS REST backend and Firebase.

### Known issues
- Onboarding can repeat after signing in again (#123).
- The Supabase service_role key in git history must still be rotated in the Supabase dashboard (#126).

## [1.3.0+7] - 2026-10-21

### Changed
- Browse pages (Discover category / ministry / state cards, home tiles, the eligible list) are now the Search screen itself, opened on that card's schemes: the same header, search box, Filter / For Me / Sort strip, cards, empty states and "not applicable" pill. There is no second results interface any more.
- Pressing the Home search bar opens a fresh search page (no old results, no leftover filters); results appear only once a query is run.
- A pushed browse page starts with no filters from other screens, and leaves none behind.

### Fixed
- "Business & MSME" showed 83 schemes after the questionnaire while its card said 309: the questionnaire added the card's own category / ministry / state as a second, differently-worded filter. The card is now the base set and only the answers (offer types, beneficiaries) narrow it.
- Six short category titles (Startup, Finance, Artisan, Digital India, Women Entrepreneurs, Student Startups) showed in English in Tamil and Hindi.
- "Clear Filters & Explore Schemes" is available from every empty results page.

### Added
- Catalog-wide tests: every filter (offer type, beneficiary, nationwide, state, and combinations) returns exactly the schemes it describes for all schemes; card counts equal list sizes; every browse title and filter label is translated in Tamil and Hindi.

## [1.2.1+6] - 2026-10-20

### Added
- "Not applicable to you" pill: a scheme typed by exact name or acronym (e.g. PMEGP) now stays in the results, flagged with a distinct outlined pill, when "For Me" or a filter would have hidden it. The "eligible" count excludes these.
- Guard tests: every catalog card chip is translated in Tamil and Hindi; Tamil UI strings never spell MSME in Latin letters; the bottom bar is not inflated by the status-bar padding.

### Changed
- Tamil: MSME is written short, in Tamil letters ("எம்எஸ்எம்இ"), in the UI strings and dictionary; official names (MSMED Act, CGTMSE, MSME-DI/DFO) and the app name are unchanged.
- Tamil and Hindi: all 379 distinct scheme-card chip values (category / scheme type / sector) are translated.
- Sharing results now copies the scheme names in the active language.

### Fixed
- Bottom navigation bar was about 50dp too tall (status-bar padding was added on top of the bar). It is now its own widget, `AppBottomNavBar`.
- State questionnaire inserted the raw English state into Tamil sentences ("Maharashtra மாநிலத்தின்…"); it now uses the Tamil name, and the Tamil word for "resident" is corrected.
- Card chips no longer split a bracketed list at its commas ("services)", "cooperatives)").

## [1.2.0+5] - 2026-10-20 (pre-release)

### Added
- Multilingual search with "Did you mean", Hindi/Tamil stemming, profile canonicalisation
  and voice-agent parity; English scheme text indexed so indirect queries resolve.
- Firebase Cloud Messaging push integration.
- Device audit report: `docs/audit/DEVICE_AUDIT_2026-10-20.md`.

### Changed
- App and voice agent now use the MSS REST backend and the 2026 scheme catalog.
- Default API origin is `https://mssapi.msmeschemes.org` (the Vercel host
  `api.msmeschemes.org` is paused).
- In-app Tamil/Hindi terms aligned with the catalog (MSME, women entrepreneurs, states).
- Home fallback promo carousel shows only the evergreen "For Women Entrepreneurs" card.

### Fixed
- Logout now revokes the session on the server before clearing local tokens (the request
  used to go out without a bearer and the session stayed valid).
- Users were signed out after an expired access token: the refresh lock was per-client, so
  parallel clients reused one refresh token and the server revoked the session. The lock is
  now shared (regression test added).
- "Use my profile" filter treated disability "No" as a disability and collapsed results to
  one scheme.
- Missing accessibility labels: legal-sheet close button, profile notification bell and
  avatar, onboarding step 4 switches.
- Fabricated home promo cards ("PMEGP · 2 days left", "TN Export Promotion Scheme",
  "UDYAM registration process updated") removed.

### Known issues
- Server `LEGAL_DOCUMENT_VERSIONS` is empty, so onboarding is never marked complete on the
  server and re-runs on every cold start (server configuration, not an app bug).
- Full Address is not restored after a restart.
- Default scheme lists are not scoped to the user's state (Filter → Maharashtra coverage
  works).
- Access and refresh tokens are kept in plain SharedPreferences.

Full detail: `docs/audit/DEVICE_AUDIT_2026-10-20.md`.

## [1.1.0+4] - 2026-10-19

### Changed
- Moved the app and voice agent to the MSS REST backend with the 2026 catalog (#114).
- Hindi + Tamil UI sweep, Companion localization and adaptive layouts (#112).

## [1.0.2] - 2026-09-06 (pre-release)

Scheme result engine, single shared filter, redesigned filter sheet, hardened profile
round-trip. See the `v1.0.2` GitHub release for notes.
