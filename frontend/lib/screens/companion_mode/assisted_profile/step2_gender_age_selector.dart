import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

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
        'color': AppColors.primary,
      },
      {
        'value': 'Male',
        'label': l10n.genderMale,
        'icon': Icons.male_rounded,
        'color': AppColors.primary,
      },
      {
        'value': 'Other',
        'label': l10n.genderOther,
        'icon': Icons.transgender_rounded,
        'color': AppColors.primary,
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
                    context,
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
            border: Border.all(color: AppColors.border),
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
                style: context.text.button.copyWith(color: AppColors.textMuted),
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
                        style: context.text.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        l10n.ageYearsLabel,
                        style: context.text.body.copyWith(
                          color: AppColors.textMuted,
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
                          ? AppColors.primarySoft
                          : AppColors.background,
                      labelStyle: context.text.body.copyWith(
                        fontWeight: selectedAge == preset
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selectedAge == preset
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: selectedAge == preset
                            ? AppColors.primary
                            : AppColors.borderStrong,
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

  Widget _buildGenderTile(
    BuildContext context, {
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
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
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
                    : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppColors.textMuted,
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
              style: context.text.body.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryDeep
                    : AppColors.textPrimary,
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
            color: enabled ? AppColors.primarySoft : AppColors.surfaceMuted,
            border: Border.all(
              color: enabled ? AppColors.primaryBorder : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? AppColors.primary : AppColors.iconMuted,
            size: 26,
          ),
        ),
      ),
    );
  }
}
