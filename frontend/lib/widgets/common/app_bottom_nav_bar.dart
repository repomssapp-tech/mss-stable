import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../services/haptics/haptics_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import 'app_tappable.dart';

/// Side margin of the floating bar.
const double kNavBarSideMargin = AppSpacing.md;

/// Space between the pill's edge and the first/last tab.
const double kNavBarInnerPad = AppSpacing.xs;

/// Gap between the floating bar and the system gesture area.
const double kNavBarFloatGap = AppSpacing.sm;

/// Base bar height before text scaling.
const double kNavBarBaseHeight = 64;

/// Smallest bottom-nav label scale: 11sp for the 12sp label style, the
/// smallest Material label size. Below it a label is unreadable, so a label
/// too long for its slot wraps onto a second line instead of shrinking
/// further (it used to go down to 0.75x, about 8sp).
const double kMinNavLabelScale = 11 / 12;

const List<(IconData, IconData)> _icons = [
  (Icons.home_outlined, Icons.home_rounded),
  (Icons.search_rounded, Icons.search_rounded),
  (Icons.explore_outlined, Icons.explore_rounded),
  (Icons.bookmark_border_rounded, Icons.bookmark_rounded),
  (Icons.person_outline_rounded, Icons.person_rounded),
];

/// The app's five-tab bottom bar: a floating liquid-glass pill.
///
/// The active tab sits in a glass "droplet" that covers both its icon and its
/// label, both in the brand primary colour. Tapping a tab slides the droplet
/// there on a spring; dragging a finger along the bar carries the droplet
/// under the finger (it stretches between tabs like a drop of water and
/// rounds up again over each one), switching tabs as it passes them, and
/// settles on the nearest tab when the finger lifts.
///
/// Labels sit under five equal slots, so the bar follows the system font size
/// only up to a point; its height tracks the (capped) scale so larger fonts get
/// a taller bar, not labels broken mid-word. The bar is built from the context
/// INSIDE the Scaffold's bottom slot (never above it), so the status-bar
/// padding can never inflate it.
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.labels,
    this.itemKeys = const {},
  }) : assert(labels.length == 5, 'home, search, discover, saved, profile');

  /// Optional keys for individual tabs (by index), so something else can find
  /// the real tab's position, e.g. the first-time tour.
  final Map<int, GlobalKey> itemKeys;

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Home, Search, Discover, Saved, Profile -- already localised.
  final List<String> labels;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  // Droplet position in slot units: 0 = first tab ... 4 = last tab.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 26,
  );

  bool _dragging = false;
  int _reported = 0;

  @override
  void initState() {
    super.initState();
    _reported = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(AppBottomNavBar old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.selectedIndex != old.selectedIndex) {
      _reported = widget.selectedIndex;
      _settleOn(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _settleOn(int index, {double velocity = 0}) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      // "Remove animations" / animation scale 0 (also a common developer
      // setting): no spring or stretch, but still a short slide so the droplet
      // never just jumps between tabs.
      _pos.animateTo(
        index.toDouble(),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _pos.animateWith(
      SpringSimulation(_spring, _pos.value, index.toDouble(), velocity),
    );
  }

  /// Reports [index] once when the droplet reaches a new tab during a drag.
  void _select(int index) {
    if (index == _reported) return;
    _reported = index;
    HapticsService.instance.tap();
    widget.onSelected(index);
  }

  void _onTap(int index) {
    _reported = index;
    _settleOn(index);
    widget.onSelected(index);
  }

  double _slotAt(double dx, double slotWidth) =>
      ((dx - kNavBarInnerPad) / slotWidth - 0.5).clamp(0.0, 4.0);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final fit = _navLabelFit(context, widget.labels);
    final scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: kMinNavLabelScale, maxScaleFactor: fit.scale);
    final height =
        scaler.scale(kNavBarBaseHeight) + (fit.wraps ? fit.lineHeight : 0);

    // No backdrop colour: the bar floats over the page, which scrolls (blurred)
    // behind the glass pill.
    return Padding(
      padding: EdgeInsets.only(
        left: kNavBarSideMargin,
        right: kNavBarSideMargin,
        bottom: bottomInset + kNavBarFloatGap,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(height: height),
          child: _GlassPill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth =
                    (constraints.maxWidth - kNavBarInnerPad * 2) / 5;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) {
                    _dragging = true;
                    _pos.stop();
                    _pos.value = _slotAt(d.localPosition.dx, slotWidth);
                  },
                  onHorizontalDragUpdate: (d) {
                    _pos.value = _slotAt(d.localPosition.dx, slotWidth);
                    _select(_pos.value.round());
                  },
                  onHorizontalDragEnd: (d) {
                    _dragging = false;
                    final index = _pos.value.round();
                    _select(index);
                    _settleOn(
                      index,
                      velocity: d.velocity.pixelsPerSecond.dx / slotWidth,
                    );
                  },
                  onHorizontalDragCancel: () {
                    _dragging = false;
                    _settleOn(widget.selectedIndex);
                  },
                  child: AnimatedBuilder(
                    animation: _pos,
                    builder: (context, _) => _buildSlots(slotWidth, height),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlots(double slotWidth, double height) {
    final pos = _pos.value.clamp(-0.3, 4.3);
    final active = pos.round().clamp(0, 4);
    // 0 over a tab, 1 halfway between two: the droplet stretches sideways
    // and flattens a little while it travels, then rounds up again.
    final travel = math.sin(math.pi * (pos - pos.floorToDouble()));
    // Wider than its slot, so the whole label (any language, up to the width
    // the bar's label scaling allows) sits inside the glow with room to spare.
    // 10% smaller than before (see _Droplet for its 10% lighter colour).
    final dropBase = (slotWidth + AppSpacing.md) * 0.9;
    final dropWidth = dropBase * (1 + 0.32 * travel);
    final dropHeight = (height - AppSpacing.sm * 2) * 0.9 * (1 - 0.1 * travel);
    final centerX = kNavBarInnerPad + slotWidth * (pos + 0.5);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: (centerX - dropWidth / 2).clamp(
            2.0,
            slotWidth * 5 + kNavBarInnerPad * 2 - dropWidth - 2,
          ),
          top: (height - dropHeight) / 2,
          width: dropWidth,
          height: dropHeight,
          child: const IgnorePointer(child: _Droplet()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kNavBarInnerPad),
          child: Row(
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: AppNavBarItem(
                    key: widget.itemKeys[i],
                    label: widget.labels[i],
                    icon: _icons[i].$1,
                    selectedIcon: _icons[i].$2,
                    selected: i == active,
                    onTap: () => _onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One tab of [AppBottomNavBar]: icon over label, announced as a selectable
/// tab.
class AppNavBarItem extends StatelessWidget {
  const AppNavBarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return AppTappable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      borderRadius: AppRadius.pillAll,
      // The droplet behind it already shows the tab; the slot fills the bar.
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: context.text.label.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar's glass body: blurred backdrop, a bright top-lit tint, a hairline
/// white rim and a soft drop shadow.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillAll,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withValues(alpha: 0.95),
                  AppColors.primarySoft.withValues(alpha: 0.88),
                ],
              ),
              border: Border.all(color: AppColors.surface, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The glass droplet behind the active tab: a primary-tinted lens with a
/// bright highlight along its top edge.
class _Droplet extends StatelessWidget {
  const _Droplet();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillAll,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withValues(alpha: 0.765),
            AppColors.primary.withValues(alpha: 0.144),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.198)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.162),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

/// Largest text scale (at most 1.15) at which every bottom-nav label still
/// fits on one line in its slot, measured from the actual labels (any
/// language) and the screen width; and whether, even at
/// [kMinNavLabelScale], some label does not fit and has to wrap.
({double scale, bool wraps, double lineHeight}) _navLabelFit(
  BuildContext context,
  List<String> labels,
) {
  final style = context.text.label.copyWith(fontWeight: FontWeight.w700);
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
      (MediaQuery.sizeOf(context).width -
          (kNavBarSideMargin + kNavBarInnerPad) * 2) /
      labels.length;
  // The droplet is wider than the slot, so a label may use nearly all of it.
  final usable = slot - AppSpacing.xs * 2;
  final fit = usable / widest;
  return (
    scale: fit.clamp(kMinNavLabelScale, 1.15),
    wraps: fit < kMinNavLabelScale,
    lineHeight: lineHeight,
  );
}
