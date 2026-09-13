import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

/// Static 4-segment stepper + "Step X of 4" fraction text shown at the top
/// of the [BasicProfileScreen] card, above the scrollable step form.
class ProfileProgressIndicator extends StatelessWidget {
  final int currentStep;

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kBorderGrey = Color(0xFFE2E8F0);

  const ProfileProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepper(currentStep),
        const SizedBox(height: AppSpacing.sm),
        Center(child: _buildProgressFraction(context, currentStep)),
      ],
    );
  }

  Widget _buildStepper(int step) {
    return Row(
      children: [
        Expanded(child: _buildProgressSegment(step >= 1)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildProgressSegment(step >= 2)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildProgressSegment(step >= 3)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildProgressSegment(step >= 4)),
      ],
    );
  }

  Widget _buildProgressSegment(bool isCompleted) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted ? kPrimaryBlue : kBorderGrey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildProgressFraction(BuildContext context, int step) {
    final l10n = context.l10n;
    final text = switch (step) {
      1 => l10n.step1Of4,
      2 => l10n.step2Of4,
      3 => l10n.step3Of4,
      4 => l10n.step4Of4,
      _ => l10n.step1Of4,
    };
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kPrimaryBlue,
      ),
    );
  }
}
