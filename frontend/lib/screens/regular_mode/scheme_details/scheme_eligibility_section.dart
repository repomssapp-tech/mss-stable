import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../utils/app_spacing.dart';

/// Content section for scheme eligibility criteria and verification notes.
class SchemeEligibilityContent extends StatelessWidget {
  final LocalizedScheme scheme;

  const SchemeEligibilityContent({
    super.key,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...scheme.eligibilityCriteria.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.hairline),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2563EB),
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rule,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (scheme.verificationNotes.isNotEmpty) ...[
          const Divider(height: AppSpacing.xl),
          Text(
            context.l10n.verificationNote,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            scheme.verificationNotes,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
