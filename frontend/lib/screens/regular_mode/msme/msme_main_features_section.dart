import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

class MsmeMainFeaturesSection extends StatelessWidget {
  final String moduleId;
  final Color iconColor;

  const MsmeMainFeaturesSection({
    super.key,
    required this.moduleId,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    List<String> localizedFeatures = [];
    switch (moduleId) {
      case 'schemes':
        localizedFeatures = [
          l10n.msmeFeatureSchemes1,
          l10n.msmeFeatureSchemes2,
          l10n.msmeFeatureSchemes3,
          l10n.msmeFeatureSchemes4,
          l10n.msmeFeatureSchemes5,
          l10n.msmeFeatureSchemes6,
          l10n.msmeFeatureSchemes7,
          // 'Reminders for registration deadlines' and 'side-by-side
          // comparison' were removed (MS1/MS2): grepped the codebase and
          // found no deadline-tracking logic (only static 2024 seed-data
          // dates) and no comparison UI anywhere. Saving a scheme IS real
          // (AppProvider.toggleBookmark), so that half of the old combined
          // claim stays.
          l10n.msmeFeatureSchemes8,
        ];
        break;
      case 'finance':
        localizedFeatures = [
          l10n.msmeFeatureFinance1,
          l10n.msmeFeatureFinance2,
          l10n.msmeFeatureFinance3,
          l10n.msmeFeatureFinance4,
          l10n.msmeFeatureFinance5,
          l10n.msmeFeatureFinance6,
          l10n.msmeFeatureFinance7,
        ];
        break;
      case 'tax_gst':
        localizedFeatures = [
          l10n.msmeFeatureTaxGst1,
          l10n.msmeFeatureTaxGst2,
          l10n.msmeFeatureTaxGst3,
          l10n.msmeFeatureTaxGst4,
          // Verified real: msme_tax_gst_panel.dart has two live TextFields
          // (invoice amount, days delayed) wired to
          // _calculateLateInterest() -- an actual interactive calculator,
          // not just informational text. Kept.
          l10n.msmeFeatureTaxGst5,
          l10n.msmeFeatureTaxGst6,
          l10n.msmeFeatureTaxGst7,
        ];
        break;
      case 'export':
        localizedFeatures = [
          l10n.msmeFeatureExport1,
          l10n.msmeFeatureExport2,
          l10n.msmeFeatureExport3,
          l10n.msmeFeatureExport4,
          l10n.msmeFeatureExport5,
          l10n.msmeFeatureExport6,
          l10n.msmeFeatureExport7,
        ];
        break;
      case 'treds':
        localizedFeatures = [
          l10n.msmeFeatureTreds1,
          l10n.msmeFeatureTreds2,
          l10n.msmeFeatureTreds3,
          l10n.msmeFeatureTreds4,
          l10n.msmeFeatureTreds5,
          l10n.msmeFeatureTreds6,
          l10n.msmeFeatureTreds7,
        ];
        break;
      case 'csr':
        localizedFeatures = [
          l10n.msmeFeatureCsr1,
          l10n.msmeFeatureCsr2,
          l10n.msmeFeatureCsr3,
          l10n.msmeFeatureCsr4,
          l10n.msmeFeatureCsr5,
          l10n.msmeFeatureCsr6,
        ];
        break;
      case 'govt':
        localizedFeatures = [
          l10n.msmeFeatureGovt1,
          l10n.msmeFeatureGovt2,
          l10n.msmeFeatureGovt3,
          l10n.msmeFeatureGovt4,
          l10n.msmeFeatureGovt5,
          l10n.msmeFeatureGovt6,
        ];
        break;
      case 'institutions':
        localizedFeatures = [
          l10n.msmeFeatureInstitutions1,
          l10n.msmeFeatureInstitutions2,
          l10n.msmeFeatureInstitutions3,
          l10n.msmeFeatureInstitutions4,
          l10n.msmeFeatureInstitutions5,
          l10n.msmeFeatureInstitutions6,
        ];
        break;
      case 'udyam':
        localizedFeatures = [
          l10n.msmeFeatureUdyam1,
          l10n.msmeFeatureUdyam2,
          l10n.msmeFeatureUdyam3,
          l10n.msmeFeatureUdyam4,
          l10n.msmeFeatureUdyam5,
          l10n.msmeFeatureUdyam6,
        ];
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.msmeMainFeaturesInside,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...localizedFeatures.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: iconColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF334155),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
