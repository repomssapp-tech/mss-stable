# MSS App — Design-System Spec (Phase 2)

**Author:** designer session · **Date:** 2026-10-02 · **For:** programmer (Phase 2) · **Status:** approved inputs from manager (G2 ceiling 1.6×, "Best match for me" stays opt-in, H1 CTA replaces placeholders).

**Hard constraint:** no layout changes. Everything here changes styling, tokens, hit areas and semantics only. Where a hit area must grow to 48dp, grow it with padding/`ConstrainedBox` and keep the *visual* size the same.

Contrast numbers below were computed from the hex values (WCAG relative luminance).

**Files to add** (all under `frontend/lib/utils/` unless noted):

| File | Contents |
|---|---|
| `app_text.dart` | `AppTextStyles`, `context.text`, font family constants |
| `app_colors.dart` | `AppColors` (semantic tokens), `AppColors.contrastPairs` |
| `app_radius.dart` | `AppRadius` |
| `app_size.dart` | `AppSize` (tap target, icon sizes, control heights, border widths) |
| `app_elevation.dart` | `AppShadows` |
| `app_theme.dart` (extend) | `AppTheme.light` = the whole `ThemeData` (moved out of `main.dart`) |
| `widgets/common/app_icon_button.dart` | `AppIconButton` |
| `widgets/common/app_tappable.dart` | `AppTappable` (chips, tabs, rows) |
| `widgets/common/app_card.dart` | `AppCard` (revives `AppCardStyle`) |
| `test/guards/…` | the guard tests in §8 |

---

## 0. Font delivery (do this first — it's a correctness issue)

Today `google_fonts: ^8.1.0` fetches Inter/Poppins **at runtime** and no font files are bundled (`pubspec.yaml:133` fonts block is commented out; `main.dart` never sets `allowRuntimeFetching`). For an offline-first app this means:

- first launch offline → Roboto fallback everywhere;
- Tamil has no glyphs in Inter/Poppins → the system falls back per character to whatever Tamil font the device has (metrics and weights don't match, which is part of why Tamil looks cramped).

**Spec:**

1. Bundle fonts as assets (SIL OFL, free): **Inter** (400, 500, 600, 700), **Poppins** (600, 700), **Noto Sans Tamil** (400, 500, 600, 700). Put them in `frontend/assets/fonts/`.
2. Declare in `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
    - family: NotoSansTamil
      fonts:
        - asset: assets/fonts/NotoSansTamil-Regular.ttf
        - asset: assets/fonts/NotoSansTamil-Medium.ttf
          weight: 500
        - asset: assets/fonts/NotoSansTamil-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/NotoSansTamil-Bold.ttf
          weight: 700
```
3. `AppText` uses plain `TextStyle(fontFamily: …, fontFamilyFallback: ['NotoSansTamil'])`, so styles are `const`. After the codemod in §1.5, remove `google_fonts` from `pubspec.yaml` (or, if it is kept for something else, set `GoogleFonts.config.allowRuntimeFetching = false` in `main()`).
4. Size budget: the four Inter + two Poppins + four Noto Tamil TTFs add roughly 1–1.5 MB (subset Noto Tamil to Tamil + Basic Latin + punctuation + `₹` if the size matters).

---

## 1. `AppText` — type scale

### 1.1 Steps

Floor is **12sp**. Nothing in the app may render below 12 (before text scaling). Line-heights are for Latin; Tamil adds `+0.10` (see §1.3). All sizes are logical px, `fontWeight` as listed.

| Name | Font | Size | Weight | Height (en) | Height (ta) | Use |
|---|---|---|---|---|---|---|
| `display` | Poppins | 28 | w700 | 1.25 | 1.35 | splash/welcome hero, big numbers (EMI result) |
| `headline` | Poppins | 24 | w700 | 1.30 | 1.40 | **tab screen titles** (Search, Saved, Discover, Profile), greeting name |
| `titleLarge` | Poppins | 20 | w700 | 1.30 | 1.40 | dialog/sheet titles, large section headers |
| `titleMedium` | Poppins | 18 | w700 | 1.30 | 1.40 | **sub-screen app-bar title** (`StandardPageHeader`), filter sheet title |
| `titleSmall` | Poppins | 16 | w700 | 1.35 | 1.45 | section headers on a screen ("Recommended for you") |
| `cardTitle` | Poppins | 14 | w700 | 1.35 | 1.45 | scheme names in cards, list-row titles |
| `bodyLarge` | Inter | 16 | w400 | 1.50 | 1.60 | text-field input text, long-form reading |
| `body` | Inter | 14 | w400 | 1.50 | 1.60 | default paragraph/list text |
| `bodySmall` | Inter | 12 | w400 | 1.45 | 1.55 | secondary lines, hints, helper/error text, timestamps (sentences) |
| `label` | Inter | 12 | w600 | 1.40 | 1.50 | chips, tags, badges, tab labels, filter counts, nav labels |
| `button` | Inter | 14 | w600 | 1.30 | 1.40 | all button labels |
| `buttonLarge` | Inter | 16 | w700 | 1.30 | 1.40 | primary full-width CTA (Continue, Apply Now, Sign in) |

Colour is **not** baked in. Callers use `.copyWith(color: …)` with an `AppColors` token.

### 1.2 Code

```dart
// lib/utils/app_text.dart
import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const heading = 'Poppins';
  static const body = 'Inter';
  static const tamil = 'NotoSansTamil';
  static const fallback = <String>[tamil];
}

@immutable
class AppTextStyles {
  const AppTextStyles._(this._tamilBump);
  final double _tamilBump;

  static const en = AppTextStyles._(0);
  static const ta = AppTextStyles._(0.10);

  static AppTextStyles forLocale(Locale l) => l.languageCode == 'ta' ? ta : en;

  TextStyle _h(double size, double h, FontWeight w) => TextStyle(
        fontFamily: AppFonts.heading, fontFamilyFallback: AppFonts.fallback,
        fontSize: size, fontWeight: w, height: h + _tamilBump);
  TextStyle _b(double size, double h, FontWeight w) => TextStyle(
        fontFamily: AppFonts.body, fontFamilyFallback: AppFonts.fallback,
        fontSize: size, fontWeight: w, height: h + _tamilBump);

  TextStyle get display      => _h(28, 1.25, FontWeight.w700);
  TextStyle get headline     => _h(24, 1.30, FontWeight.w700);
  TextStyle get titleLarge   => _h(20, 1.30, FontWeight.w700);
  TextStyle get titleMedium  => _h(18, 1.30, FontWeight.w700);
  TextStyle get titleSmall   => _h(16, 1.35, FontWeight.w700);
  TextStyle get cardTitle    => _h(14, 1.35, FontWeight.w700);
  TextStyle get bodyLarge    => _b(16, 1.50, FontWeight.w400);
  TextStyle get body         => _b(14, 1.50, FontWeight.w400);
  TextStyle get bodySmall    => _b(12, 1.45, FontWeight.w400);
  TextStyle get label        => _b(12, 1.40, FontWeight.w600);
  TextStyle get button       => _b(14, 1.30, FontWeight.w600);
  TextStyle get buttonLarge  => _b(16, 1.30, FontWeight.w700);
}

extension AppTextContext on BuildContext {
  AppTextStyles get text =>
      AppTextStyles.forLocale(Localizations.localeOf(this));
}
```

Usage: `Text(l10n.savedTitle, style: context.text.headline.copyWith(color: AppColors.textPrimary))`.

Also build `ThemeData.textTheme` from these so Material widgets agree (map: `headlineSmall`→headline, `titleLarge`→titleLarge, `titleMedium`→titleSmall, `titleSmall`→cardTitle, `bodyLarge`→bodyLarge, `bodyMedium`→body, `bodySmall`→bodySmall, `labelLarge`→button, `labelMedium`→label, `labelSmall`→label). Delete the current dead `textTheme` in `main.dart:203-261`.

### 1.3 Tamil rules (typography)

1. **Same size as English for the same role. Never shrink for Tamil.** Delete every `isTa ? x : y` that changes `fontSize` (list in audit G3: `scheme_card.dart:296,333,365`, `saved_schemes_screen.dart:64,104,186`, `scheme_bottom_action_bar.dart:30`, `search_screen.dart:70` (`* 0.92`), `main.dart:358`, `assessment_*`, `home_updates_section.dart:191`).
2. Tamil line-height is the English value `+0.10` (done inside `AppTextStyles.ta`). Never set `height` below 1.35 on any Tamil text.
3. Handle length by **wrapping, not shrinking**: titles `maxLines: 3`, subtitles `maxLines: 2`, button labels `maxLines: 2` with `textAlign: center`, chips `maxLines: 2` or allow `Wrap`. Use `TextOverflow.ellipsis` only as the last guard at those line counts.
4. **`FitOneLine` / `FittedBox(scaleDown)` is banned for body, label and button text** (it silently reduces below the 12sp floor). It stays allowed for numeric/currency displays only (EMI amounts) and must have `// type-ok` with the reason.
5. Single-line truncation (`maxLines: 1`) is allowed only for: bottom-nav labels, app-bar titles when a subtitle is present, user names. For nav labels, if a Tamil label doesn't fit at 12sp, shorten the ARB string (see §5.3), not the font.
6. No fixed-height containers around text (`SizedBox(height: n)` / `Container(height: n)`); use `ConstrainedBox(minHeight: n)`. Exceptions: decorative strips with no text.

### 1.4 Old → new size mapping (all 29 sizes found in `lib/`)

Counts are the number of literals today. "By role" means choose the step from the widget's role.

| Old size | Count | New step | Rule |
|---|---|---|---|
| 8 | 2 | `label` 12 | badge/tag text |
| 8.5 | 8 | `label` 12 | badges (match %, "NEW", notification tags) |
| 9 | 20 | `label` 12 | tags, chart captions |
| 9.5 | 35 | `label` 12 | tags, nav labels, journey tiles |
| 10 | 30 | `label` 12 (pill/short) · `bodySmall` 12 (sentence) | by role |
| 10.5 | 39 | `label` 12 / `bodySmall` 12 | by role |
| 11 | 82 | `bodySmall` 12 (sentence/caption) · `label` 12 (pill/count) | by role |
| 11.5 | 57 | `bodySmall` 12 / `label` 12 | by role |
| 12 | 77 | `bodySmall` 12 (regular) · `label` 12 (w600+) | by weight |
| 12.5 | 36 | `bodySmall` 12 · `label` 12 | by weight |
| 13 | 74 | `body` 14 (Inter) · `cardTitle` 14 (Poppins) · `bodySmall` 12 only if purely secondary | by role |
| 13.5 | 28 | `body` 14 · `cardTitle` 14 | by role |
| 14 | 47 | `body` / `cardTitle` / `button` 14 | by role |
| 14.5 | 13 | `body` 14 (field text in wizard → `bodyLarge` 16) | by role |
| 15 | 26 | `body` 14 (Inter) · `titleSmall` 16 (Poppins/bold) | by font |
| 15.5 | 2 | `titleSmall` 16 | |
| 16 | 22 | `bodyLarge` (input) · `titleSmall` (Poppins) · `buttonLarge` (CTA) | by role |
| 16.5 | 6 | `titleSmall` 16 | section headers |
| 17 | 5 | `titleSmall` 16 (section) · `titleMedium` 18 (page title) | by role |
| 18 | 23 | `titleMedium` 18 | |
| 20 | 5 | `titleLarge` 20 | |
| 22 | 4 | `titleLarge` 20 | |
| 24 | 4 | `headline` 24 | |
| 25 | 1 | `headline` 24 | |
| 26 | 3 | `headline` 24 | |
| 28 | 1 | `display` 28 | |
| 30 | 1 | `display` 28 | |
| 32 | 1 | `display` 28 | |
| 34 | 1 | `display` 28 | |

Result: 29 sizes → **7 distinct sizes** (12, 14, 16, 18, 20, 24, 28). Some places will visibly grow (≈270 sites rise to 12). That is intended; check them in the QA pass.

### 1.5 Codemod suggestion

Mechanical: regex-replace `GoogleFonts\.(inter|poppins)\(\s*fontSize: N, …\)` into `context.text.<step>.copyWith(color: …)`. Do it per file by the role rule above; don't run it blind.
Keep `fontWeight` overrides only when they differ from the step (e.g. `label` with `w700`); prefer picking the step that already has the weight.

---

## 2. Text scale policy (`main.dart`)

Replace `main.dart:180-189`:

```dart
builder: (context, child) {
  final mq = MediaQuery.of(context);
  final scale = mq.textScaler.clamp(
    minScaleFactor: 1.0,   // no English floor
    maxScaleFactor: 1.6,   // same for en and ta (revisit 2.0 after fixed-height pass)
  );
  return MediaQuery(data: mq.copyWith(textScaler: scale), child: child!);
},
```

`TextScaler.clamp` keeps non-linear OS scaling intact. Remove `isTamil` from this code.
Acceptance: at OS font scale 1.0 English text is 1.2× **smaller** than today (the floor is gone), which is why §1 must raise the small sizes at the same time. Ship §1 and §2 together, not separately.

---

## 3. Colour tokens

### 3.1 Principles

- One palette: the existing Slate + Blue family already used for ~90% of literals.
- Text tokens all pass **≥ 4.5:1** on the surfaces listed beside them. `textMuted` was `64748B` (4.34:1 on `F1F5F9`, 3.86 on `E2E8F0`); it moves to `5B6B82`.
- Never use `iconMuted`, `borderStrong` or `disabledFg` for text that carries meaning.
- Category/tag colours are a separate small palette (§3.4), not ad-hoc hex.

### 3.2 Tokens

```dart
// lib/utils/app_colors.dart
abstract final class AppColors {
  // Surfaces
  static const background    = Color(0xFFF8FAFC); // scaffold
  static const surface       = Color(0xFFFFFFFF); // cards, sheets, inputs
  static const surfaceMuted  = Color(0xFFF1F5F9); // tab-bar track, chip bg, skeleton
  static const border        = Color(0xFFE2E8F0); // all hairlines/card borders
  static const borderStrong  = Color(0xFFCBD5E1); // dividers on tinted surfaces, drag handle, outline buttons (inactive)

  // Text
  static const textPrimary   = Color(0xFF0F172A); // 17.9:1 on surface
  static const textBody      = Color(0xFF334155); // 10.4:1 on surface
  static const textSecondary = Color(0xFF475569); // 7.6 surface · 6.9 surfaceMuted · 6.2 on E2E8F0
  static const textMuted     = Color(0xFF5B6B82); // 5.4 surface · 5.2 background · 4.95 surfaceMuted · 5.0 primarySoft
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Icons / non-text (≥ 3:1 on surface, background, surfaceMuted)
  static const iconMuted     = Color(0xFF73839A); // 3.9 / 3.7 / 3.5

  // Disabled (exempt from contrast, but stay legible)
  static const disabledBg    = Color(0xFFE2E8F0);
  static const disabledFg    = Color(0xFF8091A7);

  // Brand / interactive
  static const primary       = Color(0xFF2563EB); // 5.2 on white; white on it 5.2
  static const primaryStrong = Color(0xFF1D4ED8); // text on primarySoft: 6.2
  static const primaryDeep   = Color(0xFF1E3A8A); // headings in info banners: 9.5 on primarySoft
  static const primarySoft   = Color(0xFFEFF6FF); // selected chip bg, info banner bg
  static const primaryTint   = Color(0xFFDBEAFE); // icon-badge bg, selected border
  static const primaryBorder = Color(0xFFBFDBFE); // border on primarySoft
  static const primaryLight  = Color(0xFF60A5FA); // decor only (gradients, illustrations)

  // Status
  static const success       = Color(0xFF15803D); // 5.0 on white; white on it 5.0
  static const successSoft   = Color(0xFFDCFCE7); // text 15803D on it 4.6
  static const warning       = Color(0xFFD97706); // FILL / ICON ONLY (3.2:1 on white)
  static const warningText   = Color(0xFFB45309); // text on white 5.0
  static const warningSoft   = Color(0xFFFEF3C7); // text warningOnSoft on it 6.4
  static const warningOnSoft = Color(0xFF92400E);
  static const danger        = Color(0xFFDC2626); // 4.8 on white; white on it 4.8
  static const dangerStrong  = Color(0xFFB91C1C); // text on dangerSoft: 5.3–5.9
  static const dangerSoft    = Color(0xFFFEF2F2);
  static const dangerBorder  = Color(0xFFFCA5A5);

  // Saffron accent from the old palette: decorative only (2.1:1 with white text → never a text or button fill)
  static const accent        = Color(0xFFFF9933);

  /// (foreground, background, minRatio) pairs asserted by test/guards/contrast_test.dart.
  static const contrastPairs = <(Color, Color, double)>[
    (textPrimary, surface, 4.5), (textBody, surface, 4.5),
    (textSecondary, surface, 4.5), (textSecondary, surfaceMuted, 4.5),
    (textMuted, surface, 4.5), (textMuted, background, 4.5),
    (textMuted, surfaceMuted, 4.5), (textMuted, primarySoft, 4.5),
    (textOnPrimary, primary, 4.5), (textOnPrimary, danger, 4.5), (textOnPrimary, success, 4.5),
    (primary, surface, 4.5), (primary, primarySoft, 4.5), (primaryStrong, primaryTint, 4.5),
    (primaryDeep, primarySoft, 4.5),
    (success, successSoft, 4.5), (warningText, surface, 4.5), (warningOnSoft, warningSoft, 4.5),
    (danger, surface, 4.5), (dangerStrong, dangerSoft, 4.5),
    (iconMuted, surface, 3.0), (iconMuted, background, 3.0), (iconMuted, surfaceMuted, 3.0),
  ];
}
```

Gradient helpers: keep `AppConstants.blueGradient` (`F8FAFC → E0F2FE → EFF6FF`). Move to `AppColors.scaffoldGradient`.

`AppConstants` colour constants stay for one phase as deprecated forwards (`primaryColor => AppColors.primary`, `secondaryColor` → `primaryStrong`, `successColor` → `success`, `warningColor` → `warning`, `errorColor` → `danger`, `backgroundColor`, `surfaceColor`, `cardBorderColor` → `border`, `primaryText` → `textPrimary`, `secondaryText` → `textMuted`) so the 118-file sweep can land screen by screen.

Wire `ColorScheme.fromSeed(seedColor: primary)` then `.copyWith(primary, onPrimary: textOnPrimary, secondary: primaryStrong, surface, onSurface: textPrimary, error: danger, outline: border, outlineVariant: borderStrong, surfaceContainerHighest: surfaceMuted)`.

### 3.3 Mapping the 30 most-used hex literals (of 207 distinct)

| Hex today | Uses | → Token | Note |
|---|---|---|---|
| `2563EB` | 255 | `primary` | |
| `64748B` | 174 | `textMuted` (`5B6B82`) | slightly darker; for **icons** use `iconMuted` |
| `0F172A` | 165 | `textPrimary` | |
| `E2E8F0` | 151 | `border` | |
| `EFF6FF` | 81 | `primarySoft` | |
| `94A3B8` | 67 | text/hint → `textMuted`; icon/dot/dash → `iconMuted`; disabled → `disabledFg` | was 2.56:1 |
| `F8FAFC` | 47 | `background` | |
| `475569` | 42 | `textSecondary` | |
| `334155` | 36 | `textBody` | |
| `F1F5F9` | 30 | `surfaceMuted` | also replaces `AppCardStyle.borderColor` |
| `CBD5E1` | 29 | `borderStrong` (borders) · `disabledBg` (disabled fills) | never text |
| `1E293B` | 26 | `textPrimary` | |
| `DC2626` | 26 | `danger` | |
| `DBEAFE` | 24 | `primaryTint` | |
| `047857` | 17 | `success` | emerald → the one green |
| `93C5FD` | 17 | `primaryBorder` | |
| `16A34A` | 14 | `success` | |
| `EF4444` | 12 | `danger` (fill/icon) | 3.76:1 on white as text → don't use for text |
| `1D4ED8` | 12 | `primaryStrong` | |
| `1E3A8A` | 11 | `primaryDeep` | |
| `D97706` | 11 | `warning` (fill/icon) · `warningText` for text | |
| `ECFDF5` | 10 | `successSoft` | |
| `B91C1C` | 9 | `dangerStrong` | |
| `BFDBFE` | 8 | `primaryBorder` | |
| `FEF2F2` | 8 | `dangerSoft` | |
| `EA580C` | 8 | `warning` | |
| `F59E0B` | 8 | `warning` | |
| `7C3AED` / `6D28D9` / `7B1FA2` | 7/5/4 | category violet (§3.4) | |
| `137C47` / `15803D` / `2E7D32` | 7/7/– | `success` | |
| `0F766E` | 7 | category teal (§3.4) | |
| `F0FDF4` / `E8F5E9` / `DCFCE7` | 6/5/6 | `successSoft` | |
| `FEE2E2` | 6 | `dangerSoft` (bg) | text on it → `dangerStrong` |
| `60A5FA` | 6 | `primaryLight` | decor only |
| `FCA5A5` | 6 | `dangerBorder` | |
| `F5F3FF` / `F3E5F5` | 6/5 | category violet soft | |
| `4ADE80`, `6D5DFB`, `0D53FC` | 6/6/5 | voice/companion palette (§3.5), allowlisted | |
| `E11D48` | 4 | `danger` | |

Long tail (~170 distinct hex, ≤ 4 uses each): map to the nearest semantic token by hue/lightness; anything category-specific goes to §3.4; painters and illustrations go to §3.5.
Also replace `Colors.black.withValues(alpha: 0.01–0.05)` shadows (≈40 uses) with `AppShadows` (§4.3), and `Colors.grey/.orange/.red/.green` (≈9 uses) with tokens. `Colors.white` (261) → `AppColors.surface` for backgrounds, `AppColors.textOnPrimary` for text on filled buttons.

### 3.4 Category palette (tags, saved-card icons)

Replace `scheme_card.dart:168-222` (≈14 pairs + `hashCode % 4`) with **semantic tag styles**, all ≥ 4.5:1:

| Style | Text | Background | Used for |
|---|---|---|---|
| `tagNeutral` (default) | `textSecondary` `475569` | `surfaceMuted` `F1F5F9` | sector, scheme type, everything else |
| `tagLevel` | `primaryStrong` `1D4ED8` | `primarySoft` `EFF6FF` | Central / National |
| `tagLevelState` | `0F766E` | `CCFBF1` (4.86) | State / UT |
| `tagBenefit` | `success` `15803D` | `successSoft` `DCFCE7` (4.57) | loan, subsidy, grant |
| `tagWarn` | `warningOnSoft` `92400E` | `warningSoft` `FEF3C7` (6.37) | deadline/closing soon |

No hash-based colours. Same tag → same colour everywhere.

### 3.5 Painter / illustration colours

Allowlist (keep raw hex, tagged `// color-ok`): `state_map_painter.dart`, `voice_edge_painter.dart`, `login_screen.dart` `_GoogleIconPainter` (brand colours), `regular_voice_backdrop.dart`, `companion_voice_header.dart` gradients, `saarthi_character_header.dart`, `splash_screen.dart`, `anti_gravity_hero_section.dart`, `categories_data.dart` (category illustration accents). Move the voice/companion brand colours (`6D5DFB`, `0D53FC`, `4ADE80`, …) into `AppColors.voice*` constants in the same file as a clearly separated block.

---

## 4. Radius, size, elevation tokens

### 4.1 Radius (18 values → 6 tokens)

```dart
abstract final class AppRadius {
  static const xs = 4.0;    // progress bars, micro badges, skeleton lines
  static const sm = 8.0;    // tags, small buttons, popup menus
  static const md = 12.0;   // buttons, inputs, snackbars, small cards
  static const lg = 16.0;   // cards, dialogs, banners
  static const xl = 24.0;   // bottom-sheet top corners, date-picker, hero cards
  static const pill = 999.0;// search fields, chips, avatars, toggles
  static BorderRadius get xsAll => BorderRadius.circular(xs); // …etc for each
}
```

| Today | Count | → Token |
|---|---|---|
| 1.5, 2, 3, 4, 5 | 41 | `xs` |
| 6, 8, 9, 10 | 54 | `sm` |
| 11, 12, 13, 14, 15 | 137 | `md` (14→`md` unless it is a pill chip, then `pill`) |
| 16, 18 | 98 | `lg` |
| 20 | 24 | `lg` on cards/dialogs · `pill` on chips/pills |
| 22, 24 | 15 | `xl` |
| 28, 30 | 6 | `pill` |

### 4.2 Sizes and borders

```dart
abstract final class AppSize {
  static const tapTarget = 48.0;     // min hit area, everywhere
  static const controlHeight = 48.0; // buttons, text fields (visual); grows with text scale
  static const iconSm = 16.0;        // inline-with-text only
  static const icon = 20.0;          // default in chips/fields
  static const iconLg = 24.0;        // toolbar, nav
  static const avatarSm = 40.0, avatar = 56.0, avatarLg = 72.0;
  static const borderWidth = 1.0;    // replaces 1.0/1.2/1.5
  static const borderWidthSelected = 1.5; // selected chip/card; (2.0 only for focus ring)
}
```

### 4.3 Elevation

```dart
abstract final class AppShadows {
  static const none = <BoxShadow>[];
  static const card = [BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4))];
  static const raised = [BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, 6))]; // dialogs, popovers
  static const topBar = [BoxShadow(color: Color(0x0D0F172A), blurRadius: 16, offset: Offset(0, -4))]; // bottom action bars
}
```
Replaces ≈40 ad-hoc `Colors.black.withValues(alpha: .01–.05)` shadows.

---

## 5. Component themes (`ThemeData`)

Move the theme out of `main.dart` into `AppTheme.light` (keep `datePickerTheme`). All values below use the tokens above.

```dart
static ThemeData get light {
  final t = AppTextStyles.en; // base; locale-specific heights are applied via context.text at use sites
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary, onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.primaryStrong, surface: AppColors.surface,
    onSurface: AppColors.textPrimary, error: AppColors.danger,
    outline: AppColors.border, outlineVariant: AppColors.borderStrong,
    surfaceContainerHighest: AppColors.surfaceMuted);
  final rMd = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
  const minBtn = Size(64, AppSize.controlHeight);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppFonts.body,
    textTheme: /* §1.2 mapping */,
    materialTapTargetSize: MaterialTapTargetSize.padded, // keep 48dp hit areas
    visualDensity: VisualDensity.standard,

    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, foregroundColor: AppColors.textOnPrimary,
      disabledBackgroundColor: AppColors.disabledBg, disabledForegroundColor: AppColors.disabledFg,
      elevation: 0, minimumSize: minBtn, shape: rMd, textStyle: t.button,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md))),
    filledButtonTheme: /* same as elevated */,
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary, minimumSize: minBtn, shape: rMd, textStyle: t.button,
      side: const BorderSide(color: AppColors.primary, width: AppSize.borderWidthSelected),
      disabledForegroundColor: AppColors.disabledFg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
      foregroundColor: AppColors.primary, minimumSize: const Size(64, AppSize.tapTarget), textStyle: t.button,
      shape: rMd)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
      minimumSize: const Size.square(AppSize.tapTarget), foregroundColor: AppColors.textPrimary)),

    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      hintStyle: t.bodyLarge.copyWith(color: AppColors.textMuted),
      labelStyle: t.body.copyWith(color: AppColors.textSecondary),
      errorStyle: t.bodySmall.copyWith(color: AppColors.danger),
      border: _outline(AppColors.border), enabledBorder: _outline(AppColors.border),
      focusedBorder: _outline(AppColors.primary, 2),
      errorBorder: _outline(AppColors.danger), focusedErrorBorder: _outline(AppColors.danger, 2)),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface, selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
      shape: const StadiumBorder(), labelStyle: t.label.copyWith(color: AppColors.textBody),
      secondaryLabelStyle: t.label.copyWith(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      showCheckmark: true, checkmarkColor: AppColors.primary,
      materialTapTargetSize: MaterialTapTargetSize.padded),

    appBarTheme: AppBarTheme(backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary,
      elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: t.titleMedium.copyWith(color: AppColors.textPrimary)),
    cardTheme: CardThemeData(color: AppColors.surface, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll, side: const BorderSide(color: AppColors.border))),
    dialogTheme: DialogThemeData(backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      titleTextStyle: t.titleLarge.copyWith(color: AppColors.textPrimary), contentTextStyle: t.body.copyWith(color: AppColors.textBody)),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.surface, showDragHandle: true,
      dragHandleColor: AppColors.borderStrong, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: AppColors.textPrimary,
      contentTextStyle: t.body.copyWith(color: AppColors.textOnPrimary), shape: rMd),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    navigationBarTheme: /* see §5.2 */,
    datePickerTheme: AppTheme.datePickerTheme,
  );
}
```

`_outline(color, [width = 1])` = `OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: color, width: width))`.

### 5.1 Buttons: rules

- Primary = `ElevatedButton`/`FilledButton` (solid `primary`, radius `md`, ≥ 48dp tall). Secondary = `OutlinedButton`. Tertiary/inline = `TextButton`. Destructive = `ElevatedButton.styleFrom(backgroundColor: AppColors.danger)` with `// style-ok: destructive`.
- Full-width CTAs use `buttonLarge` via the `textStyle` on the call site, height 52 → just `minimumSize: Size.fromHeight(52)`.
- Button height grows with text scale (min only, never fixed `height:`). Remove the `SizedBox(height: 52/54)` wrappers (`login_screen.dart:243`, `scheme_bottom_action_bar.dart:56,101`) and use `minimumSize`.
- Loading state: show a 18dp `CircularProgressIndicator(strokeWidth: 2, color: foreground)` **inside** the button next to the label; keep the label and the button enabled-looking; ignore taps.
- Icons in buttons: 16–20dp, `color` inherited from `foregroundColor` (don't hardcode).
- Labels wrap (`maxLines: 2`, `textAlign: center`); no `FitOneLine` (§1.3.4).

### 5.2 Chips and tabs

- Filter/choice chips: use `ChoiceChip` / `FilterChip` (themed above) so the hit area is 48dp automatically, with `showCheckmark: true` so selected isn't colour-only. For chips with a trailing count (filter sheet), build `AppChip` on `AppTappable` with the same visuals: visual height ≥ 36, hit area 48.
- Segmented tabs (Saved, notification categories): `SegmentedButton` or `AppTappable` with `selected` semantics (§7). Track `surfaceMuted`, selected thumb `surface` + `AppShadows.card`, selected text `primary` + w700, unselected `textSecondary`.
- Bottom nav: Material 3 `NavigationBar` (themed: `backgroundColor: surface`, `indicatorColor: primarySoft`, selected icon `primary`, unselected `iconMuted`/label `textSecondary`, label style `label` 12sp, `labelBehavior: alwaysShow`, `height: 64` (min; it grows)). If the programmer prefers to keep the custom row: wrap each item in `AppTappable(selected:, semanticLabel:)` and add the pill indicator.

### 5.3 Labels that don't fit at 12sp in Tamil

Shorten these ARB strings rather than shrinking the font: bottom-nav (`navHome/navSearch/navDiscover/navSaved/navProfile`), Saved tabs, filter-strip chips. The runtime pass (audit, "Runtime verification") records which ones actually overflow.

### 5.4 `CustomButton` and `AppCardStyle` — decisions

- **`CustomButton`: delete** (`widgets/common/custom_button.dart`). It is unused (0 call sites), uses a gradient and a 52dp fixed height that match no real button in the app, and `FitOneLine` which breaks the Tamil rules. The themed buttons replace it.
- **`AppCardStyle`: revive as `AppCard`** and delete the old static class. It is also unused, but a shared card is needed because cards drift (radius 16/18, border `E2E8F0`/`E5E7EB`/`F1F5F9`, shadow alphas .015–.05).

```dart
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin, this.color = AppColors.surface, this.selected = false, this.semanticLabel});
  // Container: color, border: Border.all(color: selected ? primary : AppColors.border, width: selected ? 1.5 : 1),
  // borderRadius: AppRadius.lgAll, boxShadow: AppShadows.card.
  // If onTap != null: Material(transparent)+InkWell(borderRadius: lg) so the ripple is clipped; Semantics(button: true, label: semanticLabel).
}
```

Apply to: `SchemeCard` (radius 18→16), Saved card, Home recommended/updates/journey cards, notification cards, profile cards. Do not change their inner layout.

---

## 6. `AppIconButton` and `AppTappable`

### 6.1 `AppIconButton` — icon-only actions (bell, bookmark, mic, clear, share, back)

```dart
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,   // REQUIRED, localised (l10n). Also used as tooltip.
    required this.onPressed,       // null => disabled
    this.size = AppSize.iconLg,    // glyph size: 20 | 24
    this.color,                    // default AppColors.textPrimary (iconMuted when disabled)
    this.selected,                 // null = not a toggle; true/false adds Semantics(toggled) and swaps to selectedIcon
    this.selectedIcon,
    this.tooltip,                  // defaults to semanticLabel; pass '' to suppress
    this.badgeCount,               // int? > 0 shows a numeric badge ("9+" above 9)
    this.showDot = false,          // unread dot when no count is available
    this.badgeSemantics,           // e.g. l10n.notificationsUnread(n); appended to the label
    this.backgroundColor,          // optional circular bg (e.g. white + border on Home bell)
    this.backgroundSize = 40,      // visual circle; hit area stays 48
  });
}
```

Behaviour (all mandatory):

1. Hit area is a `ConstrainedBox(minWidth: 48, minHeight: 48)` regardless of glyph/background size; the visual circle (e.g. the Home bell's 40dp) is centred inside it.
2. `Material(type: transparency)` + `InkResponse(radius: 24, onTap)` for ripple/focus/hover; focus highlight visible.
3. `Semantics(button: true, enabled: onPressed != null, label: semanticLabel + badgeSemantics, toggled/selected when selected != null)` wrapping, and the inner `Icon` is `excludeFromSemantics`. `Tooltip(message: tooltip ?? semanticLabel, excludeFromSemantics: true)` so TalkBack doesn't read it twice.
4. Badge: `Badge` (Material 3) positioned top-right of the glyph; `backgroundColor: AppColors.danger`, label 12sp, min height 16dp; `showDot` → 8dp dot with a 1.5dp `surface` ring so it's visible on any background. Counts above 9 show `9+`.
5. Respects `Directionality`; no fixed height on the badge text.
6. Disabled: `iconMuted` colour, no ripple, still announces `enabled: false`.

Replace the following (audit A1): `scheme_card.dart:383,403`, `home_header_section.dart:94`, `home_recommended_section.dart:247`, `search_input_section.dart:92,106,118` (mic/clear/search; keep the input's `suffixIcon`/`prefixIcon` slots, put `AppIconButton` inside them), `saved_schemes_screen.dart:214-247`, `StandardPageHeader` back button, notification-card actions.

### 6.2 `AppTappable` — chips, tabs, rows, pills (anything with text/shape)

```dart
class AppTappable extends StatelessWidget {
  const AppTappable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,          // null => derive from child text
    this.selected,               // adds Semantics(selected: …)
    this.isButton = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.md)),
    this.minSize = const Size(AppSize.tapTarget, AppSize.tapTarget),
    this.alignment = Alignment.center,
  });
}
```

Behaviour: `Semantics(button: isButton, selected: selected, label: semanticLabel, container: true)` → `ConstrainedBox(BoxConstraints(minWidth: minSize.width, minHeight: minSize.height))` → `Material(transparent)` → `InkWell(onTap, borderRadius, child: Align(alignment, child: child))`. The *visual* decoration (pill background/border) stays on the child; `AppTappable` only supplies the 48dp hit area, ripple and semantics. Example: Home quick pill — keep the 38dp-tall decorated pill, wrap it so the touch area is 48dp.

### 6.3 Guard

No `GestureDetector(onTap:` in `lib/screens` or `lib/widgets` unless the line carries `// tap-ok: <reason>` (e.g. a tap-to-dismiss background). See §8.

---

## 7. Accessibility rules (apply while sweeping)

1. Every interactive element: ≥ 48×48dp hit area, a label (`semanticLabel` or visible text), and a role (`button`, `selected`, `toggled`, `textField`).
2. State never by colour alone: selected chip/tab/nav gets a check, indicator pill or weight change **plus** `Semantics(selected:)`. Unread = dot + count or "unread" in the semantic label.
3. Form fields: use `InputDecoration(labelText:)` or wrap `Semantics(label:, textField: true)`; picker (read-only) fields use `Semantics(button: true, label: '<label>, <value>')`; errors are `liveRegion: true`.
4. Decorative images/icons: `excludeFromSemantics: true`; informative ones carry a label.
5. Don't put `maxLines: 1` + ellipsis on anything the user needs to read in full (scheme names, filter options, button labels).

---

## 8. Guard tests

Add `test/guards/` following `spacing_scale_test.dart` (same `_dartFiles` + regex + `// xxx-ok` escape pattern). Because there are ~1,600 existing violations, use a **ratchet** so Phase 2 can land incrementally: each rule keeps a baseline `test/guards/baseline/<rule>.json` of `{ "path": count }`; the test fails if any file's count **increases** or a file not in the baseline has any; lowering counts is fine and `dart run tool/update_guard_baseline.dart` rewrites the baseline. When a rule reaches zero everywhere, delete its baseline and make it strict.

| Test | Forbids (regex on `lib/**/*.dart`) | Escape | Allowed files |
|---|---|---|---|
| `type_scale_test.dart` | `fontSize:\s*\d` (numeric literal) · `GoogleFonts\.` · `isTa(mil)?\s*\?\s*[\d.]+\s*:\s*[\d.]+` (language-dependent size) · `textScaleFactor` / `TextScaler.linear` outside `main.dart` | `// type-ok` | `utils/app_text.dart`, `utils/app_theme.dart`, painters |
| `type_scale_floor_test.dart` | assert every `AppTextStyles` getter has `fontSize >= 12` and every `height >= 1.25` (en) / `>= 1.35` (ta) | – | – |
| `color_tokens_test.dart` | `Color\(0x[0-9A-Fa-f]{6,8}\)` · `Colors\.(grey\|red\|green\|orange\|blue\|black\|white)` except `Colors.transparent` | `// color-ok` | `utils/app_colors.dart`, §3.5 painter allowlist |
| `contrast_test.dart` | compute WCAG ratio for each `AppColors.contrastPairs` entry; fail below the stated minimum | – | – |
| `radius_tokens_test.dart` | `BorderRadius\.circular\(\s*\d` · `Radius\.circular\(\s*\d` | `// radius-ok` | `utils/app_radius.dart`, painters |
| `tap_target_test.dart` | `GestureDetector\(\s*(?:behavior:[^,]+,\s*)?onTap:` in `lib/screens`, `lib/widgets` · `IconButton\(` whose args contain `BoxConstraints()` or `padding: EdgeInsets.zero` without `AppSize.tapTarget` | `// tap-ok: <reason>` | `widgets/common/app_icon_button.dart`, `app_tappable.dart` |
| `button_style_test.dart` | `(Elevated\|Outlined\|Text\|Filled)Button\.styleFrom\(` containing `backgroundColor:` / `shape:` / `minimumSize:` / `padding:` | `// style-ok: <reason>` | `utils/app_theme.dart` |
| `fixed_height_text_test.dart` | `(SizedBox\|Container)\(\s*height:\s*\d+` whose child subtree contains `Text(` within 6 lines | `// height-ok` | – |
| `i18n_literals_test.dart` | Tamil code points `[஀-௿]` in `lib/screens`, `lib/widgets` · `Text\(\s*['"][A-Z]` (English literal) · `AppToast\.show\w+\(\s*context,\s*['"]` | `// i18n-ok` | language names in the language pickers (`'தமிழ்'`) |
| `fit_one_line_test.dart` | `FitOneLine\(` / `FittedBox\(` wrapping a `Text` | `// type-ok: numeric` | – |
| `semantics_test.dart` (widget test) | pump each tab-bar/nav item and assert `tester.getSemantics(...)` has the selected flag; `AppIconButton` without `semanticLabel` fails to compile (`required`) | – | – |

Also keep: `spacing_scale_test.dart` (extend it to cover `EdgeInsets.only(left: 16, …)` literals still found in `scheme_bottom_action_bar.dart:33-36`).

Runtime checks to add as widget/golden tests (cheap, catch overflow regressions): render Home, Search idle, Search results, Saved, Filter sheet, Login at `textScaler` 1.0/1.3/1.6 × locale en/ta × width 320/390/800 and assert `tester.takeException() == null`.

---

## 9. Suggested Phase-2 order

1. Fonts bundled + `AppTextStyles` + `AppColors` + `AppRadius/Size/Shadows` + `AppTheme.light` (no screen changes yet; deprecated forwards in `AppConstants`). Add guard tests with baselines.
2. `AppIconButton`, `AppTappable`, `AppCard`; delete `CustomButton`.
3. §2 text-scale change **together with** the §1.4 size sweep on the 10 most visible screens (Login, Language, Home, Search, SchemeCard, Saved, Filter sheet, Nav, Notifications, Scheme details bottom bar).
4. Remaining screens (Discover/Categories sheets, Profile, wizard, Settings, Help, Companion) with the guard baselines ratcheting down.
5. Remove deprecated `AppConstants` colour aliases; turn ratchet rules into strict rules.
