import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class AssistedStepFooter extends StatelessWidget {
  final bool isLastStep;
  final bool isSubmitting;
  final bool isEnabled;
  final VoidCallback onContinue;

  const AssistedStepFooter({
    super.key,
    required this.isLastStep,
    required this.isSubmitting,
    required this.isEnabled,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final label = isLastStep
        ? context.l10n.actionFinish
        : context.l10n.actionNext;

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      color: Colors.transparent,
      child: ElevatedButton(
        onPressed: (isEnabled && !isSubmitting) ? onContinue : null,
        child: isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    context.l10n.actionSaving,
                    style: context.text.bodyLarge,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: context.text.bodyLarge),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isLastStep
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}
