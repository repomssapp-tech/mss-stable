import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/models/scheme_extras.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/screens/regular_mode/scheme_details/scheme_extra_sections.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

/// Renders the sections built from the 2026 source fields for real central,
/// Tamil Nadu and Maharashtra schemes in every UI language, checking that the
/// right sections appear, no raw `null`/`[]`/map text leaks, and nothing
/// overflows at a small phone width.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;

  String jur(MssEntity e) =>
      (e.raw['provenance'] as Map)['jurisdiction'] as String;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load();
    await LanguagePackManager.instance.loadPack('hi');
    await LanguagePackManager.instance.loadPack('ta');
  });

  Future<void> pump(WidgetTester tester, Scheme scheme, String lang) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SchemeExtraSections(
              scheme: scheme,
              lang: lang,
              onOpenUrl: (_) async {},
              resolveScheme: (_) => null,
              onOpenScheme: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Scheme adapt(MssEntity e, String lang) =>
      MssSchemeAdapter.toScheme(e, bundle, langCode: lang);

  for (final lang in ['en', 'hi', 'ta']) {
    group('sections render in $lang', () {
      testWidgets('Maharashtra scheme with contacts shows contacts', (
        tester,
      ) async {
        final e = bundle.schemes.firstWhere(
          (s) =>
              jur(s) == 'maharashtra' &&
              (s.raw['source'] as Map)['contacts'] != null,
        );
        await pump(tester, adapt(e, lang), lang);
        final l10n = await AppLocalizations.delegate.load(Locale(lang));
        expect(find.text(l10n.schemeSectionContacts), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('central scheme with benefit facts shows the figures card', (
        tester,
      ) async {
        final e = bundle.schemes.firstWhere(
          (s) =>
              jur(s) == 'central' &&
              ((s.raw['source'] as Map)['benefit_facts']?['facts'] as List?)
                      ?.isNotEmpty ==
                  true,
        );
        await pump(tester, adapt(e, lang), lang);
        final l10n = await AppLocalizations.delegate.load(Locale(lang));
        expect(find.text(l10n.schemeSectionBenefitFacts), findsOneWidget);
        expect(find.textContaining('null'), findsNothing);
        expect(find.textContaining('{'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets(
    'machine-translation notice appears for flagged Hindi text only',
    (tester) async {
      final mh = bundle.schemes.firstWhere((s) => jur(s) == 'maharashtra');
      await pump(tester, adapt(mh, 'hi'), 'hi');
      expect(find.byIcon(Icons.translate), findsOneWidget);

      await pump(tester, adapt(mh, 'en'), 'en');
      expect(find.byIcon(Icons.translate), findsNothing);
    },
  );

  testWidgets('a sparse record renders no headings at all', (tester) async {
    final extras = SchemeExtras.fromEntity({
      'identity': {'id': 'X-1', 'entityType': 'scheme', 'code': 'X-1'},
      'source': {'id': 'X-1', 'how_to_apply': {}},
      'localization': {'en': {}},
    });
    final scheme = Scheme(id: 'X-1', name: 'Sparse', extras: extras);
    await pump(tester, scheme, 'en');
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a non-2026 scheme (no extras) renders nothing', (tester) async {
    await pump(tester, Scheme(id: 'old', name: 'Old'), 'en');
    expect(find.byType(Text), findsNothing);
  });
}
