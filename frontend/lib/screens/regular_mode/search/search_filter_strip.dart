import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Reusable dropdown chip with popup menu for search sorting or filtering,
/// drawn like the outlined buttons beside it.
class SearchDropdownChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final String currentValue;
  final ValueChanged<String> onChanged;
  final String Function(String value)? displayOf;

  const SearchDropdownChip({
    super.key,
    required this.label,
    required this.options,
    required this.currentValue,
    required this.onChanged,
    this.displayOf,
  });

  @override
  Widget build(BuildContext context) {
    String show(String v) => displayOf?.call(v) ?? v;
    final bool isActive =
        currentValue.isNotEmpty &&
        currentValue != 'All' &&
        currentValue != 'Relevance';
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => [
        for (final opt in options)
          PopupMenuItem(
            value: opt,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    show(opt),
                    style: context.text.body.copyWith(
                      fontWeight: opt == currentValue
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: opt == currentValue
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (opt == currentValue)
                  const Icon(
                    Icons.check_rounded,
                    size: AppSize.iconSm,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSize.controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderStrong,
            width: AppSize.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                (currentValue.isEmpty || currentValue == 'All')
                    ? label
                    : '$label: ${show(currentValue)}',
                style: context.text.button.copyWith(color: color),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: AppSize.icon,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Discover filter strip containing Filter · For Me · Sort buttons.
class SearchFilterStrip extends StatelessWidget {
  final int facetCount;
  final bool isForMeActive;
  final String sortBy;
  final VoidCallback onOpenFilterPanel;
  final VoidCallback onToggleForMe;
  final ValueChanged<String> onSortChanged;

  /// False for a guest: "For Me" and "Best match for me" rank by an account
  /// profile a guest does not have.
  final bool showForMe;

  const SearchFilterStrip({
    super.key,
    required this.facetCount,
    required this.isForMeActive,
    required this.sortBy,
    required this.onOpenFilterPanel,
    required this.onToggleForMe,
    required this.onSortChanged,
    this.showForMe = true,
  });

  String _sortLabel(BuildContext context, String value) {
    switch (value) {
      case 'Best match for me':
        return context.l10n.sortBestMatch;
      case 'Scheme name (A-Z)':
        return context.l10n.sortSchemeNameAz;
      case 'Relevance':
      default:
        return context.l10n.sortRelevance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forMeIcon = Icon(
      isForMeActive ? Icons.check_rounded : Icons.person_outline_rounded,
      size: AppSize.iconSm,
    );
    final forMeLabel = Text(context.l10n.forMe);

    // Wraps instead of scrolling sideways, so a long label (Tamil "Sort")
    // moves to a second line rather than being cut off at the screen edge
    // (test report L10N-06 / BUG-14).
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenFilterPanel,
          icon: const Icon(Icons.filter_list_rounded, size: AppSize.iconSm),
          label: Text(
            facetCount > 0
                ? '${context.l10n.filterButton} · $facetCount'
                : context.l10n.filterButton,
          ),
        ),

        // "For Me" -- opt-in profile-eligibility filter. While on, it shows a
        // tick on the selected blue tint, like a chosen chip.
        if (showForMe)
          OutlinedButton.icon(
            onPressed: onToggleForMe,
            style: isForMeActive
                ? const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      AppColors.primarySoft,
                    ),
                  )
                : null,
            icon: forMeIcon,
            label: forMeLabel,
          ),

        SearchDropdownChip(
          label: context.l10n.sortLabel,
          options: [
            'Relevance',
            if (showForMe) 'Best match for me',
            'Scheme name (A-Z)',
          ],
          currentValue: sortBy,
          onChanged: onSortChanged,
          displayOf: (v) => _sortLabel(context, v),
        ),
      ],
    );
  }
}
