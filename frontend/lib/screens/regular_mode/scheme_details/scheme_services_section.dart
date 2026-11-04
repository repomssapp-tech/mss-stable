import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/scheme_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Content section for scheme required services (e.g. GST registration, Udyam certificate).
class SchemeServicesContent extends StatelessWidget {
  final List<SchemeService> services;

  const SchemeServicesContent({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Text(
        context.l10n.noServicesRequiredMsg,
        style: context.text.body.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        for (final service in services)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.hairline),
                  child: Icon(
                    Icons.support_agent_outlined,
                    color: AppColors.iconMuted,
                    size: AppSize.icon,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (service.category.isNotEmpty ||
                          service.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          [
                            service.category,
                            service.description,
                          ].where((value) => value.isNotEmpty).join(' · '),
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (service.mandatory) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.badgeRequired,
                    style: context.text.label.copyWith(
                      color: AppColors.dangerStrong,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
