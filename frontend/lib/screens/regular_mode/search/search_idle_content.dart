import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/scheme_repository.dart';
import '../../../utils/app_spacing.dart';
import '../search_results_screen.dart';
import 'search_models.dart';
import 'shimmer_skeleton_card.dart';
import '../../../utils/app_text.dart';

/// Highlight summary card for the "For Me" feature shown in idle search view.
class SearchHighlightSummaryCard extends StatelessWidget {
  final bool isLoadingCounts;
  final int matchingProfileCount;
  final VoidCallback onTap;
  final double Function(double) scaledFontSize;

  const SearchHighlightSummaryCard({
    super.key,
    required this.isLoadingCounts,
    required this.matchingProfileCount,
    required this.onTap,
    required this.scaledFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFF6FF),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.forMe,
                          style: AppGoogleFonts.poppins(
                            fontSize: scaledFontSize(14.5),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.tight,
                          vertical: AppSpacing.hairline,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.activeBadge,
                          style: AppGoogleFonts.inter(
                            color: const Color(0xFF047857),
                            fontSize: scaledFontSize(8.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isLoadingCounts
                        ? context.l10n.calculatingMatches
                        : context.l10n.schemesMatchProfile(
                            matchingProfileCount,
                          ),
                    style: AppGoogleFonts.inter(
                      fontSize: scaledFontSize(10.5),
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 32,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          left: AppSpacing.xs,
                          right: AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 16,
                              height: 2.5,
                              color: const Color(0xFF93C5FD),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 20,
                              height: 2.5,
                              color: const Color(0xFF93C5FD),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 12,
                              height: 2.5,
                              color: const Color(0xFF93C5FD),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF2563EB),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category tile card shown in idle Browse Categories section.
class SearchCategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isLoadingCounts;
  final double Function(double) scaledFontSize;
  final FontWeight Function(FontWeight) scaledFontWeight;

  const SearchCategoryCard({
    super.key,
    required this.category,
    required this.isLoadingCounts,
    required this.scaledFontSize,
    required this.scaledFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category["iconBg"] as Color,
              ),
              alignment: Alignment.center,
              child: Icon(
                category["icon"] as IconData,
                color: category["iconColor"] as Color,
                size: 20,
              ),
            ),
            title: Text(
              getLocalizedTagOrCategory(
                category["title"] as String,
                provider.selectedLanguage,
              ),
              style: AppGoogleFonts.inter(
                fontSize: scaledFontSize(12.5),
                fontWeight: scaledFontWeight(FontWeight.bold),
                color: const Color(0xFF0F172A),
              ),
            ),
            subtitle: isLoadingCounts
                ? const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.hairline),
                    child: SearchSkeletonBar(width: 70, height: 10),
                  )
                : Text(
                    category["count"] as String,
                    style: AppGoogleFonts.inter(
                      fontSize: scaledFontSize(10),
                      color: const Color(0xFF64748B),
                    ),
                  ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 20,
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
  final VoidCallback onHighlightTap;
  final double Function(double) scaledFontSize;
  final FontWeight Function(FontWeight) scaledFontWeight;

  const SearchIdleContent({
    super.key,
    required this.categories,
    required this.isLoadingCounts,
    required this.matchingProfileCount,
    required this.onHighlightTap,
    required this.scaledFontSize,
    required this.scaledFontWeight,
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
          onTap: onHighlightTap,
          scaledFontSize: scaledFontSize,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.browseCategories,
          style: AppGoogleFonts.poppins(
            fontSize: scaledFontSize(16),
            fontWeight: scaledFontWeight(FontWeight.bold),
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...categories.map(
          (cat) => SearchCategoryCard(
            category: cat,
            isLoadingCounts: isLoadingCounts,
            scaledFontSize: scaledFontSize,
            scaledFontWeight: scaledFontWeight,
          ),
        ),
      ],
    );
  }
}
