import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/onboarding_api_dto.dart';
import 'package:frontend/providers/controllers/profile_cloud_sync.dart';
import 'package:frontend/services/account/app_session.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/user_profile_api_dto.dart';
import 'package:frontend/services/account/onboarding_api_service.dart';
import 'package:frontend/services/account/profile_api_service.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('ProfileAggregate DTO and Mapper', () {
    test(
      'deserializes complete ProfileAggregate and converts to UserProfile',
      () {
        final json = {
          'id': '00000000-0000-4000-8000-000000000001',
          'email': 'user@example.com',
          'photo_url': 'https://example.com/avatar.png',
          'name': 'Praveen Kanna',
          'dob': '1995-08-20',
          'gender': 'Male',
          'phone': '9876543210',
          'state': 'Tamil Nadu',
          'district': 'Chennai',
          'city': 'Chennai',
          'pincode': '600028',
          'house': '42 App Way',
          'area': 'Mylapore',
          'community': 'OBC',
          'religion': 'Hindu',
          'education_level': 'Undergraduate',
          'qualification': 'B.E. Computer Science',
          'applicant_type': 'Business Owner',
          'disability': 'None',
          'first_gen_graduate': true,
          'veteran': false,
          'annual_income': 0,
          'language': 'ta',
          'notifications': true,
          'theme': 'light',
          'navigation_mode': 'regular',
          'is_profile_complete': true,
          'version': 3,
          'created_at': '2026-10-16T08:30:00.000Z',
          'updated_at': '2026-10-16T09:00:00.000Z',
          'business': {
            'profile_name': 'Kanna Tech',
            'industry': 'Software',
            'applicant_type': 'Business Owner',
            'business_stage': 'Operational',
            'business_registered': true,
            'funding_required_amount': 250000.0,
            'registration_numbers': 'UDYAM-TN-01-0001234',
            'is_first_generation_entrepreneur': true,
          },
          'legal_acceptances': [
            {
              'document_type': 'terms',
              'document_version': 'v1.0',
              'accepted_at': '2026-10-16T08:35:00.000Z',
            },
          ],
          'missing_fields': [],
        };

        final aggregate = ProfileAggregate.fromJson(json);
        expect(aggregate.id, '00000000-0000-4000-8000-000000000001');
        expect(aggregate.name, 'Praveen Kanna');
        expect(aggregate.annualIncome, 0.0);
        expect(aggregate.firstGenGraduate, isTrue);
        expect(aggregate.version, 3);
        expect(aggregate.isProfileComplete, isTrue);
        expect(aggregate.business?['profile_name'], 'Kanna Tech');

        final userProfile = aggregate.toUserProfile();
        expect(userProfile.name, 'Praveen Kanna');
        expect(userProfile.mobile, '9876543210');
        expect(userProfile.pinCode, '600028');
        expect(userProfile.annualIncome, 0.0);
        expect(userProfile.existingBusiness, isTrue);
        expect(userProfile.businessIndustry, 'Software');
        expect(userProfile.fundingRequired, 250000.0);
      },
    );

    test('buildPatchPayload sends only languages the server can store', () {
      final baseline = ProfileAggregate(
        id: 'u1',
        email: 'test@example.com',
        version: 1,
        isProfileComplete: false,
        name: 'Name',
        language: 'en',
      );

      expect(
        ProfileAggregate.buildPatchPayload(
          current: UserProfile(name: 'Name', language: 'ta'),
          baseline: baseline,
        )['language'],
        'ta',
      );
      // Every language the app offers is sent.
      for (final code in const ['hi']) {
        expect(
          ProfileAggregate.buildPatchPayload(
            current: UserProfile(name: 'Name', language: code),
            baseline: baseline,
          )['language'],
          code,
        );
      }
    });

    test(
      'buildPatchPayload creates minimal map with explicit nulls and zeroes',
      () {
        final baseline = ProfileAggregate(
          id: 'u1',
          email: 'test@example.com',
          version: 1,
          isProfileComplete: false,
          name: 'Original Name',
          phone: '1111111111',
          annualIncome: 500000.0,
          religion: 'Hindu',
          veteran: true,
        );

        final current = UserProfile(
          name: 'Updated Name',
          mobile: '1111111111', // Unchanged
          annualIncome: 0.0, // Explicit zero
          religion: '', // Explicitly cleared
          veteran: false, // Explicit false
        );

        final patch = ProfileAggregate.buildPatchPayload(
          current: current,
          baseline: baseline,
        );

        expect(patch['name'], 'Updated Name');
        expect(
          patch.containsKey('phone'),
          isFalse,
          reason: 'Unchanged fields must be omitted',
        );
        expect(
          patch['annual_income'],
          0.0,
          reason: 'Zero income must be preserved',
        );
        expect(
          patch.containsKey('religion'),
          isFalse,
          reason: 'religion was removed from the profile API',
        );
        expect(patch['veteran'], isFalse);
        expect(
          patch.containsKey('id'),
          isFalse,
          reason: 'Read-only fields must never be in PATCH',
        );
      },
    );
  });

  group('ProfileApiService', () {
    test(
      'loadProfile stores ETag and saveDraft sends X-Profile-If-Match',
      () async {
        String? capturedIfMatch;
        String? capturedStandardIfMatch;

        final mockClient = MockClient((request) async {
          if (request.method == 'GET' && request.url.path == '/v1/me/profile') {
            return http.Response(
              jsonEncode({
                'id': 'u1',
                'email': 'u@test.com',
                'name': 'Test User',
                'version': 1,
                'is_profile_complete': false,
              }),
              200,
              headers: {'etag': '"profile-1"'},
            );
          }

          if (request.method == 'PATCH' &&
              request.url.path == '/v1/me/profile') {
            capturedIfMatch = request.headers['X-Profile-If-Match'];
            capturedStandardIfMatch = request.headers['If-Match'];

            return http.Response(
              jsonEncode({
                'id': 'u1',
                'email': 'u@test.com',
                'name': 'Saved User',
                'version': 2,
                'is_profile_complete': false,
              }),
              200,
              headers: {'etag': '"profile-2"'},
            );
          }

          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org/v1',
          httpClient: mockClient,
        );
        final profileService = ProfileApiService(apiClient: apiClient);

        final initial = await profileService.loadProfile();
        expect(initial.version, 1);
        expect(profileService.currentEtag, '"profile-1"');

        final updated = await profileService.saveDraft({'name': 'Saved User'});
        expect(updated.version, 2);
        expect(profileService.currentEtag, '"profile-2"');

        // Vercel precondition compliance check:
        expect(capturedIfMatch, '"profile-1"');
        expect(
          capturedStandardIfMatch,
          isNull,
          reason: 'Do NOT send standard If-Match on Vercel',
        );
      },
    );

    test(
      'a rejected language is dropped and the rest of the draft is saved',
      () async {
        final patchBodies = <Map<String, dynamic>>[];
        final mockClient = MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'id': 'u1',
                'email': 'u@test.com',
                'version': 1,
                'is_profile_complete': false,
              }),
              200,
              headers: {'etag': '"profile-1"'},
            );
          }
          patchBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          if (patchBodies.last.containsKey('language')) {
            return http.Response(
              jsonEncode({
                'error': 'VALIDATION_ERROR',
                'details': [
                  {'field': 'language', 'code': 'INVALID_VALUE'},
                ],
              }),
              400,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'u1',
              'email': 'u@test.com',
              'name': 'Saved User',
              'version': 2,
              'is_profile_complete': false,
            }),
            200,
            headers: {'etag': '"profile-2"'},
          );
        });
        final profileService = ProfileApiService(
          apiClient: ApiClient(
            baseUrl: 'https://mssapi.msmeschemes.org/v1',
            httpClient: mockClient,
          ),
        );

        final updated = await profileService.saveDraft({
          'name': 'Saved User',
          'language': 'hi',
        });

        expect(updated.version, 2);
        expect(patchBodies.length, 2);
        expect(patchBodies.first['language'], 'hi');
        expect(patchBodies.last, {'name': 'Saved User'});
      },
    );

    test('other validation errors are not retried', () async {
      var patches = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({'id': 'u1', 'email': 'u@test.com', 'version': 1}),
            200,
            headers: {'etag': '"profile-1"'},
          );
        }
        patches++;
        return http.Response(
          jsonEncode({
            'error': 'VALIDATION_ERROR',
            'details': [
              {'field': 'phone', 'code': 'INVALID_VALUE'},
            ],
          }),
          400,
        );
      });
      final profileService = ProfileApiService(
        apiClient: ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org/v1',
          httpClient: mockClient,
        ),
      );

      await expectLater(
        profileService.saveDraft({'phone': 'x', 'language': 'hi'}),
        throwsA(isA<ApiException>()),
      );
      expect(patches, 1);
    });

    test('saveDraft propagates 412 PROFILE_VERSION_CONFLICT', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'PROFILE_VERSION_CONFLICT',
            'details': [
              {'field': 'version', 'current': 5},
            ],
          }),
          412,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final profileService = ProfileApiService(
        apiClient: apiClient,
        initialEtag: '"profile-1"',
      );

      expect(
        () => profileService.saveDraft({'name': 'Conflict User'}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isStaleVersion,
            'isStaleVersion',
            isTrue,
          ),
        ),
      );
    });
  });

  group('OnboardingApiService', () {
    test('getLegalDocuments parses configured and items correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/me/legal-documents');
        return http.Response(
          jsonEncode({
            'configured': true,
            'items': [
              {'document_type': 'terms', 'document_version': '1.0'},
              {'document_type': 'privacy_policy', 'document_version': '1.0'},
            ],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org/v1',
        httpClient: mockClient,
      );
      final service = OnboardingApiService(apiClient: apiClient);

      final legal = await service.getLegalDocuments();
      expect(legal.configured, isTrue);
      expect(legal.items.length, 2);
      expect(legal.items[0].documentType, 'terms');
      expect(legal.items[0].documentVersion, '1.0');
    });

    test(
      'submitOnboarding sends Idempotency-Key and X-Profile-If-Match with business null',
      () async {
        String? capturedIdempotency;
        String? capturedEtag;
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          expect(request.url.path, '/v1/me/onboarding');
          expect(request.method, 'PUT');
          capturedIdempotency = request.headers['Idempotency-Key'];
          capturedEtag = request.headers['X-Profile-If-Match'];
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response(
            jsonEncode({
              'id': 'u1',
              'email': 'test@test.com',
              'name': 'Onboarded User',
              'is_profile_complete': true,
              'version': 3,
              'missing_fields': [],
            }),
            200,
            headers: {'etag': '"profile-3"'},
          );
        });

        final apiClient = ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org/v1',
          httpClient: mockClient,
        );
        final service = OnboardingApiService(apiClient: apiClient);

        final submission = OnboardingSubmissionDto(
          profile: {
            'name': 'Onboarded User',
            'phone': '9876543210',
            'annual_income': 0,
          },
          business: null, // Deliberate null deactivation
          legalAcceptances: [
            const LegalDocumentItem(
              documentType: 'terms',
              documentVersion: '1.0',
            ),
            const LegalDocumentItem(
              documentType: 'privacy_policy',
              documentVersion: '1.0',
            ),
          ],
        );

        final result = await service.submitOnboarding(
          submission,
          etag: '"profile-2"',
          idempotencyKey: 'idem-key-12345',
        );

        expect(result.isProfileComplete, isTrue);
        expect(capturedIdempotency, 'idem-key-12345');
        expect(capturedEtag, '"profile-2"');
        expect(
          capturedBody?['business'],
          isNull,
          reason: 'Business null must be transmitted explicitly',
        );
        expect((capturedBody?['legal_acceptances'] as List).length, 2);
      },
    );
  });

  group('finishing onboarding needs recorded consent', () {
    late List<String> seen;
    late ApiClient client;

    Future<void> signIn() async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TokenStorage(prefs);
      await storage.saveTokens(accessToken: 'tok', refreshToken: 'ref');
      await storage.saveUser(id: 'u1', email: 'a@example.com', name: 'A');
      await AppSession.instance.hydrate(storage: storage);
      seen = [];
      final profileJson = {
        'id': 'u1',
        'email': 'a@example.com',
        'name': 'A',
        'version': 1,
        'is_profile_complete': false,
        'notifications': true,
        'language': 'en',
        'theme': 'light',
        'navigation_mode': 'regular',
        'missing_fields': <String>[],
        'legal_acceptances': <Map<String, dynamic>>[],
        'business': null,
      };
      client = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org/v1',
        httpClient: MockClient((request) async {
          seen.add('${request.method} ${request.url.path}');
          if (request.url.path == '/v1/me/onboarding') {
            seen.add('BODY ${request.body}');
          }
          return http.Response(
            jsonEncode(profileJson),
            200,
            headers: {
              'content-type': 'application/json',
              'etag': '"profile-1"',
            },
          );
        }),
        tokenStorage: storage,
      );
      final profileService = ProfileApiService(apiClient: client);
      ProfileApiService.testInstance = profileService;
      OnboardingApiService.testInstance = OnboardingApiService(
        apiClient: client,
        profileApiService: profileService,
      );
    }

    tearDown(() async {
      await AppSession.instance.resetForTest();
      ProfileApiService.testInstance = null;
      OnboardingApiService.testInstance = null;
      await LegalConsentStore.clear();
    });

    test(
      'without an accepted document only the profile fields are sent',
      () async {
        await signIn();

        await syncProfileToServer(
          UserProfile(name: 'B', state: 'Tamil Nadu', profileCompleted: true),
          isLoggedIn: true,
        );

        expect(seen.any((c) => c.contains('/v1/me/onboarding')), isFalse);
        expect(seen.any((c) => c.startsWith('PATCH /v1/me/profile')), isTrue);
      },
    );

    test(
      'with recorded consent onboarding carries exactly those acceptances',
      () async {
        await signIn();
        await LegalConsentStore.record(const [
          LegalDocumentItem(documentType: 'terms', documentVersion: 'v7'),
          LegalDocumentItem(documentType: 'privacy_policy', documentVersion: 'v3'),
          LegalDocumentItem(documentType: 'privacy_notice', documentVersion: 'v2'),
          LegalDocumentItem(documentType: 'consent', documentVersion: 'v2'),
        ]);

        await syncProfileToServer(
          _fullProfile(),
          isLoggedIn: true,
        );

        final body = seen.firstWhere((c) => c.startsWith('BODY '));
        final sent = jsonDecode(body.substring(5)) as Map<String, dynamic>;
        final profile = sent['profile'] as Map<String, dynamic>;
        expect(profile.containsKey('email'), isFalse);
        expect(profile['phone'], '9000000000');
        expect(profile['pincode'], '600001');
        expect(profile['annual_income'], 300000);
        expect(sent['legal_acceptances'], [
          {'document_type': 'terms', 'document_version': 'v7'},
          {'document_type': 'privacy_policy', 'document_version': 'v3'},
          {'document_type': 'privacy_notice', 'document_version': 'v2'},
          {'document_type': 'consent', 'document_version': 'v2'},
        ]);
      },
    );

    test('an incomplete profile is not sent as onboarding', () async {
      await signIn();
      await LegalConsentStore.record(const [
        LegalDocumentItem(documentType: 'terms', documentVersion: 'v7'),
      ]);

      await syncProfileToServer(
        UserProfile(name: 'B', state: 'Tamil Nadu', profileCompleted: true),
        isLoggedIn: true,
      );

      expect(seen.any((c) => c.startsWith('BODY ') && c.contains('legal_')),
          isFalse);
    });

    test('phone and pincode are sanitised, student venture is dropped', () {
      final p = _fullProfile()
        ..mobile = '+91 90000-00000'
        ..pinCode = '600 001'
        ..employmentStatus = 'Student'
        ..businessStage = 'Idea';
      final map = buildOnboardingProfile(p);
      expect(map['phone'], '9000000000');
      expect(map['pincode'], '600001');
      expect(missingOnboardingFields(map), isEmpty);
      expect(buildOnboardingBusiness(p, 'Student'), isNull);
      expect(buildOnboardingBusiness(p, 'Individual'), isNotNull);
      expect(missingOnboardingFields(buildOnboardingProfile(UserProfile())),
          contains('house'));
    });

    test('consent is per account: clearing forgets it', () async {
      await LegalConsentStore.record(const [
        LegalDocumentItem(documentType: 'terms', documentVersion: 'v7'),
      ]);
      expect((await LegalConsentStore.accepted()).length, 1);

      await LegalConsentStore.clear();

      expect(await LegalConsentStore.accepted(), isEmpty);
    });
  });
}

UserProfile _fullProfile() => UserProfile(
  name: 'B',
  dob: DateTime(1995, 1, 1),
  gender: 'Female',
  mobile: '9000000000',
  state: 'Tamil Nadu',
  district: 'Chennai',
  city: 'Chennai',
  house: '1 Example Street',
  pinCode: '600001',
  educationLevel: 'Undergraduate',
  community: 'General',
  annualIncome: 300000,
  employmentStatus: 'Individual',
  profileCompleted: true,
);
