import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../utils/money_format.dart';

/// Content section for scheme benefits: the scheme's own words, then its
/// benefit figures (subsidy, amount, maximum, kind of support) as the page's
/// one green moment.
class SchemeBenefitsContent extends StatelessWidget {
  final LocalizedScheme scheme;

  const SchemeBenefitsContent({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final figures = <({IconData icon, String label, String value})>[
      if (scheme.subsidyPercentage != null)
        (
          icon: Icons.percent_rounded,
          label: l10n.benefitSubsidy,
          value: '${scheme.subsidyPercentage!.toStringAsFixed(0)}%',
        ),
      if (scheme.subsidyAmount.isNotEmpty &&
          scheme.subsidyAmount.toLowerCase() != 'not specified')
        (
          icon: Icons.payments_outlined,
          label: l10n.benefitAmount,
          value: scheme.subsidyAmount,
        ),
      // The exact catalog figure, grouped the Indian way, never rounded.
      if (scheme.maxFunding != null)
        (
          icon: Icons.account_balance_wallet_outlined,
          label: l10n.benefitMaximum,
          value: formatInr(
            scheme.maxFunding!,
            decimals: scheme.maxFunding! % 1 == 0 ? 0 : 2,
          ),
        ),
      if (scheme.schemeType.isNotEmpty)
        (
          icon: Icons.category_outlined,
          label: l10n.benefitSupport,
          value: CentralizedTranslator.instance.localizeTag(scheme.schemeType),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (figures.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final f in figures)
                    ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: tileWidth),
                      child: _FigureTile(
                        icon: f.icon,
                        label: f.label,
                        value: f.value,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          scheme.benefits.isEmpty
              ? context.l10n.benefitsOfficialSourceFallback
              : scheme.benefits,
          style: context.text.body.copyWith(color: AppColors.textBody),
        ),
      ],
    );
  }
}

class _FigureTile extends StatelessWidget {
  const _FigureTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTagStyle.benefit.background,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSize.iconSm, color: AppTagStyle.benefit.text),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: context.text.cardTitle.copyWith(
              color: AppTagStyle.benefit.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
