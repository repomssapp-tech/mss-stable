import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../msme_module_details_screen.dart';
import '../../../utils/app_text.dart';

class HomeMsmeSupportSection extends StatelessWidget {
  const HomeMsmeSupportSection({super.key});

  /// Each card's width; every card in the row shares the tallest one's height.
  static const double cardWidth = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // `iconColor` and `themeColor` colour each module's own detail screen;
    // on Home every card shares the one blue icon.
    final modules = <_MsmeModule>[
      _MsmeModule(
        'schemes',
        l10n.schemes,
        l10n.subsidiesGrantsGovtSchemes,
        Icons.card_giftcard_rounded,
        const Color(0xFF2E7D32),
        Colors.green,
      ),
      _MsmeModule(
        'finance',
        l10n.finance,
        l10n.loansCreditSupportFundingOptions,
        Icons.savings_rounded,
        const Color(0xFF1565C0),
        Colors.blue,
      ),
      _MsmeModule(
        'tax_gst',
        l10n.taxGst,
        l10n.taxBenefitsGstSupportCompliance,
        Icons.percent_rounded,
        const Color(0xFFEF6C00),
        Colors.orange,
      ),
      _MsmeModule(
        'export',
        l10n.export,
        l10n.exportIncentivesFinanceMarketSupport,
        Icons.language_rounded,
        const Color(0xFF6A1B9A),
        Colors.purple,
      ),
      _MsmeModule(
        'treds',
        l10n.treds,
        l10n.invoiceDiscountingWorkingCapital,
        Icons.currency_exchange_rounded,
        const Color(0xFFC62828),
        Colors.red,
      ),
      _MsmeModule(
        'csr',
        l10n.csrSupport,
        l10n.csrProgramsIncubatorsClusterSupport,
        Icons.handshake_rounded,
        const Color(0xFF00695C),
        Colors.teal,
      ),
      _MsmeModule(
        'govt',
        l10n.govtAuthorities,
        l10n.centralStateDistrictGovtStructure,
        Icons.account_balance_rounded,
        const Color(0xFF0277BD),
        Colors.lightBlue,
      ),
      _MsmeModule(
        'institutions',
        l10n.institutions,
        l10n.sidbiNsicDicKvicMoreOrganizations,
        Icons.business_rounded,
        const Color(0xFF4527A0),
        Colors.deepPurple,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exploreMsmeSupport,
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
                for (var i = 0; i < modules.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: i == modules.length - 1
                          ? AppSpacing.none
                          : AppSpacing.md,
                    ),
                    child: _buildMSMESupportCard(context, modules[i]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMSMESupportCard(BuildContext context, _MsmeModule module) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MSMEModuleDetailsScreen(
                moduleId: module.id,
                title: module.title,
                description: module.subtitle,
                icon: module.icon,
                iconColor: module.iconColor,
                themeColor: module.themeColor,
              ),
            ),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: cardWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                    module.icon,
                    color: AppColors.primary,
                    size: AppSize.iconLg,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  module.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  module.subtitle,
                  textAlign: TextAlign.center,
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
    );
  }
}

class _MsmeModule {
  const _MsmeModule(
    this.id,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.themeColor,
  );

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color themeColor;
}
