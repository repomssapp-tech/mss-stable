import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/library/library_api_service.dart';
import 'package:frontend/services/library/library_sync_service.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/request_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHost implements LibrarySyncHost {
  FakeHost({List<String>? bookmarks, List<String>? eligibility})
    : bookmarks = bookmarks ?? [],
      eligibilityIds = eligibility ?? [];

  @override
  List<String> bookmarks;
  @override
  List<String> eligibilityIds;
  DateTime? savedAt;

  @override
  Future<void> applyRemoteBookmarks(List<String> ids) async =>
      bookmarks = List.of(ids);

  @override
  Future<void> applyRemoteEligibility(List<String> ids, DateTime? at) async {
    eligibilityIds = List.of(ids);
    savedAt = at;
  }
}

class Call {
  Call(this.method, this.path, this.request);
  final String method;
  final String path;
  final http.Request request;

  @override
  String toString() => '$method $path';
}

http.Response _json(Object body, [int status = 200, Map<String, String>? h]) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json', ...?h},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late RequestManager requests;
  late TokenStorage tokens;
  late List<Call> calls;
  late String? owner;
  late Future<http.Response> Function(http.Request) server;
  late FakeHost host;

  // Server defaults: nothing saved, every write accepted.
  var serverFavorites = <String>[];
  var eligibilityVersion = 0;
  var eligibilityIds = <String>[];

  Future<http.Response> defaultServer(http.Request r) async {
    final path = r.url.path;
    if (r.method == 'GET' && path == '/v1/me/favorites') {
      return _json({
        'items': [
          for (final id in serverFavorites)
            {'scheme_id': id, 'saved_at': '2026-10-18T00:00:00.000Z'},
        ],
        'next_cursor': null,
      });
    }
    if (path.startsWith('/v1/me/favorites/')) {
      final id = path.split('/').last;
      if (r.method == 'PUT') {
        serverFavorites.add(id);
        return _json({'scheme_id': id, 'saved_at': '2026-10-18T00:00:00.000Z'});
      }
      serverFavorites.remove(id);
      return http.Response('', 204);
    }
    if (path == '/v1/me/eligibility-results') {
      if (r.method == 'GET') {
        return _json(
          {
            'scheme_ids': eligibilityIds,
            'saved_at': eligibilityVersion == 0
                ? null
                : '2026-10-18T00:00:00.000Z',
            'version': eligibilityVersion,
            'eligibility_verified': false,
          },
          200,
          {'etag': '"eligibility-$eligibilityVersion"'},
        );
      }
      eligibilityIds = List<String>.from(
        (jsonDecode(r.body) as Map)['scheme_ids'] as List,
      );
      eligibilityVersion++;
      return _json(
        {
          'scheme_ids': eligibilityIds,
          'saved_at': '2026-10-18T00:00:00.000Z',
          'version': eligibilityVersion,
          'eligibility_verified': false,
        },
        200,
        {'etag': '"eligibility-$eligibilityVersion"'},
      );
    }
    return _json({'error': 'NOT_FOUND'}, 404);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokens = TokenStorage(await SharedPreferences.getInstance());
    await tokens.saveTokens(accessToken: 'tok', refreshToken: 'ref');
    now = DateTime.utc(2026, 10, 18, 12);
    requests = RequestManager(clock: () => now);
    calls = [];
    owner = 'owner-1';
    serverFavorites = [];
    eligibilityVersion = 0;
    eligibilityIds = [];
    server = defaultServer;
    host = FakeHost();
  });

  LibrarySyncService service({String? Function()? ownerId}) {
    final api = LibraryApiService(
      client: ApiClient(
        baseUrl: 'https://api.msmeschemes.org',
        httpClient: MockClient((r) async {
          calls.add(Call(r.method, r.url.path, r));
          return server(r);
        }),
        tokenStorage: tokens,
      ),
    );
    return LibrarySyncService(
      host: host,
      api: api,
      requests: requests,
      writeDelay: const Duration(milliseconds: 20),
      ownerId: ownerId ?? () => owner,
    );
  }

  group('sending changes', () {
    test(
      'a save is PUT with no body and no content type, then dequeued',
      () async {
        final sync = service();

        await sync.recordFavorite('TN2026-001', saved: true);
        expect(sync.pendingChanges, 1);
        await sync.flush();

        expect(calls.map((c) => '$c'), ['PUT /v1/me/favorites/TN2026-001']);
        expect(calls.single.request.body, isEmpty);
        expect(
          calls.single.request.headers.containsKey('content-type'),
          isFalse,
        );
        expect(calls.single.request.headers['authorization'], 'Bearer tok');
        expect(sync.pendingChanges, 0);
      },
    );

    test('a burst is batched: the last state of each scheme wins', () async {
      final sync = service();

      await sync.recordFavorite('A', saved: true);
      await sync.recordFavorite('B', saved: true);
      await sync.recordFavorite('A', saved: false);
      expect(calls, isEmpty, reason: 'nothing is sent until the delay passes');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(calls.map((c) => '$c').toSet(), {
        'DELETE /v1/me/favorites/A',
        'PUT /v1/me/favorites/B',
      });
      expect(sync.pendingChanges, 0);
      sync.dispose();
    });

    test('ids the server cannot accept are never sent', () async {
      final sync = service();

      await sync.recordFavorite('bad id/with slash', saved: true);
      await sync.recordFavorite('', saved: true);
      await sync.flush();

      expect(calls, isEmpty);
      expect(sync.pendingChanges, 0);
    });

    test(
      '404 drops the change; 409 keeps it queued without blocking others',
      () async {
        server = (r) async {
          final id = r.url.path.split('/').last;
          if (id == 'HIDDEN') return _json({'error': 'SCHEME_NOT_FOUND'}, 404);
          if (id == 'NOSTATE')
            return _json({'error': 'PROFILE_STATE_REQUIRED'}, 409);
          return defaultServer(r);
        };
        final sync = service();
        await sync.recordFavorite('HIDDEN', saved: true);
        await sync.recordFavorite('NOSTATE', saved: true);
        await sync.recordFavorite('OK', saved: true);

        await sync.flush();

        expect(serverFavorites, ['OK']);
        expect(sync.pendingChanges, 1, reason: 'only NOSTATE stays queued');
      },
    );

    test('a server error keeps the queue and backs off', () async {
      var failing = true;
      server = (r) async =>
          failing ? _json({'error': 'INTERNAL_ERROR'}, 500) : defaultServer(r);
      final sync = service();
      await sync.recordFavorite('A', saved: true);
      await sync.recordFavorite('B', saved: true);

      await sync.flush();
      expect(sync.pendingChanges, 2);
      final afterFirst = calls.length;

      await sync.flush(); // within the backoff window: no request
      expect(calls.length, afterFirst);

      failing = false;
      now = now.add(const Duration(minutes: 2));
      await sync.flush();
      expect(sync.pendingChanges, 0);
      expect(serverFavorites.toSet(), {'A', 'B'});
    });

    test(
      'the queue survives a restart and is not inherited by another account',
      () async {
        final first = service();
        await first.recordFavorite('A', saved: true);
        first.dispose();

        final restarted = service();
        await restarted.flush();
        expect(serverFavorites, ['A']);

        final other = FakeHost();
        final firstAgain = service();
        await firstAgain.recordFavorite('B', saved: true);
        firstAgain.dispose();
        owner = 'owner-2';
        final switched = LibrarySyncService(
          host: other,
          api: LibraryApiService(
            client: ApiClient(
              baseUrl: 'https://api.msmeschemes.org',
              httpClient: MockClient((r) async {
                calls.add(Call(r.method, r.url.path, r));
                return server(r);
              }),
              tokenStorage: tokens,
            ),
          ),
          requests: requests,
          ownerId: () => owner,
        );
        calls.clear();
        await switched.flush();

        expect(calls, isEmpty, reason: 'owner-1 queue is not sent as owner-2');
      },
    );

    test('nothing is recorded or sent while signed out', () async {
      owner = null;
      final sync = service();

      await sync.recordFavorite('A', saved: true);
      await sync.recordEligibility(['A']);
      await sync.flush();

      expect(calls, isEmpty);
      expect(sync.pendingChanges, 0);
    });
  });

  group('pulling the server copy', () {
    test(
      'the first sync keeps both sides and uploads local-only schemes',
      () async {
        serverFavorites = ['SERVER-ONLY', 'BOTH'];
        host = FakeHost(bookmarks: ['LOCAL-ONLY', 'BOTH']);
        final sync = service();

        await sync.pull();

        expect(host.bookmarks.toSet(), {'LOCAL-ONLY', 'BOTH', 'SERVER-ONLY'});
        expect(serverFavorites.toSet(), {'LOCAL-ONLY', 'BOTH', 'SERVER-ONLY'});
        expect(sync.pendingChanges, 0);
      },
    );

    test(
      'later syncs follow the server, with this device\'s unsent changes on top',
      () async {
        serverFavorites = ['A'];
        host = FakeHost(bookmarks: ['A']);
        final sync = service();
        await sync.pull(); // first sync

        // Another device saved B and removed A.
        serverFavorites = ['B'];
        now = now.add(const Duration(minutes: 20));
        await sync.pull();

        expect(host.bookmarks, ['B']);
      },
    );

    test('a fresh pull is not repeated; force pulls again', () async {
      final sync = service();
      await sync.pull();
      final count = calls.length;

      await sync.pull();
      expect(calls.length, count);

      await sync.pull(force: true);
      expect(calls.length, greaterThan(count));
    });

    test('server eligibility results replace the local set', () async {
      eligibilityVersion = 3;
      eligibilityIds = ['TN2026-001'];
      host = FakeHost(eligibility: ['OLD']);
      final sync = service();

      await sync.pull();

      expect(host.eligibilityIds, ['TN2026-001']);
      expect(host.savedAt, isNotNull);
    });

    test(
      'a first sync uploads local eligibility results when the server has none',
      () async {
        host = FakeHost(eligibility: ['TN2026-001']);
        final sync = service();

        await sync.pull();

        expect(eligibilityIds, ['TN2026-001']);
        expect(eligibilityVersion, 1);
      },
    );
  });

  group('eligibility results', () {
    test(
      'a save reads the ETag then PUTs with X-Eligibility-If-Match',
      () async {
        eligibilityVersion = 4;
        eligibilityIds = ['OLD'];
        final sync = service();

        await sync.recordEligibility(['A', 'B']);
        await sync.flush();

        final put = calls.firstWhere((c) => c.method == 'PUT');
        expect(
          put.request.headers['X-Eligibility-If-Match'] ??
              put.request.headers['x-eligibility-if-match'],
          '"eligibility-4"',
        );
        expect(jsonDecode(put.request.body), {
          'scheme_ids': ['A', 'B'],
        });
        expect(eligibilityIds, ['A', 'B']);
      },
    );

    test('a clear sends an empty list', () async {
      eligibilityVersion = 1;
      eligibilityIds = ['A'];
      final sync = service();

      await sync.recordEligibility([]);
      await sync.flush();

      expect(eligibilityIds, isEmpty);
    });

    test('a version conflict reloads the ETag once and writes again', () async {
      eligibilityVersion = 2;
      var conflicts = 0;
      server = (r) async {
        if (r.method == 'PUT' &&
            r.url.path == '/v1/me/eligibility-results' &&
            conflicts == 0) {
          conflicts++;
          eligibilityVersion = 3; // another device wrote first
          return _json({'error': 'ELIGIBILITY_VERSION_CONFLICT'}, 412);
        }
        return defaultServer(r);
      };
      final sync = service();

      await sync.recordEligibility(['A']);
      await sync.flush();

      expect(conflicts, 1);
      expect(eligibilityIds, ['A']);
      expect(sync.pendingChanges, 0);
    });

    test(
      'ids not visible to the account are dropped, not retried forever',
      () async {
        server = (r) async =>
            r.method == 'PUT' && r.url.path.endsWith('eligibility-results')
            ? _json({'error': 'SCHEME_NOT_FOUND'}, 404)
            : defaultServer(r);
        final sync = service();

        await sync.recordEligibility(['OTHER-STATE']);
        await sync.flush();

        expect(sync.pendingChanges, 0);
      },
    );
  });

  test('reset forgets the queue and the account', () async {
    final sync = service();
    await sync.recordFavorite('A', saved: true);

    await sync.reset();

    expect(sync.pendingChanges, 0);
    calls.clear();
    await sync.flush();
    expect(calls, isEmpty);
  });
}
