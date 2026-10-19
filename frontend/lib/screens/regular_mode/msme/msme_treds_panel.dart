import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';

class TredsInteractivePanel extends StatefulWidget {
  final Color iconColor;
  final Color themeColor;

  const TredsInteractivePanel({
    super.key,
    required this.iconColor,
    required this.themeColor,
  });

  @override
  State<TredsInteractivePanel> createState() => _TredsInteractivePanelState();
}

class _TredsInteractivePanelState extends State<TredsInteractivePanel> {
  int _tredsStepIndex = 0;
  final List<Map<String, String>> _tredsSteps = [
    {
      'title': '1. Invoice Upload',
      'desc':
          'MSME Seller uploads the invoice for goods/services delivered to the Corporate Buyer on the TReDS platform (RXIL/M1xchange/Invoicemart).',
      'action': 'Seller uploads invoice & supporting documents.',
    },
    {
      'title': '2. Buyer Acceptance',
      'desc':
          'The Corporate Buyer logs into the TReDS portal, verifies the details, and digitally accepts the uploaded invoice.',
      'action':
          'Buyer approves invoice; it becomes a legally binding payment obligation.',
    },
    {
      'title': '3. Bank Bidding',
      'desc':
          'Multiple banks and NBFCs view the accepted factoring unit and submit competing discount rate bids in an online auction.',
      'action':
          'Financiers compete; lowest discount interest rate is automatically selected.',
    },
    {
      'title': '4. Payment Settlement',
      'desc':
          'The winning financier pays the discounted invoice amount to the MSME bank account within T+1 days. The buyer repays the financier on due date.',
      'action':
          'Immediate cash realization for MSME without collateral or recourse.',
    },
  ];

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
              CentralizedTranslator.instance.localize(
                'TReDS Invoice Discounting Flow',
              ),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_tredsSteps.length, (idx) {
                  final isSelected = idx == _tredsStepIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tredsStepIndex = idx;
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
                          context.l10n.msmeStepNumber(idx + 1),
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
                    CentralizedTranslator.instance.localize(
                      _tredsSteps[_tredsStepIndex]['title']!,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    CentralizedTranslator.instance.localize(
                      _tredsSteps[_tredsStepIndex]['desc']!,
                    ),
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
                          CentralizedTranslator.instance.localize(
                            _tredsSteps[_tredsStepIndex]['action']!,
                          ),
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
          ],
        ),
      ),
    );
  }
}
