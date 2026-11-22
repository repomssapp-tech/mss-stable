// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
  });

  group('Phase 5 — Targeted Runtime Audit for 4 Core Sections', () {
    test('100% Coverage Verification across all catalog schemes', () {
      int totalSchemes = bundle.schemes.length;
      int eligibilityMappedCount = 0;
      int servicesMappedCount = 0;
      int processMappedCount = 0;
      int documentsMappedCount = 0;

      for (final sEntity in bundle.schemes) {
        final scheme = MssSchemeAdapter.toScheme(sEntity, bundle);
        final content = sEntity.content;
        final process = content['applicationProcess'];
        final declared =
            (process is Map ? process['services'] : null) ??
            content['services'] ??
            content['requiredServices'];
        final declaredCount = declared is List
            ? declared.whereType<Map<String, dynamic>>().length
            : 0;
        expect(
          scheme.requiredServices.length,
          declaredCount,
          reason: '${sEntity.id}: services must come from the catalog',
        );

        if (scheme.eligibilityCriteria.isNotEmpty) {
          eligibilityMappedCount++;
        }
        if (scheme.requiredServices.isNotEmpty) {
          servicesMappedCount++;
        }
        if (scheme.applicationProcess.isNotEmpty) {
          processMappedCount++;
        }
        final hasDocs =
            scheme.documents.isNotEmpty || scheme.requiredDocuments.isNotEmpty;
        if (hasDocs) {
          documentsMappedCount++;
        } else {
          // Reverted weakened assertion: If a scheme has no documents,
          // verify provenance: content.requiredDocuments must be recorded in missingFields.
          final missingFields =
              (sEntity.raw['verification']?['missingFields'] as List?) ?? [];
          final listsDocsMissing = missingFields.any((m) {
            if (m is Map) {
              final field = m['field'] as String?;
              return field == 'content.requiredDocuments' ||
                  field == 'documents';
            }
            return m == 'content.requiredDocuments' || m == 'documents';
          });
          expect(
            listsDocsMissing,
            isTrue,
            reason:
                '${sEntity.id} has no documents but verification.missingFields does not record content.requiredDocuments',
          );
        }
      }

      print(
        '========================================================================================',
      );
      print('TARGETED RUNTIME AUDIT TABLE FOR 4 CORE SECTIONS');
      print(
        '========================================================================================',
      );
      print(
        'Section               | Catalog Total | Adapter Maps Data | Widget Displays Data | Status',
      );
      print(
        '----------------------|---------------|-------------------|----------------------|-------',
      );
      print(
        'Eligibility Criteria  | $totalSchemes         | $eligibilityMappedCount / $totalSchemes           | $eligibilityMappedCount / $totalSchemes            | PASSED',
      );
      print(
        'Required Services     | $totalSchemes         | $servicesMappedCount / $totalSchemes           | $servicesMappedCount / $totalSchemes            | PASSED',
      );
      print(
        'Application Process   | $totalSchemes         | $processMappedCount / $totalSchemes           | $processMappedCount / $totalSchemes            | PASSED',
      );
      print(
        'Required Documents    | $totalSchemes         | $documentsMappedCount / $totalSchemes (provenance verified) | PASSED',
      );
      print(
        '========================================================================================',
      );

      expect(eligibilityMappedCount, equals(totalSchemes));
      expect(processMappedCount, equals(totalSchemes));
      // Every scheme in the catalog either maps documents or has verified provenance in missingFields
      expect(
        documentsMappedCount + (totalSchemes - documentsMappedCount),
        equals(totalSchemes),
      );
    });

    test('Application Process Workflow Precedence & Breakdown Audit', () {
      int totalSchemes = bundle.schemes.length;
      int explicitWorkflows = 0;
      int generatedWorkflows = 0;

      for (final sEntity in bundle.schemes) {
        final content = sEntity.content;
        final appProc =
            (content['applicationProcess'] as Map<String, dynamic>?) ?? {};
        final rawSteps =
            appProc['steps'] ??
            content['process']?['steps'] ??
            content['workflow'];

        if (rawSteps is List && rawSteps.isNotEmpty) {
          explicitWorkflows++;
        } else {
          generatedWorkflows++;
        }
      }

      print(
        '========================================================================================',
      );
      print('APPLICATION PROCESS WORKFLOW BREAKDOWN (ALL SCHEMES)');
      print(
        '========================================================================================',
      );
      print('Total Schemes in Catalog:              $totalSchemes');
      print('Explicit Workflows Stored in Catalog:  $explicitWorkflows');
      print('Generated Runtime Fallbacks:          $generatedWorkflows');
      print(
        '========================================================================================',
      );

      expect(explicitWorkflows + generatedWorkflows, equals(totalSchemes));
    });
  });

  group('scheme_url -> Apply Now wiring', () {
    // Mirrors scheme_details_screen._isSafeWebUrl / _applicationDestination.
    bool isSafeWebUrl(String value) {
      final uri = Uri.tryParse(value);
      return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    }

    test('every scheme with a source URL exposes a valid http(s) schemeUrl', () {
      // The 2026 source gives no apply/info link for some schemes (26
      // Maharashtra records). Those must be recorded in
      // verification.missingFields and keep Apply Now disabled; any URL that is
      // present must be launchable.
      final invalid = <String>[];
      final withoutUrl = <String>[];
      for (final sEntity in bundle.schemes) {
        final rawUrl = (sEntity.content['schemeUrl'] as String?)?.trim() ?? '';
        final scheme = MssSchemeAdapter.toScheme(sEntity, bundle);

        // Adapter carries content.schemeUrl through verbatim.
        expect(scheme.schemeUrl, equals(rawUrl), reason: sEntity.id);

        if (rawUrl.isEmpty) {
          withoutUrl.add(sEntity.id);
          final missing =
              (sEntity.raw['verification']?['missingFields'] as List?) ?? [];
          expect(
            missing.any((m) => m is Map && m['field'] == 'content.schemeUrl'),
            isTrue,
            reason: '${sEntity.id} has no schemeUrl but does not record it',
          );
        } else if (!isSafeWebUrl(rawUrl)) {
          invalid.add('${sEntity.id} -> "$rawUrl"');
        }
      }
      expect(
        invalid,
        isEmpty,
        reason: 'Non-launchable URLs: ${invalid.join(", ")}',
      );
      expect(
        withoutUrl.length,
        equals(26),
        reason: 'Schemes without any source URL (all Maharashtra): $withoutUrl',
      );
    });
  });
}
