// The v2 illustrated design (onboarding and the new Saarthi screens), ported
// from the designer's Flutter project. These screens are hand-laid-out on a
// 360pt-wide canvas and scale with the screen width, so the spacing/colour
// guards exempt `lib/design_v2/` the same way they exempt the splash and the
// painters. Every user-facing string still comes from the ARB files.
import 'package:flutter/material.dart';

import '../utils/app_text.dart';

/// Tricolour palette of the v2 design.
abstract final class MssColors {
  static const saffron = Color(0xFFFF9933);
  static const saffronDeep = Color(0xFFE86F00);
  static const saffronText = Color(0xFFC25A00);
  static const saffronLight = Color(0xFFFFE3C2);
  static const green = Color(0xFF138808);
  static const greenDeep = Color(0xFF0E6B06);
  static const greenLight = Color(0xFFDDF0D6);
  static const ashokaBlue = Color(0xFF000080);
  static const cream = Color(0xFFFFF8EF);
  static const eligibleAmber = Color(0xFFB85F00);
  static const ink = Color(0xFF0B0B4A);
  static const body = Color(0xFF3B3B6B);
  static const muted = Color(0xFF6B6B8F);
  static const line = Color(0x14000080);
}

abstract final class MssAssets {
  static const _p = 'assets/images/onboarding';
  static const logo = 'assets/images/Logo/Logo icon.webp';
  static const bgOrange = '$_p/bg_orange.webp';
  static const bgGreen = '$_p/bg_green.webp';
  static const bgWhite = '$_p/bg_white.webp';
  static const bgTricolor = '$_p/bg_tricolor.webp';
  static const charStudentPhone = '$_p/char_student_phone.webp';
  static const charWomanSaree = '$_p/char_woman_saree.webp';
  static const charFarmer = '$_p/char_farmer.webp';
  static const charGirlStudent = '$_p/char_girl_student.webp';
  static const charWomanPink = '$_p/char_woman_pink.webp';
  static const charSaarthiGuide = '$_p/char_saarthi_guide.webp';
  static const charStudentTablet = '$_p/char_student_tablet.webp';
  static const saarthiAvatar = '$_p/saarthi_avatar.webp';
  static const saarthiNamaste = '$_p/saarthi_namaste.webp';
  static const saarthiPresent = '$_p/saarthi_present.webp';

  static const onboarding = [
    bgOrange,
    bgGreen,
    bgWhite,
    bgTricolor,
    charStudentPhone,
    charFarmer,
    charWomanPink,
    charGirlStudent,
    charSaarthiGuide,
  ];
}

/// Layout scale: screen width / the 360pt design width.
double designScale(BuildContext context) =>
    MediaQuery.sizeOf(context).width / 360;

/// Poppins (with Tamil and Devanagari fallbacks) at [size] design points.
TextStyle pop(
  double size,
  FontWeight weight,
  Color color,
  double s, {
  double? height,
}) => TextStyle(
  fontFamily: AppFonts.heading,
  fontFamilyFallback: AppFonts.fallback,
  fontSize: size * s,
  fontWeight: weight,
  color: color,
  height: height,
);

TextStyle tamil(
  double size,
  FontWeight weight,
  Color color,
  double s, {
  double? height,
}) => TextStyle(
  fontFamily: AppFonts.tamil,
  fontSize: size * s,
  fontWeight: weight,
  color: color,
  height: height,
);

TextStyle deva(double size, FontWeight weight, Color color, double s) =>
    TextStyle(
      fontFamily: AppFonts.devanagari,
      fontSize: size * s,
      fontWeight: weight,
      color: color,
    );

/// Hand-laid-out screens follow the phone's font size only up to 1.15x;
/// beyond that their absolutely placed text would overlap. Tamil and Hindi
/// set the same words in longer runs than English, so their text is drawn
/// a little smaller ([languageFactor]) to stay inside the designed panels.
class DesignTextScale extends StatelessWidget {
  const DesignTextScale({super.key, required this.child});

  final Widget child;

  static double languageFactor(String languageCode) => switch (languageCode) {
    'ta' => 0.8,
    'hi' || 'mr' => 0.92,
    _ => 1.0,
  };

  @override
  Widget build(BuildContext context) {
    final device = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.15);
    final factor = languageFactor(Localizations.localeOf(context).languageCode);
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(device * factor)),
      child: child,
    );
  }
}
