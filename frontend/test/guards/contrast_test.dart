// spec_design_system.md §8, contrast_test.dart. Computes the WCAG relative-
// luminance contrast ratio for every (foreground, background, minRatio)
// tuple in AppColors.contrastPairs and fails if any falls below its stated
// minimum. Not ratcheted -- these are fixed token values the design system
// itself promises to keep accessible, so there's nothing to incrementally
// fix; it's pass/fail today and forever.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/utils/app_colors.dart';

double _linearize(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color c) {
  final r = _linearize(c.r);
  final g = _linearize(c.g);
  final b = _linearize(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('every AppColors.contrastPairs entry meets its stated WCAG minimum', () {
    final failures = <String>[];
    for (final (fg, bg, minRatio) in AppColors.contrastPairs) {
      final ratio = contrastRatio(fg, bg);
      if (ratio < minRatio) {
        failures.add(
          '$fg on $bg: ${ratio.toStringAsFixed(2)}:1 (needs >= $minRatio:1)',
        );
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
