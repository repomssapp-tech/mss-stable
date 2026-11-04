import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'assisted_selection_card.dart';

class Step3RoleStageSelector extends StatelessWidget {
  final String selectedRoleId;
  final ValueChanged<String> onRoleSelected;

  const Step3RoleStageSelector({
    super.key,
    required this.selectedRoleId,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final roles = [
      {
        'id': 'entrepreneur',
        'title': l10n.workNewBusiness,
        'subtitle': l10n.workNewBusinessDesc,
        'icon': Icons.lightbulb_outline_rounded,
        'color': AppColors.primary,
      },
      {
        'id': 'existing_business',
        'title': l10n.workExistingBusiness,
        'subtitle': l10n.workExistingBusinessDesc,
        'icon': Icons.storefront_outlined,
        'color': AppColors.primary,
      },
      {
        'id': 'farmer',
        'title': l10n.workFarmer,
        'subtitle': l10n.workFarmerDesc,
        'icon': Icons.agriculture_outlined,
        'color': AppColors.primary,
      },
      {
        'id': 'artisan',
        'title': l10n.workArtisan,
        'subtitle': l10n.workArtisanDesc,
        'icon': Icons.palette_outlined,
        'color': AppColors.primary,
      },
      {
        'id': 'student',
        'title': l10n.workStudent,
        'subtitle': l10n.workStudentDesc,
        'icon': Icons.school_outlined,
        'color': AppColors.primary,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < roles.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AssistedSelectionCard(
            title: roles[i]['title'] as String,
            subtitle: roles[i]['subtitle'] as String?,
            icon: roles[i]['icon'] as IconData?,
            activeColor: roles[i]['color'] as Color,
            isSelected: selectedRoleId == roles[i]['id'],
            onTap: () => onRoleSelected(roles[i]['id'] as String),
          ),
        ],
      ],
    );
  }
}
