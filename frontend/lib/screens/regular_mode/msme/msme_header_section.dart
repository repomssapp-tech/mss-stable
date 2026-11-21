import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class MsmeHeaderSection extends StatelessWidget {
  final String moduleId;
  final String description;
  final Color iconColor;
  final Color themeColor;

  const MsmeHeaderSection({
    super.key,
    required this.moduleId,
    required this.description,
    required this.iconColor,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final localizedDescription = CentralizedTranslator.instance.localizeFor(
      Localizations.localeOf(context).languageCode,
      description,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (localizedDescription.trim().isNotEmpty) ...[
            Text(
              localizedDescription,
              style: context.text.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _buildWhatUserGets(context),
        ],
      ),
    );
  }

  Widget _buildWhatUserGets(BuildContext context) {
    final valueText = switch (moduleId) {
      'schemes' => context.l10n.msmeValueSchemes,
      'finance' => context.l10n.msmeValueFinance,
      'tax_gst' => context.l10n.msmeValueTaxGst,
      'export' => context.l10n.msmeValueExport,
      'treds' => context.l10n.msmeValueTreds,
      'csr' => context.l10n.msmeValueCsr,
      'govt' => context.l10n.msmeValueGovt,
      'institutions' => context.l10n.msmeValueInstitutions,
      'udyam' => context.l10n.msmeValueUdyam,
      _ => '',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.05),
            themeColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: iconColor, size: AppSize.icon),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  context.l10n.msmeWhatTheUserGets,
                  softWrap: true,
                  style: context.text.label.copyWith(color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            valueText,
            style: context.text.button.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
