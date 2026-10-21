import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/account/app_session.dart';
import 'package:frontend/services/account/onboarding_api_service.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/widgets/legal/legal_document_modal.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app({required Locale locale, required void Function(bool?) onResult}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async =>
                onResult(await LegalDocumentModal.showTermsOfUse(context)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LegalDocumentModal requires reading to the end', () {
    testWidgets('Accept before the end only shows the alert', (tester) async {
      bool? result = false;
      var closed = false;
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          onResult: (value) {
            result = value;
            closed = true;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LegalDocumentModal)),
      )!;

      // The hint is visible while the end has not been reached.
      expect(find.text(l10n.legalScrollToEndHint), findsOneWidget);

      await tester.tap(find.text(l10n.legalAccept));
      await tester.pumpAndSettle();

      expect(find.text(l10n.legalScrollToEndNotice), findsOneWidget);
      expect(closed, isFalse, reason: 'the document was not accepted');

      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();
      expect(find.text(l10n.legalScrollToEndNotice), findsNothing);
      expect(find.byType(LegalDocumentModal), findsOneWidget);
      expect(result, isFalse);
    });

    testWidgets('after scrolling to the end Accept closes with true', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        _app(locale: const Locale('en'), onResult: (value) => result = value),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LegalDocumentModal)),
      )!;

      for (var i = 0; i < 8; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -600),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text(l10n.legalScrollToEndHint), findsNothing);
      await tester.tap(find.text(l10n.legalAccept));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(LegalDocumentModal), findsNothing);
    });

    testWidgets('closing early does not accept', (tester) async {
      bool? result = false;
      var closed = false;
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          onResult: (value) {
            result = value;
            closed = true;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });

    test('the alert and hint exist in English, Tamil and Hindi', () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      for (final code in ['ta', 'hi']) {
        final localized = await AppLocalizations.delegate.load(Locale(code));
        expect(localized.legalScrollToEndNotice, isNotEmpty, reason: code);
        expect(localized.legalScrollToEndHint, isNotEmpty, reason: code);
        expect(
          localized.legalScrollToEndNotice,
          isNot(english.legalScrollToEndNotice),
          reason: '$code must not fall back to English',
        );
        expect(
          localized.legalScrollToEndHint,
          isNot(english.legalScrollToEndHint),
          reason: code,
        );
      }
      expect(english.legalScrollToEndNotice, contains('end'));
    });
  });

  group('login agreement becomes recorded consent', () {
    late List<String> seen;
    late OnboardingApiService service;

    Future<void> signIn({required bool configured}) async {
      final prefs = await SharedPreferences.getInstance();
      final storage = TokenStorage(prefs);
      await storage.saveTokens(accessToken: 'tok', refreshToken: 'ref');
      await storage.saveUser(id: 'u1', email: 'a@example.com', name: 'A');
      await AppSession.instance.hydrate(storage: storage);
      seen = [];
      service = OnboardingApiService(
        apiClient: ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org/v1',
          httpClient: MockClient((request) async {
            seen.add('${request.method} ${request.url.path}');
            return http.Response(
              jsonEncode({
                'configured': configured,
                'items': configured
                    ? [
                        {'document_type': 'terms', 'document_version': 'v7'},
                        {
                          'document_type': 'privacy_policy',
                          'document_version': 'v3',
                        },
                        {
                          'document_type': 'privacy_notice',
                          'document_version': 'v2',
                        },
                        {'document_type': 'consent', 'document_version': 'v1'},
                      ]
                    : [],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
          tokenStorage: storage,
        ),
      );
    }

    tearDown(() async {
      await AppSession.instance.resetForTest();
      await LegalConsentStore.clear();
    });

    test(
      'without an agreement on the sign-in screen nothing is recorded',
      () async {
        await signIn(configured: true);

        await LegalConsentStore.recordFromLoginAgreement(service);

        expect(seen, isEmpty, reason: 'no request is even needed');
        expect(await LegalConsentStore.accepted(), isEmpty);
      },
    );

    test('the sign-in agreement records Terms and Privacy Policy once', () async {
      await signIn(configured: true);
      await LegalConsentStore.markLoginAgreement();

      await LegalConsentStore.recordFromLoginAgreement(service);

      expect(seen, ['GET /v1/me/legal-documents']);
      final accepted = await LegalConsentStore.accepted();
      expect(accepted.map((d) => d.documentType), ['terms', 'privacy_policy']);
      expect(accepted.map((d) => d.documentVersion), ['v7', 'v3']);
      expect(await LegalConsentStore.hasLoginAgreement(), isFalse);
      expect(await LegalConsentStore.isComplete(), isFalse);

      await LegalConsentStore.recordFromLoginAgreement(service);
      expect(seen.length, 1, reason: 'already recorded: no second request');
    });

    test('completing the profile records the data-use page', () async {
      await signIn(configured: true);
      await LegalConsentStore.markLoginAgreement();
      await LegalConsentStore.recordFromLoginAgreement(service);

      await LegalConsentStore.recordFromProfileCompletion(service);

      final accepted = await LegalConsentStore.accepted();
      expect(accepted.map((d) => d.documentType), [
        'terms',
        'privacy_policy',
        'privacy_notice',
        'consent',
      ]);
      expect(accepted.map((d) => d.documentVersion), ['v7', 'v3', 'v2', 'v1']);
      expect(await LegalConsentStore.isComplete(), isTrue);
    });

    test('the data-use page is not recorded without the sign-in documents',
        () async {
      await signIn(configured: true);

      await LegalConsentStore.recordFromProfileCompletion(service);

      expect(seen, isEmpty);
      expect(await LegalConsentStore.accepted(), isEmpty);
    });

    test('documents not configured yet: the agreement waits', () async {
      await signIn(configured: false);
      await LegalConsentStore.markLoginAgreement();

      await LegalConsentStore.recordFromLoginAgreement(service);

      expect(await LegalConsentStore.accepted(), isEmpty);
      expect(await LegalConsentStore.hasLoginAgreement(), isTrue);
    });

    test('clearing (sign-out) forgets the agreement and the consent', () async {
      await signIn(configured: true);
      await LegalConsentStore.markLoginAgreement();
      await LegalConsentStore.recordFromLoginAgreement(service);
      await LegalConsentStore.markLoginAgreement();

      await LegalConsentStore.clear();

      expect(await LegalConsentStore.accepted(), isEmpty);
      expect(await LegalConsentStore.hasLoginAgreement(), isFalse);
    });
  });
}
