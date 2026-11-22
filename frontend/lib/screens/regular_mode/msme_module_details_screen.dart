import 'package:flutter/material.dart';

import '../../services/catalog/centralized_translator.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/common/standard_page_header.dart';
import 'msme/msme_action_panels.dart';
import 'msme/msme_export_panel.dart';
import 'msme/msme_govt_hierarchy_panel.dart';
import 'msme/msme_header_section.dart';
import 'msme/msme_institutions_panel.dart';
import 'msme/msme_main_features_section.dart';
import 'msme/msme_tax_gst_panel.dart';
import 'msme/msme_treds_panel.dart';

export 'msme/msme_action_panels.dart';
export 'msme/msme_export_panel.dart';
export 'msme/msme_govt_hierarchy_panel.dart';
export 'msme/msme_header_section.dart';
export 'msme/msme_institutions_panel.dart';
export 'msme/msme_main_features_section.dart';
export 'msme/msme_tax_gst_panel.dart';
export 'msme/msme_treds_panel.dart';

class MSMEModuleDetailsScreen extends StatelessWidget {
  final String
  moduleId; // 'schemes', 'finance', 'tax_gst', 'export', 'treds', 'csr', 'govt', 'institutions', 'udyam'
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color themeColor;

  const MSMEModuleDetailsScreen({
    super.key,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final localizedTitle = CentralizedTranslator.instance.localizeFor(
      Localizations.localeOf(context).languageCode,
      title,
    );
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: localizedTitle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: StandardPageHeader(
          MediaQuery.textScalerOf(context),
          title: localizedTitle,
          titleIcon: Container(
            width: AppSize.avatarSm,
            height: AppSize.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: AppSize.iconLg),
          ),
          showDivider: true,
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MsmeHeaderSection(
                moduleId: moduleId,
                description: description,
                iconColor: iconColor,
                themeColor: themeColor,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // Interactive Feature Panel (The Core Function)
                    _buildInteractiveFeaturePanel(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Main Features Inside Section
                    MsmeMainFeaturesSection(
                      moduleId: moduleId,
                      iconColor: iconColor,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveFeaturePanel() {
    switch (moduleId) {
      case 'schemes':
        return SchemesInteractivePanel(iconColor: iconColor);
      case 'finance':
        return FinanceInteractivePanel(iconColor: iconColor);
      case 'tax_gst':
        return TaxGstInteractivePanel(iconColor: iconColor);
      case 'export':
        return ExportInteractivePanel(iconColor: iconColor);
      case 'treds':
        return TredsInteractivePanel(
          iconColor: iconColor,
          themeColor: themeColor,
        );
      case 'csr':
        return CsrInteractivePanel(iconColor: iconColor);
      case 'govt':
        return GovtInteractivePanel(iconColor: iconColor);
      case 'institutions':
        return InstitutionsInteractivePanel(iconColor: iconColor);
      case 'udyam':
        return UdyamInteractivePanel(
          iconColor: iconColor,
          themeColor: themeColor,
        );
      default:
        return const SizedBox();
    }
  }
}
