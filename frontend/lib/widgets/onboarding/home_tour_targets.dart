import 'package:flutter/widgets.dart';

/// The real widgets the first-time home tour points at. Each key is attached to
/// exactly one widget in the app (the home search bar, the floating Saarthi
/// button, and the Discover and Profile items of the bottom bar), so the tour
/// measures the live layout instead of using fixed coordinates.
class HomeTourTargets {
  const HomeTourTargets._();

  static final GlobalKey search = GlobalKey(debugLabel: 'tour-search');
  static final GlobalKey askSaarthi = GlobalKey(debugLabel: 'tour-saarthi');
  static final GlobalKey discover = GlobalKey(debugLabel: 'tour-discover');
  static final GlobalKey profile = GlobalKey(debugLabel: 'tour-profile');

  /// Every target is on screen and laid out.
  static bool get allReady =>
      [search, askSaarthi, discover, profile].every(isLaidOut);

  static bool isLaidOut(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize;
  }
}
