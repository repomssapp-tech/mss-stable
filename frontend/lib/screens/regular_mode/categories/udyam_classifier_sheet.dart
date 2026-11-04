import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/msme_classification.dart';
import '../../../utils/app_text.dart';

/// Udyam MSME Classifier bottom sheet.
///
/// Extracted verbatim from `_CategoriesScreenState._openUdyamClassifier`
/// (frontend refactor C2, slice 1). Self-contained: reads only
/// `AppProvider.selectedLanguage`, `CentralizedTranslator`, `AppSpacing` and
/// the passed [context]. No behaviour change — the modal, its local
/// `TextEditingController`s and the `StatefulBuilder` calc logic are unchanged.
void showUdyamClassifierSheet(BuildContext context) {
  final investmentController = TextEditingController();
  final turnoverController = TextEditingController();
  String result = '';
  String subResult = '';
  Color resultColor = AppColors.textPrimary;

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
                          Icons.domain_verification,
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
                              context.l10n.calcUdyamClassifierTitle,
                              style: context.text.cardTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              context.l10n.calcUdyamClassifierSub,
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
                    context.l10n.calcInvestmentLabel,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: investmentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '0.5',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      prefixText: '₹ ',
                      suffixText: context.l10n.croreSuffix,
                      helperText: context.l10n.calcInvestmentHelper,
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
                    context.l10n.calcTurnoverLabel,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: turnoverController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '3.0',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      prefixText: '₹ ',
                      suffixText: context.l10n.croreSuffix,
                      helperText: context.l10n.calcTurnoverHelper,
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
                  const SizedBox(height: AppSpacing.xl),
                  if (result.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: resultColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: resultColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.calcClassificationResult,
                                      style: context.text.label.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      result,
                                      style: context.text.cardTitle.copyWith(
                                        color: resultColor,
                                      ),
                                    ),
                                    if (subResult.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        subResult,
                                        style: context.text.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final double invest =
                            double.tryParse(investmentController.text) ?? 0;
                        final double turn =
                            double.tryParse(turnoverController.text) ?? 0;

                        // 0 is valid (a new unit); only blanks, text and
                        // negatives are rejected (test report BUG-12).
                        final investOk =
                            (double.tryParse(investmentController.text) ??
                                -1) >=
                            0;
                        final turnOk =
                            (double.tryParse(turnoverController.text) ?? -1) >=
                            0;
                        if (!investOk || !turnOk) {
                          setModalState(() {
                            result = context.l10n.udyamInvalid;
                            subResult = context.l10n.udyamInvalidSub;
                            resultColor = AppColors.danger;
                          });
                          return;
                        }

                        String category = '';
                        switch (classifyMsme(
                          investmentCr: invest,
                          turnoverCr: turn,
                        )) {
                          case MsmeTier.micro:
                            category = context.l10n.udyamMicro;
                            resultColor = AppColors.primary;
                          case MsmeTier.small:
                            category = context.l10n.udyamSmall;
                            resultColor = AppColors.primary;
                          case MsmeTier.medium:
                            category = context.l10n.udyamMedium;
                            resultColor = AppColors.primary;
                          case MsmeTier.large:
                            category = context.l10n.udyamLarge;
                            // Above the MSME limits: a caution, not an error.
                            resultColor = AppColors.warningText;
                        }

                        setModalState(() {
                          result = category;
                          subResult = context.l10n.udyamLimitsSummary(
                            formatCrore(kMicroLimits.investmentCr),
                            formatCrore(kMicroLimits.turnoverCr),
                            formatCrore(kSmallLimits.investmentCr),
                            formatCrore(kSmallLimits.turnoverCr),
                            formatCrore(kMediumLimits.investmentCr),
                            formatCrore(kMediumLimits.turnoverCr),
                          );
                        });
                      },
                      child: Text(context.l10n.calcBtnCalculate),
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
