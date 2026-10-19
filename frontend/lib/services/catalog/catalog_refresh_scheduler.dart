import 'dart:async';

import 'package:flutter/widgets.dart';

import '../network/foreground_poller.dart';
import '../network/request_manager.dart';
import 'scheme_catalog_sync_service.dart';

/// When the app looks for a newer scheme catalog.
///
/// The app never queries schemes on the server: it searches its local copy of
/// the catalog. This scheduler only decides when to ask the catalog update API
/// (`GET /v1/catalog/current`) whether a newer release exists; if it does, the
/// sync service downloads and verifies it, installs it, and the controller then
/// reloads the local copy.
///
/// Checks happen:
/// * every time the app starts (always),
/// * every 30 minutes of active use (the clock pauses in the background),
/// * when the app returns to the foreground or the network comes back, at most
///   once a minute (a quick app switch costs nothing).
class CatalogRefreshScheduler {
  CatalogRefreshScheduler({
    required Future<CatalogSyncResult> Function() check,
    RequestManager? manager,
    ForegroundPoller? poller,
    DateTime Function()? clock,
    Timer Function(Duration, void Function())? timerFactory,
  }) : _check = check,
       _manager = manager ?? RequestManager.instance {
    _poller =
        poller ??
        ForegroundPoller(
          interval: interval,
          task: _onInterval,
          onResume: _onResume,
          onReconnect: _onResume,
          observeLifecycle: false,
          clock: clock,
          timerFactory: timerFactory,
        );
  }

  static const Duration interval = Duration(minutes: 30);

  /// A periodic tick right after another check is skipped.
  static const Duration tickGuard = Duration(minutes: 29);

  /// Foreground / reconnect checks are at most this often.
  static const Duration resumeGap = Duration(minutes: 1);

  static const String _key = 'catalog_check';

  final Future<CatalogSyncResult> Function() _check;
  final RequestManager _manager;
  late final ForegroundPoller _poller;

  /// Starts the periodic clock. Call once at app start, then [checkOnStart].
  void start() => _poller.start();

  void stop() => _poller.stop();

  /// The app's lifecycle events, forwarded by the one observer in AppProvider.
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _poller.didChangeAppLifecycleState(state);

  /// The check every cold start makes, regardless of earlier checks.
  Future<RequestOutcome<CatalogSyncResult>> checkOnStart() =>
      _manager.run(_key, _check, force: true);

  Future<void> _onInterval() async {
    await _manager.run(_key, _check, minInterval: tickGuard);
  }

  Future<void> _onResume() async {
    await _manager.run(_key, _check, minInterval: resumeGap);
  }
}
