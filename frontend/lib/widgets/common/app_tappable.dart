import 'package:flutter/material.dart';

import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';

/// Shared tappable primitive for chips, tabs, rows and pills -- anything
/// with its own text/shape decoration (spec_design_system.md §6.2).
///
/// Callers should pass their pill/chip background through [decoration]
/// rather than wrapping [child] in their own `Container`: an `InkWell`'s
/// splash paints on its nearest `Material` ancestor, which sits *under*
/// whatever the `InkWell`'s own child draws, so a `Container(decoration:)`
/// wrapping the child would hide the ripple on any non-transparent
/// background (D3, Phase 2 design review). [Ink] paints its decoration as
/// part of the `Material`'s own painting pass instead, so the ripple
/// composites visibly on top of it.
class AppTappable extends StatelessWidget {
  const AppTappable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.selected,
    this.isButton = true,
    this.decoration,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.md)),
    this.minSize = const Size(AppSize.tapTarget, AppSize.tapTarget),
    this.alignment = Alignment.center,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;
  final bool? selected;
  final bool isButton;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Size minSize;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isButton,
      selected: selected,
      label: semanticLabel,
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize.width,
          minHeight: minSize.height,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Ink(
              decoration: decoration,
              padding: padding,
              child: Align(alignment: alignment, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
