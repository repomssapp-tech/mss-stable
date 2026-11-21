import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/account/app_session.dart';
import '../../services/onboarding/home_tour_store.dart';
import 'home_tour_targets.dart';
import 'spotlight_tour.dart';

/// Why [HomeTour.maybeStart] did or did not show the tour.
enum HomeTourStart {
  /// The tour is now on screen.
  started,

  /// This account has already finished or skipped it; never ask again.
  alreadyDone,

  /// Not signed in, or a tour is already showing.
  notApplicable,

  /// Some target is not on screen yet; try again shortly.
  notReady,
}

/// The first-time home tour: search bar, Saarthi button, then the Discover and
/// Profile items of the bottom bar. Shown once per signed-in account; Finish
/// and Skip are both remembered (see [HomeTourStore]).
class HomeTour {
  const HomeTour._();

  static OverlayEntry? _entry;

  /// A tour is on screen. Only one can exist at a time.
  static bool get isShowing => _entry != null;

  /// Whether the tour is already done, read ahead of time (see [prefetch]).
  /// Null until known.
  static bool? _knownDone;

  /// True when the tour still has to be shown here. Null until [prefetch]
  /// has run.
  static bool? get pending => _knownDone == null ? null : !_knownDone!;

  /// Reads the tour status before home is built (the navigation-mode screen
  /// and the splash call it), so home can start the tour on its first frames
  /// instead of waiting to find out.
  static Future<bool> prefetch({
    HomeTourStore store = const HomeTourStore(),
  }) async {
    final done = await store.isDone(AppSession.instance.userId);
    _knownDone = done;
    return !done;
  }

  @visibleForTesting
  static void resetForTesting() => _knownDone = null;

  static Future<HomeTourStart> maybeStart(
    BuildContext context, {
    HomeTourStore store = const HomeTourStore(),
    String? userId,
  }) async {
    // A guest has no account id; the tour is still shown, once per phone.
    final id = userId ?? AppSession.instance.userId;
    if (_entry != null) return HomeTourStart.notApplicable;
    if (await store.isDone(id)) {
      _knownDone = true;
      return HomeTourStart.alreadyDone;
    }
    if (!context.mounted || _entry != null) return HomeTourStart.notApplicable;
    if (!HomeTourTargets.allReady) return HomeTourStart.notReady;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    void close(HomeTourOutcome outcome) {
      if (_entry != entry) return;
      entry.remove();
      _entry = null;
      _knownDone = true;
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

  /// Removes a tour that is on screen without recording anything (the shell is
  /// going away, e.g. on logout).
  static void dismiss() {
    final entry = _entry;
    _entry = null;
    entry?.remove();
  }

  static List<TourStep> _steps(BuildContext context) {
    final l10n = context.l10n;
    return [
      TourStep(
        target: HomeTourTargets.search,
        icon: Icons.search_rounded,
        title: l10n.homeTourFindTitle,
        body: l10n.homeTourFindBody,
      ),
      TourStep(
        target: HomeTourTargets.askSaarthi,
        icon: Icons.auto_awesome_rounded,
        title: l10n.homeTourAskTitle,
        body: l10n.homeTourAskBody,
      ),
      TourStep(
        target: HomeTourTargets.discover,
        icon: Icons.explore_rounded,
        title: l10n.homeTourDiscoverTitle,
        body: l10n.homeTourDiscoverBody,
      ),
      TourStep(
        target: HomeTourTargets.profile,
        icon: Icons.person_rounded,
        title: l10n.homeTourProfileTitle,
        body: l10n.homeTourProfileBody,
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
