import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/app_spacing.dart';
import '../../../utils/constants.dart';

/// Labelled text-field with leading/trailing icons and an inline error row,
/// used across all 4 steps of the profile-completion wizard.
///
/// Extracted verbatim from `basic_profile_screen.dart` (frontend refactor C4,
/// safe slice) — a `StatelessWidget` with zero coupling to
/// `_BasicProfileScreenState`, used only inside that file.
class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? prefixText;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final void Function(String)? onChanged;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.leadingIcon,
    required this.trailingIcon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.prefixText,
    this.hintText,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: AppConstants.primaryText,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppConstants.surfaceColor,
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppConstants.secondaryText,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                prefixIcon: prefixText == null
                    ? Icon(
                        leadingIcon,
                        color: hasError
                            ? AppConstants.errorColor
                            : AppConstants.secondaryText,
                        size: 20,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: AppSpacing.lg),
                          Icon(
                            leadingIcon,
                            color: hasError
                                ? AppConstants.errorColor
                                : AppConstants.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            prefixText!,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryText,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.tight),
                        ],
                      ),
                prefixIconConstraints: prefixText == null
                    ? null
                    : const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: Icon(
                  trailingIcon,
                  color: hasError
                      ? AppConstants.errorColor
                      : AppConstants.secondaryText,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.cardBorderColor,
                    width: hasError ? 1.4 : 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.cardBorderColor,
                    width: hasError ? 1.4 : 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.primaryColor,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: AppConstants.errorColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
