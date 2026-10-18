import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';

class LegalConsentSection extends StatelessWidget {
  final bool hasViewedTerms;
  final bool hasViewedPrivacy;
  final bool hasAgreedToConsent;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final ValueChanged<bool?> onConsentChanged;
  final VoidCallback onDisabledConsentTap;

  const LegalConsentSection({
    super.key,
    required this.hasViewedTerms,
    required this.hasViewedPrivacy,
    required this.hasAgreedToConsent,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onConsentChanged,
    required this.onDisabledConsentTap,
  });

  bool get canConsent => hasViewedTerms && hasViewedPrivacy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canConsent
          ? () => onConsentChanged(!hasAgreedToConsent)
          : onDisabledConsentTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: hasAgreedToConsent,
                onChanged: canConsent
                    ? onConsentChanged
                    : (_) => onDisabledConsentTap(),
                activeColor: const Color(0xFF0D53FC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
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
                      recognizer: TapGestureRecognizer()
                        ..onTap = onOpenTerms,
                    ),
                    TextSpan(text: context.l10n.legalConsentMid),
                    TextSpan(
                      text: context.l10n.privacyPolicy,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D53FC),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = onOpenPrivacy,
                    ),
                    TextSpan(text: context.l10n.legalConsentSuffix),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
