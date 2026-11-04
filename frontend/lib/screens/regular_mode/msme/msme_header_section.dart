import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class MsmeHeaderSection extends StatelessWidget {
  final String moduleId;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color themeColor;

  const MsmeHeaderSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModuleHeader(context),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.xxl,
          ),
          child: _buildWhatUserGets(context),
        ),
      ],
    );
  }

  Widget _buildModuleHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        CentralizedTranslator.instance.localize(title),
                        style: context.text.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CentralizedTranslator.instance.localize(description),
                      style: context.text.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatUserGets(BuildContext context) {
    String valueText = '';
    switch (moduleId) {
      case 'schemes':
        valueText =
            'Find government subsidies, grants, and registration schemes you are eligible for, customized to your profile details.';
        break;
      case 'finance':
        valueText =
            'Access loan options, credit guarantees, equipment loans, and SIDBI schemes to finance and expand your enterprise.';
        break;
      case 'tax_gst':
        valueText =
            'Learn about corporate tax reductions, GST threshold relief, composition schemes, and legal interest claims for payment delays.';
        break;
      case 'export':
        valueText =
            'Discover export incentives, financial credits, credit insurance, and regulatory agencies to expand your business globally.';
        break;
      case 'treds':
        valueText =
            'Discount your trade invoices through online bidding with banks and financial institutions to get immediate cash flow without collateral.';
        break;
      case 'csr':
        valueText =
            'Connect with corporate social responsibility (CSR) programs, tech incubation grants, and specialized skill development clusters.';
        break;
      case 'govt':
        valueText =
            'Understand government department responsibilities and reach the appropriate authority (Central Ministry, State Directorate, or District DIC) for business help.';
        break;
      case 'institutions':
        valueText =
            'Identify the right institutions (SIDBI, NSIC, DIC, KVIC, etc.) and explore their service catalogs, contact avenues, and programs.';
        break;
      case 'udyam':
        valueText =
            'Complete official MSME Udyam registration for free to unlock priority sector bank loans, 15% capital subsidies, collateral-free credit (CGTMSE), and Government tender exemptions.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.05),
            themeColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: iconColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  context.l10n.msmeWhatTheUserGets,
                  softWrap: true,
                  style: context.text.label.copyWith(color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CentralizedTranslator.instance.localize(valueText),
            style: context.text.button.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
