import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'custom_input_field.dart';

class Step1BasicDetailsForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController ageController;
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<DateTime?> onDobDerived;
  final bool hasSubmitted;
  final bool hasConsented;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onOpenConsentModal;
  final VoidCallback onFieldChanged;

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kInfoBlueBg = Color(0xFFF0F5FA);

  const Step1BasicDetailsForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.ageController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onDobDerived,
    required this.hasSubmitted,
    required this.hasConsented,
    required this.onConsentChanged,
    required this.onOpenConsentModal,
    required this.onFieldChanged,
  });

  String? _phoneErrorText(BuildContext context) {
    if (!hasSubmitted) return null;
    final phone = phoneController.text.trim();
    if (phone.isEmpty) return context.l10n.profileErrEnterPhone;
    if (phone.length != 10) return context.l10n.profileErrPhone10Digits;
    return null;
  }

  String? _ageErrorText(BuildContext context) {
    if (!hasSubmitted) return null;
    final ageStr = ageController.text.trim();
    if (ageStr.isEmpty) return context.l10n.profileErrEnterAge;
    final age = int.tryParse(ageStr);
    if (age == null || age < 1 || age > 120) {
      return context.l10n.profileErrValidAge;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.basicDetailsSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: kSlate500,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Full Name
        CustomInputField(
          label: '${l10n.labelFullName} *',
          controller: nameController,
          leadingIcon: Icons.person_outline,
          trailingIcon: Icons.edit_outlined,
          errorText: hasSubmitted && nameController.text.trim().isEmpty
              ? l10n.profileErrEnterFullName
              : null,
          onChanged: (_) {
            if (hasSubmitted) onFieldChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email Address
        CustomInputField(
          label: '${l10n.emailAddress} *',
          controller: emailController,
          leadingIcon: Icons.mail_outline,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: hasSubmitted &&
                  (emailController.text.trim().isEmpty ||
                      !emailController.text.contains('@'))
              ? l10n.profileErrValidEmail
              : null,
          onChanged: (_) {
            if (hasSubmitted) onFieldChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Phone Number (+91 prefix)
        CustomInputField(
          label: '${l10n.phoneNumber} *',
          controller: phoneController,
          leadingIcon: Icons.phone_outlined,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.phone,
          hintText: l10n.profileHint10DigitMobile,
          prefixText: '+91 ',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          errorText: _phoneErrorText(context),
          onChanged: (_) {
            if (hasSubmitted) onFieldChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Gender Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: l10n.labelGender,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kSlate900,
                ),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: _buildGenderBox(l10n.genderMale, Icons.male)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildGenderBox(l10n.genderFemale, Icons.female)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildGenderBox(l10n.genderOther, Icons.transgender),
                ),
              ],
            ),
            if (hasSubmitted && selectedGender.isEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.profileErrSelectGender,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date of Birth / Age
        CustomInputField(
          label: '${l10n.labelAge} *',
          controller: ageController,
          leadingIcon: Icons.cake_outlined,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.number,
          hintText: 'e.g. 25',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          errorText: _ageErrorText(context),
          onChanged: (val) {
            final age = int.tryParse(val.trim());
            if (age != null && age > 0 && age <= 120) {
              final now = DateTime.now();
              onDobDerived(DateTime(now.year - age, now.month, now.day));
            } else {
              onDobDerived(null);
            }
            if (hasSubmitted) onFieldChanged();
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Info Box
        _buildInfoBox(context),
        const SizedBox(height: AppSpacing.xxl),

        // Data-processing consent (DPDPA) — Step 1 is gated on this
        _buildConsentSection(context),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildConsentSection(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileConsentSectionTitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: hasConsented,
                activeColor: kPrimaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: (hasSubmitted && !hasConsented)
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF94A3B8),
                  width: 1.5,
                ),
                onChanged: (val) => onConsentChanged(val ?? false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () => onConsentChanged(!hasConsented),
                child: Text(
                  l10n.profileConsentCheckboxLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: kSlate800,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxxl),
          child: InkWell(
            onTap: onOpenConsentModal,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                l10n.profileConsentReadMore,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: kPrimaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        if (hasSubmitted && !hasConsented) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxxl),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.profileConsentPleaseConsent,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderBox(String gender, IconData icon) {
    final isSelected = selectedGender == gender;
    const activeBg = Color(0xFFF0F5FF);

    return GestureDetector(
      onTap: () {
        onGenderChanged(isSelected ? '' : gender);
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryBlue : kSlate500,
              size: 13,
            ),
            const SizedBox(width: AppSpacing.hairline),
            Flexible(
              child: Text(
                gender,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kPrimaryBlue : kSlate800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kInfoBlueBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E1FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: kPrimaryBlue,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.profileInfoNote,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: kSlate800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
