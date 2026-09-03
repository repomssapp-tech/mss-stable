import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/scheme_card.dart';
import '../../widgets/standard_page_header.dart';
import '../../providers/app_state_provider.dart';
import '../../services/centralized_translator.dart';
import '../../l10n/l10n.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_toast.dart';
import 'scheme_details_screen.dart';
import '../../utils/app_spacing.dart';

class EligibilityResultsScreen extends StatelessWidget {
  const EligibilityResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isTa = provider.selectedLanguage == 'ta';
    final allMatches = provider.recommendedSchemes;

    // Eligible schemes are those with a match score > 0%
    final eligibleMatches = allMatches
        .where((entry) => entry.value.score > 0)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: StandardPageHeader(
        title: isTa
            ? CentralizedTranslator.instance.translate('Eligibility Results')
            : 'Eligibility Results',
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            onPressed: () async {
              final shareText =
                  'My Scheme Eligibility Results:\n${eligibleMatches.map((e) => '• ${e.key.name} (${(e.value.score * 100).toInt()}% Match)').take(5).join('\n')}';
              await Clipboard.setData(ClipboardData(text: shareText));
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  provider.selectedLanguage == 'ta'
                      ? 'தகுதி முடிவுகள் நகலெடுக்கப்பட்டது'
                      : 'Eligibility results copied to clipboard',
                );
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  // Custom Vector Success Illustration Stack
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
                    'Great News! 🎉',
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
                        const TextSpan(text: 'You are eligible for\n'),
                        TextSpan(
                          text: '${eligibleMatches.length} Government Schemes',
                          style: const TextStyle(color: Color(0xFF137C47)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    'based on the information you provided',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Recommended Schemes Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Recommended Schemes',
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Expand/View all matching schemes
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
                      child: Text(
                        'No matching schemes found. Adjust your profile details to expand matching rules.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFA3D9C9).withValues(alpha: 0.5),
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
                              'These schemes are sorted based on your profile match and eligibility criteria.',
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF137C47,
                      ), // Solid green theme button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      AppToast.showSuccess(
                        context,
                        'Results saved to your eligibility profile!',
                      );
                    },
                    icon: const Icon(Icons.bookmark_outline, size: 20),
                    label: Text(
                      'Save Results',
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
                        'Your information is secure and private',
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
        ],
      ),
    );
  }
}
