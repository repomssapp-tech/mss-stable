import 'package:flutter/material.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'role_model.dart';
import 'profile_option_grid.dart';
import '../../../utils/app_size.dart';
import '../../../widgets/common/app_tappable.dart';
import '../../../utils/app_text.dart';

class Step3AboutYouForm extends StatelessWidget {
  final List<RoleModel>? roles;
  final Set<String> selectedRoleIds;
  final ValueChanged<String> onRoleToggled;
  final bool hasSubmitted;

  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate900 = AppColors.textPrimary;
  static const Color kSlate500 = AppColors.textMuted;
  static const Color kBorderGrey = AppColors.border;

  const Step3AboutYouForm({
    super.key,
    this.roles,
    required this.selectedRoleIds,
    required this.onRoleToggled,
    required this.hasSubmitted,
  });

  static String canonicalRoleTitle(String roleId) => switch (roleId) {
    'student' => 'Student',
    'entrepreneur' => 'Entrepreneur',
    'existing_business' => 'Business',
    'msme' => 'MSME Owner',
    'farmer' => 'Farmer',
    'artisan' => 'Artisan / SHG Member',
    _ => roleId,
  };

  static String? roleIdFromEmploymentStatus(String status) =>
      switch (status.trim().toLowerCase()) {
        'student' => 'student',
        'aspiring entrepreneur' || 'entrepreneur' => 'entrepreneur',
        'existing business' || 'business' => 'existing_business',
        'msme owner' || 'msme' => 'msme',
        'farmer' => 'farmer',
        'artisan / shg member' || 'artisan' || 'artisan_shg' => 'artisan',
        _ => null,
      };

  static List<RoleModel> buildDefaultRoles(BuildContext context) {
    final l10n = context.l10n;
    return [
      RoleModel(
        id: 'student',
        title: l10n.empStudent,
        subtitle: l10n.studentSubtitle,
        imagePath: 'assets/images/roles/student.webp',
        icon: Icons.school_outlined,
        color: AppColors.primary,
      ),
      RoleModel(
        id: 'entrepreneur',
        title: l10n.aspiringEntrepreneur,
        subtitle: l10n.aspiringEntrepreneurSubtitle,
        imagePath: 'assets/images/roles/entrepreneur.webp',
        icon: Icons.lightbulb_outline,
        color: AppColors.primary,
      ),
      RoleModel(
        id: 'existing_business',
        title: l10n.existingBusiness,
        subtitle: l10n.existingBusinessSubtitle,
        imagePath: 'assets/images/roles/business.webp',
        icon: Icons.business_center_outlined,
        color: AppColors.primary,
      ),
      RoleModel(
        id: 'msme',
        title: l10n.msmeOwner,
        subtitle: l10n.msmeOwnerSubtitle,
        imagePath: 'assets/images/roles/msme.webp',
        icon: Icons.storefront_outlined,
        color: AppColors.primary,
      ),
      RoleModel(
        id: 'farmer',
        title: l10n.empFarmer,
        subtitle: l10n.farmerSubtitle,
        imagePath: 'assets/images/roles/farmer.webp',
        icon: Icons.agriculture_outlined,
        color: AppColors.primary,
      ),
      RoleModel(
        id: 'artisan',
        title: l10n.artisanShg,
        subtitle: l10n.artisanShgSubtitle,
        imagePath: 'assets/images/roles/artisan.webp',
        icon: Icons.palette_outlined,
        color: AppColors.primary,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedRoles = roles ?? buildDefaultRoles(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.tellUsAboutYou,
          textAlign: TextAlign.center,
          style: context.text.titleSmall.copyWith(color: kSlate900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aboutYouSubtitle,
          textAlign: TextAlign.center,
          style: context.text.body.copyWith(color: kSlate500),
        ),
        const SizedBox(height: AppSpacing.sm),

        ProfileOptionGrid(
          options: [
            for (final role in resolvedRoles)
              _buildRoleCard(context, role, selectedRoleIds.contains(role.id)),
          ],
        ),
        if (hasSubmitted && selectedRoleIds.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.profileErrSelectOptionToContinue,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, RoleModel role, bool isSelected) {
    return AppTappable(
      selected: isSelected,
      onTap: () => onRoleToggled(role.id),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isSelected ? kPrimaryBlue : kBorderGrey,
          width: isSelected ? AppSize.borderWidthSelected : AppSize.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(role.icon, color: role.color),
              Icon(
                isSelected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: AppSize.icon,
                color: isSelected ? kPrimaryBlue : AppColors.iconMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            role.title,
            style: context.text.label.copyWith(color: kSlate900),
          ),
        ],
      ),
    );
  }
}
