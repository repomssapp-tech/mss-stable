import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

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
    final bool isPicker = onTap != null;

    final field = TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: context.text.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.text.bodyLarge.copyWith(color: AppColors.textMuted),
        prefixIcon: prefixText == null
            ? Icon(
                leadingIcon,
                color: hasError ? AppColors.danger : AppColors.textSecondary,
                size: AppSize.iconSm,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  Icon(
                    leadingIcon,
                    color: hasError ? AppColors.danger : AppColors.textSecondary,
                    size: AppSize.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    prefixText!,
                    style: context.text.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
          color: hasError ? AppColors.danger : AppColors.textSecondary,
          size: AppSize.iconSm,
        ),
        // The error-state border colour is the one override the shared
        // inputDecorationTheme can't express (it doesn't know this field's
        // validation state); everything else inherits from the theme.
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.danger),
              )
            : null,
        focusedBorder: hasError
            ? OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.danger, width: 2),
              )
            : null,
      ),
    );

    return Semantics(
      container: true,
      label: label,
      textField: !isPicker,
      button: isPicker,
      value: controller.text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          isPicker
              ? InkWell(
                  onTap: onTap,
                  borderRadius: AppRadius.mdAll,
                  child: IgnorePointer(child: field),
                )
              : field,
          if (hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: AppSize.iconSm,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: context.text.bodySmall.copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
