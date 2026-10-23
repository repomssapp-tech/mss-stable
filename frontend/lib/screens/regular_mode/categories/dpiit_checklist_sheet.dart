import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'dpiit_eligibility.dart';
import '../../../utils/app_text.dart';

/// DPIIT startup-recognition eligibility checklist bottom sheet.
///
/// Shows one checkbox per [DpiitCriterion] (five criteria). "Check Eligibility"
/// passes only when every criterion is met (AND-gate); otherwise the unmet
/// criteria are listed. Changing any answer clears the verdict so a stale
/// result never sits beside new answers, and the result icon matches the
/// verdict. Self-contained: reads only `context.l10n` and `AppSpacing`.
/// (Originally extracted from `_CategoriesScreenState._openDpiitChecklist`.)
void showDpiitChecklistSheet(BuildContext context) {
  final l10n = context.l10n;
  final met = <DpiitCriterion>{};
  // Null until "Check Eligibility" is pressed; cleared again when any answer
  // changes so a stale verdict is never shown beside new answers.
  bool? passed;
  List<DpiitCriterion> unmet = const [];
  final criteria = <DpiitCriterion, (String, String)>{
    DpiitCriterion.entityType: (
      l10n.dpiitCriteriaRegistered,
      l10n.dpiitCriteriaRegisteredSub,
    ),
    DpiitCriterion.age: (l10n.dpiitCriteriaAge, l10n.dpiitCriteriaAgeSub),
    DpiitCriterion.turnover: (
      l10n.dpiitCriteriaTurnover,
      l10n.dpiitCriteriaTurnoverSub,
    ),
    DpiitCriterion.notReconstruction: (
      l10n.dpiitCriteriaNotSplit,
      l10n.dpiitCriteriaNotSplitSub,
    ),
    DpiitCriterion.innovation: (
      l10n.dpiitCriteriaInnovation,
      l10n.dpiitCriteriaInnovationSub,
    ),
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
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
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dpiitTitle,
                              style: AppGoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              l10n.dpiitSubtitle,
                              style: AppGoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
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
                          color: Color(0xFF64748B),
                        ),
                        tooltip: context.l10n.close,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (final entry in criteria.entries) ...[
                          if (entry.key != DpiitCriterion.entityType)
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          CheckboxListTile(
                            title: Text(
                              entry.value.$1,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              entry.value.$2,
                              style: const TextStyle(fontSize: 9.5),
                            ),
                            value: met.contains(entry.key),
                            activeColor: const Color(0xFF2563EB),
                            onChanged: (val) => setModalState(() {
                              if (val ?? false) {
                                met.add(entry.key);
                              } else {
                                met.remove(entry.key);
                              }
                              passed = null;
                            }),
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                  entry.key == DpiitCriterion.entityType
                                      ? 16
                                      : 0,
                                ),
                                bottom: Radius.circular(
                                  entry.key == DpiitCriterion.innovation
                                      ? 16
                                      : 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (passed != null) ...[
                    Builder(
                      builder: (context) {
                        final ok = passed!;
                        final resultColor = ok
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFDC2626);
                        final missing = unmet
                            .map((c) => criteria[c]!.$1)
                            .join('; ');
                        final message = ok
                            ? l10n.dpiitResultEligible
                            : '${l10n.dpiitResultNotEligible}\n'
                                  '${l10n.dpiitResultUnmet(missing)}';
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: resultColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  ok ? Icons.check_circle : Icons.cancel,
                                  color: resultColor,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: AppGoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: resultColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          unmet = unmetDpiitCriteria(met);
                          passed = unmet.isEmpty;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.dpiitCheckEligibility,
                        style: AppGoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
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
