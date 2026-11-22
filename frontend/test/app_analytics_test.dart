import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/analytics/app_analytics.dart';
import 'package:frontend/services/network/connectivity_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bufferKey = 'mss_analytics_buffer_v1';

Map<String, dynamic> snapshot(SharedPreferences buffer) =>
    jsonDecode(buffer.getString(_bufferKey)!) as Map<String, dynamic>;

class _Probe implements ConnectivityProbe {
  _Probe(this.online);

  final bool online;

  @override
  Future<List<ConnectivityResult>> check() async => [
    online ? ConnectivityResult.wifi : ConnectivityResult.none,
  ];

  @override
  Stream<List<ConnectivityResult>> get changes => const Stream.empty();
}

Map<String, String> context() => {
  'user_kind': 'guest',
  'language': 'en',
  'mode': 'regular',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> connect(bool online) async {
    await ConnectivityService.instance.dispose();
    final service = ConnectivityService(probe: _Probe(online));
    ConnectivityService.testInstance = service;
    await service.start();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() async {
    await ConnectivityService.instance.dispose();
    ConnectivityService.testInstance = null;
  });

  test('default analytics buffers and uploads guest activity', () async {
    await connect(true);
    final packets = <Map<String, dynamic>>[];
    final service = AppAnalytics(
      endpoint: Uri.parse('https://example.test/v1/analytics/events'),
      client: MockClient((request) async {
        final packet = jsonDecode(request.body) as Map<String, dynamic>;
        packets.add(packet);
        return http.Response(
          jsonEncode({'accepted': (packet['events'] as List).length}),
          200,
        );
      }),
    );
    service.start(context);
    service.track(
      AnalyticsEvent.featureOpened,
      properties: {'feature': 'discover'},
    );
    await service.flush();
    await service.close();

    expect(packets, isNotEmpty);
    expect(packets.first['notice_version'], 'analytics-v1');
    expect(
      packets.expand((packet) => packet['events'] as List),
      contains(containsPair('name', 'feature_opened')),
    );
  });

  test(
    'offline events survive restart and upload together with stable IDs',
    () async {
      await connect(false);
      final buffer = await SharedPreferences.getInstance();
      final offline = AppAnalytics(noticeVersion: 'test-v1');
      offline.start(context);
      final search = offline.interactionId();
      offline.track(
        AnalyticsEvent.searchSubmitted,
        interactionId: search,
        properties: {'source': 'typed', 'result_count': 1},
      );
      offline.track(
        AnalyticsEvent.schemeOpened,
        interactionId: search,
        properties: {'scheme_id': 'CEN-1', 'entry_point': 'search'},
      );
      offline.track(
        AnalyticsEvent.searchSubmitted,
        properties: {'source': 'typed', 'result_count': 0, 'query': 'private'},
      );
      await offline.close();
      final buffered = snapshot(buffer);

      await connect(true);
      final requests = <http.Request>[];
      final online = AppAnalytics(
        noticeVersion: 'test-v1',
        endpoint: Uri.parse('https://example.test/v1/analytics/events'),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{"accepted":2,"duplicates":1}', 200);
        }),
      );
      online.start(context);
      await online.flush();
      await online.close();

      expect(requests, hasLength(1));
      expect(requests.single.headers.containsKey('authorization'), isFalse);
      expect(jsonDecode(requests.single.body), {
        'schema_version': 1,
        ...buffered,
      });
      final events = buffered['events'] as List;
      expect(events.map((e) => e['name']), [
        'session_start',
        'search_submitted',
        'scheme_opened',
      ]);
      expect(events.skip(1).map((e) => e['interaction_id']), [search, search]);
      expect(snapshot(buffer)['events'], isEmpty);
    },
  );

  test(
    'rate limiting retains the packet and suppresses immediate retries',
    () async {
      await connect(false);
      final buffer = await SharedPreferences.getInstance();
      final offline = AppAnalytics(noticeVersion: 'test-v1');
      offline.start(context);
      offline.track(
        AnalyticsEvent.featureOpened,
        properties: {'feature': 'home'},
      );
      await offline.close();
      final buffered = snapshot(buffer);

      await connect(true);
      var requests = 0;
      final online = AppAnalytics(
        noticeVersion: 'test-v1',
        endpoint: Uri.parse('https://example.test/v1/analytics/events'),
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 429, headers: {'retry-after': '600'});
        }),
      );
      online.start(context);
      await online.flush();
      await online.flush();
      await online.close();

      expect(requests, 1);
      expect(snapshot(buffer), buffered);
    },
  );

  test('a disabled build creates no queued events or HTTP calls', () async {
    final buffer = await SharedPreferences.getInstance();
    final service = AppAnalytics(
      noticeVersion: '',
      client: MockClient((_) async => throw StateError('Unexpected upload')),
    );
    service.start(context);
    service.track(
      AnalyticsEvent.featureOpened,
      properties: {'feature': 'home'},
    );
    await service.flush();
    await service.close();

    expect(service.interactionId(), isNull);
    expect(buffer.getString(_bufferKey), isNull);
  });
}
