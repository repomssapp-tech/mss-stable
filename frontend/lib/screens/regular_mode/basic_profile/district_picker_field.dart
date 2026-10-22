import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/recommendation/indian_districts.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// The onboarding District field: opens a searchable list of the official
/// (LGD) districts of the chosen state, so the district is picked rather than
/// typed (issue #145 item 2.1). The controller holds the district name.
///
/// Until a state is chosen the field explains that the state comes first.
/// A district filled in earlier (typed in an older version, or by location
/// lookup) is still shown and kept until the user picks another one.
class DistrictPickerField extends StatelessWidget {
  const DistrictPickerField({
    super.key,
    required this.controller,
    required this.state,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;

  /// The state chosen above (English catalog name).
  final String state;
  final String? errorText;
  final VoidCallback onChanged;

  bool get _hasState => state.trim().isNotEmpty;

  Future<void> _pick(BuildContext context) async {
    if (!_hasState) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _DistrictPickerSheet(state: state, selected: controller.text.trim()),
    );
    if (picked == null) return;
    controller.text = picked;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final raw = controller.text.trim();
    final shown = raw.isEmpty ? null : raw;
    final hint = _hasState
        ? l10n.profileSelectDistrict
        : l10n.profileSelectStateFirst;
    const outline = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: AppColors.borderStrong),
    );

    return Semantics(
      button: true,
      enabled: _hasState,
      label: l10n.district,
      value: shown ?? '',
      hint: hint,
      excludeSemantics: true,
      child: InkWell(
        onTap: _hasState ? () => _pick(context) : null,
        borderRadius: AppRadius.mdAll,
        child: InputDecorator(
          isEmpty: shown == null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.text.body.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(
              Icons.domain_outlined,
              color: AppColors.textMuted,
              size: AppSize.icon,
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textMuted,
            ),
            errorText: errorText,
            errorStyle: context.text.bodySmall.copyWith(
              color: AppColors.danger,
            ),
            filled: true,
            fillColor: _hasState ? AppColors.surface : AppColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: outline,
            enabledBorder: outline,
          ),
          child: shown == null
              ? null
              : Text(
                  shown,
                  style: context.text.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Searchable list of the chosen state's districts. Pops with the name.
class _DistrictPickerSheet extends StatefulWidget {
  const _DistrictPickerSheet({required this.state, required this.selected});

  final String state;
  final String selected;

  @override
  State<_DistrictPickerSheet> createState() => _DistrictPickerSheetState();
}

class _DistrictPickerSheetState extends State<_DistrictPickerSheet> {
  late final Future<List<String>> _districts = IndianDistricts.forState(
    widget.state,
  );
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.profileSearchDistrictHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _districts,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final q = _query.trim().toLowerCase();
                  final list = [
                    for (final d in snap.data ?? const <String>[])
                      if (q.isEmpty || d.toLowerCase().contains(q)) d,
                  ];
                  if (list.isEmpty) {
                    return Center(child: Text(l10n.profileNoDistrictMatch));
                  }
                  final selected = widget.selected.toLowerCase();
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final name = list[i];
                      final isSelected = name.toLowerCase() == selected;
                      return ListTile(
                        title: Text(name),
                        selected: isSelected,
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.pop(context, name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
