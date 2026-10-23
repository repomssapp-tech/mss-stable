import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class StepIndicatorBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const StepIndicatorBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1E293B),
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: context.l10n.actionBack,
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              context.l10n.simpleProfileStepIndicator(currentStep, totalSteps),
              style: AppGoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppGoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppGoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
