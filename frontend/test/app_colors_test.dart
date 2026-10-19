import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/utils/app_colors.dart';

void main() {
  test(
    'AppTagStyle records expose a `text` field (renamed from textSecondary)',
    () {
      expect(AppTagStyle.neutral.text, const Color(0xFF475569));
      expect(AppTagStyle.neutral.background, const Color(0xFFF1F5F9));
    },
  );

  test(
    'styleForTag is deterministic -- same tag always gets the same style',
    () {
      expect(styleForTag('Central Government'), AppTagStyle.level);
      expect(styleForTag('Loan'), AppTagStyle.benefit);
      expect(styleForTag('Unrecognized Tag'), AppTagStyle.neutral);
      // Calling twice with the same input must not hash-wander.
      expect(styleForTag('MSME Credit'), styleForTag('MSME Credit'));
    },
  );
}
