import 'dart:math';

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Loan EMI calculator bottom sheet (EMI + principal + interest + total).
///
/// Extracted verbatim from `_CategoriesScreenState._openEmiCalculator`
/// (frontend refactor C2, slice 4). Self-contained: reads only `context.l10n`,
/// `AppSpacing`, `FitOneLine` and `dart:math` `pow`. No behaviour change.
void showEmiCalculatorSheet(BuildContext context) {
  final l10n = context.l10n;
  final loanController = TextEditingController();
  final rateController = TextEditingController();
  final tenureController = TextEditingController();
  double emiVal = 0.0;
  double principalVal = 0.0;
  double interestVal = 0.0;
  double totalVal = 0.0;
  String error = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.emiCalcTitle,
                              style: context.text.cardTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.emiCalcSubtitle,
                              style: context.text.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        tooltip: context.l10n.close,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.emiLoanAmount,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: loanController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '500000',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      prefixText: '₹ ',
                      helperText: l10n.emiLoanAmountHelper,
                      helperStyle: context.text.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      prefixStyle: context.text.label.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.emiInterestRate,
                              style: context.text.label.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            TextField(
                              controller: rateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                hintText: '9.5',
                                hintStyle: context.text.bodySmall.copyWith(
                                  color: AppColors.iconMuted,
                                ),
                                suffixText: '%',
                                helperText: l10n.emiInterestRateHelper,
                                helperStyle: context.text.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.emiTenureMonths,
                              style: context.text.label.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            TextField(
                              controller: tenureController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                hintText: '60',
                                hintStyle: context.text.bodySmall.copyWith(
                                  color: AppColors.iconMuted,
                                ),
                                suffixText: l10n.emiTenureSuffixMo,
                                helperText: l10n.emiTenureHelper,
                                helperStyle: context.text.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: Text(
                        error,
                        style: context.text.label.copyWith(
                          color: AppColors.dangerStrong,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else if (emiVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryTint),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.emiMonthlyEmi,
                                  softWrap: true,
                                  style: context.text.label.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '₹ ${emiVal.toStringAsFixed(2)}',
                                  style: context.text.cardTitle.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.tight,
                            ),
                            child: Divider(
                              color: AppColors.primaryTint,
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.emiPrincipal,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '₹ ${principalVal.toStringAsFixed(2)}',
                                  style: context.text.cardTitle.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.emiTotalInterest,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '₹ ${interestVal.toStringAsFixed(2)}',
                                  style: context.text.cardTitle.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.tight,
                            ),
                            child: Divider(
                              color: AppColors.primaryTint,
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.emiTotalAmount,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '₹ ${totalVal.toStringAsFixed(2)}',
                                  style: context.text.cardTitle.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final double p =
                            double.tryParse(loanController.text) ?? 0;
                        // A blank rate is invalid, but 0% is a real offer
                        // (interest-free loans; test report BUG-12).
                        final double annualRate =
                            double.tryParse(rateController.text) ?? -1;
                        final double n =
                            double.tryParse(tenureController.text) ?? 0;

                        if (!p.isFinite ||
                            p <= 0 ||
                            !annualRate.isFinite ||
                            annualRate < 0 ||
                            !n.isFinite ||
                            n <= 0) {
                          setModalState(() {
                            error = l10n.emiInvalidInputs;
                            emiVal = 0;
                          });
                          return;
                        }

                        final double r = (annualRate / 12) / 100;
                        final double emi = r == 0
                            ? p / n
                            : (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
                        final double totalPayable = emi * n;
                        final double totalInterest = totalPayable - p;

                        setModalState(() {
                          error = '';
                          emiVal = emi;
                          principalVal = p;
                          interestVal = totalInterest;
                          totalVal = totalPayable;
                        });
                      },
                      child: Text(l10n.emiCalculate),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
