import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Machinery / project-cost subsidy estimator bottom sheet.
///
/// Extracted verbatim from `_CategoriesScreenState._openSubsidyEstimator`
/// (frontend refactor C2, slice 2). Self-contained: reads only `context.l10n`,
/// `AppSpacing`, `FitOneLine` and the passed [context]. No behaviour change —
/// the modal, its local controllers and the `StatefulBuilder` calc are
/// unchanged.
void showSubsidyEstimatorSheet(BuildContext context) {
  final l10n = context.l10n;
  final costController = TextEditingController();
  final subsidyController = TextEditingController();
  double costVal = 0.0;
  double subsidyPercentVal = 0.0;
  double subsidyAmountVal = 0.0;
  double netCostVal = 0.0;
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
                          Icons.account_balance_wallet_outlined,
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
                              l10n.subsidyTitle,
                              style: context.text.cardTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.subsidySubtitle,
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
                    l10n.subsidyProjectCost,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '25',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      prefixText: '₹ ',
                      suffixText: l10n.subsidyProjectCostSuffix,
                      helperText: l10n.subsidyProjectCostHelper,
                      helperStyle: context.text.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      suffixStyle: context.text.label.copyWith(
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
                    l10n.subsidyPercentLabel,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: subsidyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '15',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      suffixText: '%',
                      helperText: l10n.subsidyPercentHelper,
                      helperStyle: context.text.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      suffixStyle: context.text.label.copyWith(
                        color: AppColors.textMuted,
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
                  ] else if (costVal > 0) ...[
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
                                  l10n.subsidyOriginalCost,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  l10n.subsidyLakhFmt(
                                    costVal.toStringAsFixed(2),
                                  ),
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
                                  l10n.subsidyExpectedLabel(
                                    subsidyPercentVal.toStringAsFixed(1),
                                  ),
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  l10n.subsidyLakhFmt(
                                    subsidyAmountVal.toStringAsFixed(2),
                                  ),
                                  style: context.text.cardTitle.copyWith(
                                    color: AppTagStyle.benefit.text,
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
                                  l10n.subsidyNetCost,
                                  softWrap: true,
                                  style: context.text.label.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  l10n.subsidyLakhFmt(
                                    netCostVal.toStringAsFixed(2),
                                  ),
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
                        final double cost =
                            double.tryParse(costController.text) ?? 0;
                        final double percent =
                            double.tryParse(subsidyController.text) ?? 0;

                        if (cost <= 0 || percent <= 0 || percent > 100) {
                          setModalState(() {
                            error = l10n.subsidyInvalidValues;
                            costVal = 0;
                          });
                          return;
                        }

                        final double subsidyAmount = cost * (percent / 100);
                        final double netAmount = cost - subsidyAmount;

                        setModalState(() {
                          error = '';
                          costVal = cost;
                          subsidyPercentVal = percent;
                          subsidyAmountVal = subsidyAmount;
                          netCostVal = netAmount;
                        });
                      },
                      child: Text(l10n.subsidyCalculate),
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
