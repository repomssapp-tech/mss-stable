import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

/// Business-setup document checklist bottom sheet (per entity type).
///
/// Extracted verbatim from `_CategoriesScreenState._openDocumentChecklist` and
/// its `_docChecklist` helper (frontend refactor C2, slice 7). Self-contained:
/// reads only `context.l10n` / `AppLocalizations`, `AppSpacing`. No behaviour
/// change.
List<String> _docChecklist(AppLocalizations l10n, String entityType) {
  if (entityType == 'Partnership') {
    return [
      l10n.docItemPartnershipDeed,
      l10n.docItemDeedRegistration,
      l10n.docItemFirmPanTan,
      l10n.docItemFirmBankAccount,
      l10n.docItemGstRegistrationOptional,
    ];
  } else if (entityType == 'LLP') {
    return [
      l10n.docItemLlpNameApproval,
      l10n.docItemFillipForm,
      l10n.docItemLlpAgreement,
      l10n.docItemLlpPanTan,
      l10n.docItemLlpBankAccount,
    ];
  }
  return [
    l10n.docItemDsc,
    l10n.docItemDin,
    l10n.docItemMoaAoa,
    l10n.docItemCoi,
    l10n.docItemCompanyPanTan,
    l10n.docItemCorporateBankAccount,
  ];
}

void showDocumentChecklistSheet(BuildContext context) {
  final l10n = context.l10n;
  String selectedType = 'Private Limited';
  List<String> checklist = _docChecklist(l10n, selectedType);

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
                        Icons.rule_folder_outlined,
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
                            l10n.docChecklistTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            l10n.docChecklistSubtitle,
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
                  l10n.docEntityType,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items:
                      <String, String>{
                        'Private Limited': l10n.docEntityPrivateLimited,
                        'Partnership': l10n.docEntityPartnership,
                        'One Person Company (OPC)': l10n.docEntityOpc,
                        'LLP': l10n.docEntityLlp,
                      }.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedType = val;
                        checklist = _docChecklist(l10n, val);
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.docRequiredDocuments,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: checklist.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEFF2F5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2563EB),
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                checklist[index],
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.docCloseChecklist,
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
