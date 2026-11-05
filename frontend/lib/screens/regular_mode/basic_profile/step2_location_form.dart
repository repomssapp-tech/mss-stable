import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../services/recommendation/indian_states.dart';
import 'state_picker_field.dart';
import 'district_picker_field.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class Step2LocationForm extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  final bool isLoadingLocation;
  final bool hasSubmitted;
  final VoidCallback? onFetchLocation;
  final VoidCallback onChanged;

  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate900 = AppColors.textPrimary;
  static const Color kSlate800 = AppColors.textPrimary;
  static const Color kSlate500 = AppColors.textMuted;

  /// A place name must have some letters in any supported script and a sane length --
  /// rejects junk like "1" / "11" / "." that non-empty checks let through.
  static final RegExp _placeNameLetters = RegExp(r'\p{L}', unicode: true);
  static bool looksLikePlaceName(String value, {int min = 2}) {
    final t = value.trim();
    return t.length >= min && _placeNameLetters.hasMatch(t);
  }

  /// Whether [value] names one of India's states or union territories, in any
  /// supported language or as a code.
  static bool isKnownState(String value) => IndianStates.code(value) != null;

  /// The server needs exactly six digits.
  static bool isValidPincode(String value) =>
      RegExp(r'^\d{6}$').hasMatch(value.trim());

  const Step2LocationForm({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.districtController,
    required this.stateController,
    required this.pincodeController,
    required this.isLoadingLocation,
    required this.hasSubmitted,
    required this.onFetchLocation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.whereLocated,
          textAlign: TextAlign.center,
          style: context.text.titleSmall.copyWith(color: kSlate900),
        ),
        const SizedBox(height: AppSpacing.md),

        // Live Location Button
        InkWell(
          onTap: isLoadingLocation ? null : onFetchLocation,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: kPrimaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: isLoadingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.useCurrentLocation,
                    style: context.text.bodyLarge.copyWith(color: kSlate900),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kPrimaryBlue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // OR Divider
        Row(
          children: [
            const Expanded(
              child: Divider(color: AppColors.border, thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.or,
                style: context.text.label.copyWith(color: kSlate500),
              ),
            ),
            const Expanded(
              child: Divider(color: AppColors.border, thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Full Address Multi-line Text Area
        _buildLabel(context, '${l10n.fullAddress} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          context,
          controller: addressController,
          hintText: l10n.hintAddressExample,
          icon: Icons.home_outlined,
          errorText: hasSubmitted && addressController.text.trim().isEmpty
              ? l10n.profileErrEnterHouseStreet
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // City / Town Field
        _buildLabel(context, '${l10n.cityTown} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          context,
          controller: cityController,
          hintText: l10n.hintCityExample,
          icon: Icons.location_city_outlined,
          errorText:
              hasSubmitted && !looksLikePlaceName(cityController.text, min: 2)
              ? l10n.profileErrValidCity
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // State Field: picked from the fixed list of states and union
        // territories, never typed (a typo would break state-based scheme
        // matching).
        _buildLabel(context, '${l10n.state} *'),
        const SizedBox(height: AppSpacing.tight),
        StatePickerField(
          controller: stateController,
          errorText: hasSubmitted && !isKnownState(stateController.text)
              ? l10n.profileErrValidState
              : null,
          // A district belongs to one state: a new state clears it.
          onStateChanged: districtController.clear,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // District Field: picked from the chosen state's official (LGD)
        // districts, so it sits below State (issue #145 item 2.1).
        _buildLabel(context, '${l10n.district} *'),
        const SizedBox(height: AppSpacing.tight),
        DistrictPickerField(
          controller: districtController,
          state: stateController.text,
          errorText:
              hasSubmitted &&
                  !looksLikePlaceName(districtController.text, min: 2)
              ? l10n.profileErrValidDistrict
              : null,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Pincode Field
        _buildLabel(context, '${l10n.pincode} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          context,
          controller: pincodeController,
          hintText: '600001',
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          errorText: hasSubmitted && !isValidPincode(pincodeController.text)
              ? l10n.profileErrPincode6Digits
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final hasAsterisk = text.contains('*');
    final baseText = text.replaceAll('*', '').trim();
    return Text.rich(
      TextSpan(
        text: baseText,
        style: context.text.button.copyWith(color: kSlate800),
        children: hasAsterisk
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: context.text.body.copyWith(color: kSlate900),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.text.body.copyWith(color: AppColors.iconMuted),
        prefixIcon: Icon(icon, color: kSlate500, size: 20),
        errorText: errorText,
        errorStyle: context.text.bodySmall.copyWith(color: AppColors.danger),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderStrong,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderStrong,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
