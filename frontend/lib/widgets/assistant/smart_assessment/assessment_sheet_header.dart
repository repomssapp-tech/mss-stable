import 'package:flutter/material.dart';
import '../../../screens/regular_mode/categories/categories_data.dart';
import '../../../screens/regular_mode/categories/state_map_painter.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class AssessmentSheetHeader extends StatelessWidget {
  final String cardTitleLocalized;
  final String rawCardTitle;
  final String cardType;
  final Color themeColor;
  final double progress;
  final String stepLabel;
  final String closeTooltip;
  final bool isTamil;
  final VoidCallback onClose;

  const AssessmentSheetHeader({
    super.key,
    required this.cardTitleLocalized,
    required this.rawCardTitle,
    required this.cardType,
    required this.themeColor,
    required this.progress,
    required this.stepLabel,
    required this.closeTooltip,
    required this.isTamil,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                    padding: cardType == 'state'
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(AppSpacing.tight),
                    decoration: cardType == 'state'
                        ? null
                        : BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                    child: cardType == 'state'
                        ? Image.asset(
                            getStateMapAsset(rawCardTitle),
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return CustomPaint(
                                size: const Size(32, 32),
                                painter: StateMapPainter(rawCardTitle),
                              );
                            },
                          )
                        : Icon(
                            cardType == 'ministry'
                                ? Icons.account_balance_rounded
                                : Icons.grid_view_rounded,
                            color: themeColor,
                            size: 16,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      cardTitleLocalized,
                      softWrap: true,
                      style: AppGoogleFonts.poppins(
                        fontSize: isTamil ? 13.0 : 14.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: closeTooltip,
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Progress Bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFEFF6FF),
                  color: themeColor,
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              stepLabel,
              style: AppGoogleFonts.inter(
                fontSize: isTamil ? 9.5 : 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
