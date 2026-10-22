import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MssSchemeAdapter Characterization Suite', () {
    late MssCatalogBundle bundle;

    setUpAll(() async {
      bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    });

    test('characterizes canonical PMEGP scheme mapping', () {
      final pmegpEntity = bundle.schemes.firstWhere(
        (s) => s.id == 'CEN2026-085',
        orElse: () => bundle.schemes.first,
      );

      final schemeEn = MssSchemeAdapter.toScheme(
        pmegpEntity,
        bundle,
        langCode: 'en',
      );

      expect(schemeEn.id, pmegpEntity.id);
      expect(schemeEn.isActive, isTrue);
      expect(schemeEn.status, 'ACTIVE');
      expect(schemeEn.name, isNotEmpty);
      expect(schemeEn.governmentLevel, anyOf('Central', contains('Central')));
      expect(schemeEn.state, anyOf('All India', contains('India'), isNotEmpty));
      expect(schemeEn.overview, isNotEmpty);
      expect(schemeEn.benefits, isNotEmpty);
      expect(schemeEn.eligibilityCriteria, isNotEmpty);
      expect(schemeEn.applicationProcess, isNotEmpty);
      expect(schemeEn.documents, isNotEmpty);
      expect(schemeEn.glanceChips, isNotEmpty);

      // Verify Tamil mapping for the same entity
      final schemeTa = MssSchemeAdapter.toScheme(
        pmegpEntity,
        bundle,
        langCode: 'ta',
      );
      expect(schemeTa.id, pmegpEntity.id);
      expect(schemeTa.isActive, isTrue);
      expect(schemeTa.name, isNotEmpty);
      expect(schemeTa.overview, isNotEmpty);
    });

    test('characterizes graph resolution of authorities and institutions', () {
      for (final entity in bundle.schemes.take(20)) {
        final scheme = MssSchemeAdapter.toScheme(entity, bundle);
        expect(scheme.sponsoringBody, isNotEmpty);
        expect(scheme.issuingBody, isNotEmpty);

        final auths = bundle.getAuthoritiesForScheme(entity);
        if (auths.isNotEmpty) {
          expect(scheme.sponsoringBody, isNotEmpty);
        }
      }
    });

    test('characterizes benefits and funding metrics parsing', () {
      bool foundMaxFunding = false;
      bool foundSubsidyPercentage = false;

      for (final entity in bundle.schemes) {
        final scheme = MssSchemeAdapter.toScheme(entity, bundle);
        if (scheme.maxFunding != null && scheme.maxFunding! > 0) {
          foundMaxFunding = true;
        }
        if (scheme.subsidyPercentage != null && scheme.subsidyPercentage! > 0) {
          foundSubsidyPercentage = true;
        }
      }

      expect(
        foundMaxFunding,
        isTrue,
        reason: 'At least one scheme has parsed maxFunding',
      );
      expect(
        foundSubsidyPercentage,
        isTrue,
        reason: 'At least one scheme has parsed subsidyPercentage',
      );
    });

    test('characterizes closed status on synthetic entity', () {
      final closedEntity = MssEntity.fromJson({
        'identity': {
          'id': 'SCH_TEST_CLOSED',
          'code': 'TEST_CLOSED',
          'entityType': 'scheme',
          'status': 'CLOSED',
          'name': 'Closed Test Scheme',
        },
        'content': {
          'classification': {
            'government': {'level': 'Central'},
          },
          'overview': {'summary': 'Closed scheme description'},
          'eligibility': {
            'criteria': ['Eligible if active'],
          },
          'benefits': {'summary': 'No active benefits'},
        },
      });

      final scheme = MssSchemeAdapter.toScheme(closedEntity, bundle);
      expect(scheme.status, 'CLOSED');
      expect(scheme.isActive, isFalse);
    });

    test('characterizes fallback defaults for sparse synthetic entity', () {
      final sparseEntity = MssEntity.fromJson({
        'identity': {
          'id': 'SCH_TEST_SPARSE',
          'code': 'TEST_SPARSE',
          'entityType': 'scheme',
          'status': '',
        },
        'content': {
          'classification': {
            'government': {'level': 'State'},
          },
        },
      });

      final scheme = MssSchemeAdapter.toScheme(sparseEntity, bundle);
      // Empty status defaults to ACTIVE
      expect(scheme.status, 'ACTIVE');
      expect(scheme.isActive, isTrue);
      // Name falls back to code
      expect(scheme.name, 'TEST_SPARSE');
      // No coverage given: the state stays unknown (it used to default to
      // Tamil Nadu for any non-central level, issue #143).
      expect(scheme.state, isEmpty);
      expect(scheme.appliesNationally, isNull);
      expect(scheme.stateCodes, isEmpty);
      // Overview falls back to synthetic overview
      expect(
        scheme.overview,
        contains(
          'Government scheme providing financial and institutional support',
        ),
      );
      // Benefits falls back to default text
      expect(
        scheme.benefits,
        contains(
          'Provides financial assistance, subsidies, or institutional support',
        ),
      );
    });

    test('characterizes document checklist and mandatory flag mapping', () {
      final docEntity = MssEntity.fromJson({
        'identity': {
          'id': 'SCH_TEST_DOCS',
          'code': 'TEST_DOCS',
          'entityType': 'scheme',
          'status': 'ACTIVE',
          'name': 'Document Test Scheme',
        },
        'content': {
          'documents': [
            {
              'name': 'Aadhaar Card',
              'mandatory': true,
              'type': 'Identity Proof',
            },
            {
              'name': 'Project Report',
              'mandatory': false,
              'type': 'Financial Document',
            },
          ],
        },
      });

      final scheme = MssSchemeAdapter.toScheme(docEntity, bundle);
      expect(scheme.documents.length, 2);
      expect(scheme.documents[0].name, 'Aadhaar Card');
      expect(scheme.documents[0].isMandatory, isTrue);
      expect(scheme.documents[1].name, 'Project Report');
      expect(scheme.documents[1].isMandatory, isFalse);

      // requiredDocuments list contains all mapped document names
      expect(scheme.requiredDocuments, contains('Aadhaar Card'));
      expect(scheme.requiredDocuments, contains('Project Report'));
    });

    test('characterizes application workflow steps mapping', () {
      final procEntity = MssEntity.fromJson({
        'identity': {
          'id': 'SCH_TEST_PROC',
          'code': 'TEST_PROC',
          'entityType': 'scheme',
          'status': 'ACTIVE',
          'name': 'Process Test Scheme',
        },
        'content': {
          'applicationProcess': {
            'steps': [
              {
                'step': 1,
                'title': 'Online Registration',
                'description': 'Register on the portal',
              },
              {
                'step': 2,
                'title': 'Upload Documents',
                'description': 'Attach required certificates',
              },
            ],
          },
        },
      });

      final scheme = MssSchemeAdapter.toScheme(procEntity, bundle);
      expect(scheme.applicationProcess.length, 2);
      expect(scheme.applicationProcess[0], contains('Online Registration'));
      expect(scheme.applicationProcess[1], contains('Upload Documents'));
    });
  });
}
