import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/onboarding_api_dto.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/user_profile_api_dto.dart';
import 'package:frontend/services/account/onboarding_api_service.dart';
import 'package:frontend/services/account/profile_api_service.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:frontend/services/notifications/sse_event_service.dart';

const _base = 'https://mssapi.msmeschemes.org/v1';

http.Response _profile(int version, {int status = 200}) => http.Response(
  jsonEncode({
    'id': 'u1',
    'email': 'u@test.com',
    'name': 'Synthetic User',
    'version': version,
    'is_profile_complete': false,
  }),
  status,
  headers: {'etag': '"profile-$version"'},
);

/// Mock API whose ETag advances on every write. Records the version header
/// each write sent.
class _FakeServer {
  int version = 10;
  final sentIfMatch = <String>[];
  final sentKeys = <String>[];
  Duration patchDelay = Duration.zero;
  bool failOnboarding = false;

  Future<http.Response> handle(http.Request request) async {
    if (request.method == 'GET') return _profile(version);
    if (request.method == 'PATCH') await Future<void>.delayed(patchDelay);
    sentIfMatch.add(request.headers['x-profile-if-match'] ?? '');
    final key = request.headers['idempotency-key'];
    if (key != null) sentKeys.add(key);
    if (request.url.path.endsWith('/me/onboarding') && failOnboarding) {
      return http.Response(jsonEncode({'error': 'VALIDATION_ERROR'}), 400);
    }
    version++;
    return _profile(version);
  }
}

({_FakeServer server, ProfileApiService profile, OnboardingApiService onboarding})
_setup() {
  final server = _FakeServer();
  final client = ApiClient(
    baseUrl: _base,
    httpClient: MockClient(server.handle),
  );
  final profile = ProfileApiService(apiClient: client);
  final onboarding = OnboardingApiService(
    apiClient: client,
    profileApiService: profile,
  );
  return (server: server, profile: profile, onboarding: onboarding);
}

OnboardingSubmissionDto _submission(String name) => OnboardingSubmissionDto(
  profile: {'name': name},
  legalAcceptances: const [
    LegalDocumentItem(documentType: 'terms', documentVersion: '1'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ETag adoption', () {
    test('GET -> PATCH -> onboarding -> PATCH each send the previous ETag', () async {
      final s = _setup();

      await s.profile.loadProfile();
      await s.profile.saveDraft({'name': 'A'});
      await s.onboarding.submitOnboarding(_submission('A'));
      expect(s.profile.currentEtag, '"profile-12"');
      await s.profile.saveDraft({'name': 'B'});

      expect(s.server.sentIfMatch, ['"profile-10"', '"profile-11"', '"profile-12"']);
      expect(s.profile.currentEtag, '"profile-13"');
      expect(s.profile.currentProfile?.version, 13);
    });

    test('legal acceptance response ETag is used by the next PATCH', () async {
      final s = _setup();

      await s.profile.loadProfile();
      await s.onboarding.acceptLegalDocuments(const [
        LegalDocumentItem(documentType: 'terms', documentVersion: '1'),
      ], etag: s.profile.currentEtag!);
      await s.profile.saveDraft({'name': 'After legal'});

      expect(s.server.sentIfMatch, ['"profile-10"', '"profile-11"']);
    });
  });

  group('Conflict recovery', () {
    test('412 reloads the server version, keeps the edit and does not loop', () async {
      var patches = 0;
      final client = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((request) async {
          if (request.method == 'GET') return _profile(5);
          patches++;
          return http.Response(
            jsonEncode({'error': 'PROFILE_VERSION_CONFLICT'}),
            412,
          );
        }),
      );
      final profile = ProfileApiService(
        apiClient: client,
        initialEtag: '"profile-1"',
      );

      await expectLater(
        profile.saveDraft({'name': 'My edit'}),
        throwsA(
          isA<ApiException>().having((e) => e.isStaleVersion, 'stale', true),
        ),
      );

      expect(patches, 1, reason: 'no blind retry');
      expect(profile.currentEtag, '"profile-5"');
    });
  });

  group('Concurrent saves', () {
    test('overlapping writes are serialized and the ETag advances', () async {
      final s = _setup();
      s.server.patchDelay = const Duration(milliseconds: 30);

      final first = s.profile.saveDraft({'name': 'Background draft'});
      final second = s.profile.saveDraft({'name': 'Complete Profile'});
      await Future.wait([first, second]);

      expect(s.server.sentIfMatch, ['"profile-10"', '"profile-11"']);
      expect(s.profile.currentEtag, '"profile-12"');
    });

    test('a failed write does not block the next one', () async {
      final s = _setup();
      s.server.failOnboarding = true;

      await expectLater(
        s.onboarding.submitOnboarding(_submission('A'), etag: '"profile-10"'),
        throwsA(isA<ApiException>()),
      );
      s.server.failOnboarding = false;
      await s.profile.saveDraft({'name': 'Next'});

      expect(s.server.sentIfMatch.length, 2); // failed PUT, then PATCH
    });
  });

  group('Onboarding idempotency key', () {
    test('same payload retried keeps its key; a new payload or a success gets a new one', () async {
      final s = _setup();
      s.server.failOnboarding = true;

      await expectLater(
        s.onboarding.submitOnboarding(_submission('A'), etag: '"profile-10"'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        s.onboarding.submitOnboarding(_submission('A'), etag: '"profile-10"'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        s.onboarding.submitOnboarding(_submission('B'), etag: '"profile-10"'),
        throwsA(isA<ApiException>()),
      );
      expect(s.server.sentKeys[1], s.server.sentKeys[0]);
      expect(s.server.sentKeys[2], isNot(s.server.sentKeys[0]));

      s.server.failOnboarding = false;
      await s.onboarding.submitOnboarding(_submission('B'), etag: '"profile-10"');
      await s.onboarding.submitOnboarding(_submission('B'));
      expect(s.server.sentKeys[3], s.server.sentKeys[2]);
      expect(s.server.sentKeys[4], isNot(s.server.sentKeys[3]));
    });
  });

  group('Removed religion field', () {
    test('a legacy religion value is never in the PATCH payload', () {
      final patch = ProfileAggregate.buildPatchPayload(
        current: UserProfile(name: 'Synthetic User', religion: 'Hindu'),
      );
      expect(patch.containsKey('religion'), isFalse);
      expect(jsonEncode(patch).contains('religion'), isFalse);
    });

    test('saveProfileChanges does not send religion', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((request) async {
          if (request.method == 'PATCH') {
            bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          }
          return _profile(2);
        }),
      );
      final profile = ProfileApiService(apiClient: client);

      await profile.saveProfileChanges(
        UserProfile(name: 'Changed Name', religion: 'Hindu'),
      );

      expect(bodies.single['name'], 'Changed Name');
      expect(bodies.single.containsKey('religion'), isFalse);
    });
  });

  group('Notification stream URL', () {
    for (final base in [
      'https://mssapi.msmeschemes.org',
      'https://mssapi.msmeschemes.org/',
      'https://mssapi.msmeschemes.org/v1',
      'https://mssapi.msmeschemes.org/v1/',
    ]) {
      test('base "$base" gives a single /v1 and keeps headers', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mss_sse_last_event_id', 'cursor-9');
        final tokens = TokenStorage(prefs);
        await tokens.saveTokens(
          accessToken: 'synthetic-access',
          refreshToken: 'synthetic-refresh',
        );
        final seen = Completer<http.BaseRequest>();
        final service = SseEventService(
          client: ApiClient(baseUrl: base, tokenStorage: tokens),
          tokenStorage: tokens,
          httpClient: MockClient((request) async {
            if (!seen.isCompleted) seen.complete(request);
            return http.Response('', 404);
          }),
        );

        await service.startListening(onRefetchNeeded: () async {});
        final request = await seen.future.timeout(const Duration(seconds: 5));
        service.stopListening();

        expect(request.url.path, '/v1/me/notifications/events');
        expect(request.headers['Authorization'], 'Bearer synthetic-access');
        expect(request.headers['Accept'], 'text/event-stream');
        expect(request.headers['Last-Event-ID'], 'cursor-9');
      });
    }

    test('a 404 backs off and gives up instead of retrying every second', () async {
      final prefs = await SharedPreferences.getInstance();
      final tokens = TokenStorage(prefs);
      await tokens.saveTokens(accessToken: 'a', refreshToken: 'r');
      var requests = 0;
      final service = SseEventService(
        client: ApiClient(baseUrl: _base, tokenStorage: tokens),
        tokenStorage: tokens,
        httpClient: MockClient((request) async {
          requests++;
          return http.Response('', 404);
        }),
      );

      await service.startListening(onRefetchNeeded: () async {});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      service.stopListening();

      expect(requests, 1, reason: 'the retry is delayed by at least 30 s');
    });
  });
}
