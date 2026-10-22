import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

class CustomConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;

  /// When null, falls back to the localized default in [build].
  final String? cancelLabel;

  /// When null, falls back to the localized default in [build].
  final String? confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const CustomConfirmDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    this.cancelLabel,
    this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    this.isDestructive = false,
  });

  static void show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String message,
    String? cancelLabel,
    String? confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: CustomConfirmDialog(
          icon: icon,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          confirmColor: confirmColor,
          onConfirm: onConfirm,
          isDestructive: isDestructive,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCancelLabel = cancelLabel ?? context.l10n.dialogCancel;
    final resolvedConfirmLabel = confirmLabel ?? context.l10n.dialogConfirm;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: AppColors.border,
          width: AppSize.borderWidthSelected,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          // B3 (batch-1 review): destructive confirms must use AppColors.danger,
          // not whatever raw colour (e.g. #EF4444, 3.76:1 with white) the caller
          // passed -- that combination fails WCAG contrast.
          Container(
            width: AppSize.avatar,
            height: AppSize.avatar,
            decoration: BoxDecoration(
              color: isDestructive ? AppColors.dangerSoft : iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppColors.danger : iconColor,
              size: AppSize.iconLg,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Action Buttons Row
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom( // style-ok: dialog-local shape/hit-area, not a theme-wide button variant
                    minimumSize: const Size(0, AppSize.tapTarget),
                    // Two buttons share a narrow dialog: the default 24 dp
                    // side padding left Tamil labels too little room.
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    resolvedCancelLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Confirm Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom( // style-ok: confirmColor is caller-supplied per call (danger/primary/success), not a static theme variant
                    // B3: a destructive confirm always uses the vetted
                    // AppColors.danger (4.83:1 with white), never the
                    // caller's raw colour -- no call-site changes needed.
                    backgroundColor: isDestructive
                        ? AppColors.danger
                        : confirmColor,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(0, AppSize.tapTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Text(
                    resolvedConfirmLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
