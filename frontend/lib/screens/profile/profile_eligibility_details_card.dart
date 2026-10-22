import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import 'profile_value_formatters.dart';
import 'profile_widgets.dart';

/// Card displaying eligibility and professional details (education, employment, income, etc.)
class ProfileEligibilityDetailsCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileEligibilityDetailsCard({super.key, required this.provider});

  static String _education(UserProfile p) =>
      p.educationLevel.isNotEmpty ? p.educationLevel : p.qualification;

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.eligibilityProfessionalDetails,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Details Row 1: Qualification & Employment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoCol(
                label: context.l10n.labelEducationLevel,
                // educationLevel is the field the server stores and returns;
                // qualification is only a local mirror, so it can be stale
                // after a sync (issue 148: education never updated).
                value: _education(profile).isNotEmpty
                    ? ProfileValueFormatters.getLocalizedProfileValue(
                        _education(profile),
                        context,
                      )
                    : '-',
                flex: 1,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelEmployment,
                value: profile.employmentStatus.isNotEmpty
                    ? ProfileValueFormatters.getLocalizedProfileValue(
                        profile.employmentStatus,
                        context,
                      )
                    : '-',
                flex: 1,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
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
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
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
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.businessInformation,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
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
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileInfoCol(
                  label: context.l10n.labelFundingRequired,
                  value: profile.fundingRequired > 0
                      ? '₹${profile.fundingRequired.toStringAsFixed(0)}'
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
