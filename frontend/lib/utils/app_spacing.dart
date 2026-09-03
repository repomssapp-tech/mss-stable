/// Canonical spacing scale for the app.
///
/// Derived from an inventory of every hardcoded `EdgeInsets` / `SizedBox` gap
/// in `lib/` (Sept 2026). The values **4, 6, 8, 12, 16, 20, 24** account for
/// the large majority of call sites; **2** is kept for hairline gaps and
/// **32** for section breaks. The off-scale one-offs that showed up in the
/// inventory (5, 7, 9, 10, 11, 13, 14, 18, 28, 36, …) are the inconsistency
/// this scale exists to remove — snap each to its nearest step.
///
/// Enforced for the Discover and Profile flows by
/// `test/spacing_scale_test.dart`.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 0
  static const double none = 0;

  /// 2 — hairline separators, icon nudges.
  static const double hairline = 2;

  /// 4
  static const double xs = 4;

  /// 6 — tight chip gaps, label→field gaps.
  static const double tight = 6;

  /// 8
  static const double sm = 8;

  /// 12
  static const double md = 12;

  /// 16 — default card / screen padding.
  static const double lg = 16;

  /// 20
  static const double xl = 20;

  /// 24
  static const double xxl = 24;

  /// 32 — section breaks.
  static const double xxxl = 32;

  /// Every allowed value. Used by the enforcement test.
  /// (Not `const`: Dart forbids `double` elements in a const set.)
  static final Set<double> scale = <double>{
    none,
    hairline,
    xs,
    tight,
    sm,
    md,
    lg,
    xl,
    xxl,
    xxxl,
  };
}
