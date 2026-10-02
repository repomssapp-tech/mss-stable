import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import 'app_icon_button.dart';

/// StandardPageHeader
/// ──────────────────
/// Unified header widget ensuring consistent top padding, SafeArea compliance,
/// vertically centered back button, aligned titles & subtitles, and action icons.
///
/// `PreferredSizeWidget.preferredSize` can't see a `BuildContext`, so this is
/// a thin wrapper around `AppBar` instead of building its own bar: the real,
/// text-scale-aware height comes from [_height], and [preferredSize] only
/// reports an upper bound for the `Scaffold` (spec_phase3.md group 4, G6).
class StandardPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color backgroundColor;
  final double elevation;

  const StandardPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor = AppColors.surface,
    this.elevation = 0,
  });

  bool get _hasSubtitle => subtitle != null && subtitle!.isNotEmpty;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  double _height(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final height = 56.0 * scale + (_hasSubtitle ? 18.0 * scale : 0.0);
    return height.clamp(56.0, 96.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppBar(
      toolbarHeight: _height(context),
      titleSpacing: 0,
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton
          ? AppIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: l10n.back,
              onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.titleMedium.copyWith(color: AppColors.textPrimary),
            maxLines: _hasSubtitle ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_hasSubtitle)
            Text(
              subtitle!,
              style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: actions,
      bottom: elevation > 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            )
          : null,
    );
  }
}
