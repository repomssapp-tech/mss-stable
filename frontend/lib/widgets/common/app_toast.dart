import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_spacing.dart';

enum ToastType { success, info, warning, error }

/// A unified, sleek Material 3 Toast and Banner notification system.
/// Replaces raw debugging SnackBar popups with polished, floating notifications.
class AppToast {
  AppToast._();

  /// Shows a success toast with a green accent and checkmark icon.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, ToastType.success, duration);
  }

  /// Shows an informational toast with a blue accent and info icon.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, ToastType.info, duration);
  }

  /// Shows a warning toast with an amber accent and warning icon.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, ToastType.warning, duration);
  }

  /// Shows a user-friendly error toast with a soft red accent and alert icon.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(context, message, ToastType.error, duration);
  }

  static void _show(
    BuildContext context,
    String message,
    ToastType type,
    Duration duration,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bgColor = const Color(0xFFF0FDF4); // Light Emerald
        borderColor = const Color(0xFFBBF7D0);
        iconColor = const Color(0xFF16A34A);
        textColor = const Color(0xFF14532D);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.info:
        bgColor = const Color(0xFFEFF6FF); // Light Blue
        borderColor = const Color(0xFFBFDBFE);
        iconColor = const Color(0xFF2563EB);
        textColor = const Color(0xFF1E3A8A);
        icon = Icons.info_rounded;
        break;
      case ToastType.warning:
        bgColor = const Color(0xFFFFFBEB); // Light Amber
        borderColor = const Color(0xFFFDE68A);
        iconColor = const Color(0xFFD97706);
        textColor = const Color(0xFF78350F);
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.error:
        bgColor = const Color(0xFFFEF2F2); // Light Rose
        borderColor = const Color(0xFFFECACA);
        iconColor = const Color(0xFFDC2626);
        textColor = const Color(0xFF7F1D1D);
        icon = Icons.error_outline_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 3,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      padding: EdgeInsets.zero,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}
