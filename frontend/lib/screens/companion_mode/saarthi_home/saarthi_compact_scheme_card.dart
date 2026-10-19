import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/voice/livekit_voice_agent_controller.dart';
import '../../../utils/app_spacing.dart';
import '../../regular_mode/scheme_details_screen.dart';

/// Builds a themed icon for companion mode scheme cards based on the scheme name.
Widget buildSaarthiSchemeIcon(String schemeName) {
  final lower = schemeName.toLowerCase();
  IconData icon = Icons.account_balance_rounded;
  Color bg = const Color(0xFFEFF6FF);
  Color foreground = const Color(0xFF2563EB);

  if (lower.contains('pmegp')) {
    icon = Icons.factory_outlined;
  } else if (lower.contains('cgtmse')) {
    icon = Icons.currency_rupee_rounded;
    bg = const Color(0xFFECFDF5);
    foreground = const Color(0xFF059669);
  } else if (lower.contains('mse-cdp')) {
    icon = Icons.settings_outlined;
    bg = const Color(0xFFF5F3FF);
    foreground = const Color(0xFF7C3AED);
  }

  return Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 20, color: foreground),
  );
}

/// Matches a [Scheme] with its corresponding [CloudSchemeResult] from metadata.
CloudSchemeResult? metadataForScheme(
  Scheme scheme,
  List<CloudSchemeResult>? results,
) {
  if (results == null) return null;
  String normalize(String value) => value.toLowerCase().trim();
  for (final result in results) {
    if (result.id.isNotEmpty && normalize(result.id) == normalize(scheme.id)) {
      return result;
    }
    if (result.code.isNotEmpty &&
        (normalize(result.code) == normalize(scheme.schemeCode) ||
            normalize(result.code) == normalize(scheme.id))) {
      return result;
    }
    if (result.name.isNotEmpty &&
        normalize(result.name) == normalize(scheme.name)) {
      return result;
    }
  }
  return null;
}

/// Compact scheme card widget for Saarthi companion mode assistant transcript turns.
class SaarthiCompactSchemeCard extends StatelessWidget {
  const SaarthiCompactSchemeCard({
    super.key,
    required this.scheme,
    this.metadata,
  });

  final Scheme scheme;
  final CloudSchemeResult? metadata;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    final locScheme = scheme.toLocalized(lang);

    final confidence = metadata?.matchConfidence;
    final confidenceColor = confidence == null
        ? const Color(0xFF64748B)
        : confidence >= 80
        ? const Color(0xFF047857)
        : confidence >= 60
        ? const Color(0xFF2563EB)
        : const Color(0xFFB45309);
    final verified =
        metadata?.isVerified == true ||
        scheme.verificationStatus.toLowerCase().contains('verified');
    final sourceConfidence = metadata?.sourceConfidence.trim() ?? '';
    final summary = locScheme.benefits.trim().isNotEmpty
        ? locScheme.benefits.trim()
        : locScheme.overview.trim();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('companion-scheme-${scheme.id}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: confidenceColor.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSaarthiSchemeIcon(locScheme.name),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        locScheme.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.tight,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        confidence == null
                            ? context.l10n.companionReviewMatch
                            : context.l10n.companionMatchPercent(confidence),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: confidenceColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      height: 1.4,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: verified
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Expanded(
                      child: Text(
                        verified
                            ? sourceConfidence.isEmpty
                                  ? context.l10n.companionOfficialSourceChecked
                                  : context.l10n
                                        .companionOfficialSourceCheckedConfidence(
                                          '${sourceConfidence[0].toUpperCase()}${sourceConfidence.substring(1)}',
                                        )
                            : context.l10n.companionVerifyWithDepartment,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: verified
                              ? const Color(0xFF047857)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.companionViewEligibility,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.hairline),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
