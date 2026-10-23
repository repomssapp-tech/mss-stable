import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class Step2GenderAgeSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderSelected;
  final int selectedAge;
  final ValueChanged<int> onAgeChanged;

  const Step2GenderAgeSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
    required this.selectedAge,
    required this.onAgeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final genders = [
      {
        'value': 'Female',
        'label': l10n.genderFemale,
        'icon': Icons.female_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'value': 'Male',
        'label': l10n.genderMale,
        'icon': Icons.male_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'value': 'Other',
        'label': l10n.genderOther,
        'icon': Icons.transgender_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    final agePresets = [18, 25, 35, 45, 55];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gender Row. Equal-height tiles, so a label that wraps to a second
        // line (the Tamil "third gender" label) keeps the row even.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < genders.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildGenderTile(
                    label: genders[i]['label'] as String,
                    value: genders[i]['value'] as String,
                    icon: genders[i]['icon'] as IconData,
                    color: genders[i]['color'] as Color,
                    isSelected:
                        selectedGender.toLowerCase() ==
                        (genders[i]['value'] as String).toLowerCase(),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Age Container
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                l10n.ageSelectLabel,
                style: AppGoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepperButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      if (selectedAge > 18) {
                        onAgeChanged(selectedAge - 1);
                      }
                    },
                    enabled: selectedAge > 18,
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Column(
                    children: [
                      Text(
                        '$selectedAge',
                        style: AppGoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        l10n.ageYearsLabel,
                        style: AppGoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  _buildStepperButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      if (selectedAge < 90) {
                        onAgeChanged(selectedAge + 1);
                      }
                    },
                    enabled: selectedAge < 90,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Preset chips
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: [
                  for (final preset in agePresets)
                    ActionChip(
                      label: Text('$preset'),
                      backgroundColor: selectedAge == preset
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      labelStyle: AppGoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: selectedAge == preset
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selectedAge == preset
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF475569),
                      ),
                      side: BorderSide(
                        color: selectedAge == preset
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFCBD5E1),
                        width: selectedAge == preset ? 1.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => onAgeChanged(preset),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onGenderSelected(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              // Two lines: a three-column row is too narrow for some Tamil
              // and Hindi labels on one line.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppGoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            size: 26,
          ),
        ),
      ),
    );
  }
}
