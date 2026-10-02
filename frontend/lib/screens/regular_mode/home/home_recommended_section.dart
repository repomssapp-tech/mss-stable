import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../basic_profile_screen.dart';
import '../scheme_details_screen.dart';

class HomeRecommendedSection extends StatefulWidget {
  final List<Scheme>? schemes;
  final AppProvider? provider;

  const HomeRecommendedSection({
    super.key,
    this.schemes,
    this.provider,
  });

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
    if (widget.schemes != null) {
      scoredSchemes = widget.schemes!.map((s) => MapEntry(s, null)).toList();
    } else {
      scoredSchemes = appProvider.recommendedSchemes
          .where((entry) => entry.value.score > 0)
          .take(5)
          .map((entry) => MapEntry(entry.key, entry.value.percentage))
          .toList();
    }

    final List<Map<String, dynamic>> items = [
      for (final entry in scoredSchemes)
        () {
          final sRaw = entry.key;
          final s = sRaw.toLocalized(appProvider.selectedLanguage);
          return {
            'id': sRaw.id,
            'title': s.name,
            'subtitle': s.overview.isNotEmpty ? s.overview : s.objectives,
            'matchPercentage': entry.value,
            'isBookmarked':
                appProvider.bookmarkedIds.contains(sRaw.id) ||
                appProvider.bookmarkedIds.contains(sRaw.schemeCode),
            'chips': s.glanceChips.take(3).toList(),
            'location': s.state.isNotEmpty ? s.state : context.l10n.regionAllIndia,
            'scheme': sRaw,
          };
        }(),
    ];

    // No other Home section (promo carousel, journey, MSME support) gates
    // its content on `schemesLoading`, so this doesn't invent a new loading
    // branch either -- it shows the empty state whenever there's nothing to
    // recommend, same as every sibling section does with its own data.
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.recommendedForYou,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 225,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final Scheme? schemeObj = item['scheme'] as Scheme?;
              final isBookmarked = item['isBookmarked'] as bool;
              final matchPercentage = item['matchPercentage'] as int?;
              final isTa = appProvider.selectedLanguage == 'ta';

              final double screenWidth = MediaQuery.of(context).size.width;
              const double spacing = 12.0;
              final double cardWidth = (screenWidth - 32 - spacing) / 1.08;

              final title = item['title'] as String;
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

              return GestureDetector(
                onTap: () {
                  if (schemeObj != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailsScreen(scheme: schemeObj),
                      ),
                    );
                  }
                },
                child: Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(
                    right: AppSpacing.md,
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match & Bookmark Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Only shown when this item carries a real
                          // RecommendationResult score -- never fabricated.
                          if (matchPercentage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FitOneLine(
                                child: Text(
                                  context.l10n.matchPercentageFormat(
                                    matchPercentage,
                                  ),
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF15803D),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          const SizedBox(width: AppSpacing.tight),
                          GestureDetector(
                            onTap: () {
                              // H7: bookmark by `id`, the single canonical
                              // key everywhere -- `schemeCode` always
                              // differs from `id` in the real catalog.
                              final schemeId = item['id'] as String;
                              appProvider.toggleBookmark(schemeId);
                            },
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  shortForm,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (fullName.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    "($fullName)",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Chips Row
                      Builder(
                        builder: (context) {
                          final rawChipsList = List<String>.from(
                            item['chips'] as List<String>,
                          )..sort((a, b) => a.length.compareTo(b.length));
                          final chipsList = isTa
                              ? rawChipsList
                                    .map(
                                      (t) => CentralizedTranslator.instance
                                          .translateTag(t),
                                    )
                                    .toList()
                              : rawChipsList;
                          return Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: chipsList.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.tight,
                                  vertical: AppSpacing.hairline,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.recommendedForYou,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.homeRecommendationsEmptyMessage,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BasicProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.completeProfile,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
