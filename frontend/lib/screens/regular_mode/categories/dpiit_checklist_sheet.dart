import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

/// DPIIT startup-recognition eligibility checklist bottom sheet.
///
/// Extracted verbatim from `_CategoriesScreenState._openDpiitChecklist`
/// (frontend refactor C2, slice 5). Self-contained: reads only `context.l10n`,
/// `AppSpacing`. No behaviour change — the four criteria checkboxes and the
/// AND-gate result logic are unchanged.
void showDpiitChecklistSheet(BuildContext context) {
  final l10n = context.l10n;
  bool isPvtLtdOrLlp = false;
  bool isUnder10Years = false;
  bool turnoverUnder100Cr = false;
  bool isInnovative = false;
  String result = '';
  Color resultColor = const Color(0xFF2563EB);

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
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              l10n.dpiitSubtitle,
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Text(
                            l10n.dpiitCriteriaRegistered,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n.dpiitCriteriaRegisteredSub,
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: isPvtLtdOrLlp,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) =>
                              setModalState(() => isPvtLtdOrLlp = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: Text(
                            l10n.dpiitCriteriaAge,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n.dpiitCriteriaAgeSub,
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: isUnder10Years,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(
                            () => isUnder10Years = val ?? false,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: Text(
                            l10n.dpiitCriteriaTurnover,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n.dpiitCriteriaTurnoverSub,
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: turnoverUnder100Cr,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(
                            () => turnoverUnder100Cr = val ?? false,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: Text(
                            l10n.dpiitCriteriaInnovation,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n.dpiitCriteriaInnovationSub,
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: isInnovative,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) =>
                              setModalState(() => isInnovative = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                        ),
                      ],
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
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              resultColor == const Color(0xFF047857)
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: resultColor,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                result,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor,
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
                        final eligible =
                            isPvtLtdOrLlp &&
                            isUnder10Years &&
                            turnoverUnder100Cr &&
                            isInnovative;
                        setModalState(() {
                          if (eligible) {
                            result = l10n.dpiitResultEligible;
                            resultColor = const Color(0xFF0D9488); // Teal Green
                          } else {
                            result = l10n.dpiitResultNotEligible;
                            resultColor = const Color(0xFFDC2626); // Red
                          }
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
