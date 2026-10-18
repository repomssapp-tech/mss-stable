import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';

class ExportInteractivePanel extends StatefulWidget {
  final Color iconColor;

  const ExportInteractivePanel({
    super.key,
    required this.iconColor,
  });

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
    int checkedCount =
        _exportChecklist.where((item) => item['checked'] == true).length;
    double progress = checkedCount / _exportChecklist.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CentralizedTranslator.instance.localize('Export Readiness Assessment'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CentralizedTranslator.instance.localize('Complete this checklist to identify missing links for international trade registration.'),
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF64748B),
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
                      backgroundColor: const Color(0xFFE2E8F0),
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(_exportChecklist.length, (index) {
              final item = _exportChecklist[index];
              final qText = CentralizedTranslator.instance.localize(item['question'] as String);
              final tipText = CentralizedTranslator.instance.localize(item['tip'] as String);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: item['checked'],
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      qText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
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
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              color: Color(0xFFD97706),
                              size: 14,
                            ),
                            const SizedBox(width: AppSpacing.tight),
                            Expanded(
                              child: Text(
                                tipText,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.w500,
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
