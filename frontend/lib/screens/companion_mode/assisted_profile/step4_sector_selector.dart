import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'assisted_selection_card.dart';

class Step4SectorSelector extends StatelessWidget {
  final String selectedSector;
  final ValueChanged<String> onSectorSelected;

  const Step4SectorSelector({
    super.key,
    required this.selectedSector,
    required this.onSectorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final sectors = [
      {
        'id': 'Agriculture',
        'title': l10n.sectorAgri,
        'icon': Icons.eco_outlined,
      },
      {
        'id': 'Manufacturing',
        'title': l10n.sectorManufacturing,
        'icon': Icons.precision_manufacturing_outlined,
      },
      {
        'id': 'Retail',
        'title': l10n.sectorRetail,
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'id': 'Textiles',
        'title': l10n.sectorTextiles,
        'icon': Icons.dry_cleaning_outlined,
      },
      {
        'id': 'Food Processing',
        'title': l10n.sectorFood,
        'icon': Icons.restaurant_outlined,
      },
      {
        'id': 'Services',
        'title': l10n.sectorServices,
        'icon': Icons.devices_outlined,
      },
      {
        'id': 'Handicrafts',
        'title': l10n.sectorHandicrafts,
        'icon': Icons.brush_outlined,
      },
      {
        'id': 'General',
        'title': l10n.sectorGeneral,
        'icon': Icons.all_inclusive_outlined,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < sectors.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AssistedSelectionCard(
            title: sectors[i]['title'] as String,
            icon: sectors[i]['icon'] as IconData?,
            isSelected: selectedSector.toLowerCase() ==
                (sectors[i]['id'] as String).toLowerCase(),
            onTap: () => onSectorSelected(sectors[i]['id'] as String),
          ),
        ],
      ],
    );
  }
}
