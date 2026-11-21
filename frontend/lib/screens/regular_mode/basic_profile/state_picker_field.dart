import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/recommendation/indian_states.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../services/location_lock/location_lock.dart';

/// The onboarding State field: shows the chosen state in the app language
/// and opens a searchable list of every state and union territory, so the
/// state is picked rather than typed (a typo broke state-based scheme
/// matching). The controller always holds the English catalog name.
class StatePickerField extends StatelessWidget {
  const StatePickerField({
    super.key,
    required this.controller,
    required this.errorText,
    required this.onChanged,
    this.onStateChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onChanged;

  /// Called before [onChanged] when the user picks a different state.
  final VoidCallback? onStateChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _StatePickerSheet(selected: IndianStates.canonical(controller.text)),
    );
    if (picked == null) return;
    final changed =
        IndianStates.canonical(controller.text) !=
        IndianStates.canonical(picked);
    controller.text = picked;
    if (changed) onStateChanged?.call();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    // Location lock: the state comes from GPS and cannot be picked.
    final locked = LocationScope.stateName;
    if (locked != null && IndianStates.canonical(controller.text) != locked) {
      controller.text = locked;
    }
    final raw = controller.text.trim();
    final shown = raw.isEmpty
        ? null
        : IndianStates.displayName(IndianStates.canonical(raw), lang);
    const outline = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: AppColors.borderStrong),
    );

    return Semantics(
      button: true,
      label: l10n.state,
      value: shown ?? '',
      hint: l10n.profileSelectState,
      excludeSemantics: true,
      child: InkWell(
        onTap: locked != null ? null : () => _pick(context),
        borderRadius: AppRadius.mdAll,
        child: InputDecorator(
          isEmpty: shown == null,
          decoration: InputDecoration(
            hintText: l10n.profileSelectState,
            hintStyle: context.text.body.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(
              Icons.map_outlined,
              color: AppColors.textMuted,
              size: AppSize.icon,
            ),
            suffixIcon: Icon(
              locked != null
                  ? Icons.lock_outline_rounded
                  : Icons.arrow_drop_down_rounded,
              color: AppColors.textMuted,
            ),
            helperText: locked != null ? l10n.locationStateLocked : null,
            errorText: locked != null ? null : errorText,
            errorStyle: context.text.bodySmall.copyWith(
              color: AppColors.danger,
            ),
            filled: true,
            fillColor: AppColors.surface,
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

/// Searchable list of states and union territories, in the app language with
/// the English name underneath. Pops with the English name.
class _StatePickerSheet extends StatefulWidget {
  const _StatePickerSheet({required this.selected});

  final String selected;

  @override
  State<_StatePickerSheet> createState() => _StatePickerSheetState();
}

class _StatePickerSheetState extends State<_StatePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final q = _query.trim().toLowerCase();
    final code = IndianStates.code(q);
    final canonical = code == null
        ? IndianStates.canonical(q)
        : IndianStates.nameForCode(code);
    final states = [
      for (final name in IndianStates.names)
        if (q.isEmpty ||
            name == canonical ||
            name.toLowerCase().contains(q) ||
            IndianStates.displayName(name, lang).toLowerCase().contains(q))
          name,
    ];

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
                  hintText: l10n.profileSearchStateHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
              ),
            ),
            Expanded(
              child: states.isEmpty
                  ? Center(child: Text(l10n.profileNoStateMatch))
                  : ListView.builder(
                      itemCount: states.length,
                      itemBuilder: (context, i) {
                        final name = states[i];
                        final local = IndianStates.displayName(name, lang);
                        final selected = name == widget.selected;
                        return ListTile(
                          title: Text(local),
                          subtitle: local == name ? null : Text(name),
                          selected: selected,
                          trailing: selected
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.pop(context, name),
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
