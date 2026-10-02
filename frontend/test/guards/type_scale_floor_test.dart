// spec_design_system.md §8, type_scale_floor_test.dart. Asserts every
// AppTextStyles getter has fontSize >= 12 and height >= 1.25 (en) / >= 1.35
// (ta). Not ratcheted -- this is the floor the whole type scale exists to
// guarantee; it must hold for every role, forever.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/utils/app_text.dart';

void main() {
  final roles = <String, TextStyle Function(AppTextStyles)>{
    'display': (t) => t.display,
    'headline': (t) => t.headline,
    'titleLarge': (t) => t.titleLarge,
    'titleMedium': (t) => t.titleMedium,
    'titleSmall': (t) => t.titleSmall,
    'cardTitle': (t) => t.cardTitle,
    'bodyLarge': (t) => t.bodyLarge,
    'body': (t) => t.body,
    'bodySmall': (t) => t.bodySmall,
    'label': (t) => t.label,
    'button': (t) => t.button,
    'buttonLarge': (t) => t.buttonLarge,
  };

  test('every AppTextStyles.en role is >= 12sp with height >= 1.25', () {
    for (final entry in roles.entries) {
      final style = entry.value(AppTextStyles.en);
      expect(
        style.fontSize! >= 12,
        isTrue,
        reason: '${entry.key} (en): fontSize ${style.fontSize} < 12',
      );
      expect(
        style.height! >= 1.25,
        isTrue,
        reason: '${entry.key} (en): height ${style.height} < 1.25',
      );
    }
  });

  test('every AppTextStyles.ta role is >= 12sp with height >= 1.35', () {
    for (final entry in roles.entries) {
      final style = entry.value(AppTextStyles.ta);
      expect(
        style.fontSize! >= 12,
        isTrue,
        reason: '${entry.key} (ta): fontSize ${style.fontSize} < 12',
      );
      expect(
        style.height! >= 1.35,
        isTrue,
        reason: '${entry.key} (ta): height ${style.height} < 1.35',
      );
    }
  });
}
