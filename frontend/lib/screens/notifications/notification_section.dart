import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';

class NotificationSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final Color headerIconBg;
  final Color headerIconColor;
  final List<Widget> cards;
  final VoidCallback onViewAll;

  const NotificationSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.headerIconBg,
    required this.headerIconColor,
    required this.cards,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: headerIconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(headerIcon, color: headerIconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FitOneLine(
                        child: Text(
                          context.l10n.viewAll,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.hairline),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...cards,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
