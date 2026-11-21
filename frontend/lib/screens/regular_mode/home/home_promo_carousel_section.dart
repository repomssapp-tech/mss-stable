import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../services/catalog/scheme_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_elevation.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/assistant/smart_assessment_bottom_sheet.dart';
import '../../notifications_screen.dart';
import '../search_results_screen.dart';
import '../questionnaire_results_screen.dart';
import '../categories/discover_counts.dart';
import '../../../utils/app_text.dart';

/// The promotions cards shown in Featured's place when there is nothing to
/// feature yet. Cards come from `/v1/promotions` (published by the admin
/// panel), or the one evergreen fallback in `app_state_seed_data.dart`. They
/// move only when swiped.
class HomePromoCarouselSection extends StatefulWidget {
  const HomePromoCarouselSection({super.key});

  /// Card height at the default text size; it grows with the text scale.
  static const double cardHeight = 168;

  @override
  State<HomePromoCarouselSection> createState() =>
      _HomePromoCarouselSectionState();
}

class _HomePromoCarouselSectionState extends State<HomePromoCarouselSection> {
  // Full width: one card fills the content area (no peeking neighbours).
  final PageController _carouselPageController = PageController();
  int _activeCarouselIndex = 0;

  @override
  void dispose() {
    _carouselPageController.dispose();
    super.dispose();
  }

  String _getCarouselBadgeText(String raw) {
    if (raw == 'Alert') return context.l10n.carouselBadgeAlert;
    if (raw == 'New Scheme') return context.l10n.carouselBadgeNewScheme;
    if (raw == 'Notify') return context.l10n.carouselBadgeNotify;
    if (raw == 'Featured') return context.l10n.featured;
    return raw;
  }

  // These translate server card text that matches exactly; the facts in it
  // (deadlines, scheme names) come from the published card, never from here.
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

  /// A card's badge colour as published, or null when it is missing or not a
  /// valid `#RRGGBB` / `#AARRGGBB` value.
  Color? _parseHexColor(Object? hexString) {
    if (hexString is! String) return null;
    final hex = hexString.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    final value = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
    return value == null ? null : Color(value);
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
      SmartAssessmentBottomSheet.show(context, targetTitle, targetType, (
        answers,
      ) async {
        final all = await SchemeRepository.instance.getAllSchemes();
        final schemes = DiscoverCounts.schemesFor(targetTitle, targetType, all);
        if (!context.mounted) return;
        if (schemes.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionnaireResultsScreen(
                title: targetTitle,
                cardType: targetType,
                schemes: schemes,
                catalogSchemes: all,
                answers: answers,
              ),
            ),
          );
          return;
        }
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
      width: AppSize.avatar,
      height: AppSize.avatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: AppSize.avatar - AppSpacing.sm,
            height: AppSize.avatar - AppSpacing.sm,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryTint,
                width: AppSize.borderWidth,
              ),
              boxShadow: AppShadows.card,
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppColors.primarySoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: context.text.label.copyWith(color: AppColors.primaryDeep),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard({
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required String title,
    String? subtitle,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: bgImage != null
                ? null
                : Border.all(
                    color: AppColors.border,
                    width: AppSize.borderWidth,
                  ),
            image: bgImage != null
                ? DecorationImage(
                    image: ResizeImage(AssetImage(bgImage), width: 1080),
                    fit: BoxFit.cover,
                    // The art sits on the right; keep it in view on tall cards.
                    alignment: Alignment.centerRight,
                  )
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (badgeText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              CentralizedTranslator.instance.localizeTag(
                                badgeText,
                              ),
                              style: context.text.label.copyWith(
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Text(
                          transTitle,
                          style: context.text.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (transSubtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            transSubtitle,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textSecondary,
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
                    // Keeps the text clear of the banner art on the right.
                    const SizedBox(width: 85), // spacing-ok: banner art width
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int count, int activeIndex) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: still ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: isActive ? AppSpacing.md : AppSpacing.tight,
          height: AppSpacing.tight,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.hairline),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillAll,
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final items = provider.carouselItems;
    if (_activeCarouselIndex >= items.length) _activeCarouselIndex = 0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Column(
      children: [
        SizedBox(
          // spacing-ok: card height, not spacing
          height:
              HomePromoCarouselSection.cardHeight * textScale.clamp(1.0, 1.6),
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (index) =>
                setState(() => _activeCarouselIndex = index),
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              // Every card gets one of the designed banners as its background.
              String? bgImage = item['bg_image'] as String?;
              if (bgImage == null || bgImage.isEmpty) {
                const fallbackBanners = [
                  'assets/images/Background/alert banner.webp',
                  'assets/images/Background/new scheme banner.webp',
                  'assets/images/Background/notification banner.webp',
                  'assets/images/Background/suggestion banner.webp',
                ];
                bgImage = fallbackBanners[index % fallbackBanners.length];
              }

              // The banners carry their own art on the right, so a graphic is
              // drawn only for a draft-progress card without one.
              Widget rightGraphic = const SizedBox();
              if (item['graphic_type'] == 'progress') {
                final double progress =
                    (item['progress'] as num?)?.toDouble() ?? 0.0;
                rightGraphic = _buildProgressGraphic(progress);
              }

              return _buildCarouselCard(
                badgeText: _getCarouselBadgeText(item['badge_text'] ?? ''),
                badgeTextColor:
                    _parseHexColor(item['badge_text_color']) ??
                    AppTagStyle.level.text,
                badgeBgColor:
                    _parseHexColor(item['badge_bg_color']) ??
                    AppTagStyle.level.background,
                title: _getCarouselTitle(item['title'] ?? ''),
                subtitle: _getCarouselSubtitle(item['subtitle'] ?? ''),
                onTap: () => _handleCarouselTap(context, item),
                rightGraphic: rightGraphic,
                bgImage: bgImage,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDotIndicator(items.length, _activeCarouselIndex),
      ],
    );
  }
}
