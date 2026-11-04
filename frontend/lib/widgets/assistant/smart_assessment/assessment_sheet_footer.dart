import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text.dart';

class AssessmentSheetFooter extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final Color themeColor;
  final bool isTamil;
  final String backLabel;
  final String skipLabel;

  const AssessmentSheetFooter({
    super.key,
    required this.showBackButton,
    required this.onBack,
    required this.onSubmit,
    required this.themeColor,
    required this.isTamil,
    required this.backLabel,
    required this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showBackButton)
          Flexible(
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(backLabel, style: context.text.label),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            ),
          )
        else
          const SizedBox.shrink(),
        Flexible(
          child: TextButton(
            onPressed: onSubmit,
            style: TextButton.styleFrom(foregroundColor: themeColor),
            child: Text(
              skipLabel,
              style: context.text.label.copyWith(
                decoration: context.linkDecoration,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
