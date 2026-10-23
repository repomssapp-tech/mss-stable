import '../services/catalog/language_pack_manager.dart';
import 'scheme_extras.dart';

class SchemeDocument {
  final String name;
  final String nameTa;
  final String mandatory;
  final String mandatoryTa;
  final String issuingAuthority;
  final String issuingAuthorityTa;
  final String description;
  final String descriptionTa;
  final String estimatedCost;
  final String estimatedCostTa;
  final String remarks;
  final String remarksTa;
  // Hindi text stored in the catalogue record (`{"en": ..., "hi": ...}`).
  final String nameHi;
  final String issuingAuthorityHi;
  final String descriptionHi;
  final String estimatedCostHi;
  final String remarksHi;
  final String sourceUrl;
  final String validityMonths;
  final String downloadTemplateUrl;
  final String sampleCopyUrl;
  final String verificationPortalUrl;

  const SchemeDocument({
    required this.name,
    this.nameTa = '',
    this.mandatory = '',
    this.mandatoryTa = '',
    this.issuingAuthority = '',
    this.issuingAuthorityTa = '',
    this.description = '',
    this.descriptionTa = '',
    this.estimatedCost = '',
    this.estimatedCostTa = '',
    this.remarks = '',
    this.remarksTa = '',
    this.nameHi = '',
    this.issuingAuthorityHi = '',
    this.descriptionHi = '',
    this.estimatedCostHi = '',
    this.remarksHi = '',
    this.sourceUrl = '',
    this.validityMonths = '',
    this.downloadTemplateUrl = '',
    this.sampleCopyUrl = '',
    this.verificationPortalUrl = '',
  });

  bool get isMandatory =>
      mandatory.toLowerCase() == 'yes' || mandatory.toLowerCase() == 'required';

  SchemeDocument copyWith({
    String? name,
    String? nameTa,
    String? mandatory,
    String? mandatoryTa,
    String? issuingAuthority,
    String? issuingAuthorityTa,
    String? description,
    String? descriptionTa,
    String? estimatedCost,
    String? estimatedCostTa,
    String? remarks,
    String? remarksTa,
    String? nameHi,
    String? issuingAuthorityHi,
    String? descriptionHi,
    String? estimatedCostHi,
    String? remarksHi,
    String? sourceUrl,
    String? validityMonths,
    String? downloadTemplateUrl,
    String? sampleCopyUrl,
    String? verificationPortalUrl,
  }) {
    return SchemeDocument(
      name: name ?? this.name,
      nameTa: nameTa ?? this.nameTa,
      mandatory: mandatory ?? this.mandatory,
      mandatoryTa: mandatoryTa ?? this.mandatoryTa,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      issuingAuthorityTa: issuingAuthorityTa ?? this.issuingAuthorityTa,
      description: description ?? this.description,
      descriptionTa: descriptionTa ?? this.descriptionTa,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      estimatedCostTa: estimatedCostTa ?? this.estimatedCostTa,
      remarks: remarks ?? this.remarks,
      remarksTa: remarksTa ?? this.remarksTa,
      nameHi: nameHi ?? this.nameHi,
      issuingAuthorityHi: issuingAuthorityHi ?? this.issuingAuthorityHi,
      descriptionHi: descriptionHi ?? this.descriptionHi,
      estimatedCostHi: estimatedCostHi ?? this.estimatedCostHi,
      remarksHi: remarksHi ?? this.remarksHi,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      validityMonths: validityMonths ?? this.validityMonths,
      downloadTemplateUrl: downloadTemplateUrl ?? this.downloadTemplateUrl,
      sampleCopyUrl: sampleCopyUrl ?? this.sampleCopyUrl,
      verificationPortalUrl:
          verificationPortalUrl ?? this.verificationPortalUrl,
    );
  }
}

class SchemeService {
  final String name;
  final String nameTa;
  final String category;
  final String categoryTa;
  final bool mandatory;
  final String description;
  final String descriptionTa;
  final String purpose;
  final String purposeTa;
  final String department;
  final String departmentTa;
  final String website;
  final String contact;
  final String status;
  final String notes;
  final String notesTa;
  // Hindi text stored in the catalogue record (`{"en": ..., "hi": ...}`).
  final String nameHi;
  final String categoryHi;
  final String descriptionHi;
  final String purposeHi;
  final String departmentHi;
  final String notesHi;

  const SchemeService({
    required this.name,
    this.nameTa = '',
    this.category = '',
    this.categoryTa = '',
    this.mandatory = false,
    this.description = '',
    this.descriptionTa = '',
    this.purpose = '',
    this.purposeTa = '',
    this.department = '',
    this.departmentTa = '',
    this.website = '',
    this.contact = '',
    this.status = 'ACTIVE',
    this.notes = '',
    this.notesTa = '',
    this.nameHi = '',
    this.categoryHi = '',
    this.descriptionHi = '',
    this.purposeHi = '',
    this.departmentHi = '',
    this.notesHi = '',
  });
}

/// Unified scheme model populated by the bundled catalog (the 2026 scheme
/// data); [extras] carries the source fields with no dedicated property.
class Scheme {
  final String id; // Stable catalog id, e.g. "CEN2026-085"
  final String schemeCode; // Catalog code (equal to [id] for 2026 records)
  final String name;
  final String nameTa;
  final String shortName;
  final String fullSchemeName;
  final String ministry;
  final String department;
  final String implementingAgency;
  final double matchScore;
  final String logoUrl;
  final String officialSource;
  final String governmentLevel; // Central / State
  final String sponsoringBody; // issuing_department
  final String issuingBody; // issuing_body (implementing agency)
  /// Display text of where the scheme applies ("All India", "Maharashtra",
  /// "North Eastern States and Sikkim"). For filtering use [appliesNationally]
  /// and [stateCodes]; `schemeAppliesInState` in scheme_filter.dart combines
  /// them.
  final String state;

  /// Whether the scheme applies in every state, from the catalog's
  /// `classification.government.appliesNationally`. Null when the record does
  /// not say, which is different from false: false with no [stateCodes]
  /// means the coverage is unknown.
  final bool? appliesNationally;

  /// ISO 3166-2 codes of the states the scheme is limited to (`IN-TN`), from
  /// `classification.government.states`. Empty when nationwide or unknown.
  final List<String> stateCodes;
  final String sector;
  final String targetBeneficiary;
  final String schemeType; // assistance_type
  final String category;
  final String overview; // maps to "overview" column
  final String overviewTa;
  final String objectives;
  final String benefits; // benefits_description
  final String benefitsTa;
  final double? subsidyPercentage;
  final double? maxFunding;
  final double? minFunding;
  final double? interestSubventionRate;
  final String applicationMode;
  final String officialWebsite;
  final String applicationUrl;
  final String guidelinesUrl;
  final String sourceUrl;

  /// Canonical official application/landing URL for the scheme, from
  /// catalog.scheme.scheme_url (mirrored into record_json.content.schemeUrl).
  /// This is the sole source for the "Apply Now" action.
  final String schemeUrl;

  final String districtApplicable;
  final String subsidyAmount;
  final String verificationStatus;
  final String verificationNotes;
  final String lastUpdated;

  /// When the scheme was added to the catalog (`metadata.createdAt`,
  /// ISO date). Drives the "newly released" slides on Home; empty when the
  /// record does not say.
  final String addedOn;
  final String searchKeywords;
  final String status;
  final bool isActive;

  // Phase 5 At-a-Glance Chips
  final List<String> glanceChips;

  // Phase 5 Benefits & Funding Breakdown
  final List<String> benefitTypesList;
  final String capitalSubsidyDetails;
  final String interestSubventionDetails;
  final String marginMoneyDetails;
  final String loanGuaranteeDetails;
  final List<String> supportTypes;
  final String rawBenefitsDisplayText;

  // Phase 5 Detailed Eligibility Breakdown
  final String eligibilityAgeRange;
  final String turnoverLimits;
  final String investmentLimits;
  final List<String> allowedBusinessTypes;
  final String educationRequirements;
  final List<String> mandatoryConditions;
  final List<String> optionalConditions;
  final List<String> specialCategories;

  // Typed facet values for profile-vs-scheme matching (RecommendationEngine)
  // -- distinct from the display-text fields above, which are for showing
  // eligibility criteria in the UI, not for comparing against UserProfile.
  final int? eligibilityMinAge;
  final int? eligibilityMaxAge;
  final List<String> eligibilityGenderValues;
  final List<String> eligibilityBusinessStageValues;

  // Phase 5 Application Timeline & Services
  final String applicationFee;
  final String processingDurationDays;
  final String intakeTimelineText;

  // Phase 5 Linked Graph Extensions (Finance, Tax, Knowledge, Helplines)
  final List<String> financeProductsSummary;
  final List<String> taxExemptionsSummary;
  final List<String> applicableTaxesList;
  final List<String> knowledgeGuidanceList;
  final Map<String, String> helplineContactsMap;

  /// 2026 source details with no dedicated field (contacts, benefit facts,
  /// status note, links...). [SchemeExtras.empty] for non-2026 records.
  final SchemeExtras extras;

  /// Names the catalog stores in other languages for this scheme's short
  /// name and its ministry/department/agency, keyed by field then language.
  /// Shown as is, ahead of any runtime translation.
  final Map<String, Map<String, String>> nativeNames;

  /// The catalog's stored [lang] name for [field], or null when it has none.
  String? nativeName(String field, String lang) {
    final value = nativeNames[field]?[lang];
    return value == null || value.isEmpty ? null : value;
  }

  // Joined / enriched fields (populated on detail load)
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final List<String> applicationProcess;
  final List<SchemeDocument> documents;
  final List<SchemeService> requiredServices;
  final List<Map<String, String>> faqs;

  const Scheme({
    required this.id,
    this.schemeCode = '',
    required this.name,
    this.nameTa = '',
    this.shortName = '',
    this.fullSchemeName = '',
    this.ministry = '',
    this.department = '',
    this.implementingAgency = '',
    this.matchScore = 1.0,
    this.logoUrl = '',
    this.officialSource = '',
    this.governmentLevel = 'Central',
    this.sponsoringBody = '',
    this.issuingBody = '',
    this.state = 'All India',
    this.appliesNationally,
    this.stateCodes = const [],
    this.sector = '',
    this.targetBeneficiary = '',
    this.schemeType = '',
    this.category = '',
    this.overview = '',
    this.overviewTa = '',
    this.objectives = '',
    this.benefits = '',
    this.benefitsTa = '',
    this.subsidyPercentage,
    this.maxFunding,
    this.minFunding,
    this.interestSubventionRate,
    this.applicationMode = '',
    this.officialWebsite = '',
    this.applicationUrl = '',
    this.guidelinesUrl = '',
    this.sourceUrl = '',
    this.schemeUrl = '',
    this.districtApplicable = '',
    this.subsidyAmount = '',
    this.verificationStatus = '',
    this.verificationNotes = '',
    this.lastUpdated = '',
    this.addedOn = '',
    this.searchKeywords = '',
    this.status = 'ACTIVE',
    this.isActive = true,
    this.glanceChips = const [],
    this.benefitTypesList = const [],
    this.capitalSubsidyDetails = '',
    this.interestSubventionDetails = '',
    this.marginMoneyDetails = '',
    this.loanGuaranteeDetails = '',
    this.supportTypes = const [],
    this.rawBenefitsDisplayText = '',
    this.eligibilityAgeRange = '',
    this.turnoverLimits = '',
    this.investmentLimits = '',
    this.allowedBusinessTypes = const [],
    this.educationRequirements = '',
    this.mandatoryConditions = const [],
    this.optionalConditions = const [],
    this.specialCategories = const [],
    this.eligibilityMinAge,
    this.eligibilityMaxAge,
    this.eligibilityGenderValues = const [],
    this.eligibilityBusinessStageValues = const [],
    this.applicationFee = '',
    this.processingDurationDays = '',
    this.intakeTimelineText = '',
    this.financeProductsSummary = const [],
    this.taxExemptionsSummary = const [],
    this.applicableTaxesList = const [],
    this.knowledgeGuidanceList = const [],
    this.helplineContactsMap = const {},
    this.extras = SchemeExtras.empty,
    this.nativeNames = const {},
    this.eligibilityCriteria = const [],
    this.requiredDocuments = const [],
    this.applicationProcess = const [],
    this.documents = const [],
    this.requiredServices = const [],
    this.faqs = const [],
  });

  /// Get scheme name localized according to language selection with clean fallback.
  String getName([String langCode = 'en']) {
    if (langCode != 'en') {
      final packVal = LanguagePackManager.instance.getField(
        lang: langCode,
        entityType: 'scheme',
        entityId: id,
        fieldName: 'name',
      );
      if (packVal != null && packVal.isNotEmpty) return packVal;
    }
    if (langCode == 'ta' && nameTa.trim().isNotEmpty) {
      return nameTa.trim();
    }
    return name.isNotEmpty ? name : schemeCode;
  }

  /// Get localized overview description
  String getOverview([String langCode = 'en']) {
    if (langCode != 'en') {
      final packVal =
          LanguagePackManager.instance.getField(
            lang: langCode,
            entityType: 'scheme',
            entityId: id,
            fieldName: 'summary',
          ) ??
          LanguagePackManager.instance.getField(
            lang: langCode,
            entityType: 'scheme',
            entityId: id,
            fieldName: 'description',
          );
      if (packVal != null && packVal.isNotEmpty) return packVal;
    }
    if (langCode == 'ta' && overviewTa.trim().isNotEmpty) {
      return overviewTa.trim();
    }
    return overview;
  }

  /// Get localized benefits description
  String getBenefits([String langCode = 'en']) {
    if (langCode != 'en') {
      final packVal = LanguagePackManager.instance.getField(
        lang: langCode,
        entityType: 'scheme',
        entityId: id,
        fieldName: 'benefits_text',
      );
      if (packVal != null && packVal.isNotEmpty) return packVal;
    }
    if (langCode == 'ta' && benefitsTa.trim().isNotEmpty) {
      return benefitsTa.trim();
    }
    return benefits;
  }

  /// Returns a copy with specified fields updated.
  Scheme copyWith({
    String? name,
    double? matchScore,
    String? status,
    String? applicationUrl,
    String? officialWebsite,
  }) {
    return Scheme(
      id: id,
      schemeCode: schemeCode,
      name: name ?? this.name,
      nameTa: nameTa,
      shortName: shortName,
      fullSchemeName: fullSchemeName,
      ministry: ministry,
      department: department,
      implementingAgency: implementingAgency,
      matchScore: matchScore ?? this.matchScore,
      logoUrl: logoUrl,
      officialSource: officialSource,
      governmentLevel: governmentLevel,
      sponsoringBody: sponsoringBody,
      issuingBody: issuingBody,
      state: state,
      appliesNationally: appliesNationally,
      stateCodes: stateCodes,
      sector: sector,
      targetBeneficiary: targetBeneficiary,
      schemeType: schemeType,
      category: category,
      overview: overview,
      overviewTa: overviewTa,
      objectives: objectives,
      benefits: benefits,
      benefitsTa: benefitsTa,
      subsidyPercentage: subsidyPercentage,
      maxFunding: maxFunding,
      minFunding: minFunding,
      interestSubventionRate: interestSubventionRate,
      applicationMode: applicationMode,
      officialWebsite: officialWebsite ?? this.officialWebsite,
      applicationUrl: applicationUrl ?? this.applicationUrl,
      guidelinesUrl: guidelinesUrl,
      sourceUrl: sourceUrl,
      schemeUrl: schemeUrl,
      districtApplicable: districtApplicable,
      subsidyAmount: subsidyAmount,
      verificationStatus: verificationStatus,
      verificationNotes: verificationNotes,
      lastUpdated: lastUpdated,
      addedOn: addedOn,
      searchKeywords: searchKeywords,
      status: status ?? this.status,
      isActive: isActive,
      glanceChips: glanceChips,
      benefitTypesList: benefitTypesList,
      capitalSubsidyDetails: capitalSubsidyDetails,
      interestSubventionDetails: interestSubventionDetails,
      marginMoneyDetails: marginMoneyDetails,
      loanGuaranteeDetails: loanGuaranteeDetails,
      supportTypes: supportTypes,
      rawBenefitsDisplayText: rawBenefitsDisplayText,
      eligibilityAgeRange: eligibilityAgeRange,
      turnoverLimits: turnoverLimits,
      investmentLimits: investmentLimits,
      allowedBusinessTypes: allowedBusinessTypes,
      educationRequirements: educationRequirements,
      mandatoryConditions: mandatoryConditions,
      optionalConditions: optionalConditions,
      specialCategories: specialCategories,
      eligibilityMinAge: eligibilityMinAge,
      eligibilityMaxAge: eligibilityMaxAge,
      eligibilityGenderValues: eligibilityGenderValues,
      eligibilityBusinessStageValues: eligibilityBusinessStageValues,
      applicationFee: applicationFee,
      processingDurationDays: processingDurationDays,
      intakeTimelineText: intakeTimelineText,
      financeProductsSummary: financeProductsSummary,
      taxExemptionsSummary: taxExemptionsSummary,
      applicableTaxesList: applicableTaxesList,
      knowledgeGuidanceList: knowledgeGuidanceList,
      helplineContactsMap: helplineContactsMap,
      extras: extras,
      nativeNames: nativeNames,
      eligibilityCriteria: eligibilityCriteria,
      requiredDocuments: requiredDocuments,
      applicationProcess: applicationProcess,
      documents: documents,
      requiredServices: requiredServices,
      faqs: faqs,
    );
  }

  /// Returns a copy with enriched detail fields (eligibility, documents, etc.)
  Scheme copyWithDetails({
    List<String>? eligibilityCriteria,
    List<String>? requiredDocuments,
    List<String>? applicationProcess,
    List<SchemeDocument>? documents,
    List<SchemeService>? requiredServices,
    List<Map<String, String>>? faqs,
    List<String>? glanceChips,
    List<String>? benefitTypesList,
    String? capitalSubsidyDetails,
    String? interestSubventionDetails,
    String? marginMoneyDetails,
    String? loanGuaranteeDetails,
    List<String>? supportTypes,
    String? rawBenefitsDisplayText,
    String? eligibilityAgeRange,
    String? turnoverLimits,
    String? investmentLimits,
    List<String>? allowedBusinessTypes,
    String? educationRequirements,
    List<String>? mandatoryConditions,
    List<String>? optionalConditions,
    List<String>? specialCategories,
    int? eligibilityMinAge,
    int? eligibilityMaxAge,
    List<String>? eligibilityGenderValues,
    List<String>? eligibilityBusinessStageValues,
    String? applicationFee,
    String? processingDurationDays,
    String? intakeTimelineText,
    List<String>? financeProductsSummary,
    List<String>? taxExemptionsSummary,
    List<String>? applicableTaxesList,
    List<String>? knowledgeGuidanceList,
    Map<String, String>? helplineContactsMap,
  }) {
    return Scheme(
      id: id,
      schemeCode: schemeCode,
      name: name,
      shortName: shortName,
      fullSchemeName: fullSchemeName,
      ministry: ministry,
      department: department,
      implementingAgency: implementingAgency,
      matchScore: matchScore,
      logoUrl: logoUrl,
      officialSource: officialSource,
      governmentLevel: governmentLevel,
      sponsoringBody: sponsoringBody,
      issuingBody: issuingBody,
      state: state,
      appliesNationally: appliesNationally,
      stateCodes: stateCodes,
      sector: sector,
      targetBeneficiary: targetBeneficiary,
      schemeType: schemeType,
      category: category,
      overview: overview,
      overviewTa: overviewTa,
      objectives: objectives,
      benefits: benefits,
      benefitsTa: benefitsTa,
      subsidyPercentage: subsidyPercentage,
      maxFunding: maxFunding,
      minFunding: minFunding,
      interestSubventionRate: interestSubventionRate,
      applicationMode: applicationMode,
      officialWebsite: officialWebsite,
      applicationUrl: applicationUrl,
      guidelinesUrl: guidelinesUrl,
      sourceUrl: sourceUrl,
      schemeUrl: schemeUrl,
      districtApplicable: districtApplicable,
      subsidyAmount: subsidyAmount,
      verificationStatus: verificationStatus,
      verificationNotes: verificationNotes,
      lastUpdated: lastUpdated,
      addedOn: addedOn,
      searchKeywords: searchKeywords,
      status: status,
      isActive: isActive,
      glanceChips: glanceChips ?? this.glanceChips,
      benefitTypesList: benefitTypesList ?? this.benefitTypesList,
      capitalSubsidyDetails:
          capitalSubsidyDetails ?? this.capitalSubsidyDetails,
      interestSubventionDetails:
          interestSubventionDetails ?? this.interestSubventionDetails,
      marginMoneyDetails: marginMoneyDetails ?? this.marginMoneyDetails,
      loanGuaranteeDetails: loanGuaranteeDetails ?? this.loanGuaranteeDetails,
      supportTypes: supportTypes ?? this.supportTypes,
      rawBenefitsDisplayText:
          rawBenefitsDisplayText ?? this.rawBenefitsDisplayText,
      eligibilityAgeRange: eligibilityAgeRange ?? this.eligibilityAgeRange,
      turnoverLimits: turnoverLimits ?? this.turnoverLimits,
      investmentLimits: investmentLimits ?? this.investmentLimits,
      allowedBusinessTypes: allowedBusinessTypes ?? this.allowedBusinessTypes,
      educationRequirements:
          educationRequirements ?? this.educationRequirements,
      mandatoryConditions: mandatoryConditions ?? this.mandatoryConditions,
      optionalConditions: optionalConditions ?? this.optionalConditions,
      specialCategories: specialCategories ?? this.specialCategories,
      eligibilityMinAge: eligibilityMinAge ?? this.eligibilityMinAge,
      eligibilityMaxAge: eligibilityMaxAge ?? this.eligibilityMaxAge,
      eligibilityGenderValues:
          eligibilityGenderValues ?? this.eligibilityGenderValues,
      eligibilityBusinessStageValues:
          eligibilityBusinessStageValues ?? this.eligibilityBusinessStageValues,
      applicationFee: applicationFee ?? this.applicationFee,
      processingDurationDays:
          processingDurationDays ?? this.processingDurationDays,
      intakeTimelineText: intakeTimelineText ?? this.intakeTimelineText,
      financeProductsSummary:
          financeProductsSummary ?? this.financeProductsSummary,
      taxExemptionsSummary: taxExemptionsSummary ?? this.taxExemptionsSummary,
      applicableTaxesList: applicableTaxesList ?? this.applicableTaxesList,
      knowledgeGuidanceList:
          knowledgeGuidanceList ?? this.knowledgeGuidanceList,
      helplineContactsMap: helplineContactsMap ?? this.helplineContactsMap,
      extras: extras,
      nativeNames: nativeNames,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      applicationProcess: applicationProcess ?? this.applicationProcess,
      documents: documents ?? this.documents,
      requiredServices: requiredServices ?? this.requiredServices,
      faqs: faqs ?? this.faqs,
    );
  }
}
