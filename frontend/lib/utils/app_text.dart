import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  const AppTextStyles._(this._tamilBump, {double sizeFactor = 1})
    : _sizeFactor = sizeFactor;
  final double _tamilBump;
  final double _sizeFactor;

  double _size(double size) => (size * _sizeFactor).clamp(12.0, size);

  static const en = AppTextStyles._(0);
  static const ta = AppTextStyles._(0.10, sizeFactor: 0.92);
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
    fontSize: _size(size),
    fontWeight: w,
    height: h + _tamilBump,
  );
  TextStyle _b(double size, double h, FontWeight w) => TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.fallback,
    fontSize: _size(size),
    fontWeight: w,
    fontVariations: [FontVariation('wght', w.value.toDouble())],
    height: h + _tamilBump,
  );

  TextStyle get display => _h(28, 1.25, FontWeight.w600);
  TextStyle get headline => _h(24, 1.30, FontWeight.w600);
  TextStyle get titleLarge => _h(20, 1.30, FontWeight.w600);
  TextStyle get titleMedium => _h(18, 1.30, FontWeight.w600);
  TextStyle get titleSmall => _h(16, 1.35, FontWeight.w600);
  TextStyle get cardTitle => _h(14, 1.35, FontWeight.w600);
  TextStyle get bodyLarge => _b(16, 1.50, FontWeight.w400);
  TextStyle get body => _b(14, 1.50, FontWeight.w400);
  TextStyle get bodySmall => _b(12, 1.45, FontWeight.w400);
  TextStyle get label => _b(12, 1.40, FontWeight.w600);
  TextStyle get button => _b(14, 1.30, FontWeight.w600);
  TextStyle get buttonLarge => _b(16, 1.30, FontWeight.w600);
}

/// Usage: `Text(l10n.savedTitle, style: context.text.headline.copyWith(color: AppColors.textPrimary))`.
/// Not yet adopted at call sites (Phase 3 codemod, spec §1.5) -- this phase
/// only adds the infrastructure and wires it into `AppTheme.light`'s
/// `textTheme` so Material widgets that fall back to theme defaults agree.
extension AppTextContext on BuildContext {
  AppTextStyles get text =>
      AppTextStyles.forLocale(Localizations.localeOf(this));

  /// The decoration for a link inside running text. An underline cuts through
  /// the below-the-line marks of Devanagari and Tamil (nukta, u/ū signs,
  /// conjuncts), which reads as broken text, so Hindi and Tamil links are
  /// shown by colour and weight alone.
  TextDecoration get linkDecoration =>
      Localizations.localeOf(this).languageCode == 'en'
      ? TextDecoration.underline
      : TextDecoration.none;
}

/// `GoogleFonts.poppins/inter` with the bundled Tamil and Devanagari fonts as
/// fallback. A plain GoogleFonts style names no fallback, so Tamil and Hindi
/// letters in it come from the phone's default font in regular weight while
/// Latin letters in the same line turn bold ("MSME" bold, the Tamil words
/// not). With the fallback, a bold title is bold from the first letter to the
/// last in every language.
abstract final class AppGoogleFonts {
  static TextStyle poppins({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => GoogleFonts.poppins(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
  ).copyWith(fontFamilyFallback: AppFonts.fallback);

  static TextStyle inter({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => GoogleFonts.inter(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
  ).copyWith(fontFamilyFallback: AppFonts.fallback);
}
