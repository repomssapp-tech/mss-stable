import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';

class Step2LocationForm extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController stateController;
  final bool isLoadingLocation;
  final bool hasSubmitted;
  final VoidCallback? onFetchLocation;
  final VoidCallback onChanged;

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);

  /// A place name must have some letters (Latin or Tamil) and a sane length --
  /// rejects junk like "1" / "11" / "." that non-empty checks let through.
  static final RegExp _placeNameLetters = RegExp(r'[A-Za-z஀-௿]');
  static bool looksLikePlaceName(String value, {int min = 2}) {
    final t = value.trim();
    return t.length >= min && _placeNameLetters.hasMatch(t);
  }

  const Step2LocationForm({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.districtController,
    required this.stateController,
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
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
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
              border: Border.all(color: const Color(0xFFDCE7F5), width: 1.2),
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
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kSlate900,
                    ),
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
              child: Divider(
                color: Color(0xFFE2E8F0),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.or,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kSlate500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(
              child: Divider(
                color: Color(0xFFE2E8F0),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Full Address Multi-line Text Area
        _buildLabel('${l10n.fullAddress} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: addressController,
          hintText: 'e.g. Door/Flat No, Street Name, Locality',
          icon: Icons.home_outlined,
          errorText: hasSubmitted && addressController.text.trim().isEmpty
              ? l10n.profileErrEnterHouseStreet
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // City / Town Field
        _buildLabel('${l10n.cityTown} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: cityController,
          hintText: 'e.g. Chennai',
          icon: Icons.location_city_outlined,
          errorText: hasSubmitted && !looksLikePlaceName(cityController.text, min: 2)
              ? l10n.profileErrValidCity
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // District Field
        _buildLabel('${l10n.district} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: districtController,
          hintText: 'e.g. Chennai',
          icon: Icons.domain_outlined,
          errorText: hasSubmitted && !looksLikePlaceName(districtController.text, min: 2)
              ? l10n.profileErrValidCity
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // State Field
        _buildLabel('${l10n.state} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: stateController,
          hintText: l10n.profileHintStateExample,
          icon: Icons.map_outlined,
          errorText: hasSubmitted && !looksLikePlaceName(stateController.text, min: 3)
              ? l10n.profileErrValidState
              : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildLabel(String text) {
    final hasAsterisk = text.contains('*');
    final baseText = text.replaceAll('*', '').trim();
    return Text.rich(
      TextSpan(
        text: baseText,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: kSlate800,
        ),
        children: hasAsterisk
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildTextField({
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
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: kSlate900,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(icon, color: kSlate500, size: 20),
        errorText: errorText,
        errorStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFDC2626),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
