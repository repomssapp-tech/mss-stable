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
  const SearchSkeletonBar({super.key, required this.width, required this.height});

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

/// Self-contained shimmering scheme-card placeholder shown while search
/// results are loading.
///
/// Extracted from `search_screen.dart` (frontend refactor C5, safe slice) —
/// owns its own `AnimationController`, zero coupling to `SearchScreenState`.
/// Renamed from `_ShimmerSkeletonCard` for the same per-file-privacy reason
/// as [SearchSkeletonBar].
class ShimmerSkeletonCard extends StatefulWidget {
  const ShimmerSkeletonCard({super.key});

  @override
  State<ShimmerSkeletonCard> createState() => ShimmerSkeletonCardState();
}

class ShimmerSkeletonCardState extends State<ShimmerSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer Logo Box
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Shimmer Content Lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
