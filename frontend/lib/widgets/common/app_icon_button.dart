import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';

/// Shared icon-only action button (bell, bookmark, mic, clear, share, back
/// -- spec_design_system.md §6.1). Hit area is always >= 48x48dp
/// regardless of the visual glyph/background size, with required,
/// localised semantics.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.size = AppSize.iconLg,
    this.color,
    this.selected,
    this.selectedIcon,
    this.tooltip,
    this.badgeCount,
    this.showDot = false,
    this.badgeSemantics,
    this.backgroundColor,
    this.backgroundSize = 40,
  });

  final IconData icon;
  final String
  semanticLabel; // REQUIRED, localised (l10n). Also used as tooltip.
  final VoidCallback? onPressed; // null => disabled
  final double size; // glyph size: 20 | 24
  final Color? color; // default AppColors.textPrimary (iconMuted when disabled)
  final bool? selected; // null = not a toggle
  final IconData? selectedIcon;
  final String? tooltip; // defaults to semanticLabel; pass '' to suppress
  final int? badgeCount; // int? > 0 shows a numeric badge ("9+" above 9)
  final bool showDot; // unread dot when no count is available
  final String? badgeSemantics; // e.g. l10n.notificationsUnread(n)
  final Color? backgroundColor; // optional circular bg
  final double backgroundSize; // visual circle; hit area stays 48

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final effectiveIcon = (selected == true && selectedIcon != null)
        ? selectedIcon!
        : icon;
    final effectiveColor = !enabled
        ? AppColors.iconMuted
        : (color ?? AppColors.textPrimary);
    final effectiveTooltip = tooltip ?? semanticLabel;
    final label = badgeSemantics != null
        ? '$semanticLabel $badgeSemantics'
        : semanticLabel;

    Widget glyph = ExcludeSemantics(
      child: Icon(effectiveIcon, size: size, color: effectiveColor),
    );

    if (backgroundColor != null) {
      glyph = Container(
        width: backgroundSize,
        height: backgroundSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: glyph,
      );
    }

    if (badgeCount != null && badgeCount! > 0) {
      glyph = Badge(
        label: Text(badgeCount! > 9 ? '9+' : '$badgeCount'),
        backgroundColor: AppColors.danger,
        textColor: AppColors.textOnPrimary,
        child: glyph,
      );
    } else if (showDot) {
      glyph = Badge(
        backgroundColor: AppColors.danger,
        smallSize: 8,
        child: glyph,
      );
    }

    Widget button = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSize.tapTarget,
        minHeight: AppSize.tapTarget,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          radius: 24,
          onTap: onPressed,
          child: Center(child: glyph),
        ),
      ),
    );

    if (effectiveTooltip.isNotEmpty) {
      button = Tooltip(
        message: effectiveTooltip,
        excludeFromSemantics: true,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      toggled: selected,
      child: button,
    );
  }
}
