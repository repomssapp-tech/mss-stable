import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../common/app_tappable.dart';

/// One stop of a [SpotlightTour]: the widget to light up and what to say.
class TourStep {
  const TourStep({
    required this.target,
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Key of the real widget to highlight (measured live, never a fixed spot).
  final GlobalKey target;
  final IconData icon;
  final String title;
  final String body;
}

/// The words around the steps, already localised.
class TourLabels {
  const TourLabels({
    required this.skip,
    required this.next,
    required this.finish,
    required this.progress,
  });

  final String skip;
  final String next;
  final String finish;

  /// "1 of 4".
  final String Function(int current, int total) progress;
}

/// A dark overlay with a spotlight on the current step's real widget, a curved
/// arrow to a card that explains it, and Skip / Next / Finish.
///
/// [stepsBuilder] and [labelsBuilder] run on every build, so the text follows
/// the app language and text scale. The target's rectangle and the card's size
/// are re-measured on every frame, so the spotlight follows layout changes
/// (rotation, language, text scale, a button moving). A step whose target never
/// appears is skipped after a short wait. The overlay absorbs all touches, so
/// the page underneath cannot be used until the tour ends.
class SpotlightTour extends StatefulWidget {
  const SpotlightTour({
    super.key,
    required this.stepsBuilder,
    required this.labelsBuilder,
    required this.onFinish,
    required this.onSkip,
    this.initialStep = 0,
  });

  final List<TourStep> Function(BuildContext context) stepsBuilder;
  final TourLabels Function(BuildContext context) labelsBuilder;

  /// The last step's Finish was pressed (or every remaining target was gone).
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final int initialStep;

  @override
  State<SpotlightTour> createState() => _SpotlightTourState();
}

class _SpotlightTourState extends State<SpotlightTour>
    with SingleTickerProviderStateMixin {
  static const int _framesBeforeGivingUp = 90;

  final GlobalKey _cardKey = GlobalKey(debugLabel: 'tour-card');
  late final Ticker _ticker;
  late int _step = widget.initialStep;
  Rect? _target;
  Size? _cardSize;
  int _missingFrames = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_measure)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final steps = widget.stepsBuilder(context);
    if (steps.isEmpty) return;
    final step = steps[_step.clamp(0, steps.length - 1)];
    final overlayBox = context.findRenderObject();
    Rect? target;
    final box = step.target.currentContext?.findRenderObject();
    if (overlayBox is RenderBox &&
        overlayBox.hasSize &&
        box is RenderBox &&
        box.attached &&
        box.hasSize) {
      target = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    }
    final card = _cardKey.currentContext?.findRenderObject();
    final cardSize = card is RenderBox && card.hasSize ? card.size : null;

    if (target == null) {
      if (++_missingFrames >= _framesBeforeGivingUp) {
        _advance(steps);
        return;
      }
    } else {
      _missingFrames = 0;
    }
    if (_differs(target, _target) || cardSize != _cardSize) {
      setState(() {
        _target = target;
        _cardSize = cardSize;
      });
    }
  }

  static bool _differs(Rect? a, Rect? b) {
    if (a == null || b == null) return a != b;
    return (a.left - b.left).abs() > 0.5 ||
        (a.top - b.top).abs() > 0.5 ||
        (a.width - b.width).abs() > 0.5 ||
        (a.height - b.height).abs() > 0.5;
  }

  void _advance(List<TourStep> steps) {
    _missingFrames = 0;
    if (_step >= steps.length - 1) {
      widget.onFinish();
    } else {
      setState(() {
        _step++;
        _target = null;
        _cardSize = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.stepsBuilder(context);
    final labels = widget.labelsBuilder(context);
    final step = steps[_step.clamp(0, steps.length - 1)];
    final isLast = _step >= steps.length - 1;
    final media = MediaQuery.of(context);
    final size = media.size;
    final cardWidth = math.min(size.width - AppSpacing.lg * 2, 420.0);
    final cardLeft = (size.width - cardWidth) / 2;
    final cardHeight = _cardSize?.height ?? 220.0;
    final target = _target;

    // Below the target when it sits in the top part of the screen, above it
    // otherwise (the Saarthi button and the bottom bar items).
    final below = target != null && target.center.dy < size.height * 0.45;
    const arrowRoom = 44.0;
    final minTop = media.padding.top + AppSpacing.sm;
    final maxTop =
        size.height - media.padding.bottom - cardHeight - AppSpacing.sm;
    var cardTop = target == null
        ? (size.height - cardHeight) / 2
        : below
        ? target.bottom + arrowRoom
        : target.top - arrowRoom - cardHeight;
    cardTop = cardTop.clamp(minTop, math.max(minTop, maxTop));

    return Stack(
      children: [
        // Absorbs every touch: nothing under the tour can be used.
        const Positioned.fill(child: ModalBarrier(dismissible: false)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ScrimPainter(target)),
          ),
        ),
        if (target != null && _cardSize != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ArrowPainter(
                  target: target,
                  card: Rect.fromLTWH(
                    cardLeft,
                    cardTop,
                    cardWidth,
                    _cardSize!.height,
                  ),
                  cardIsAbove: !below,
                ),
              ),
            ),
          ),
        Positioned(
          left: cardLeft,
          top: cardTop,
          width: cardWidth,
          child: Semantics(
            container: true,
            liveRegion: true,
            child: _TourCard(
              key: _cardKey,
              step: step,
              index: _step,
              total: steps.length,
              labels: labels,
              isLast: isLast,
              maxHeight: size.height - minTop - media.padding.bottom,
              onNext: () => _advance(steps),
              onSkip: widget.onSkip,
            ),
          ),
        ),
      ],
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.labels,
    required this.isLast,
    required this.maxHeight,
    required this.onNext,
    required this.onSkip,
  });

  final TourStep step;
  final int index;
  final int total;
  final TourLabels labels;
  final bool isLast;
  final double maxHeight;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = labels.progress(index + 1, total);
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.xlAll,
      elevation: 4,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress chip at the start, Skip at the far end.
              Row(
                children: [
                  Flexible(
                    // Align fills the row's free space, so Skip sits at the
                    // far end while the chip keeps its own width.
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            progress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.label.copyWith(
                              color: AppColors.primaryStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppTappable(
                    onTap: onSkip,
                    semanticLabel: labels.skip,
                    borderRadius: AppRadius.pillAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        labels.skip,
                        style: context.text.body.copyWith(
                          color: AppColors.primaryStrong,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Icon beside the title; the description below it then gets the
              // card's whole width.
              Row(
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(step.icon, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        step.title,
                        textAlign: TextAlign.justify,
                        style: context.text.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                step.body,
                textAlign: TextAlign.justify,
                style: context.text.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: AppSpacing.sm,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < total; i++)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: i == index ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == index
                                    ? AppColors.primary
                                    : AppColors.primaryBorder,
                                borderRadius: AppRadius.pillAll,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onNext,
                    iconAlignment: IconAlignment.end,
                    icon: Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(isLast ? labels.finish : labels.next),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark scrim over the whole screen with a rounded hole and a soft blue glow
/// around [target].
class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.target);

  final Rect? target;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.72);
    final full = Offset.zero & size;
    final t = target;
    if (t == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final hole = RRect.fromRectAndRadius(
      t.inflate(6),
      Radius.circular(math.min(t.shortestSide / 2 + 6, 28)),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(full)
        ..addRRect(hole),
      scrim,
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..color = AppColors.primaryBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.target != target;
}

/// A curved arrow from the card's edge to the highlighted widget.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    required this.target,
    required this.card,
    required this.cardIsAbove,
  });

  final Rect target;
  final Rect card;
  final bool cardIsAbove;

  @override
  void paint(Canvas canvas, Size size) {
    final startX = target.center.dx.clamp(card.left + 32, card.right - 32);
    final start = Offset(startX, cardIsAbove ? card.bottom : card.top);
    final end = Offset(
      target.center.dx,
      cardIsAbove ? target.top - 10 : target.bottom + 10,
    );
    if ((end - start).distance < 14) return;
    final midY = (start.dy + end.dy) / 2;
    final c1 = Offset(start.dx, midY);
    final c2 = Offset(end.dx, midY);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final line = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Arrowhead: along the curve's final direction.
    final dir = end - c2;
    final angle = math.atan2(dir.dy, dir.dx);
    const head = 11.0;
    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - head * math.cos(angle - 0.5),
        end.dy - head * math.sin(angle - 0.5),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - head * math.cos(angle + 0.5),
        end.dy - head * math.sin(angle + 0.5),
      );

    canvas.drawPath(path, glow);
    canvas.drawPath(headPath, glow);
    canvas.drawPath(path, line);
    canvas.drawPath(headPath, line);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.target != target ||
      old.card != card ||
      old.cardIsAbove != cardIsAbove;
}
