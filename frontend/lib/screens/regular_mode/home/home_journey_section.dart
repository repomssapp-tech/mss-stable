import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/scheme_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../msme_module_details_screen.dart';
import '../search_results_screen.dart';

class HomeJourneySection extends StatelessWidget {
  const HomeJourneySection({super.key});

  /// Each card's width; every card in the row shares the tallest one's height.
  static const double cardWidth = 104;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.whatWouldYouLikeToDoToday,
          style: context.text.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildJourneyActionCard(
                  context: context,
                  title: context.l10n.exportSupport,
                  icon: Icons.public_rounded,
                  moduleId: 'export',
                ),
                _buildJourneyActionCard(
                  context: context,
                  title: context.l10n.growBusiness,
                  icon: Icons.trending_up_rounded,
                  categoryName: 'Business & MSME',
                ),
                _buildJourneyActionCard(
                  context: context,
                  title: context.l10n.registerUdyam,
                  icon: Icons.app_registration_rounded,
                  moduleId: 'udyam',
                ),
                _buildJourneyActionCard(
                  context: context,
                  title: context.l10n.findFunding,
                  icon: Icons.currency_rupee_rounded,
                  categoryName: 'Business Loans & Credit',
                ),
                _buildJourneyActionCard(
                  context: context,
                  title: context.l10n.startABusiness,
                  icon: Icons.storefront_rounded,
                  categoryName: 'Startup',
                  last: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(
    BuildContext context, {
    required String title,
    String? moduleId,
    String? categoryName,
  }) async {
    // Route on the language-stable moduleId / categoryName, never the
    // localized `title` -- in Tamil a title like "உத்யம் பதிவு" contains
    // no "udyam"/"export" substring, so the old checks silently fell
    // through and every card returned the same generic fallback list.

    // 1. Register Udyam -> interactive Udyam Registration module
    if (moduleId == 'udyam') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MSMEModuleDetailsScreen(
            moduleId: 'udyam',
            title: context.l10n.registerUdyam,
            description: context.l10n.udyamModuleDescription,
            icon: Icons.app_registration_rounded,
            iconColor: AppColors.primary,
            themeColor: AppColors.primarySoft,
          ),
        ),
      );
      return;
    }

    // 2. Export Support -> Export Readiness module
    if (moduleId == 'export') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MSMEModuleDetailsScreen(
            moduleId: 'export',
            title: context.l10n.exportSupport,
            description: context.l10n.exportModuleDescription,
            icon: Icons.public_rounded,
            iconColor: const Color(0xFF047857),
            themeColor: const Color(0xFFECFDF5),
          ),
        ),
      );
      return;
    }

    final schemes = await SchemeRepository.instance.getSchemesByCategory(
      categoryName ?? title,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          title: title,
          type: 'category',
          initialSchemes: schemes,
        ),
      ),
    );
  }

  Widget _buildJourneyActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? moduleId,
    String? categoryName,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: last ? AppSpacing.none : AppSpacing.md),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(
            context,
            title: title,
            moduleId: moduleId,
            categoryName: categoryName,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: cardWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              // Icon on top, label under it; labels wrap at word breaks and
              // the row's shared height keeps every icon on one line.
              child: Column(
                children: [
                  Container(
                    width: AppSize.avatarSm,
                    height: AppSize.avatarSm,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: AppSize.iconLg,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
