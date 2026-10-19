import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Where the phone's own network status comes from. The platform implementation
/// asks Android/iOS (ConnectivityManager / NWPathMonitor); tests use a fake.
abstract interface class ConnectivityProbe {
  Future<List<ConnectivityResult>> check();
  Stream<List<ConnectivityResult>> get changes;
}

class _PlatformConnectivityProbe implements ConnectivityProbe {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<List<ConnectivityResult>> check() => _connectivity.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}

/// The phone's reported connectivity (Wi-Fi, mobile data, ethernet, VPN...).
///
/// This is what the operating system says, not proof that our server answers:
/// a Wi-Fi network without internet still reads as online. Its job is to stop
/// the app from spending requests (and timers) while the phone reports no
/// network at all, and to trigger one catch-up when a network comes back.
/// Request failures are handled separately by `RequestManager` backoff.
///
/// When the status cannot be read (no platform plugin, a read error) the phone
/// is assumed online, so a broken probe never blocks the app.
class ConnectivityService {
  ConnectivityService({ConnectivityProbe? probe})
    : _probe = probe ?? _PlatformConnectivityProbe();

  static ConnectivityService? _instance;
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService();
  @visibleForTesting
  static set testInstance(ConnectivityService? service) => _instance = service;

  final ConnectivityProbe _probe;
  final StreamController<bool> _changes = StreamController<bool>.broadcast(
    sync: true,
  );
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;
  bool _started = false;

  /// Last status reported by the phone.
  bool get isOnline => _online;

  /// Emits only when the status flips (offline -> online or the reverse).
  Stream<bool> get onChanged => _changes.stream;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  /// Reads the current status and starts following changes. Safe to repeat.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _online = _hasNetwork(await _probe.check());
    } catch (e) {
      debugPrint('[ConnectivityService] initial read failed: $e');
      _online = true;
    }
    try {
      _subscription = _probe.changes.listen(
        _apply,
        onError: (Object e) {
          debugPrint('[ConnectivityService] stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('[ConnectivityService] could not listen: $e');
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final online = _hasNetwork(results);
    if (online == _online) return;
    _online = online;
    if (!_changes.isClosed) _changes.add(online);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
