import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/money_format.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// GST / tax calculator bottom sheet (CGST + SGST + total invoice).
///
/// Extracted verbatim from `_CategoriesScreenState._openGstCalculator`
/// (frontend refactor C2, slice 3). Self-contained: reads only
/// `AppProvider.selectedLanguage`, `CentralizedTranslator`, `context.l10n`,
/// `AppSpacing`, `FitOneLine`. No behaviour change.
void showGstCalculatorSheet(BuildContext context) {
  final amountController = TextEditingController();
  double gstPercentage = 18.0;
  // Inter-state supply → IGST (full rate); intra-state → CGST + SGST (half each).
  bool interState = false;
  double igstVal = 0.0;
  double baseVal = 0.0;
  double cgstVal = 0.0;
  double sgstVal = 0.0;
  double totalVal = 0.0;
  bool invalidAmount = false;

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
                          Icons.percent_outlined,
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
                              context.l10n.calcGstTitle,
                              style: context.text.cardTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              context.l10n.calcGstSub,
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
                    context.l10n.calcBaseAmountLabel,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '50000',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      prefixText: '₹ ',
                      helperText: context.l10n.calcBaseAmountHelper,
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
                  Text(
                    context.l10n.calcGstRateLabel,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // GST slabs after the 22 Sep 2025 rationalisation (GST 2.0).
                    children: [0.0, 5.0, 18.0, 40.0].map((rate) {
                      final isSelected = gstPercentage == rate;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                '${rate.toStringAsFixed(0)}%',
                                style: context.text.bodySmall.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => gstPercentage = rate);
                              }
                            },
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.surface,
                            checkmarkColor: AppColors.primary,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [false, true].map((inter) {
                      final isSelected = interState == inter;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                inter
                                    ? context.l10n.calcGstInterState
                                    : context.l10n.calcGstWithinState,
                                textAlign: TextAlign.center,
                                style: context.text.label.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  interState = inter;
                                  final gstAmount =
                                      baseVal * (gstPercentage / 100);
                                  igstVal = gstAmount;
                                  cgstVal = gstAmount / 2;
                                  sgstVal = gstAmount / 2;
                                });
                              }
                            },
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.surface,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdAll,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (invalidAmount) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: Text(
                        context.l10n.calcErrValidBaseAmount,
                        style: context.text.label.copyWith(
                          color: AppColors.dangerStrong,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else if (baseVal > 0) ...[
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
                                  context.l10n.calcBasePrice,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '₹ ${baseVal.toStringAsFixed(2)}',
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
                          if (interState)
                            _taxRow(
                              context,
                              'IGST (${gstPercentage.toStringAsFixed(0)}%)',
                              igstVal,
                            )
                          else ...[
                            _taxRow(
                              context,
                              'CGST (${(gstPercentage / 2).toStringAsFixed(1)}%)',
                              cgstVal,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _taxRow(
                              context,
                              'SGST (${(gstPercentage / 2).toStringAsFixed(1)}%)',
                              sgstVal,
                            ),
                          ],
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
                                  context.l10n.calcTotalInvoice,
                                  softWrap: true,
                                  style: context.text.label.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '₹ ${totalVal.toStringAsFixed(2)}',
                                  style: context.text.cardTitle.copyWith(
                                    color: AppColors.primary,
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
                        final double base =
                            double.tryParse(amountController.text) ?? 0;
                        if (base <= 0) {
                          setModalState(() {
                            invalidAmount = true;
                            baseVal = 0;
                          });
                          return;
                        }
                        final double gstAmount = base * (gstPercentage / 100);
                        setModalState(() {
                          invalidAmount = false;
                          baseVal = base;
                          igstVal = gstAmount;
                          cgstVal = gstAmount / 2;
                          sgstVal = gstAmount / 2;
                          totalVal = base + gstAmount;
                        });
                      },
                      child: Text(context.l10n.calcBtnCalculateTax),
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

/// One tax line in the result card: label on the left, rupee amount right.
/// The amount wraps rather than shrinking.
Widget _taxRow(BuildContext context, String label, double amount) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible(
      child: Text(
        label,
        style: context.text.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    Text(
      formatInr(amount),
      style: context.text.cardTitle.copyWith(
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  ],
);
