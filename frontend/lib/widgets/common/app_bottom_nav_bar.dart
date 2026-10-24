import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../services/haptics/haptics_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import 'app_tappable.dart';
import 'nav_frosted_bubble.dart';

/// Side margin of the floating bar.
const double kNavBarSideMargin = AppSpacing.md;

/// Space between the pill's edge and the first/last tab.
const double kNavBarInnerPad = AppSpacing.xs;

/// Gap between the floating bar and the system gesture area.
const double kNavBarFloatGap = AppSpacing.sm;

/// Height of the white pill. The bar shows icons only (labels are read out
/// by screen readers), so it does not grow with the text scale.
const double kNavBarHeight = 64;

/// Diameter of the soft circle behind each idle icon.
const double _wellSize = 40;

/// How far the droplet tail reaches past the bubble's edge halfway between
/// two tabs. At rest there is no tail: the bubble is a plain circle.
const double _tailLength = 10;

const List<(IconData, IconData)> _icons = [
  (Icons.home_outlined, Icons.home_rounded),
  (Icons.search_rounded, Icons.search_rounded),
  (Icons.explore_outlined, Icons.explore_rounded),
  (Icons.bookmark_border_rounded, Icons.bookmark_rounded),
  (Icons.person_outline_rounded, Icons.person_rounded),
];

/// The app's five-tab bottom bar: a floating white pill with outline icons,
/// each in a soft lavender circle. The active tab is a round frosted purple
/// glass bubble (white icon, a light rim); while it moves it stretches and
/// grows a droplet tail trailing behind it.
///
/// Tapping a tab springs the bubble there; dragging a finger along the bar
/// carries the bubble under the finger like a drop of liquid (it stretches
/// between tabs and rounds up again over each one), switching tabs as it
/// passes them, and settles on the nearest tab when the finger lifts.
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

  /// Home, Search, Discover, Saved, Profile -- already localised. Announced
  /// by screen readers; the bar itself shows icons only.
  final List<String> labels;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  // Bubble position in slot units: 0 = first tab ... 4 = last tab.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 24,
  );

  bool _dragging = false;
  int _reported = 0;

  // Which way the tail points: 1 = right, -1 = left. It trails the bubble,
  // pointing back the way it came (on the last tab, toward the others).
  late double _tailDir = widget.selectedIndex == 4 ? -1 : 1;

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

  /// Points the tail back along a move to [to] (ignoring the spring's small
  /// overshoot, which would flip it).
  void _aimTail(double to) {
    final delta = to - _pos.value;
    if (delta.abs() > 0.05) _tailDir = -delta.sign;
  }

  void _settleOn(int index, {double velocity = 0}) {
    _aimTail(index.toDouble());
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
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

  /// Reports [index] once when the bubble reaches a new tab during a drag.
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

    return Padding(
      padding: EdgeInsets.only(
        left: kNavBarSideMargin,
        right: kNavBarSideMargin,
        bottom: bottomInset + kNavBarFloatGap,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(height: kNavBarHeight),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = (constraints.maxWidth - kNavBarInnerPad * 2) / 5;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) {
                _dragging = true;
                _pos.stop();
                _pos.value = _slotAt(d.localPosition.dx, slotWidth);
              },
              onHorizontalDragUpdate: (d) {
                final to = _slotAt(d.localPosition.dx, slotWidth);
                _aimTail(to);
                _pos.value = to;
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
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pos,
                  builder: (context, _) => _buildBar(slotWidth),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBar(double slotWidth) {
    final pos = _pos.value.clamp(-0.3, 4.3);
    final active = pos.round().clamp(0, 4);
    // 0 over a tab, 1 halfway between two: the bubble stretches sideways
    // while it travels and its tail grows, then it rounds up again.
    final travel = math.sin(math.pi * (pos - pos.floorToDouble()));
    final size = math.min(
      slotWidth * 0.92,
      kNavBarHeight - AppSpacing.tight * 2,
    );
    final width = size * (1 + 0.22 * travel);
    final height = size * (1 - 0.06 * travel);
    final centerX = kNavBarInnerPad + slotWidth * (pos + 0.5);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: _WhitePill()),
        // Idle tabs (the active slot's icon is drawn on the bubble instead).
        Positioned.fill(
          left: kNavBarInnerPad,
          right: kNavBarInnerPad,
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
        // The frosted bubble.
        Positioned(
          left: centerX - width / 2,
          top: (kNavBarHeight - height) / 2,
          width: width,
          height: height,
          child: IgnorePointer(
            child: NavFrostedBubble(
              icon: _icons[active].$2,
              iconSize: size * 0.44,
              tailDir: _tailDir,
              tail: _tailLength * travel,
            ),
          ),
        ),
      ],
    );
  }
}

/// One tab slot of [AppBottomNavBar]: its outline icon in a soft circle
/// (hidden while it is the active tab, whose icon sits on the bubble),
/// announced as a selectable tab with its label.
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
    return AppTappable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      borderRadius: AppRadius.pillAll,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: selected ? 0 : 1,
          child: Container(
            width: _wellSize,
            height: _wellSize,
            decoration: const BoxDecoration(
              color: AppColors.navWell,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.navIconIdle, size: 22),
          ),
        ),
      ),
    );
  }
}

/// The bar's body: a white pill with a hairline edge and a soft shadow, so
/// it floats over white pages too.
class _WhitePill extends StatelessWidget {
  const _WhitePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.navBubbleDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
