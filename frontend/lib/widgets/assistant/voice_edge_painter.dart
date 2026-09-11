import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The four visual states the ambient voice-session glow (`VoiceEdgePainter`)
/// and level-bar widgets ([VoiceLevelBars]) render.
enum VoiceEdgeActivity { idle, listening, processing, speaking }

/// Small animated equalizer-style level meter used next to the mic button.
///
/// Extracted from `voice_assistant_overlay.dart` (frontend refactor C3, safe
/// slice — this widget and [VoiceLevelPainter] have zero coupling to
/// `_VoiceAssistantOverlayState`, only `animation` + `level` passed in).
class VoiceLevelBars extends StatelessWidget {
  const VoiceLevelBars({
    super.key,
    required this.animation,
    required this.level,
    required this.active,
    this.color,
  });

  final Animation<double> animation;
  final ValueListenable<double> level;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: active ? 1 : 0.32,
    duration: const Duration(milliseconds: 180),
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, level]),
        builder: (context, child) => CustomPaint(
          size: const Size(54, 20),
          painter: VoiceLevelPainter(
            progress: animation.value,
            level: level.value,
            active: active,
            color: color,
          ),
        ),
      ),
    ),
  );
}

class VoiceLevelPainter extends CustomPainter {
  const VoiceLevelPainter({
    required this.progress,
    required this.level,
    required this.active,
    this.color,
  });

  static const int barCount = 9;
  final double progress;
  final double level;
  final bool active;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.2;
    final spacing = (size.width - strokeWidth) / (barCount - 1);
    final center = (barCount - 1) / 2;
    final energy = ((level - 0.12) / 0.88).clamp(0.0, 1.0);
    final phase = progress * math.pi * 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF2563EB), Color(0xFF67E8F9)],
      ).createShader(Offset.zero & size);
    }
    for (var index = 0; index < barCount; index++) {
      final distance = ((index - center).abs() / center).clamp(0.0, 1.0);
      final envelope = 1 - distance * 0.48;
      final motion = (math.sin(phase * 2 + index * 0.82) + 1) / 2;
      final normalizedHeight = active
          ? (0.2 + envelope * (0.2 + motion * 0.5) * (0.55 + energy * 0.65))
                .clamp(0.2, 1.0)
          : 0.2 + envelope * 0.08;
      final barHeight = size.height * normalizedHeight;
      final x = strokeWidth / 2 + spacing * index;
      final top = (size.height - barHeight) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, size.height - top), paint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceLevelPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.level != level ||
      oldDelegate.active != active ||
      oldDelegate.color != color;
}

/// The full-bleed ambient "ammbient edge glow" behind the voice overlay
/// (a Gemini-style wide U-shaped wash, not a bordered rectangle).
class VoiceEdgePainter extends CustomPainter {
  const VoiceEdgePainter({
    required this.entranceProgress,
    required this.ambientProgress,
    required this.activityIntensity,
    required this.activity,
    required this.radius,
    required this.reduceMotion,
    this.companion = false,
  });

  final double entranceProgress;
  final double ambientProgress;
  final double activityIntensity;
  final VoiceEdgeActivity activity;
  final double radius;
  final bool reduceMotion;
  final bool companion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final timeline = entranceProgress.clamp(0.0, 1.0);
    final envelope = reduceMotion
        ? switch (activity) {
            VoiceEdgeActivity.listening => 0.50,
            VoiceEdgeActivity.processing => 0.34,
            VoiceEdgeActivity.speaking => 0.42,
            VoiceEdgeActivity.idle => 0.28,
          }
        : _bloomEnvelope(timeline);
    if (envelope <= 0.001) return;

    final spread = reduceMotion
        ? 1.0
        : Curves.easeOutCubic.transform((timeline / 0.34).clamp(0.0, 1.0));
    final phase = reduceMotion ? 0.0 : ambientProgress * math.pi * 2;
    final level = activityIntensity.clamp(0.0, 1.0);
    final strength = switch (activity) {
      VoiceEdgeActivity.idle => 0.72,
      VoiceEdgeActivity.listening => 0.82 + level * 0.16,
      VoiceEdgeActivity.processing => 0.64,
      VoiceEdgeActivity.speaking => 0.74,
    };
    final opacity = envelope * strength;
    final horizontalDrift = reduceMotion ? 0.0 : math.sin(phase) * 8;
    final verticalDrift = reduceMotion ? 0.0 : math.sin(phase * 1.4) * 12;
    final cornerRadius = radius.clamp(24.0, 58.0);
    final sideTop = size.height * (1 - 0.92 * spread);

    // Gemini's effect is a wide U-shaped wash, not a bordered rectangle. The
    // two neutral strokes create a cloudy inner edge with no crisp core and no
    // line across the top of the screen.
    final ambientRail = Path()
      ..moveTo(0, sideTop)
      ..lineTo(0, size.height - cornerRadius)
      ..quadraticBezierTo(0, size.height, cornerRadius, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - cornerRadius,
      )
      ..lineTo(size.width, sideTop);
    canvas.drawPath(
      ambientRail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26)
        ..color = const Color(0xFFE8EDF3).withValues(alpha: opacity * 0.22),
    );
    canvas.drawPath(
      ambientRail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..color = const Color(0xFFF8FAFC).withValues(alpha: opacity * 0.38),
    );

    final sideHeight = size.height * (0.24 + spread * 0.56);
    _drawGlow(
      canvas,
      center: Offset(-12 + horizontalDrift, size.height * 0.80),
      width: 150,
      height: sideHeight * 0.58,
      color: companion ? const Color(0xFFF97316) : const Color(0xFF62E58F),
      opacity: opacity * 0.44,
    );
    _drawGlow(
      canvas,
      center: Offset(-20 - horizontalDrift * 0.4, size.height * 0.47),
      width: 105,
      height: sideHeight * 0.66,
      color: companion ? const Color(0xFFFDBA74) : const Color(0xFF93C5FD),
      opacity: opacity * 0.20,
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.48 + horizontalDrift, size.height + 12),
      width: size.width * 0.64,
      height: 125,
      color: companion ? const Color(0xFFFB923C) : const Color(0xFFFACC15),
      opacity: opacity * 0.48,
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.82 - horizontalDrift, size.height + 6),
      width: size.width * 0.46,
      height: 120,
      color: const Color(0xFF60A5FA),
      opacity: opacity * 0.30,
    );
    _drawGlow(
      canvas,
      center: Offset(size.width + 12 - horizontalDrift, size.height * 0.76),
      width: 145,
      height: sideHeight * 0.62,
      color: const Color(0xFFC084FC),
      opacity: opacity * 0.40,
    );
    _drawGlow(
      canvas,
      center: Offset(
        size.width + 18 + horizontalDrift * 0.5,
        size.height * 0.27 + verticalDrift,
      ),
      width: 110,
      height: sideHeight * 0.72,
      color: const Color(0xFFFB7185),
      opacity: opacity * 0.34,
    );
  }

  double _bloomEnvelope(double timeline) {
    if (timeline < 0.10) {
      return Curves.easeOut.transform(timeline / 0.10);
    }
    if (timeline < 0.56) return 1;
    return 1 - Curves.easeInCubic.transform((timeline - 0.56) / 0.44);
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required Color color,
    required double opacity,
  }) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.46),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant VoiceEdgePainter oldDelegate) =>
      oldDelegate.entranceProgress != entranceProgress ||
      oldDelegate.ambientProgress != ambientProgress ||
      oldDelegate.activityIntensity != activityIntensity ||
      oldDelegate.activity != activity ||
      oldDelegate.radius != radius ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.companion != companion;
}
