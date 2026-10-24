import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'mss_design.dart';

/// Full-bleed illustrated background.
class MssBackground extends StatelessWidget {
  const MssBackground({
    super.key,
    required this.asset,
    required this.fallback,
    this.alignment = Alignment.bottomCenter,
  });
  final String asset;
  final Color fallback;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: fallback,
        image: DecorationImage(
          image: AssetImage(asset),
          fit: BoxFit.cover,
          alignment: alignment,
        ),
      ),
    ),
  );
}

/// Frosted white panel behind headlines.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.s,
    this.opacity = .6,
    this.borderColor,
  });
  final double s;
  final double opacity;
  final Color? borderColor;

  @override
  // No backdrop blur: over the soft illustrated backgrounds a translucent
  // panel looks the same and costs nothing per frame while pages swipe.
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity + .12),
      borderRadius: BorderRadius.circular(32 * s),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: .7),
      ),
    ),
  );
}

/// Character image, optionally mirrored, positioned so it is cropped by the screen edge.
class Character extends StatelessWidget {
  const Character({super.key, required this.asset, this.mirror = false});
  final String asset;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final img = ExcludeSemantics(
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
    );
    return mirror
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1, 1, 1),
            child: img,
          )
        : img;
  }
}

/// Small tilted floating card (MSME, Loans, …).
class FloatChip extends StatelessWidget {
  const FloatChip({
    super.key,
    required this.label,
    required this.s,
    this.bg = Colors.white,
    this.fg = MssColors.ashokaBlue,
    this.degrees = 0,
    this.fontSize = 13,
    this.weight = FontWeight.w700,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    this.radius = 14,
    this.shadow = const Color(0x26000050),
  });
  final String label;
  final double s;
  final Color bg, fg, shadow;
  final double degrees, fontSize, radius;
  final FontWeight weight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: degrees * math.pi / 180,
    child: Container(
      padding: padding * s,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius * s),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 20 * s,
            offset: Offset(0, 8 * s),
          ),
        ],
      ),
      child: Text(label, style: pop(fontSize, weight, fg, s)),
    ),
  );
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.s,
    this.bg = MssColors.ashokaBlue,
    this.fg = Colors.white,
    this.weight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
    this.halo,
    this.arrow = true,
  });
  final String label;
  final VoidCallback onTap;
  final double s;
  final Color bg, fg;
  final FontWeight weight;
  final EdgeInsets padding;
  final Color? halo;

  /// A trailing arrow icon (Poppins has no "→" glyph).
  final bool arrow;

  @override
  Widget build(BuildContext context) => Container(
    decoration: halo == null
        ? null
        : BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: halo!, spreadRadius: 6 * s)],
          ),
    child: Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: padding * s,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: pop(14, weight, fg, s)),
              if (arrow) ...[
                SizedBox(width: 6 * s),
                Icon(Icons.arrow_forward_rounded, color: fg, size: 17 * s),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Next button sitting on a tab that grows out of the screen edge (left or right).
class EdgeTabButton extends StatelessWidget {
  const EdgeTabButton({
    super.key,
    required this.s,
    required this.button,
    required this.tabColor,
    this.fromRight = false,
    this.shadow = false,
  });
  final double s;
  final Widget button;
  final Color tabColor;
  final bool fromRight;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    padding: fromRight
        ? EdgeInsets.fromLTRB(8 * s, 6 * s, 18 * s, 6 * s)
        : EdgeInsets.fromLTRB(18 * s, 6 * s, 8 * s, 6 * s),
    decoration: BoxDecoration(
      color: tabColor,
      borderRadius: fromRight
          ? const BorderRadius.horizontal(left: Radius.circular(999))
          : const BorderRadius.horizontal(right: Radius.circular(999)),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: const Color(0x1F000050),
                blurRadius: 18 * s,
                offset: Offset(0, 6 * s),
              ),
            ]
          : null,
    ),
    child: button,
  );
}

class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.active,
    required this.s,
    this.count = 4,
    this.color = MssColors.ashokaBlue,
    this.inactiveOpacity = .3,
  });
  final int active, count;
  final double s;
  final Color color;
  final double inactiveOpacity;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(count, (i) {
      final on = i == active;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.symmetric(horizontal: 3.5 * s),
        width: (on ? 20 : 7) * s,
        height: 7 * s,
        decoration: BoxDecoration(
          color: on ? color : color.withValues(alpha: inactiveOpacity),
          borderRadius: BorderRadius.circular(4 * s),
        ),
      );
    }),
  );
}

class SkipButton extends StatelessWidget {
  const SkipButton({
    super.key,
    required this.onTap,
    required this.s,
    this.bg = const Color(0xB3FFFFFF),
  });
  final VoidCallback onTap;
  final double s;
  final Color bg;

  @override
  Widget build(BuildContext context) => Material(
    color: bg,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
        child: Text(
          context.l10n.onbSkip,
          style: pop(12, FontWeight.w600, MssColors.ashokaBlue, s),
        ),
      ),
    ),
  );
}

class StepCounter extends StatelessWidget {
  const StepCounter({super.key, required this.step, required this.s});
  final int step;
  final double s;

  @override
  Widget build(BuildContext context) => Text(
    context.l10n.onbStep(step.toString().padLeft(2, '0'), '04'),
    style: pop(13, FontWeight.w600, MssColors.ashokaBlue, s),
  );
}
