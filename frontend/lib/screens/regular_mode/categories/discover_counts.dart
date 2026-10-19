import 'package:flutter/material.dart';
import '../../../models/scheme_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';

/// Localized display label for a fixed app-taxonomy category / section name.
///
/// The category taxonomy is a fixed in-app list (not catalog rows), so its
/// Tamil lives in the ARB. Unknown values (e.g. already-localized section
/// headers) pass through unchanged.
String localizedCategoryLabel(BuildContext context, String enTitle) {
  final l = context.l10n;
  switch (enTitle) {
    case 'Business & MSME':
      return l.catBusinessMsme;
    case 'Startup & Incubation':
      return l.catStartupIncubation;
    case 'Loans & Credit Support':
      return l.catLoansCreditSupport;
    case 'Women Entrepreneurship':
      return l.catWomenEntrepreneurship;
    case 'Finance & Banking':
      return l.catFinanceBanking;
    case 'Skill Development':
      return l.catSkillDevelopment;
    case 'Artisan & Craftsmen':
      return l.catArtisanCraftsmen;
    case 'Digital India & Tech':
      return l.catDigitalIndiaTech;
    case 'Student & Youth Startups':
      return l.catStudentYouthStartups;
    case 'Manufacturing & Industry':
      return l.catManufacturingIndustry;
    case 'Export & Trade Promotion':
      return l.catExportTradePromotion;
    case 'Agriculture & Allied':
      return l.catAgricultureAllied;
    case 'Rural Development & SHG':
      return l.catRuralDevelopmentShg;
    case 'Technology & Innovation':
      return l.catTechnologyInnovation;
    case 'Khadi & Village Industries':
      return l.catKhadiVillageIndustries;
    case 'SC / ST & Minority':
      return l.catScStMinority;
    case 'Green Energy & Environment':
      return l.catGreenEnergyEnvironment;
    case 'Health & Healthcare':
      return l.catHealthHealthcare;
    case 'Food Processing':
      return l.catFoodProcessing;
    case 'Education & Fellowship':
      return l.catEducationFellowship;
    case 'Infrastructure & Logistics':
      return l.catInfrastructureLogistics;
    case 'Social Welfare & Support':
      return l.catSocialWelfareSupport;
    case 'Renewable & Energy Efficiency':
      return l.catRenewableEnergyEfficiency;
    default:
      return enTitle;
  }
}

/// Localized display label for ministry / state names.
///
/// These are bounded catalog-derived proper nouns, so they route through the
/// sanctioned runtime EN->TA engine ([CentralizedTranslator]) in Tamil mode
/// and stay verbatim in English mode.
String localizedProperName(String enName, AppProvider provider) {
  return CentralizedTranslator.instance.localizeFor(
    provider.selectedLanguage,
    enName,
  );
}

/// DiscoverCounts
/// ──────────────
/// Deterministic, connectivity-independent derivation of the Discover tab's
/// per-grouping scheme counts, computed entirely from the offline catalog
/// (`SchemeRepository.getAllSchemes()` == `bundle.schemes`, one row per scheme of
/// `scheme_catalog.json`). One row == one scheme, everywhere.
///
/// This replaces the previous `_loadDynamicCounts()` implementation, which
/// called `repo.getSchemesByCategory/Ministry/State(name).length` — a loose
/// keyword `.where()` over `category`/`searchKeywords`/`overview`/`benefits`
/// that (a) hit `/v1/search` when online, so counts changed with
/// connectivity, (b) double-counted categories, (c) inflated ministries via
/// free-text "finance"/"rural" matches in overview prose, and (d) inflated
/// every state because `getSchemesByState` treated every central / "all
/// india" / blank-state scheme as matching *every* state name.
///
/// Design decisions (see PR body):
///   • State  — a scheme counts for a state if it is nationally applicable
///     (central / central+state / Pan-India) OR its own `state` field names
///     that state. The central-schemes-count-for-every-state overlap is
///     INTENTIONAL and honest: those schemes genuinely apply there. Tamil
///     Nadu therefore legitimately shows more than Maharashtra (it has
///     state-scoped schemes on top of the national baseline).
///   • Ministry — matched on the structured `ministry` field (falling back to
///     `sponsoringBody`), via a small normalized-alias map. NOT a substring
///     search of overview text. Ministries with no schemes legitimately
///     show 0 ("Updating Soon").
///   • Category — the curated Discover categories ("Women Entrepreneurship",
///     "Startup & Incubation", …) are marketing concepts that do not map to
///     any single structured field (the catalog's `sectors`/`schemeType`/
///     `tags` are empty on most schemes — Phase 1 finding). So category uses
///     an explicit, fixed keyword predicate over the scheme's structured +
///     descriptive text. Categories deliberately OVERLAP (a scheme can be
///     both "Startup" and "Women Entrepreneurship"), so `sum(category
///     counts) > scheme count` by construction — this is reported, not hidden, and
///     there is no "fall back to MSME schemes when nothing matches" inflation.
class DiscoverCounts {
  DiscoverCounts._();

  /// Curated category cards shown on Discover (mirrors the labels the screen
  /// looks up in `_dynamicCategoryCounts`).
  static const List<String> categoryLabels = [
    'Business & MSME',
    'Startup & Incubation',
    'Loans & Credit Support',
    'Women Entrepreneurship',
    'Finance & Banking',
    'Skill Development',
    'Artisan & Craftsmen',
    'Digital India & Tech',
    'Student & Youth Startups',
    'Manufacturing & Industry',
    'Export & Trade Promotion',
    'Agriculture & Allied',
    'Rural Development & SHG',
    'Technology & Innovation',
    'Khadi & Village Industries',
    'SC / ST & Minority',
    'Green Energy & Environment',
    'Health & Healthcare',
    'Food Processing',
    'Education & Fellowship',
    'Infrastructure & Logistics',
    'Social Welfare & Support',
    'Renewable & Energy Efficiency',
    // Short aliases still referenced by older curated collections / tests.
    'Startup',
    'Finance',
    'Artisan',
    'Digital India',
    'Women Entrepreneurs',
    'Student Startups',
  ];

  static const List<String> ministryLabels = [
    'Ministry of MSME',
    'Ministry of Education',
    'Ministry of Finance',
    'Ministry of Agriculture',
    'Ministry of Rural Development',
    'Ministry of Skill Development',
    'Ministry of Social Justice',
    'Ministry of Housing',
    'Ministry of Health',
  ];

  static const List<String> stateLabels = [
    'Tamil Nadu',
    'Maharashtra',
    'Uttar Pradesh',
    'Karnataka',
    'Gujarat',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Haryana',
    'Himachal Pradesh',
    'Jammu & Kashmir',
    'Jharkhand',
    'Kerala',
    'Ladakh',
    'Madhya Pradesh',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Telangana',
    'Tripura',
    'Uttarakhand',
    'West Bengal',
  ];

  /// Fixed keyword predicate per curated category. Matched (case-insensitive
  /// substring) against a scheme's structured + descriptive text.
  static const Map<String, List<String>> _categoryKeywords = {
    'Business & MSME': [
      'msme',
      'micro enterprise',
      'small enterprise',
      'medium enterprise',
      'udyam',
      'micro, small',
    ],
    'Startup & Incubation': [
      'startup',
      'start-up',
      'incubat',
      'dpiit',
      'seed fund',
      'accelerator',
    ],
    'Loans & Credit Support': [
      'loan',
      'credit',
      'collateral',
      'mudra',
      'cgtmse',
      'working capital',
      'term loan',
      'refinanc',
    ],
    'Women Entrepreneurship': ['women', 'mahila', 'female'],
    'Finance & Banking': [
      'bank',
      'finance',
      'financial',
      'venture capital',
      'equity',
      'credit guarantee',
      'sidbi',
    ],
    'Skill Development': [
      'skill',
      'training',
      'apprentice',
      'vocational',
      'upskill',
      'capacity building',
      'entrepreneurship development programme',
    ],
    'Artisan & Craftsmen': [
      'artisan',
      'craft',
      'handicraft',
      'handloom',
      'weaver',
      'vishwakarma',
      'coir',
      'pottery',
      'khadi',
    ],
    'Digital India & Tech': [
      'digital',
      'e-commerce',
      'e commerce',
      'ict',
      'online platform',
      'technology adoption',
    ],
    'Student & Youth Startups': [
      'student',
      'youth',
      'campus',
      'fellowship',
      'young entrepreneur',
    ],
    'Manufacturing & Industry': [
      'manufactur',
      'industr',
      'production',
      'plant & machinery',
      'lean',
      'factory',
      'zed',
    ],
    'Export & Trade Promotion': [
      'export',
      'trade promotion',
      'international market',
      'dgft',
      'foreign trade',
      'exhibition',
      'cross-border',
    ],
    'Agriculture & Allied': [
      'agricultur',
      'farmer',
      'agri ',
      'agri-',
      'horticultur',
      'allied',
      'dairy',
      'fisher',
      'animal husbandry',
      'agro',
    ],
    'Rural Development & SHG': [
      'rural',
      'shg',
      'self help',
      'self-help',
      'livelihood',
      'village',
      'panchayat',
    ],
    'Technology & Innovation': [
      'innovat',
      'r&d',
      'research',
      'patent',
      'deep tech',
      'technolog',
    ],
    'Khadi & Village Industries': [
      'khadi',
      'village industr',
      'pmegp',
      'honey mission',
      'kvic',
    ],
    'SC / ST & Minority': [
      'sc/st',
      'sc / st',
      'sc-st',
      'scheduled caste',
      'scheduled tribe',
      'minorit',
      'dalit',
      'adivasi',
    ],
    'Green Energy & Environment': [
      'green',
      'environment',
      'clean tech',
      'pollution',
      'sustainab',
      'carbon',
      'effluent',
      'eco-friendly',
    ],
    'Health & Healthcare': [
      'health',
      'hospital',
      'medical',
      'ayushman',
      'wellness',
      'pharma',
    ],
    'Food Processing': [
      'food processing',
      'pmfme',
      'cold chain',
      'food safety',
      'agro processing',
      'micro food',
    ],
    'Education & Fellowship': [
      'education',
      'scholarship',
      'fellowship',
      'research grant',
      'academ',
    ],
    'Infrastructure & Logistics': [
      'infrastructure',
      'logistic',
      'industrial park',
      'cluster',
      'warehous',
      'common facility',
      'flatted factory',
    ],
    'Social Welfare & Support': [
      'welfare',
      'social security',
      'pension',
      'maternity',
      'rehabilitat',
      'differently abled',
      'disabilit',
      'insurance',
    ],
    'Renewable & Energy Efficiency': [
      'renewable',
      'energy efficiency',
      'solar',
      'power backup',
      'energy conservation',
      'energy audit',
    ],
    'Startup': ['startup', 'start-up', 'incubat', 'dpiit', 'seed fund'],
    'Finance': ['finance', 'financial', 'loan', 'credit', 'bank', 'sidbi'],
    'Artisan': [
      'artisan',
      'craft',
      'handicraft',
      'handloom',
      'weaver',
      'vishwakarma',
    ],
    'Digital India': ['digital', 'e-commerce', 'e commerce', 'ict'],
    'Women Entrepreneurs': ['women', 'mahila', 'female'],
    'Student Startups': ['student', 'youth', 'campus', 'fellowship'],
  };

  /// Normalized aliases for ministry-name matching against the structured
  /// `ministry` / `sponsoringBody` field (never overview text).
  static const Map<String, List<String>> _ministryAliases = {
    'Ministry of MSME': ['micro, small', 'msme'],
    'Ministry of Education': [
      'ministry of education',
      'department of higher education',
      'department of school education',
    ],
    'Ministry of Finance': [
      'ministry of finance',
      'department of financial services',
      'department of economic affairs',
    ],
    'Ministry of Agriculture': [
      'ministry of agriculture',
      'agriculture & farmers',
      'agriculture and farmers',
    ],
    'Ministry of Rural Development': ['rural development'],
    'Ministry of Skill Development': ['skill development'],
    'Ministry of Social Justice': ['social justice'],
    'Ministry of Housing': ['housing and urban', 'housing & urban'],
    'Ministry of Health': [
      'health and family welfare',
      'health & family welfare',
      'ministry of health',
    ],
  };

  static String _composite(Scheme s) =>
      ('${s.name} ${s.shortName} ${s.category} ${s.schemeType} ${s.sector} '
              '${s.targetBeneficiary} ${s.searchKeywords} ${s.overview} ${s.benefits}')
          .toLowerCase();

  /// A scheme that applies across India regardless of the user's state:
  /// central / central+state government level, or a Pan-India / All-India /
  /// blank state field.
  static bool nationallyApplicable(Scheme s) {
    final level = s.governmentLevel.toLowerCase();
    final state = s.state.toLowerCase();
    return level.contains('central') ||
        state.contains('pan-india') ||
        state.contains('all india') ||
        state.trim().isEmpty;
  }

  static bool matchesCategory(Scheme s, String label) {
    final keywords = _categoryKeywords[label];
    if (keywords == null || keywords.isEmpty) return false;
    final hay = _composite(s);
    return keywords.any(hay.contains);
  }

  static bool matchesMinistry(Scheme s, String label) {
    final aliases = _ministryAliases[label] ?? <String>[label.toLowerCase()];
    final hay = (s.ministry.isNotEmpty ? s.ministry : s.sponsoringBody)
        .toLowerCase();
    return aliases.any(hay.contains);
  }

  static bool matchesState(Scheme s, String label) {
    if (nationallyApplicable(s)) return true;
    return s.state.toLowerCase().contains(label.toLowerCase());
  }

  /// The exact rows [compute] counted for ([label], [kind]) — so the
  /// drilldown list opened from a Discover card can never disagree with the
  /// number printed on that card. [kind] is 'category' | 'ministry' | 'state'.
  static List<Scheme> schemesFor(
    String label,
    String kind,
    List<Scheme> schemes,
  ) {
    switch (kind) {
      case 'ministry':
        return schemes.where((s) => matchesMinistry(s, label)).toList();
      case 'state':
        return schemes.where((s) => matchesState(s, label)).toList();
      case 'category':
      default:
        return schemes.where((s) => matchesCategory(s, label)).toList();
    }
  }

  /// Computes every displayed grouping count from [schemes]. Deterministic:
  /// the same input always yields the same map.
  static Map<String, int> compute(List<Scheme> schemes) {
    final counts = <String, int>{};
    for (final label in categoryLabels) {
      counts[label] = schemes.where((s) => matchesCategory(s, label)).length;
    }
    for (final label in ministryLabels) {
      counts[label] = schemes.where((s) => matchesMinistry(s, label)).length;
    }
    for (final label in stateLabels) {
      counts[label] = schemes.where((s) => matchesState(s, label)).length;
    }
    return counts;
  }
}
