import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import 'app_icon_button.dart';

class StandardPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? titleIcon;
  final String? subtitle;

  /// Replaces the back button (e.g. a close button in a selection mode).
  final Widget? leading;
  final List<Widget>? actions;
  final Color backgroundColor;
  final bool showDivider;
  final TextScaler textScaler;

  const StandardPageHeader(
    this.textScaler, {
    super.key,
    required this.title,
    this.titleIcon,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor = AppColors.surface,
    this.showDivider = false,
  });

  bool get _hasSubtitle => subtitle != null && subtitle!.isNotEmpty;

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (showDivider ? 1 : 0));

  double get _toolbarHeight {
    final height =
        textScaler.scale(kToolbarHeight) +
        (_hasSubtitle ? textScaler.scale(18) : 0);
    return height.clamp(kToolbarHeight, 96.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleText = Text(
      title,
      style:
          (titleIcon == null
                  ? context.text.titleMedium
                  : context.text.titleSmall)
              .copyWith(color: AppColors.textPrimary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return AppBar(
      toolbarHeight: _toolbarHeight,
      titleSpacing: 0,
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading:
          leading ??
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: l10n.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleIcon case final icon?)
            Row(
              children: [
                icon,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: titleText),
                const SizedBox(width: AppSpacing.lg),
              ],
            )
          else
            titleText,
          if (_hasSubtitle)
            Text(
              subtitle!,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: actions,
      bottom: showDivider
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            )
          : null,
    );
  }
}
