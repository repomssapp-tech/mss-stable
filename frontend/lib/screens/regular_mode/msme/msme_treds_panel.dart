import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

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
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeTredsFlowHeading,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_tredsSteps.length, (idx) {
                  final isSelected = idx == _tredsStepIndex;
                  return Expanded(
                    child: InkWell(
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
                          style: context.text.label.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
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
                    style: context.text.cardTitle.copyWith(
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    CentralizedTranslator.instance.localize(
                      _tredsSteps[_tredsStepIndex]['desc']!,
                    ),
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Expanded(
                        child: Text(
                          CentralizedTranslator.instance.localize(
                            _tredsSteps[_tredsStepIndex]['action']!,
                          ),
                          style: context.text.label.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
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
