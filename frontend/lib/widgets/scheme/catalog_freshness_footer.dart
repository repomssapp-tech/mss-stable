import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/catalog/mss_catalog_bundle.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../utils/app_colors.dart';

/// 2.7 (audit_fix.md): a subtle indicator of catalog data currency, so a
/// user can tell "no match" apart from "this device's local catalog is
/// old" -- worded as data currency, not degradation, since offline-first
/// is the intended design here, not something to apologize for.
class CatalogFreshnessFooter extends StatelessWidget {
  const CatalogFreshnessFooter({super.key});

  String _formatDate(DateTime date, List<String> months) {
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final months = context.l10n.monthAbbrList
        .split(',')
        .map((m) => m.trim())
        .toList();
    return FutureBuilder<MssCatalogBundle>(
      future: MssCatalogBundle.load(),
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        if (bundle == null) return const SizedBox.shrink();

        final dateText = bundle.releasedAt != null
            ? _formatDate(bundle.releasedAt!.toLocal(), months)
            : null;
        final l10n = context.l10n;
        final label = dateText != null
            ? l10n.catalogFreshnessLabelUpdated(dateText, bundle.releaseTag)
            : l10n.catalogFreshnessLabel(bundle.releaseTag);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: Text(
              label,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
