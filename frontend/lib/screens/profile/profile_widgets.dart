import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Info Column Helper for the Profile Grid: a quiet label over its value.
class ProfileInfoCol extends StatelessWidget {
  final String label;
  final String value;
  final int flex;

  /// Kept for callers; Tamil now uses the same sizes (the roles add its
  /// extra line height on their own).
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
            style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.hairline),
          Text(
            value,
            style: context.text.label.copyWith(color: AppColors.textPrimary),
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
    return const SizedBox(width: AppSpacing.md);
  }
}

/// Grouped Card container for Settings/Navigation Tiles.
class ProfileGroupCard extends StatelessWidget {
  final List<Widget> tiles;
  final EdgeInsetsGeometry? margin;

  const ProfileGroupCard({super.key, required this.tiles, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.tight,
          ),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: tiles),
      ),
    );
  }
}

/// One row in a Profile group: a quiet icon, title, optional subtitle and
/// value, and a chevron.
class ProfileTile extends StatelessWidget {
  final IconData icon;

  /// The icon's colour; blue unless the row means something else (red for
  /// sign out).
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
    this.iconColor = AppColors.primary,
    this.iconBgColor = AppColors.primarySoft,
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
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSize.avatarSm,
                  height: AppSize.avatarSm,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: AppSize.icon),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.cardTitle.copyWith(
                          color: textColor ?? AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailingText != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailingText!,
                    style: context.text.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.iconMuted,
                  size: AppSize.icon,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            color: AppColors.border,
            height: AppSize.borderWidth,
            thickness: AppSize.borderWidth,
            indent: AppSpacing.lg + AppSize.avatarSm + AppSpacing.md,
          ),
      ],
    );
  }
}
