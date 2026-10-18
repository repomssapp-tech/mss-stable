import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../search_results_screen.dart';

class SchemesInteractivePanel extends StatelessWidget {
  final Color iconColor;

  const SchemesInteractivePanel({
    super.key,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeInteractiveToolsActions,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.msmeInteractiveToolsDesc,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: () {
                      provider.updateTabIndex(1); // Navigate to search
                      Navigator.of(context).pop(); // Dismiss detail
                    },
                    child: Text(
                      context.l10n.msmeSearchSchemes,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: iconColor,
                      side: BorderSide(color: iconColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: () {
                      provider.updateTabIndex(4); // Navigate to profile
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      context.l10n.completeProfileTitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceInteractivePanel extends StatelessWidget {
  final Color iconColor;

  const FinanceInteractivePanel({
    super.key,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CentralizedTranslator.instance.localize('Find Funding Options'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CentralizedTranslator.instance.localize('Instantly search our database for credit support, collateral-free business loans, and SIDBI programs.'),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchResultsScreen(
                        title: 'Loan',
                        type: 'category',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.currency_rupee, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: FitOneLine(
                        child: Text(
                          CentralizedTranslator.instance.localize('Search MSME Loans & Funding'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CsrInteractivePanel extends StatelessWidget {
  final Color iconColor;

  const CsrInteractivePanel({
    super.key,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CentralizedTranslator.instance.localize('Explore CSR & Technology Clusters'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CentralizedTranslator.instance.localize('Search for schemes offering cluster development, technology upgrades, and incubator grants.'),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchResultsScreen(
                        title: 'Cluster',
                        type: 'category',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hub, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: FitOneLine(
                        child: Text(
                          CentralizedTranslator.instance.localize('Search Cluster / Tech Schemes'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UdyamInteractivePanel extends StatefulWidget {
  final Color iconColor;
  final Color themeColor;

  const UdyamInteractivePanel({
    super.key,
    required this.iconColor,
    required this.themeColor,
  });

  @override
  State<UdyamInteractivePanel> createState() => _UdyamInteractivePanelState();
}

class _UdyamInteractivePanelState extends State<UdyamInteractivePanel> {
  int _udyamStepIndex = 0;

  List<Map<String, String>> _udyamSteps(AppLocalizations l10n) => [
    {
      'title': l10n.msmeUdyamStep1Title,
      'desc': l10n.msmeUdyamStep1Desc,
      'action': l10n.msmeUdyamStep1Action,
    },
    {
      'title': l10n.msmeUdyamStep2Title,
      'desc': l10n.msmeUdyamStep2Desc,
      'action': l10n.msmeUdyamStep2Action,
    },
    {
      'title': l10n.msmeUdyamStep3Title,
      'desc': l10n.msmeUdyamStep3Desc,
      'action': l10n.msmeUdyamStep3Action,
    },
    {
      'title': l10n.msmeUdyamStep4Title,
      'desc': l10n.msmeUdyamStep4Desc,
      'action': l10n.msmeUdyamStep4Action,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _udyamSteps(l10n);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.msmeUdyamFlowTitle,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Step Selector Pills (Step 1, Step 2, Step 3, Step 4)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(steps.length, (idx) {
                  final isSelected = idx == _udyamStepIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _udyamStepIndex = idx;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.iconColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          l10n.msmeStepNumber(idx + 1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Step Details Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.themeColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[_udyamStepIndex]['title']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    steps[_udyamStepIndex]['desc']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Expanded(
                        child: Text(
                          steps[_udyamStepIndex]['action']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Button to official Udyam portal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
                child: Text(
                  l10n.msmeUdyamGoToPortal,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(
                    'https://www.udyamregistration.gov.in/',
                  );
                  try {
                    final launched = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched) {
                      await launchUrl(url, mode: LaunchMode.platformDefault);
                    }
                  } catch (_) {
                    try {
                      await launchUrl(url, mode: LaunchMode.platformDefault);
                    } catch (e) {
                      debugPrint('Could not launch Udyam URL: $e');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
