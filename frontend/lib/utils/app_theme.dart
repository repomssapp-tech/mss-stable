import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_size.dart';
import 'app_text.dart';
import 'constants.dart';
import 'app_spacing.dart';

OutlineInputBorder _outline(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );

/// AppTheme
/// ────────
/// Centralized styling definitions for the MSS App, ensuring 100% theme
/// consistency across dialogs, pickers, and surfaces.
class AppTheme {
  AppTheme._();

  /// Phase 2 (2.3): the whole app `ThemeData`, moved out of `main.dart`.
  /// Built from the tokens in app_colors/app_radius/app_size/app_elevation
  /// /app_text.dart (spec_design_system.md §5). No screen has adopted
  /// `context.text.*` yet (that is the Phase 3 codemod), so this changes
  /// only the *ambient* theme defaults -- what Material widgets fall back
  /// to when a call site doesn't pass its own explicit style. The large
  /// majority of existing screens pass explicit `GoogleFonts.inter/poppins`
  /// styles that override these defaults entirely, so this is visually
  /// neutral for them.
  static ThemeData get light {
    final t = AppTextStyles.en;
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primaryStrong,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
      surfaceContainerHighest: AppColors.surfaceMuted,
    );
    final rMd = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
    const minBtn = Size(64, AppSize.controlHeight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.body,
      textTheme:
          TextTheme(
            headlineSmall: t.headline,
            titleLarge: t.titleLarge,
            titleMedium: t.titleSmall,
            titleSmall: t.cardTitle,
            bodyLarge: t.bodyLarge,
            bodyMedium: t.body,
            bodySmall: t.bodySmall,
            labelLarge: t.button,
            labelMedium: t.label,
            labelSmall: t.label,
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          elevation: 0,
          minimumSize: minBtn,
          shape: rMd,
          textStyle: t.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          elevation: 0,
          minimumSize: minBtn,
          shape: rMd,
          textStyle: t.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: minBtn,
          shape: rMd,
          textStyle: t.button,
          side: const BorderSide(
            color: AppColors.primary,
            width: AppSize.borderWidthSelected,
          ),
          disabledForegroundColor: AppColors.disabledFg,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, AppSize.tapTarget),
          textStyle: t.button,
          shape: rMd,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSize.tapTarget),
          foregroundColor: AppColors.textPrimary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: t.bodyLarge.copyWith(color: AppColors.textMuted),
        labelStyle: t.body.copyWith(color: AppColors.textSecondary),
        errorStyle: t.bodySmall.copyWith(color: AppColors.danger),
        border: _outline(AppColors.border),
        enabledBorder: _outline(AppColors.border),
        focusedBorder: _outline(AppColors.primary, 2),
        errorBorder: _outline(AppColors.danger),
        focusedErrorBorder: _outline(AppColors.danger, 2),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: t.label.copyWith(color: AppColors.textBody),
        secondaryLabelStyle: t.label.copyWith(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        showCheckmark: true,
        checkmarkColor: AppColors.primary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t.titleMedium.copyWith(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: t.titleLarge.copyWith(color: AppColors.textPrimary),
        contentTextStyle: t.body.copyWith(color: AppColors.textBody),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        // D1 (Phase 2 design review): off for now -- ~13 existing sheets
        // already draw their own handle, so a theme-level one doubles up.
        // Phase 3 flips this to true per sheet as each manual handle is
        // deleted.
        showDragHandle: false,
        dragHandleColor: AppColors.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: t.body.copyWith(color: AppColors.textOnPrimary),
        shape: rMd,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return t.label.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.iconMuted,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),
      datePickerTheme: AppTheme.datePickerTheme,
    );
  }

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
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppConstants.primaryColor,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
