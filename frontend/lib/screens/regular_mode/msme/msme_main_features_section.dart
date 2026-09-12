import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
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
    List<String> features = [];
    switch (moduleId) {
      case 'schemes':
        features = [
          'Personalized schemes matched to business profile',
          'Central vs. State schemes filter',
          'Comprehensive eligibility checker',
          'Search by scheme categories',
          'Capital subsidies, grants & interest subventions',
          'Reminders for registration deadlines',
          'Lists of required documents & checklists',
          'Clear, step-by-step application guidelines',
          'Scheme save & side-by-side comparison',
        ];
        break;
      case 'finance':
        features = [
          'Collateral-free business term loans & working capital',
          'SIDBI specialized credit schemes for machinery & tools',
          'Credit Guarantees (CGTMSE) for collateral-free bank options',
          'Equipment & machinery financing models',
          'Detailed comparisons of loan interest rates',
          'Direct contact pathways to SIDBI & partner commercial banks',
          'SME IPO listing requirements (BSE SME & NSE Emerge)',
        ];
        break;
      case 'tax_gst':
        features = [
          'MSME Corporate Income-Tax benefits',
          'GST registration threshold limits (₹40/₹20 Lakhs exemptions)',
          'GST Composition Scheme parameters (1% tax, easier filings)',
          'Section 43B(h) Income Tax protection (45-day payment rule)',
          'Late payment interest claim calculator (3x Bank Rate)',
          'Export tax refunds & LUT (Letter of Undertaking) rules',
          'MSME Samadhaan portal recovery guidelines',
        ];
        break;
      case 'export':
        features = [
          'Duty refund schemes (RoDTEP, RoSCTL) & Drawbacks',
          'Pre-shipment & Post-shipment export credit financing',
          'Interest subvention on foreign currency loans',
          'ECGC credit risk insurance coverage policies',
          'MDA & MAI schemes for foreign exhibition participation',
          'Directory of Export Councils & DGFT field offices',
          'HS Code classifications & AD Code registration guide',
        ];
        break;
      case 'treds':
        features = [
          'Invoice Discounting multi-party platforms explainer',
          'Onboarding guidelines for MSME Sellers',
          'RXIL, M1xchange & Invoicemart registration steps',
          'Acceptance guidelines for Corporate Buyers',
          'Financier bidding flow (anonymized auction for best rates)',
          'Payment settlement pathways (T+1 credit cycles)',
          'Recourse vs. Non-recourse factoring definitions',
        ];
        break;
      case 'csr':
        features = [
          'Corporate CSR-backed cluster development funding',
          'Access to corporate incubation grants for prototype support',
          'Specialized green-energy & waste-management cluster programs',
          'Skill development & technology upgrade programs',
          'List of CSR implementing agencies & NGOs',
          'Eligibility checklists & application pathways',
        ];
        break;
      case 'govt':
        features = [
          'Ministry of MSME (Central Govt) policies & initiatives',
          'State Directorate of Industries / Dept of Commerce role',
          'District Industries Centre (DIC) local assistance offices',
          'Clear hierarchies: Central -> State -> District levels',
          'Key contact directories & nodal officer lists',
          'Authority-specific schemes (PMEGP vs State subsidies)',
        ];
        break;
      case 'institutions':
        features = [
          'SIDBI (Small Industries Development Bank of India) credit portals',
          'NSIC (National Small Industries Corporation) raw material support',
          'DIC (District Industries Centre) single-window registrations',
          'KVIC (Khadi and Village Industries Commission) rural projects',
          'TIIC, StartupTN, FaMeTN, SIPCOT regional service descriptions',
          'Program services catalog & contact application routes',
        ];
        break;
      case 'udyam':
        features = [
          '100% Free & Paperless Instant Portal Registration',
          'Lifetime Validity with QR Code e-Certificate',
          'Automatic CGTMSE Collateral-Free Credit & TReDS Eligibility',
          'Exemption from Earnest Money Deposit (EMD) in Govt Tenders',
          'Eligible for 15% CLCSS Technology & Capital Subsidies',
          'Concessional Electricity & Patent Registration Fee Waiver',
        ];
        break;
    }

    final isTa =
        Provider.of<AppProvider>(context, listen: false).selectedLanguage ==
        'ta';
    final localizedFeatures = isTa
        ? features
              .map((f) => CentralizedTranslator.instance.translate(f))
              .toList()
        : features;

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
