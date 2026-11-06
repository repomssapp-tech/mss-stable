import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/scheme_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../search_results_screen.dart';
import 'search_models.dart';
import 'shimmer_skeleton_card.dart';
import '../../../utils/app_text.dart';

/// The "For me" card on the idle Search tab: how many schemes match the
/// user's profile, and a tap to list them.
class SearchHighlightSummaryCard extends StatelessWidget {
  final bool isLoadingCounts;
  final int matchingProfileCount;

  /// [matchingProfileCount] counts partial matches, not strong ones.
  final bool matchingProfileIsPartial;
  final VoidCallback onTap;

  const SearchHighlightSummaryCard({
    super.key,
    required this.isLoadingCounts,
    required this.matchingProfileCount,
    this.matchingProfileIsPartial = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(
          color: AppColors.primaryBorder,
          width: AppSize.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: AppSize.avatarSm,
                height: AppSize.avatarSm,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.how_to_reg_outlined,
                  color: AppColors.primary,
                  size: AppSize.icon,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.forMe,
                      style: context.text.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      isLoadingCounts
                          ? context.l10n.calculatingMatches
                          : matchingProfileIsPartial
                          ? context.l10n.forMePartialCount(matchingProfileCount)
                          : context.l10n.schemesMatchProfile(
                              matchingProfileCount,
                            ),
                      style: context.text.bodySmall.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: AppSize.iconLg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category row shown in the idle Browse categories list.
class SearchCategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isLoadingCounts;

  const SearchCategoryCard({
    super.key,
    required this.category,
    required this.isLoadingCounts,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final categoryTitle = category["title"] as String;
            final schemes = await SchemeRepository.instance
                .getSchemesByCategory(categoryTitle);
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchResultsScreen(
                  title: categoryTitle,
                  type: 'category',
                  initialSchemes: schemes,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSize.avatarSm,
                  height: AppSize.avatarSm,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySoft,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    category["icon"] as IconData,
                    color: AppColors.primary,
                    size: AppSize.icon,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getLocalizedTagOrCategory(
                          category["title"] as String,
                          provider.selectedLanguage,
                        ),
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.hairline),
                      if (isLoadingCounts)
                        const SearchSkeletonBar(width: 70, height: 10)
                      else
                        Text(
                          category["count"] as String,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.iconMuted,
                  size: AppSize.icon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Idle view content showing highlight summary card and category list.
class SearchIdleContent extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final bool isLoadingCounts;
  final int matchingProfileCount;
  final bool matchingProfileIsPartial;
  final VoidCallback onHighlightTap;

  const SearchIdleContent({
    super.key,
    required this.categories,
    required this.isLoadingCounts,
    required this.matchingProfileCount,
    this.matchingProfileIsPartial = false,
    required this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey("IdleContent"),
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const ClampingScrollPhysics(),
      children: [
        SearchHighlightSummaryCard(
          isLoadingCounts: isLoadingCounts,
          matchingProfileCount: matchingProfileCount,
          matchingProfileIsPartial: matchingProfileIsPartial,
          onTap: onHighlightTap,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.browseCategories,
          style: context.text.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final cat in categories)
          SearchCategoryCard(category: cat, isLoadingCounts: isLoadingCounts),
      ],
    );
  }
}
