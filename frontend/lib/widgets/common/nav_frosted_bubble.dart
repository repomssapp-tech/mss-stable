import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

/// The active tab's bubble: translucent blue over a light blur of what is
/// under it (frosted glass), a highlight toward the top-left, a light rim
/// and, while moving, a droplet tail on the [tailDir] side.
class NavFrostedBubble extends StatelessWidget {
  const NavFrostedBubble({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.tailDir,
    required this.tail,
  });

  final IconData icon;
  final double iconSize;
  final double tailDir;
  final double tail;

  @override
  Widget build(BuildContext context) {
    final shape = _BubbleShape(tailDir: tailDir, tail: tail);
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _BubbleShadowPainter(shape)),
        ClipPath(
          clipper: _BubbleClipper(shape),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const SizedBox.expand(),
          ),
        ),
        CustomPaint(painter: _BubblePainter(shape)),
        Center(
          child: Icon(icon, color: AppColors.textOnPrimary, size: iconSize),
        ),
      ],
    );
  }
}

/// A circle at rest; while moving, an ellipse with a droplet tail.
class _BubbleShape {
  const _BubbleShape({required this.tailDir, required this.tail});

  final double tailDir;
  final double tail;

  Path pathFor(Size size) {
    final rx = size.width / 2;
    final ry = size.height / 2;
    final cx = rx;
    final cy = ry;
    final body = Path()..addOval(Offset.zero & size);
    // Settled (or a spring's last hair of motion): a plain circle.
    if (tail < 0.5) return body;
    const a = 0.42; // where the tail leaves the body, from the horizontal
    final baseX = cx + tailDir * rx * math.cos(a);
    final tipX = cx + tailDir * (rx + tail);
    final ctrlX = cx + tailDir * (rx + tail * 0.45);
    final tailPath = Path()
      ..moveTo(baseX, cy - ry * math.sin(a))
      ..quadraticBezierTo(ctrlX, cy - ry * 0.10, tipX, cy)
      ..quadraticBezierTo(ctrlX, cy + ry * 0.10, baseX, cy + ry * math.sin(a))
      ..close();
    return Path.combine(PathOperation.union, body, tailPath);
  }

  bool sameAs(_BubbleShape o) => o.tailDir == tailDir && o.tail == tail;
}

class _BubbleClipper extends CustomClipper<Path> {
  const _BubbleClipper(this.shape);

  final _BubbleShape shape;

  @override
  Path getClip(Size size) => shape.pathFor(size);

  @override
  bool shouldReclip(_BubbleClipper old) => !old.shape.sameAs(shape);
}

class _BubbleShadowPainter extends CustomPainter {
  const _BubbleShadowPainter(this.shape);

  final _BubbleShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      shape.pathFor(size).shift(const Offset(0, 5)),
      Paint()
        ..color = AppColors.navBubbleDeep.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }

  @override
  bool shouldRepaint(_BubbleShadowPainter old) => !old.shape.sameAs(shape);
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.shape);

  final _BubbleShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.pathFor(size);
    final bounds = Offset.zero & size;

    // Translucent blue body: lets the blur underneath show through.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navBubbleLight.withValues(alpha: 0.86),
            AppColors.navBubbleDeep.withValues(alpha: 0.90),
          ],
        ).createShader(bounds),
    );

    // Frost highlight toward the top-left.
    canvas.save();
    canvas.clipPath(path);
    final glint = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.04,
      size.width * 0.62,
      size.height * 0.46,
    );
    canvas.drawOval(
      glint,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.textOnPrimary.withValues(alpha: 0.42),
            AppColors.textOnPrimary.withValues(alpha: 0),
          ],
        ).createShader(glint),
    );
    canvas.restore();

    // Light rim, brighter at the top.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.textOnPrimary.withValues(alpha: 0.75),
            AppColors.textOnPrimary.withValues(alpha: 0.08),
          ],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => !old.shape.sameAs(shape);
}
