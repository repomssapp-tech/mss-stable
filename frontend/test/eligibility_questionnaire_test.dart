import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/eligibility_questionnaire.dart';
import 'package:frontend/models/places_data.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/screens/regular_mode/eligibility_check/eligibility_check_screen.dart';
import 'package:frontend/screens/regular_mode/eligibility_check/eligibility_location.dart';
import 'package:frontend/screens/regular_mode/home/home_guest_reminder_card.dart';
import 'package:frontend/services/account/eligibility_answers_store.dart';
import 'package:frontend/services/account/questionnaire_sync_service.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

EligibilityQuestionnaire _load() => EligibilityQuestionnaire.parse(
  File('assets/questionnaire/questionnaire.json').readAsStringSync(),
);
PlacesData _places() =>
    PlacesData.parse(File('assets/questionnaire/places.json').readAsStringSync());

UserProfile _profile() => UserProfile(
  name: 'Asha',
  gender: 'Female',
  dob: DateTime.now().subtract(const Duration(days: 365 * 30)),
  state: 'Maharashtra',
  district: 'Pune',
);

const _required = {
  'gender': 'woman',
  'age_band': 'a25_35',
  'business_state': 'maharashtra',
  'nature': 'services',
  'business_age': 'lt_1',
};

/// Records what would be sent, instead of sending it.
class _RecordingApi extends ApiClient {
  _RecordingApi({this.fail = false});
  final bool fail;
  final calls = <Map<String, Object?>>[];

  Future<ApiResponse<dynamic>> _record(
    String method,
    String path,
    dynamic body,
    bool auth,
  ) async {
    if (fail) throw Exception('offline');
    calls.add({'method': method, 'path': path, 'body': body, 'auth': auth});
    return const ApiResponse(data: {}, statusCode: 200, headers: {});
  }

  @override
  Future<ApiResponse<dynamic>> put(
    String path, {
    required dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) => _record('PUT', path, body, requiresAuth);

  @override
  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) => _record('POST', path, body, requiresAuth);

  @override
  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) => _record('GET', path, null, requiresAuth);
}

Widget _app(Widget home, {String locale = 'en'}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: Locale(locale),
  home: home,
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('catalog: 28 questions with en/hi/mr/ta text; Devanagari for hi and mr', () {
    final q = _load();
    expect(q.fields, hasLength(28));
    final devanagari = RegExp(r'[ऀ-ॿ]');
    for (final f in q.fields) {
      expect(f.question['mr'], matches(devanagari), reason: f.id);
      expect(f.question['hi'], matches(devanagari), reason: f.id);
      expect(f.question['ta'], isNotEmpty, reason: f.id);
      for (final o in f.options) {
        expect(o.text.keys, containsAll(['en', 'mr', 'hi', 'ta']), reason: f.id);
      }
    }
    expect(
      q.fields.where((f) => f.required).map((f) => f.id),
      EligibilityQuestionnaire.requiredIds,
    );
  });

  test('the personal details answer gender, age and home state, so they are not asked twice', () {
    final q = _load();
    final derived = q.derive(_profile());
    expect(derived['gender'], 'woman');
    expect(derived['age_band'], 'a25_35');
    expect(derived['home_state'], 'maharashtra');
    expect(derived['home_district'], 'Pune');
    final quick = q.asked({...derived}, derived, quick: true).map((f) => f.id);
    expect(quick, isNot(contains('gender')));
    expect(quick, contains('business_state'));
    expect(quick, contains('business_district'));
    expect(quick, contains('help_needed'));
    expect(quick, isNot(contains('tax')), reason: 'long-list questions are not in the short survey');
    expect(q.asked({...derived}, derived, quick: false).map((f) => f.id), contains('tax'));
  });

  test('questions for a running business follow business_age; done means every asked question', () {
    final q = _load();
    final derived = q.derive(_profile());
    final gi = q.fields.firstWhere((f) => f.id == 'gi_tag');
    expect(q.isVisible(gi, {}), isFalse);
    expect(q.isVisible(gi, {'business_age': 'not_started'}), isFalse);
    expect(q.isVisible(gi, {'business_age': 'y1_3'}), isTrue);
    final quickAnswers = {
      'business_state': 'maharashtra',
      'business_district': 'Pune',
      'business_taluka': 'Haveli',
      'business_city': 'Pune',
      'nature': 'services',
      'business_age': 'not_started',
      'help_needed': ['finance'],
    };
    expect(q.isDone(quickAnswers, derived, all: false), isTrue, reason: 'a guest finished the short list');
    expect(q.isDone(quickAnswers, derived, all: true), isFalse, reason: 'Google sign-in needs every question');
    expect(q.isDone({}, derived, all: false), isFalse);
  });

  test('places: districts, talukas and cities follow the state', () {
    final p = _places();
    expect(p.districts('maharashtra'), hasLength(36));
    expect(p.districts('tamil_nadu'), hasLength(38));
    expect(p.talukas('maharashtra', 'Pune'), contains('Haveli'));
    expect(p.talukas('tamil_nadu', 'Chennai'), contains('Egmore'));
    expect(p.talukas('maharashtra', 'Chennai'), isEmpty);
    expect(p.cities('maharashtra'), isNotEmpty);
    expect(PlacesData.match(p.districts('maharashtra'), ' pune '), 'Pune');
  });

  test('answers and location round-trip through the store', () async {
    SharedPreferences.setMockInitialValues({});
    const store = EligibilityAnswersStore();
    await store.save({'age_band': 'a25_35', 'social_category': ['sc']});
    expect(await store.load(), {'age_band': 'a25_35', 'social_category': ['sc']});
    expect(await store.isPending(), isTrue);
    await store.markSent();
    expect(await store.isPending(), isFalse);
    await store.saveLocation(const QuestionnaireLocation(18.5204, 73.8567, 20));
    expect((await store.loadLocation())?.latitude, 18.5204);
    await store.clear();
    expect(await store.load(), isEmpty);
    expect(await store.loadLocation(), isNull);
  });

  test('guest id is a version 4 uuid and is kept', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      QuestionnaireSyncService.newGuestId(),
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
    final svc = QuestionnaireSyncService(apiClient: _RecordingApi());
    expect(await svc.guestId(), await svc.guestId());
  });

  test('a guest sends answers to the public guest endpoint with their id', () async {
    SharedPreferences.setMockInitialValues({});
    const store = EligibilityAnswersStore();
    await store.save(_required);
    final api = _RecordingApi();
    final svc = QuestionnaireSyncService(apiClient: api, isSignedIn: () => false);
    expect(await svc.sync(language: 'ta'), isTrue);
    final call = api.calls.single;
    expect(call['path'], '/questionnaire/guest');
    expect(call['auth'], isFalse);
    final body = call['body'] as Map;
    expect(body['guest_id'], await svc.guestId());
    expect(body['language'], 'ta');
    expect(body['answers'], _required);
    expect(await store.isPending(), isFalse);
  });

  test('a signed-in user sends to their own endpoint; a new phone reads the account answers', () async {
    SharedPreferences.setMockInitialValues({});
    const store = EligibilityAnswersStore();
    final api = _RecordingApi();
    final svc = QuestionnaireSyncService(apiClient: api, isSignedIn: () => true);
    await svc.pullIfEmpty();
    expect(api.calls.single['path'], '/me/questionnaire');
    expect(api.calls.single['method'], 'GET');
    await store.save(_required);
    api.calls.clear();
    expect(await svc.sync(), isTrue);
    expect(api.calls.single['path'], '/me/questionnaire');
    expect((api.calls.single['body'] as Map).containsKey('guest_id'), isFalse);
  });

  test('a failed send keeps the answers pending, and sign-in claims the guest row', () async {
    SharedPreferences.setMockInitialValues({});
    const store = EligibilityAnswersStore();
    await store.save(_required);
    final failing = QuestionnaireSyncService(apiClient: _RecordingApi(fail: true), isSignedIn: () => false);
    expect(await failing.sync(), isFalse);
    expect(await store.isPending(), isTrue);
    final guestId = await failing.guestId();
    final api = _RecordingApi();
    final svc = QuestionnaireSyncService(apiClient: api, isSignedIn: () => true);
    await svc.afterSignIn(language: 'en');
    expect(api.calls.first['path'], '/me/questionnaire/claim');
    expect((api.calls.first['body'] as Map)['guest_id'], guestId);
    expect(api.calls.last['path'], '/me/questionnaire');
    expect(await store.isPending(), isFalse);
  });

  testWidgets('short survey: gender and age are not asked; state then district then taluka', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _tall(tester);
    await tester.pumpWidget(
      _app(
        EligibilityCheckScreen(
          questionnaire: _load(),
          places: _places(),
          profile: _profile(),
          quick: true,
          firstRun: true,
          sendAnswers: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tell us about you'), findsOneWidget);
    expect(find.text('Where you live and work'), findsWidgets, reason: 'the first short step is the place, not "About you"');
    expect(find.textContaining('What is your gender'), findsNothing);
    expect(find.textContaining('Skip the rest'), findsNothing, reason: 'the short survey has no skip');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Please answer this to continue'), findsOneWidget);
  });

  testWidgets('"Use my location" fills the state, district and city and keeps the coordinates', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _tall(tester);
    await tester.pumpWidget(
      _app(
        EligibilityCheckScreen(
          questionnaire: _load(),
          places: _places(),
          profile: _profile(),
          quick: true,
          sendAnswers: (_) async => true,
          detect: () async => const DetectedPlace(
            location: QuestionnaireLocation(18.5204, 73.8567, 12),
            state: 'Maharashtra',
            district: 'pune',
            city: 'Pune',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my current location'));
    await tester.pumpAndSettle();
    const store = EligibilityAnswersStore();
    final saved = await store.load();
    expect(saved['business_state'], 'maharashtra');
    expect(saved['business_district'], 'Pune', reason: 'the list spelling, not the detected one');
    expect(saved['business_city'], 'Pune');
    expect((await store.loadLocation())?.longitude, 73.8567);
  });

  testWidgets('long list: a guest can skip the rest; a Google user cannot', (tester) async {
    SharedPreferences.setMockInitialValues({
      'mss.eligibility.answers': jsonEncode({..._required, 'business_district': 'Pune'}),
    });
    _tall(tester);
    var finished = 0;
    await tester.pumpWidget(
      _app(
        EligibilityCheckScreen(
          questionnaire: _load(),
          places: _places(),
          profile: _profile(),
          allowSkip: true,
          firstRun: true,
          sendAnswers: (_) async => true,
          onFinished: (_) => finished++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Skip the rest'), findsOneWidget);
    await tester.tap(find.text('Skip the rest'));
    await tester.pumpAndSettle();
    expect(finished, 1);

    await tester.pumpWidget(
      _app(
        EligibilityCheckScreen(
          questionnaire: _load(),
          places: _places(),
          profile: _profile(),
          mandatory: true,
          sendAnswers: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Skip the rest'), findsNothing);
    expect(find.text('All questions are needed to continue.'), findsOneWidget);
  });

  testWidgets('question language can switch to Tamil and Marathi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _tall(tester);
    await tester.pumpWidget(
      _app(EligibilityCheckScreen(questionnaire: _load(), places: _places(), sendAnswers: (_) async => true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();
    expect(find.textContaining('உங்கள் பாலினம்'), findsOneWidget);
    await tester.tap(find.text('मराठी'));
    await tester.pumpAndSettle();
    expect(find.textContaining('तुमचे लिंग'), findsOneWidget);
  });

  testWidgets('guest reminder says to sign in to complete the profile', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: HomeGuestReminderCard())));
    expect(find.textContaining('Complete your profile'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
