import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/app_info_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_version.dart';
import '../../utils/app_text.dart';

void showAboutAppDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final text = context.text;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/Logo/Logo.webp',
                      width: AppSize.tapTarget,
                      height: AppSize.tapTarget,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'MSS',
                        style: text.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // The installed build's real version, not a literal.
                    FutureBuilder<AppVersion?>(
                      future: AppInfoService.installedVersion(),
                      builder: (context, snapshot) {
                        final v = snapshot.data;
                        return Text(
                          v == null ? '' : 'v${v.label}',
                          style: text.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.aboutAppSubtitle,
                  style: text.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                Text(
                  context.l10n.aboutAppDescriptionLong,
                  style: text.body.copyWith(color: AppColors.textBody),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.aboutDevelopedWith,
                  style: text.label.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Partner marks exactly as supplied.
                Row(
                  children: [
                    Flexible(
                      child: Image.asset(
                        'assets/images/Logo/rit_logo.webp',
                        height: AppSpacing.xxxl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Flexible(
                      child: Image.asset(
                        'assets/images/Logo/sss_tn_chapter_logo.webp',
                        height: AppSpacing.xxxl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• Rajalakshmi Institute of Technology (RIT)\n• Swadeshi Shodh Sansthan (SSS TN Chapter)',
                  style: text.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: AppSize.iconSm,
                      color: AppColors.iconMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.l10n.aboutSupportLine(
                          'mssschemessearch@gmail.com',
                        ),
                        style: text.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.close),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
