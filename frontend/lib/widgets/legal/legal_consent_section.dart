import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../utils/app_text.dart';
import 'package:google_fonts/google_fonts.dart';
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
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: context.l10n.legalTermsOfUseLink,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D53FC),
                    decoration: context.linkDecoration,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onOpenTerms,
                ),
                TextSpan(text: context.l10n.legalConsentMid),
                TextSpan(
                  text: context.l10n.privacyPolicy,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D53FC),
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
