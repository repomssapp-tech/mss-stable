import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'assisted_selection_card.dart';

class Step1StateSelector extends StatelessWidget {
  final String selectedState;
  final ValueChanged<String> onStateSelected;

  const Step1StateSelector({
    super.key,
    required this.selectedState,
    required this.onStateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final states = [
      {
        'value': 'Tamil Nadu',
        'title': l10n.stateTamilNadu,
        'subtitle': l10n.regionSouthIndia,
        'icon': Icons.temple_hindu_outlined,
      },
      {
        'value': 'Maharashtra',
        'title': l10n.stateMaharashtra,
        'subtitle': l10n.regionWestIndia,
        'icon': Icons.location_city_outlined,
      },
      {
        'value': 'Uttar Pradesh',
        'title': l10n.stateUttarPradesh,
        'subtitle': l10n.regionNorthIndia,
        'icon': Icons.account_balance_outlined,
      },
      {
        'value': 'Karnataka',
        'title': l10n.stateKarnataka,
        'subtitle': l10n.regionSouthIndia,
        'icon': Icons.hub_outlined,
      },
      {
        'value': 'Gujarat',
        'title': l10n.stateGujarat,
        'subtitle': l10n.regionWestIndia,
        'icon': Icons.factory_outlined,
      },
      {
        'value': 'Other',
        'title': l10n.stateOther,
        'subtitle': l10n.regionAllIndia,
        'icon': Icons.public_outlined,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < states.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AssistedSelectionCard(
            title: states[i]['title'] as String,
            subtitle: states[i]['subtitle'] as String?,
            icon: states[i]['icon'] as IconData?,
            isSelected: selectedState.toLowerCase() ==
                (states[i]['value'] as String).toLowerCase(),
            onTap: () => onStateSelected(states[i]['value'] as String),
          ),
        ],
      ],
    );
  }
}
