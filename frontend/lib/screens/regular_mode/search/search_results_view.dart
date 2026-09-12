import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../engine/recommendation_engine.dart';
import '../../../l10n/l10n.dart';
import '../../../models/scheme_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/scheme/scheme_card.dart';
import '../scheme_details_screen.dart';
import 'search_models.dart';
import 'shimmer_skeleton_card.dart';

/// Shimmer skeleton placeholder list while search query or filters are loading.
class SearchLoadingSkeleton extends StatelessWidget {
  const SearchLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey("LoadingContent"),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const ShimmerSkeletonCard();
      },
    );
  }
}

/// Search results list displaying scheme cards and empty state representations.
class SearchResultsList extends StatelessWidget {
  final List<Scheme> searchResults;
  final String queryText;
  final bool isForMe;
  final ForMeEmptyState forMeEmptyState;
  final AppProvider provider;
  final double Function(double) scaledFontSize;

  const SearchResultsList({
    super.key,
    required this.searchResults,
    required this.queryText,
    required this.isForMe,
    required this.forMeEmptyState,
    required this.provider,
    required this.scaledFontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty) {
      final bool forMeNeedsProfile =
          isForMe && forMeEmptyState == ForMeEmptyState.completeProfile;
      final bool forMeNoMatches =
          isForMe && forMeEmptyState != ForMeEmptyState.completeProfile;

      final String title;
      final String subtitle;
      final IconData icon;
      if (forMeNeedsProfile) {
        icon = Icons.assignment_ind_outlined;
        title = context.l10n.searchCompleteProfileTitle;
        subtitle = context.l10n.searchCompleteProfileSubtitle;
      } else if (forMeNoMatches) {
        icon = Icons.search_off_rounded;
        title = context.l10n.searchNoProfileMatchesTitle;
        subtitle = context.l10n.searchNoProfileMatchesSubtitle;
      } else if (queryText.isNotEmpty) {
        icon = Icons.search_off_rounded;
        title = context.l10n.noSchemesFound(queryText);
        subtitle = context.l10n.tryDifferentKeyword;
      } else {
        icon = Icons.filter_alt_off_outlined;
        title = context.l10n.searchNoFilterMatchesTitle;
        subtitle = context.l10n.searchNoFilterMatchesSubtitle;
      }

      return ListView(
        key: const ValueKey('ResultsContent'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 48,
        ),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.grey[400]),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: scaledFontSize(15),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: scaledFontSize(12),
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: const ValueKey('ResultsContent'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      physics: const ClampingScrollPhysics(),
      itemCount: searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final titleText = isForMe
              ? context.l10n.eligibleSchemesForYouCount(searchResults.length)
              : context.l10n.matchingSchemesCount(searchResults.length);

          final subtitleText = isForMe
              ? context.l10n.matchedStrictlyAgainstProfile
              : (queryText.isNotEmpty
                    ? context.l10n.searchBestMatchesForQuery(queryText)
                    : context.l10n.searchBestMatchesForCriteria);

          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitleText,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        final scheme = searchResults[index - 1];
        final recResult = RecommendationEngine.evaluate(
          provider.profile,
          scheme,
        );

        return SchemeCard(
          scheme: scheme,
          result: recResult,
          isBookmarked: provider.bookmarkedIds.contains(scheme.id),
          onBookmarkToggle: () => provider.toggleBookmark(scheme.id),
          showActions: false,
          showMatchPercentage: isForMe,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
        );
      },
    );
  }
}
