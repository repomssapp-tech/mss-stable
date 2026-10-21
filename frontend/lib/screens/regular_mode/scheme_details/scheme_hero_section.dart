import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/emblem_helper.dart';

/// Hero header section displaying scheme emblem, level badge, title,
/// sponsoring body, and match relevance banner.
///
/// Extracted from `scheme_details_screen.dart` (frontend refactor C5, safe slice) —
/// pure stateless presenter taking [LocalizedScheme] and [imagePath] via constructor.
class SchemeHeroSection extends StatelessWidget {
  final LocalizedScheme scheme;
  final String imagePath;

  /// Real match percentage from the results list, when the caller has one.
  /// The banner is hidden when null, so the page never shows an invented
  /// score (issue #129: every scheme used to show a hard-coded 96%).
  final int? matchPercentage;

  /// True when the eligibility engine marked this scheme "not applicable".
  final bool notApplicable;

  const SchemeHeroSection({
    super.key,
    required this.scheme,
    required this.imagePath,
    this.matchPercentage,
    this.notApplicable = false,
  });

  Widget _buildSchemeLogo(
    BuildContext context,
    LocalizedScheme scheme, {
    double size = 48,
  }) {
    final emblemAsset = EmblemHelper.getEmblemAsset(
      governmentLevel: scheme.governmentLevel,
      state: scheme.state,
      schemeCode: scheme.schemeCode,
      sponsoringBody: scheme.sponsoringBody,
      name: scheme.name,
    );

    // Emblem WebPs are ~900-1024px square; cap the decode to the physical
    // pixels shown (size dp x devicePixelRatio) instead of full resolution.
    final int decodePx = (size * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Image.asset(
      emblemAsset,
      fit: BoxFit.contain,
      width: size,
      height: size,
      cacheWidth: decodePx,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/States assets/Indian emblem.webp',
          fit: BoxFit.contain,
          width: size,
          height: size,
          cacheWidth: decodePx,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = scheme.name;
    final regex = RegExp(r'\(([^)]+)\)');
    final matchObj = regex.firstMatch(title);
    String shortForm = title;
    String fullName = '';

    final bracketText = matchObj?.group(1)?.trim() ?? '';
    if (bracketText.isNotEmpty) {
      final outsideText = title
          .replaceAll(regex, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final isBracketAcronym =
          bracketText.length <= 10 &&
          !bracketText.contains(' ') &&
          bracketText == bracketText.toUpperCase();
      if (isBracketAcronym) {
        shortForm = bracketText;
        fullName = outsideText;
      } else if (bracketText.length > outsideText.length) {
        shortForm = outsideText;
        fullName = bracketText;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image (Emblem Container)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  // 80% of the circle, so the emblem's bottom text is not
                  // cropped (test report UI-05).
                  child: ClipOval(
                    child: Center(
                      child: _buildSchemeLogo(context, scheme, size: 96),
                    ),
                  ),
                ),
              ),
            ),

            // Right Content Block
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.tight,
                            vertical: AppSpacing.hairline,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.levelSchemeFormat(
                              scheme.governmentLevel.isNotEmpty
                                  ? scheme.governmentLevel
                                  : 'Central',
                            ),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2563EB),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          shortForm,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fullName.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.hairline),
                          Text(
                            "($fullName)",
                            style: GoogleFonts.inter(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          scheme.sponsoringBody,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),

                    // Sponsoring theme tags
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (scheme.schemeType.isNotEmpty)
                          _buildMiniTag(
                            scheme.schemeType,
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                        if (scheme.sector.isNotEmpty)
                          _buildMiniTag(
                            scheme.sector,
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                          ),
                        if (scheme.schemeType.isEmpty &&
                            scheme.sector.isEmpty) ...[
                          _buildMiniTag(
                            "Loan",
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                          _buildMiniTag(
                            "Subsidy",
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),

                    // Match Banner (Single-row layout); only with a real score.
                    if (notApplicable || matchPercentage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF2563EB),
                              size: 12,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: GoogleFonts.inter(fontSize: 10),
                                  children: [
                                    if (notApplicable)
                                      TextSpan(
                                        text: context.l10n.schemeNotApplicable,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warningText,
                                        ),
                                      )
                                    else ...[
                                      TextSpan(
                                        text: context.l10n
                                            .matchPercentageFormat(
                                              matchPercentage!,
                                            ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      if (matchPercentage! >= 80)
                                        TextSpan(
                                          text:
                                              " • ${context.l10n.highlyRelevant}",
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tight,
        vertical: AppSpacing.hairline,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        CentralizedTranslator.instance.localizeTag(label),
        style: GoogleFonts.inter(
          color: text,
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
