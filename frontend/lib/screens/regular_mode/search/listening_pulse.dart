import 'package:flutter/material.dart';

/// Rings that expand and fade behind [child] while the microphone is open,
/// so voice search visibly reads as "listening". Falls back to a steady halo
/// when the platform asks for reduced motion.
class ListeningPulse extends StatefulWidget {
  const ListeningPulse({
    super.key,
    required this.child,
    this.color = const Color(0xFFDC2626),
    this.size = 40,
  });

  final Widget child;
  final Color color;

  /// Diameter the rings grow to.
  final double size;

  @override
  State<ListeningPulse> createState() => _ListeningPulseState();
}

class _ListeningPulseState extends State<ListeningPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final still = !_controller.isAnimating;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in const [0.0, 0.5])
                _ring(still ? 0.6 : (_controller.value + offset) % 1.0, still),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }

  Widget _ring(double t, bool still) {
    final diameter = widget.size * (0.45 + 0.55 * t);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withValues(alpha: still ? 0.15 : 0.28 * (1 - t)),
      ),
    );
  }
}
