import 'package:flutter/material.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text.dart';
import 'package:flutter/services.dart';

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
  final VoidCallback onOpenConsentModal;
  final VoidCallback onFieldChanged;

  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate900 = AppColors.textPrimary;
  static const Color kSlate800 = AppColors.textPrimary;
  static const Color kSlate500 = AppColors.textMuted;
  static const Color kBorderGrey = AppColors.border;
  static const Color kInfoBlueBg = AppColors.primarySoft;

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
          style: context.text.body.copyWith(color: kSlate500),
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
          maxLines: 2,
          // An address has no spaces or line breaks; with two lines allowed
          // the Enter key must not add one.
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          errorText:
              hasSubmitted &&
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
                style: context.text.button.copyWith(color: kSlate900),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _buildGenderBox(context, l10n.genderMale, Icons.male),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildGenderBox(
                    context,
                    l10n.genderFemale,
                    Icons.female,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildGenderBox(
                    context,
                    l10n.genderOther,
                    Icons.transgender,
                  ),
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
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.profileErrSelectGender,
                      style: context.text.bodySmall.copyWith(
                        color: AppColors.danger,
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
          hintText: l10n.hintAgeExample,
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
          style: context.text.button.copyWith(color: kSlate900),
        ),
        const SizedBox(height: AppSpacing.sm),
        // The data-use consent is given by completing the profile: only a
        // notice and a way to read the document are shown, no checkbox.
        Text(
          l10n.profileConsentCheckboxLabel,
          style: context.text.body.copyWith(color: kSlate800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: onOpenConsentModal,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                l10n.profileConsentReadMore,
                style: context.text.button.copyWith(
                  color: kPrimaryBlue,
                  decoration: context.linkDecoration,
                  decorationColor: kPrimaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderBox(BuildContext context, String gender, IconData icon) {
    final isSelected = selectedGender == gender;
    const activeBg = AppColors.primarySoft;

    return InkWell(
      borderRadius: AppRadius.mdAll,
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
              size: AppSize.iconSm,
            ),
            const SizedBox(width: AppSpacing.hairline),
            Flexible(
              child: Text(
                gender,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.copyWith(
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
        border: Border.all(color: AppColors.primaryBorder),
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
              style: context.text.bodySmall.copyWith(color: kSlate800),
            ),
          ),
        ],
      ),
    );
  }
}
