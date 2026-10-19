import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'assisted_selection_card.dart';

class Step5CommunitySelector extends StatelessWidget {
  final String selectedCommunity;
  final ValueChanged<String> onCommunitySelected;

  const Step5CommunitySelector({
    super.key,
    required this.selectedCommunity,
    required this.onCommunitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final communities = [
      {
        'id': 'OBC',
        'title': l10n.commObcBcMbc,
        'subtitle': l10n.commDescObc,
        'icon': Icons.groups_2_outlined,
      },
      {
        'id': 'SC',
        'title': l10n.commScCategory,
        'subtitle': l10n.commDescSc,
        'icon': Icons.shield_outlined,
      },
      {
        'id': 'ST',
        'title': l10n.commStCategory,
        'subtitle': l10n.commDescSt,
        'icon': Icons.forest_outlined,
      },
      {
        'id': 'Minority',
        'title': l10n.commMinority,
        'subtitle': l10n.commDescMinority,
        'icon': Icons.diversity_3_outlined,
      },
      {
        'id': 'General',
        'title': l10n.commGeneralOc,
        'subtitle': l10n.commDescGeneral,
        'icon': Icons.public_outlined,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < communities.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AssistedSelectionCard(
            title: communities[i]['title'] as String,
            subtitle: communities[i]['subtitle'] as String?,
            icon: communities[i]['icon'] as IconData?,
            isSelected:
                selectedCommunity.toUpperCase() ==
                (communities[i]['id'] as String).toUpperCase(),
            onTap: () => onCommunitySelected(communities[i]['id'] as String),
          ),
        ],
      ],
    );
  }
}
