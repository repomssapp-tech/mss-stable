import 'package:flutter/material.dart';
import 'app_spacing.dart';

/// AppCardStyle
/// ────────────
/// Standardized card styling parameters, paddings, borders, shadows, and margins
/// to maintain 100% visual consistency across all screens and cards in the app.
class AppCardStyle {
  AppCardStyle._();

  static const double borderRadiusValue = 16.0;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(borderRadiusValue),
  );

  static const Color borderColor = Color(0xFFF1F5F9);
  static const BorderSide borderSide = BorderSide(
    color: borderColor,
    width: 1.2,
  );

  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    vertical: AppSpacing.tight,
    horizontal: AppSpacing.lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets cardInnerPadding = EdgeInsets.all(AppSpacing.lg);

  static const double chipSpacing = 6.0;
  static const double chipRunSpacing = 6.0;

  static BoxDecoration defaultCardDecoration({
    Color backgroundColor = Colors.white,
    Color borderColor = borderColor,
    double borderRadius = borderRadiusValue,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
