import 'package:flutter/material.dart';

import '../../../utils/app_spacing.dart';

/// A small reusable static skeleton bar, for inline loading placeholders
/// (e.g. a category tile's count while getCategoryCounts() is still
/// computing) that are too small to warrant a full [ShimmerSkeletonCard].
/// Deliberately NOT animated, unlike [ShimmerSkeletonCard]: this shows
/// during the idle Browse Categories view, which is on screen by default
/// (not just during a transient results-loading state), so an indefinitely-
/// repeating animation here would leave every widget test that pumps this
/// screen unable to ever reach `pumpAndSettle()` -- there would always be a
/// pending frame. A static box still reads as "loading" via its shape/color.
///
/// Extracted from `search_screen.dart` (frontend refactor C5, safe slice) —
/// zero coupling to `SearchScreenState`. Renamed from the file-private
/// `_SkeletonBar` since Dart privacy is per-file; no external references
/// existed before the move (grep-verified), so widening visibility changes
/// nothing behaviourally.
class SearchSkeletonBar extends StatelessWidget {
  const SearchSkeletonBar({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Sweeps one soft highlight across [child] (the whole skeleton list at once,
/// so every card shimmers in step instead of blinking on its own). Stays
/// still when the platform asks for reduced motion.
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-2.0 + 4.0 * t, -0.3),
            end: Alignment(-1.0 + 4.0 * t, 0.3),
            colors: const [
              Color(0x00FFFFFF),
              Color(0xB3FFFFFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Scheme-card placeholder shown while search results load. Static on its
/// own; wrap the list in [ShimmerSweep] to animate it. Bars scale with the
/// card width so narrow phones and large text do not overflow.
class ShimmerSkeletonCard extends StatelessWidget {
  const ShimmerSkeletonCard({super.key});

  static const _barDecoration = BoxDecoration(
    color: Color(0xFFE2E8F0),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  static Widget _bar(double height, {double widthFactor = 1}) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(height: height, decoration: _barDecoration),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(16, widthFactor: 0.7),
                const SizedBox(height: AppSpacing.sm),
                _bar(14, widthFactor: 0.45),
                const SizedBox(height: AppSpacing.md),
                _bar(12),
                const SizedBox(height: AppSpacing.tight),
                _bar(12, widthFactor: 0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
