import 'dart:async';

import 'package:flutter/widgets.dart';

import 'connectivity_service.dart';

/// Runs [task] every [interval] of ACTIVE use of the app.
///
/// * The clock only counts while the app is in the foreground: going to the
///   background pauses it (the elapsed active time is kept) and coming back
///   resumes it, so "every 30 minutes" means 30 minutes of actual use.
/// * Nothing runs while the phone reports no network; when a network comes
///   back, [onReconnect] (default [task]) runs once.
/// * [onResume] runs when the app returns to the foreground. Callers pass work
///   that is already guarded by `RequestManager`, so a quick app switch does not
///   cost a request.
///
/// The poller schedules work only; it never calls the server itself.
class ForegroundPoller with WidgetsBindingObserver {
  ForegroundPoller({
    required this.interval,
    required this.task,
    this.onResume,
    this.onReconnect,
    ConnectivityService? connectivity,
    DateTime Function()? clock,
    Timer Function(Duration, void Function())? timerFactory,
    bool observeLifecycle = true,
  }) : _connectivity = connectivity,
       _clock = clock ?? DateTime.now,
       _timerFactory = timerFactory ?? Timer.new,
       _observeLifecycle = observeLifecycle;

  final Duration interval;
  final FutureOr<void> Function() task;
  final FutureOr<void> Function()? onResume;
  final FutureOr<void> Function()? onReconnect;
  final ConnectivityService? _connectivity;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function()) _timerFactory;
  final bool _observeLifecycle;

  bool _running = false;
  bool _foreground = true;
  Duration _accumulated = Duration.zero;
  DateTime? _activeSince;
  Timer? _timer;
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityService get _network =>
      _connectivity ?? ConnectivityService.instance;

  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;
    _foreground = true;
    _accumulated = Duration.zero;
    _activeSince = _clock();
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = _network.onChanged.listen((online) {
      if (online && _foreground) unawaited(_run(onReconnect ?? task));
    });
    _schedule();
  }

  void stop() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    unawaited(_connectivitySubscription?.cancel());
    _connectivitySubscription = null;
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
  }

  void _schedule() {
    _timer?.cancel();
    final remaining = interval - _accumulated;
    _timer = _timerFactory(
      remaining.isNegative ? Duration.zero : remaining,
      () => unawaited(_onTimer()),
    );
  }

  Future<void> _onTimer() async {
    if (!_running || !_foreground) return;
    _accumulated = Duration.zero;
    _activeSince = _clock();
    _schedule();
    if (!_network.isOnline) return;
    await _run(task);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_foreground) return;
        _foreground = true;
        _activeSince = _clock();
        _schedule();
        final resume = onResume;
        if (resume != null) unawaited(_run(resume));
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (!_foreground) return;
        _foreground = false;
        final since = _activeSince;
        if (since != null) _accumulated += _clock().difference(since);
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.inactive:
        // Transient (permission dialogs, notification shade): keep counting.
        break;
    }
  }

  Future<void> _run(FutureOr<void> Function() work) async {
    try {
      await work();
    } catch (e) {
      debugPrint('[ForegroundPoller] task failed: $e');
    }
  }
}
