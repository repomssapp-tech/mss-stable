import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/responsive.dart';

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
              label: FitOneLine(
                child: Text(
                  backLabel,
                  style: GoogleFonts.inter(
                    fontSize: isTamil ? 11.0 : 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        Flexible(
          child: TextButton(
            onPressed: onSubmit,
            style: TextButton.styleFrom(foregroundColor: themeColor),
            child: FitOneLine(
              child: Text(
                skipLabel,
                style: GoogleFonts.inter(
                  fontSize: isTamil ? 11.0 : 12.0,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
