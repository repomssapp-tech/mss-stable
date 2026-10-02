import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_elevation.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';

/// Shared card shell (spec_design_system.md §5.4), reviving the old unused
/// `AppCardStyle` as a real widget instead of a static-value holder. Cards
/// drifted across the app (radius 16/18, border E2E8F0/E5E7EB/F1F5F9, shadow
/// alphas .015-.05); this is the single source of truth going forward.
///
/// Not yet adopted at call sites (SchemeCard, Saved card, Home cards, etc.
/// -- that sweep is Phase 3); this phase only adds the widget itself.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.color = AppColors.surface,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
        width: selected ? AppSize.borderWidthSelected : AppSize.borderWidth,
      ),
      borderRadius: AppRadius.lgAll,
      boxShadow: AppShadows.card,
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    // D3 (Phase 2 design review): the decorated Container must be OUTSIDE
    // the Material/InkWell, not wrapping it -- an InkWell's splash paints
    // on its nearest Material ancestor, which sits *under* whatever the
    // InkWell's own child draws. With the old order (Container -> Material
    // -> InkWell -> Container(decoration) -> child), the ripple painted
    // beneath the card's own background and border and was invisible on
    // any card that wasn't fully transparent. margin also moves outside the
    // InkWell here, so the tappable/ripple area is the card's visible
    // bounds, not bounds+margin.
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        margin: margin,
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadius.lgAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
