import 'package:flutter/material.dart';
import '../../../widgets/common/auto_translated_text.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../services/recommendation/for_you_picks.dart';
import '../../../services/recommendation/indian_states.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../utils/emblem_helper.dart';
import '../basic_profile_screen.dart';
import '../scheme_details_screen.dart';
import 'guest_state_schemes.dart';
import '../../../widgets/common/sign_in_required_sheet.dart';

class HomeRecommendedSection extends StatefulWidget {
  final List<Scheme>? schemes;
  final AppProvider? provider;

  const HomeRecommendedSection({super.key, this.schemes, this.provider});

  @override
  State<HomeRecommendedSection> createState() => _HomeRecommendedSectionState();
}

class _HomeRecommendedSectionState extends State<HomeRecommendedSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = widget.provider ?? Provider.of<AppProvider>(context);

    // `widget.schemes` is a test-only seam with no associated
    // RecommendationResult, so items built from it never get a match badge
    // (see the badge-suppression rule below). Production always goes
    // through `appProvider.recommendedSchemes`, which carries a real score.
    final List<MapEntry<Scheme, int?>> scoredSchemes;
    // Production resolves through the same pickForYou as Search's "For Me",
    // so the two always agree. A test passing `widget.schemes` sees them as
    // strong matches.
    var tier = ForYouTier.strong;
    // A guest has no account to match against: show the top schemes for
    // their state, with no match badge, instead of "Recommended for you".
    final guest = appProvider.isGuest && widget.schemes == null;
    final guestState = guest
        ? guestStateFor(
            profileState: appProvider.profile.state,
            language: appProvider.selectedLanguage,
          )
        : '';
    if (widget.schemes != null) {
      scoredSchemes = widget.schemes!.map((s) => MapEntry(s, null)).toList();
    } else if (guest) {
      scoredSchemes = [
        for (final s in pickGuestStateSchemes(
          all: appProvider.allSchemes,
          state: guestState,
        ))
          MapEntry(s, null),
      ];
    } else {
      final picks = pickForYou(
        profile: appProvider.profile,
        ranked: appProvider.recommendedSchemes,
      );
      tier = picks.tier;
      scoredSchemes = picks.items
          .take(5)
          .map((entry) => MapEntry(entry.key, entry.value.percentage))
          .toList();
    }

    final List<_RecommendedItem> items = [
      for (final entry in scoredSchemes)
        () {
          final sRaw = entry.key;
          final s = sRaw.toLocalized(appProvider.selectedLanguage);
          return _RecommendedItem(
            scheme: sRaw,
            title: s.name,
            subtitle: s.overview.isNotEmpty ? s.overview : s.objectives,
            matchPercentage: entry.value,
            isBookmarked:
                appProvider.bookmarkedIds.contains(sRaw.id) ||
                appProvider.bookmarkedIds.contains(sRaw.schemeCode),
            chips: s.glanceChips.take(3).toList(),
          );
        }(),
    ];

    final heading = Text(
      !guest
          ? context.l10n.recommendedForYou
          : guestState.isEmpty
          ? context.l10n.homeTopSchemes
          : context.l10n.homeTopSchemesInState(
              IndianStates.displayName(
                guestState,
                appProvider.selectedLanguage,
              ),
            ),
      style: context.text.titleSmall.copyWith(color: AppColors.textPrimary),
    );
    // Nothing is a strong match: say so, then show the closest ones.
    final partialNote = tier == ForYouTier.partial
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.hairline),
            child: Text(
              context.l10n.forYouPartialNote,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          )
        : null;

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: AppSpacing.md),
          // While the catalog loads there is nothing to judge yet, so someone
          // whose profile is complete sees the card waiting, not a request
          // to complete it.
          if (appProvider.schemesLoading &&
              (guest || appProvider.profileCompletionPercentage >= 100) &&
              widget.schemes == null)
            _buildLoadingState(context)
          else
            _buildEmptyState(
              context,
              message: tier == ForYouTier.none
                  ? context.l10n.searchNoProfileMatchesTitle
                  : context.l10n.homeRecommendationsEmptyMessage,
            ),
        ],
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    // A little of the next card peeks in, so the row reads as scrollable.
    final cardWidth = (screenWidth - AppSpacing.lg * 2 - AppSpacing.md) / 1.08;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading,
        ?partialNote,
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: i == items.length - 1
                          ? AppSpacing.none
                          : AppSpacing.md,
                    ),
                    child: SizedBox(
                      width: cardWidth,
                      child: _buildCard(context, appProvider, items[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppProvider appProvider,
    _RecommendedItem item,
  ) {
    final schemeObj = item.scheme;
    final (shortForm, fullName) = _splitName(item.title);

    final chips =
        (List<String>.from(item.chips)
              ..sort((a, b) => a.length.compareTo(b.length)))
            .map((t) => CentralizedTranslator.instance.localizeTag(t))
            .toList();

    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchemeDetailsScreen(scheme: schemeObj),
          ),
        ),
        child: Stack(
          children: [
            // Faint emblem of who runs the scheme: the state's
            // emblem, or the national emblem for central schemes.
            Positioned(
              right: -AppSpacing.md,
              bottom: -AppSpacing.md,
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    EmblemHelper.getEmblemAsset(
                      governmentLevel: schemeObj.governmentLevel,
                      state: schemeObj.state,
                      schemeCode: schemeObj.schemeCode,
                      sponsoringBody: schemeObj.sponsoringBody,
                      name: schemeObj.name,
                    ),
                    width: 120,
                    height: 120,
                    cacheWidth: 240,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match and bookmark row.
                  Row(
                    children: [
                      // Only shown when this item carries a real
                      // RecommendationResult score -- never fabricated.
                      if (item.matchPercentage != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppTagStyle.level.background,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              context.l10n.matchPercentageFormat(
                                item.matchPercentage!,
                              ),
                              style: context.text.label.copyWith(
                                color: AppTagStyle.level.text,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        // H7: bookmark by `id`, the single canonical
                        // key everywhere -- `schemeCode` always
                        // differs from `id` in the real catalog.
                        onPressed: () async {
                          if (!await requireAccount(context)) return;
                          appProvider.toggleBookmark(schemeObj.id);
                        },
                        tooltip: item.isBookmarked
                            ? context.l10n.removeSavedTooltip
                            : context.l10n.saveSchemeTooltip,
                        icon: Icon(
                          item.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: item.isBookmarked
                              ? AppColors.primary
                              : AppColors.iconMuted,
                          size: AppSize.icon,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          shortForm,
                          language: appProvider.selectedLanguage,
                          style: context.text.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
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
                        // The scheme's summary.
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.lg),
                          child: AutoTranslatedText(
                            item.subtitle,
                            language: appProvider.selectedLanguage,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chips sit at the foot of every card in the row.
                  const Spacer(),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final tag in chips)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.tight,
                              vertical: AppSpacing.hairline,
                            ),
                            decoration: BoxDecoration(
                              color: AppTagStyle.neutral.background,
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              tag,
                              style: context.text.bodySmall.copyWith(
                                color: AppTagStyle.neutral.text,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Splits "Full Name (ACRONYM)" into the short form shown as the title and
  /// the full name shown under it.
  (String, String) _splitName(String title) {
    final regex = RegExp(r'\(([^)]+)\)');
    final bracketText = regex.firstMatch(title)?.group(1)?.trim() ?? '';
    if (bracketText.isEmpty) return (title, '');
    final outsideText = title
        .replaceAll(regex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final isBracketAcronym =
        bracketText.length <= 10 &&
        !bracketText.contains(' ') &&
        bracketText == bracketText.toUpperCase();
    if (isBracketAcronym) return (bracketText, outsideText);
    if (bracketText.length > outsideText.length) {
      return (outsideText, bracketText);
    }
    return (title, '');
  }

  Widget _buildLoadingState(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: AppColors.border,
            width: AppSize.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final widthFactor in const [0.5, 0.9, 0.7]) ...[
              FractionallySizedBox(
                widthFactor: widthFactor,
                child: Container(
                  height: AppSpacing.md,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: context.text.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BasicProfileScreen()),
              );
            },
            child: Text(context.l10n.completeProfile),
          ),
        ],
      ),
    );
  }
}

class _RecommendedItem {
  const _RecommendedItem({
    required this.scheme,
    required this.title,
    required this.subtitle,
    required this.matchPercentage,
    required this.isBookmarked,
    required this.chips,
  });

  final Scheme scheme;
  final String title;
  final String subtitle;
  final int? matchPercentage;
  final bool isBookmarked;
  final List<String> chips;
}
