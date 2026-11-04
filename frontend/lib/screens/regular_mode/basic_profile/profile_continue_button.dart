import 'package:flutter/material.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

/// Sticky CTA button at the bottom of [BasicProfileScreen]'s card. Disabled
/// (grey) whenever the current step's validity gate isn't satisfied yet;
/// shows a spinner while the final submit is in flight.
class ProfileContinueButton extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final bool isStep2Valid;
  final String? selectedRole;
  final bool isStep4Valid;
  final VoidCallback? onPressed;

  static const Color kPrimaryBlue = AppColors.primary;

  const ProfileContinueButton({
    super.key,
    required this.currentStep,
    required this.isSubmitting,
    required this.isStep2Valid,
    required this.selectedRole,
    required this.isStep4Valid,
    required this.onPressed,
  });

  bool get _isEnabled {
    if (currentStep == 2 && !isStep2Valid) return false;
    if (currentStep == 3 && selectedRole == null) return false;
    if (currentStep == 4 && !isStep4Valid) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ElevatedButton(
      // Still tappable when incomplete (it then explains what is missing),
      // but drawn in the theme's disabled colours until every field is valid.
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          _isEnabled ? AppColors.primary : AppColors.disabledBg,
        ),
        foregroundColor: WidgetStatePropertyAll(
          _isEnabled ? AppColors.textOnPrimary : AppColors.disabledFg,
        ),
      ),
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.textOnPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    currentStep == 4
                        ? l10n.completeProfile
                        : l10n.navContinueButton,
                  ),
                ),
                if (currentStep < 4) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.arrow_forward_rounded, size: AppSize.icon),
                ],
              ],
            ),
    );
  }
}
