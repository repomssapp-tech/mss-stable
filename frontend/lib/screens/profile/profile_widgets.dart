import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';

/// Info Column Helper for the Profile Grid.
class ProfileInfoCol extends StatelessWidget {
  final String label;
  final String value;
  final int flex;
  final bool isTamil;

  const ProfileInfoCol({
    super.key,
    required this.label,
    required this.value,
    required this.flex,
    this.isTamil = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTamil ? 10.0 : 10.5,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              height: isTamil ? 1.35 : 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTamil ? 11.0 : 11.5,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              height: isTamil ? 1.35 : 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Vertical Divider Helper for the Profile Grid.
class ProfileDividerCol extends StatelessWidget {
  const ProfileDividerCol({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}

/// Grouped Card container for Settings/Navigation Tiles.
class ProfileGroupCard extends StatelessWidget {
  final List<Widget> tiles;
  final EdgeInsetsGeometry? margin;

  const ProfileGroupCard({
    super.key,
    required this.tiles,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.tight,
          ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Column(children: tiles),
      ),
    );
  }
}

/// Custom Profile ListTile builder.
class ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final String? trailingText;
  final bool showDivider;
  final Color? textColor;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailingText,
    this.showDivider = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.hairline,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFF0F172A),
            ),
          ),
          subtitle: subtitle != null && subtitle!.isNotEmpty
              ? Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FitOneLine(
                      child: Text(
                        trailingText!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            color: Color(0xFFF1F5F9),
            height: 1,
            indent: 68,
            endIndent: AppSpacing.lg,
          ),
      ],
    );
  }
}
