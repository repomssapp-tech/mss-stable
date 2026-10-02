import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

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
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.success, duration, actionLabel, onAction);
  }

  /// Shows an informational toast with a blue accent and info icon.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.info, duration, actionLabel, onAction);
  }

  /// Shows a warning toast with an amber accent and warning icon.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.warning, duration, actionLabel, onAction);
  }

  /// Shows a user-friendly error toast with a soft red accent and alert icon.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.error, duration, actionLabel, onAction);
  }

  static void _show(
    BuildContext context,
    String message,
    ToastType type,
    Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
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
        bgColor = AppColors.successSoft;
        borderColor = AppColors.success;
        iconColor = AppColors.success;
        textColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.info:
        bgColor = AppColors.primarySoft;
        borderColor = AppColors.primaryBorder;
        iconColor = AppColors.primary;
        textColor = AppColors.primaryDeep;
        icon = Icons.info_rounded;
        break;
      case ToastType.warning:
        bgColor = AppColors.warningSoft;
        borderColor = AppColors.warning;
        iconColor = AppColors.warning;
        textColor = AppColors.warningOnSoft;
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.error:
        bgColor = AppColors.dangerSoft;
        borderColor = AppColors.dangerBorder;
        iconColor = AppColors.danger;
        textColor = AppColors.dangerStrong;
        icon = Icons.error_outline_rounded;
        break;
    }

    final hasAction = actionLabel != null && onAction != null;

    final snackBar = SnackBar(
      elevation: 3,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      padding: EdgeInsets.zero,
      duration: hasAction ? const Duration(seconds: 5) : duration,
      content: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: AppSize.iconSm),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      message,
                      // B2 (batch-1 review): a toast must never hide its
                      // message. 4 lines fits every message in this app at
                      // <= 140 chars; longer than that is genuinely
                      // unbounded caller input, so it still gets an
                      // ellipsis rather than pushing the toast off-screen.
                      maxLines: 4,
                      overflow: message.length <= 140
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (hasAction && message.length <= 40)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom( // style-ok: CTA height inside a toast row
                        minimumSize: const Size(0, AppSize.tapTarget),
                      ),
                      child: Text(actionLabel, maxLines: 2),
                    ),
                ],
              ),
              // Long messages get the action on its own row so the message
              // keeps its full width instead of fighting the button for space.
              if (hasAction && message.length > 40)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom( // style-ok: CTA height inside a toast row
                      minimumSize: const Size(0, AppSize.tapTarget),
                    ),
                    child: Text(actionLabel, maxLines: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}
