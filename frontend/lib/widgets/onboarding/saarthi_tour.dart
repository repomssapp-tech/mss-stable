import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/account/app_session.dart';
import '../../services/onboarding/home_tour_store.dart';
import 'home_tour.dart';
import 'spotlight_tour.dart';

class SaarthiTourTargets {
  SaarthiTourTargets();

  final GlobalKey mic = GlobalKey(debugLabel: 'tour-saarthi-mic');
  final GlobalKey type = GlobalKey(debugLabel: 'tour-saarthi-type');
  final GlobalKey sessions = GlobalKey(debugLabel: 'tour-saarthi-sessions');

  bool get allReady => [mic, type, sessions].every(_laidOut);

  static bool _laidOut(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize;
  }
}

/// The first-time tour of Saarthi mode, the companion-mode counterpart of
/// [HomeTour]: speak, type, find past chats. Shown once per phone, guest or
/// signed-in; Finish and Skip are both remembered and survive sign-out.
class SaarthiTour {
  SaarthiTour();

  final targets = SaarthiTourTargets();

  static const HomeTourStore defaultStore = HomeTourStore(tour: 'saarthi');

  OverlayEntry? _entry;

  Future<HomeTourStart> maybeStart(
    BuildContext context, {
    HomeTourStore store = defaultStore,
    String? userId,
  }) async {
    final id = userId ?? AppSession.instance.userId;
    if (_entry != null || HomeTour.isShowing) {
      return HomeTourStart.notApplicable;
    }
    if (await store.isDone(id)) return HomeTourStart.alreadyDone;
    if (!context.mounted || _entry != null) return HomeTourStart.notApplicable;
    if (!targets.allReady || !HomeTour.isFrontmost(context)) {
      return HomeTourStart.notReady;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    void close(HomeTourOutcome outcome) {
      if (_entry != entry) return;
      entry.remove();
      _entry = null;
      store.record(id, outcome);
    }

    entry = OverlayEntry(
      builder: (_) => SpotlightTour(
        stepsBuilder: _steps,
        labelsBuilder: _labels,
        onFinish: () => close(HomeTourOutcome.completed),
        onSkip: () => close(HomeTourOutcome.skipped),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    return HomeTourStart.started;
  }

  /// Removes a tour that is on screen without recording anything.
  void dismiss() {
    final entry = _entry;
    _entry = null;
    entry?.remove();
  }

  List<TourStep> _steps(BuildContext context) {
    final l10n = context.l10n;
    return [
      TourStep(
        target: targets.mic,
        icon: Icons.mic_none_rounded,
        title: l10n.saarthiTourSpeakTitle,
        body: l10n.saarthiTourSpeakBody,
      ),
      TourStep(
        target: targets.type,
        icon: Icons.keyboard_outlined,
        title: l10n.saarthiTourTypeTitle,
        body: l10n.saarthiTourTypeBody,
      ),
      TourStep(
        target: targets.sessions,
        icon: Icons.search_rounded,
        title: l10n.saarthiTourHistoryTitle,
        body: l10n.saarthiTourHistoryBody,
      ),
    ];
  }

  static TourLabels _labels(BuildContext context) {
    final l10n = context.l10n;
    return TourLabels(
      skip: l10n.homeTourSkip,
      next: l10n.homeTourNext,
      finish: l10n.homeTourFinish,
      progress: l10n.homeTourProgress,
    );
  }
}
