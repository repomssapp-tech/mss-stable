import 'package:flutter/widgets.dart';

import '../../services/haptics/haptics_service.dart';

/// Gives a light haptic tick on every tap anywhere in the app, when haptics
/// are on in Settings. Wraps the whole app (MaterialApp.builder).
///
/// It only listens: it never consumes pointer events, so every button,
/// gesture and scroll works exactly as before. A touch counts as a tap when
/// it lifts within [_maxTapDuration] and moves less than [_maxTapSlop]
/// logical pixels, so scrolls and drags do not buzz.
class HapticTouchLayer extends StatefulWidget {
  const HapticTouchLayer({super.key, required this.child});

  final Widget child;

  @override
  State<HapticTouchLayer> createState() => _HapticTouchLayerState();
}

class _HapticTouchLayerState extends State<HapticTouchLayer> {
  static const Duration _maxTapDuration = Duration(milliseconds: 450);
  static const double _maxTapSlop = 18;

  final Map<int, (Offset, Duration)> _downs = {};

  void _onDown(PointerDownEvent e) =>
      _downs[e.pointer] = (e.position, e.timeStamp);

  void _onUp(PointerUpEvent e) {
    final down = _downs.remove(e.pointer);
    if (down == null) return;
    final (position, time) = down;
    if ((e.position - position).distance > _maxTapSlop) return;
    if (e.timeStamp - time > _maxTapDuration) return;
    HapticsService.instance.tap();
  }

  void _onCancel(PointerCancelEvent e) => _downs.remove(e.pointer);

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _onDown,
    onPointerUp: _onUp,
    onPointerCancel: _onCancel,
    child: widget.child,
  );
}
