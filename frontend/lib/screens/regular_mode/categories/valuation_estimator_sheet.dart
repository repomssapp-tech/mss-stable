import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Seed-stage startup valuation estimator bottom sheet (ARR-multiple ranges).
///
/// Extracted verbatim from `_CategoriesScreenState._openValuationEstimator`
/// (frontend refactor C2, slice 6). Self-contained: reads only `context.l10n`,
/// `AppSpacing`, `FitOneLine`. No behaviour change — the sector/growth multiple
/// logic and the local `formatVal` helper are unchanged.
void showValuationEstimatorSheet(BuildContext context) {
  final l10n = context.l10n;
  final mrrController = TextEditingController();
  final growthController = TextEditingController();
  String selectedSector = 'SaaS / Tech';
  double lowEstimate = 0.0;
  double highEstimate = 0.0;
  double arrVal = 0.0;
  double appliedMultiple = 0.0;
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
          String formatVal(double val) {
            if (val >= 10000000) {
              return l10n.valuationCroreFmt(
                (val / 10000000).toStringAsFixed(2),
              );
            }
            return l10n.valuationLakhFmt((val / 100000).toStringAsFixed(2));
          }

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
                          Icons.trending_up_outlined,
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
                              l10n.valuationTitle,
                              style: context.text.cardTitle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.valuationSubtitle,
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
                    l10n.valuationMrrLabel,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: mrrController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '200000',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: AppColors.iconMuted,
                      ),
                      prefixText: '₹ ',
                      helperText: l10n.valuationMrrHelper,
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
                              l10n.valuationMomGrowth,
                              style: context.text.label.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            TextField(
                              controller: growthController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                                helperText: l10n.valuationMomHelper,
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
                              l10n.valuationSector,
                              style: context.text.label.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedSector,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items:
                                  [
                                    'SaaS / Tech',
                                    'E-commerce',
                                    'Fintech',
                                    'AgriTech',
                                  ].map((String sector) {
                                    return DropdownMenuItem<String>(
                                      value: sector,
                                      child: Text(
                                        _sectorLabel(context, sector),
                                        style: context.text.bodySmall,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedSector = val);
                                }
                              },
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
                  ] else if (lowEstimate > 0) ...[
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
                                  l10n.valuationRange,
                                  softWrap: true,
                                  style: context.text.label.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '${formatVal(lowEstimate)} - ${formatVal(highEstimate)}',
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
                                  l10n.valuationCalculatedArr,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  l10n.valuationLakhFmt(
                                    (arrVal / 100000).toStringAsFixed(1),
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
                                  l10n.valuationAppliedMultiple,
                                  softWrap: true,
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '${appliedMultiple.toStringAsFixed(1)}x',
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
                        final double mrr =
                            double.tryParse(mrrController.text) ?? 0;
                        final double growth =
                            double.tryParse(growthController.text) ?? 0;

                        if (mrr <= 0) {
                          setModalState(() {
                            error = l10n.valuationInvalidMrr;
                            lowEstimate = 0;
                          });
                          return;
                        }

                        double baseMultiple = 10;
                        if (selectedSector == 'Fintech') baseMultiple = 12;
                        if (selectedSector == 'E-commerce') baseMultiple = 6;
                        if (selectedSector == 'AgriTech') baseMultiple = 8;

                        if (growth > 20) {
                          baseMultiple += 4;
                        } else if (growth > 10) {
                          baseMultiple += 2;
                        }

                        final double arr = mrr * 12;
                        setModalState(() {
                          error = '';
                          arrVal = arr;
                          appliedMultiple = baseMultiple;
                          lowEstimate = arr * baseMultiple;
                          highEstimate = arr * (baseMultiple + 3);
                        });
                      },
                      child: Text(l10n.valuationEstimate),
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

/// Localized label for a sector. The English value stays the internal key the
/// multiple logic matches on.
String _sectorLabel(BuildContext context, String sector) {
  final l10n = context.l10n;
  switch (sector) {
    case 'SaaS / Tech':
      return l10n.valuationSectorSaasTech;
    case 'E-commerce':
      return l10n.valuationSectorEcommerce;
    case 'Fintech':
      return l10n.valuationSectorFintech;
    case 'AgriTech':
      return l10n.valuationSectorAgritech;
    default:
      return sector;
  }
}
