import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/money_format.dart';
import '../../l10n/l10n.dart';
import '../../models/user_profile.dart';
import '../../services/recommendation/profile_canonicalizer.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import 'profile_value_formatters.dart';
import 'profile_widgets.dart';
import '../../utils/app_text.dart';

/// Card displaying eligibility and professional details (education, employment, income, etc.)
class ProfileEligibilityDetailsCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileEligibilityDetailsCard({super.key, required this.provider});

  static String _education(UserProfile p) =>
      p.educationLevel.isNotEmpty ? p.educationLevel : p.qualification;

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    final roles = ProfileCanonicalizer.employmentRoles(
      profile.employmentStatus,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Header
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
                size: AppSize.icon,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.eligibilityProfessionalDetails,
                  style: context.text.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              ProfileInfoCol(
                label: context.l10n.labelEducationLevel,
                value: _education(profile).isNotEmpty
                    ? ProfileValueFormatters.getLocalizedProfileValue(
                        _education(profile),
                        context,
                      )
                    : '-',
                flex: 1,
              ),
            ],
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.labelEmployment,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final role in roles)
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        ProfileValueFormatters.getLocalizedProfileValue(
                          role,
                          context,
                        ),
                        style: context.text.label.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.border, height: 1),
          ),

          // Details Row 2: Community & Income
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoCol(
                label: context.l10n.labelCommunityCategory,
                value: profile.community.isNotEmpty
                    ? ProfileValueFormatters.getLocalizedProfileValue(
                        profile.community,
                        context,
                      )
                    : '-',
                flex: 1,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelAnnualIncome,
                value: ProfileValueFormatters.getLocalizedIncomeRange(
                  profile.annualIncome,
                  context,
                ),
                flex: 1,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.border, height: 1),
          ),

          // Details Row 3: Special Statuses (Disability & Veteran)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoCol(
                label: context.l10n.labelDifferentlyAbled,
                value:
                    profile.disability.isNotEmpty &&
                        profile.disability != 'None'
                    ? ProfileValueFormatters.getLocalizedProfileValue(
                        profile.disability,
                        context,
                      )
                    : context.l10n.valNo,
                flex: 1,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelExServiceman,
                value: profile.veteran
                    ? context.l10n.valYes
                    : context.l10n.valNo,
                flex: 1,
              ),
            ],
          ),

          // Business Details (Optional)
          if (profile.existingBusiness) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(color: AppColors.border, height: 1),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.businessInformation,
              style: context.text.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileInfoCol(
                  label: context.l10n.labelBusinessStage,
                  value: profile.businessStage.isNotEmpty
                      ? ProfileValueFormatters.getLocalizedProfileValue(
                          profile.businessStage,
                          context,
                        )
                      : '-',
                  flex: 1,
                ),
                const ProfileDividerCol(),
                ProfileInfoCol(
                  label: context.l10n.labelIndustry,
                  value: profile.businessIndustry.isNotEmpty
                      ? ProfileValueFormatters.getLocalizedProfileValue(
                          profile.businessIndustry,
                          context,
                        )
                      : '-',
                  flex: 1,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(color: AppColors.border, height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileInfoCol(
                  label: context.l10n.labelFundingRequired,
                  value: profile.fundingRequired > 0
                      ? formatInr(profile.fundingRequired, decimals: 0)
                      : '-',
                  flex: 1,
                ),
                const ProfileDividerCol(),
                ProfileInfoCol(
                  label: context.l10n.labelRegNumbers,
                  value: profile.registrationNumbers.isNotEmpty
                      ? profile.registrationNumbers
                      : '-',
                  flex: 1,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
