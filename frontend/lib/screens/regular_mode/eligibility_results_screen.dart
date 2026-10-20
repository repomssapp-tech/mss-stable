import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/scheme/scheme_card.dart';
import '../../widgets/common/standard_page_header.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/app_toast.dart';
import 'scheme_details_screen.dart';
import 'search_results_screen.dart';
import '../../utils/app_spacing.dart';

class EligibilityResultsScreen extends StatefulWidget {
  const EligibilityResultsScreen({super.key});

  @override
  State<EligibilityResultsScreen> createState() =>
      _EligibilityResultsScreenState();
}

class _EligibilityResultsScreenState extends State<EligibilityResultsScreen> {
  bool _isSaving = false;
  bool _hasSavedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: StandardPageHeader(
        title: context.l10n.eligibilityResultsTitle,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            tooltip: context.l10n.shareResultsTooltip,
            onPressed: () async {
              final shareText =
                  '${context.l10n.eligResShareHeader}\n${eligibleMatches.map((e) => context.l10n.eligResShareItem(e.key.getName(provider.selectedLanguage), (e.value.score * 100).toInt())).take(5).join('\n')}';
              await Clipboard.setData(ClipboardData(text: shareText));
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  context.l10n.eligibilityResultsCopiedToClipboard,
                );
              }
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
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    // Image-based Success Illustration from assets
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Image.asset(
                        'assets/images/Background/suggestion banner.webp',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Great News Header
                    Text(
                      context.l10n.eligResGreatNews,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF137C47),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        children: [
                          TextSpan(text: context.l10n.eligResEligibleForPrefix),
                          TextSpan(
                            text: context.l10n.eligResGovernmentSchemesCount(
                              eligibleMatches.length,
                            ),
                            style: const TextStyle(color: Color(0xFF137C47)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      context.l10n.eligResBasedOnInfo,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Recommended Schemes Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              context.l10n.eligResRecommendedSchemes,
                              softWrap: true,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (eligibleMatches.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SearchResultsScreen(
                                      title: context
                                          .l10n
                                          .eligResEligibleSchemesTitle,
                                      type: 'eligible',
                                      initialSchemes: eligibleMatches
                                          .map((e) => e.key)
                                          .toList(),
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: FitOneLine(
                                      child: Text(
                                        context.l10n.viewAll,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF137C47),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.hairline),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xFF137C47),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Recommended cards list
                    if (eligibleMatches.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(AppSpacing.xxl),
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              context.l10n.eligResNoMatches,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.4,
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.explore_outlined,
                                size: 18,
                              ),
                              label: Text(
                                context.l10n.eligResExploreAll,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...eligibleMatches.map(
                        (entry) => SchemeCard(
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
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // Info Alert Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFA3D9C9,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF137C47),
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.l10n.eligResSortedInfo,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF137C47),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Bottom Bar Action Panel
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAlreadySaved
                              ? const Color(0xFF0F766E)
                              : const Color(0xFF137C47),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isAlreadySaved
                              ? const Color(0xFF0F766E)
                              : null,
                          disabledForegroundColor: isAlreadySaved
                              ? Colors.white
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            eligibleMatches.isEmpty ||
                                _isSaving ||
                                isAlreadySaved
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  final ids = eligibleMatches
                                      .map((e) => e.key.id)
                                      .toList();
                                  await provider.saveEligibilityResults(ids);
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isSaving = false;
                                    _hasSavedThisSession = true;
                                  });
                                  AppToast.showSuccess(
                                    context,
                                    context.l10n.eligResSavedToast,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  setState(() => _isSaving = false);
                                  AppToast.showError(
                                    context,
                                    context.l10n.eligResSaveFailed,
                                  );
                                }
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isAlreadySaved
                                    ? Icons.bookmark_added_rounded
                                    : Icons.bookmark_outline,
                                size: 20,
                              ),
                        label: Text(
                          _isSaving
                              ? context.l10n.eligResSaving
                              : (isAlreadySaved
                                    ? context.l10n.eligResSavedToProfile
                                    : context.l10n.eligResSaveResults),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            context.l10n.eligResSecurePrivate,
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
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
