import 'package:flutter/material.dart';

import '../../services/catalog/centralized_translator.dart';
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
    // The app bar title is empty (see below), so name the route for screen
    // readers with the same localized text the header card shows.
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: CentralizedTranslator.instance.localize(title),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        // The header card below carries the module title; the bar keeps only
        // the back arrow so the title is not shown twice.
        appBar: const StandardPageHeader(title: '', elevation: 1),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Module Header Card & What the User Gets
              MsmeHeaderSection(
                moduleId: moduleId,
                title: title,
                description: description,
                icon: icon,
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
