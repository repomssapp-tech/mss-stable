import 'package:flutter/material.dart';

/// Font family constants (spec_design_system.md §1.2). Inter/Poppins are
/// bundled local assets (2.2); Noto Sans Tamil is the fallback for Tamil
/// glyphs neither of those has.
abstract final class AppFonts {
  static const heading = 'Poppins';
  static const body = 'Inter';
  static const tamil = 'NotoSansTamil';
  static const devanagari = 'NotoSansDevanagari';
  static const fallback = <String>[tamil, devanagari];
}

/// The type scale (spec §1.1). Floor is 12sp; nothing in the app may render
/// below it. Tamil line-heights are the English value +0.10 (§1.3.2).
/// Colour is never baked in -- callers `.copyWith(color: AppColors.x)`.
@immutable
class AppTextStyles {
  const AppTextStyles._(this._tamilBump);
  final double _tamilBump;

  static const en = AppTextStyles._(0);
  static const ta = AppTextStyles._(0.10);
  // Devanagari carries headline strokes and above/below-base matras, so it
  // needs the same extra leading as Tamil to avoid clipped or cramped lines.
  static const hi = AppTextStyles._(0.10);

  static AppTextStyles forLocale(Locale l) => switch (l.languageCode) {
    'ta' => ta,
    'hi' => hi,
    _ => en,
  };

  // D4 (Phase 2 design review): Poppins is bundled as static per-weight
  // files (SemiBold/Bold), so FontWeight alone picks the right file --
  // _h needs no fontVariations. Inter and Noto Sans Tamil, the two fonts
  // _b resolves to (body text, with Tamil falling back to Noto Sans
  // Tamil), are both bundled as single *variable* font files registered
  // under several `weight:` entries in pubspec.yaml. Whether a Flutter
  // engine applies the `wght` axis from FontWeight alone for a font
  // registered that way wasn't something the designer could confirm by
  // reading the code, so fontVariations is set explicitly here -- correct
  // either way, and removes the ambiguity regardless of engine behaviour.
  TextStyle _h(double size, double h, FontWeight w) => TextStyle(
    fontFamily: AppFonts.heading,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: size,
    fontWeight: w,
    height: h + _tamilBump,
  );
  TextStyle _b(double size, double h, FontWeight w) => TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: size,
    fontWeight: w,
    fontVariations: [FontVariation('wght', w.value.toDouble())],
    height: h + _tamilBump,
  );

  TextStyle get display => _h(28, 1.25, FontWeight.w700);
  TextStyle get headline => _h(24, 1.30, FontWeight.w700);
  TextStyle get titleLarge => _h(20, 1.30, FontWeight.w700);
  TextStyle get titleMedium => _h(18, 1.30, FontWeight.w700);
  TextStyle get titleSmall => _h(16, 1.35, FontWeight.w700);
  TextStyle get cardTitle => _h(14, 1.35, FontWeight.w700);
  TextStyle get bodyLarge => _b(16, 1.50, FontWeight.w400);
  TextStyle get body => _b(14, 1.50, FontWeight.w400);
  TextStyle get bodySmall => _b(12, 1.45, FontWeight.w400);
  TextStyle get label => _b(12, 1.40, FontWeight.w600);
  TextStyle get button => _b(14, 1.30, FontWeight.w600);
  TextStyle get buttonLarge => _b(16, 1.30, FontWeight.w700);
}

/// Usage: `Text(l10n.savedTitle, style: context.text.headline.copyWith(color: AppColors.textPrimary))`.
/// Not yet adopted at call sites (Phase 3 codemod, spec §1.5) -- this phase
/// only adds the infrastructure and wires it into `AppTheme.light`'s
/// `textTheme` so Material widgets that fall back to theme defaults agree.
extension AppTextContext on BuildContext {
  AppTextStyles get text =>
      AppTextStyles.forLocale(Localizations.localeOf(this));
}
