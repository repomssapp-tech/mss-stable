import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';

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
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        Icons.account_balance_wallet_outlined,
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
                            l10n.subsidyTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            l10n.subsidySubtitle,
                            style: GoogleFonts.inter(
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
                Text(
                  l10n.subsidyProjectCost,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
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
                    fillColor: const Color(0xFFF8FAFC),
                    hintText: '25',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixText: '₹ ',
                    suffixText: l10n.subsidyProjectCostSuffix,
                    helperText: l10n.subsidyProjectCostHelper,
                    helperStyle: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF64748B),
                    ),
                    suffixStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    prefixStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.subsidyPercentLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
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
                    fillColor: const Color(0xFFF8FAFC),
                    hintText: '15',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    suffixText: '%',
                    helperText: l10n.subsidyPercentHelper,
                    helperStyle: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF64748B),
                    ),
                    suffixStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
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
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      error,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
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
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: FitOneLine(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  l10n.subsidyLakhFmt(
                                    costVal.toStringAsFixed(2),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
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
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: FitOneLine(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  l10n.subsidyLakhFmt(
                                    subsidyAmountVal.toStringAsFixed(2),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                          child: Divider(color: Color(0xFFDBEAFE), height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.subsidyNetCost,
                                softWrap: true,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: FitOneLine(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  l10n.subsidyLakhFmt(
                                    netCostVal.toStringAsFixed(2),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
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
                  height: 44,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.subsidyCalculate,
                      style: GoogleFonts.inter(
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
