import '../../models/mss_entity.dart';
import '../../models/scheme_extras.dart';
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
      geoCoverage: header.coverage,
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
      eligibilityBusinessStageValues:
          eligibility.eligibilityBusinessStageValues,
      applicationFee: resources.applicationFee,
      processingDurationDays: resources.processingDurationDays,
      intakeTimelineText: resources.intakeTimelineText,
      financeProductsSummary: benefits.financeProductsSummary,
      taxExemptionsSummary: benefits.taxExemptionsSummary,
      applicableTaxesList: benefits.applicableTaxesList,
      knowledgeGuidanceList: benefits.knowledgeGuidanceList,
      helplineContactsMap: resources.helplineContactsMap,
      extras: SchemeExtras.fromEntity(entity.raw),
      nativeNames: header.nativeNames,
      eligibilityCriteria: eligibility.elCriteriaList,
      requiredDocuments: resources.reqDocNames,
      applicationProcess: resources.stepsList,
      documents: resources.docList,
      requiredServices: resources.serviceList,
      faqs: resources.faqList,
    );
  }
}
