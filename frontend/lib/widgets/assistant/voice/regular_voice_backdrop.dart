import 'dart:math' as math;
import 'package:flutter/material.dart';

class RegularVoiceBackdrop extends StatelessWidget {
  const RegularVoiceBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1020), Color(0xFF070A12), Color(0xFF05070C)],
          stops: [0, 0.46, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5D52E8).withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D52E8).withValues(alpha: 0.16),
                    blurRadius: 120,
                    spreadRadius: 45,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -130,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF18BBD0).withValues(alpha: 0.07),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18BBD0).withValues(alpha: 0.12),
                    blurRadius: 130,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegularVoiceAmbientPainter extends CustomPainter {
  const RegularVoiceAmbientPainter({
    required this.progress,
    required this.intensity,
    required this.active,
    required this.reduceMotion,
  });

  final double progress;
  final double intensity;
  final bool active;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = reduceMotion ? 0.35 : progress;
    final pulse = active ? 0.6 + math.sin(phase * math.pi * 2) * 0.12 : 0.35;
    final center = Offset(size.width / 2, math.min(size.height * 0.31, 270));
    final radius = math.min(size.width * 0.38, 170) + intensity * 18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B7CFF).withValues(alpha: 0.0),
          const Color(0xFF8B7CFF).withValues(alpha: 0.16 * pulse),
          const Color(0xFF22D3EE).withValues(alpha: 0.0),
        ],
        stops: const [0.66, 0.86, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius + 18, paint..strokeWidth = 0.7);
  }

  @override
  bool shouldRepaint(covariant RegularVoiceAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.active != active ||
      oldDelegate.reduceMotion != reduceMotion;
}
