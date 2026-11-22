import '../../../models/mss_entity.dart';
import '../../../models/scheme_model.dart';
import '../../../utils/language_names.dart';
import 'scheme_adapter_text_utils.dart';

/// Immutable container holding resolved documents, application process steps,
/// services, URLs, and helplines/FAQs.
class SchemeResourcesData {
  final List<SchemeDocument> docList;
  final List<String> reqDocNames;
  final List<String> stepsList;
  final List<SchemeService> serviceList;
  final String applicationFee;
  final String processingDurationDays;
  final String intakeTimelineText;
  final String applicationMode;
  final List<Map<String, String>> faqList;
  final String officialWebsite;
  final String applicationUrl;
  final String guidelinesUrl;
  final String logoUrl;
  final String schemeUrl;
  final Map<String, String> helplineContactsMap;

  const SchemeResourcesData({
    required this.docList,
    required this.reqDocNames,
    required this.stepsList,
    required this.serviceList,
    required this.applicationFee,
    required this.processingDurationDays,
    required this.intakeTimelineText,
    required this.applicationMode,
    required this.faqList,
    required this.officialWebsite,
    required this.applicationUrl,
    required this.guidelinesUrl,
    required this.logoUrl,
    required this.schemeUrl,
    required this.helplineContactsMap,
  });
}

/// Resolves documents, workflow steps, implementing agency services, URLs,
/// and support contacts for a scheme entity.
class SchemeResourcesResolver {
  SchemeResourcesResolver._();

  /// A reader for one record's multilingual fields: returns the English text
  /// and files the other languages' text under the field name in [into].
  static String Function(String, dynamic, [String]) _reader(
    Map<String, Map<String, String>> into,
  ) => (field, raw, [defaultStr = '']) {
    final (en, translations) = SchemeAdapterTextUtils.extractMultilingual(
      raw,
      defaultStr,
    );
    if (translations.isNotEmpty) into[field] = translations;
    return en;
  };

  static SchemeResourcesData resolve(
    MssEntity entity, {
    required String issuingBody,
    required String langCode,
  }) {
    final content = entity.content;
    final resources =
        (SchemeAdapterTextUtils.mapOrNull(content['resources'])) ?? {};
    final appProc =
        (SchemeAdapterTextUtils.mapOrNull(content['applicationProcess'])) ?? {};
    final appTimeline =
        (SchemeAdapterTextUtils.mapOrNull(content['applicationTimeline'])) ??
        {};
    final contactsObj =
        (SchemeAdapterTextUtils.mapOrNull(content['contacts'])) ?? {};

    // ── 7. Required Documents ──────────────────────────────────────────
    final docList = <SchemeDocument>[];
    final reqDocNames = <String>[];

    final rawDocs = SchemeAdapterTextUtils.asList(
      content['requiredDocuments'] ?? content['documents'],
    );
    if (rawDocs != null) {
      for (final docItem in rawDocs) {
        if (docItem is Map<String, dynamic>) {
          final translations = <String, Map<String, String>>{};
          final read = _reader(translations);
          final dNameEn = read(
            'name',
            docItem['name'] ?? docItem['title'] ?? docItem,
          );
          final dDescEn = read(
            'description',
            docItem['description'] ?? docItem['summary'],
          );
          final dAuthEn = read(
            'issuingAuthority',
            docItem['issuingAuthorityText'] ?? docItem['issuingAuthority'],
          );
          final dCostEn = read(
            'estimatedCost',
            docItem['estimatedCostText'] ?? docItem['estimatedCostInr'],
          );
          final dRemEn = read('remarks', docItem['remarks']);

          final finalDocName = SchemeAdapterTextUtils.firstText([
            dNameEn,
            ...?translations['name']?.values,
            'Required Document',
          ]);

          reqDocNames.add(finalDocName);
          docList.add(
            SchemeDocument(
              name: finalDocName,
              mandatory:
                  (SchemeAdapterTextUtils.textOrNull(
                    docItem['mandatoryText'],
                  )) ??
                  (docItem['mandatory'] == 'required' ||
                          docItem['mandatory'] == true
                      ? 'Yes'
                      : 'No'),
              issuingAuthority: dAuthEn,
              description: dDescEn,
              estimatedCost: dCostEn,
              remarks: dRemEn,
              translations: translations,
              sourceUrl:
                  (SchemeAdapterTextUtils.textOrNull(docItem['sourceUrl'])) ??
                  '',
              validityMonths: docItem['validityMonths']?.toString() ?? '',
              downloadTemplateUrl:
                  (SchemeAdapterTextUtils.textOrNull(
                    docItem['downloadTemplateUrl'],
                  )) ??
                  '',
              sampleCopyUrl:
                  (SchemeAdapterTextUtils.textOrNull(
                    docItem['sampleCopyUrl'],
                  )) ??
                  '',
              verificationPortalUrl:
                  (SchemeAdapterTextUtils.textOrNull(
                    docItem['verificationPortalUrl'],
                  )) ??
                  '',
            ),
          );
        }
      }
    }

    // ── 8. Application Process & Required Services ────────────────────
    final stepsList = <String>[];
    final rawSteps = SchemeAdapterTextUtils.asList(
      appProc['steps'] ?? content['process']?['steps'] ?? content['workflow'],
    );
    if (rawSteps != null && rawSteps.isNotEmpty) {
      for (int i = 0; i < rawSteps.length; i++) {
        final step = rawSteps[i];
        if (step is Map<String, dynamic>) {
          final (titleEn, titles) = SchemeAdapterTextUtils.extractMultilingual(
            step['title'],
          );
          final (descEn, descs) = SchemeAdapterTextUtils.extractMultilingual(
            step['description'],
          );
          final stepNum = step['stepNumber'] ?? (i + 1);

          final stepEn = titleEn.isNotEmpty
              ? 'Step $stepNum: $titleEn${descEn.isNotEmpty ? " - $descEn" : ""}'
              : (descEn.isNotEmpty ? 'Step $stepNum: $descEn' : '');
          final title = titles[langCode] ?? '';
          final desc = descs[langCode] ?? '';
          final label = stepLabel(langCode, stepNum);
          final stepLocal = title.isNotEmpty
              ? '$label $title${desc.isNotEmpty ? " - $desc" : ""}'
              : (desc.isNotEmpty ? '$label $desc' : '');

          if (stepLocal.isNotEmpty) {
            stepsList.add(stepLocal);
          } else if (stepEn.isNotEmpty) {
            stepsList.add(stepEn);
          }
        } else if (step is String && step.isNotEmpty) {
          stepsList.add('Step ${i + 1}: $step');
        }
      }
    }

    if (stepsList.isEmpty) {
      final modeText =
          (SchemeAdapterTextUtils.textOrNull(appProc['modeText']))?.trim() ??
          (SchemeAdapterTextUtils.textOrNull(appProc['mode']))?.trim() ??
          '';
      final onlineUrl =
          (SchemeAdapterTextUtils.textOrNull(appProc['onlineUrl']))?.trim() ??
          '';
      final offlineDetails =
          (SchemeAdapterTextUtils.textOrNull(
            appProc['offlineDetails'],
          ))?.trim() ??
          '';

      if (modeText.isNotEmpty) {
        stepsList.add('Application Mode: $modeText');
      }
      if (onlineUrl.isNotEmpty) {
        stepsList.add('Apply Online: $onlineUrl');
      } else if (offlineDetails.isNotEmpty) {
        stepsList.add('Offline Process: $offlineDetails');
      }

      if (stepsList.isEmpty) {
        stepsList.add(
          'Current application process not verified for this scheme. '
          'Please refer to the official source above for the latest procedure.',
        );
      }
    }

    final serviceList = <SchemeService>[];
    final rawServices = SchemeAdapterTextUtils.asList(
      appProc['services'] ?? content['services'] ?? content['requiredServices'],
    );
    if (rawServices != null && rawServices.isNotEmpty) {
      for (final sItem in rawServices) {
        if (sItem is Map<String, dynamic>) {
          final translations = <String, Map<String, String>>{};
          final read = _reader(translations);
          final sNameEn = read('name', sItem['name'] ?? sItem['title']);
          final sCatEn = read(
            'category',
            sItem['category'],
            'Government Service',
          );
          final sDescEn = read('description', sItem['description']);
          final sPurpEn = read('purpose', sItem['purpose']);
          final sDeptEn = read('department', sItem['department'], issuingBody);
          final sNotesEn = read('notes', sItem['notes']);

          final finalServiceName = SchemeAdapterTextUtils.firstText([
            sNameEn,
            ...?translations['name']?.values,
            'Government Service',
          ]);

          serviceList.add(
            SchemeService(
              name: finalServiceName,
              category: sCatEn,
              mandatory:
                  sItem['mandatory'] == true ||
                  sItem['mandatory'] == 'required',
              description: sDescEn,
              purpose: sPurpEn,
              department: sDeptEn,
              website:
                  (SchemeAdapterTextUtils.textOrNull(sItem['website'])) ?? '',
              contact:
                  (SchemeAdapterTextUtils.textOrNull(sItem['contact'])) ?? '',
              status:
                  (SchemeAdapterTextUtils.textOrNull(sItem['status'])) ??
                  'ACTIVE',
              notes: sNotesEn,
              translations: translations,
            ),
          );
        }
      }
    }

    final applicationFee =
        (SchemeAdapterTextUtils.textOrNull(appProc['applicationFeeText'])) ??
        (appProc['applicationFeeInr'] != null
            ? '₹${appProc['applicationFeeInr']}'
            : 'Nil');
    final processingDurationDays =
        appTimeline['processingDurationDays']?.toString() ?? '30';
    final intakeTimelineText =
        (SchemeAdapterTextUtils.textOrNull(appTimeline['text'])) ??
        'Rolling intake throughout financial year';

    final applicationMode =
        (SchemeAdapterTextUtils.textOrNull(appProc['modeText'])) ??
        (SchemeAdapterTextUtils.textOrNull(appProc['mode'])) ??
        'Online / Offline';

    // ── 10. Official Links & Helplines ───────────────────────────────
    final faqList = <Map<String, String>>[];
    final rawFaqs = SchemeAdapterTextUtils.asList(content['faqs']);
    if (rawFaqs != null) {
      for (final f in rawFaqs) {
        if (f is Map<String, dynamic>) {
          final q = SchemeAdapterTextUtils.getLocalizedText(
            f['question'],
            langCode,
          );
          final a = SchemeAdapterTextUtils.getLocalizedText(
            f['answer'],
            langCode,
          );
          if (q.isNotEmpty && a.isNotEmpty) {
            faqList.add({
              'question': q,
              'answer': a,
              'category':
                  (SchemeAdapterTextUtils.textOrNull(f['category'])) ?? '',
            });
          }
        }
      }
    }

    final sourcesList = SchemeAdapterTextUtils.asList(content['sources']);
    String? officialWebsiteRaw =
        (SchemeAdapterTextUtils.textOrNull(resources['officialWebsiteUrl'])) ??
        (SchemeAdapterTextUtils.textOrNull(
          resources['applicationPortalUrl'],
        )) ??
        (SchemeAdapterTextUtils.textOrNull(resources['schemePortalUrl'])) ??
        (SchemeAdapterTextUtils.textOrNull(resources['portalUrl'])) ??
        (SchemeAdapterTextUtils.textOrNull(appProc['onlineUrl']));

    String? guidelinesUrlRaw = (SchemeAdapterTextUtils.textOrNull(
      resources['guidelinesPdfUrl'],
    ));

    if (sourcesList != null) {
      for (final s in sourcesList) {
        if (s is Map<String, dynamic>) {
          final type =
              (SchemeAdapterTextUtils.textOrNull(s['sourceType']) ?? '')
                  .toLowerCase();
          final url = SchemeAdapterTextUtils.textOrNull(s['url']);
          if (url != null && url.isNotEmpty) {
            if (officialWebsiteRaw == null || officialWebsiteRaw.isEmpty) {
              if (type.contains('website') ||
                  type.contains('portal') ||
                  s['isPrimary'] == true) {
                officialWebsiteRaw = url;
              }
            }
            if (guidelinesUrlRaw == null || guidelinesUrlRaw.isEmpty) {
              if (type.contains('guideline') ||
                  type.contains('pdf') ||
                  url.endsWith('.pdf')) {
                guidelinesUrlRaw = url;
              }
            }
          }
        }
      }
    }

    // No silent fallback: a scheme with no verified source URL keeps an
    // empty officialWebsite. The UI then disables the Apply / Source
    // buttons (see _BottomActionBar `applyEnabled` and
    // _buildOfficialSourceCard) instead of sending the user to an
    // unrelated government homepage.
    final officialWebsite =
        (officialWebsiteRaw != null && officialWebsiteRaw.trim().isNotEmpty)
        ? officialWebsiteRaw.trim()
        : '';
    final applicationUrl =
        (SchemeAdapterTextUtils.textOrNull(appProc['onlineUrl'])) ??
        (SchemeAdapterTextUtils.textOrNull(
          resources['applicationPortalUrl'],
        )) ??
        officialWebsite;
    final guidelinesUrl = guidelinesUrlRaw ?? '';
    final logoUrl =
        (SchemeAdapterTextUtils.textOrNull(resources['logoUrl'])) ?? '';

    // catalog.scheme.scheme_url, mirrored into record_json.content.schemeUrl.
    // Authoritative "Apply Now" destination -- used directly, no fallback.
    final schemeUrl =
        (SchemeAdapterTextUtils.textOrNull(content['schemeUrl']))?.trim() ?? '';

    final helplineContactsMap = <String, String>{};
    if (contactsObj['helplines'] is List) {
      for (final h in contactsObj['helplines']) {
        if (h is Map) {
          final title = h['title'] ?? h['name'] ?? 'Helpline';
          final phone = h['phone'] ?? h['number'] ?? '';
          if (phone.toString().isNotEmpty) {
            helplineContactsMap[title.toString()] = phone.toString();
          }
        }
      }
    }

    return SchemeResourcesData(
      docList: docList,
      reqDocNames: reqDocNames,
      stepsList: stepsList,
      serviceList: serviceList,
      applicationFee: applicationFee,
      processingDurationDays: processingDurationDays,
      intakeTimelineText: intakeTimelineText,
      applicationMode: applicationMode,
      faqList: faqList,
      officialWebsite: officialWebsite,
      applicationUrl: applicationUrl,
      guidelinesUrl: guidelinesUrl,
      logoUrl: logoUrl,
      schemeUrl: schemeUrl,
      helplineContactsMap: helplineContactsMap,
    );
  }
}
