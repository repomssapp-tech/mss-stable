import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../regular_mode/categories/categories_data.dart';
import '../../regular_mode/categories/discover_counts.dart';
import 'assisted_selection_card.dart';

class Step1StateSelector extends StatelessWidget {
  final String selectedState;
  final ValueChanged<String> onStateSelected;

  const Step1StateSelector({
    super.key,
    required this.selectedState,
    required this.onStateSelected,
  });

  static const List<String> _quickPickValues = [
    'Tamil Nadu',
    'Maharashtra',
    'Uttar Pradesh',
    'Karnataka',
    'Gujarat',
  ];

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
    ];

    // True once a state outside the 5 quick picks has actually been chosen
    // via the searchable picker -- never the literal 'Other'.
    final hasCustomSelection =
        selectedState.isNotEmpty &&
        !_quickPickValues.any(
          (v) => v.toLowerCase() == selectedState.toLowerCase(),
        );

    return Column(
      children: [
        for (int i = 0; i < states.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          AssistedSelectionCard(
            title: states[i]['title'] as String,
            subtitle: states[i]['subtitle'] as String?,
            icon: states[i]['icon'] as IconData?,
            isSelected:
                selectedState.toLowerCase() ==
                (states[i]['value'] as String).toLowerCase(),
            onTap: () => onStateSelected(states[i]['value'] as String),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AssistedSelectionCard(
          title: l10n.stateOther,
          subtitle: hasCustomSelection ? selectedState : l10n.regionAllIndia,
          icon: Icons.public_outlined,
          isSelected: hasCustomSelection,
          onTap: () async {
            final picked = await _showStatePicker(context);
            if (picked != null) onStateSelected(picked);
          },
        ),
      ],
    );
  }

  Future<String?> _showStatePicker(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filtered = allStatesList
                .where(
                  (state) => localizedProperName(
                    state,
                    provider,
                  ).toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheetContext.l10n.allStatesAndUts,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText:
                              sheetContext.l10n.searchStateOrUtPlaceholder,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final state = filtered[index];
                            return ListTile(
                              title: Text(localizedProperName(state, provider)),
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(state),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
