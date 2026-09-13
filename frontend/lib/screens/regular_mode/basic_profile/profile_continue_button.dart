import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';

/// Sticky CTA button at the bottom of [BasicProfileScreen]'s card. Disabled
/// (grey) whenever the current step's validity gate isn't satisfied yet;
/// shows a spinner while the final submit is in flight.
class ProfileContinueButton extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final bool hasConsentedDataProcessing;
  final bool isStep2Valid;
  final String? selectedRole;
  final bool isStep4Valid;
  final VoidCallback? onPressed;

  static const Color kPrimaryBlue = Color(0xFF2563EB);

  const ProfileContinueButton({
    super.key,
    required this.currentStep,
    required this.isSubmitting,
    required this.hasConsentedDataProcessing,
    required this.isStep2Valid,
    required this.selectedRole,
    required this.isStep4Valid,
    required this.onPressed,
  });

  bool get _isEnabled {
    if (currentStep == 1 && !hasConsentedDataProcessing) return false;
    if (currentStep == 2 && !isStep2Valid) return false;
    if (currentStep == 3 && selectedRole == null) return false;
    if (currentStep == 4 && !isStep4Valid) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEnabled ? kPrimaryBlue : Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
      ),
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FitOneLine(
                    child: Text(
                      currentStep == 4
                          ? l10n.completeProfile
                          : l10n.navContinueButton,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (currentStep < 4) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
    );
  }
}
