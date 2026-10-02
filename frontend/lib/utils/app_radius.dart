import 'package:flutter/material.dart';

/// Corner-radius tokens (spec_design_system.md §4.1). 18 distinct radii
/// found across the app collapse to these 6 steps.
abstract final class AppRadius {
  static const xs = 4.0; // progress bars, micro badges, skeleton lines
  static const sm = 8.0; // tags, small buttons, popup menus
  static const md = 12.0; // buttons, inputs, snackbars, small cards
  static const lg = 16.0; // cards, dialogs, banners
  static const xl = 24.0; // bottom-sheet top corners, date-picker, hero cards
  static const pill = 999.0; // search fields, chips, avatars, toggles

  static const xsAll = BorderRadius.all(Radius.circular(xs));
  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xlAll = BorderRadius.all(Radius.circular(xl));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
}
