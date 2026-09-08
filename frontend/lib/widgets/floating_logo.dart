import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../utils/responsive.dart';
import '../utils/app_spacing.dart';

class FloatingLogo extends StatelessWidget {
  const FloatingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Logo/Logo.webp',
          height: 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 1.5,
              color: const Color(0xFFF97316),
            ), // Orange
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: FitOneLine(
                child: Text(
                  context.l10n.discoverEveryScheme,
                  style: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 16,
              height: 1.5,
              color: const Color(0xFF15803D),
            ), // Green
          ],
        ),
      ],
    );
  }
}
