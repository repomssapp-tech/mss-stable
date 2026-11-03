import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_elevation.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/emblem_helper.dart';
import '../../../utils/app_text.dart';
import '../../../widgets/common/auto_translated_text.dart';

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

  /// The emblem's size; it sits in a circle a little larger than this.
  static const double emblemSize = 96;

  const SchemeHeroSection({
    super.key,
    required this.scheme,
    required this.imagePath,
    this.matchPercentage,
    this.notApplicable = false,
  });

  Widget _buildSchemeLogo(BuildContext context, LocalizedScheme scheme) {
    final emblemAsset = EmblemHelper.getEmblemAsset(
      governmentLevel: scheme.governmentLevel,
      state: scheme.state,
      schemeCode: scheme.schemeCode,
      sponsoringBody: scheme.sponsoringBody,
      name: scheme.name,
    );

    // Emblem WebPs are ~900-1024px square; cap the decode to the physical
    // pixels shown (size dp x devicePixelRatio) instead of full resolution.
    final int decodePx = (emblemSize * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Image.asset(
      emblemAsset,
      fit: BoxFit.contain,
      width: emblemSize,
      height: emblemSize,
      cacheWidth: decodePx,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/States assets/Indian emblem.webp',
          fit: BoxFit.contain,
          width: emblemSize,
          height: emblemSize,
          cacheWidth: decodePx,
          excludeFromSemantics: true,
        );
      },
    );
  }

  /// "Central scheme" / "State scheme" in the app language, or null when the
  /// record does not say who runs it.
  String? _levelLabel(BuildContext context) {
    final level = scheme.governmentLevel.trim();
    if (level.isEmpty) return null;
    final name = switch (level.toLowerCase()) {
      'central' => context.l10n.filterCentral,
      'state' => context.l10n.filterState,
      _ => CentralizedTranslator.instance.localizeTag(level),
    };
    return context.l10n.levelSchemeFormat(name);
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

    final levelLabel = _levelLabel(context);
    final language = Localizations.localeOf(context).languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The emblem of who runs the scheme, on a quiet panel.
            Expanded(
              flex: 2,
              child: ColoredBox(
                color: AppColors.surfaceMuted,
                child: Center(
                  child: Container(
                    width: emblemSize + AppSpacing.xl,
                    height: emblemSize + AppSpacing.xl,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.card,
                    ),
                    // The circle is larger than the emblem, so the emblem's
                    // bottom text is not cropped (test report UI-05).
                    child: ClipOval(
                      child: Center(child: _buildSchemeLogo(context, scheme)),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (levelLabel != null) ...[
                      _Tag(label: levelLabel, style: AppTagStyle.level),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AutoTranslatedText(
                      shortForm,
                      language: language,
                      style: context.text.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fullName.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.hairline),
                      Text(
                        "($fullName)",
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (scheme.sponsoringBody.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        scheme.sponsoringBody,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Type and sector, only when the record has them.
                    if (scheme.schemeType.isNotEmpty ||
                        scheme.sector.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (scheme.schemeType.isNotEmpty)
                            _Tag(
                              label: CentralizedTranslator.instance.localizeTag(
                                scheme.schemeType,
                              ),
                              style: AppTagStyle.neutral,
                            ),
                          if (scheme.sector.isNotEmpty)
                            _Tag(
                              label: CentralizedTranslator.instance.localizeTag(
                                scheme.sector,
                              ),
                              style: AppTagStyle.neutral,
                            ),
                        ],
                      ),
                    ],

                    // Match line; only with a real score.
                    if (notApplicable || matchPercentage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (notApplicable)
                              TextSpan(
                                text: context.l10n.schemeNotApplicable,
                                style: const TextStyle(
                                  color: AppColors.warningText,
                                ),
                              )
                            else ...[
                              TextSpan(
                                text: context.l10n.matchPercentageFormat(
                                  matchPercentage!,
                                ),
                                style: const TextStyle(
                                  color: AppColors.primaryStrong,
                                ),
                              ),
                              if (matchPercentage! >= 80)
                                TextSpan(
                                  text: " · ${context.l10n.highlyRelevant}",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ],
                        ),
                        style: context.text.label,
                      ),
                    ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.style});

  final String label;
  final ({Color text, Color background}) style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.hairline,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(label, style: context.text.label.copyWith(color: style.text)),
    );
  }
}
