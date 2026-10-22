import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// "Inactive" badge for a saved scheme the latest catalog no longer lists as
/// active; the longer reason is its tooltip and screen-reader label.
class InactiveSchemeBadge extends StatelessWidget {
  const InactiveSchemeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.savedInactiveHint,
      child: Semantics(
        label: '${l10n.savedInactiveBadge}. ${l10n.savedInactiveHint}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.hairline,
          ),
          decoration: const BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: AppRadius.xsAll,
          ),
          child: Text(
            l10n.savedInactiveBadge,
            style: context.text.label.copyWith(color: AppColors.warningOnSoft),
          ),
        ),
      ),
    );
  }
}
