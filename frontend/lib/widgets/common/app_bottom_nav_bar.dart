import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';

/// Side margin of the floating bar.
const double kNavBarSideMargin = AppSpacing.lg;

/// Gap between the floating bar and the system gesture area.
const double kNavBarFloatGap = AppSpacing.sm;

/// The app's five-tab bottom bar: a floating frosted-glass pill. The tab
/// content shows through it blurred (the shell Scaffold uses `extendBody`),
/// tinted with the brand blue, with white icons and labels.
///
/// Labels sit under five equal slots, so the bar follows the system font size
/// only up to a point; its height tracks the (capped) scale so larger fonts get
/// a taller bar, not labels broken mid-word.
///
/// The text-scale override below is built from the context INSIDE the
/// Scaffold's bottom slot. Building it from a context above the Scaffold would
/// copy the status-bar padding back into the bar, and [NavigationBar]'s
/// SafeArea would add it on top: ~50dp of empty white above the icons. The
/// bar sits above the gesture inset itself, so its own SafeArea gets none.
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

  static NavigationBarThemeData _glassTheme(BuildContext context) {
    final base = NavigationBarTheme.of(context);
    final label = base.labelTextStyle?.resolve(const {}) ?? const TextStyle();
    return base.copyWith(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.textOnPrimary.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => label.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.textOnPrimary
              : AppColors.textOnPrimary.withValues(alpha: 0.78),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.textOnPrimary
              : AppColors.textOnPrimary.withValues(alpha: 0.78),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: kNavBarSideMargin,
        right: kNavBarSideMargin,
        bottom: bottomInset + kNavBarFloatGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.pillAll,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillAll,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.72),
                    AppColors.primaryDeep.withValues(alpha: 0.82),
                  ],
                ),
                border: Border.all(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.28),
                ),
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
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
                      child: NavigationBarTheme(
                        data: _glassTheme(slotContext),
                        child: Builder(
                          builder: (navContext) => NavigationBar(
                            // One more label line when a label has to wrap.
                            height:
                                MediaQuery.textScalerOf(navContext).scale(
                                  NavigationBarTheme.of(navContext).height ??
                                      64,
                                ) +
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
                                // Same glyph selected/unselected: the pill
                                // indicator carries the selected state.
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
                                selectedIcon: const Icon(
                                  Icons.bookmark_rounded,
                                ),
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
                    );
                  },
                ),
              ),
            ),
          ),
        ),
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
  final slot =
      (MediaQuery.sizeOf(context).width - kNavBarSideMargin * 2) /
      labels.length;
  final usable = slot - AppSpacing.sm * 2;
  final fit = usable / widest;
  return (
    scale: fit.clamp(kMinNavLabelScale, 1.15),
    wraps: fit < kMinNavLabelScale,
    lineHeight: lineHeight,
  );
}
