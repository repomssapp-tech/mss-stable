import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../l10n/app_localizations.dart';
import 'app_tappable.dart';

/// Horizontal quick-search pills shared by Home and Search (spec_phase3.md
/// §0.1, replaces the duplicated `_buildQuickPills`/`SearchQuickPills`).
class QuickPills extends StatelessWidget {
  const QuickPills({super.key, required this.onSelected});

  /// Receives the QUERY string, not the display label.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pills = <({String label, String query})>[
      (label: l.quickPillPmegp, query: l.quickPillPmegpQuery),
      (label: l.quickPillStartup, query: l.quickPillStartupQuery),
      (label: l.quickPillLoans, query: l.quickPillLoansQuery),
      (label: l.quickPillWomen, query: l.quickPillWomenQuery),
      (label: l.quickPillAscend, query: l.quickPillAscendQuery),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            for (final p in pills)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppTappable(
                  onTap: () => onSelected(p.query),
                  semanticLabel: p.label,
                  borderRadius: AppRadius.pillAll,
                  // Visual pill goes through `decoration` so the ripple is
                  // visible (Phase 2 fix D3).
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.pillAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: AppSize.iconSm,
                        color: AppColors.iconMuted,
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Text(
                        p.label,
                        style: context.text.label.copyWith(color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
