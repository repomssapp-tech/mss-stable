import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/catalog_refresh_scheduler.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:frontend/services/network/connectivity_service.dart';
import 'package:frontend/services/network/debouncer.dart';
import 'package:frontend/services/network/foreground_poller.dart';
import 'package:frontend/services/network/request_manager.dart';

class FakeProbe implements ConnectivityProbe {
  FakeProbe(this.initial);

  List<ConnectivityResult> initial;
  Object? checkError;
  final StreamController<List<ConnectivityResult>> controller =
      StreamController<List<ConnectivityResult>>.broadcast(sync: true);

  @override
  Future<List<ConnectivityResult>> check() async {
    if (checkError != null) throw checkError!;
    return initial;
  }

  @override
  Stream<List<ConnectivityResult>> get changes => controller.stream;
}

Future<ConnectivityService> _network({bool online = true}) async {
  final service = ConnectivityService(
    probe: FakeProbe([
      online ? ConnectivityResult.wifi : ConnectivityResult.none,
    ]),
  );
  await service.start();
  return service;
}

class FakeTimers {
  final List<Duration> scheduled = [];
  void Function()? lastCallback;

  Timer create(Duration after, void Function() fire) {
    scheduled.add(after);
    lastCallback = fire;
    return _FakeTimer(() => lastCallback = null);
  }

  void fireLast() {
    final cb = lastCallback;
    lastCallback = null;
    cb?.call();
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this._onCancel);
  final void Function() _onCancel;
  bool _active = true;

  @override
  void cancel() {
    _active = false;
    _onCancel();
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService (what the phone reports)', () {
    test('reads the initial status from the phone', () async {
      expect((await _network()).isOnline, isTrue);
      expect((await _network(online: false)).isOnline, isFalse);
    });

    test('any real network counts: wifi, mobile, ethernet, vpn', () async {
      for (final kind in [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
      ]) {
        final service = ConnectivityService(probe: FakeProbe([kind]));
        await service.start();
        expect(service.isOnline, isTrue, reason: '$kind');
      }
    });

    test('emits only when the status flips', () async {
      final probe = FakeProbe([ConnectivityResult.wifi]);
      final service = ConnectivityService(probe: probe);
      await service.start();
      final seen = <bool>[];
      service.onChanged.listen(seen.add);

      probe.controller.add([ConnectivityResult.mobile]); // still online
      probe.controller.add([ConnectivityResult.none]);
      probe.controller.add([ConnectivityResult.none]); // no change
      probe.controller.add([ConnectivityResult.wifi, ConnectivityResult.vpn]);

      expect(seen, [false, true]);
      expect(service.isOnline, isTrue);
    });

    test('an unreadable status is treated as online', () async {
      final probe = FakeProbe([ConnectivityResult.none])
        ..checkError = StateError('no plugin');
      final service = ConnectivityService(probe: probe);

      await service.start();

      expect(service.isOnline, isTrue);
    });
  });

  group('RequestManager', () {
    late DateTime now;
    late RequestManager manager;

    setUp(() async {
      now = DateTime.utc(2026, 10, 18, 12);
      manager = RequestManager(
        connectivity: await _network(),
        clock: () => now,
      );
    });

    test('concurrent callers share one request', () async {
      var calls = 0;
      final gate = Completer<int>();
      Future<int> fetch() {
        calls++;
        return gate.future;
      }

      final a = manager.run('k', fetch);
      final b = manager.run('k', fetch);
      gate.complete(7);

      expect((await a).value, 7);
      expect((await b).value, 7);
      expect(calls, 1);
    });

    test('a fresh result is reused instead of asking again', () async {
      var calls = 0;
      Future<int> fetch() async => ++calls;
      const window = Duration(minutes: 2);

      expect((await manager.run('k', fetch, minInterval: window)).ran, isTrue);
      now = now.add(const Duration(seconds: 119));
      final second = await manager.run('k', fetch, minInterval: window);
      expect(second.status, RequestStatus.throttled);
      expect(calls, 1);

      now = now.add(const Duration(seconds: 2));
      expect((await manager.run('k', fetch, minInterval: window)).ran, isTrue);
      expect(calls, 2);
    });

    test('force skips the freshness window', () async {
      var calls = 0;
      Future<int> fetch() async => ++calls;
      await manager.run('k', fetch, minInterval: const Duration(hours: 1));

      final forced = await manager.run(
        'k',
        fetch,
        minInterval: const Duration(hours: 1),
        force: true,
      );

      expect(forced.ran, isTrue);
      expect(calls, 2);
    });

    test('nothing is sent while the phone has no network', () async {
      final probe = FakeProbe([ConnectivityResult.wifi]);
      final network = ConnectivityService(probe: probe);
      await network.start();
      final offlineManager = RequestManager(
        connectivity: network,
        clock: () => now,
      );
      var calls = 0;
      Future<int> fetch() async => ++calls;

      probe.controller.add([ConnectivityResult.none]);
      final blocked = await offlineManager.run('k', fetch, force: true);
      expect(blocked.status, RequestStatus.offline);
      expect(calls, 0);

      probe.controller.add([ConnectivityResult.wifi]);
      expect((await offlineManager.run('k', fetch)).ran, isTrue);
    });

    test('failures back off 30s, 60s, 120s... and success resets it', () async {
      var failing = true;
      var calls = 0;
      Future<int> fetch() async {
        calls++;
        if (failing) {
          throw const ApiException(
            statusCode: 500,
            errorCode: 'X',
            message: 'boom',
          );
        }
        return 1;
      }

      expect((await manager.run('k', fetch)).status, RequestStatus.failed);
      expect((await manager.run('k', fetch)).status, RequestStatus.backingOff);
      expect(calls, 1);

      now = now.add(const Duration(seconds: 31));
      expect((await manager.run('k', fetch)).status, RequestStatus.failed);
      now = now.add(const Duration(seconds: 31));
      expect(
        (await manager.run('k', fetch)).status,
        RequestStatus.backingOff,
        reason: 'second failure waits 60s',
      );
      now = now.add(const Duration(seconds: 30));
      failing = false;
      expect((await manager.run('k', fetch)).ran, isTrue);

      // After a success the next failure starts from 30s again.
      failing = true;
      now = now.add(const Duration(seconds: 1));
      await manager.run('k', fetch, force: true);
      now = now.add(const Duration(seconds: 31));
      expect((await manager.run('k', fetch)).status, RequestStatus.failed);
    });

    test('backoff is capped', () async {
      final capped = RequestManager(
        connectivity: await _network(),
        clock: () => now,
        maxBackoff: const Duration(minutes: 1),
      );
      Future<int> fail() async => throw const ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
        message: 'x',
      );

      for (var i = 0; i < 6; i++) {
        await capped.run('k', fail, force: true);
      }
      now = now.add(const Duration(seconds: 61));
      expect((await capped.run('k', fail)).status, RequestStatus.failed);
    });

    test('a server Retry-After is honoured even when forced', () async {
      var calls = 0;
      Future<int> fetch() async {
        calls++;
        throw const ApiException(
          statusCode: 429,
          errorCode: 'RATE_LIMITED',
          message: 'slow down',
          retryAfterSeconds: 90,
        );
      }

      await manager.run('k', fetch);
      expect(
        (await manager.run('k', fetch, force: true)).status,
        RequestStatus.backingOff,
      );
      expect(calls, 1);

      now = now.add(const Duration(seconds: 91));
      expect(
        (await manager.run('k', fetch, force: true)).status,
        RequestStatus.failed,
      );
      expect(calls, 2);
    });

    test(
      'keys are independent; invalidate and reset clear freshness',
      () async {
        var a = 0;
        var b = 0;
        await manager.run(
          'a',
          () async => ++a,
          minInterval: const Duration(hours: 1),
        );
        await manager.run(
          'b',
          () async => ++b,
          minInterval: const Duration(hours: 1),
        );

        expect(
          (await manager.run(
            'a',
            () async => ++a,
            minInterval: const Duration(hours: 1),
          )).status,
          RequestStatus.throttled,
        );
        manager.invalidate('a');
        expect(
          (await manager.run(
            'a',
            () async => ++a,
            minInterval: const Duration(hours: 1),
          )).ran,
          isTrue,
        );

        manager.reset();
        expect(manager.lastSuccessAt('b'), isNull);
        expect(
          (await manager.run(
            'b',
            () async => ++b,
            minInterval: const Duration(hours: 1),
          )).ran,
          isTrue,
        );
      },
    );
  });

  group('Debouncer', () {
    test('a burst of calls runs only the last one', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 40));
      final ran = <int>[];

      debouncer.run(() => ran.add(1));
      debouncer.run(() => ran.add(2));
      debouncer.run(() => ran.add(3));
      expect(debouncer.isPending, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(ran, [3]);
      expect(debouncer.isPending, isFalse);
    });

    test('flush runs the waiting action now, cancel drops it', () async {
      final debouncer = Debouncer(const Duration(seconds: 10));
      final ran = <String>[];

      debouncer.run(() => ran.add('a'));
      await debouncer.flush();
      expect(ran, ['a']);

      debouncer.run(() => ran.add('b'));
      debouncer.cancel();
      await debouncer.flush();
      expect(ran, ['a']);
    });
  });

  group('ForegroundPoller (active-use timer)', () {
    late DateTime now;
    late FakeTimers timers;
    late int runs;
    late int resumes;
    late int reconnects;

    ForegroundPoller build(ConnectivityService network) => ForegroundPoller(
      interval: const Duration(minutes: 30),
      task: () => runs++,
      onResume: () => resumes++,
      onReconnect: () => reconnects++,
      connectivity: network,
      clock: () => now,
      timerFactory: timers.create,
      observeLifecycle: false,
    );

    setUp(() {
      now = DateTime.utc(2026, 10, 18, 12);
      timers = FakeTimers();
      runs = 0;
      resumes = 0;
      reconnects = 0;
    });

    test(
      'schedules the full interval, runs the task, then reschedules',
      () async {
        final poller = build(await _network())..start();

        expect(timers.scheduled, [const Duration(minutes: 30)]);
        timers.fireLast();
        await Future<void>.delayed(Duration.zero);

        expect(runs, 1);
        expect(timers.scheduled, [
          const Duration(minutes: 30),
          const Duration(minutes: 30),
        ]);
        poller.stop();
      },
    );

    test('only active time counts: background pauses the clock', () async {
      final poller = build(await _network())..start();

      now = now.add(const Duration(minutes: 10));
      poller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(
        timers.lastCallback,
        isNull,
        reason: 'timer cancelled in background',
      );

      now = now.add(const Duration(hours: 3)); // time in the background
      poller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(timers.scheduled.last, const Duration(minutes: 20));
      expect(resumes, 1);
      expect(runs, 0, reason: 'no catch-up flood after a long background');
      poller.stop();
    });

    test('a brief inactive state (dialogs) does not pause the clock', () async {
      final poller = build(await _network())..start();

      poller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      poller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(resumes, 0);
      expect(timers.scheduled, [const Duration(minutes: 30)]);
      poller.stop();
    });

    test('the task is skipped while the phone has no network', () async {
      final poller = build(await _network(online: false))..start();

      timers.fireLast();
      await Future<void>.delayed(Duration.zero);

      expect(runs, 0);
      expect(timers.scheduled.length, 2, reason: 'still rescheduled');
      poller.stop();
    });

    test(
      'regaining a network runs onReconnect once, only in the foreground',
      () async {
        final probe = FakeProbe([ConnectivityResult.none]);
        final network = ConnectivityService(probe: probe);
        await network.start();
        final poller = build(network)..start();

        probe.controller.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);
        expect(reconnects, 1);

        probe.controller.add([ConnectivityResult.none]);
        poller.didChangeAppLifecycleState(AppLifecycleState.paused);
        probe.controller.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);
        expect(reconnects, 1, reason: 'not while in the background');
        poller.stop();
      },
    );

    test('stop cancels everything', () async {
      final poller = build(await _network())..start();

      poller.stop();

      expect(poller.isRunning, isFalse);
      expect(timers.lastCallback, isNull);
    });
  });

  group('CatalogRefreshScheduler (30 min of active use + every start)', () {
    late DateTime now;
    late FakeTimers timers;
    late int checks;
    late CatalogRefreshScheduler scheduler;

    setUp(() async {
      now = DateTime.utc(2026, 10, 18, 12);
      timers = FakeTimers();
      checks = 0;
      scheduler = CatalogRefreshScheduler(
        check: () async {
          checks++;
          return const CatalogSyncResult(CatalogSyncOutcome.unchanged);
        },
        manager: RequestManager(
          connectivity: await _network(),
          clock: () => now,
        ),
        clock: () => now,
        timerFactory: timers.create,
      );
    });

    test('every start checks, even right after a previous check', () async {
      await scheduler.checkOnStart();
      await scheduler.checkOnStart();

      expect(checks, 2);
    });

    test('the periodic tick fires every 30 minutes of active use', () async {
      scheduler.start();
      expect(timers.scheduled, [const Duration(minutes: 30)]);

      now = now.add(const Duration(minutes: 30));
      timers.fireLast();
      await Future<void>.delayed(Duration.zero);

      expect(checks, 1);
      scheduler.stop();
    });

    test('a tick right after a start check is not repeated', () async {
      scheduler.start();
      await scheduler.checkOnStart();

      now = now.add(const Duration(minutes: 28));
      timers.fireLast();
      await Future<void>.delayed(Duration.zero);

      expect(checks, 1);
      scheduler.stop();
    });

    test('returning to the app checks at most once a minute', () async {
      scheduler.start();
      await scheduler.checkOnStart();
      expect(checks, 1);

      scheduler.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 20));
      scheduler.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(checks, 1, reason: 'quick app switch costs nothing');

      scheduler.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      scheduler.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(checks, 2);
      scheduler.stop();
    });
  });
}
