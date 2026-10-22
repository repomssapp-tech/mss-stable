import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../utils/responsive.dart';

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
                          Icons.percent_outlined,
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
                              context.l10n.calcGstTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              context.l10n.calcGstSub,
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
                    context.l10n.calcBaseAmountLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
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
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '50000',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      helperText: context.l10n.calcBaseAmountHelper,
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
                  Text(
                    context.l10n.calcGstRateLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
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
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => gstPercentage = rate);
                              }
                            },
                            selectedColor: const Color(0xFFEFF6FF),
                            backgroundColor: Colors.white,
                            checkmarkColor: const Color(0xFF2563EB),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
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
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        context.l10n.calcErrValidBaseAmount,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
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
                                  context.l10n.calcBasePrice,
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${baseVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.tight,
                            ),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          if (interState)
                            _taxRow(
                              'IGST (${gstPercentage.toStringAsFixed(0)}%)',
                              igstVal,
                            )
                          else ...[
                            _taxRow(
                              'CGST (${(gstPercentage / 2).toStringAsFixed(1)}%)',
                              cgstVal,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _taxRow(
                              'SGST (${(gstPercentage / 2).toStringAsFixed(1)}%)',
                              sgstVal,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.tight,
                            ),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.calcTotalInvoice,
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
                                    '₹ ${totalVal.toStringAsFixed(2)}',
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.calcBtnCalculateTax,
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

/// One tax line in the result card: label on the left, rupee amount right.
Widget _taxRow(String label, double amount) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible(
      child: Text(
        label,
        softWrap: true,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
      ),
    ),
    const SizedBox(width: AppSpacing.sm),
    Flexible(
      child: FitOneLine(
        alignment: Alignment.centerRight,
        child: Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ),
  ],
);
