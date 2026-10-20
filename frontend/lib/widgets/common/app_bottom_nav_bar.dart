import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';

/// The app's five-tab bottom bar.
///
/// Labels sit under five equal slots, so the bar follows the system font size
/// only up to a point; its height tracks the (capped) scale so larger fonts get
/// a taller bar, not labels broken mid-word.
///
/// The text-scale override below is built from the context INSIDE the
/// Scaffold's bottom slot. Building it from a context above the Scaffold would
/// copy the status-bar padding back into the bar, and [NavigationBar]'s
/// SafeArea would add it on top: ~50dp of empty white above the icons.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.labels,
  }) : assert(labels.length == 5, 'home, search, discover, saved, profile');

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Home, Search, Discover, Saved, Profile -- already localised.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Builder(
        builder: (slotContext) => MediaQuery(
          data: MediaQuery.of(slotContext).copyWith(
            textScaler: MediaQuery.textScalerOf(slotContext).clamp(
              minScaleFactor: 0.75,
              maxScaleFactor: _navLabelScaleCap(slotContext, labels),
            ),
          ),
          child: Builder(
            builder: (navContext) => NavigationBar(
              height: MediaQuery.textScalerOf(
                navContext,
              ).scale(NavigationBarTheme.of(navContext).height ?? 64),
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: labels[0],
                ),
                NavigationDestination(
                  // Same glyph selected/unselected: the pill indicator carries
                  // the selected state instead.
                  icon: const Icon(Icons.search_rounded),
                  selectedIcon: const Icon(Icons.search_rounded),
                  label: labels[1],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore_rounded),
                  label: labels[2],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_border_rounded),
                  selectedIcon: const Icon(Icons.bookmark_rounded),
                  label: labels[3],
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: labels[4],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Largest text scale at which every bottom-nav label still fits on one line in
/// its slot. Measured from the actual labels (any language) and the screen
/// width, so narrow phones and long translations shrink the labels slightly
/// instead of breaking words, and roomy phones follow the system font size.
double _navLabelScaleCap(BuildContext context, List<String> labels) {
  final style =
      NavigationBarTheme.of(context).labelTextStyle?.resolve(const {}) ??
      Theme.of(context).textTheme.labelMedium ??
      const TextStyle();
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
  }
  if (widest == 0) return 1.15;
  final slot = MediaQuery.sizeOf(context).width / labels.length;
  final usable = slot - AppSpacing.sm * 2;
  return (usable / widest).clamp(0.75, 1.15);
}
