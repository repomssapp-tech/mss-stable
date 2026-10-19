import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/adapter/scheme_header_resolver.dart';
import 'package:frontend/services/catalog/adapter/scheme_eligibility_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  late List<MssEntity> schemes;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load();
    schemes = bundle.byCatalog['scheme'] ?? [];
  });

  group('Catalog v3.1 Contract Tests (1.37.0-alpha, schemes_json_only)', () {
    test('Shape contract on all 406 schemes in bundle', () {
      expect(
        schemes.length,
        406,
        reason: 'Must have 406 schemes in bundle (274 central + 53 TN + 79 MH)',
      );

      final forbiddenFacetKeys = {'applicable', 'min', 'max', 'range'};

      for (final s in schemes) {
        final content = s.content;

        // 1. Classification is under content, not at entity root
        expect(
          content.containsKey('classification'),
          isTrue,
          reason: '${s.id} must have content.classification',
        );
        expect(
          content['classification'],
          isA<Map<String, dynamic>>(),
          reason: '${s.id} classification must be a Map',
        );

        // 2. content.benefits.benefitTypes is a List
        final benefits = content['benefits'] as Map<String, dynamic>?;
        expect(
          benefits,
          isNotNull,
          reason: '${s.id} must have content.benefits',
        );
        expect(
          benefits!.containsKey('benefitTypes'),
          isTrue,
          reason: '${s.id} must have content.benefits.benefitTypes',
        );
        expect(
          benefits['benefitTypes'],
          isA<List>(),
          reason: '${s.id} benefitTypes must be a List',
        );

        // 3. content.objectives is a List
        expect(
          content.containsKey('objectives'),
          isTrue,
          reason: '${s.id} must have content.objectives',
        );
        expect(
          content['objectives'],
          isA<List>(),
          reason: '${s.id} objectives must be a List',
        );

        // 4. identity.status in {active, closed, unknown}
        final status = (s.identity['status'] as String?)?.toLowerCase();
        expect(
          status,
          isIn(['active', 'closed', 'unknown', 'announced']),
          reason:
              '${s.id} identity.status must be active, closed, unknown, or announced',
        );

        // 5. Facets contain no forbidden keys (applicable, min, max, range)
        final eligibility = content['eligibility'] as Map<String, dynamic>?;
        if (eligibility != null && eligibility.containsKey('facets')) {
          final facets = eligibility['facets'] as Map<String, dynamic>?;
          if (facets != null) {
            for (final entry in facets.entries) {
              expect(
                forbiddenFacetKeys.contains(entry.key.toLowerCase()),
                isFalse,
                reason: '${s.id} facet root key "${entry.key}" is forbidden',
              );
              if (entry.value is Map<String, dynamic>) {
                final subMap = entry.value as Map<String, dynamic>;
                for (final subKey in subMap.keys) {
                  expect(
                    forbiddenFacetKeys.contains(subKey.toLowerCase()),
                    isFalse,
                    reason:
                        '${s.id} facet "${entry.key}" contains forbidden subKey "$subKey"',
                  );
                }
              }
            }
          }
        }
      }
    });

    test(
      'CEN2026-174: SchemeHeaderResolver resolves non-empty ministry and schemeType',
      () {
        final s255 = bundle.byId['CEN2026-174'];
        expect(s255, isNotNull, reason: 'CEN2026-174 must exist in bundle');

        final header = SchemeHeaderResolver.resolve(
          s255!,
          bundle,
          langCode: 'en',
        );

        expect(
          header.ministry,
          isNotEmpty,
          reason: 'CEN2026-174 ministry must be non-empty',
        );
        expect(
          header.schemeType,
          isNotEmpty,
          reason: 'CEN2026-174 schemeType must be non-empty',
        );
        expect(
          header.schemeType.toLowerCase(),
          anyOf('credit_guarantee', 'credit guarantee'),
          reason: 'CEN2026-174 schemeType must resolve to credit guarantee',
        );
      },
    );

    test(
      'CEN2026-174: SchemeEligibilityResolver produces structured facets',
      () {
        final s255 = bundle.byId['CEN2026-174'];
        expect(s255, isNotNull, reason: 'CEN2026-174 must exist in bundle');

        final header = SchemeHeaderResolver.resolve(
          s255!,
          bundle,
          langCode: 'en',
        );

        final eligibility = SchemeEligibilityResolver.resolve(
          s255,
          targetBeneficiary: header.targetBeneficiary,
          langCode: 'en',
        );

        expect(
          eligibility.allowedBusinessTypes,
          containsAll(['micro', 'small', 'medium']),
          reason:
              'CEN2026-174 structured facets must include micro, small, medium',
        );
      },
    );

    test(
      'Graph symmetry: Every child_of relationship has a matching parent_of',
      () {
        final childOfRels = <Map<String, String>>[];
        final parentOfRels = <String, Set<String>>{};

        for (final s in schemes) {
          for (final ref in s.references) {
            final relType =
                (ref['relationType'] ?? ref['relationshipType']) as String?;
            final targetId =
                (ref['entityId'] ?? ref['targetEntityId'] ?? ref['targetId'])
                    as String?;

            if (targetId == null || targetId.isEmpty) continue;

            if (relType == 'child_of') {
              childOfRels.add({'source': s.id, 'target': targetId});
            } else if (relType == 'parent_of') {
              parentOfRels.putIfAbsent(s.id, () => <String>{}).add(targetId);
            }
          }
        }

        // Assert 50 child_of relationships in the 406-scheme bundle (carried over via the legacy supplement)
        expect(
          childOfRels.length,
          50,
          reason: 'Bundle must contain exactly 50 child_of relationships',
        );

        // Assert every child_of (A child_of B) has B parent_of A
        for (final rel in childOfRels) {
          final child = rel['source']!;
          final parent = rel['target']!;

          final hasParentOf = parentOfRels[parent]?.contains(child) ?? false;
          expect(
            hasParentOf,
            isTrue,
            reason: 'Parent $parent must have parent_of targeting child $child',
          );
        }
      },
    );
  });
}
