import '../../../models/mss_entity.dart';
import '../../../models/scheme_model.dart';
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
          final (
            dNameEn,
            dNameTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            docItem['name'] ?? docItem['title'] ?? docItem,
          );
          final (
            dDescEn,
            dDescTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            docItem['description'] ?? docItem['summary'],
          );
          final (
            dAuthEn,
            dAuthTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            docItem['issuingAuthorityText'] ?? docItem['issuingAuthority'],
          );
          final (
            dCostEn,
            dCostTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            docItem['estimatedCostText'] ?? docItem['estimatedCostInr'],
          );
          final (dRemEn, dRemTa) =
              SchemeAdapterTextUtils.extractMultilingualStr(docItem['remarks']);

          final finalDocName = dNameEn.isNotEmpty
              ? dNameEn
              : (dNameTa.isNotEmpty ? dNameTa : 'Required Document');

          reqDocNames.add(finalDocName);
          docList.add(
            SchemeDocument(
              name: finalDocName,
              nameTa: dNameTa,
              mandatory:
                  (SchemeAdapterTextUtils.textOrNull(
                    docItem['mandatoryText'],
                  )) ??
                  (docItem['mandatory'] == 'required' ||
                          docItem['mandatory'] == true
                      ? 'Yes'
                      : 'No'),
              issuingAuthority: dAuthEn,
              issuingAuthorityTa: dAuthTa,
              description: dDescEn,
              descriptionTa: dDescTa,
              estimatedCost: dCostEn,
              estimatedCostTa: dCostTa,
              remarks: dRemEn,
              remarksTa: dRemTa,
              nameHi: SchemeAdapterTextUtils.extractHi(
                docItem['name'] ?? docItem['title'],
              ),
              descriptionHi: SchemeAdapterTextUtils.extractHi(
                docItem['description'] ?? docItem['summary'],
              ),
              issuingAuthorityHi: SchemeAdapterTextUtils.extractHi(
                docItem['issuingAuthorityText'] ?? docItem['issuingAuthority'],
              ),
              estimatedCostHi: SchemeAdapterTextUtils.extractHi(
                docItem['estimatedCostText'] ?? docItem['estimatedCostInr'],
              ),
              remarksHi: SchemeAdapterTextUtils.extractHi(docItem['remarks']),
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
          final (titleEn, titleTa) =
              SchemeAdapterTextUtils.extractMultilingualStr(step['title']);
          final (
            descEn,
            descTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            step['description'],
          );
          final stepNum = step['stepNumber'] ?? (i + 1);

          final stepEn = titleEn.isNotEmpty
              ? 'Step $stepNum: $titleEn${descEn.isNotEmpty ? " - $descEn" : ""}'
              : (descEn.isNotEmpty ? 'Step $stepNum: $descEn' : '');
          final stepTa = titleTa.isNotEmpty
              ? 'படி $stepNum: $titleTa${descTa.isNotEmpty ? " - $descTa" : ""}'
              : (descTa.isNotEmpty ? 'படி $stepNum: $descTa' : '');

          if (stepTa.isNotEmpty) {
            stepsList.add(stepTa);
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
          final (
            sNameEn,
            sNameTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            sItem['name'] ?? sItem['title'],
          );
          final (
            sCatEn,
            sCatTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            sItem['category'],
            'Government Service',
          );
          final (
            sDescEn,
            sDescTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            sItem['description'],
          );
          final (sPurpEn, sPurpTa) =
              SchemeAdapterTextUtils.extractMultilingualStr(sItem['purpose']);
          final (
            sDeptEn,
            sDeptTa,
          ) = SchemeAdapterTextUtils.extractMultilingualStr(
            sItem['department'],
            issuingBody,
          );
          final (sNotesEn, sNotesTa) =
              SchemeAdapterTextUtils.extractMultilingualStr(sItem['notes']);

          final finalServiceName = sNameEn.isNotEmpty
              ? sNameEn
              : (sNameTa.isNotEmpty ? sNameTa : 'Government Service');

          serviceList.add(
            SchemeService(
              name: finalServiceName,
              nameTa: sNameTa,
              category: sCatEn,
              categoryTa: sCatTa,
              mandatory:
                  sItem['mandatory'] == true ||
                  sItem['mandatory'] == 'required',
              description: sDescEn,
              descriptionTa: sDescTa,
              purpose: sPurpEn,
              purposeTa: sPurpTa,
              department: sDeptEn,
              departmentTa: sDeptTa,
              website:
                  (SchemeAdapterTextUtils.textOrNull(sItem['website'])) ?? '',
              contact:
                  (SchemeAdapterTextUtils.textOrNull(sItem['contact'])) ?? '',
              status:
                  (SchemeAdapterTextUtils.textOrNull(sItem['status'])) ??
                  'ACTIVE',
              notes: sNotesEn,
              notesTa: sNotesTa,
              nameHi: SchemeAdapterTextUtils.extractHi(
                sItem['name'] ?? sItem['title'],
              ),
              categoryHi: SchemeAdapterTextUtils.extractHi(sItem['category']),
              descriptionHi: SchemeAdapterTextUtils.extractHi(
                sItem['description'],
              ),
              purposeHi: SchemeAdapterTextUtils.extractHi(sItem['purpose']),
              departmentHi: SchemeAdapterTextUtils.extractHi(
                sItem['department'],
              ),
              notesHi: SchemeAdapterTextUtils.extractHi(sItem['notes']),
            ),
          );
        }
      }
    }

    if (serviceList.isEmpty) {
      serviceList.add(
        SchemeService(
          name: '$issuingBody Application & Verification Service',
          category: 'Implementing Agency Service',
          mandatory: true,
          description:
              'Single-window application submission, document verification, and subsidy processing.',
          department: issuingBody,
          website:
              (SchemeAdapterTextUtils.textOrNull(appProc['onlineUrl'])) ??
              (SchemeAdapterTextUtils.textOrNull(
                resources['officialWebsiteUrl'],
              )) ??
              '',
          status: 'ACTIVE',
        ),
      );
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
