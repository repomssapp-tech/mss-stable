import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/scheme/scheme_card.dart';
import '../../widgets/common/standard_page_header.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common/app_toast.dart';
import 'scheme_details_screen.dart';
import 'search_results_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_elevation.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/share_text.dart';
import '../../utils/app_text.dart';

class EligibilityResultsScreen extends StatefulWidget {
  const EligibilityResultsScreen({super.key});

  @override
  State<EligibilityResultsScreen> createState() =>
      _EligibilityResultsScreenState();
}

class _EligibilityResultsScreenState extends State<EligibilityResultsScreen> {
  bool _isSaving = false;
  bool _hasSavedThisSession = false;

  Future<void> _save(AppProvider provider, List<String> ids) async {
    setState(() => _isSaving = true);
    try {
      await provider.saveEligibilityResults(ids);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasSavedThisSession = true;
      });
      AppToast.showSuccess(context, context.l10n.eligResSavedToast);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.showError(context, context.l10n.eligResSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final l10n = context.l10n;
    final allMatches = provider.recommendedSchemes;

    // Eligible schemes are those with a match score > 0%
    final eligibleMatches = allMatches
        .where((entry) => entry.value.score > 0)
        .toList();

    final eligibleIds = eligibleMatches.map((e) => e.key.id).toSet();
    final isAlreadySaved =
        _hasSavedThisSession ||
        (provider.hasSavedEligibilityResults &&
            eligibleIds.isNotEmpty &&
            provider.savedEligibilitySchemeIds.toSet().containsAll(
              eligibleIds,
            ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardPageHeader(
        title: l10n.eligibilityResultsTitle,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              size: AppSize.icon,
              color: AppColors.primary,
            ),
            tooltip: l10n.shareResultsTooltip,
            onPressed: () async {
              final text =
                  '${l10n.eligResShareHeader}\n${eligibleMatches.map((e) => l10n.eligResShareItem(e.key.getName(provider.selectedLanguage), (e.value.score * 100).toInt())).take(5).join('\n')}';
              await shareText(
                context,
                text,
                copiedMessage: l10n.eligibilityResultsCopiedToClipboard,
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The result itself: how many schemes fit, in the
                    // page's one green.
                    Container(
                      margin: const EdgeInsets.all(AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppTagStyle.benefit.background,
                        borderRadius: AppRadius.lgAll,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.eligResGreatNews,
                            style: context.text.label.copyWith(
                              color: AppTagStyle.benefit.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: l10n.eligResEligibleForPrefix),
                                TextSpan(
                                  text: l10n.eligResGovernmentSchemesCount(
                                    eligibleMatches.length,
                                  ),
                                  style: TextStyle(
                                    color: AppTagStyle.benefit.text,
                                  ),
                                ),
                              ],
                            ),
                            style: context.text.headline.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.eligResBasedOnInfo,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.xs,
                        top: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.eligResRecommendedSchemes,
                              style: context.text.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (eligibleMatches.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SearchResultsScreen(
                                      title: l10n.eligResEligibleSchemesTitle,
                                      type: 'eligible',
                                      initialSchemes: eligibleMatches
                                          .map((e) => e.key)
                                          .toList(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(l10n.viewAll),
                            ),
                        ],
                      ),
                    ),

                    if (eligibleMatches.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(
                            color: AppColors.border,
                            width: AppSize.borderWidth,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: AppSize.tapTarget,
                              color: AppColors.iconMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.eligResNoMatches,
                              style: context.text.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              onPressed: () {
                                provider.updateTabIndex(2);
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              icon: const Icon(
                                Icons.explore_outlined,
                                size: AppSize.iconSm,
                              ),
                              label: Text(l10n.eligResExploreAll),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final entry in eligibleMatches)
                        SchemeCard(
                          scheme: entry.key,
                          result: entry.value,
                          isBookmarked: provider.bookmarkedIds.contains(
                            entry.key.id,
                          ),
                          onBookmarkToggle: () =>
                              provider.toggleBookmark(entry.key.id),
                          onTap: () {
                            provider.addToRecentlyViewed(entry.key.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SchemeDetailsScreen(scheme: entry.key),
                              ),
                            );
                          },
                        ),

                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        l10n.eligResSortedInfo,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar: the one primary action.
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppShadows.topBar,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: AppSize.borderWidth,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          eligibleMatches.isEmpty || _isSaving || isAlreadySaved
                          ? null
                          : () => _save(
                              provider,
                              eligibleMatches.map((e) => e.key.id).toList(),
                            ),
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: AppSize.icon,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : Icon(
                              isAlreadySaved
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_outline_rounded,
                              size: AppSize.icon,
                            ),
                      label: Text(
                        _isSaving
                            ? l10n.eligResSaving
                            : (isAlreadySaved
                                  ? l10n.eligResSavedToProfile
                                  : l10n.eligResSaveResults),
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
}
