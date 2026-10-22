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
        builder: (slotContext) {
          final fit = _navLabelFit(slotContext, labels);
          return MediaQuery(
            data: MediaQuery.of(slotContext).copyWith(
              textScaler: MediaQuery.textScalerOf(slotContext).clamp(
                minScaleFactor: kMinNavLabelScale,
                maxScaleFactor: fit.scale,
              ),
            ),
            child: Builder(
              builder: (navContext) => NavigationBar(
                // One more label line when a label has to wrap.
                height:
                    MediaQuery.textScalerOf(
                      navContext,
                    ).scale(NavigationBarTheme.of(navContext).height ?? 64) +
                    (fit.wraps ? fit.lineHeight : 0),
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
          );
        },
      ),
    );
  }
}

/// Smallest bottom-nav label scale: 11sp for the 12sp label style, the
/// smallest Material label size. Below it a label is unreadable, so a label
/// too long for its slot wraps onto a second line instead of shrinking
/// further (it used to go down to 0.75x, about 8sp).
const double kMinNavLabelScale = 11 / 12;

/// Largest text scale (at most 1.15) at which every bottom-nav label still
/// fits on one line in its slot, measured from the actual labels (any
/// language) and the screen width; and whether, even at
/// [kMinNavLabelScale], some label does not fit and has to wrap.
({double scale, bool wraps, double lineHeight}) _navLabelFit(
  BuildContext context,
  List<String> labels,
) {
  final style =
      NavigationBarTheme.of(context).labelTextStyle?.resolve(const {}) ??
      Theme.of(context).textTheme.labelMedium ??
      const TextStyle();
  final lineHeight =
      (style.fontSize ?? 12) * (style.height ?? 1.4) * kMinNavLabelScale;
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
  }
  if (widest == 0) return (scale: 1.15, wraps: false, lineHeight: lineHeight);
  final slot = MediaQuery.sizeOf(context).width / labels.length;
  final usable = slot - AppSpacing.sm * 2;
  final fit = usable / widest;
  return (
    scale: fit.clamp(kMinNavLabelScale, 1.15),
    wraps: fit < kMinNavLabelScale,
    lineHeight: lineHeight,
  );
}
