import 'package:flutter/material.dart';

/// Semantic colour tokens (spec_design_system.md §3). One palette: the
/// existing Slate + Blue family already used for ~90% of the app's hex
/// literals. Text tokens all pass >= 4.5:1 on the surfaces listed beside
/// them; icon-only tokens pass >= 3:1. See [contrastPairs] and
/// `test/guards/contrast_test.dart`.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFF8FAFC); // scaffold
  static const surface = Color(0xFFFFFFFF); // cards, sheets, inputs
  static const surfaceMuted = Color(0xFFF1F5F9); // tab-bar track, chip bg, skeleton
  static const border = Color(0xFFE2E8F0); // all hairlines/card borders
  static const borderStrong = Color(0xFFCBD5E1); // dividers on tinted surfaces, drag handle, outline buttons (inactive)

  // Text
  static const textPrimary = Color(0xFF0F172A); // 17.9:1 on surface
  static const textBody = Color(0xFF334155); // 10.4:1 on surface
  static const textSecondary = Color(0xFF475569); // 7.6 surface . 6.9 surfaceMuted . 6.2 on E2E8F0
  static const textMuted = Color(0xFF5B6B82); // 5.4 surface . 5.2 background . 4.95 surfaceMuted . 5.0 primarySoft
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Icons / non-text (>= 3:1 on surface, background, surfaceMuted)
  static const iconMuted = Color(0xFF73839A); // 3.9 / 3.7 / 3.5

  // Disabled (exempt from contrast, but stay legible)
  static const disabledBg = Color(0xFFE2E8F0);
  static const disabledFg = Color(0xFF8091A7);

  // Brand / interactive
  static const primary = Color(0xFF2563EB); // 5.2 on white; white on it 5.2
  static const primaryStrong = Color(0xFF1D4ED8); // text on primarySoft: 6.2
  static const primaryDeep = Color(0xFF1E3A8A); // headings in info banners: 9.5 on primarySoft
  static const primarySoft = Color(0xFFEFF6FF); // selected chip bg, info banner bg
  static const languageHindiBg = Color(0xFFFFF7ED); // Hindi card avatar bg (Amber 50)
  static const languageHindiFg = Color(0xFFC2410C); // Hindi card avatar text (Orange 700)
  static const primaryTint = Color(0xFFDBEAFE); // icon-badge bg, selected border
  static const primaryBorder = Color(0xFFBFDBFE); // border on primarySoft
  static const primaryLight = Color(0xFF60A5FA); // decor only (gradients, illustrations)

  // Status
  static const success = Color(0xFF15803D); // 5.0 on white; white on it 5.0
  static const successSoft = Color(0xFFDCFCE7); // text 15803D on it 4.6
  static const warning = Color(0xFFD97706); // FILL / ICON ONLY (3.2:1 on white)
  static const warningText = Color(0xFFB45309); // text on white 5.0
  static const warningSoft = Color(0xFFFEF3C7); // text warningOnSoft on it 6.4
  static const warningOnSoft = Color(0xFF92400E);
  static const danger = Color(0xFFDC2626); // 4.8 on white; white on it 4.8
  static const dangerStrong = Color(0xFFB91C1C); // text on dangerSoft: 5.3-5.9
  static const dangerSoft = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFCA5A5);

  // Saffron accent from the old palette: decorative only (2.1:1 with white
  // text -> never a text or button fill)
  static const accent = Color(0xFFFF9933);

  /// Gradient helper, moved from `AppConstants.blueGradient`.
  static const scaffoldGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// (foreground, background, minRatio) pairs asserted by
  /// test/guards/contrast_test.dart.
  static const contrastPairs = <(Color, Color, double)>[
    (textPrimary, surface, 4.5),
    (textBody, surface, 4.5),
    (textSecondary, surface, 4.5),
    (textSecondary, surfaceMuted, 4.5),
    (textMuted, surface, 4.5),
    (textMuted, background, 4.5),
    (textMuted, surfaceMuted, 4.5),
    (textMuted, primarySoft, 4.5),
    (textOnPrimary, primary, 4.5),
    (textOnPrimary, danger, 4.5),
    (textOnPrimary, success, 4.5),
    (primary, surface, 4.5),
    (primary, primarySoft, 4.5),
    (primaryStrong, primaryTint, 4.5),
    (primaryDeep, primarySoft, 4.5),
    (success, successSoft, 4.5),
    (warningText, surface, 4.5),
    (warningOnSoft, warningSoft, 4.5),
    (danger, surface, 4.5),
    (dangerStrong, dangerSoft, 4.5),
    (iconMuted, surface, 3.0),
    (iconMuted, background, 3.0),
    (iconMuted, surfaceMuted, 3.0),
  ];
}

/// Semantic tag/category colour pairs (spec §3.4). No hash-based colours --
/// same tag meaning gets the same colour everywhere.
abstract final class AppTagStyle {
  static const neutral = (text: Color(0xFF475569), background: Color(0xFFF1F5F9));
  static const level = (text: Color(0xFF1D4ED8), background: Color(0xFFEFF6FF));
  static const levelState = (text: Color(0xFF0F766E), background: Color(0xFFCCFBF1));
  static const benefit = (text: Color(0xFF15803D), background: Color(0xFFDCFCE7));
  static const warn = (text: Color(0xFF92400E), background: Color(0xFFFEF3C7));
}

/// Deterministic tag -> style mapping (spec_phase3.md Phase-2-corrections
/// note, group 11). No hash-based colours: the same tag meaning always gets
/// the same colour, unlike the old `_getTagColors` in `scheme_card.dart`.
///
/// Return type is the same record shape as [AppTagStyle]'s members (Dart
/// records are structurally typed, so this is interchangeable with them)
/// rather than `AppTagStyle` itself, since that identifier names the
/// abstract holder class, not an instantiable type.
({Color text, Color background}) styleForTag(String tag) {
  final t = tag.toLowerCase().trim();
  if (t.contains('central') ||
      t.contains('national') ||
      t.contains('india') ||
      t.contains('state') ||
      t.contains('tamil') ||
      t.contains('tn')) {
    return AppTagStyle.level;
  }
  if (t.contains('loan') ||
      t.contains('credit') ||
      t.contains('subsidy') ||
      t.contains('grant')) {
    return AppTagStyle.benefit;
  }
  if (t.contains('deadline') || t.contains('closing') || t.contains('urgent')) {
    return AppTagStyle.warn;
  }
  if (t.contains('active') || t.contains('open') || t.contains('live')) {
    return AppTagStyle.levelState;
  }
  return AppTagStyle.neutral;
}
