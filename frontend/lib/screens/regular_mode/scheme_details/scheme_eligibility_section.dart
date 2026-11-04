import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Content section for scheme eligibility criteria and verification notes.
class SchemeEligibilityContent extends StatelessWidget {
  final LocalizedScheme scheme;

  const SchemeEligibilityContent({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in scheme.eligibilityCriteria)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.hairline),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: AppSize.iconSm,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rule,
                    style: context.text.body.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (scheme.verificationNotes.isNotEmpty) ...[
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Text(
            context.l10n.verificationNote,
            style: context.text.label.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            scheme.verificationNotes,
            style: context.text.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
