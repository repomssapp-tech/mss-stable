import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// The canonical English copyright line supplied by the rights holders.
const String mssCopyrightLine =
    '© 2026 Swadeshi Shodh Sansthan, Tamil Nadu Chapter & Rajalakshmi '
    'Institute of Technology, Chennai. All Rights Reserved.';

/// The app's copyright notice.
///
/// [CopyrightNotice.line] is the one-line form for screen footers (login,
/// settings). [CopyrightNotice.full] adds the heading and the full notice
/// (About dialog, Terms of Use).
class CopyrightNotice extends StatelessWidget {
  const CopyrightNotice.line({super.key}) : full = false;
  const CopyrightNotice.full({super.key}) : full = true;

  final bool full;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    if (!full) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          context.l10n.copyrightOwnership,
          textAlign: TextAlign.center,
          style: text.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.copyrightNoticeTitle,
          style: text.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.copyrightOwnership,
          style: text.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.copyrightNoticeBody,
          style: text.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
