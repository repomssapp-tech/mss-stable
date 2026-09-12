import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'role_model.dart';

class Step3AboutYouForm extends StatelessWidget {
  final List<RoleModel>? roles;
  final String? selectedRoleId;
  final ValueChanged<String?> onRoleSelected;
  final bool hasSubmitted;

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);

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
        color: const Color(0xFF3B82F6),
      ),
      RoleModel(
        id: 'entrepreneur',
        title: l10n.aspiringEntrepreneur,
        subtitle: l10n.aspiringEntrepreneurSubtitle,
        imagePath: 'assets/images/roles/entrepreneur.webp',
        icon: Icons.lightbulb_outline,
        color: const Color(0xFFF59E0B),
      ),
      RoleModel(
        id: 'existing_business',
        title: l10n.existingBusiness,
        subtitle: l10n.existingBusinessSubtitle,
        imagePath: 'assets/images/roles/business.webp',
        icon: Icons.business_center_outlined,
        color: const Color(0xFF6366F1),
      ),
      RoleModel(
        id: 'msme',
        title: l10n.msmeOwner,
        subtitle: l10n.msmeOwnerSubtitle,
        imagePath: 'assets/images/roles/msme.webp',
        icon: Icons.storefront_outlined,
        color: const Color(0xFF10B981),
      ),
      RoleModel(
        id: 'farmer',
        title: l10n.empFarmer,
        subtitle: l10n.farmerSubtitle,
        imagePath: 'assets/images/roles/farmer.webp',
        icon: Icons.agriculture_outlined,
        color: const Color(0xFF14B8A6),
      ),
      RoleModel(
        id: 'artisan',
        title: l10n.artisanShg,
        subtitle: l10n.artisanShgSubtitle,
        imagePath: 'assets/images/roles/artisan.webp',
        icon: Icons.palette_outlined,
        color: const Color(0xFFEC4899),
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
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aboutYouSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: kSlate500,
          ),
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
            childAspectRatio:
                MediaQuery.sizeOf(context).width < 360 ? 1.05 : 1.22,
          ),
          itemBuilder: (context, index) {
            final role = resolvedRoles[index];
            final isSelected = selectedRoleId == role.id;
            return _buildRoleCard(role, isSelected);
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
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.profileErrSelectOptionToContinue,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
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

  Widget _buildRoleCard(RoleModel role, bool isSelected) {
    return GestureDetector(
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
          color: isSelected ? const Color(0xFFF5F9FF) : Colors.white,
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kSlate900,
                          height: 1.15,
                        ),
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
