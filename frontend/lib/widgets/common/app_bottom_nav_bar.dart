import 'dart:math' as math;

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

/// Base height of the violet pill before text scaling.
const double kNavBarBaseHeight = 64;

/// How far the active tab's glass tile rises above the pill.
const double kNavBarLift = 18;

/// Smallest label scale: 11sp for the 12sp label style.
const double kMinNavLabelScale = 11 / 12;

const List<(IconData, IconData)> _icons = [
  (Icons.home_outlined, Icons.home_rounded),
  (Icons.search_rounded, Icons.search_rounded),
  (Icons.explore_outlined, Icons.explore_rounded),
  (Icons.bookmark_border_rounded, Icons.bookmark_rounded),
  (Icons.person_outline_rounded, Icons.person_rounded),
];

/// The app's five-tab bottom bar (v2 design): a floating violet pill with
/// light-blue icons. The active tab rises out of the pill as a glossy glass
/// tile (white icon, a cyan-white glow along its top edge) with its label in
/// bold white below it.
///
/// Tapping a tab springs the tile there; dragging a finger along the bar
/// carries the tile under the finger like a drop of liquid (it sinks into the
/// pill and stretches between tabs, then rises again over each one),
/// switching tabs as it passes them, and settles on the nearest tab when the
/// finger lifts.
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
  // Tile position in slot units: 0 = first tab ... 4 = last tab.
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

  /// Reports [index] once when the tile reaches a new tab during a drag.
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
    final scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: kMinNavLabelScale, maxScaleFactor: 1.15);
    final barHeight = scaler.scale(kNavBarBaseHeight);

    return Padding(
      padding: EdgeInsets.only(
        left: kNavBarSideMargin,
        right: kNavBarSideMargin,
        bottom: bottomInset + kNavBarFloatGap,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(height: barHeight + kNavBarLift),
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
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pos,
                    builder: (context, _) =>
                        _buildBar(context, slotWidth, barHeight),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, double slotWidth, double barHeight) {
    final pos = _pos.value.clamp(-0.3, 4.3);
    final active = pos.round().clamp(0, 4);
    // 0 over a tab, 1 halfway between two: the tile sinks into the pill and
    // stretches sideways while it travels, then rises and rounds up again.
    final travel = math.sin(math.pi * (pos - pos.floorToDouble()));
    final tileSize = math.min(slotWidth * 0.9, barHeight * 0.92);
    final tileWidth = tileSize * (1 + 0.28 * travel);
    final tileHeight = tileSize * (1 - 0.08 * travel);
    final lift = kNavBarLift * (1 - 0.7 * travel);
    final centerX = kNavBarInnerPad + slotWidth * (pos + 0.5);
    final tileTop = kNavBarLift - lift + AppSpacing.xs;
    final labelOpacity = (1 - travel * 1.6).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The violet pill.
        Positioned(
          left: 0,
          right: 0,
          top: kNavBarLift,
          bottom: 0,
          child: const _VioletPill(),
        ),
        // Idle icons (the active slot's icon is drawn on the tile instead).
        Positioned(
          left: kNavBarInnerPad,
          right: kNavBarInnerPad,
          top: kNavBarLift,
          bottom: 0,
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
        // The raised glass tile.
        Positioned(
          left: centerX - tileWidth / 2,
          top: tileTop,
          width: tileWidth,
          height: tileHeight,
          child: IgnorePointer(
            child: _GlassTile(icon: _icons[active].$2, size: tileSize),
          ),
        ),
        // The active tab's label, in the pill under the tile.
        Positioned(
          left: centerX - slotWidth * 0.75,
          width: slotWidth * 1.5,
          bottom: AppSpacing.xs,
          child: IgnorePointer(
            child: Opacity(
              opacity: labelOpacity,
              child: ExcludeSemantics(
                child: Text(
                  widget.labels[active],
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: context.text.label.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One tab slot of [AppBottomNavBar]: its idle light-blue icon (hidden while
/// it is the active tab, whose icon sits on the raised tile), announced as a
/// selectable tab with its label.
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
          child: Icon(selectedIcon, color: AppColors.navIconIdle, size: 24),
        ),
      ),
    );
  }
}

/// The bar's body: a solid violet pill with a soft violet glow under it.
class _VioletPill extends StatelessWidget {
  const _VioletPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillAll,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navViolet, AppColors.navVioletDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navViolet.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

/// The glossy glass tile on the active tab: lighter violet, a thin light rim,
/// a cyan-white glow along its top edge and a white icon with a soft shadow.
/// Drawn with gradients only (no backdrop blur), so sliding it costs one
/// small repaint per frame.
class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.3);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.navTile,
        border: Border.all(
          color: AppColors.textOnPrimary.withValues(alpha: 0.32),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navVioletDeep.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Glow along the top edge.
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.78,
                heightFactor: 0.34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.1,
                      colors: [
                        AppColors.navGlow.withValues(alpha: 0.95),
                        AppColors.navGlow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Faint sheen toward the bottom.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.textOnPrimary.withValues(alpha: 0),
                    AppColors.textOnPrimary.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                color: AppColors.textOnPrimary,
                size: size * 0.46,
                shadows: [
                  Shadow(
                    color: AppColors.navVioletDeep.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
