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

    List<Scheme> schemesList;
    if (widget.schemes != null) {
      schemesList = widget.schemes!;
    } else {
      final recommendedScored = appProvider.recommendedSchemes
          .where((entry) => entry.value.score > 0)
          .toList();
      schemesList =
          (recommendedScored.isNotEmpty
                  ? recommendedScored
                  : appProvider.recommendedSchemes)
              .take(5)
              .map((entry) => entry.key)
              .toList();
    }

    final List<Map<String, dynamic>> items = [];

    if (schemesList.isNotEmpty) {
      for (int i = 0; i < schemesList.length; i++) {
        final sRaw = schemesList[i];
        final s = sRaw.toLocalized(appProvider.selectedLanguage);
        final match = 95 - (i * 3);
        items.add({
          'id': sRaw.id,
          'title': s.name,
          'subtitle': s.overview.isNotEmpty ? s.overview : s.objectives,
          'match': context.l10n.matchPercentageFormat(match),
          'isBookmarked':
              appProvider.bookmarkedIds.contains(sRaw.id) ||
              appProvider.bookmarkedIds.contains(sRaw.schemeCode),
          'schemeCode': sRaw.schemeCode,
          'chips': s.glanceChips.take(3).toList(),
          'location': s.state.isNotEmpty ? s.state : 'All India',
          'scheme': sRaw,
        });
      }
    } else {
      items.addAll([
        {
          'id': 'pmegp_loan',
          'title': 'PMEGP Loan',
          'subtitle': "Prime Minister's Employment Generation Programme",
          'match': context.l10n.matchPercentageFormat(95),
          'isBookmarked': false,
          'schemeCode': 'PMEGP',
          'chips': ['Central Scheme', 'Loan', 'Subsidy'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'PMEGP',
          'logoColor': const Color(0xFF9A3412),
        },
        {
          'id': 'msme_loan',
          'title': 'MSME Loan',
          'subtitle': 'Credit Guarantee Fund Trust for MSEs',
          'match': context.l10n.matchPercentageFormat(92),
          'isBookmarked': true,
          'schemeCode': 'MSME',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'MSME',
          'logoColor': const Color(0xFF1E3A8A),
        },
        {
          'id': 'standup_india',
          'title': 'Stand Up India',
          'subtitle': 'Bank Loans for SC/ST & Women Entrepreneurs',
          'match': context.l10n.matchPercentageFormat(88),
          'isBookmarked': false,
          'schemeCode': 'SUI',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'UP India',
          'logoColor': const Color(0xFF15803D),
        },
        {
          'id': 'mudra_loan',
          'title': 'Mudra Loan',
          'subtitle': 'Loans up to ₹10 Lakhs Non-Corporate Business',
          'match': context.l10n.matchPercentageFormat(85),
          'isBookmarked': false,
          'schemeCode': 'Mudra',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'Mudra',
          'logoColor': const Color(0xFFB91C1C),
        },
      ]);
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
                                item['match'] as String,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF15803D),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.tight),
                          GestureDetector(
                            onTap: () {
                              final sCode = item['schemeCode'] as String;
                              appProvider.toggleBookmark(sCode);
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
}
