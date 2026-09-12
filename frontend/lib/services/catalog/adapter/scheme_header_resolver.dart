import '../../../models/mss_entity.dart';
import '../mss_catalog_bundle.dart';
import 'scheme_adapter_text_utils.dart';

/// Immutable container holding resolved header, classification, authority,
/// overview, and glance chip data for a scheme.
class SchemeHeaderData {
  final String statusStr;
  final bool isActive;
  final String name;
  final String nameTa;
  final String shortName;
  final String finalFullName;
  final String ministry;
  final String department;
  final String implementingAgency;
  final String sponsoringBody;
  final String issuingBody;
  final String governmentLevel;
  final String state;
  final String sector;
  final String schemeType;
  final String category;
  final String districtApplicable;
  final String overviewEn;
  final String overviewTa;
  final String objectivesEn;
  final String targetBeneficiary;
  final Set<String> glanceChips;

  const SchemeHeaderData({
    required this.statusStr,
    required this.isActive,
    required this.name,
    required this.nameTa,
    required this.shortName,
    required this.finalFullName,
    required this.ministry,
    required this.department,
    required this.implementingAgency,
    required this.sponsoringBody,
    required this.issuingBody,
    required this.governmentLevel,
    required this.state,
    required this.sector,
    required this.schemeType,
    required this.category,
    required this.districtApplicable,
    required this.overviewEn,
    required this.overviewTa,
    required this.objectivesEn,
    required this.targetBeneficiary,
    required this.glanceChips,
  });
}

/// Resolves header identity, graph authorities, classifications, overview,
/// and at-a-glance chips for a scheme entity.
class SchemeHeaderResolver {
  SchemeHeaderResolver._();

  static SchemeHeaderData resolve(
    MssEntity entity,
    MssCatalogBundle bundle, {
    required String langCode,
  }) {
    final content = entity.content;
    final classification =
        (content['classification'] as Map<String, dynamic>?) ?? {};
    final gov = (classification['government'] as Map<String, dynamic>?) ?? {};
    final overviewObj = (content['overview'] as Map<String, dynamic>?) ?? {};
    final targetBeneficiariesObj =
        (content['targetBeneficiaries'] as Map<String, dynamic>?) ?? {};
    final eligibilityTextObj =
        (content['eligibilityText'] as Map<String, dynamic>?) ?? {};

    // ── 1. Status & Header Information ──────────────────────────────────
    final rawStatus = entity.status.toLowerCase().trim();
    final statusStr = rawStatus.isEmpty ? 'ACTIVE' : rawStatus.toUpperCase();
    final isActive = statusStr != 'CLOSED';

    final nameEn = entity.getLocalizedName('en');
    final nameTa = entity.getLocalizedName('ta');
    final name = nameEn.isNotEmpty
        ? nameEn
        : (nameTa.isNotEmpty ? nameTa : entity.code);
    final shortName = SchemeAdapterTextUtils.getLocalizedText(
      entity.identity['shortName'] ?? classification['shortName'],
      langCode,
    );
    final fullSchemeName = SchemeAdapterTextUtils.getLocalizedText(
      entity.identity['fullName'],
      langCode,
    );
    final finalFullName = fullSchemeName.isNotEmpty ? fullSchemeName : name;

    // ── 2. Graph Relationship Resolution (Authorities & Institutions) ───
    final resolvedAuthorities = bundle.getAuthoritiesForScheme(entity);
    final resolvedInstitutions = bundle.getInstitutionsForScheme(entity);

    // ministryText can hold a placeholder explanation (e.g. "Not applicable
    // (State scheme)") for schemes with no central ministry -- ministryId is
    // the reliable, language-independent signal for whether a real ministry
    // is actually resolved, so gate on that rather than the text being
    // merely non-empty.
    final hasResolvedMinistry = gov['ministryId'] != null;
    String ministry = hasResolvedMinistry
        ? SchemeAdapterTextUtils.getLocalizedText(gov['ministryText'], langCode)
        : '';
    String department = SchemeAdapterTextUtils.getLocalizedText(
      gov['departmentText'],
      langCode,
    );
    String implementingAgency = SchemeAdapterTextUtils.getLocalizedText(
      gov['implementingAgencyText'],
      langCode,
    );

    if (ministry.isEmpty && resolvedAuthorities.isNotEmpty) {
      ministry = resolvedAuthorities.first.getLocalizedName(langCode);
    }
    if (department.isEmpty) {
      if (resolvedAuthorities.length > 1) {
        department = resolvedAuthorities[1].getLocalizedName(langCode);
      } else if (ministry.isNotEmpty) {
        department = ministry;
      }
    }
    if (implementingAgency.isEmpty && resolvedInstitutions.isNotEmpty) {
      implementingAgency = resolvedInstitutions.first.getLocalizedName(
        langCode,
      );
    }

    final sponsoringBody = ministry.isNotEmpty
        ? ministry
        : (department.isNotEmpty ? department : 'Government of India');
    final issuingBody = implementingAgency.isNotEmpty
        ? implementingAgency
        : sponsoringBody;

    final govLevelRaw =
        (gov['levelText'] as String?) ?? (gov['level'] as String?) ?? 'Central';
    final governmentLevel = govLevelRaw.isNotEmpty ? govLevelRaw : 'Central';

    final stateRaw = (gov['statesText'] as String?);
    final state = (stateRaw != null && stateRaw.isNotEmpty)
        ? stateRaw
        : (governmentLevel.toLowerCase().contains('central')
              ? 'All India'
              : 'Tamil Nadu');

    final sector =
        (classification['sectorsText'] as String?) ??
        SchemeAdapterTextUtils.asList(classification['sectors'])?.join(', ') ??
        (classification['sector'] as String?) ??
        (content['sector'] as String?) ??
        '';

    final schemeType =
        (classification['schemeTypeText'] as String?) ??
        SchemeAdapterTextUtils.asList(classification['schemeType'])?.join(
          ', ',
        ) ??
        (classification['schemeType'] as String?) ??
        '';

    final category = schemeType.isNotEmpty
        ? schemeType
        : (sector.isNotEmpty ? sector : 'General');

    // ── 3. Overview & Objectives ───────────────────────────────────────
    String overviewEn = '';
    String overviewTa = entity.getLocalizedAttribute('summary', 'ta');
    if (overviewTa.isEmpty) {
      overviewTa = entity.getLocalizedAttribute('overview', 'ta');
    }
    if (overviewTa.isEmpty) {
      overviewTa = entity.getLocalizedAttribute('description', 'ta');
    }

    final summaryRaw =
        overviewObj['summary'] ??
        overviewObj['description'] ??
        content['summary'] ??
        content['description'] ??
        content['overview'];
    if (summaryRaw is Map<String, dynamic>) {
      final en = summaryRaw['en'] as String? ?? '';
      final ta = summaryRaw['ta'] as String? ?? '';
      overviewEn = en.isNotEmpty ? en : ta;
      if (overviewTa.isEmpty && ta.isNotEmpty) overviewTa = ta;
    } else if (summaryRaw is String) {
      overviewEn = summaryRaw;
    }

    final objectivesEn = SchemeAdapterTextUtils.getLocalizedText(
      content['objectives'] ?? overviewObj['objective'],
      langCode,
    );

    // ── 4. Target Beneficiaries & At-a-Glance Chips ────────────────────
    final beneficiaryDesc = SchemeAdapterTextUtils.getLocalizedText(
      targetBeneficiariesObj['description'] ??
          classification['targetBeneficiariesText'] ??
          classification['targetBeneficiaries'],
      langCode,
    );
    final targetBeneficiary = beneficiaryDesc.isNotEmpty
        ? beneficiaryDesc
        : 'Eligible MSMEs & Enterprises';

    if (overviewEn.isEmpty) {
      final elTextEn =
          (eligibilityTextObj['summary'] as String?) ??
          (content['eligibilityText'] as String?) ??
          entity.getLocalizedAttribute('eligibilityText', 'en');
      final elTextTa = entity.getLocalizedAttribute('eligibilityText', 'ta');
      if (elTextEn.isNotEmpty) {
        overviewEn = elTextEn;
        if (overviewTa.isEmpty && elTextTa.isNotEmpty) overviewTa = elTextTa;
      } else {
        overviewEn =
            'Government scheme providing financial and institutional support for $targetBeneficiary.';
      }
    }

    final glanceChips = <String>{};
    if (governmentLevel.isNotEmpty) glanceChips.add(governmentLevel);
    if (state.isNotEmpty) glanceChips.add(state);
    if (sector.isNotEmpty) {
      glanceChips.addAll(
        sector.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }
    if (schemeType.isNotEmpty) glanceChips.add(schemeType);

    final benTypes = SchemeAdapterTextUtils.asList(
      targetBeneficiariesObj['beneficiaryTypes'],
    );
    if (benTypes != null) glanceChips.addAll(benTypes.map((e) => e.toString()));

    final entTypes = SchemeAdapterTextUtils.asList(
      targetBeneficiariesObj['enterpriseTypes'],
    );
    if (entTypes != null) glanceChips.addAll(entTypes.map((e) => e.toString()));

    final busStages = SchemeAdapterTextUtils.asList(
      targetBeneficiariesObj['businessStages'],
    );
    if (busStages != null) {
      glanceChips.addAll(busStages.map((e) => e.toString()));
    }

    final specCats = SchemeAdapterTextUtils.asList(
      targetBeneficiariesObj['specialCategories'],
    );
    if (specCats != null) glanceChips.addAll(specCats.map((e) => e.toString()));

    final tags = SchemeAdapterTextUtils.asList(classification['tags']);
    if (tags != null) glanceChips.addAll(tags.map((e) => e.toString()));

    final districtApplicable = (gov['districtsText'] as String?) ?? '';

    return SchemeHeaderData(
      statusStr: statusStr,
      isActive: isActive,
      name: name,
      nameTa: nameTa,
      shortName: shortName,
      finalFullName: finalFullName,
      ministry: ministry,
      department: department,
      implementingAgency: implementingAgency,
      sponsoringBody: sponsoringBody,
      issuingBody: issuingBody,
      governmentLevel: governmentLevel,
      state: state,
      sector: sector,
      schemeType: schemeType,
      category: category,
      districtApplicable: districtApplicable,
      overviewEn: overviewEn,
      overviewTa: overviewTa,
      objectivesEn: objectivesEn,
      targetBeneficiary: targetBeneficiary,
      glanceChips: glanceChips,
    );
  }
}
