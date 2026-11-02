import '../services/catalog/centralized_translator.dart';
import '../services/catalog/language_pack_manager.dart';
import '../utils/language_names.dart';
import 'scheme_model.dart';

/// LocalizedScheme
/// ─────────────────
/// Centralized wrapper for [Scheme] that exposes pre-localized fields
/// for the active language. UI widgets consume this object directly,
/// eliminating all inline widget translation logic.
class LocalizedScheme {
  final Scheme rawScheme;
  final String languageCode;

  final String name;
  final String shortName;
  final String fullSchemeName;
  final String ministry;
  final String department;
  final String implementingAgency;
  final String governmentLevel;
  final String sponsoringBody;
  final String issuingBody;
  final String state;
  final String sector;
  final String targetBeneficiary;
  final String schemeType;
  final String category;
  final String overview;
  final String objectives;
  final String benefits;
  final String subsidyAmount;
  final String verificationStatus;
  final String verificationNotes;
  final String lastUpdated;

  // Phase 5 Benefits & Funding Breakdown
  final List<String> glanceChips;
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

  // Phase 5 Application Timeline & Services
  final String applicationFee;
  final String processingDurationDays;
  final String intakeTimelineText;

  // Phase 5 Linked Graph Extensions
  final List<String> financeProductsSummary;
  final List<String> taxExemptionsSummary;
  final List<String> applicableTaxesList;
  final List<String> knowledgeGuidanceList;
  final Map<String, String> helplineContactsMap;

  // Joined / enriched fields
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final List<String> applicationProcess;
  final List<SchemeDocument> documents;
  final List<SchemeService> requiredServices;
  final List<Map<String, String>> faqs;

  // Pass-through getters for non-text / protected attributes
  String get id => rawScheme.id;
  String get schemeCode => rawScheme.schemeCode;
  double get matchScore => rawScheme.matchScore;
  String get logoUrl => rawScheme.logoUrl;
  String get officialSource => rawScheme.officialSource;
  double? get subsidyPercentage => rawScheme.subsidyPercentage;
  double? get maxFunding => rawScheme.maxFunding;
  double? get minFunding => rawScheme.minFunding;
  double? get interestSubventionRate => rawScheme.interestSubventionRate;
  String get applicationMode => rawScheme.applicationMode;
  String get officialWebsite => rawScheme.officialWebsite;
  String get applicationUrl => rawScheme.applicationUrl;
  String get guidelinesUrl => rawScheme.guidelinesUrl;
  String get sourceUrl => rawScheme.sourceUrl;
  String get schemeUrl => rawScheme.schemeUrl;
  String get districtApplicable => rawScheme.districtApplicable;
  String get searchKeywords => rawScheme.searchKeywords;
  String get status => rawScheme.status;
  bool get isActive => rawScheme.isActive;

  const LocalizedScheme._({
    required this.rawScheme,
    required this.languageCode,
    required this.name,
    required this.shortName,
    required this.fullSchemeName,
    required this.ministry,
    required this.department,
    required this.implementingAgency,
    required this.governmentLevel,
    required this.sponsoringBody,
    required this.issuingBody,
    required this.state,
    required this.sector,
    required this.targetBeneficiary,
    required this.schemeType,
    required this.category,
    required this.overview,
    required this.objectives,
    required this.benefits,
    required this.subsidyAmount,
    required this.verificationStatus,
    required this.verificationNotes,
    required this.lastUpdated,
    required this.glanceChips,
    required this.benefitTypesList,
    required this.capitalSubsidyDetails,
    required this.interestSubventionDetails,
    required this.marginMoneyDetails,
    required this.loanGuaranteeDetails,
    required this.supportTypes,
    required this.rawBenefitsDisplayText,
    required this.eligibilityAgeRange,
    required this.turnoverLimits,
    required this.investmentLimits,
    required this.allowedBusinessTypes,
    required this.educationRequirements,
    required this.mandatoryConditions,
    required this.optionalConditions,
    required this.specialCategories,
    required this.applicationFee,
    required this.processingDurationDays,
    required this.intakeTimelineText,
    required this.financeProductsSummary,
    required this.taxExemptionsSummary,
    required this.applicableTaxesList,
    required this.knowledgeGuidanceList,
    required this.helplineContactsMap,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    required this.applicationProcess,
    required this.documents,
    required this.requiredServices,
    required this.faqs,
  });

  /// The catalog's own eligibility list in [lang] when it has one; otherwise
  /// [fallback] applied to the English list (nothing is invented).
  static List<String> _storedEligibility(
    Scheme scheme,
    String lang, {
    List<String> Function(List<String>)? fallback,
  }) {
    final stored = scheme.extras.storedEligibility(lang);
    if (stored.isNotEmpty) return stored;
    final base = scheme.eligibilityCriteria;
    return fallback == null ? base : fallback(base);
  }

  /// A word-by-word machine translation that still has two or more ordinary
  /// English words reads as a mix ("Eligible individuals/நிறுவனங்கள்
  /// establishing புதிய micro-..."), which is harder to read than the
  /// original. Then the original English sentence is shown whole (test report
  /// BUG-07 / L10N-01). Acronyms (PMEGP, MSME) are upper-case and not counted.
  static String _wholeOrOriginal(String translated, String original) {
    final englishWords = RegExp(r'\b[a-z]{3,}\b').allMatches(translated).length;
    return englishWords >= 2 ? original : translated;
  }

  static final RegExp _stepPrefix = RegExp(r'^Step (\d+):\s*');

  /// Stored steps in [lang] when they line up one-to-one with the English
  /// steps (same count); the English "Step N:" numbering is kept in [lang].
  static List<String> _storedSteps(
    Scheme scheme,
    String lang, {
    List<String> Function(List<String>)? fallback,
  }) {
    final base = scheme.applicationProcess;
    final stored = scheme.extras.storedSteps(lang);
    if (stored.isEmpty) return fallback == null ? base : fallback(base);
    final numbered = base.isNotEmpty && base.every(_stepPrefix.hasMatch);
    if (stored.length != base.length || !numbered) {
      return stored.length == base.length || base.isEmpty
          ? stored
          : (fallback == null ? base : fallback(base));
    }
    return [
      for (var i = 0; i < stored.length; i++)
        '${stepLabel(lang, i + 1)} ${stored[i]}',
    ];
  }

  /// Every language runs through one pipeline, so a language the catalogue
  /// adds needs no code here. For each field: the text the catalogue stores in
  /// the language, then the translator (see [CentralizedTranslator]), then the
  /// original English. A value is never invented.
  factory LocalizedScheme.fromScheme(Scheme scheme, String languageCode) {
    if (languageCode != 'en') {
      return LocalizedScheme._translated(scheme, languageCode);
    }

    return LocalizedScheme._(
      rawScheme: scheme,
      languageCode: languageCode,
      name: scheme.name,
      shortName: scheme.shortName,
      fullSchemeName: scheme.fullSchemeName,
      ministry: scheme.ministry,
      department: scheme.department,
      implementingAgency: scheme.implementingAgency,
      governmentLevel: scheme.governmentLevel,
      sponsoringBody: scheme.sponsoringBody,
      issuingBody: scheme.issuingBody,
      state: scheme.state,
      sector: scheme.sector,
      targetBeneficiary: scheme.targetBeneficiary,
      schemeType: scheme.schemeType,
      category: scheme.category,
      overview: scheme.overview,
      objectives: scheme.objectives,
      benefits: scheme.benefits,
      subsidyAmount: scheme.subsidyAmount,
      verificationStatus: scheme.verificationStatus,
      verificationNotes: scheme.verificationNotes,
      lastUpdated: scheme.lastUpdated,
      glanceChips: scheme.glanceChips,
      benefitTypesList: scheme.benefitTypesList,
      capitalSubsidyDetails: scheme.capitalSubsidyDetails,
      interestSubventionDetails: scheme.interestSubventionDetails,
      marginMoneyDetails: scheme.marginMoneyDetails,
      loanGuaranteeDetails: scheme.loanGuaranteeDetails,
      supportTypes: scheme.supportTypes,
      rawBenefitsDisplayText: scheme.rawBenefitsDisplayText,
      eligibilityAgeRange: scheme.eligibilityAgeRange,
      turnoverLimits: scheme.turnoverLimits,
      investmentLimits: scheme.investmentLimits,
      allowedBusinessTypes: scheme.allowedBusinessTypes,
      educationRequirements: scheme.educationRequirements,
      mandatoryConditions: scheme.mandatoryConditions,
      optionalConditions: scheme.optionalConditions,
      specialCategories: scheme.specialCategories,
      applicationFee: scheme.applicationFee,
      processingDurationDays: scheme.processingDurationDays,
      intakeTimelineText: scheme.intakeTimelineText,
      financeProductsSummary: scheme.financeProductsSummary,
      taxExemptionsSummary: scheme.taxExemptionsSummary,
      applicableTaxesList: scheme.applicableTaxesList,
      knowledgeGuidanceList: scheme.knowledgeGuidanceList,
      helplineContactsMap: scheme.helplineContactsMap,
      eligibilityCriteria: scheme.eligibilityCriteria,
      requiredDocuments: scheme.requiredDocuments,
      applicationProcess: scheme.applicationProcess,
      documents: scheme.documents,
      requiredServices: scheme.requiredServices,
      faqs: scheme.faqs,
    );
  }

  factory LocalizedScheme._translated(Scheme scheme, String lang) {
    final translator = CentralizedTranslator.instance;
    final pack = LanguagePackManager.instance;
    // A language with a rewriting engine turns English it has no stored text
    // for into a translation; any other language looks up exact dictionary
    // entries and otherwise keeps the English whole, never a word-by-word mix.
    final rewrites = translator.rewritesEnglish(lang);

    String? packed(String fieldName) {
      final value = pack.getField(
        lang: lang,
        entityType: 'scheme',
        entityId: scheme.id,
        fieldName: fieldName,
      );
      return value == null || value.isEmpty ? null : value;
    }

    String? kept(String field) {
      final value = scheme.nativeName(field, lang)?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    // Generic metadata (level, state, category...): exact tag or tag rewrite.
    String tag(String v) => translator.localizeTagFor(lang, v);
    // Short free text: exact phrase or full rewrite.
    String text(String v) => translator.localizeFor(lang, v);
    // Long prose is not looked up: only a rewriting engine touches it.
    String prose(String v) => rewrites ? translator.translate(v) : v;
    // Names of organisations: stored name, then translated.
    String body(String field, String v) =>
        scheme.nativeName(field, lang) ??
        (rewrites ? translator.translate(v) : tag(v));

    final storedName = kept('name') ?? packed('name');
    final name = storedName ?? prose(scheme.name);
    final benefits =
        kept('benefits') ?? packed('benefits_text') ?? prose(scheme.benefits);

    // The language's names of the required documents, stored alongside the
    // English list and keyed by the English name.
    final storedDocNames = scheme.extras.storedDocumentNames(lang);
    final docNames = <String, String>{
      if (storedDocNames.length == scheme.requiredDocuments.length)
        for (var i = 0; i < storedDocNames.length; i++)
          if (storedDocNames[i].isNotEmpty)
            scheme.requiredDocuments[i]: storedDocNames[i],
    };
    String orStored(String stored, String translated) =>
        stored.isNotEmpty ? stored : translated;
    // Document text with nothing stored: never a word-by-word mix (BUG-07).
    String docText(String v) =>
        rewrites ? _wholeOrOriginal(translator.translate(v), v) : text(v);

    return LocalizedScheme._(
      rawScheme: scheme,
      languageCode: lang,
      name: name,
      shortName:
          packed('short_name') ??
          scheme.nativeName('shortName', lang) ??
          (rewrites ? tag(scheme.shortName) : scheme.shortName),
      fullSchemeName:
          storedName ??
          (rewrites ? translator.translate(scheme.fullSchemeName) : name),
      ministry: body('ministry', scheme.ministry),
      department: body('department', scheme.department),
      implementingAgency: body('implementingAgency', scheme.implementingAgency),
      governmentLevel: tag(scheme.governmentLevel),
      sponsoringBody: body('sponsoringBody', scheme.sponsoringBody),
      issuingBody: body('issuingBody', scheme.issuingBody),
      state: tag(scheme.state),
      sector: tag(scheme.sector),
      targetBeneficiary: rewrites
          ? _wholeOrOriginal(
              translator.translate(scheme.targetBeneficiary),
              scheme.targetBeneficiary,
            )
          : tag(scheme.targetBeneficiary),
      schemeType: tag(scheme.schemeType),
      category: tag(scheme.category),
      overview:
          kept('overview') ??
          packed('summary') ??
          packed('description') ??
          prose(scheme.overview),
      objectives: packed('objective') ?? prose(scheme.objectives),
      benefits: benefits,
      subsidyAmount: text(scheme.subsidyAmount),
      verificationStatus: rewrites
          ? translator.translate(scheme.verificationStatus)
          : tag(scheme.verificationStatus),
      verificationNotes: text(scheme.verificationNotes),
      lastUpdated: scheme.lastUpdated,
      glanceChips: scheme.glanceChips.map(tag).toList(),
      benefitTypesList: scheme.benefitTypesList.map(tag).toList(),
      capitalSubsidyDetails: text(scheme.capitalSubsidyDetails),
      interestSubventionDetails: text(scheme.interestSubventionDetails),
      marginMoneyDetails: text(scheme.marginMoneyDetails),
      loanGuaranteeDetails: text(scheme.loanGuaranteeDetails),
      supportTypes: scheme.supportTypes.map(tag).toList(),
      rawBenefitsDisplayText: benefits,
      eligibilityAgeRange: text(scheme.eligibilityAgeRange),
      turnoverLimits: text(scheme.turnoverLimits),
      investmentLimits: text(scheme.investmentLimits),
      allowedBusinessTypes: scheme.allowedBusinessTypes.map(tag).toList(),
      educationRequirements: text(scheme.educationRequirements),
      mandatoryConditions: scheme.mandatoryConditions.map(text).toList(),
      optionalConditions: scheme.optionalConditions.map(text).toList(),
      specialCategories: scheme.specialCategories.map(tag).toList(),
      applicationFee: text(scheme.applicationFee),
      processingDurationDays: text(scheme.processingDurationDays),
      intakeTimelineText: text(scheme.intakeTimelineText),
      financeProductsSummary: scheme.financeProductsSummary.map(text).toList(),
      taxExemptionsSummary: scheme.taxExemptionsSummary.map(text).toList(),
      applicableTaxesList: scheme.applicableTaxesList.map(tag).toList(),
      knowledgeGuidanceList: scheme.knowledgeGuidanceList.map(text).toList(),
      helplineContactsMap: scheme.helplineContactsMap,
      eligibilityCriteria: _storedEligibility(
        scheme,
        lang,
        fallback: (l) => l.map(prose).toList(),
      ),
      requiredDocuments: [
        for (final d in scheme.requiredDocuments) docNames[d] ?? docText(d),
      ],
      applicationProcess: _storedSteps(
        scheme,
        lang,
        fallback: (l) => l.map(prose).toList(),
      ),
      documents: scheme.documents
          .map(
            // Text stored in the catalogue record first, then the dictionary,
            // then the original English.
            (d) => d.copyWith(
              name: orStored(
                d.translated('name', lang),
                docNames[d.name] ?? docText(d.name),
              ),
              description: orStored(
                d.translated('description', lang),
                docText(d.description),
              ),
              issuingAuthority: orStored(
                d.translated('issuingAuthority', lang),
                docText(d.issuingAuthority),
              ),
              estimatedCost: orStored(
                d.translated('estimatedCost', lang),
                docText(d.estimatedCost),
              ),
              // Canonical flag ("Yes"/"Required"): `isMandatory` reads it and
              // the details screen shows the localized badge itself.
              mandatory: d.mandatory,
              remarks: orStored(
                d.translated('remarks', lang),
                docText(d.remarks),
              ),
            ),
          )
          .toList(),
      requiredServices: scheme.requiredServices
          .map(
            (s) => SchemeService(
              name: orStored(s.translated('name', lang), text(s.name)),
              category: orStored(
                s.translated('category', lang),
                tag(s.category),
              ),
              mandatory: s.mandatory,
              description: orStored(
                s.translated('description', lang),
                text(s.description),
              ),
              purpose: orStored(s.translated('purpose', lang), text(s.purpose)),
              department: orStored(
                s.translated('department', lang),
                text(s.department),
              ),
              website: s.website,
              contact: s.contact,
              status: s.status,
              notes: orStored(s.translated('notes', lang), text(s.notes)),
              translations: s.translations,
            ),
          )
          .toList(),
      faqs: scheme.faqs
          .map(
            (faq) => {
              'question': text(faq['question'] ?? ''),
              'answer': text(faq['answer'] ?? ''),
            },
          )
          .toList(),
    );
  }
}

/// Remembers each scheme's localized copy per language.
///
/// Building a [LocalizedScheme] runs dozens of dictionary and language-pack
/// lookups (about 55 ms per scheme in a debug build). Cards called it again on
/// every rebuild -- Home, Saved, search results -- which was the main cause of
/// the app hanging. The copy only changes when the translation data does, so
/// it is cached per scheme object and dropped whenever the dictionary or a
/// language pack is (re)loaded ([invalidate]). A reloaded catalog builds new
/// Scheme objects, which start with an empty cache.
abstract final class LocalizedSchemeCache {
  static final Expando<Map<String, LocalizedScheme>> _cache = Expando(
    'localized',
  );
  static int _generation = 0;
  static final Expando<int> _builtAt = Expando('localizedGeneration');

  /// Forget every cached copy (translations changed).
  static void invalidate() => _generation++;

  static LocalizedScheme of(Scheme scheme, String languageCode) {
    if (_builtAt[scheme] != _generation) {
      _cache[scheme] = {};
      _builtAt[scheme] = _generation;
    }
    final byLanguage = _cache[scheme]!;
    return byLanguage[languageCode] ??= LocalizedScheme.fromScheme(
      scheme,
      languageCode,
    );
  }
}

extension SchemeLocalizationExtension on Scheme {
  LocalizedScheme toLocalized(String languageCode) =>
      LocalizedSchemeCache.of(this, languageCode);
}
