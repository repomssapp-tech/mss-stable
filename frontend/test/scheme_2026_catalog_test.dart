import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/models/scheme_extras.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/controllers/scheme_catalog_controller.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';
import 'package:frontend/services/catalog/scheme_id_migration.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

/// Integrity and behaviour of the catalog built from schemes_json_only
/// (release 1.37.0-alpha): counts, languages per jurisdiction, preservation of
/// the verbatim source, the extras view, saved-id migration and the queued
/// catalog reload.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  late List<MssEntity> schemes;

  String jurisdictionOf(MssEntity e) =>
      (e.raw['provenance'] as Map)['jurisdiction'] as String;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load();
    schemes = bundle.schemes;
  });

  group('catalog integrity', () {
    test('406 unique schemes: 274 central, 53 Tamil Nadu, 79 Maharashtra', () {
      expect(schemes.length, 406);
      expect(schemes.map((s) => s.id).toSet().length, 406);
      final byJur = <String, int>{};
      for (final s in schemes) {
        byJur.update(jurisdictionOf(s), (n) => n + 1, ifAbsent: () => 1);
      }
      expect(byJur, {'central': 274, 'tamil_nadu': 53, 'maharashtra': 79});
    });

    test('content languages per jurisdiction match the agreed mapping', () {
      final langs = <String, Set<String>>{};
      for (final s in schemes) {
        langs
            .putIfAbsent(jurisdictionOf(s), () => {})
            .addAll((s.raw['localization'] as Map).keys.cast<String>());
      }
      expect(langs['central'], {'en', 'hi', 'mr', 'ta'});
      expect(langs['tamil_nadu'], {'en', 'hi', 'mr', 'ta'});
      // Marathi is preserved in the data but not offered in the UI.
      expect(langs['maharashtra'], {'en', 'hi', 'mr'});
    });

    test(
      'every scheme keeps its verbatim source record and an English name',
      () {
        for (final s in schemes) {
          final src = s.raw['source'];
          expect(src, isA<Map>(), reason: '${s.id} must keep source');
          expect((src as Map)['id'], s.id);
          expect(s.getLocalizedName('en'), isNotEmpty, reason: s.id);
        }
      },
    );

    test('no localized value is a raw language map or stray object', () {
      const objectKeys = {'contacts'}; // intentional structured value
      for (final s in schemes) {
        final loc = s.raw['localization'] as Map<String, dynamic>;
        for (final entry in loc.entries) {
          (entry.value as Map<String, dynamic>).forEach((k, v) {
            if (objectKeys.contains(k)) return;
            expect(
              v is String || v is List,
              isTrue,
              reason: '${s.id}.${entry.key}.$k is ${v.runtimeType}',
            );
          });
        }
      }
    });

    test(
      'schemes without a counterpart in a language fall back to English',
      () {
        // Maharashtra records carry no Tamil.
        final mh = schemes.firstWhere(
          (s) => jurisdictionOf(s) == 'maharashtra',
        );
        expect(mh.getLocalizedName('ta'), mh.getLocalizedName('en'));
      },
    );

    test('dataset origin and where a scheme applies are separate fields', () {
      Map gov(MssEntity e) =>
          (e.content['classification'] as Map)['government'] as Map;
      for (final s in schemes) {
        expect(gov(s)['originDataset'], jurisdictionOf(s), reason: s.id);
        expect(gov(s)['appliesNationally'], isA<bool>(), reason: s.id);
        if (gov(s)['appliesNationally'] == true) {
          expect(gov(s)['states'], isEmpty, reason: '${s.id} is national');
        }
      }
      Map byId(String id) => gov(schemes.firstWhere((s) => s.id == id));
      // An all-India central scheme filed in the Tamil Nadu dataset applies
      // everywhere, not just in Tamil Nadu.
      expect(byId('TN2026-049')['appliesNationally'], isTrue);
      expect(byId('TN2026-049')['states'], isEmpty);
      // A centrally sponsored mission run by Tamil Nadu applies only there.
      expect(byId('TN2026-044')['level'], 'state');
      expect(byId('TN2026-044')['sourceLevel'], 'central_state');
      expect(byId('TN2026-044')['states'], ['IN-TN']);
    });

    test('each legacy code appears once per scheme', () {
      for (final s in schemes) {
        final codes = [
          for (final lc in s.identity['legacyCodes'] as List)
            (lc as Map)['code'],
        ];
        expect(codes.length, codes.toSet().length, reason: s.id);
      }
    });
  });

  group('SchemeExtras', () {
    SchemeExtras extrasOf(MssEntity e) => SchemeExtras.fromEntity(e.raw);

    test('contacts, portal fallback and links are exposed', () {
      final mh = schemes.where((s) => jurisdictionOf(s) == 'maharashtra');
      final withContacts = mh.firstWhere(
        (s) => extrasOf(s).contacts('en').isNotEmpty,
      );
      final lines = extrasOf(withContacts).contacts('en');
      expect(
        lines.map((l) => l.key),
        anyOf(contains('phone'), contains('email')),
      );
      expect(lines.every((l) => l.value.isNotEmpty), isTrue);

      final withPortal = mh.firstWhere(
        (s) => (s.content['portalInfo'] as Map?) != null,
      );
      expect(
        extrasOf(withPortal).links('en').map((l) => l.kind),
        contains('portal'),
      );
    });

    test('benefit facts carry numeric metrics', () {
      final withFacts = schemes.firstWhere(
        (s) => extrasOf(s).benefitFacts('en').isNotEmpty,
      );
      final fact = extrasOf(withFacts).benefitFacts('en').first;
      expect(fact.metrics.isNotEmpty || fact.notes.isNotEmpty, isTrue);
    });

    test('machine-translation flag only where the source sets it', () {
      final mh = schemes.firstWhere((s) => jurisdictionOf(s) == 'maharashtra');
      final central = schemes.firstWhere((s) => jurisdictionOf(s) == 'central');
      expect(extrasOf(mh).isMachineTranslated('hi'), isTrue);
      expect(extrasOf(central).isMachineTranslated('hi'), isFalse);
    });

    test('legacy codes survive for the private-AI knowledge base', () {
      final pmegp = schemes.firstWhere((s) => s.id == 'CEN2026-085');
      expect(extrasOf(pmegp).legacyCodes, contains('IN130'));
    });

    test('unknown future keys do not break parsing and stay in source', () {
      final raw = {
        'identity': {'id': 'X-1', 'entityType': 'scheme', 'code': 'X-1'},
        'source': {
          'id': 'X-1',
          'brand_new_field': {
            'nested': [1, 2, 3],
          },
          'how_to_apply': {'application_status': 'open'},
        },
        'localization': {'en': {}},
      };
      final extras = SchemeExtras.fromEntity(raw);
      expect(extras.applicationStatus, 'open');
      expect(extras.contacts('en'), isEmpty);
      expect((raw['source'] as Map)['brand_new_field'], isNotNull);
      expect(MssEntity.fromJson(raw).id, 'X-1');
    });

    test('adapter carries extras onto the Scheme model', () {
      final e = schemes.firstWhere((s) => s.id == 'CEN2026-085');
      final scheme = MssSchemeAdapter.toScheme(e, bundle);
      expect(scheme.extras.isEmpty, isFalse);
      expect(scheme.extras.jurisdiction, 'central');
    });
  });

  group('saved-id migration', () {
    late Map<String, String> idMap;
    late Set<String> known;

    setUpAll(() {
      idMap = bundle.schemeIdMap;
      known = {for (final s in schemes) s.id};
    });

    test('the id map ships inside the bundle (no side file)', () async {
      SchemeIdMigration.resetForTest();
      expect(idMap.length, greaterThan(800));
      expect(await SchemeIdMigration.load(), idMap);
      expect(File('assets/catalog/scheme_id_map.json').existsSync(), isFalse);
    });

    test('every new id is reachable from the map; map targets all exist', () {
      expect(known.difference(idMap.values.toSet()), isEmpty);
      expect(idMap.values.toSet().difference(known), isEmpty);
    });

    test('old ids and legacy codes are rewritten, order kept, deduped', () {
      final out = SchemeIdMigration.migrate(
        ['SCH000130', 'IN130', 'TN130', 'CEN2026-023'],
        idMap,
        known,
      );
      expect(out, ['CEN2026-085', 'CEN2026-023']);
    });

    test(
      'a retired pre-2026 scheme is dropped; unknown non-legacy ids stay',
      () {
        // SCH000094 (MCDP) has no counterpart in the 2026 catalog.
        expect(SchemeIdMigration.migrate(['SCH000094'], idMap, known), isEmpty);
        expect(
          SchemeIdMigration.migrate(['some-future-id'], idMap, known),
          isNull,
          reason: 'not a pre-2026 id, so it must not be erased',
        );
      },
    );

    test('already-migrated lists are untouched (idempotent)', () {
      expect(
        SchemeIdMigration.migrate(['CEN2026-085', 'TN2026-001'], idMap, known),
        isNull,
      );
    });
  });

  group('queued catalog reload', () {
    test('a load requested mid-flight is re-run, not dropped', () async {
      SchemeRepository.instance.clearCache();
      final controller = SchemeCatalogController();
      final profile = UserProfile();

      final first = controller.loadSchemes(langCode: 'en', profile: profile);
      // Arrives while the first load is still running.
      final second = controller.loadSchemes(
        langCode: 'hi',
        profile: profile,
        forceRefresh: true,
      );
      await Future.wait([first, second]);

      expect(controller.schemesLoading, isFalse);
      expect(controller.allSchemes.length, 406);
      // The repository was re-adapted for the later (Hindi) request, and
      // language-agnostic callers now reuse that list instead of flipping the
      // cache back to English.
      final reused = await SchemeRepository.instance.getAllSchemes();
      expect(identical(reused, controller.allSchemes), isTrue);
    });
  });
}
