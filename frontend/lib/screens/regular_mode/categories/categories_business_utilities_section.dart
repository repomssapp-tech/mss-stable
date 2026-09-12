import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import 'document_checklist_sheet.dart';
import 'dpiit_checklist_sheet.dart';
import 'emi_calculator_sheet.dart';
import 'gst_calculator_sheet.dart';
import 'subsidy_estimator_sheet.dart';
import 'udyam_classifier_sheet.dart';
import 'valuation_estimator_sheet.dart';

class CategoriesBusinessUtilitiesSection extends StatelessWidget {
  const CategoriesBusinessUtilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isTa = provider.selectedLanguage == 'ta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            isTa
                ? CentralizedTranslator.instance.translate(
                    'Business Utilities & Tools',
                  )
                : 'Business Utilities & Tools',
            style: GoogleFonts.poppins(
              fontSize: isTa ? 14.0 : 15.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              CategoryUtilityCard(
                icon: Icons.domain_verification,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Udyam Classifier',
                      )
                    : 'Udyam Classifier',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Check MSME tier',
                      )
                    : 'Check MSME tier',
                onTap: () => showUdyamClassifierSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.calculate_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Subsidy Estimator',
                      )
                    : 'Subsidy Estimator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Machinery subsidies',
                      )
                    : 'Machinery subsidies',
                onTap: () => showSubsidyEstimatorSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.percent_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate('GST Calculator')
                    : 'GST Calculator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Compute GST invoice',
                      )
                    : 'Compute GST invoice',
                onTap: () => showGstCalculatorSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.monetization_on_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate('EMI Calculator')
                    : 'EMI Calculator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Calculate loan EMIs',
                      )
                    : 'Calculate loan EMIs',
                onTap: () => showEmiCalculatorSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.rocket_launch_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'DPIIT Eligibility',
                      )
                    : 'DPIIT Eligibility',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Check startup criteria',
                      )
                    : 'Check startup criteria',
                onTap: () => showDpiitChecklistSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.trending_up_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Valuation Estimator',
                      )
                    : 'Valuation Estimator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Seed valuation ranges',
                      )
                    : 'Seed valuation ranges',
                onTap: () => showValuationEstimatorSheet(context),
              ),
              CategoryUtilityCard(
                icon: Icons.rule_folder_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate('Doc Checklist')
                    : 'Doc Checklist',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Business setup docs',
                      )
                    : 'Business setup docs',
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
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
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
