import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/updates/app_release.dart';
import 'package:frontend/services/updates/app_update_service.dart';
import 'package:frontend/utils/app_version.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _installed = AppVersion(1, 4, 8, 16);

Map<String, Object?> _release(
  String tag, {
  bool draft = false,
  bool prerelease = false,
  List<String> apks = const [],
}) => {
  'tag_name': tag,
  'html_url': 'https://github.com/Roger-Chris/MSS_App/releases/tag/$tag',
  'draft': draft,
  'prerelease': prerelease,
  'assets': [
    for (final name in apks)
      {
        'name': name,
        'browser_download_url':
            'https://github.com/Roger-Chris/MSS_App/releases/download/$tag/$name',
      },
  ],
};

void main() {
  group('AppRelease.versionFromTag', () {
    test('reads app-vX.Y.Z+N tags', () {
      expect(
        AppRelease.versionFromTag('app-v1.4.8+16'),
        const AppVersion(1, 4, 8, 16),
      );
      expect(
        AppRelease.versionFromTag(' app-v2.0.0+120 '),
        const AppVersion(2, 0, 0, 120),
      );
    });

    test('ignores catalog and other tag shapes', () {
      for (final tag in [
        'catalog-1.37.1-alpha',
        'app-v1.4.8',
        'v1.4.8+16',
        'app-1.4.8+16',
        'app-v1.4+16',
        'app-v1.4.8+16-beta',
        '',
      ]) {
        expect(AppRelease.versionFromTag(tag), isNull, reason: tag);
      }
    });
  });

  group('AppRelease.fromJson', () {
    test('keeps the page and prefers the universal APK', () {
      final r = AppRelease.fromJson(
        _release(
          'app-v1.4.9+17',
          apks: ['MSS-1.4.9+17-arm64.apk', 'MSS-1.4.9+17.apk'],
        ),
      )!;
      expect(r.version.build, 17);
      expect(r.pageUrl.host, 'github.com');
      expect(r.apkUrl!.path, endsWith('/MSS-1.4.9+17.apk'));
      expect(r.updateUrl, r.apkUrl);
    });

    test('falls back to a split APK, then to the release page', () {
      final split = AppRelease.fromJson(
        _release('app-v1.4.9+17', apks: ['MSS-1.4.9+17-arm64.apk']),
      )!;
      expect(split.apkUrl!.path, endsWith('-arm64.apk'));

      final none = AppRelease.fromJson(_release('app-v1.4.9+17'))!;
      expect(none.apkUrl, isNull);
      expect(none.updateUrl, none.pageUrl);
    });

    test('rejects drafts, pre-releases, catalog tags and bad shapes', () {
      expect(
        AppRelease.fromJson(_release('app-v1.4.9+17', draft: true)),
        isNull,
      );
      expect(
        AppRelease.fromJson(_release('app-v1.4.9+17', prerelease: true)),
        isNull,
      );
      expect(AppRelease.fromJson(_release('catalog-1.38.0')), isNull);
      expect(AppRelease.fromJson('app-v1.4.9+17'), isNull);
      expect(AppRelease.fromJson({'tag_name': 'app-v1.4.9+17'}), isNull);
      expect(AppRelease.fromJson({'tag_name': 17, 'html_url': 3}), isNull);
    });

    test('only opens https links on github.com', () {
      final json = _release('app-v1.4.9+17')
        ..['html_url'] = 'https://evil.example/releases/latest';
      expect(AppRelease.fromJson(json), isNull);

      final apk = _release('app-v1.4.9+17')
        ..['assets'] = [
          {
            'name': 'MSS.apk',
            'browser_download_url': 'http://github.com/MSS.apk',
          },
        ];
      expect(AppRelease.fromJson(apk)!.apkUrl, isNull);
    });
  });

  group('AppRelease.newestOf', () {
    test('picks the highest app build and skips catalog releases', () {
      final newest = AppRelease.newestOf([
        _release('catalog-1.40.0'),
        _release('app-v1.4.8+16'),
        _release('app-v1.5.0+18', prerelease: true),
        _release('app-v1.4.9+17'),
      ]);
      expect(newest!.version, const AppVersion(1, 4, 9, 17));
    });

    test('is null for an empty, catalog-only or non-list reply', () {
      expect(AppRelease.newestOf([]), isNull);
      expect(AppRelease.newestOf([_release('catalog-1.40.0')]), isNull);
      expect(AppRelease.newestOf({'message': 'Not Found'}), isNull);
      expect(AppRelease.newestOf(null), isNull);
    });
  });

  group('AppUpdateService.shouldNotify', () {
    AppRelease build(int n) => AppRelease(
      version: AppVersion(1, 4, 8, n),
      pageUrl: AppUpdateService.latestReleasePage,
    );

    test('compares build numbers only', () {
      expect(
        AppUpdateService.shouldNotify(
          release: build(17),
          installed: _installed,
        ),
        isTrue,
      );
      expect(
        AppUpdateService.shouldNotify(
          release: build(16),
          installed: _installed,
        ),
        isFalse,
      );
      expect(
        AppUpdateService.shouldNotify(
          release: build(15),
          installed: _installed,
        ),
        isFalse,
      );
      // A lower version name with a higher build is still the newer install.
      expect(
        AppUpdateService.shouldNotify(
          release: AppRelease(
            version: const AppVersion(1, 4, 0, 17),
            pageUrl: AppUpdateService.latestReleasePage,
          ),
          installed: _installed,
        ),
        isTrue,
      );
    });

    test('a dismissed build stays hidden until a newer one appears', () {
      expect(
        AppUpdateService.shouldNotify(
          release: build(17),
          installed: _installed,
          dismissedBuild: 17,
        ),
        isFalse,
      );
      expect(
        AppUpdateService.shouldNotify(
          release: build(18),
          installed: _installed,
          dismissedBuild: 17,
        ),
        isTrue,
      );
    });
  });

  group('AppUpdateService.isDue', () {
    final now = DateTime(2026, 10, 23, 12);
    int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;

    test('throttles checks to one per resumeGap', () {
      expect(AppUpdateService.isDue(null, now), isTrue);
      expect(
        AppUpdateService.isDue(ago(const Duration(minutes: 5)), now),
        isFalse,
      );
      expect(
        AppUpdateService.isDue(
          ago(AppUpdateService.resumeGap - const Duration(minutes: 1)),
          now,
        ),
        isFalse,
      );
      expect(
        AppUpdateService.isDue(ago(AppUpdateService.resumeGap), now),
        isTrue,
      );
    });

    test('a last check in the future (clock moved back) is due', () {
      expect(
        AppUpdateService.isDue(
          now.add(const Duration(days: 1)).millisecondsSinceEpoch,
          now,
        ),
        isTrue,
      );
    });
  });

  group('AppUpdateService.check', () {
    late int requests;
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      requests = 0;
      now = DateTime(2026, 10, 23, 12);
    });

    AppUpdateService service(
      FutureOr<http.Response> Function(http.Request) reply, {
      AppVersion? installed = _installed,
      Duration timeout = AppUpdateService.requestTimeout,
    }) => AppUpdateService(
      client: MockClient((request) async {
        requests++;
        expect(request.url, AppUpdateService.releasesApi);
        expect(request.headers.containsKey('Authorization'), isFalse);
        return reply(request);
      }),
      installedVersion: () async => installed,
      clock: () => now,
      timeout: timeout,
    );

    http.Response ok(List<Object?> releases) =>
        http.Response(jsonEncode(releases), 200);

    test('returns a newer build', () async {
      final s = service(
        (_) => ok([
          _release('app-v1.4.9+17', apks: ['MSS-1.4.9+17.apk']),
        ]),
      );
      final r = await s.check(onStart: true);
      expect(r!.version.build, 17);
      expect(r.updateUrl.path, endsWith('/MSS-1.4.9+17.apk'));
    });

    test('says nothing when the installed build is current', () async {
      final s = service((_) => ok([_release('app-v1.4.8+16')]));
      expect(await s.check(onStart: true), isNull);
    });

    test('fails silently on rate limits, errors and bad replies', () async {
      for (final reply in <http.Response>[
        http.Response('{"message":"API rate limit exceeded"}', 403),
        http.Response('', 429),
        http.Response('{"message":"Not Found"}', 404),
        http.Response('', 500),
        http.Response('not json', 200),
        http.Response('{"tag_name":"app-v9.9.9+99"}', 200),
      ]) {
        final s = service((_) => reply);
        expect(await s.check(onStart: true), isNull, reason: reply.body);
      }
    });

    test('fails silently offline', () async {
      final s = service(
        (_) => throw http.ClientException('Failed host lookup'),
      );
      expect(await s.check(onStart: true), isNull);
    });

    test('gives up after the timeout', () async {
      final s = service(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 20),
      );
      expect(await s.check(onStart: true), isNull);
    });

    test('makes no request when the installed version is unknown', () async {
      final s = service((_) => ok([]), installed: null);
      expect(await s.check(onStart: true), isNull);
      expect(requests, 0);
    });

    test('resume checks are throttled; start checks are not', () async {
      final s = service((_) => ok([_release('app-v1.4.9+17')]));
      expect(await s.check(onStart: true), isNotNull);
      expect(requests, 1);

      now = now.add(const Duration(hours: 1));
      expect(await s.check(), isNull);
      expect(requests, 1, reason: 'within resumeGap: no request');

      expect(await s.check(onStart: true), isNotNull);
      expect(requests, 2, reason: 'a cold start always checks');

      now = now.add(AppUpdateService.resumeGap);
      expect(await s.check(), isNotNull);
      expect(requests, 3);
    });

    test('a failed check still counts toward the throttle', () async {
      final s = service((_) => http.Response('', 403));
      await s.check();
      now = now.add(const Duration(minutes: 30));
      await s.check();
      expect(requests, 1);
    });

    test('Later hides that build until a newer one appears', () async {
      var tag = 'app-v1.4.9+17';
      final s = service((_) => ok([_release(tag)]));
      final first = await s.check(onStart: true);
      await s.dismiss(first!);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppUpdateService.dismissedBuildKey), 17);
      expect(await s.check(onStart: true), isNull);

      tag = 'app-v1.5.0+18';
      expect((await s.check(onStart: true))!.version.build, 18);
    });
  });

  group('release notes and version name', () {
    test('notes come from the release body as plain lines', () {
      const body =
          'MSS app 2.1 (build 17). Installs as an update.\n'
          '\n'
          '### Fixed\n'
          '- Hindi is offered in the **language picker** again.\n'
          '- See [the guide](https://example.com) for `details`.\n'
          '<!-- internal -->\n'
          'Signed with the MSS release key (SHA-256 cc58f15a).\n'
          'Built by GitHub Actions run 1 from abc.\n';
      expect(AppRelease.notesFrom(body), [
        'MSS app 2.1 (build 17). Installs as an update.',
        'Fixed',
        '• Hindi is offered in the language picker again.',
        '• See the guide for details.',
      ]);
    });

    test('notes are empty without a body and capped when long', () {
      expect(AppRelease.notesFrom(null), isEmpty);
      final long = List.generate(60, (i) => '- item $i').join('\n');
      expect(AppRelease.notesFrom(long), hasLength(AppRelease.maxNoteLines));
    });

    test('a release carries its notes', () {
      final r = AppRelease.fromJson({
        'tag_name': 'app-v2.1.0+17',
        'html_url':
            'https://github.com/nyxri0f8/MSS_App-releases/releases/tag/x',
        'draft': false,
        'prerelease': false,
        'body': '### Added\r\n- Update notice with release notes',
        'assets': const [],
      })!;
      expect(r.notes, ['Added', '• Update notice with release notes']);
    });

    test('2.1.0 is shown as 2.1, other versions in full', () {
      expect(const AppVersion(2, 1, 0, 17).displayName, '2.1');
      expect(const AppVersion(2, 1, 3, 18).displayName, '2.1.3');
    });

    test('the check reads the public releases repository', () {
      expect(
        AppUpdateService.releasesApi.toString(),
        'https://api.github.com/repos/${AppUpdateService.releasesRepo}'
        '/releases?per_page=10',
      );
      expect(AppUpdateService.releasesRepo, isNot('Roger-Chris/MSS_App'));
    });
  });
}
