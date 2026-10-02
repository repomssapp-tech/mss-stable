# MSS App — Phase 3 Screen-Sweep Specs

**Author:** designer session · **Date:** 2026-10-02 · **For:** programmer · **Branch/base:** `fix/production-readiness` @ `f6f7026` (re-check line numbers before editing; they drift as Phase 1/2 land)

**Prerequisite:** Phase 2 primitives exist (`spec_design_system.md`): `AppText` (`context.text.<step>`), `AppColors`, `AppRadius`, `AppSize`, `AppShadows`, `AppTheme.light` component themes, `AppIconButton`, `AppTappable`, `AppCard`. Everything below is written against those names. If a primitive isn't merged yet, use the raw value shown in the *Before* column's token note and leave a `// TODO(phase2)` — but do not invent a new one.

**Already done in Phase 1 (per manager, 2026-10-02): H1, V1, V2, and the bookmark-key unification (H7/SD3 incl. the schemeCode→id migration), plus the Phase 1b items (AS1, ST1, PR1, CH1, MS1/MS2).** Those entries below are marked **DONE IN PHASE 1 — verify only**. For them: do not re-implement; just confirm after Phase 1 lands that the behaviour matches the "After" text and apply only the visual remainder that is explicitly listed (tokens/type scale/48dp/semantics), which is not Phase 1 work.

**Phase 2 corrections (from `review_phase2_design.md`) — apply before or with the first Phase 3 PR**

- **Real API names.** Tag colours are `AppTagStyle.neutral/level/levelState/benefit/warn` in `utils/app_colors.dart` (records; rename the colour field from `textSecondary` to `text`). There is **no** `utils/app_tag_style.dart` and no `tagStyleFor`: add `AppTagStyle styleForTag(String tag)` next to the card (or in `app_colors.dart`) and use it in group 11. Radii are `AppRadius.xsAll/smAll/mdAll/lgAll/xlAll/pillAll` (const `BorderRadius`); `BorderRadius.circular(AppRadius.pill)` is equally fine.
- **Ripple fix (blocking).** `AppCard(onTap)` and `AppTappable` currently hide the ink splash under coloured children and put `AppCard.margin` inside the `InkWell`. Fix first: `AppCard` = `Padding(margin) → Container(decoration) → Material(transparency) → InkWell → Padding(padding) → child`; `AppTappable` gains two optional params, `decoration: BoxDecoration?` (painted with `Ink(decoration: …)` inside the `InkWell`) and `padding: EdgeInsetsGeometry?` (applied inside the ink). **Everywhere below that says "`AppTappable` around a `Container(decoration: …)`" means: pass that decoration (and padding) via `AppTappable(decoration: …, padding: …, child: <contents>)` instead of wrapping a `Container`.** (QuickPills, filter chips, saved tabs, tag pills, For Me chip.)
- **Drag handle.** `AppTheme.light` must set `bottomSheetTheme.showDragHandle: false` for now (it currently adds a second handle to ~13 sheets that draw their own). In this phase each sheet either keeps its manual handle (leave it) or is migrated by deleting the manual handle **and** passing `showDragHandle: true` to that `showModalBottomSheet` call. Groups 12 and 16 do the migration for their sheets.
- **Nav bar theme.** Add `surfaceTintColor: Colors.transparent` and `elevation: 0` to `navigationBarTheme` (spec §5.2) before group 1 adopts `NavigationBar`.
- **Ambient button sizing** is intentionally 48dp (spec §5); QA re-checks the Search filter strip, Saved cards, Home profile-completion card, calculators and dialogs.
- **Font weights.** Add `fontVariations: [FontVariation('wght', w.value.toDouble())]` to `AppTextStyles._b` (Inter/Noto) unless the device check shows `FontWeight` already maps to the variable axis.
- **Guards first.** Group 0 also lands the four missing guard rules (`button_style`, `fixed_height_text`, `fit_one_line`, `semantics`) and the corrected `tap_target` (whole-file `balancedCalls`, baseline will rise to ≈ 40).

**Rules for every item**

1. **No layout change.** Same widgets in the same order and positions. Only style, hit area, semantics, copy, and the state/behaviour called out.
2. Every new user-visible string is an ARB key in **both** `app_en.arb` and `app_ta.arb` (list in §Z). Reuse an existing key if one with the same meaning exists (grep first).
3. Tamil: same size as English per role, no shrinking, wrap instead of ellipsis (`spec_design_system.md` §1.3).
4. Any raw `GestureDetector(onTap:)` you touch becomes `AppTappable`/`AppIconButton`. Any literal `fontSize`, `Color(0x…)`, `BorderRadius.circular(n)` in a touched widget becomes a token.
5. When a file is in two groups below, the **earlier-numbered group owns it**; the later group's items are applied by the same person in the same PR. The groups are otherwise disjoint (see the collision map at the end).
6. Acceptance for each file: `flutter analyze` clean, existing tests green, guard baselines don't grow, and the screen renders without overflow at en/ta × text scale 1.0/1.3/1.6 × width 320/390.

Severity tags are from `audit_design.md`. Items P2 that sit in the same file are included so the file is touched once.

---

## 0. New shared widgets (do first, owned by one person; unblocks groups 5, 6, 7)

### 0.1 `lib/widgets/common/quick_pills.dart` (new) — replaces duplicated pills (H5, S2)

```dart
/// Horizontal quick-search pills shared by Home and Search.
class QuickPills extends StatelessWidget {
  const QuickPills({super.key, required this.onSelected});
  final ValueChanged<String> onSelected; // receives the QUERY, not the label

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pills = <({String label, String query})>[
      (label: l.quickPillPmegp,   query: l.quickPillPmegpQuery),
      (label: l.quickPillStartup, query: l.quickPillStartupQuery),
      (label: l.quickPillLoans,   query: l.quickPillLoansQuery),
      (label: l.quickPillWomen,   query: l.quickPillWomenQuery),
      (label: l.quickPillAscend,  query: l.quickPillAscendQuery),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(children: [
          for (final p in pills)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppTappable(
                onTap: () => onSelected(p.query),
                semanticLabel: p.label,
                borderRadius: AppRadius.pillAll,
                // Visual pill goes through `decoration` so the ripple is visible (Phase 2 fix D3).
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_rounded, size: AppSize.iconSm, color: AppColors.iconMuted),
                  const SizedBox(width: AppSpacing.tight),
                  Text(p.label, style: context.text.label.copyWith(color: AppColors.textBody)),
                ]),
              )),
        ]),
      ),
    );
  }
}
```

Pills are now 40–48dp tall: `AppTappable` applies its 48dp minimum outside the `Ink`, so the drawn pill reaches 48dp (accepted in the batch-1 review, B8; use `vertical: AppSpacing.xs` padding to keep the pill close to 40 plus ink). No fixed `height: 38`. The same applies to every chip/tab built on `AppTappable(decoration:)`.
ARB: add the five `quickPill*Query` keys (English query words: `PMEGP`, `Startup`, `Loans`, `Women`, `ASCEND`; Tamil: the Tamil search terms the catalogue indexes, e.g. `PMEGP`, `தொடக்க நிறுவனம்`, `கடன்`, `பெண்கள்`, `ASCEND`). Delete the `.replaceAll("Search ", "")`/`.replaceAll("தேடுக","")` code at both call sites.

### 0.2 `lib/utils/money_format.dart` (new) — D4

```dart
import 'package:intl/intl.dart';
String formatInr(num v, {int decimals = 2}) =>
    NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: decimals).format(v);
// 1234567.891 -> "₹ 12,34,567.89"
```
(`intl` is already a dependency via `flutter_localizations`; confirm in `pubspec.yaml`.)

---

## 1. `lib/main.dart` — G2 text scale, theme move, N1 bottom nav

**Owner of: G2, N1, theme wiring.**

### 1a. Text-scale policy (G2/G3)

Before (`main.dart:173-192`):
```dart
builder: (context, child) {
  final mediaQueryData = MediaQuery.of(context);
  final isTamil = selectedLanguage == 'ta';
  final deviceScale = mediaQueryData.textScaler.scale(1.0);
  final boundedScale = deviceScale.clamp(isTamil ? 1.0 : 1.20, isTamil ? 1.12 : 1.30);
  return MediaQuery(data: mediaQueryData.copyWith(textScaler: TextScaler.linear(boundedScale)), child: child!);
},
```
After:
```dart
builder: (context, child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.6)),
    child: child!);
},
theme: AppTheme.light,            // replaces the inline ThemeData(...) at :193-272
```
- Delete the inline `textTheme` (`:203-261`) and `cardTheme` (they move into `AppTheme.light`).
- `selectedLanguage` is still read for `locale:`; remove the `isTamil` local.
- **Must ship in the same PR as the size sweep for the files in groups 2–15** (English text loses its 1.2× floor).

### 1b. Bottom navigation (N1)

Replace `_buildNavItem` + the `Container(... Row(...))` bottom bar (`:313-367`, `:451-517`) with Material 3 `NavigationBar`:

```dart
bottomNavigationBar: navigationMode == 'companion'
    ? null
    : NavigationBar(
        selectedIndex: currentTabIndex,
        onDestinationSelected: (i) {
          if (currentTabIndex == i && i == 1) searchTabKey.currentState?.resetToIdle();
          provider.updateTabIndex(i);
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined),        selectedIcon: const Icon(Icons.home_rounded),        label: l10n.navHome),
          NavigationDestination(icon: const Icon(Icons.search_rounded),       selectedIcon: const Icon(Icons.search_rounded),       label: l10n.navSearch),
          NavigationDestination(icon: const Icon(Icons.explore_outlined),     selectedIcon: const Icon(Icons.explore_rounded),     label: l10n.navDiscover),
          NavigationDestination(icon: const Icon(Icons.bookmark_border_rounded), selectedIcon: const Icon(Icons.bookmark_rounded), label: l10n.navSaved),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded),   label: l10n.navProfile),
        ],
      ),
```
`navigationBarTheme` in `AppTheme.light` (Phase 2 shipped it **without** `surfaceTintColor` and `elevation`; add them): `backgroundColor: AppColors.surface`, `surfaceTintColor: Colors.transparent`, `indicatorColor: AppColors.primarySoft`, `elevation: 0`, `height: 64`, `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`, `iconTheme`: selected `primary`/unselected `iconMuted` size 24, `labelTextStyle`: `context`-free `AppTextStyles.en.label` coloured `primary` (selected, w700) / `textSecondary`, **12sp, `maxLines` default**. Add a 1px `AppColors.border` top border by wrapping in `DecoratedBox(border: Border(top: BorderSide(color: AppColors.border)))`.
- The Search tab's active/inactive icon is the same glyph (the indicator pill shows state); fixes G7. **Batch-1 review (B5):** `indicatorColor` must be `AppColors.primaryTint` (DBEAFE) not `primarySoft` (EFF6FF is ~1.1:1 on the white bar); selected `labelTextStyle` is `w700` (unselected `w600`); unselected icon/label colour `textSecondary`. Material caps `NavigationBar` label scale at 1.3×, which is acceptable. Extract the bar to an `AppBottomNav` widget so it can be tested with the real ARB labels (en + ta, scale 1.0/1.6). If `navSaved` ("சேமித்தவை") ellipsises at 320dp on the device, change it to "சேமிப்பு".
- If a Tamil label wraps/clips at 12sp on 320dp, shorten the ARB string (`navDiscover`/`navProfile` first), never the font.
- `Semantics` (selected, "tab n of 5") come with `NavigationBar`.

Acceptance: tapping the active Search tab still resets search; companion mode still has no bar.

---

## 2. `lib/screens/login_screen.dart` — F1, F2, F3 (toast), F4, F5

**Owner: Login.** Do not touch `legal_consent_section.dart` (group 3).

### F1 — gate checklist and disabled-button hint

Before (`:226-318`): consent row → 52dp OutlinedButton that is greyed (`opacity 0.45`) until `canConsent && _hasAgreedToConsent`.
After:
1. Directly under `LegalConsentSection(...)` and above the button insert (new private widget `_SignInChecklist`):
```dart
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  _CheckRow(done: _hasViewedTerms,   label: context.l10n.loginChecklistTerms),
  _CheckRow(done: _hasViewedPrivacy, label: context.l10n.loginChecklistPrivacy),
  _CheckRow(done: _hasAgreedToConsent, label: context.l10n.loginChecklistAgree),
])
```
`_CheckRow` = `Row[Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 18, color: done ? AppColors.success : AppColors.iconMuted), SizedBox(width: sm), Expanded(Text(label, style: context.text.bodySmall.copyWith(color: done ? AppColors.textBody : AppColors.textMuted)))]` wrapped in `Semantics(checked: done, label: label)`. Rows are 12sp; spacing `AppSpacing.xs`.
2. The checklist hides itself (`SizedBox.shrink()`) once all three are done.
3. Sign-in button becomes the themed `OutlinedButton` (no custom border/bg colours): `OutlinedButton(onPressed: isLoginEnabled ? _signIn : null, child: Row[GoogleIcon(size: 18), SizedBox(sm), Flexible(Text(l10n.continueWithGoogle, textAlign: center, maxLines: 2))])`, `style:` only `minimumSize: Size.fromHeight(52)` (`// style-ok: CTA height`). Remove the `Opacity(0.45)` wrapper; disabled look comes from the theme (`disabledForegroundColor`).
4. `onDisabledConsentTap` toast stays (now with the localised string, see F3).

### F2 — loading state

Inside the button child, when `_isLoading`: replace the Row with
```dart
Row(mainAxisAlignment: MainAxisAlignment.center, children: [
  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
  const SizedBox(width: AppSpacing.sm),
  Flexible(child: Text(context.l10n.loginOpeningGoogle, maxLines: 2, textAlign: TextAlign.center)),
])
```
and `isLoginEnabled` must **not** include `!_isLoading` for visual purposes: keep `onPressed: _isLoading ? () {} : …` (swallow taps) so the button doesn't grey out while loading. Foreground `AppColors.primary`.

### F3 (toast) — DONE IN PHASE 1, verify only

Phase 1 added `loginReviewTermsNotice` (en/ta) and uses it in `_showNoticeBeforeContinuing`. Use that key (not `loginReviewLegalFirst` from §Z). Verify the Tamil toast (92 chars) doesn't clip at 320dp.

### F4 — legibility

| Line | Before | After |
|---|---|---|
| `:134-141` title | Poppins 17 | `context.text.titleSmall.copyWith(color: AppColors.textPrimary)` (16) — or `titleMedium` 18; pick `titleMedium` |
| `:145-153` subtitle | Inter 9.5, `64748B` | `context.text.bodySmall.copyWith(color: AppColors.textMuted)` (12) |
| `:204-210` card title | Poppins 15 | `context.text.titleSmall` (16) `textPrimary` |
| `:214-222` | Inter 11 | `bodySmall` `textMuted` |
| `:319-326` | Inter 10 | `bodySmall` `textMuted` |
| background text over image | none | If any text sits directly on the photo, put it on a `DecoratedBox(color: AppColors.surface.withValues(alpha: .85), borderRadius: AppRadius.mdAll)` or move it into the card |

### F5

`:99-102` and `:126-130` `Image.asset(...)` get the same `errorBuilder` as `beta_gate_screen.dart:171,232` (logo → `Icon(Icons.verified_user_rounded, size: 80, color: AppColors.primary)`; background → `Container(decoration: BoxDecoration(gradient: AppColors.scaffoldGradient))`).

Tokens: `:158-173` card → `AppCard`-like decoration (`surface`, `border`, `AppRadius.lg` — the old 20 maps to `lg` for cards, `AppShadows.card`).

---

## 3. `lib/screens/beta_gate_screen.dart` and `lib/widgets/legal/legal_consent_section.dart` — F4 (gate), G8

### beta_gate_screen.dart
- `_showErrorSnackBar` (`:96-136`): delete the custom `SnackBar`; call `AppToast.showError(context, message)`. (Removes the second feedback style.)
- Footer text (`:196-205`): `Text(l10n.betaGateAuthorizedTestersOnly, style: context.text.bodySmall.copyWith(color: AppColors.textOnPrimary))` **on the dark-blue wave** (white text, ≥ 4.5:1 on that blue; if the background image varies, wrap in a `DecoratedBox(color: AppColors.textPrimary.withValues(alpha: .35), borderRadius: pill)` with `horizontal: md, vertical: xs` padding). Remove `letterSpacing: 0.4`.
- Card subtitle (`:309-316`) `bodySmall` `textMuted`; title `titleMedium`; hint text in the field from the theme (`textMuted`).
- Replace raw `Color(0xFFE2E8F0)`/radius 20 on the card with `AppColors.border` / `AppRadius.lg`.
- Password field: add `Semantics(textField: true, label: l10n.betaGatePasswordLabel)` (or `InputDecoration.labelText`); the eye icon → `AppIconButton(semanticLabel: isPasswordVisible ? l10n.hidePassword : l10n.showPassword)` (48dp).

### legal_consent_section.dart
- `:61` text 11.5 → `bodySmall`; the whole row stays one opaque tap target (already is) with `Semantics(checked: value, label: <row text>)`; min height 48.

---

## 4. `lib/widgets/common/standard_page_header.dart`, `custom_input_field.dart`, `app_toast.dart`, `custom_confirm_dialog.dart` — G6, A3, shared

**Owner: shared widgets.** Other groups consume these; land this PR first within Phase 3.

### standard_page_header.dart (G6)
- Title: `Poppins 17` → `context.text.titleMedium` (18), `maxLines: 2` when `subtitle` is empty else 1; subtitle `bodySmall` `textMuted` `maxLines: 1`.
- Height: `PreferredSizeWidget.preferredSize` can't see `BuildContext`, so make `StandardPageHeader` a thin wrapper: `Widget build(...) => AppBar(toolbarHeight: _height(context), titleSpacing: 0, leading: <back AppIconButton>, title: <title/subtitle Column>, actions: actions, backgroundColor: AppColors.surface, elevation: 0, scrolledUnderElevation: 0, bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border)))` and `preferredSize` returns `Size.fromHeight(72)` (an upper bound for the scaffold). `_height(context) = max(56, 24 * MediaQuery.textScalerOf(context).scale(1.0)) + (hasSubtitle ? 18 * scale : 0)` clamped to ≤ 96, so the bar grows with text scale. Titles `maxLines: 2` when there is no subtitle.
- Back button → `AppIconButton(icon: Icons.arrow_back_rounded, semanticLabel: l10n.back, onPressed: onBackPressed ?? maybePop)`.
- Colours: `AppColors.surface`, divider `AppColors.border`.

### custom_input_field.dart (A3)
Before: label `Text` above field, no association; `GestureDetector`+`AbsorbPointer` for pickers; error 11sp.
After:
```dart
Semantics(
  container: true,
  label: label,
  textField: onTap == null,
  button: onTap != null,
  value: controller.text,
  child: ExcludeSemantics(excluding: false, child: Column(…same visual…)),
)
```
- Keep the visible label `Text` (style `context.text.label.copyWith(color: AppColors.textPrimary)`, 12sp w600 → or `body` w600 14: choose `body` + `FontWeight.w600`).
- Field text `bodyLarge` (16), hint `bodyLarge.copyWith(color: AppColors.textMuted)`, error row `bodySmall` `danger`, icon 16 → `AppSize.iconSm`.
- Picker (`onTap != null`): replace `GestureDetector+AbsorbPointer` with `InkWell(onTap)` wrapping `IgnorePointer(child: TextFormField(readOnly: true, …))`; semantics as above.
- Error text gets `Semantics(liveRegion: true)`.
- All borders from tokens: `AppColors.border` / `primary` (2dp focus) / `danger`; radius `AppRadius.md`. Delete the per-field `OutlineInputBorder` copies — inherit from `inputDecorationTheme` (override only the error variants if `hasError`).

### app_toast.dart / custom_confirm_dialog.dart
- Toast/Dialog text sizes: `body`/`bodySmall` (13/12.5/13.5 → 14/12), colours from tokens; dialog buttons themed (`TextButton` cancel, `ElevatedButton` confirm, danger variant for destructive), min 48dp, `maxLines: 2` labels. Add `Semantics(liveRegion: true)` to toast.
- `AppToast.show*` gains optional `{String? actionLabel, VoidCallback? onAction}` (needed by V3 undo): render a `TextButton` with `actionLabel` at the end; duration 5s when an action is present.

---

## 5. `lib/screens/regular_mode/home/home_header_section.dart` — H2, H3, H5

**Owner: Home header.** Depends on 0.1 and `AppIconButton`.

### H2 — bell (`:92-137`)
Before: 40×40 `GestureDetector` + `Container(circle, border)` + red 8dp dot at `top:10,right:10`.
After:
```dart
AppIconButton(
  icon: Icons.notifications_none_rounded,
  semanticLabel: context.l10n.notificationsTooltip,
  badgeSemantics: unread > 0 ? context.l10n.notificationsUnreadCount(unread) : null,
  badgeCount: unread > 0 ? unread : null,
  size: AppSize.iconLg,
  color: AppColors.textPrimary,
  backgroundColor: AppColors.surface,        // white circle with border + shadow stays
  backgroundSize: 40,
  onPressed: onNotificationTap,
)
```
`unread = provider.notifications.where((n) => n['read'] == false).length`. The circle keeps its `AppColors.border` ring and `AppShadows.card`; the hit area is 48. Badge: danger fill, white 12sp text, `9+` above 9.

### H3 — search bar and Filter pill (`:142-226`)
Before: outer white pill container with two separate `GestureDetector`s (icon, text) and a Filter pill (≈ 30dp tall).
After: keep the same visual row, but
1. Outer `Semantics(button: true, label: l10n.searchPlaceholder, onTap: onSearchBarTap)` and wrap the left `Icon` + placeholder in one `AppTappable(onTap: onSearchBarTap, minSize: Size(48, 48))` (keep the `Expanded`).
2. Placeholder text `bodyLarge.copyWith(color: AppColors.textMuted)` → use `body` (14): placeholder was 13.5.
3. Filter pill: `AppTappable(onTap: …, semanticLabel: l10n.filter, borderRadius: pill)` around the existing bordered `Container`; pill text `label` (12), icon 16, border `AppColors.borderStrong`. Container vertical padding stays `AppSpacing.tight`; the AppTappable supplies the 48dp height.
4. Container: radius `pill`, border `AppColors.border`, shadow `AppShadows.card`; vertical padding `AppSpacing.xs` (the 48dp children make it taller than before by design: reduce outer vertical padding from `sm` to `xs` to keep total height ≈ unchanged).

### H5 — pills (`:228-289`)
Delete `_buildQuickPills`; use
```dart
QuickPills(onSelected: (q) {
  if (onVoiceQuery != null) { onVoiceQuery!(q); } else { provider.updateSearchQuery(q); provider.updateTabIndex(1); }
})
```
Greeting (`:52-62`): `AppConstants.getTimeGreeting` text → `body.w500 textMuted`; the 👋 emoji gets `ExcludeSemantics`. Name `headline` (24; guests: `titleMedium` 18 as today).

---

## 6. `lib/screens/regular_mode/home/home_recommended_section.dart` — H1, H4, H6, H7

**Owner: Home recommended.** (H1 was approved earlier; if Phase 1b already shipped it, skip H1.)

### H1 (P0) — DONE IN PHASE 1, verify only
Verify: no `95 - (i*3)`, no placeholder items; badge only when the real score > 0; empty-profile CTA card shown instead. **Visual remainder (Phase 3):** the `_RecommendedEmptyCard` and badge use the tokens/type steps shown below (`AppCard`, `cardTitle`, `bodySmall`, `successSoft`/`success` badge, `label` 12).
**Review follow-up R1 (from `review_phase1_design.md`) — apply here:** the empty state is currently shown (a) for complete profiles with no positive scores and (b) briefly on every cold start before the catalog loads. Render by state: *catalog loading* → 3-card skeleton (same height as a card); *profile complete, no matches* → neutral line `homeRecommendationsNoMatches` ("No matches yet — try Search or Discover", ta: "இன்னும் பொருத்தங்கள் இல்லை — தேடல் அல்லது கண்டறிதலைப் பயன்படுத்துங்கள்") + `OutlinedButton(l10n.browseSchemes → provider.updateTabIndex(1))`; *profile incomplete* → the current "Complete profile" CTA card, with the icon and title from the spec below (R2).
Original before: `match = 95 - (i*3)` (`:63`) and hardcoded placeholder items (`:79-131`).
After:
1. Remove the `match` computation. Use the real result: `appProvider.recommendedSchemes` entries are `MapEntry<Scheme, RecommendationResult>`; carry `entry.value.percentage` into the item map and show the badge **only if `entry.value.score > 0`**; otherwise omit the badge widget (not an empty pill). Badge text uses the existing `matchPercentageFormat(percentage)`.
2. Delete the placeholder `items.addAll([...])` block. When there is nothing to show, render `_RecommendedEmptyCard` (same outer height as a card, full width) :
```dart
AppCard(child: Column(crossAxisAlignment: start, children: [
  Icon(Icons.person_search_outlined, size: 28, color: AppColors.primary),
  SizedBox(height: sm),
  Text(l10n.homeRecommendedEmptyTitle, style: context.text.cardTitle.copyWith(color: AppColors.textPrimary)),
  SizedBox(height: xs),
  Text(l10n.homeRecommendedEmptyBody, style: context.text.bodySmall.copyWith(color: AppColors.textSecondary)),
  Spacer(),
  Align(alignment: centerStart, child: ElevatedButton(onPressed: () => Navigator.push(…BasicProfileScreen()), child: Text(l10n.completeProfileCta))),
]))
```
3. Never pre-bookmark; no fake `logoText/logoColor` items.

### H4 — fixed height
Before: `SizedBox(height: 225, child: ListView.builder(scrollDirection: horizontal …))` with `Spacer()` inside the card column.
After: replace the fixed box with a content-sized strip:
```dart
final scale = MediaQuery.textScalerOf(context).scale(1.0); // 1.0–1.6
final cardHeight = (205 * scale.clamp(1.0, 1.4)) + (isTa ? 16 : 0);   // design height 205 = current 225 minus 2×(xs margin) …
SizedBox(height: cardHeight, child: ListView.builder(…))
```
Preferred (no magic numbers): wrap the list in `IntrinsicHeight`-free approach — use `ConstrainedBox(constraints: BoxConstraints(minHeight: 205))` around a `SingleChildScrollView(scrollDirection: horizontal, child: IntrinsicHeight(child: Row(crossAxisAlignment: stretch, children: cards)))`. Each card keeps its `width` formula but clamped: `final cardWidth = min((screenWidth - 2*lg - md)/1.08, 360.0)` (also fixes R1 stretching on tablets). Inside each card replace `Spacer()` + `Column` with `Column(mainAxisSize: min)` + a `SizedBox(height: sm)` before the chips, so the card grows with text.
Text: title `cardTitle` (14, Poppins) `maxLines: 3`, full-name `bodySmall` `textMuted` `maxLines: 3`, chips `label` (12).

### H6, H7 (H7 key unification: DONE IN PHASE 1, verify only)
Verify: every bookmark toggle/read in this file uses `scheme.id` only. H6 (icon button) remains Phase 3.
- Bookmark icon: `AppIconButton(icon: Icons.bookmark_border_rounded, selectedIcon: Icons.bookmark_rounded, selected: isBookmarked, semanticLabel: isBookmarked ? l10n.removeSavedTooltip : l10n.saveSchemeTooltip, onPressed: () => appProvider.toggleBookmark(<scheme.id>), size: AppSize.icon)`. **Canonical key = `scheme.id`** (not `schemeCode`); `isBookmarked = appProvider.bookmarkedIds.contains(scheme.id)` (drop the `|| contains(schemeCode)`).
- Whole card: `AppCard(onTap: …, semanticLabel: title)` replaces `GestureDetector`+`Container`; radius `lg`, border `AppColors.border`.
- Badge: `successSoft` bg, `success` text, `label` 12.

---

## 7. `lib/screens/regular_mode/home/{home_msme_support_section,home_promo_carousel_section,home_journey_section,home_updates_section,home_profile_completion_card}.dart` — H4 (rest), F3

**Owner: Home sections (one person).**

### home_journey_section.dart
- Tile `Container(width: 88, height: 112, …)` (`:137-180`) → `ConstrainedBox(constraints: BoxConstraints(minWidth: 88, maxWidth: 104, minHeight: 112))` inside `AppTappable(onTap: …)`; text `label` (12, `w700`) `maxLines: 3`, `textAlign: center`, `textBaseline` unchanged; icon 24 `primary`.
- The row of tiles: wrap in `IntrinsicHeight` so tiles equal height.
- F3: `MSMEModuleDetailsScreen(title: 'Register UDYAM', description: …)` and `'Export Support'` (`:92-117`) → `l10n.msmeUdyamTitle/Desc`, `l10n.msmeExportTitle/Desc` (new ARB; Phase 1b MS1 may already add them — reuse).
- Tile card → `AppCard`.

### home_msme_support_section.dart / home_promo_carousel_section.dart
- `SizedBox(height: 178)` (`:26`) and `SizedBox(height: 154)` (`:369`) → `ConstrainedBox(minHeight: <same number>)` + `IntrinsicHeight` over a horizontal `Row` inside `SingleChildScrollView`; card width capped at 360 (R1).
- Title/subtitle: `cardTitle`/`bodySmall`, `maxLines: 3/2`; no `FittedBox`.
- Any 46/56dp image boxes (`home_promo_carousel_section.dart:157-164`, `home_msme_support_section.dart:162`) stay fixed (decorative, no text).

### home_updates_section.dart
- Delete `_scaledFontSize`/`_scaledLineHeight` (`:191-198`); use the type scale.
- Card text sizes 10/10.5 → `bodySmall`/`label`.

### home_profile_completion_card.dart
- `height: 38` (`:93`) button → themed `ElevatedButton` (min 48).
- Progress ring/bar: `Semantics(label: l10n.profileCompletionFormat(pct), value: '$pct%')`.

---

## 8. `lib/screens/regular_mode/search/search_input_section.dart` — S1, S2 (pills moved), typography

**Owner: Search input.**

### S1 — field and icons (`:60-141`)
Before: fixed `Container(height: 48, radius 30)`, `TextField` with `IconButton`s using `padding: EdgeInsets.zero, constraints: BoxConstraints()`.
After:
```dart
Container(
  constraints: const BoxConstraints(minHeight: AppSize.controlHeight),
  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.border), boxShadow: AppShadows.card),
  child: TextField(
    …,
    style: context.text.bodyLarge.copyWith(color: AppColors.textPrimary),       // was scaledFontSize(13)
    decoration: InputDecoration(
      hintText: context.l10n.searchPlaceholder,
      hintStyle: context.text.bodyLarge.copyWith(color: AppColors.textMuted),   // was 12.5 / 94A3B8
      prefixIcon: AppIconButton(icon: Icons.search_rounded, semanticLabel: context.l10n.search, color: AppColors.primary, size: AppSize.icon, onPressed: …),
      suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
        if (hasText) AppIconButton(icon: Icons.close_rounded, semanticLabel: context.l10n.clearSearchTooltip, color: AppColors.iconMuted, size: AppSize.icon, onPressed: onClear),
        AppIconButton(icon: isDictating ? Icons.mic_rounded : Icons.mic_none_rounded,
          semanticLabel: isDictating ? context.l10n.stopVoiceSearchTooltip : context.l10n.voiceSearchTooltip,
          color: isDictating ? AppColors.danger : AppColors.primary, size: AppSize.icon, onPressed: onToggleDictation),
      ]),
      border: InputBorder.none, isDense: false,
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
  ),
)
```
Remove the `scaledFontSize` constructor param from `SearchInputField` and `SearchTryBanner` (and in `search_screen.dart:68-71, 552, 570, 618, 650` — the `* 0.92` Tamil shrink is deleted; coordinate with the owner of `search_screen.dart`, group 9).
Add `textInputAction: search` (already), `enableSuggestions: false`.

### S2 — pills
Delete `SearchQuickPills` (`:144-211`) and use `QuickPills(onSelected: onPillSelected)` at the call site.

### Other
- `SearchHeaderBar` (`:7-34`): title `headline`, subtitle `bodySmall` `textMuted` (12 — same).
- `SearchTryBanner` (`:214-256`): `Icon(…size: 12)` → `AppSize.iconSm`; text `bodySmall` `textMuted`; remove the `FittedBox` (wrap to 2 lines); wrap in `AppTappable(minSize: Size(48,48), alignment: centerLeft)`.

---

## 9. `lib/screens/regular_mode/search/search_filter_strip.dart` — S5, sort rule

**Owner: Filter strip.**

- Chips: replace the two `OutlinedButton.icon`s with the themed `OutlinedButton.icon` (no `styleFrom` shape/padding): Filter = outlined `primary`; For Me = `FilterChip`-like: when `isForMeActive` use `ElevatedButton.icon` (solid `primary`, white text) else `OutlinedButton.icon`; both `minimumSize: Size(0, 48)`, label `label` (12 w600), icon 16. `Semantics(selected: isForMeActive)` on For Me. Add a check icon on For Me when active (`Icons.check_rounded` replaces `auto_awesome`).
- `SearchDropdownChip` (`:7-114`): popup text `body`/`label`; selected row check icon `AppSize.iconSm`; chip container padding `md`/`sm` + min height 48 via `ConstrainedBox`; border `AppColors.border`/`primary`.
- S5 edge cue: wrap the `SingleChildScrollView` in
```dart
ShaderMask(
  shaderCallback: (r) => const LinearGradient(colors: [Colors.white, Colors.white, Colors.transparent],
      stops: [0, .92, 1]).createShader(r),
  blendMode: BlendMode.dstIn,
  child: SingleChildScrollView(…),
)
```
(fades the right edge so clipped chips are visibly scrollable).
- First-use tooltip on For Me (`Tooltip(message: l10n.forMeTooltip, triggerMode: TooltipTriggerMode.longPress)` always; plus one-time `showTooltip` via `GlobalKey<TooltipState>` persisted in `SharedPreferences` key `forMeTipShown`).
- **Sort rule** (approved): the option `'Best match for me'` is `PopupMenuItem(enabled: profileEmpty == false, …)`; when disabled show the label plus a second line `l10n.sortBestMatchNeedsProfile` (`bodySmall textMuted`) and a `Icons.lock_outline_rounded` (16). `profileEmpty` = `provider.profileCompletionPercentage == 0` (pass a new `bool canSortByProfile` into `SearchFilterStrip` from `search_screen.dart`). Default `sortBy` remains `'Relevance'`.

---

## 10. `lib/screens/regular_mode/search/search_results_view.dart` (+ `search_results_screen.dart`) — S3, S4, S7

**Owner: Search results.**

### S3 — save action on result cards
`SchemeCard(... showActions: false ...)` (`:175`) → `showActions: true` and the card shows **only the bookmark** (see group 11: `SchemeCard` gets `showShare` flag defaulting to false). Wire `onBookmarkToggle: () => provider.toggleBookmark(scheme.id)` (already). Same in `search_results_screen.dart:522-531` (`showMatchPercentage: false` stays false there).

### S4 — empty state (`:53-116`)
Before: icon + 2 lines.
After:
```dart
Center(child: Column(mainAxisSize: min, children: [
  Icon(icon, size: 48, color: AppColors.iconMuted),                       // was Colors.grey[400]
  SizedBox(height: md),
  Text(title, style: context.text.titleSmall.copyWith(color: AppColors.textBody), textAlign: center),
  SizedBox(height: tight),
  Text(subtitle, style: context.text.body.copyWith(color: AppColors.textSecondary), textAlign: center),
  SizedBox(height: lg),
  if (hasActiveFacets) ElevatedButton(onPressed: onClearFilters, child: Text(l10n.clearFilters))
  else if (queryText.isNotEmpty) OutlinedButton(onPressed: onClearSearch, child: Text(l10n.clearSearch)),
  SizedBox(height: lg),
  QuickPills(onSelected: onPillSelected),
]))
```
New params on `SearchResultsList`: `bool hasActiveFacets, VoidCallback onClearFilters, VoidCallback onClearSearch, ValueChanged<String> onPillSelected` supplied from `search_screen.dart`/`search_results_screen.dart` (`resetToIdle` for clear search; the existing facet-reset method for clear filters). `For Me` empty variants keep their copy but get a CTA: `completeProfile` → button "Complete profile" (`BasicProfileScreen`); `noMatches` → "Show all results" (turns For Me off).
Replace the `scaledFontSize` param (remove, see group 8).

### S7
List header: title `titleSmall`, subtitle `bodySmall` `textMuted`. `padding vertical: 48` → `AppSpacing.xxxl` + `AppSpacing.md`.

---

## 11. `lib/widgets/scheme/scheme_card.dart` — C1–C4, S3

**Owner: SchemeCard.** Layout unchanged (emblem circle | text block | action column).

| # | Before | After |
|---|---|---|
| C1 title | Poppins `isTa ? 13 : 14`, h `isTa ? 1.35 : 1.25` (`:295-300`) | `context.text.cardTitle.copyWith(color: AppColors.textPrimary)`, `maxLines: 3` |
| C1 subtitle | Inter `isTa ? 10.5 : 11` (`:332-337`) | `bodySmall.copyWith(color: AppColors.textMuted)`, `maxLines: 2` |
| C1 match badge | Inter 8.5, `E8F5E8`/`2E7D32` (`:307-325`) | `Container(padding: horizontal sm, vertical xs, decoration: successSoft + radius sm)`, `Text(l10n.matchPercentageFormat(pct), style: label.copyWith(color: AppColors.success))` (12) |
| C1 tags | Inter `isTa ? 9 : 9.5` bold, 14 colour pairs (`:168-222,354-370`) | `label` (12); styles from §3.4 of the design spec: `tagLevel` (Central/National), `tagLevelState` (State/UT), `tagBenefit` (loan/subsidy/grant), else `tagNeutral`; delete `_getTagColors`' hash fallback; add `static TagStyle tagStyleFor(String tag)` in `utils/app_tag_style.dart` |
| C2 — **DONE IN PHASE 1, verify only** | `"${pct}% ${isTa ? 'பொருத்தம்' : 'Match'}"` (`:317`) and toast strings (`:418-420`) | `l10n.matchPercentageFormat(pct)`; toast `l10n.schemeCopiedToast` (keys exist) |
| C3 | covered by C1 tags | |
| C4 share | `Icons.share_outlined` that copies (`:403-438`) | Use `showShare` (default `false`). When shown: `AppIconButton(icon: Icons.copy_rounded, semanticLabel: l10n.copyLinkTooltip, …)` (copy semantics match the icon). Real share sheet is out of scope unless `share_plus` is added |
| S3 bookmark | 30×30 `GestureDetector` (`:383-401`) | `AppIconButton(icon: Icons.bookmark_border_rounded, selected: isBookmarked, selectedIcon: Icons.bookmark_rounded, semanticLabel: isBookmarked ? l10n.removeSavedTooltip : l10n.saveSchemeTooltip, color: AppColors.primary, size: AppSize.icon, onPressed: onBookmarkToggle)` — the action column keeps its position; column width becomes 48 |
| card shell | radius 18, border `E2E8F0` 1.2, shadow alpha .03 (`:237-258`) | `AppCard(onTap: onTap, margin: EdgeInsets.symmetric(vertical: sm, horizontal: lg), padding: lg)`; radius `lg` 16, border `border` 1, `AppShadows.card` |
| logo | 72dp circle `E2E8F0` | same size, `Border.all(color: AppColors.border)`; `Image` gets `excludeFromSemantics: true` (name conveys it) |

Add constructor param `final bool showShare;` (default `false`). Semantics for the card: `AppCard(semanticLabel: '${loc.name}. $subtitle')`.

---

## 12. `lib/widgets/scheme/filter_panel.dart` — S6

**Owner: Filter sheet.**

- Drag handle: delete the manual handle (`:154-164`) and call `showModalBottomSheet(showDragHandle: true, …)` at both callers (`search_screen.dart:445`, `search_results_screen.dart:95`) because the theme default is off (Phase 2 correction).
- Sheet: `Container(height: size.height * 0.8, …)` (`:146-147`) → return `DraggableScrollableSheet(initialChildSize: .85, minChildSize: .5, maxChildSize: .95, expand: false, builder: (ctx, scroll) => …)` with the content `ListView(controller: scroll)`; keep the gradient header look; top radius `AppRadius.xl`. (If the caller uses `showModalBottomSheet(isScrollControlled: true)` already — it does at `search_screen.dart:445`, `search_results_screen.dart:95` — no caller change.)
- Header: title `titleMedium`; "Clear all" → `TextButton(onPressed: _clear, child: Text(l10n.filterClearAll))` (48dp); "Use my profile" row → `TextButton.icon(onPressed: _prefillFromProfile, icon: Icon(Icons.person_pin_circle_outlined, size: 16), label: Text(l10n.filterUseMyProfile(state)))` with `maxLines: 2`.
- Group headers `cardTitle` `textSecondary`.
- `_chip` (`:419-463`): replace `Container(height: 40) + GestureDetector` with
```dart
Semantics(selected: selected, button: true, label: '${spec.label}, ${spec.count}',
  child: AppTappable(onTap: spec.onTap, borderRadius: BorderRadius.circular(AppRadius.pill),
    child: Container(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
      child: Row(children: [
        if (selected) const Padding(padding: EdgeInsets.only(right: AppSpacing.xs), child: Icon(Icons.check_rounded, size: AppSize.iconSm, color: AppColors.textOnPrimary)),
        Expanded(child: Text(spec.label, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: context.text.label.copyWith(color: selected ? AppColors.textOnPrimary : AppColors.textBody))),
        const SizedBox(width: AppSpacing.xs),
        Text('${spec.count}', style: context.text.label.copyWith(
            color: selected ? AppColors.textOnPrimary.withValues(alpha: .9) : AppColors.textSecondary)),   // was 94A3B8 (2.6:1)
      ])))))
```
- "Show N schemes" footer button: themed `ElevatedButton` (min 48), `Text(l10n.filterShowSchemes(n), maxLines: 2, textAlign: center)`; no fixed height.

---

## 13. `lib/screens/regular_mode/saved_schemes_screen.dart` — V1–V5, C5 (and V2 bug)

**Owner: Saved.** Whole file; layout (header, tabs, list, bottom manage hint) is kept except the Manage control moves into the existing header row (explicitly requested in the audit; it removes the hidden bottom banner; the manager approved the audit).

| # | Before | After |
|---|---|---|
| V1 — **DONE IN PHASE 1, verify only** (`:556-562`) | subtitle = `noSavedSchemesDesc` | `Text(bookmarks.isEmpty ? l10n.noSavedSchemesDesc : l10n.savedSubtitleCount(bookmarks.length), style: bodySmall.copyWith(color: textMuted))` |
| V2 label/data — **DONE IN PHASE 1, verify only** (remaining Phase 3 work for V2 is visual: the tab-1 menu/empty state use the new tokens, and the undo toast in V3) | tab 1 label `recentlyAddedTab`, list = `recentlyViewedSchemes` | rename ARB value to "Recently viewed" (`recentlyViewedTab`; keep the old key as an alias or delete after grep); the card menu in tab 1 shows **"Save"** (`l10n.saveSchemeButton`) when the scheme isn't bookmarked, "Remove from saved" when it is; never call a bare `toggleBookmark` for "Remove": `if (isBookmarked) provider.toggleBookmark(id)` for remove, `if (!isBookmarked) provider.toggleBookmark(id)` for save |
| V2 empty copy | one empty state for both tabs (`:455-523`) | `_buildEmptyState(tab)`: tab 0 → `noSavedSchemes` / `noSavedSchemesDesc`; tab 1 → `recentlyViewedEmptyTitle` / `recentlyViewedEmptyDesc`. CTA `browseSchemes` (V5) → `provider.updateTabIndex(1)` (Search) for tab 1 and `2` (Discover) for tab 0 |
| V3 manage (R3: also hides the banner on the "Recently viewed" tab, where the per-card menu no longer exists) | banner is list item `displayedSchemes.length` (`:574-578`) with button | Remove the list item. Add `TextButton.icon(onPressed: toggleManage, icon: Icon(_isManageMode ? Icons.check_rounded : Icons.tune_rounded, size: 16), label: Text(_isManageMode ? l10n.doneManaging : l10n.manageSaved))` at the right end of the title row (`Row[ Expanded(Column(title, subtitle)), TextButton ]`); shown only in tab 0 and when the list is non-empty. When manage mode is on, show a one-line hint above the list (`bodySmall` on `primarySoft`, text `savedRemoveNoLongerInterested`) |
| V3 delete | `IconButton` → immediate `toggleBookmark` (`:214-227`) | `AppIconButton(icon: Icons.delete_outline_rounded, color: AppColors.danger, semanticLabel: l10n.savedRemoveFromSavedTooltip, onPressed: () { provider.toggleBookmark(id); AppToast.showInfo(context, l10n.schemeRemovedToast, actionLabel: l10n.undo, onAction: () => provider.toggleBookmark(id)); })` (undo re-adds) |
| V3 menu | `PopupMenuButton` (`:228-247`) | `PopupMenuButton` with `icon: Icon(Icons.more_vert_rounded)`, `tooltip: l10n.moreOptions`, and `constraints` default (so the hit area is 48) — remove `padding: zero`/`constraints: BoxConstraints()` |
| V4 tabs (`:23-118`) | two `GestureDetector`s, `isTa ? 10.5 : 11.5` | one `SegmentedButton<int>` styled to the pill track: `segments: [ButtonSegment(value: 0, label: Text(l10n.allSavedTabFormat(n), maxLines: 2)), ButtonSegment(value: 1, label: Text(l10n.recentlyViewedTab, maxLines: 2))]`, `showSelectedIcon: false`, `style: SegmentedButton.styleFrom(backgroundColor: AppColors.surfaceMuted, selectedBackgroundColor: AppColors.surface, selectedForegroundColor: AppColors.primary, foregroundColor: AppColors.textSecondary, textStyle: context.text.label, minimumSize: Size(0, 48))`; width `Expanded` (wrap `SizedBox(width: double.infinity)`). Delete the language-dependent vertical padding |
| V5 empty CTA (`:495-518`) | hand-styled `ElevatedButton`, label `navDiscover` | themed `ElevatedButton(child: Text(l10n.browseSchemes))` |
| C5 card (`:120-364`) | own style, 9.5–11sp text, dead icon branches (`:126-146`) | `AppCard` shell; leading 40dp icon tile `primarySoft`/`primary` (**single colour**, delete the if/else); name `cardTitle` `maxLines: 3`; category `label` `primary`; overview `bodySmall` `textSecondary` `maxLines: 2`; meta row `bodySmall textMuted` (government level • scheme type) with 16dp icons; "View details" `OutlinedButton` themed (`label`-sized text from the theme, `maxLines: 2`, no `FitOneLine`) |
| bg | `Scaffold(backgroundColor: 0xFFF8FAFC)` | theme default (`AppColors.background`) |

Title row uses `headline`.

---

## 14. `lib/screens/regular_mode/scheme_details/scheme_bottom_action_bar.dart` + `scheme_details_screen.dart` — G3, SD1–SD5

**Owner: Scheme details (both files).**

### scheme_bottom_action_bar.dart (G3, SD5)
Before: raw `16` paddings; `labelSize = isTamil ? 11.5 : 14`; `SizedBox(height: 54)`; disabled Apply with no reason.
After:
```dart
Container(
  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.md),
  decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.topBar,
      border: const Border(top: BorderSide(color: AppColors.border))),
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    if (!applyEnabled)
      Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(context.l10n.applyUnavailableHint, textAlign: TextAlign.center,
            style: context.text.bodySmall.copyWith(color: AppColors.textMuted))),
    Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: onBookmarkToggle,
        icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: AppSize.icon),
        label: Text(isBookmarked ? l10n.savedSchemeButton : l10n.saveSchemeButton, textAlign: TextAlign.center, maxLines: 2),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)))),      // style-ok: CTA height
      const SizedBox(width: AppSpacing.lg),
      Expanded(child: ElevatedButton(
        onPressed: applyEnabled ? onApply : null,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),        // style-ok: CTA height
        child: Row(mainAxisAlignment: center, children: [
          Flexible(child: Text(l10n.applyNowButton, textAlign: TextAlign.center, maxLines: 2)),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.arrow_forward_rounded, size: AppSize.iconSm)]))),
    ]),
  ]),
)
```
Text size comes from the button theme (`buttonLarge` 16 w700 via `.copyWith(textStyle:)` on both) — **same size in Tamil**. `labelSize`/`isTamil` deleted.

### scheme_details_screen.dart
- **SD1** (`:242,280,298`): `AppToast.showSuccess(context, context.l10n.schemeCopiedToast)`; back tooltip `context.l10n.back`; share action → `AppIconButton(icon: Icons.copy_rounded, semanticLabel: context.l10n.shareSchemeTooltip, …)` (copies; icon matches). Title `titleMedium`.
- **SD2** overview (`:396-403`): `context.text.body.copyWith(color: AppColors.textSecondary)` (14, was 12 `64748B`). Tabs (`:343-375`): `AppTappable(onTap: () => _onTabTapped(index), selected: isSelected, semanticLabel: tabs[index], borderRadius: none)` around the existing underlined `Container`; label `context.text.label.copyWith(fontSize: …)` is **not** allowed → use `label` (12 w600) for unselected and a bold copy via `.copyWith(fontWeight: FontWeight.w700)` for selected; underline `primary` 2dp; min height 48 (`StickyTabBarDelegate.kHeight` → 48, plus `Scrollbar`-less right-edge fade like group 9).
- **SD3 — DONE IN PHASE 1, verify only** (incl. the `schemeCode`→`id` migration): confirm the bottom bar reads and toggles `widget.scheme.id` only and that a scheme saved from Home appears once in Saved. Original spec for reference: `onBookmarkToggle: () => provider.toggleBookmark(widget.scheme.id)` and `isBookmarked: provider.bookmarkedIds.contains(widget.scheme.id)` (drop the schemeCode `||` at `:537-539`). **Also add a one-time migration** in `LibraryController.hydrate`: for each stored id that equals a scheme's `schemeCode` but not an `id`, replace it with that scheme's `id` (dedupe). (Engineering item; coordinate with the Phase-1 owner of `library_controller.dart`.)
- **SD4** (`:384-390,521-523`): content `SliverPadding.bottom: AppSize.tapTarget * 2 + AppSpacing.lg` (room for the action bar), delete the trailing `SizedBox(height: screenHeight * 0.5)`; append a `SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink())` so short pages don't leave odd gaps. Verify tab-jump still reaches the last section (if the last section is too short to align at top, accept it aligning at the bottom).
- **SD5**: `if (_detailsLoading)` spinner (`:417-428`) → three skeleton blocks (`Container(height: 72, decoration: surfaceMuted, radius lg)` with the existing `shimmer_skeleton_card` style) instead of a mid-page `CircularProgressIndicator`.
- Section tiles (`SchemeExpandableSection`): header `cardTitle`, content `body`; expansion arrow `AppIconButton`-free but whole header `AppTappable` 48dp (owner of `scheme_expandable_section.dart` = this group).

---

## 15. `lib/screens/companion_mode/saarthi_welcome_screen.dart` + `assisted_profile/*` — AS2, AS3, AS4, AS5 (AS1 is Phase 1b)

**Owner: Companion welcome.** Do not collide with the Phase 1b owner of `step1_state_selector.dart`; the files below exclude it.

### saarthi_welcome_screen.dart — AS3 (`:290-350`)
Before: `Scaffold > SafeArea > LayoutBuilder > SingleChildScrollView > ConstrainedBox > Padding > IntrinsicHeight > Column[ header, Expanded(step), footer ]`.
After:
```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: AppSpacing.sm),
        StepIndicatorBar(…same args…),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey<int>(_currentStep), child: _buildCurrentStepContent())))),
        AssistedStepFooter(…same args…),     // always visible, outside the scroll area
      ]))))
```
`IntrinsicHeight` is removed. The footer is pinned; on tall screens the look is unchanged.

### step2_gender_age_selector.dart — AS2
- Gender tile (`:196-259`): wrap in `Semantics(button: true, selected: isSelected, label: label)`; tile = `AppTappable` (min 48 already satisfied by content), add a check badge (top-right 16dp `Icons.check_circle_rounded`, `primary`) when selected so state isn't colour-only; label `body`.w600 → `label` is 12; use `body` 14 with `maxLines: 2`, `textAlign: center` (was `maxLines: 1`).
- Stepper buttons (`:262-297`): `AppIconButton(icon: Icons.remove_rounded / add_rounded, semanticLabel: l10n.ageDecrease / l10n.ageIncrease, backgroundColor: enabled ? primarySoft : surfaceMuted, backgroundSize: 52, color: enabled ? primary : disabledFg, onPressed: enabled ? … : null)`; add **hold-to-repeat**: wrap in `GestureDetector(onLongPressStart: startRepeat, onLongPressEnd: stopRepeat)` is a new bare detector → implement inside a new `_RepeatIconButton` widget in this file with `// tap-ok: long-press repeat`; repeat every 120ms, 60ms after 10 steps.
- Age block: `Semantics(label: l10n.ageSelectLabel, value: '$selectedAge ${l10n.ageYearsLabel}', increasedValue: '${(selectedAge + 1).clamp(18, 90)}', decreasedValue: '${(selectedAge - 1).clamp(18, 90)}', onIncrease: …, onDecrease: …, child: …)`. The big number text `display`-like: `context.text.display.copyWith(fontSize: 48)` is **not** allowed → use `display` (28) at `fontWeight w700` and accept the smaller size, OR add one extra scale step `numeral` (48, Poppins w700) to `AppTextStyles` (recommended; used only here).
- Tap the number to type: `AppTappable(onTap: _editAge)` → small dialog with a number `TextField` (18–90 validation), same visuals otherwise.
- Presets `ActionChip`s: `labelStyle` `label`; theme chip.

### assisted_step_footer.dart — AS4
Delete the per-button `styleFrom` (themed `ElevatedButton`, `minimumSize: Size.fromHeight(54)` with `// style-ok`); `Row` children wrapped in `Flexible`, label `maxLines: 2`; when `!isEnabled && !isSubmitting` show above the button `Text(l10n.assistedChooseOne, textAlign: center, style: bodySmall.copyWith(color: AppColors.textMuted))`. Spinner `color: AppColors.textOnPrimary`.

### step_indicator_bar.dart — AS5
- Back: `AppIconButton(icon: Icons.arrow_back_rounded, semanticLabel: l10n.actionBack, onPressed: onBack)`.
- Progress: `Semantics(label: l10n.simpleProfileStepIndicator(currentStep, totalSteps), child: ExcludeSemantics(child: LinearProgressIndicator(…)))`; colours `AppColors.border`/`primary`; radius `AppRadius.sm`.
- Title `titleLarge` (20), subtitle `body` `textMuted`; `height` from the scale (Tamil +0.1 built in).

### step1_state_selector.dart — AS1 review follow-ups (R4; file moves from Phase 1b into this group)
AS1 itself is done (searchable picker, real state value). Remaining: (1) the "Other states" card shows the stored English state name in Tamil mode: use `localizedProperName(selectedState, provider)` for the subtitle (better: card title = localised chosen state, subtitle = "Other states"); (2) wrap the picker sheet content in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom))` so the keyboard doesn't cover the list (`autofocus: true` is kept); (3) mark the current state with a trailing `Icons.check_rounded` (`AppColors.primary`) and show `l10n.noStatesMatch` when the filter is empty; (4) tokenise (`AppColors`, `AppRadius.xl` top corners, `titleMedium`, theme `inputDecorationTheme`).

### assisted_selection_card.dart (reference widget; tokenise only)
Colours → tokens (`AppColors.primary`, `primarySoft`, `border`, `textPrimary`, `primaryDeep`, `surfaceMuted`, `textSecondary`, `borderStrong`); title `cardTitle`-sized Inter → use `body` w600/w700 (14); subtitle `bodySmall` `textMuted`; `Semantics(label: subtitle == null ? title : '$title, $subtitle')`; radius `lg`; `activeColor` default `AppColors.primary`. This widget becomes the model for `AppChoiceCard` if desired.

---

## 16. `lib/screens/regular_mode/categories/*` — D1, D2, D3, D4

**Owner: Discover + calculators (split by file as below, two people possible).**

### categories_section_lists.dart (D1, D2, D3)
- `CategoriesSectionHeader` (`:96-151`): title `titleSmall` (Tamil not smaller); "View all" → `TextButton.icon(onPressed: onViewAll, iconAlignment: IconAlignment.end, icon: Icon(Icons.chevron_right_rounded, size: 16), label: Text(l10n.viewAll))` (48dp).
- `CategoryHorizontalList` (`:168-250`): `SizedBox(height: 126/138)` → `IntrinsicHeight` over a `Row` in a horizontal `SingleChildScrollView` with `minHeight: 126`; tile `AppCard(onTap, width: 134 via ConstrainedBox(minWidth: 134, maxWidth: 160))`; icon 18 → `AppSize.icon` in a `primarySoft` circle; name `cardTitle` `maxLines: 3`; count `label`: `cnt == null` → a 40×10 `surfaceMuted` skeleton bar (D2, replaces `'...'`); `cnt == 0` → `label.copyWith(color: AppColors.warningText)` **and** tile in disabled style (D3): `color: surfaceMuted`, no tap (`onTap: null`), `Semantics(enabled: false, hint: l10n.updatingSoon)`; delete the `showComingSoonInfo` dialog call path (keep the function only if still used elsewhere; grep).
- Same treatment for `MinistryHorizontalList` and `StateHorizontalList` (same file) and for the three "view all" sheets in `categories_view_all_sheets.dart` (`height: size.height * 0.85/0.7` → `DraggableScrollableSheet`, list rows `ListTile` min 48dp, counts `label`).
- `categories_screen.dart:193-208` titles: `headline` / `bodySmall textMuted`.

### emi_calculator_sheet.dart, gst_calculator_sheet.dart, subsidy_estimator_sheet.dart, valuation_estimator_sheet.dart, udyam_classifier_sheet.dart, dpiit_checklist_sheet.dart (D4)
For each sheet (same transformation; EMI shown):
1. Sheet padding (`:36-42`): `EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl)` (removes raw `20/14/24`; also fixes the guard blind spot — compute `viewInsets` into a local `final bottomInset = …;` first so the `EdgeInsets` call has no nested parentheses).
2. Drag handle: pass `showDragHandle: true` to this sheet's `showModalBottomSheet` (the theme default is off, Phase 2 correction D1) and delete the manual `Container(width: 38, height: 4)`.
3. Header title `titleSmall`, subtitle `bodySmall textMuted`, close `AppIconButton(icon: Icons.close_rounded, semanticLabel: l10n.close)`.
4. Each field (`:109-129,166-188,222-241`): delete the separate 11sp label `Text`; use `TextField(decoration: InputDecoration(labelText: l10n.emiLoanAmount, hintText: '500000', prefixText: '₹ ', helperText: l10n.emiLoanAmountHelper, helperMaxLines: 2))` — hint/helper/label styles from the theme (`bodyLarge` text, `bodySmall` helper `textMuted`, hint `textMuted`). Remove per-field `OutlineInputBorder`/`fillColor` (theme). Add `inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]` (rate/loan) and `FilteringTextInputFormatter.digitsOnly` (tenure), `maxLength` where sensible, `textInputAction: next`/`done`.
5. Results: amounts via `formatInr(value)` (§0.2); `FitOneLine` only on the amount `Text` (allowed with `// type-ok: numeric`); labels `body`; result card `AppCard(color: primarySoft)`; error container `dangerSoft`/`dangerBorder`, text `bodySmall` `dangerStrong`, `Semantics(liveRegion: true)`.
6. "Calculate" button: themed `ElevatedButton`, `maxLines: 2`.
Apply the same to GST (`gstRate` dropdown → `DropdownButtonFormField` with `labelText`), subsidy, valuation (their numeric fields use `formatInr`), Udyam classifier and DPIIT checklist (`CheckboxListTile`s for 48dp rows).

---

## 17. `lib/screens/regular_mode/settings_screen.dart` — ST2, ST3, ST4 (ST1 is Phase 1b)

**Owner: Settings.**

- **ST1/ST2 — DROPPED.** Phase 1 wired the push switch to `profile.notificationsEnabled` (48×48 hit area), and the row is being removed in Phase 2 (decision 2.0). Nothing to do here; if the row is retained, make it a `SwitchListTile.adaptive` so the whole row toggles.
- **ST3**: `'User'`/`'U'` (`:276,310,327`) → `l10n.commonUserFallback` and its first letter; version `'1.2.0'` (`:552`) → `PackageInfo.fromPlatform()` (`package_info_plus`, add dependency) shown via `settingsAppVersion(info.version)`.
- **ST4**: `Scaffold` background → theme; AppBar → `StandardPageHeader(title: l10n.profileSettingsTitle)` (group 4) for consistency (left-aligned, 18sp); group header (`:570-582`) `cardTitle`; `_buildSettingRow`: title `body` `w600` `textPrimary`, value `bodySmall` `textMuted` `maxLines: 1`, `TextOverflow.ellipsis` (drop `FitOneLine`, `:641`), chevron `Icons.chevron_right_rounded` size 20 `iconMuted`; dividers `AppColors.border`; `_buildGroupContainer` → `AppCard(padding: zero)`; Logout `OutlinedButton.icon` themed with `maxLines: 2` label (drop `styleFrom` shape/side/padding; keep `minimumSize: Size.fromHeight(48)`); danger confirm uses `confirmColor: AppColors.danger`.
- Profile header card (`:248-379`): name `cardTitle`→`titleSmall` (16, same size in Tamil), phone `bodySmall textMuted`, completion chip `label` `primary` on `primarySoft`; avatar fallback text `titleLarge`.

---

## 18. `lib/screens/profile/*` — PR2, PR3 (PR1 is Phase 1b)

**Owner: Profile.**

- **PR2** `profile_banner_card.dart:75-164`: merge the two `GestureDetector`s into one `AppTappable(onTap: () => changeProfilePicture(context, provider), semanticLabel: l10n.changeProfilePhoto, borderRadius: circle)` around the avatar `Stack`; the camera badge stays a 24dp visual (white circle, `Icons.camera_alt_outlined` 14) with `ExcludeSemantics`; watermark icon `ExcludeSemantics`. Badge row (`:193-235`): text `label` 12, `AppColors.success`/`warningText` on `successSoft`/`warningSoft` pill instead of tinted white on blue (contrast); icon 14. Name `titleSmall` (16, Tamil same size). Gradient stays (brand); text on it `AppColors.textOnPrimary`.
- **PR3** `profile_navigation_sections.dart:24-139` and `profile_widgets.dart`: every `ProfileTile` icon `AppColors.primary` on `AppColors.primarySoft`; logout `danger` on `dangerSoft`. Tile row = `ListTile`-height min 56 with `AppTappable`; title `body`.w600, subtitle `bodySmall textMuted` `maxLines: 2`; card shell `AppCard(padding: zero)`; dividers `AppColors.border`; `ProfileTile.trailingText` `bodySmall`.
- Other profile cards (`profile_user_info_card.dart`, `profile_eligibility_details_card.dart`, `profile_about_dialog.dart`): replace the 4 hardcoded Tamil/English ternaries in `profile_about_dialog.dart:93,107,137,236` with ARB (`aboutTagline`, `aboutDescription`, `aboutCreatedBy`, `close` — reuse `l10n.close`); sizes via scale; `profile_user_info_card.dart:103` `tapTargetSize: shrinkWrap` → remove (default padded).

---

## 19. `lib/screens/regular_mode/sarvam_chat_screen.dart` — CH2 (CH1 is Phase 1b)

**Owner: Chat.**
- `IconButton.filled` send (`:325-335`): `minimumSize: const Size(AppSize.tapTarget, AppSize.tapTarget)`; colours from theme (`ElevatedButton`-like `IconButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.disabledBg)`).
- Composer `TextField`: hint `bodyLarge textMuted`; borders from `inputDecorationTheme` but radius `AppRadius.xl`; focused border `AppColors.primary` 2dp (was `93C5FD` ≈ 1.9:1).
- Starter prompts: `ActionChip` → themed chip, label `label`; show up to 4 prompts (add `sarvamPromptDocuments`, `sarvamPromptEligibility`).
- App-bar: title `titleSmall` ("Saarthi" brand string stays a literal), subtitle `bodySmall`; avatar circle `ExcludeSemantics`.
- Message bubbles: body `body` 14 (`:351` base 14 OK), links `primary` underlined; user bubble `primary`/white text; assistant bubble `surface` + `border`; markdown sizes via the scale; `Semantics(label: '${role == 'user' ? l10n.you : 'Saarthi'}: ${content}')` per bubble.

---

## 20. `lib/screens/regular_mode/msme/*`, `msme_module_details_screen.dart` — MS3 (+F3 follow-through)

**Owner: MSME panels.** (MS1/MS2 are Phase 1b — content localisation/truthfulness.)
- All sizes 10.5–11.5 (`msme_govt_hierarchy_panel.dart:172,194`, `msme_export_panel.dart:97,190`, `msme_treds_panel.dart:181`, `msme_institutions_panel.dart:116,128,245`, `msme_tax_gst_panel.dart:107,118`, `msme_action_panels.dart:477`) → `bodySmall`/`label`.
- `GestureDetector`s at `msme_action_panels.dart:401`, `msme_govt_hierarchy_panel.dart:86`, `msme_treds_panel.dart:95` → `AppTappable` (expandable panel headers `selected`/`expanded` semantics: `Semantics(button: true, expanded: isOpen)`).
- Panel shells → `AppCard`; icon/colour pairs → tokens (`primarySoft`/`primary`, success/warning only for status).

---

## 21. Notifications and Help — light

- `notification_empty_state.dart`: icon `AppColors.iconMuted` 48; title `titleSmall`, body `bodySmall textMuted` (`l10n.notifEmptyBody`), CTA `OutlinedButton(l10n.browseSchemes → provider.updateTabIndex(1))`; replace `vertical: 80` with `AppSpacing.xxxl` ×2.
- `notification_category_bar.dart`: `Container(height: 38)` → `ConstrainedBox(minHeight: 48)`; chips → `ChoiceChip` (themed, `showCheckmark: true`), label `label`; `Semantics(selected:)` comes with `ChoiceChip`.
- `notification_cards.dart` (52 hex, sizes 8.5/10/10.5/11.5): tokens via the colour map; card `AppCard`; badges `label` 12; timestamps `bodySmall textMuted`; unread dot + `Semantics(label: unread)`.
- `help_support/*`: same field rules as group 4; sub-12 sizes → scale; bare `GestureDetector`s (`help_support_sections.dart` ×2) → `AppTappable`.

---

## 22. Cross-cutting: G3 Tamil sizes (done inside the groups above)

The explicit list to delete so nothing is missed (grep `isTa ?`/`isTamil ?` + `fontSize`/`height`/`0.92`): `scheme_card.dart:296,299,333,365`, `saved_schemes_screen.dart:41,64,81,104,186,191`, `scheme_bottom_action_bar.dart:30`, `search_screen.dart:70`, `main.dart:180-185,358` (nav labels), `home_updates_section.dart:191-198`, `categories_section_lists.dart:98,112,169,224,229`, `profile_banner_card.dart:181-188`, `settings_screen.dart:331-338`, `assessment_sheet_header.dart:93,129`, `assessment_sheet_footer.dart:39,59`, `assessment_question_card.dart:52,55,64,66,108,115`, `home_header_section.dart` (none). Acceptance: `grep -rE "isTa(mil)?\s*\?\s*[0-9.]+\s*:\s*[0-9.]+" frontend/lib` returns nothing.

---

## Collision map (who edits which file)

| Group | Files (exclusive) |
|---|---|
| 0 | `widgets/common/quick_pills.dart` (new), `utils/money_format.dart` (new) |
| 1 | `main.dart`, `utils/app_theme.dart` |
| 2 | `screens/login_screen.dart` |
| 3 | `screens/beta_gate_screen.dart`, `widgets/legal/legal_consent_section.dart` |
| 4 | `widgets/common/{standard_page_header,custom_input_field,app_toast,custom_confirm_dialog}.dart`, `screens/regular_mode/basic_profile/custom_input_field.dart` |
| 5 | `home/home_header_section.dart` |
| 6 | `home/home_recommended_section.dart` |
| 7 | `home/{home_msme_support_section,home_promo_carousel_section,home_journey_section,home_updates_section,home_profile_completion_card}.dart`, `home_screen.dart` |
| 8 | `search/search_input_section.dart`, `search_screen.dart` (remove `scaledFontSize`, pass new params, `canSortByProfile`) |
| 9 | `search/search_filter_strip.dart` |
| 10 | `search/search_results_view.dart`, `search_results_screen.dart` |
| 11 | `widgets/scheme/scheme_card.dart`, `utils/app_tag_style.dart` (new) |
| 12 | `widgets/scheme/filter_panel.dart` |
| 13 | `saved_schemes_screen.dart` |
| 14 | `scheme_details/*`, `scheme_details_screen.dart` |
| 15 | `companion_mode/saarthi_welcome_screen.dart`, `companion_mode/assisted_profile/*` (except `step1_state_selector.dart`, Phase 1b) |
| 16 | `categories/*`, `categories_screen.dart` |
| 17 | `settings_screen.dart` |
| 18 | `screens/profile/*`, `profile_screen.dart` |
| 19 | `sarvam_chat_screen.dart` |
| 20 | `msme/*`, `msme_module_details_screen.dart` |
| 21 | `notifications/*`, `notifications_screen.dart`, `help_support/*` |

Groups 8 and 9 and 10 touch `search_screen.dart` only through group 8 (it owns the file; 9 and 10 need params added there: group 8 adds `canSortByProfile`, `hasActiveFacets`, `onClearFilters`, `onClearSearch`, `onPillSelected` plumbing at the same time).
Land order: 0 → 1/4 (parallel) → everything else in parallel → 22 grep check.

---

## §Z — New / changed ARB keys (add to **both** `app_en.arb` and `app_ta.arb`)

Reuse any existing key with the same meaning (grep first). Tamil strings are proposed; have a Tamil speaker review before release.

| Key | English | Tamil |
|---|---|---|
| `loginChecklistTerms` | Read the Terms of Use | பயன்பாட்டு விதிமுறைகளைப் படிக்கவும் |
| `loginChecklistPrivacy` | Read the Privacy Policy | தனியுரிமைக் கொள்கையைப் படிக்கவும் |
| `loginChecklistAgree` | Agree to continue | தொடர ஒப்புக்கொள்ளவும் |
| `loginOpeningGoogle` | Opening Google… | Google-ஐத் திறக்கிறது… |
| `loginReviewLegalFirst` | Please review the Terms of Use and Privacy Policy before continuing. | தொடர்வதற்கு முன் பயன்பாட்டு விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையைப் படிக்கவும். |
| `betaGatePasswordLabel` | Beta password | பீட்டா கடவுச்சொல் |
| `showPassword` / `hidePassword` | Show password / Hide password | கடவுச்சொல்லைக் காட்டு / மறை |
| `notificationsTooltip` | Notifications | அறிவிப்புகள் |
| `notificationsUnreadCount(n)` | {n} unread | {n} படிக்காதவை |
| `quickPillPmegpQuery` | PMEGP | PMEGP |
| `quickPillStartupQuery` | Startup | தொடக்க நிறுவனம் |
| `quickPillLoansQuery` | Loans | கடன் |
| `quickPillWomenQuery` | Women | பெண்கள் |
| `quickPillAscendQuery` | ASCEND | ASCEND |
| `homeRecommendedEmptyTitle` | Complete your profile to see schemes for you | உங்களுக்கான திட்டங்களைக் காண சுயவிவரத்தை நிறைவு செய்யுங்கள் |
| `homeRecommendedEmptyBody` | Add a few details and we will show schemes you may be eligible for. | சில விவரங்களைச் சேர்த்தால், நீங்கள் தகுதி பெறக்கூடிய திட்டங்களைக் காட்டுவோம். |
| `completeProfileCta` | Complete profile | சுயவிவரத்தை நிறைவு செய் |
| `saveSchemeTooltip` | Save scheme | திட்டத்தைச் சேமி |
| `removeSavedTooltip` | Remove from saved | சேமிப்பிலிருந்து நீக்கு |
| `schemeCopiedToast` | Scheme details copied | திட்ட விவரங்கள் நகலெடுக்கப்பட்டது |
| `copyLinkTooltip` | Copy link | இணைப்பை நகலெடு |
| `shareSchemeTooltip` | Copy scheme details | திட்ட விவரங்களை நகலெடு |
| `clearFilters` | Clear filters | வடிகட்டிகளை அழி |
| `clearSearch` | Clear search | தேடலை அழி |
| `forMeTooltip` | Show only schemes you are eligible for (uses your profile) | உங்கள் சுயவிவரத்தின்படி தகுதியான திட்டங்களை மட்டும் காட்டு |
| `sortBestMatchNeedsProfile` | Complete your profile to use this | இதைப் பயன்படுத்த சுயவிவரத்தை நிறைவு செய்யவும் |
| `savedSubtitleCount(n)` | {n} schemes saved | {n} திட்டங்கள் சேமிக்கப்பட்டன |
| `recentlyViewedTab` | Recently viewed | சமீபத்தில் பார்த்தவை |
| `recentlyViewedEmptyTitle` | Nothing viewed yet | இன்னும் எதுவும் பார்க்கவில்லை |
| `recentlyViewedEmptyDesc` | Schemes you open will appear here. | நீங்கள் திறக்கும் திட்டங்கள் இங்கே தோன்றும். |
| `browseSchemes` | Browse schemes | திட்டங்களைப் பார்க்க |
| `schemeRemovedToast` | Removed from saved | சேமிப்பிலிருந்து நீக்கப்பட்டது |
| `undo` | Undo | செயல்தவிர் |
| `moreOptions` | More options | மேலும் விருப்பங்கள் |
| `applyUnavailableHint` | No official application link yet | அதிகாரப்பூர்வ விண்ணப்ப இணைப்பு இன்னும் இல்லை |
| `assistedChooseOne` | Choose one option to continue | தொடர ஒரு விருப்பத்தைத் தேர்ந்தெடுக்கவும் |
| `ageIncrease` / `ageDecrease` | Increase age / Decrease age | வயதைக் கூட்டு / குறை |
| `changeProfilePhoto` | Change profile photo | சுயவிவரப் படத்தை மாற்று |
| `msmeUdyamTitle`/`Desc`, `msmeExportTitle`/`Desc` | (existing English strings from `home_journey_section.dart:94-113`) | (translate) |
| `notifEmptyBody` | New scheme updates and reminders will show up here. | புதிய திட்ட அறிவிப்புகள் மற்றும் நினைவூட்டல்கள் இங்கே தோன்றும். |
| `aboutTagline`, `aboutDescription`, `aboutCreatedBy` | (move the ternary strings from `profile_about_dialog.dart:93,107,137`) | (existing Tamil strings) |
| `sarvamPromptDocuments`, `sarvamPromptEligibility` | Which documents do I need? / Am I eligible for a loan? | எனக்கு என்ன ஆவணங்கள் தேவை? / நான் கடனுக்குத் தகுதியானவரா? |
| `recentlyAddedTab` | (remove or alias to `recentlyViewedTab`) | |

---

## §Z2 — Phase 1 review follow-ups (copy and wording; all land in Phase 3)

Owner groups are in the last column. Strings are exact; paste as given. Tamil still needs a native-speaker pass before release.

| # | Key | Change | Owner |
|---|---|---|---|
| 1 | `savedSubtitleCountFormat` | **Replace the value** with an ICU plural in both ARBs and keep the `count` placeholder metadata (`"placeholders": {"count": {"type": "int"}}`). EN: `{count, plural, =1{1 scheme saved} other{{count} schemes saved}}`. TA: `{count, plural, =1{1 திட்டம் சேமிக்கப்பட்டுள்ளது} other{{count} திட்டங்கள் சேமிக்கப்பட்டுள்ளன}}`. Regenerate `app_localizations*.dart`. Call site is unchanged (`savedSubtitleCountFormat(bookmarks.length)`). Add a widget-test case for count 1 and 2. | 13 (Saved) |
| 2 | `aiDisclaimerNotice` (Sarvam chat) | **Style:** `context.text.bodySmall.copyWith(color: AppColors.textMuted)` = **12sp** (was Inter 11, `sarvam_chat_screen.dart` `_buildDisclaimer`), `textAlign: center`, **no `maxLines` and no ellipsis** (a safety notice must never be truncated). Target: ≤ 2 lines at scale 1.0 in both languages on a 320dp phone; wrapping to 3 at 1.6× is acceptable. Background `AppColors.background`, padding `horizontal: AppSpacing.lg, vertical: AppSpacing.xs` (unchanged). **Tamil text shortened to fit 2 lines:** TA `AI தவறாகக் கூறலாம். அதிகாரப்பூர்வ இணையதளத்தில் சரிபார்க்கவும்.` (≈ 62 chars; was 89). EN unchanged: `AI can make mistakes. Check details on the official scheme website.` | 19 (Chat) |
| 3 | `msmeFeatureTaxGst2` (TA) | Remove the duplicated word. TA: `GST பதிவு வரம்புகள் (₹40/₹20 லட்சம் விலக்குகள்)` (EN unchanged). | 20 (MSME) |
| 4 | `msmeFeatureUdyam4` (TA) | Replace the phonetic spelling with the usual term. TA: `அரசு டெண்டர்களில் முன்வைப்புத் தொகை (EMD) விலக்கு` (EN unchanged). | 20 (MSME) |
| 5 | `searchStateOrUtPlaceholder` (TA) | Replace "யூடி". TA: `மாநிலம்/யூனியன் பிரதேசத்தைத் தேடுக` (≈ 35 chars so the hint fits on one line in the 14sp field on a 320dp phone; the longer form `மாநிலம் அல்லது யூனியன் பிரதேசத்தைத் தேடுங்கள்` truncates). EN unchanged: `Search state or UT`. Use the same Tamil for the `allStatesAndUts` sheet title if it still says "UT". | 15 (step1 selector) |
| 6 | `noStatesMatch` (new, R4) | EN `No states match your search`; TA `உங்கள் தேடலுக்கு பொருந்தும் மாநிலங்கள் இல்லை`. | 15 |
| 7 | `homeRecommendationsNoMatches` (new, R1) | EN `No matches yet — try Search or Discover`; TA `இன்னும் பொருத்தங்கள் இல்லை — தேடல் அல்லது கண்டறிதலைப் பயன்படுத்துங்கள்`. | 6 (Home recommended) |
| 8 | `msmeFeatureTreds1`, `msmeFeatureTreds7` (TA, recommended) | Avoid mixed-script transliterations. TREDS1 TA: `விலைப்பட்டியல் தள்ளுபடி: பல தரப்பு தளங்கள் விளக்கம்`. TREDS7 TA: `திரும்பப்பெறும் vs. திரும்பப்பெறாத கடன் வசூல் (factoring) வரையறைகள்`. | 20 |
| 9 | `loginReviewTermsNotice` (TA, only if it clips on device) | Shorten to ≈ 62 chars: `தொடர்வதற்கு முன் விதிமுறைகள் & தனியுரிமைக் கொள்கையைப் படிக்கவும்`. Verify at 320dp first. | 2 (Login) |

Open product question (not a spec item): `msmeFeatureFinance5` "Detailed comparisons of loan interest rates" — manager has put it on the PR's product-owner list; if the owner says the feature doesn't exist, delete the line in `msme_main_features_section.dart` (Finance list) and the two ARB keys.
