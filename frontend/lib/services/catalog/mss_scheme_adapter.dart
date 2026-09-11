import '../../models/mss_entity.dart';
import '../../models/mss_models.dart';
import '../../models/scheme_model.dart';
import 'adapter/scheme_benefits_resolver.dart';
import 'adapter/scheme_eligibility_resolver.dart';
import 'adapter/scheme_header_resolver.dart';
import 'adapter/scheme_resources_resolver.dart';
import 'mss_catalog_bundle.dart';

export 'adapter/scheme_adapter_text_utils.dart';
export 'adapter/scheme_benefits_resolver.dart';
export 'adapter/scheme_eligibility_resolver.dart';
export 'adapter/scheme_header_resolver.dart';
export 'adapter/scheme_resources_resolver.dart';

/// MssSchemeAdapter
/// ─────────────────
/// Canonical translation layer converting an [MssEntity] of type 'scheme'
/// into the rich [Scheme] domain model object.
/// Resolves linked entities (authority, institution, finance, tax, CSR, export,
/// TReDS, knowledge, services, documents) strictly in-memory from [MssCatalogBundle]
/// using `relationships.references` and `byId` graph resolution.
///
/// Decomposed into dedicated sub-parsers:
/// - [SchemeHeaderResolver]: Status, header names, authority graph resolution, overview, glance chips
/// - [SchemeEligibilityResolver]: Narrative and structured conditions, limits, facet matching
/// - [SchemeBenefitsResolver]: Funding amounts, subsidies, loans, linked finance/tax/knowledge products
/// - [SchemeResourcesResolver]: Documents, workflow steps, implementing agency services, URLs, helplines
class MssSchemeAdapter {
  MssSchemeAdapter._();

  /// Convert a scheme entity to a Scheme model object using in-memory catalog graph references.
  static Scheme toScheme(
    MssEntity entity,
    MssCatalogBundle bundle, {
    String langCode = 'en',
  }) {
    assert(
      entity.entityType == 'scheme',
      'MssSchemeAdapter requires an entity of type scheme',
    );

    final header = SchemeHeaderResolver.resolve(
      entity,
      bundle,
      langCode: langCode,
    );

    final eligibility = SchemeEligibilityResolver.resolve(
      entity,
      targetBeneficiary: header.targetBeneficiary,
      langCode: langCode,
    );

    final benefits = SchemeBenefitsResolver.resolve(
      entity,
      bundle,
      overviewEn: header.overviewEn,
      langCode: langCode,
    );

    final resources = SchemeResourcesResolver.resolve(
      entity,
      issuingBody: header.issuingBody,
      langCode: langCode,
    );

    final metadata = entity.metadata;

    final searchKeywords =
        '${header.name} ${header.shortName} ${header.finalFullName} ${header.sponsoringBody} ${header.issuingBody} ${header.sector} ${header.glanceChips.join(" ")}'
            .trim();

    return Scheme(
      id: entity.id,
      schemeCode: entity.code,
      name: header.name,
      nameTa: header.nameTa,
      shortName: header.shortName,
      fullSchemeName: header.finalFullName,
      ministry: header.ministry,
      department: header.department,
      implementingAgency: header.implementingAgency,
      matchScore: 1.0,
      logoUrl: resources.logoUrl,
      officialSource: resources.officialWebsite,
      governmentLevel: header.governmentLevel,
      sponsoringBody: header.sponsoringBody,
      issuingBody: header.issuingBody,
      state: header.state,
      sector: header.sector,
      targetBeneficiary: header.targetBeneficiary,
      schemeType: header.schemeType,
      category: header.category,
      overview: header.overviewEn,
      overviewTa: header.overviewTa,
      objectives: header.objectivesEn,
      benefits: benefits.rawBenefitsDisplayText,
      benefitsTa: benefits.benefitsTa,
      subsidyPercentage: benefits.subsidyPercentage,
      maxFunding: benefits.maxFunding,
      minFunding: benefits.minFunding,
      interestSubventionRate: benefits.interestSubventionRate,
      applicationMode: resources.applicationMode,
      officialWebsite: resources.officialWebsite,
      applicationUrl: resources.applicationUrl,
      guidelinesUrl: resources.guidelinesUrl,
      sourceUrl: resources.officialWebsite,
      schemeUrl: resources.schemeUrl,
      districtApplicable: header.districtApplicable,
      subsidyAmount: benefits.subsidyAmountText,
      verificationStatus:
          (metadata['verificationStatus'] as String?) ?? 'VERIFIED',
      verificationNotes: (metadata['sourceNotes'] as String?) ?? '',
      lastUpdated: (metadata['updatedAt'] as String?) ?? '',
      searchKeywords: searchKeywords,
      status: header.statusStr,
      isActive: header.isActive,
      glanceChips: header.glanceChips.toList(),
      benefitTypesList: benefits.benefitTypesList,
      capitalSubsidyDetails: benefits.capitalSubsidyDetails,
      interestSubventionDetails: benefits.interestSubventionDetails,
      marginMoneyDetails: benefits.marginMoneyDetails,
      loanGuaranteeDetails: benefits.loanGuaranteeDetails,
      supportTypes: const [],
      rawBenefitsDisplayText: benefits.rawBenefitsDisplayText,
      eligibilityAgeRange: eligibility.ageRange,
      turnoverLimits: eligibility.turnoverLimits,
      investmentLimits: eligibility.investmentLimits,
      allowedBusinessTypes: eligibility.allowedBusinessTypes,
      educationRequirements: eligibility.educationRequirements,
      mandatoryConditions: eligibility.mandatoryConditions,
      optionalConditions: eligibility.optionalConditions,
      specialCategories: eligibility.specialCategories,
      eligibilityMinAge: eligibility.eligibilityMinAge,
      eligibilityMaxAge: eligibility.eligibilityMaxAge,
      eligibilityGenderValues: eligibility.eligibilityGenderValues,
      eligibilityBusinessStageValues: eligibility.eligibilityBusinessStageValues,
      applicationFee: resources.applicationFee,
      processingDurationDays: resources.processingDurationDays,
      intakeTimelineText: resources.intakeTimelineText,
      financeProductsSummary: benefits.financeProductsSummary,
      taxExemptionsSummary: benefits.taxExemptionsSummary,
      applicableTaxesList: benefits.applicableTaxesList,
      knowledgeGuidanceList: benefits.knowledgeGuidanceList,
      helplineContactsMap: resources.helplineContactsMap,
      eligibilityCriteria: eligibility.elCriteriaList,
      requiredDocuments: resources.reqDocNames,
      applicationProcess: resources.stepsList,
      documents: resources.docList,
      requiredServices: resources.serviceList,
      faqs: resources.faqList,
    );
  }

  /// Adapt a SchemeResult (from POST /v1/search) into a Scheme domain model,
  /// merging offline catalog bundle details when available with API relevance/enrichment scores.
  static Scheme schemeResultToScheme(
    SchemeResult result,
    MssCatalogBundle bundle, {
    String langCode = 'en',
  }) {
    final entity = bundle.getEntity(result.schemeId);
    if (entity != null && entity.entityType == 'scheme') {
      final scheme = toScheme(entity, bundle, langCode: langCode);
      final applyUrl = result.applyAction?.url ?? scheme.applicationUrl;
      return scheme.copyWith(
        name: result.name.isNotEmpty ? result.name : scheme.name,
        matchScore: result.matchScore,
        status: result.status != SchemeStatus.unrecognised
            ? result.status.name
            : scheme.status,
        applicationUrl: applyUrl.isNotEmpty ? applyUrl : scheme.applicationUrl,
      );
    }
    return Scheme(
      id: result.schemeId,
      name: result.name,
      matchScore: result.matchScore,
      status: result.status != SchemeStatus.unrecognised
          ? result.status.name
          : 'active',
      officialWebsite: result.applyAction?.url ?? '',
      applicationUrl: result.applyAction?.url ?? '',
      overview: result.explanation.summary,
      searchKeywords: result.matchReasons.map((m) => m.detail).join(' '),
    );
  }

  /// Adapt an MssSchemeIntelligence DTO (from GET /v1/schemes/{id}) into a Scheme domain model.
  static Scheme schemeIntelligenceToScheme(
    MssSchemeIntelligence intel,
    MssCatalogBundle bundle, {
    String langCode = 'en',
  }) {
    final entity = bundle.getEntity(intel.schemeId);
    if (entity != null && entity.entityType == 'scheme') {
      final scheme = toScheme(entity, bundle, langCode: langCode);
      final applyOnline = intel.nextActions.firstWhere(
        (a) => a.action == 'apply_online',
        orElse: () => const MssNextAction(action: '', label: ''),
      );
      return scheme.copyWith(
        name: intel.name ?? scheme.name,
        status: intel.schemeStatus != SchemeStatus.unrecognised
            ? intel.schemeStatus.name
            : scheme.status,
        applicationUrl: applyOnline.url ?? scheme.applicationUrl,
      );
    }
    final applyAction = intel.nextActions.firstWhere(
      (a) => a.action == 'apply_online',
      orElse: () => const MssNextAction(action: '', label: ''),
    );
    return Scheme(
      id: intel.schemeId,
      name: intel.name ?? intel.schemeId,
      status: intel.schemeStatus != SchemeStatus.unrecognised
          ? intel.schemeStatus.name
          : 'active',
      officialWebsite: applyAction.url ?? '',
      applicationUrl: applyAction.url ?? '',
    );
  }
}
