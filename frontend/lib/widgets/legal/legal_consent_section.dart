import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';

class LegalConsentSection extends StatelessWidget {
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  const LegalConsentSection({
    super.key,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: context.l10n.legalConsentPrefix,
              style: context.text.bodySmall.copyWith(color: AppColors.textBody),
              children: [
                TextSpan(
                  text: context.l10n.legalTermsOfUseLink,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: context.linkDecoration,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onOpenTerms,
                ),
                TextSpan(text: context.l10n.legalConsentMid),
                TextSpan(
                  text: context.l10n.privacyPolicy,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: context.linkDecoration,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onOpenPrivacy,
                ),
                TextSpan(text: context.l10n.legalConsentSuffix),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
