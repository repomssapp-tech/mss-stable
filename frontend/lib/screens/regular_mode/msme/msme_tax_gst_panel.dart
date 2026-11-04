import 'dart:math';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class TaxGstInteractivePanel extends StatefulWidget {
  final Color iconColor;

  const TaxGstInteractivePanel({super.key, required this.iconColor});

  @override
  State<TaxGstInteractivePanel> createState() => _TaxGstInteractivePanelState();
}

class _TaxGstInteractivePanelState extends State<TaxGstInteractivePanel> {
  final _invoiceController = TextEditingController(text: '100000');
  final _daysController = TextEditingController(text: '60');
  double _calculatedInterest = 0.0;
  double _totalAmount = 0.0;
  final double _annualRate = 0.2025; // 3x RBI Bank Rate (6.75% * 3 = 20.25%)

  @override
  void initState() {
    super.initState();
    _calculateLateInterest();
  }

  void _calculateLateInterest() {
    final double invoiceVal = double.tryParse(_invoiceController.text) ?? 0.0;
    final int delayDays = int.tryParse(_daysController.text) ?? 0;
    if (invoiceVal <= 0 || delayDays <= 0) {
      setState(() {
        _calculatedInterest = 0.0;
        _totalAmount = invoiceVal;
      });
      return;
    }
    final double monthlyRate = _annualRate / 12;
    final double months = delayDays / 30;
    final double finalVal = invoiceVal * pow(1 + monthlyRate, months);

    setState(() {
      _calculatedInterest = finalVal - invoiceVal;
      _totalAmount = finalVal;
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _daysController.dispose();
    super.dispose();
  }

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
            Row(
              children: [
                Icon(Icons.calculate, color: widget.iconColor, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.msmeDelayedPaymentCalcTitle,
                    style: context.text.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.msmeDelayedPaymentCalcDesc,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.msmeInvoiceAmountRupees,
                    style: context.text.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.msmeDaysDelayedPost45,
                    style: context.text.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.tight),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _invoiceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => _calculateLateInterest(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => _calculateLateInterest(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.msmeInterestRate3xBankRate,
                          softWrap: true,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          context.l10n.msmeRatePerAnnum(
                            (_annualRate * 100).toStringAsFixed(2),
                          ),
                          style: context.text.label.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.msmeCalculatedInterestLabel,
                          softWrap: true,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          '₹${_calculatedInterest.toStringAsFixed(0)}',
                          style: context.text.button.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12, color: AppColors.borderStrong),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.msmeTotalClaimableAmountLabel,
                          softWrap: true,
                          style: context.text.button.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          '₹${_totalAmount.toStringAsFixed(0)}',
                          style: context.text.button.copyWith(
                            color: widget.iconColor,
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
