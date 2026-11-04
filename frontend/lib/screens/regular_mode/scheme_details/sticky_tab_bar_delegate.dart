import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

/// Custom [SliverPersistentHeaderDelegate] for the sticky scheme details tab bar.
///
/// Extracted from `scheme_details_screen.dart` (frontend refactor C5, safe slice).
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  static const double kHeight = 48.0;

  const StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => kHeight;

  @override
  double get maxExtent => kHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.surface, height: kHeight, child: child);
  }

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
