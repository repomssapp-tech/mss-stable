import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'assisted_selection_card.dart';

class Step6EducationSelector extends StatelessWidget {
  final String selectedEducation;
  final ValueChanged<String> onEducationSelected;

  const Step6EducationSelector({
    super.key,
    required this.selectedEducation,
    required this.onEducationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final educations = [
      {
        'id': 'School',
        'title': l10n.eduSchool,
        'subtitle': l10n.eduDescSchool,
        'icon': Icons.backpack_outlined,
      },
      {
        'id': 'Diploma',
        'title': l10n.eduDiploma,
        'subtitle': l10n.eduDescDiploma,
        'icon': Icons.handyman_outlined,
      },
      {
        'id': 'Undergraduate',
        'title': l10n.eduUndergraduate,
        'subtitle': l10n.eduDescUndergraduate,
        'icon': Icons.school_outlined,
      },
      {
        'id': 'Postgraduate',
        'title': l10n.eduPostgraduate,
        'subtitle': l10n.eduDescPostgraduate,
        'icon': Icons.psychology_outlined,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < educations.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AssistedSelectionCard(
            title: educations[i]['title'] as String,
            subtitle: educations[i]['subtitle'] as String?,
            icon: educations[i]['icon'] as IconData?,
            isSelected:
                selectedEducation.toLowerCase() ==
                (educations[i]['id'] as String).toLowerCase(),
            onTap: () => onEducationSelected(educations[i]['id'] as String),
          ),
        ],
      ],
    );
  }
}
