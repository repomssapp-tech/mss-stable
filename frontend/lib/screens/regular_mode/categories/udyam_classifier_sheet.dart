import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/msme_classification.dart';

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
  Color resultColor = const Color(0xFF1E293B);

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
                          Icons.domain_verification,
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
                              CentralizedTranslator.instance.localize(
                                'Udyam MSME Classifier',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              CentralizedTranslator.instance.localize(
                                'Classify your business under official government guidelines.',
                              ),
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
                    CentralizedTranslator.instance.localize(
                      'Investment in Plant & Machinery',
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
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
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '0.5',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      suffixText: context.l10n.croreSuffix,
                      helperText: CentralizedTranslator.instance.localize(
                        'Enter original purchase value of machinery in Crores',
                      ),
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
                    CentralizedTranslator.instance.localize('Annual Turnover'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
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
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '3.0',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      suffixText: context.l10n.croreSuffix,
                      helperText: CentralizedTranslator.instance.localize(
                        'Enter total revenue/sales of last financial year in Crores',
                      ),
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
                                      CentralizedTranslator.instance.localize(
                                        'Classification Result',
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      CentralizedTranslator.instance.localize(
                                        result,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: resultColor,
                                      ),
                                    ),
                                    if (subResult.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        CentralizedTranslator.instance.localize(
                                          subResult,
                                        ),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF475569),
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
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double invest =
                            double.tryParse(investmentController.text) ?? 0;
                        final double turn =
                            double.tryParse(turnoverController.text) ?? 0;

                        if (invest <= 0 || turn <= 0) {
                          setModalState(() {
                            result = 'Invalid Input';
                            subResult =
                                'Please enter valid values greater than 0';
                            resultColor = const Color(0xFFDC2626);
                          });
                          return;
                        }

                        String category = '';
                        switch (classifyMsme(
                          investmentCr: invest,
                          turnoverCr: turn,
                        )) {
                          case MsmeTier.micro:
                            category = 'MICRO Enterprise';
                            resultColor = const Color(0xFF0D9488); // Teal
                          case MsmeTier.small:
                            category = 'SMALL Enterprise';
                            resultColor = const Color(0xFF2563EB); // Royal Blue
                          case MsmeTier.medium:
                            category = 'MEDIUM Enterprise';
                            resultColor = const Color(0xFFD97706); // Amber
                          case MsmeTier.large:
                            category = 'Large Enterprise (Beyond MSME Limits)';
                            resultColor = const Color(0xFFDC2626); // Red
                        }

                        setModalState(() {
                          result = category;
                          subResult = msmeLimitsSummary();
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
                        CentralizedTranslator.instance.localize(
                          'Calculate Classification',
                        ),
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
