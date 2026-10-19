import 'dart:async';

/// Collapses a burst of calls into one: only the last action scheduled within
/// [delay] runs. Used for writes that can come in rapid bursts (marking several
/// notifications read, saving the profile while the user edits it).
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;
  FutureOr<void> Function()? _pending;

  bool get isPending => _pending != null;

  /// Schedules [action], replacing any action still waiting.
  void run(FutureOr<void> Function() action) {
    _pending = action;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(flush()));
  }

  /// Runs the waiting action now (for example when the app goes to the
  /// background). Does nothing when nothing is waiting.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final action = _pending;
    _pending = null;
    if (action != null) await action();
  }

  /// Drops the waiting action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
