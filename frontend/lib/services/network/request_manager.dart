import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_exception.dart';
import 'connectivity_service.dart';

/// What happened to a request handed to [RequestManager.run].
enum RequestStatus {
  /// The request was sent and succeeded.
  ran,

  /// Skipped: a successful run for the same key is still fresh.
  throttled,

  /// Skipped: the phone reports no network.
  offline,

  /// Skipped: a recent failure (or the server's Retry-After) says wait.
  backingOff,

  /// The request was sent and failed; see [RequestOutcome.error].
  failed,
}

class RequestOutcome<T> {
  const RequestOutcome(this.status, {this.value, this.error});

  final RequestStatus status;
  final T? value;
  final Object? error;

  bool get ran => status == RequestStatus.ran;
}

class _Entry {
  Future<RequestOutcome<Object?>>? inFlight;
  DateTime? lastSuccess;
  DateTime? backoffUntil;
  DateTime? retryAfterUntil;
  int failures = 0;
}

/// One place that decides whether a live request to the server may go out.
///
/// Every key (for example `notifications` or `promotions`) gets:
///
/// * **single flight**: concurrent callers share one request;
/// * **freshness window** (`minInterval`): a recent success is reused instead
///   of asking again, so opening a screen does not refetch;
/// * **offline gate**: nothing is sent while the phone reports no network;
/// * **backoff**: after a failure the next attempt waits 30 s, 60 s, 120 s ...
///   up to 15 min, and a server `Retry-After` is always honoured, even for a
///   forced call.
///
/// `force` skips the freshness window and the plain backoff (an explicit user
/// action), never the offline gate or `Retry-After`.
class RequestManager {
  RequestManager({
    ConnectivityService? connectivity,
    DateTime Function()? clock,
    this.baseBackoff = const Duration(seconds: 30),
    this.maxBackoff = const Duration(minutes: 15),
  }) : _connectivity = connectivity,
       _clock = clock ?? DateTime.now;

  static RequestManager? _instance;
  static RequestManager get instance => _instance ??= RequestManager();
  @visibleForTesting
  static set testInstance(RequestManager? manager) => _instance = manager;

  final ConnectivityService? _connectivity;
  final DateTime Function() _clock;
  final Duration baseBackoff;
  final Duration maxBackoff;
  final Map<String, _Entry> _entries = {};

  ConnectivityService get _network =>
      _connectivity ?? ConnectivityService.instance;

  /// When [key] last succeeded, or null.
  DateTime? lastSuccessAt(String key) => _entries[key]?.lastSuccess;

  Future<RequestOutcome<T>> run<T>(
    String key,
    Future<T> Function() fetch, {
    Duration minInterval = Duration.zero,
    bool force = false,
    bool requiresOnline = true,
  }) async {
    final entry = _entries.putIfAbsent(key, _Entry.new);

    final running = entry.inFlight;
    if (running != null) {
      final shared = await running;
      return RequestOutcome<T>(
        shared.status,
        value: shared.value is T ? shared.value as T : null,
        error: shared.error,
      );
    }

    final now = _clock();
    if (requiresOnline && !_network.isOnline) {
      return RequestOutcome<T>(RequestStatus.offline);
    }
    final retryAfter = entry.retryAfterUntil;
    if (retryAfter != null && now.isBefore(retryAfter)) {
      return RequestOutcome<T>(RequestStatus.backingOff);
    }
    if (!force) {
      final backoff = entry.backoffUntil;
      if (backoff != null && now.isBefore(backoff)) {
        return RequestOutcome<T>(RequestStatus.backingOff);
      }
      final last = entry.lastSuccess;
      if (last != null && now.difference(last) < minInterval) {
        return RequestOutcome<T>(RequestStatus.throttled);
      }
    }

    final run = _execute<T>(entry, fetch);
    entry.inFlight = run.then((outcome) => outcome);
    try {
      return await run;
    } finally {
      entry.inFlight = null;
    }
  }

  Future<RequestOutcome<T>> _execute<T>(
    _Entry entry,
    Future<T> Function() fetch,
  ) async {
    try {
      final value = await fetch();
      entry
        ..lastSuccess = _clock()
        ..failures = 0
        ..backoffUntil = null
        ..retryAfterUntil = null;
      return RequestOutcome<T>(RequestStatus.ran, value: value);
    } catch (error) {
      entry.failures++;
      final now = _clock();
      final retryAfter = error is ApiException ? error.retryAfterSeconds : null;
      if (retryAfter != null && retryAfter > 0) {
        entry.retryAfterUntil = now.add(Duration(seconds: retryAfter));
      } else {
        final factor = 1 << (entry.failures - 1).clamp(0, 10);
        final delay = baseBackoff * factor;
        entry.backoffUntil = now.add(delay > maxBackoff ? maxBackoff : delay);
      }
      return RequestOutcome<T>(RequestStatus.failed, error: error);
    }
  }

  /// Makes the next [run] for [key] proceed (data known to be stale, e.g. after
  /// a language change). Does not clear a server `Retry-After`.
  void invalidate(String key) {
    _entries[key]
      ?..lastSuccess = null
      ..backoffUntil = null;
  }

  /// Forgets everything (sign-out or account switch).
  void reset() => _entries.clear();
}
