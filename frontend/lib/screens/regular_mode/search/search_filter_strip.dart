import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

/// Reusable dropdown chip with popup menu for search sorting or filtering.
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

    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: PopupMenuButton<String>(
        onSelected: onChanged,
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        itemBuilder: (context) => options
            .map(
              (opt) => PopupMenuItem(
                value: opt,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      show(opt),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: opt == currentValue
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: opt == currentValue
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    if (opt == currentValue)
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (currentValue.isEmpty || currentValue == 'All')
                    ? label
                    : '$label: ${show(currentValue)}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ],
          ),
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

  const SearchFilterStrip({
    super.key,
    required this.facetCount,
    required this.isForMeActive,
    required this.sortBy,
    required this.onOpenFilterPanel,
    required this.onToggleForMe,
    required this.onSortChanged,
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
    // Wraps instead of scrolling sideways, so a long label (Tamil "Sort")
    // moves to a second line rather than being cut off at the screen edge
    // (test report L10N-06 / BUG-14).
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Filter Button
        OutlinedButton.icon(
          onPressed: onOpenFilterPanel,
          icon: const Icon(
            Icons.filter_list,
            size: 14,
            color: Color(0xFF2563EB),
          ),
          label: Text(
            facetCount > 0
                ? '${context.l10n.filterButton} · $facetCount'
                : context.l10n.filterButton,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.tight,
            ),
          ),
        ),

        // "For Me" -- opt-in profile-eligibility filter
        OutlinedButton.icon(
          onPressed: onToggleForMe,
          icon: Icon(
            Icons.auto_awesome,
            size: 14,
            color: isForMeActive ? Colors.white : const Color(0xFF2563EB),
          ),
          label: Text(
            context.l10n.forMe,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isForMeActive ? Colors.white : const Color(0xFF2563EB),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: isForMeActive
                ? const Color(0xFF2563EB)
                : Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.tight,
            ),
          ),
        ),

        // Sort
        SearchDropdownChip(
          label: context.l10n.sortLabel,
          options: const [
            'Relevance',
            'Best match for me',
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
