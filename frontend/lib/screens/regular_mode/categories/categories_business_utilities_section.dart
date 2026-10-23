import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../l10n/l10n.dart';
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
    final provider = Provider.of<AppProvider>(context);
    final isTa = provider.selectedLanguage == 'ta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            context.l10n.discoverUtilitiesTitle,
            style: AppGoogleFonts.poppins(
              fontSize: isTa ? 14.0 : 15.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          // Icon and padding are fixed; the two text lines grow with the
          // user's font size (issue #144).
          height: 50 + MediaQuery.textScalerOf(context).scale(48),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              CategoryUtilityCard(
                icon: Icons.domain_verification,
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
                icon: Icons.monetization_on_outlined,
                title: context.l10n.utilEmiTitle,
                desc: context.l10n.utilEmiDesc,
                onTap: () => showEmiCalculatorSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.rocket_launch_outlined,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(height: AppSpacing.tight),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppGoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppGoogleFonts.inter(
                  fontSize: 8.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
