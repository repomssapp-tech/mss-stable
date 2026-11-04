import 'package:flutter/material.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'role_model.dart';
import '../../../utils/app_text.dart';

class Step3AboutYouForm extends StatelessWidget {
  final List<RoleModel>? roles;
  final String? selectedRoleId;
  final ValueChanged<String?> onRoleSelected;
  final bool hasSubmitted;

  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate900 = AppColors.textPrimary;
  static const Color kSlate500 = AppColors.textMuted;
  static const Color kBorderGrey = AppColors.border;

  const Step3AboutYouForm({
    super.key,
    this.roles,
    required this.selectedRoleId,
    required this.onRoleSelected,
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

        // Grid of role cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: resolvedRoles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: MediaQuery.sizeOf(context).width < 360
                ? 1.05
                : 1.22,
          ),
          itemBuilder: (context, index) {
            final role = resolvedRoles[index];
            final isSelected = selectedRoleId == role.id;
            return _buildRoleCard(context, role, isSelected);
          },
        ),
        if (hasSubmitted && selectedRoleId == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(10),
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
    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: () {
        onRoleSelected(isSelected ? null : role.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Micro Radio Button indicator
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryBlue : Colors.white,
                  border: Border.all(
                    color: isSelected ? kPrimaryBlue : kBorderGrey,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 10)
                    : null,
              ),
            ),

            // Perfectly centered content with equal spacing and padding
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(role.icon, color: role.color, size: 19),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  SizedBox(
                    height: 32,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        role.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.label.copyWith(color: kSlate900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
