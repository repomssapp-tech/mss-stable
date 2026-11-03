import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import 'document_checklist_sheet.dart';
import 'dpiit_checklist_sheet.dart';
import 'emi_calculator_sheet.dart';
import 'gst_calculator_sheet.dart';
import 'subsidy_estimator_sheet.dart';
import 'udyam_classifier_sheet.dart';
import 'valuation_estimator_sheet.dart';
import '../../../utils/app_text.dart';

class CategoriesBusinessUtilitiesSection extends StatelessWidget {
  const CategoriesBusinessUtilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Must listen: this widget is instantiated `const` by its parent
    // (categories_screen.dart), so without an InheritedWidget dependency
    // here it would never rebuild on a language change -- a `listen: false`
    // read here previously went stale indefinitely (bug: Discover's
    // "Business Utilities & Tools" kept rendering in the old language).
    Provider.of<AppProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            context.l10n.discoverUtilitiesTitle,
            style: context.text.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Every card takes the tallest one's height, which grows with the
        // user's font size (issue #144).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategoryUtilityCard(
                  icon: Icons.domain_verification_outlined,
                  title: context.l10n.utilUdyamTitle,
                  desc: context.l10n.utilUdyamDesc,
                  onTap: () => showUdyamClassifierSheet(context),
                ),
                CategoryUtilityCard(
                  icon: Icons.calculate_outlined,
                  title: context.l10n.utilSubsidyTitle,
                  desc: context.l10n.utilSubsidyDesc,
                  onTap: () => showSubsidyEstimatorSheet(context),
                ),
                CategoryUtilityCard(
                  icon: Icons.percent_outlined,
                  title: context.l10n.utilGstTitle,
                  desc: context.l10n.utilGstDesc,
                  onTap: () => showGstCalculatorSheet(context),
                ),
                CategoryUtilityCard(
                  icon: Icons.currency_rupee_rounded,
                  title: context.l10n.utilEmiTitle,
                  desc: context.l10n.utilEmiDesc,
                  onTap: () => showEmiCalculatorSheet(context),
                ),
                CategoryUtilityCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: context.l10n.utilDpiitTitle,
                  desc: context.l10n.utilDpiitDesc,
                  onTap: () => showDpiitChecklistSheet(context),
                ),
                CategoryUtilityCard(
                  icon: Icons.trending_up_outlined,
                  title: context.l10n.utilValuationTitle,
                  desc: context.l10n.utilValuationDesc,
                  onTap: () => showValuationEstimatorSheet(context),
                ),
                CategoryUtilityCard(
                  icon: Icons.rule_folder_outlined,
                  title: context.l10n.utilDocChecklistTitle,
                  desc: context.l10n.utilDocChecklistDesc,
                  onTap: () => showDocumentChecklistSheet(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryUtilityCard extends StatelessWidget {
  const CategoryUtilityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  /// Every utility card's width.
  static const double width = 150;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: width),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.primary, size: AppSize.icon),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    style: context.text.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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
