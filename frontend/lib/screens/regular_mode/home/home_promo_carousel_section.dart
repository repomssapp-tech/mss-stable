import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/assistant/smart_assessment_bottom_sheet.dart';
import '../../notifications_screen.dart';
import '../search_results_screen.dart';

class HomePromoCarouselSection extends StatefulWidget {
  const HomePromoCarouselSection({super.key});

  @override
  State<HomePromoCarouselSection> createState() =>
      _HomePromoCarouselSectionState();
}

class _HomePromoCarouselSectionState extends State<HomePromoCarouselSection> {
  final PageController _carouselPageController = PageController(
    viewportFraction: 0.88,
  );
  int _activeCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselPageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselPageController.hasClients) {
        final nextPage = (_activeCarouselIndex + 1) % itemCount;
        _carouselPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initCarouselTimer(int itemCount) {
    if (_carouselTimer != null) return;
    _startCarouselTimer(itemCount);
  }

  double _scaledFontSize(double baseSize) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta' ? baseSize * 0.88 : baseSize;
  }

  FontWeight _scaledFontWeight(FontWeight baseWeight) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedLanguage == 'ta') {
      if (baseWeight == FontWeight.bold || baseWeight == FontWeight.w700) {
        return FontWeight.w600;
      }
      if (baseWeight == FontWeight.w600) {
        return FontWeight.w500;
      }
    }
    return baseWeight;
  }

  String _getCarouselBadgeText(String raw) {
    if (raw == 'Alert') return context.l10n.carouselBadgeAlert;
    if (raw == 'New Scheme') return context.l10n.carouselBadgeNewScheme;
    if (raw == 'Notify') return context.l10n.carouselBadgeNotify;
    if (raw == 'Featured') return context.l10n.featured;
    return raw;
  }

  String _getCarouselTitle(String raw) {
    if (raw == 'Applications Closing Soon') {
      return context.l10n.carouselTitleApplicationsClosingSoon;
    }
    if (raw == 'PMEGP (Closing in 5 Days)') {
      return context.l10n.carouselTitlePmegpClosing;
    }
    if (raw == 'TN Export Promotion Scheme') {
      return context.l10n.carouselSubTnExport;
    }
    if (raw == 'New Scheme') return context.l10n.carouselTitleNewScheme;
    if (raw == 'Important Update') {
      return context.l10n.carouselTitleImportantUpdate;
    }
    if (raw == 'For Women Entrepreneurs') {
      return context.l10n.forWomenEntrepreneurs;
    }
    return raw;
  }

  String _getCarouselSubtitle(String raw) {
    if (raw == 'PMEGP · 2 days left') {
      return context.l10n.carouselSubPmegpDaysLeft;
    }
    if (raw == 'TN Export Promotion Scheme') {
      return context.l10n.carouselSubTnExport;
    }
    if (raw == 'UDYAM registration process updated') {
      return context.l10n.carouselSubUdyamProcess;
    }
    if (raw == 'Explore special funding schemes') {
      return context.l10n.exploreSpecialFundingSchemes;
    }
    return raw;
  }

  Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _handleCarouselTap(BuildContext context, Map<String, dynamic> item) {
    final route = item['target_route'] as String?;
    // The card names the browse page it opens; older cards without one keep
    // opening Business & MSME (test report NEW-04).
    final targetTitle = item['browse_title'] as String? ?? 'Business & MSME';
    final targetType = item['browse_type'] as String? ?? 'category';
    if (route == 'notifications') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    } else if (route == 'discover_results') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SearchResultsScreen(title: targetTitle, type: targetType),
        ),
      );
    } else if (route == 'draft_session') {
      SmartAssessmentBottomSheet.show(context, targetTitle, targetType, () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SearchResultsScreen(title: targetTitle, type: targetType),
          ),
        );
      });
    }
  }

  Widget _buildProgressGraphic(double progress) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard({
    required Gradient bgGradient,
    required Color borderColor,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required String title,
    String? subtitle,
    required Color titleColor,
    required VoidCallback onTap,
    required Widget rightGraphic,
    String? bgImage,
  }) {
    String displayTitle = title;
    String displaySubtitle = subtitle ?? '';
    if (displaySubtitle.isEmpty && title.contains(' — ')) {
      final parts = title.split(' — ');
      displayTitle = parts[0];
      displaySubtitle = parts[1];
    }

    final transTitle = CentralizedTranslator.instance.localize(displayTitle);
    final transSubtitle = CentralizedTranslator.instance.localize(
      displaySubtitle,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.tight,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: bgImage != null ? null : bgGradient,
            image: bgImage != null
                ? DecorationImage(
                    image: ResizeImage(AssetImage(bgImage), width: 1080),
                    fit: BoxFit.cover,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bgImage != null ? Colors.transparent : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor.withValues(
                          alpha: bgImage != null ? 0.9 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        CentralizedTranslator.instance.localizeTag(badgeText),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      transTitle,
                      style: GoogleFonts.poppins(
                        fontSize: _scaledFontSize(13.5),
                        fontWeight: _scaledFontWeight(FontWeight.bold),
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transSubtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        transSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: _scaledFontSize(10.0),
                          color: const Color(0xFF475569),
                          fontWeight: _scaledFontWeight(FontWeight.w600),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (bgImage == null)
                rightGraphic
              else
                // Reserve spacer on the right so text doesn't overlap the background image's built-in icon
                const SizedBox(width: 85),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int count, int activeIndex, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 12 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.hairline),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? color : const Color(0xFFE2E8F0),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final items = provider.carouselItems;

    // Initialize timer on build once items are fetched
    if (items.isNotEmpty) {
      _initCarouselTimer(items.length);
    }

    return Column(
      children: [
        SizedBox(
          height: 154,
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (index) {
              setState(() {
                _activeCarouselIndex = index;
              });
              // Restart timer to avoid sliding immediately after manual swipe
              _startCarouselTimer(items.length);
            },
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final gradientColors = [
                _parseHexColor(item['bg_gradient_start'] ?? '#FFF7ED'),
                _parseHexColor(item['bg_gradient_end'] ?? '#FFFFEDD5'),
              ];

              // Always ensure a rich design banner background image is used
              String? bgImage = item['bg_image'] as String?;
              if (bgImage == null || bgImage.isEmpty) {
                final fallbackBanners = [
                  'assets/images/Background/alert banner.webp',
                  'assets/images/Background/new scheme banner.webp',
                  'assets/images/Background/notification banner.webp',
                  'assets/images/Background/suggestion banner.webp',
                ];
                bgImage = fallbackBanners[index % fallbackBanners.length];
              }

              // Since the 4 banner images have built-in illustrations on the right,
              // only render rightGraphic if it's a draft session progress or no bgImage
              Widget rightGraphic = const SizedBox();
              if (item['graphic_type'] == 'progress') {
                final double progress =
                    (item['progress'] as num?)?.toDouble() ?? 0.0;
                rightGraphic = _buildProgressGraphic(progress);
              }

              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.88,
                  child: _buildCarouselCard(
                    bgGradient: LinearGradient(colors: gradientColors),
                    borderColor: _parseHexColor(
                      item['badge_bg_color'] ?? '#E2E8F0',
                    ),
                    badgeText: _getCarouselBadgeText(item['badge_text'] ?? ''),
                    badgeTextColor: _parseHexColor(
                      item['badge_text_color'] ?? '#0F172A',
                    ),
                    badgeBgColor: _parseHexColor(
                      item['badge_bg_color'] ?? '#F1F5F9',
                    ),
                    title: _getCarouselTitle(item['title'] ?? ''),
                    subtitle: _getCarouselSubtitle(item['subtitle'] ?? ''),
                    titleColor: const Color(0xFF1E293B),
                    onTap: () {
                      _handleCarouselTap(context, item);
                    },
                    rightGraphic: rightGraphic,
                    bgImage: bgImage,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDotIndicator(
          items.length,
          _activeCarouselIndex,
          const Color(0xFF2563EB),
        ),
      ],
    );
  }
}
