import '../../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class ExportInteractivePanel extends StatefulWidget {
  final Color iconColor;

  const ExportInteractivePanel({super.key, required this.iconColor});

  @override
  State<ExportInteractivePanel> createState() => _ExportInteractivePanelState();
}

class _ExportInteractivePanelState extends State<ExportInteractivePanel> {
  final List<Map<String, dynamic>> _exportChecklist = [
    {
      'question': 'Do you have an Import Export Code (IEC) from DGFT?',
      'checked': false,
      'tip': 'Apply online on dgft.gov.in. It is issued instantly against PAN.',
    },
    {
      'question':
          'Do you have an active Bank Account and AD Code registration?',
      'checked': false,
      'tip':
          'Request an AD (Authorized Dealer) Code from your bank and register it with Customs.',
    },
    {
      'question':
          'Have you identified the HS Code (Harmonized System Code) for your product?',
      'checked': false,
      'tip':
          'HS Codes classify products globally. Search online or consult a customs broker.',
    },
    {
      'question':
          'Is your business registered under Udyam (MSME Registration)?',
      'checked': false,
      'tip':
          'Free registration on udyamregistration.gov.in. Required for export subsidies.',
    },
    {
      'question': 'Do you have an RCMC from an Export Promotion Council?',
      'checked': false,
      'tip':
          'Registration cum Membership Certificate (RCMC) is needed to claim duty refunds/incentives.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    int checkedCount = _exportChecklist
        .where((item) => item['checked'] == true)
        .length;
    double progress = checkedCount / _exportChecklist.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeExportReadinessHeading,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.msmeExportReadinessDescription,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.iconColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: context.text.label.copyWith(color: widget.iconColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(_exportChecklist.length, (index) {
              final item = _exportChecklist[index];
              final qText = CentralizedTranslator.instance.localize(
                item['question'] as String,
              );
              final tipText = CentralizedTranslator.instance.localize(
                item['tip'] as String,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: item['checked'],
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      qText,
                      style: context.text.label.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    activeColor: widget.iconColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        item['checked'] = val ?? false;
                      });
                    },
                  ),
                  if (item['checked'] == false)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xxxl,
                        bottom: AppSpacing.sm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.warningSoft),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              color: AppColors.warning,
                              size: 14,
                            ),
                            const SizedBox(width: AppSpacing.tight),
                            Expanded(
                              child: Text(
                                tipText,
                                style: context.text.bodySmall.copyWith(
                                  color: AppColors.warningText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
