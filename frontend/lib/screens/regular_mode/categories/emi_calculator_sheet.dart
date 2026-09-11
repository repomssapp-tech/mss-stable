import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';

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
                        Icons.calculate_outlined,
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
                            l10n.emiCalcTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            l10n.emiCalcSubtitle,
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
                  l10n.emiLoanAmount,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
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
                    fillColor: const Color(0xFFF8FAFC),
                    hintText: '500000',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixText: '₹ ',
                    helperText: l10n.emiLoanAmountHelper,
                    helperStyle: GoogleFonts.inter(
                      fontSize: 9,
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.emiInterestRate,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
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
                              fillColor: const Color(0xFFF8FAFC),
                              hintText: '9.5',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                              suffixText: '%',
                              helperText: l10n.emiInterestRateHelper,
                              helperStyle: GoogleFonts.inter(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
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
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.tight),
                          TextField(
                            controller: tenureController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              hintText: '60',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                              suffixText: l10n.emiTenureSuffixMo,
                              helperText: l10n.emiTenureHelper,
                              helperStyle: GoogleFonts.inter(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
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
                ] else if (emiVal > 0) ...[
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
                                l10n.emiMonthlyEmi,
                                softWrap: true,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
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
                                  '₹ ${emiVal.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
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
                                l10n.emiPrincipal,
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
                                  '₹ ${principalVal.toStringAsFixed(2)}',
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
                                l10n.emiTotalInterest,
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
                                  '₹ ${interestVal.toStringAsFixed(2)}',
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                          child: Divider(color: Color(0xFFDBEAFE), height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.emiTotalAmount,
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
                                  '₹ ${totalVal.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
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
                      final double p =
                          double.tryParse(loanController.text) ?? 0;
                      final double annualRate =
                          double.tryParse(rateController.text) ?? 0;
                      final double n =
                          double.tryParse(tenureController.text) ?? 0;

                      if (p <= 0 || annualRate <= 0 || n <= 0) {
                        setModalState(() {
                          error = l10n.emiInvalidInputs;
                          emiVal = 0;
                        });
                        return;
                      }

                      final double r = (annualRate / 12) / 100;
                      final double emi =
                          (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.emiCalculate,
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
