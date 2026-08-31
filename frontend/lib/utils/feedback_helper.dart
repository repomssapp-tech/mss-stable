import 'package:flutter/services.dart';

/// Centralized utility for consistent, lightweight tactile haptic feedback.
class AppFeedback {
  AppFeedback._();

  /// Subtle click for tab switches, filter selections, and chip taps.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light impact for button presses and card expansions.
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for success actions (e.g. saving bookmarks).
  static void medium() {
    HapticFeedback.mediumImpact();
  }
}
