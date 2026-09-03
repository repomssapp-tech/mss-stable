import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'app_spacing.dart';

/// AppTheme
/// ────────
/// Centralized styling definitions for the MSS App, ensuring 100% theme
/// consistency across dialogs, pickers, and surfaces.
class AppTheme {
  AppTheme._();

  /// Global DatePickerThemeData configured with the MSS App theme:
  /// - Royal Blue header with crisp white Poppins/Inter typography
  /// - Pure white container with rounded corners and mist-gray borders
  /// - Interactive day/year chips matching primary royal blue
  /// - Modern Material 3 action buttons
  static DatePickerThemeData get datePickerTheme {
    return DatePickerThemeData(
      backgroundColor: AppConstants.surfaceColor,
      elevation: 6.0,
      shadowColor: const Color(0x1A0F172A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppConstants.cardBorderColor, width: 1),
      ),
      headerBackgroundColor: AppConstants.primaryColor,
      headerForegroundColor: Colors.white,
      headerHeadlineStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headerHelpStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 0.5,
      ),
      weekdayStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppConstants.secondaryText,
      ),
      dayStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppConstants.primaryText,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        if (states.contains(WidgetState.disabled)) {
          return AppConstants.secondaryText.withValues(alpha: 0.38);
        }
        return AppConstants.primaryText;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return Colors.transparent;
      }),
      dayOverlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppConstants.primaryColor.withValues(alpha: 0.2);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppConstants.primaryColor.withValues(alpha: 0.08);
        }
        return null;
      }),
      dayShape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppConstants.primaryColor;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return AppConstants.primaryColor.withValues(alpha: 0.12);
      }),
      todayBorder: const BorderSide(
        color: AppConstants.primaryColor,
        width: 1.5,
      ),
      yearStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppConstants.primaryText,
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        if (states.contains(WidgetState.disabled)) {
          return AppConstants.secondaryText.withValues(alpha: 0.38);
        }
        return AppConstants.primaryText;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primaryColor;
        }
        return Colors.transparent;
      }),
      yearOverlayColor: WidgetStateProperty.all(
        AppConstants.primaryColor.withValues(alpha: 0.12),
      ),
      dividerColor: AppConstants.cardBorderColor,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppConstants.secondaryText,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 1.8,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppConstants.secondaryText,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppConstants.secondaryText.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Helper function to display a date picker styled strictly according
/// to the MSS App theme.
Future<DateTime?> showThemedDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
  String? helpText,
  String? cancelText,
  String? confirmText,
  Locale? locale,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  TextDirection? textDirection,
  TransitionBuilder? builder,
  bool Function(DateTime)? selectableDayPredicate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? (currentDate ?? DateTime.now()),
    firstDate: firstDate,
    lastDate: lastDate,
    currentDate: currentDate,
    initialEntryMode: initialEntryMode,
    initialDatePickerMode: initialDatePickerMode,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    locale: locale,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    textDirection: textDirection,
    selectableDayPredicate: selectableDayPredicate,
    builder: (context, child) {
      final themedChild = Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: AppTheme.datePickerTheme,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppConstants.primaryColor,
                onPrimary: Colors.white,
                surface: AppConstants.surfaceColor,
                onSurface: AppConstants.primaryText,
              ),
        ),
        child: child!,
      );
      if (builder != null) {
        return builder(context, themedChild);
      }
      return themedChild;
    },
  );
}
