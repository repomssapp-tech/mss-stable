import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../msme_module_details_screen.dart';

class HomeMsmeSupportSection extends StatelessWidget {
  const HomeMsmeSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.exploreMsmeSupport,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 178,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.hairline),
            children: [
              _buildMSMESupportCard(
                context: context,
                id: 'schemes',
                title: context.l10n.schemes,
                subtitle: context.l10n.subsidiesGrantsGovtSchemes,
                icon: Icons.card_giftcard,
                iconColor: const Color(0xFF2E7D32),
                themeColor: Colors.green,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'finance',
                title: context.l10n.finance,
                subtitle: context.l10n.loansCreditSupportFundingOptions,
                icon: Icons.savings,
                iconColor: const Color(0xFF1565C0),
                themeColor: Colors.blue,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'tax_gst',
                title: context.l10n.taxGst,
                subtitle: context.l10n.taxBenefitsGstSupportCompliance,
                icon: Icons.percent,
                iconColor: const Color(0xFFEF6C00),
                themeColor: Colors.orange,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'export',
                title: context.l10n.export,
                subtitle: context.l10n.exportIncentivesFinanceMarketSupport,
                icon: Icons.language,
                iconColor: const Color(0xFF6A1B9A),
                themeColor: Colors.purple,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'treds',
                title: context.l10n.treds,
                subtitle: context.l10n.invoiceDiscountingWorkingCapital,
                icon: Icons.currency_exchange,
                iconColor: const Color(0xFFC62828),
                themeColor: Colors.red,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'csr',
                title: context.l10n.csrSupport,
                subtitle: context.l10n.csrProgramsIncubatorsClusterSupport,
                icon: Icons.handshake,
                iconColor: const Color(0xFF00695C),
                themeColor: Colors.teal,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'govt',
                title: context.l10n.govtAuthorities,
                subtitle: context.l10n.centralStateDistrictGovtStructure,
                icon: Icons.account_balance,
                iconColor: const Color(0xFF0277BD),
                themeColor: Colors.lightBlue,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'institutions',
                title: context.l10n.institutions,
                subtitle: context.l10n.sidbiNsicDicKvicMoreOrganizations,
                icon: Icons.business,
                iconColor: const Color(0xFF4527A0),
                themeColor: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMSMESupportCard({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color themeColor,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MSMEModuleDetailsScreen(
                  moduleId: id,
                  title: title,
                  description: subtitle,
                  icon: icon,
                  iconColor: iconColor,
                  themeColor: themeColor,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                    fontWeight: FontWeight.w500,
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
