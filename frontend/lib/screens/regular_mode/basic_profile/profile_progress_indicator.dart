import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class ProfileProgressIndicator extends StatelessWidget {
  const ProfileProgressIndicator({super.key, required this.currentStep});

  final int currentStep;

  static const _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.assessStepLabel(currentStep, _totalSteps);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: context.text.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: LinearProgressIndicator(
            value: currentStep / _totalSteps,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppSpacing.xs),
            ),
          ),
        ),
      ],
    );
  }
}
