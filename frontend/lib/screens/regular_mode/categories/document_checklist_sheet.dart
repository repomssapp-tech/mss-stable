import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../utils/app_text.dart';

/// Business-setup document checklist helper per entity type.
List<String> _docChecklist(AppLocalizations l10n, String entityType) {
  if (entityType == 'Sole Proprietorship') {
    return [
      l10n.docItemProprietorPanAadhaar,
      l10n.docItemUdyamRegistration,
      l10n.docItemShopEstablishmentLicence,
      l10n.docItemProprietorBankAccount,
      l10n.docItemGstRegistrationOptional,
    ];
  } else if (entityType == 'Partnership') {
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

/// Interactive business-setup document checklist modal sheet.
class DocumentChecklistSheet extends StatefulWidget {
  const DocumentChecklistSheet({
    super.key,
    this.initialEntityType = 'Private Limited',
  });

  final String initialEntityType;

  @override
  State<DocumentChecklistSheet> createState() => _DocumentChecklistSheetState();
}

class _DocumentChecklistSheetState extends State<DocumentChecklistSheet> {
  late String _selectedType;
  final Set<String> _checkedDocs = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialEntityType;
  }

  void _toggleDoc(String item) {
    setState(() {
      if (_checkedDocs.contains(item)) {
        _checkedDocs.remove(item);
      } else {
        _checkedDocs.add(item);
      }
    });
  }

  void _copyChecklist(List<String> checklist, String entityName) {
    final buffer = StringBuffer();
    buffer.writeln('📋 $entityName - ${context.l10n.docChecklistTitle}');
    for (final doc in checklist) {
      final isDone = _checkedDocs.contains(doc);
      buffer.writeln('${isDone ? "[✓]" : "[ ]"} $doc');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      AppToast.showSuccess(context, context.l10n.resultsCopiedToClipboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final checklist = _docChecklist(l10n, _selectedType);
    final checkedCount = checklist.where(_checkedDocs.contains).length;
    final progress = checklist.isEmpty ? 0.0 : checkedCount / checklist.length;

    final entityEntries = <String, String>{
      'Sole Proprietorship': l10n.docEntitySoleProprietorship,
      'Private Limited': l10n.docEntityPrivateLimited,
      'Partnership': l10n.docEntityPartnership,
      'One Person Company (OPC)': l10n.docEntityOpc,
      'LLP': l10n.docEntityLlp,
    };
    final selectedEntityLabel = entityEntries[_selectedType] ?? _selectedType;

    return Padding(
      key: const Key('doc-checklist-sheet'),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: 14,
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
                    Icons.rule_folder_outlined,
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
                        l10n.docChecklistTitle,
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.docChecklistSubtitle,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('doc-checklist-copy-btn'),
                  onPressed: () =>
                      _copyChecklist(checklist, selectedEntityLabel),
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  tooltip: l10n.copyChecklistTooltip,
                ),
                IconButton(
                  key: const Key('doc-checklist-close-btn'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  tooltip: l10n.close,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.docEntityType,
              style: context.text.label.copyWith(color: AppColors.textBody),
            ),
            const SizedBox(height: AppSpacing.tight),
            DropdownButtonFormField<String>(
              key: const Key('doc-entity-type-dropdown'),
              initialValue: _selectedType,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              items: entityEntries.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value, style: context.text.bodySmall),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.docRequiredDocuments,
                    style: context.text.label.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.hairline,
                  ),
                  decoration: BoxDecoration(
                    color:
                        checkedCount == checklist.length && checklist.isNotEmpty
                        ? AppColors.successSoft
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$checkedCount / ${checklist.length}',
                    style: context.text.label.copyWith(
                      color:
                          checkedCount == checklist.length &&
                              checklist.isNotEmpty
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('doc-progress-indicator'),
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  checkedCount == checklist.length && checklist.isNotEmpty
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  final item = checklist[index];
                  final isChecked = _checkedDocs.contains(item);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: InkWell(
                      key: Key('doc-checklist-item-$index'),
                      onTap: () => _toggleDoc(item),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppColors.successSoft
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChecked
                                ? AppColors.success
                                : AppColors.surfaceMuted,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isChecked
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isChecked
                                  ? AppColors.success
                                  : AppColors.iconMuted,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                item,
                                style: context.text.label.copyWith(
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isChecked
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('doc-close-button'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.docCloseChecklist),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the business-setup document checklist bottom sheet.
void showDocumentChecklistSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const DocumentChecklistSheet(),
  );
}
