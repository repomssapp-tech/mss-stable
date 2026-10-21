import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';

class LegalConsentSection extends StatelessWidget {
  final bool hasViewedTerms;
  final bool hasViewedPrivacy;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  const LegalConsentSection({
    super.key,
    required this.hasViewedTerms,
    required this.hasViewedPrivacy,
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
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: context.l10n.legalTermsOfUseLink,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D53FC),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onOpenTerms,
                ),
                TextSpan(text: context.l10n.legalConsentMid),
                TextSpan(
                  text: context.l10n.privacyPolicy,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D53FC),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onOpenPrivacy,
                ),
                TextSpan(text: context.l10n.legalConsentSuffix),
              ],
            ),
          ),
          // Full-size targets for the two documents: the inline links are
          // only ~25 dp tall (test report NEW-10). A tick shows once read.
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _DocButton(
                label: context.l10n.legalTermsOfUseLink,
                viewed: hasViewedTerms,
                onPressed: onOpenTerms,
              ),
              _DocButton(
                label: context.l10n.privacyPolicy,
                viewed: hasViewedPrivacy,
                onPressed: onOpenPrivacy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocButton extends StatelessWidget {
  const _DocButton({
    required this.label,
    required this.viewed,
    required this.onPressed,
  });

  final String label;
  final bool viewed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        viewed ? Icons.check_circle_rounded : Icons.description_outlined,
        size: AppSize.iconSm,
        color: viewed ? AppColors.success : AppColors.primary,
      ),
      label: Text(label),
    );
  }
}
