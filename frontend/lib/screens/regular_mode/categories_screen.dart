import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/scheme_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/centralized_translator.dart';
import '../../utils/responsive.dart';
import '../../widgets/smart_assessment_bottom_sheet.dart';
import 'search_results_screen.dart';
import '../../utils/app_spacing.dart';

String _getLocalizedCategoryOrMinistry(String text, String langCode) {
  if (langCode != 'ta') return text;

  final lower = text.toLowerCase().trim();
  if (lower.contains('msme')) return 'MSME (குறு, சிறு & நடுத்தர தொழில்கள்)';
  if (lower.contains('startup & incubation') || lower.contains('startup')) {
    return 'ஸ்டார்ட்அப் & உறைவிடங்கள்';
  }
  if (lower.contains('loans & credit') ||
      lower.contains('finance & banking') ||
      lower.contains('finance') ||
      lower.contains('credit')) {
    return 'கடன்கள் & நிதி ஆதரவு';
  }
  if (lower.contains('women')) return 'பெண் தொழில்முனைவோர்';
  if (lower.contains('skill')) return 'திறன் மேம்பாடு & பயிற்சி';
  if (lower.contains('artisan') || lower.contains('craftsmen')) {
    return 'கைவினைஞர்கள் & கைவினை';
  }
  if (lower.contains('digital')) return 'டிஜிட்டல் இந்தியா & தொழில்நுட்பம்';
  if (lower.contains('student')) return 'மாணவர் & இளைஞர் ஸ்டார்ட்அப்கள்';
  if (lower.contains('manufacturing')) return 'உற்பத்தி & தொழில் துறை';
  if (lower.contains('export')) return 'ஏற்றுமதி & வர்த்தக ஊக்குவிப்பு';
  if (lower.contains('agriculture') || lower.contains('farmer')) {
    return 'விவசாயம் & சார்ந்த துறைகள்';
  }
  if (lower.contains('rural') || lower.contains('shg')) {
    return 'ஊரக வளர்ச்சி & சுய உதவிக் குழுக்கள்';
  }
  if (lower.contains('technology') || lower.contains('innovation')) {
    return 'தொழில்நுட்பம் & புதுமை';
  }
  if (lower.contains('khadi')) return 'கதர் & கிராமத் தொழில்கள்';
  if (lower.contains('sc / st') || lower.contains('minority')) {
    return 'SC / ST & சிறுபான்மையினர்';
  }
  if (lower.contains('green energy') || lower.contains('environment')) {
    return 'பசுமை ஆற்றல் & சுற்றுச்சூழல்';
  }
  if (lower.contains('health')) return 'சுகாதாரம் & நல்வாழ்வு';
  if (lower.contains('food processing')) return 'உணவு பதப்படுத்துதல்';
  if (lower.contains('education') || lower.contains('fellowship')) {
    return 'கல்வி & உதவித்தொகை';
  }
  if (lower.contains('infrastructure') || lower.contains('logistics')) {
    return 'உள்கட்டமைப்பு & தளவாடங்கள்';
  }
  if (lower.contains('social welfare')) return 'சமூக நலம் & ஆதரவு';
  if (lower.contains('renewable')) return 'புதுப்பிக்கத்தக்க ஆற்றல்';

  if (lower.contains('ministry of msme')) return 'MSME அமைச்சகம்';
  if (lower.contains('ministry of finance')) return 'நிதி அமைச்சகம்';
  if (lower.contains('ministry of rural')) return 'ஊரக வளர்ச்சி அமைச்சகம்';
  if (lower.contains('ministry of education')) return 'கல்வி அமைச்சகம்';
  if (lower.contains('ministry of agriculture')) return 'விவசாய அமைச்சகம்';
  if (lower.contains('ministry of skill')) return 'திறன் மேம்பாட்டு அமைச்சகம்';
  if (lower.contains('ministry of social justice')) return 'சமூக நீதி அமைச்சகம்';
  if (lower.contains('ministry of housing')) return 'வீட்டுவசதி & நகர்ப்புற அமைச்சகம்';
  if (lower.contains('ministry of health')) return 'சுகாதார அமைச்சகம்';

  if (lower.contains('tamil nadu')) return 'தமிழ்நாடு';
  if (lower.contains('maharashtra')) return 'மகாராஷ்டிரா';
  if (lower.contains('uttar pradesh')) return 'உத்தரப் பிரதேசம்';
  if (lower.contains('karnataka')) return 'கர்நாடகா';
  if (lower.contains('gujarat')) return 'குஜராத்';
  if (lower.contains('andhra pradesh')) return 'ஆந்திரப் பிரதேசம்';
  if (lower.contains('kerala')) return 'கேரளா';
  if (lower.contains('delhi')) return 'டெல்லி';
  if (lower.contains('punjab')) return 'பஞ்சாப்';
  if (lower.contains('rajasthan')) return 'ராஜஸ்தான்';
  if (lower.contains('telangana')) return 'தெலுங்கானா';
  if (lower.contains('west bengal')) return 'மேற்கு வங்காளம்';

  if (lower == 'by category') return 'பிரிவுகள் வாரியாக';
  if (lower == 'by ministry') return 'அமைச்சகங்கள் வாரியாக';
  if (lower == 'by state') return 'மாநிலங்கள் வாரியாக';
  if (lower == 'all categories') return 'அனைத்து பிரிவுகளும்';
  if (lower == 'all ministries') return 'அனைத்து அமைச்சகங்களும்';
  if (lower == 'all states') return 'அனைத்து மாநிலங்களும்';
  if (lower == 'by stage') return 'வளர்ச்சி நிலை வாரியாக';
  if (lower == 'popular') return 'பிரபலமானவை';
  if (lower == 'newly added') return 'சமீபத்தில் சேர்க்கப்பட்டவை';

  return text;
}

/// DiscoverCounts
/// ──────────────
/// Deterministic, connectivity-independent derivation of the Discover tab's
/// per-grouping scheme counts, computed entirely from the offline catalog
/// (`SchemeRepository.getAllSchemes()` == `bundle.schemes`, the 219 rows of
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
///     counts) > 219` by construction — this is reported, not hidden, and
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
      'msme', 'micro enterprise', 'small enterprise', 'medium enterprise',
      'udyam', 'micro, small'
    ],
    'Startup & Incubation': [
      'startup', 'start-up', 'incubat', 'dpiit', 'seed fund', 'accelerator'
    ],
    'Loans & Credit Support': [
      'loan', 'credit', 'collateral', 'mudra', 'cgtmse', 'working capital',
      'term loan', 'refinanc'
    ],
    'Women Entrepreneurship': ['women', 'mahila', 'female'],
    'Finance & Banking': [
      'bank', 'finance', 'financial', 'venture capital', 'equity',
      'credit guarantee', 'sidbi'
    ],
    'Skill Development': [
      'skill', 'training', 'apprentice', 'vocational', 'upskill',
      'capacity building', 'entrepreneurship development programme'
    ],
    'Artisan & Craftsmen': [
      'artisan', 'craft', 'handicraft', 'handloom', 'weaver', 'vishwakarma',
      'coir', 'pottery', 'khadi'
    ],
    'Digital India & Tech': [
      'digital', 'e-commerce', 'e commerce', 'ict', 'online platform',
      'technology adoption'
    ],
    'Student & Youth Startups': [
      'student', 'youth', 'campus', 'fellowship', 'young entrepreneur'
    ],
    'Manufacturing & Industry': [
      'manufactur', 'industr', 'production', 'plant & machinery', 'lean',
      'factory', 'zed'
    ],
    'Export & Trade Promotion': [
      'export', 'trade promotion', 'international market', 'dgft',
      'foreign trade', 'exhibition', 'cross-border'
    ],
    'Agriculture & Allied': [
      'agricultur', 'farmer', 'agri ', 'agri-', 'horticultur', 'allied',
      'dairy', 'fisher', 'animal husbandry', 'agro'
    ],
    'Rural Development & SHG': [
      'rural', 'shg', 'self help', 'self-help', 'livelihood', 'village',
      'panchayat'
    ],
    'Technology & Innovation': [
      'innovat', 'r&d', 'research', 'patent', 'deep tech', 'technolog'
    ],
    'Khadi & Village Industries': [
      'khadi', 'village industr', 'pmegp', 'honey mission', 'kvic'
    ],
    'SC / ST & Minority': [
      'sc/st', 'sc / st', 'sc-st', 'scheduled caste', 'scheduled tribe',
      'minorit', 'dalit', 'adivasi'
    ],
    'Green Energy & Environment': [
      'green', 'environment', 'clean tech', 'pollution', 'sustainab',
      'carbon', 'effluent', 'eco-friendly'
    ],
    'Health & Healthcare': [
      'health', 'hospital', 'medical', 'ayushman', 'wellness', 'pharma'
    ],
    'Food Processing': [
      'food processing', 'pmfme', 'cold chain', 'food safety',
      'agro processing', 'micro food'
    ],
    'Education & Fellowship': [
      'education', 'scholarship', 'fellowship', 'research grant', 'academ'
    ],
    'Infrastructure & Logistics': [
      'infrastructure', 'logistic', 'industrial park', 'cluster', 'warehous',
      'common facility', 'flatted factory'
    ],
    'Social Welfare & Support': [
      'welfare', 'social security', 'pension', 'maternity', 'rehabilitat',
      'differently abled', 'disabilit', 'insurance'
    ],
    'Renewable & Energy Efficiency': [
      'renewable', 'energy efficiency', 'solar', 'power backup',
      'energy conservation', 'energy audit'
    ],
    'Startup': ['startup', 'start-up', 'incubat', 'dpiit', 'seed fund'],
    'Finance': ['finance', 'financial', 'loan', 'credit', 'bank', 'sidbi'],
    'Artisan': [
      'artisan', 'craft', 'handicraft', 'handloom', 'weaver', 'vishwakarma'
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
      'ministry of education', 'department of higher education',
      'department of school education'
    ],
    'Ministry of Finance': [
      'ministry of finance', 'department of financial services',
      'department of economic affairs'
    ],
    'Ministry of Agriculture': [
      'ministry of agriculture', 'agriculture & farmers',
      'agriculture and farmers'
    ],
    'Ministry of Rural Development': ['rural development'],
    'Ministry of Skill Development': ['skill development'],
    'Ministry of Social Justice': ['social justice'],
    'Ministry of Housing': ['housing and urban', 'housing & urban'],
    'Ministry of Health': [
      'health and family welfare', 'health & family welfare',
      'ministry of health'
    ],
  };

  static String _composite(Scheme s) => (
        '${s.name} ${s.shortName} ${s.category} ${s.schemeType} ${s.sector} '
        '${s.targetBeneficiary} ${s.searchKeywords} ${s.overview} ${s.benefits}'
      ).toLowerCase();

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
    final hay =
        (s.ministry.isNotEmpty ? s.ministry : s.sponsoringBody).toLowerCase();
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

class CategoryItem {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const CategoryItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.onCategorySelected});

  final ValueChanged<String>? onCategorySelected;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _scrollController = ScrollController();

  // Section keys for scrolling
  final GlobalKey _categorySectionKey = GlobalKey();
  final GlobalKey _ministrySectionKey = GlobalKey();
  final GlobalKey _stateSectionKey = GlobalKey();

  Map<String, int> _dynamicCategoryCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDynamicCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDynamicCounts();
  }

  Future<void> _loadDynamicCounts() async {
    try {
      // Derive every Discover count from the offline catalog's structured
      // fields (219 rows) via [DiscoverCounts] — no /v1/search, no keyword
      // sweep of overview prose, no hardcoded totals, connectivity-independent.
      final schemes = await SchemeRepository.instance.getAllSchemes();
      final counts = DiscoverCounts.compute(schemes);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _dynamicCategoryCounts = counts;
        });
      });
    } catch (e) {
      debugPrint('[CategoriesScreen] error loading dynamic counts: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Full 23 categories for the "View All" bottom sheet
  static const List<CategoryItem> allCategoriesList = [
    CategoryItem(
      title: 'Business & MSME',
      description:
          'Subsidized loans, credit guarantees, and setup support for micro, small & medium businesses',
      icon: Icons.domain,
      iconColor: Color(0xFF00796B),
      backgroundColor: Color(0xFFE0F2F1),
    ),
    CategoryItem(
      title: 'Startup & Incubation',
      description:
          'Seed funding, grants, incubation, and equity assistance programs',
      icon: Icons.rocket_launch,
      iconColor: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFFF3E5F5),
    ),
    CategoryItem(
      title: 'Loans & Credit Support',
      description:
          'Collateral-free loans, interest subvention, and institutional credit schemes',
      icon: Icons.monetization_on,
      iconColor: Color(0xFF2563EB),
      backgroundColor: Color(0xFFE0F2FE),
    ),
    CategoryItem(
      title: 'Women Entrepreneurship',
      description:
          'Specialized finance, capital subsidies, and resources for women-owned businesses',
      icon: Icons.person,
      iconColor: Color(0xFFD81B60),
      backgroundColor: Color(0xFFFCE4EC),
    ),
    CategoryItem(
      title: 'Finance & Banking',
      description:
          'Banking linkages, financial inclusion, and formal credit access schemes',
      icon: Icons.account_balance,
      iconColor: Color(0xFF1E88E5),
      backgroundColor: Color(0xFFE3F2FD),
    ),
    CategoryItem(
      title: 'Skill Development',
      description:
          'Free vocational training, certification, and skill upgradation programs',
      icon: Icons.trending_up,
      iconColor: Color(0xFF43A047),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    CategoryItem(
      title: 'Artisan & Craftsmen',
      description:
          'Toolkits distribution, market linkages, and exhibitions for traditional craftspeople',
      icon: Icons.brush,
      iconColor: Color(0xFF6D4C41),
      backgroundColor: Color(0xFFEFEBE9),
    ),
    CategoryItem(
      title: 'Digital India & Tech',
      description:
          'Digital enablement, technology adoption, and e-commerce onboardings',
      icon: Icons.desktop_windows,
      iconColor: Color(0xFF0288D1),
      backgroundColor: Color(0xFFE1F5FE),
    ),
    CategoryItem(
      title: 'Student & Youth Startups',
      description:
          'Student entrepreneurship, innovation challenges, and campus incubations',
      icon: Icons.school_outlined,
      iconColor: Color(0xFF5E35B1),
      backgroundColor: Color(0xFFEDE7F6),
    ),
    CategoryItem(
      title: 'Manufacturing & Industry',
      description:
          'Capital subsidies, Lean manufacturing, and modern tooling assistance',
      icon: Icons.precision_manufacturing,
      iconColor: Color(0xFF3949AB),
      backgroundColor: Color(0xFFE8EAF6),
    ),
    CategoryItem(
      title: 'Export & Trade Promotion',
      description:
          'International exhibitions, export freight support, and global market access',
      icon: Icons.local_shipping,
      iconColor: Color(0xFF00897B),
      backgroundColor: Color(0xFFE0F2F1),
    ),
    CategoryItem(
      title: 'Agriculture & Allied',
      description:
          'Agri-tech, post-harvest infrastructure, and farmer producer support',
      icon: Icons.agriculture,
      iconColor: Color(0xFF2E7D32),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    CategoryItem(
      title: 'Rural Development & SHG',
      description:
          'Self-help groups, community enterprises, and rural livelihood missions',
      icon: Icons.groups,
      iconColor: Color(0xFFE65100),
      backgroundColor: Color(0xFFFFF3E0),
    ),
    CategoryItem(
      title: 'Technology & Innovation',
      description:
          'R&D grants, patent filing reimbursements, and tech transfer support',
      icon: Icons.biotech,
      iconColor: Color(0xFF6A1B9A),
      backgroundColor: Color(0xFFF3E5F5),
    ),
    CategoryItem(
      title: 'Khadi & Village Industries',
      description:
          'PMEGP, honey mission, pottery, and rural khadi industry promotion',
      icon: Icons.store,
      iconColor: Color(0xFF8D6E63),
      backgroundColor: Color(0xFFD7CCC8),
    ),
    CategoryItem(
      title: 'SC / ST & Minority',
      description:
          'Concessional credit, capacity building, and preferential procurement',
      icon: Icons.diversity_3,
      iconColor: Color(0xFF00838F),
      backgroundColor: Color(0xFFE0F7FA),
    ),
    CategoryItem(
      title: 'Green Energy & Environment',
      description:
          'Cleaner tech adoption, energy conservation audits, and solar subsidies',
      icon: Icons.eco,
      iconColor: Color(0xFF558B2F),
      backgroundColor: Color(0xFFF1F8E9),
    ),
    CategoryItem(
      title: 'Health & Healthcare',
      description:
          'Ayushman Bharat, medical enterprise support, and wellness initiatives',
      icon: Icons.local_hospital,
      iconColor: Color(0xFFC2185B),
      backgroundColor: Color(0xFFFCE4EC),
    ),
    CategoryItem(
      title: 'Food Processing',
      description:
          'PMFME micro food enterprises, cold chain, and food safety certifications',
      icon: Icons.restaurant,
      iconColor: Color(0xFFD84315),
      backgroundColor: Color(0xFFFBE9E7),
    ),
    CategoryItem(
      title: 'Education & Fellowship',
      description:
          'Higher education grants, women researcher fellowships, and skill certs',
      icon: Icons.menu_book,
      iconColor: Color(0xFF1565C0),
      backgroundColor: Color(0xFFE3F2FD),
    ),
    CategoryItem(
      title: 'Infrastructure & Logistics',
      description:
          'Industrial park relocation, cluster development, and logistics support',
      icon: Icons.apartment,
      iconColor: Color(0xFF455A64),
      backgroundColor: Color(0xFFECEFF1),
    ),
    CategoryItem(
      title: 'Social Welfare & Support',
      description:
          'Maternity relief, rehabilitation, and social security assistances',
      icon: Icons.volunteer_activism,
      iconColor: Color(0xFFAD1457),
      backgroundColor: Color(0xFFFCE4EC),
    ),
    CategoryItem(
      title: 'Renewable & Energy Efficiency',
      description:
          'Solar power units, power backup subsidies, and green energy loans',
      icon: Icons.solar_power,
      iconColor: Color(0xFFF57F17),
      backgroundColor: Color(0xFFFFFDE7),
    ),
  ];

  // core curated horizontal collections matching mockup
  final List<Map<String, dynamic>> _displayCategories = [
    {
      'title': 'Business & MSME',
      'icon': Icons.domain,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Startup & Incubation',
      'icon': Icons.rocket_launch,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Loans & Credit Support',
      'icon': Icons.monetization_on,
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Women Entrepreneurship',
      'icon': Icons.person,
      'color': const Color(0xFF2563EB),
    },
  ];

  final List<Map<String, dynamic>> _displayMinistries = [
    {'title': 'Ministry of MSME'},
    {'title': 'Ministry of Finance'},
    {'title': 'Ministry of Rural Development'},
  ];

  final List<Map<String, dynamic>> _displayStates = [
    {'title': 'Tamil Nadu'},
    {'title': 'Maharashtra'},
    {'title': 'Uttar Pradesh'},
    {'title': 'Karnataka'},
    {'title': 'Gujarat'},
  ];

  void _showComingSoonInfo(String name, String type) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isTa = provider.selectedLanguage == 'ta';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.update_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                isTa ? 'விரைவில் புதுப்பிக்கப்படும்' : 'Updating Soon',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isTa
              ? '$name பிரிவிற்கான திட்டங்கள் தற்போது சேர்க்கப்பட்டு வருகின்றன. விரைவில் புதுப்பிக்கப்படும்!'
              : 'Schemes under "$name" are currently being verified and will be updated soon. Stay tuned!',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            ),
            child: Text(
              isTa ? 'சரி' : 'Got it',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSchemeCount(int? cnt, AppProvider provider) {
    if (cnt == null) return '...';
    if (cnt == 0) {
      return provider.selectedLanguage == 'ta'
          ? 'விரைவில் வரும்'
          : 'Updating Soon';
    }
    return context.l10n.schemeCountFormat(cnt);
  }

  void _onCategorySelected(String categoryName, AppProvider provider) {
    final count = _dynamicCategoryCounts[categoryName];
    if (count == 0) {
      _showComingSoonInfo(categoryName, 'category');
      return;
    }

    SmartAssessmentBottomSheet.show(
      context,
      categoryName,
      'category',
      () async {
        // Same derivation as the count on the card: the offline catalog
        // filtered through the exact DiscoverCounts predicate. Never the
        // connectivity-dependent /v1/search keyword path, so the list and
        // the number can never disagree.
        final all = await SchemeRepository.instance.getAllSchemes();
        final schemes =
            DiscoverCounts.schemesFor(categoryName, 'category', all);
        if (!mounted) return;
        if (schemes.isEmpty) {
          _showComingSoonInfo(categoryName, 'category');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              title: categoryName,
              type: 'category',
              initialSchemes: schemes,
            ),
          ),
        );
      },
    );
  }

  void _onMinistrySelected(String ministryName, AppProvider provider) {
    final count = _dynamicCategoryCounts[ministryName];
    if (count == 0) {
      _showComingSoonInfo(ministryName, 'ministry');
      return;
    }

    SmartAssessmentBottomSheet.show(
      context,
      ministryName,
      'ministry',
      () async {
        final all = await SchemeRepository.instance.getAllSchemes();
        final schemes =
            DiscoverCounts.schemesFor(ministryName, 'ministry', all);
        if (!mounted) return;
        if (schemes.isEmpty) {
          _showComingSoonInfo(ministryName, 'ministry');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              title: ministryName,
              type: 'ministry',
              initialSchemes: schemes,
            ),
          ),
        );
      },
    );
  }

  void _onStateSelected(String stateName, AppProvider provider) {
    final count = _dynamicCategoryCounts[stateName];
    if (count == 0) {
      _showComingSoonInfo(stateName, 'state');
      return;
    }

    SmartAssessmentBottomSheet.show(context, stateName, 'state', () async {
      final all = await SchemeRepository.instance.getAllSchemes();
      final schemes = DiscoverCounts.schemesFor(stateName, 'state', all);
      if (!mounted) return;
      if (schemes.isEmpty) {
        _showComingSoonInfo(stateName, 'state');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(
            title: stateName,
            type: 'state',
            initialSchemes: schemes,
          ),
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Slate 50 (Crisp clean background without blue shade)
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header (Discover, AI collections)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.discoverTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      context.l10n.exploreTopCuratedCollections,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [

                    // Section 1: By Category
                    _buildSectionHeader(
                      key: _categorySectionKey,
                      title: context.l10n.browseByCategories,
                      onViewAll: () =>
                          _showAllCategoriesBottomSheet(context, provider),
                    ),
                    _buildCategoryHorizontalList(provider),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: By Ministry
                    _buildSectionHeader(
                      key: _ministrySectionKey,
                      title: context.l10n.browseByMinistry,
                      onViewAll: () =>
                          _showAllMinistriesBottomSheet(context, provider),
                    ),
                    _buildMinistryHorizontalList(provider),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: By State
                    _buildSectionHeader(
                      key: _stateSectionKey,
                      title: context.l10n.browseByState,
                      onViewAll: () =>
                          _showAllStatesBottomSheet(context, provider),
                    ),
                    _buildStateHorizontalList(provider),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBusinessUtilitiesSection(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader({
    required GlobalKey key,
    required String title,
    VoidCallback? onViewAll,
  }) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final localizedTitle = _getLocalizedCategoryOrMinistry(
      title,
      provider.selectedLanguage,
    );

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FlexText(
            child: Text(
              localizedTitle,
              style: GoogleFonts.poppins(
                fontSize: provider.selectedLanguage == 'ta' ? 15.0 : 16.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.selectedLanguage == 'ta'
                          ? 'அனைத்தையும் பார்க்க'
                          : 'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.hairline),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryHorizontalList(AppProvider provider) {
    return SizedBox(
      height: provider.selectedLanguage == 'ta' ? 138 : 126,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _displayCategories.length,
        itemBuilder: (context, index) {
          final item = _displayCategories[index];
          final String title = item['title'] as String;
          final int? cnt = _dynamicCategoryCounts[title];
          final String countStr = _formatSchemeCount(cnt, provider);
          final String localizedTitle = _getLocalizedCategoryOrMinistry(
            title,
            provider.selectedLanguage,
          );
          final IconData icon = item['icon'] as IconData;

          return Container(
            width: 134,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => _onCategorySelected(title, provider),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.tight),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      localizedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: provider.selectedLanguage == 'ta'
                            ? 10.0
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        height: provider.selectedLanguage == 'ta' ? 1.3 : 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      countStr,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: cnt == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinistryHorizontalList(AppProvider provider) {
    return SizedBox(
      height: provider.selectedLanguage == 'ta' ? 138 : 126,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _displayMinistries.length,
        itemBuilder: (context, index) {
          final item = _displayMinistries[index];
          final String title = item['title'] as String;
          final int? cnt = _dynamicCategoryCounts[title];
          final String countStr = _formatSchemeCount(cnt, provider);
          final String localizedTitle = _getLocalizedCategoryOrMinistry(
            title,
            provider.selectedLanguage,
          );

          return Container(
            width: 134,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => _onMinistrySelected(title, provider),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ministry emblem stylized circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: Color(0xFF2563EB),
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      localizedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: provider.selectedLanguage == 'ta'
                            ? 10.0
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        height: provider.selectedLanguage == 'ta' ? 1.3 : 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      countStr,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: cnt == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStateMapAsset(String stateName) {
    final rawPath = _getStateMapAssetRaw(stateName);
    return rawPath.replaceAll(
      'assets/images/States and UTs/',
      'assets/images/States assets/',
    );
  }

  String _getStateMapAssetRaw(String stateName) {
    switch (stateName.toLowerCase().trim()) {
      case 'tamil nadu':
        return 'assets/images/States and UTs/States/Tamil nadu.webp';
      case 'maharashtra':
        return 'assets/images/States and UTs/States/maharashtra.webp';
      case 'uttar pradesh':
        return 'assets/images/States and UTs/States/uttar_pradesh.webp';
      case 'karnataka':
        return 'assets/images/States and UTs/States/karnataka.webp';
      case 'gujarat':
        return 'assets/images/States and UTs/States/gujarat.webp';
      case 'arunachal pradesh':
        return 'assets/images/States and UTs/States/Anrunachal pradhesh.webp';
      case 'assam':
        return 'assets/images/States and UTs/States/Assam.webp';
      case 'bihar':
        return 'assets/images/States and UTs/States/Bihar.webp';
      case 'chhattisgarh':
        return 'assets/images/States and UTs/States/Chhatishgar.webp';
      case 'kerala':
        return 'assets/images/States and UTs/States/Kerala.webp';
      case 'andhra pradesh':
        return 'assets/images/States and UTs/States/andhra pradesh.webp';
      case 'goa':
        return 'assets/images/States and UTs/States/goa.webp';
      case 'haryana':
        return 'assets/images/States and UTs/States/haryana.webp';
      case 'himachal pradesh':
        return 'assets/images/States and UTs/States/himachal pradesh.webp';
      case 'jharkhand':
        return 'assets/images/States and UTs/States/jharkhand.webp';
      case 'madhya pradesh':
        return 'assets/images/States and UTs/States/madhya pradesh.webp';
      case 'manipur':
        return 'assets/images/States and UTs/States/manipur.webp';
      case 'meghalaya':
        return 'assets/images/States and UTs/States/meghalaya.webp';
      case 'mizoram':
        return 'assets/images/States and UTs/States/mizoram.webp';
      case 'nagaland':
        return 'assets/images/States and UTs/States/nagaland.webp';
      case 'odisha':
        return 'assets/images/States and UTs/States/odisha.webp';
      case 'punjab':
        return 'assets/images/States and UTs/States/punjab.webp';
      case 'rajasthan':
        return 'assets/images/States and UTs/States/rajasthan.webp';
      case 'sikkim':
        return 'assets/images/States and UTs/States/sikkim.webp';
      case 'telangana':
        return 'assets/images/States and UTs/States/telangana.webp';
      case 'tripura':
        return 'assets/images/States and UTs/States/tripura.webp';
      case 'uttarakhand':
      case 'uttarkhand':
        return 'assets/images/States and UTs/States/uttarkhand.webp';
      case 'west bengal':
        return 'assets/images/States and UTs/States/west bengal.webp';
      default:
        return 'assets/images/States and UTs/States/Tamil nadu.webp';
    }
  }

  Widget _buildStateHorizontalList(AppProvider provider) {
    return SizedBox(
      height: provider.selectedLanguage == 'ta' ? 138 : 126,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _displayStates.length,
        itemBuilder: (context, index) {
          final item = _displayStates[index];
          final String title = item['title'] as String;
          final int? cnt = _dynamicCategoryCounts[title];
          final String countStr = _formatSchemeCount(cnt, provider);
          final String localizedTitle = _getLocalizedCategoryOrMinistry(
            title,
            provider.selectedLanguage,
          );

          return Container(
            width: 134,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => _onStateSelected(title, provider),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // State Map Image representation without background
                    Image.asset(
                      _getStateMapAsset(title),
                      width: 36,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(
                          size: const Size(36, 32),
                          painter: StateMapPainter(title),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      localizedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: provider.selectedLanguage == 'ta'
                            ? 10.0
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      countStr,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: cnt == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAllCategoriesBottomSheet(
    BuildContext context,
    AppProvider provider,
  ) {
    String modalSearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allCategoriesList.where((cat) {
              return cat.title.toLowerCase().contains(
                modalSearchQuery.toLowerCase(),
              );
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FlexText(
                          child: Text(
                            provider.selectedLanguage == 'ta'
                                ? 'அனைத்து பிரிவுகளும்'
                                : 'All Categories',
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                          ),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() {
                            modalSearchQuery = val;
                          });
                        },
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: provider.selectedLanguage == 'ta'
                              ? 'பிரிவுகளைத் தேடுங்கள்...'
                              : 'Search categories...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.sm,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        return _buildCategoryCard(context, category, provider);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryItem category,
    AppProvider provider,
  ) {
    final int? cnt = _dynamicCategoryCounts[category.title];
    final String countStr = _formatSchemeCount(cnt, provider);
    final String localizedTitle = _getLocalizedCategoryOrMinistry(
      category.title,
      provider.selectedLanguage,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Close sheet
            _onCategorySelected(category.title, provider);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: category.iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: AppSpacing.tight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.hairline),
                  child: Text(
                    localizedTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.hairline),
                Text(
                  countStr,
                  style: GoogleFonts.inter(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    color: cnt == 0
                        ? const Color(0xFFD97706)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllMinistriesBottomSheet(
    BuildContext context,
    AppProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final ministries = [
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

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FlexText(
                      child: Text(
                        provider.selectedLanguage == 'ta'
                            ? 'அனைத்து அமைச்சகங்களும்'
                            : 'All Ministries',
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: ministries.length,
                  itemBuilder: (context, index) {
                    final title = ministries[index];
                    final int? cnt = _dynamicCategoryCounts[title];
                    final String countStr = _formatSchemeCount(cnt, provider);
                    final String localizedTitle =
                        _getLocalizedCategoryOrMinistry(
                          title,
                          provider.selectedLanguage,
                        );

                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          localizedTitle,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          countStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: cnt == 0
                                ? const Color(0xFFD97706)
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _onMinistrySelected(title, provider);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllStatesBottomSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final states = [
          'Andhra Pradesh',
          'Arunachal Pradesh',
          'Assam',
          'Bihar',
          'Chhattisgarh',
          'Delhi',
          'Goa',
          'Gujarat',
          'Haryana',
          'Himachal Pradesh',
          'Jammu & Kashmir',
          'Jharkhand',
          'Karnataka',
          'Kerala',
          'Ladakh',
          'Madhya Pradesh',
          'Maharashtra',
          'Manipur',
          'Meghalaya',
          'Mizoram',
          'Nagaland',
          'Odisha',
          'Puducherry',
          'Punjab',
          'Rajasthan',
          'Sikkim',
          'Tamil Nadu',
          'Telangana',
          'Tripura',
          'Uttar Pradesh',
          'Uttarakhand',
          'West Bengal',
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FlexText(
                      child: Text(
                        provider.selectedLanguage == 'ta'
                            ? 'அனைத்து மாநிலங்களும்'
                            : 'All States & UTs',
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: states.length,
                  itemBuilder: (context, index) {
                    final title = states[index];
                    final int? cnt = _dynamicCategoryCounts[title];
                    final String countStr = _formatSchemeCount(cnt, provider);
                    final String localizedTitle =
                        _getLocalizedCategoryOrMinistry(
                          title,
                          provider.selectedLanguage,
                        );

                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        leading: Image.asset(
                          _getStateMapAsset(title),
                          width: 36,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return CustomPaint(
                              size: const Size(36, 32),
                              painter: StateMapPainter(title),
                            );
                          },
                        ),
                        title: Text(
                          localizedTitle,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          countStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: cnt == 0
                                ? const Color(0xFFD97706)
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _onStateSelected(title, provider);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusinessUtilitiesSection() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isTa = provider.selectedLanguage == 'ta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            isTa
                ? CentralizedTranslator.instance.translate(
                    'Business Utilities & Tools',
                  )
                : 'Business Utilities & Tools',
            style: GoogleFonts.poppins(
              fontSize: isTa ? 14.0 : 15.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _buildUtilityCard(
                icon: Icons.domain_verification,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Udyam Classifier',
                      )
                    : 'Udyam Classifier',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Check MSME tier',
                      )
                    : 'Check MSME tier',
                onTap: _openUdyamClassifier,
              ),
              _buildUtilityCard(
                icon: Icons.calculate_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Subsidy Estimator',
                      )
                    : 'Subsidy Estimator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Machinery subsidies',
                      )
                    : 'Machinery subsidies',
                onTap: _openSubsidyEstimator,
              ),
              _buildUtilityCard(
                icon: Icons.percent_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate('GST Calculator')
                    : 'GST Calculator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Compute GST invoice',
                      )
                    : 'Compute GST invoice',
                onTap: _openGstCalculator,
              ),
              _buildUtilityCard(
                icon: Icons.monetization_on_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate('EMI Calculator')
                    : 'EMI Calculator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Calculate loan EMIs',
                      )
                    : 'Calculate loan EMIs',
                onTap: _openEmiCalculator,
              ),
              _buildUtilityCard(
                icon: Icons.rocket_launch_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'DPIIT Eligibility',
                      )
                    : 'DPIIT Eligibility',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Check startup criteria',
                      )
                    : 'Check startup criteria',
                onTap: _openDpiitChecklist,
              ),
              _buildUtilityCard(
                icon: Icons.trending_up_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Valuation Estimator',
                      )
                    : 'Valuation Estimator',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Seed valuation ranges',
                      )
                    : 'Seed valuation ranges',
                onTap: _openValuationEstimator,
              ),
              _buildUtilityCard(
                icon: Icons.rule_folder_outlined,
                title: isTa
                    ? CentralizedTranslator.instance.translate('Doc Checklist')
                    : 'Doc Checklist',
                desc: isTa
                    ? CentralizedTranslator.instance.translate(
                        'Business setup docs',
                      )
                    : 'Business setup docs',
                onTap: _openDocumentChecklist,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUtilityCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 142,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(height: AppSpacing.tight),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUdyamClassifier() {
    final isTa =
        Provider.of<AppProvider>(context, listen: false).selectedLanguage ==
        'ta';
    final investmentController = TextEditingController();
    final turnoverController = TextEditingController();
    String result = '';
    String subResult = '';
    Color resultColor = const Color(0xFF1E293B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.domain_verification,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTa
                                  ? CentralizedTranslator.instance.translate(
                                      'Udyam MSME Classifier',
                                    )
                                  : 'Udyam MSME Classifier',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isTa
                                  ? CentralizedTranslator.instance.translate(
                                      'Classify your business under official government guidelines.',
                                    )
                                  : 'Classify your business under official government guidelines.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isTa
                        ? CentralizedTranslator.instance.translate(
                            'Investment in Plant & Machinery',
                          )
                        : 'Investment in Plant & Machinery',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: investmentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '0.5',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      suffixText: isTa ? 'கோடி' : 'Cr',
                      helperText: isTa
                          ? CentralizedTranslator.instance.translate(
                              'Enter original purchase value of machinery in Crores',
                            )
                          : 'Enter original purchase value of machinery in Crores',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      suffixStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isTa
                        ? CentralizedTranslator.instance.translate(
                            'Annual Turnover',
                          )
                        : 'Annual Turnover',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: turnoverController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '3.0',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      suffixText: isTa ? 'கோடி' : 'Cr',
                      helperText: isTa
                          ? CentralizedTranslator.instance.translate(
                              'Enter total revenue/sales of last financial year in Crores',
                            )
                          : 'Enter total revenue/sales of last financial year in Crores',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      suffixStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (result.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: resultColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: resultColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTa
                                          ? CentralizedTranslator.instance
                                                .translate(
                                                  'Classification Result',
                                                )
                                          : 'Classification Result',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      isTa
                                          ? CentralizedTranslator.instance
                                                .translate(result)
                                          : result,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: resultColor,
                                      ),
                                    ),
                                    if (subResult.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        isTa
                                            ? CentralizedTranslator.instance
                                                  .translate(subResult)
                                            : subResult,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double invest =
                            double.tryParse(investmentController.text) ?? 0;
                        final double turn =
                            double.tryParse(turnoverController.text) ?? 0;

                        if (invest <= 0 || turn <= 0) {
                          setModalState(() {
                            result = 'Invalid Input';
                            subResult =
                                'Please enter valid values greater than 0';
                            resultColor = const Color(0xFFDC2626);
                          });
                          return;
                        }

                        String category = '';
                        if (invest <= 1 && turn <= 5) {
                          category = 'MICRO Enterprise';
                          resultColor = const Color(0xFF0D9488); // Teal
                        } else if (invest <= 10 && turn <= 50) {
                          category = 'SMALL Enterprise';
                          resultColor = const Color(0xFF2563EB); // Royal Blue
                        } else if (invest <= 50 && turn <= 250) {
                          category = 'MEDIUM Enterprise';
                          resultColor = const Color(0xFFD97706); // Amber
                        } else {
                          category = 'Large Enterprise (Beyond MSME Limits)';
                          resultColor = const Color(0xFFDC2626); // Red
                        }

                        setModalState(() {
                          result = category;
                          subResult =
                              'Limits: Micro (≤1cr / ≤5cr) | Small (≤10cr / ≤50cr) | Medium (≤50cr / ≤250cr)';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isTa
                            ? CentralizedTranslator.instance.translate(
                                'Calculate Classification',
                              )
                            : 'Calculate Classification',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openGstCalculator() {
    final isTa =
        Provider.of<AppProvider>(context, listen: false).selectedLanguage ==
        'ta';
    final amountController = TextEditingController();
    double gstPercentage = 18.0;
    double baseVal = 0.0;
    double cgstVal = 0.0;
    double sgstVal = 0.0;
    double totalVal = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.percent_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTa
                                  ? CentralizedTranslator.instance.translate(
                                      'GST / Tax Calculator',
                                    )
                                  : 'GST / Tax Calculator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isTa
                                  ? CentralizedTranslator.instance.translate(
                                      'Calculate CGST, SGST, and Total invoice amounts.',
                                    )
                                  : 'Calculate CGST, SGST, and Total invoice amounts.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isTa
                        ? CentralizedTranslator.instance.translate(
                            'Base Amount',
                          )
                        : 'Base Amount',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '50000',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      helperText: isTa
                          ? CentralizedTranslator.instance.translate(
                              'Enter net value of goods or services before GST',
                            )
                          : 'Enter net value of goods or services before GST',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isTa
                        ? CentralizedTranslator.instance.translate(
                            'GST Rate (%)',
                          )
                        : 'GST Rate (%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [5.0, 12.0, 18.0, 28.0].map((rate) {
                      final isSelected = gstPercentage == rate;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                '$rate%',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => gstPercentage = rate);
                              }
                            },
                            selectedColor: const Color(0xFFEFF6FF),
                            backgroundColor: Colors.white,
                            checkmarkColor: const Color(0xFF2563EB),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        isTa
                            ? CentralizedTranslator.instance.translate(error)
                            : error,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else if (baseVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isTa
                                      ? CentralizedTranslator.instance
                                            .translate('Base Price')
                                      : 'Base Price',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${baseVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'CGST (${(gstPercentage / 2).toStringAsFixed(1)}%)',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${cgstVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'SGST (${(gstPercentage / 2).toStringAsFixed(1)}%)',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${sgstVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isTa
                                      ? CentralizedTranslator.instance
                                            .translate('Total Invoice')
                                      : 'Total Invoice',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${totalVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double base =
                            double.tryParse(amountController.text) ?? 0;
                        if (base <= 0) {
                          setModalState(() {
                            error = 'Please enter a valid base amount';
                            baseVal = 0;
                          });
                          return;
                        }
                        final double gstAmount = base * (gstPercentage / 100);
                        setModalState(() {
                          error = '';
                          baseVal = base;
                          cgstVal = gstAmount / 2;
                          sgstVal = gstAmount / 2;
                          totalVal = base + gstAmount;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isTa
                            ? CentralizedTranslator.instance.translate(
                                'Calculate Tax',
                              )
                            : 'Calculate Tax',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEmiCalculator() {
    final loanController = TextEditingController();
    final rateController = TextEditingController();
    final tenureController = TextEditingController();
    double emiVal = 0.0;
    double principalVal = 0.0;
    double interestVal = 0.0;
    double totalVal = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Loan EMI Calculator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Calculate monthly payments for your business loan.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Loan Amount',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: loanController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '500000',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      helperText: 'Enter total business loan sum required',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interest Rate (% p.a.)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            TextField(
                              controller: rateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: '9.5',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                                suffixText: '%',
                                helperText: 'Enter annual rate',
                                helperStyle: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tenure (Months)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            TextField(
                              controller: tenureController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: '60',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                                suffixText: 'Mo',
                                helperText: 'Enter term in months',
                                helperStyle: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else if (emiVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Monthly EMI',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${emiVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Principal Amount',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${principalVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Total Interest Payable',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${interestVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Total Amount (Principal + Int)',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${totalVal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double p =
                            double.tryParse(loanController.text) ?? 0;
                        final double annualRate =
                            double.tryParse(rateController.text) ?? 0;
                        final double n =
                            double.tryParse(tenureController.text) ?? 0;

                        if (p <= 0 || annualRate <= 0 || n <= 0) {
                          setModalState(() {
                            error = 'Please enter valid inputs';
                            emiVal = 0;
                          });
                          return;
                        }

                        final double r = (annualRate / 12) / 100;
                        final double emi =
                            (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
                        final double totalPayable = emi * n;
                        final double totalInterest = totalPayable - p;

                        setModalState(() {
                          error = '';
                          emiVal = emi;
                          principalVal = p;
                          interestVal = totalInterest;
                          totalVal = totalPayable;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Calculate EMI',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openDpiitChecklist() {
    bool isPvtLtdOrLlp = false;
    bool isUnder10Years = false;
    bool turnoverUnder100Cr = false;
    bool isInnovative = false;
    String result = '';
    Color resultColor = const Color(0xFF2563EB);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DPIIT Recognition Checklist',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Evaluate if your business qualifies as a startup under DPIIT rules.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Text(
                            CentralizedTranslator.instance.translate(
                              'Registered as Pvt Ltd / LLP / Partnership',
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            CentralizedTranslator.instance.translate(
                              'Must be registered in India',
                            ),
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: isPvtLtdOrLlp,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) =>
                              setModalState(() => isPvtLtdOrLlp = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: Text(
                            CentralizedTranslator.instance.translate(
                              'Incorporation age is under 10 years',
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            CentralizedTranslator.instance.translate(
                              'From incorporation date',
                            ),
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: isUnder10Years,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(
                            () => isUnder10Years = val ?? false,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: Text(
                            CentralizedTranslator.instance.translate(
                              'Annual turnover has never exceeded ₹100 Cr',
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            CentralizedTranslator.instance.translate(
                              'For any financial year',
                            ),
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: turnoverUnder100Cr,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setModalState(
                            () => turnoverUnder100Cr = val ?? false,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        CheckboxListTile(
                          title: Text(
                            CentralizedTranslator.instance.translate(
                              'Working towards innovation/scaling',
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            CentralizedTranslator.instance.translate(
                              'Developing new products/processes',
                            ),
                            style: const TextStyle(fontSize: 9.5),
                          ),
                          value: isInnovative,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) =>
                              setModalState(() => isInnovative = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (result.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: resultColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              resultColor == const Color(0xFF047857)
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: resultColor,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                result,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final eligible =
                            isPvtLtdOrLlp &&
                            isUnder10Years &&
                            turnoverUnder100Cr &&
                            isInnovative;
                        setModalState(() {
                          if (eligible) {
                            result =
                                'Highly Eligible for DPIIT Startup India Recognition!';
                            resultColor = const Color(0xFF0D9488); // Teal Green
                          } else {
                            result =
                                'Not Eligible. Startups must satisfy all 4 criteria to qualify.';
                            resultColor = const Color(0xFFDC2626); // Red
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Check Eligibility',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openValuationEstimator() {
    final mrrController = TextEditingController();
    final growthController = TextEditingController();
    String selectedSector = 'SaaS / Tech';
    double lowEstimate = 0.0;
    double highEstimate = 0.0;
    double arrVal = 0.0;
    double appliedMultiple = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatVal(double val) {
              if (val >= 10000000) {
                return '₹ ${(val / 10000000).toStringAsFixed(2)} Crores';
              }
              return '₹ ${(val / 100000).toStringAsFixed(2)} Lakhs';
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.trending_up_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Startup Valuation Estimator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Get a ballpark pre-seed/seed valuation range based on MRR.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Monthly Recurring Revenue (MRR)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: mrrController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '200000',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      helperText: 'Enter monthly revenue in Rupees',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MoM Growth (%)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            TextField(
                              controller: growthController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: '15',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                                suffixText: '%',
                                helperText: 'Enter month-on-month rate',
                                helperStyle: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Sector',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tight),
                            DropdownButtonFormField<String>(
                              initialValue: selectedSector,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items:
                                  [
                                    'SaaS / Tech',
                                    'E-commerce',
                                    'Fintech',
                                    'AgriTech',
                                  ].map((String sector) {
                                    return DropdownMenuItem<String>(
                                      value: sector,
                                      child: Text(
                                        sector,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedSector = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else if (lowEstimate > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Valuation Range',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${formatVal(lowEstimate)} - ${formatVal(highEstimate)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Calculated ARR',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${(arrVal / 100000).toStringAsFixed(1)} Lakhs',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Applied ARR Multiple',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${appliedMultiple.toStringAsFixed(1)}x',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double mrr =
                            double.tryParse(mrrController.text) ?? 0;
                        final double growth =
                            double.tryParse(growthController.text) ?? 0;

                        if (mrr <= 0) {
                          setModalState(() {
                            error = 'Please enter a valid MRR';
                            lowEstimate = 0;
                          });
                          return;
                        }

                        double baseMultiple = 10;
                        if (selectedSector == 'Fintech') baseMultiple = 12;
                        if (selectedSector == 'E-commerce') baseMultiple = 6;
                        if (selectedSector == 'AgriTech') baseMultiple = 8;

                        if (growth > 20) {
                          baseMultiple += 4;
                        } else if (growth > 10) {
                          baseMultiple += 2;
                        }

                        final double arr = mrr * 12;
                        setModalState(() {
                          error = '';
                          arrVal = arr;
                          appliedMultiple = baseMultiple;
                          lowEstimate = arr * baseMultiple;
                          highEstimate = arr * (baseMultiple + 3);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Estimate Valuation',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openDocumentChecklist() {
    String selectedType = 'Private Limited';
    List<String> checklist = [
      'Digital Signature Certificate (DSC)',
      'Director Identification Number (DIN)',
      'MOA & AOA Drafting',
      'Certificate of Incorporation (COI)',
      'Company PAN & TAN Cards',
      'Corporate Bank Account',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.rule_folder_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup Document Checklist',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Checklist of documents needed to set up your business.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Business Entity Type',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    items:
                        [
                          'Private Limited',
                          'Partnership',
                          'One Person Company (OPC)',
                          'LLP',
                        ].map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedType = val;
                          if (val == 'Partnership') {
                            checklist = [
                              'Partnership Deed drafting',
                              'Deed Registration with Registrar',
                              'PAN & TAN cards of Firm',
                              'Firm Bank Account',
                              'GST Registration (Optional)',
                            ];
                          } else if (val == 'LLP') {
                            checklist = [
                              'LLP Name Approval (RUN-LLP)',
                              'FiLLiP Form (LLP Incorporation)',
                              'LLP Agreement Drafting',
                              'LLP PAN & TAN Cards',
                              'LLP Bank Account',
                            ];
                          } else {
                            checklist = [
                              'Digital Signature Certificate (DSC)',
                              'Director Identification Number (DIN)',
                              'MOA & AOA Drafting',
                              'Certificate of Incorporation (COI)',
                              'Company PAN & TAN Cards',
                              'Corporate Bank Account',
                            ];
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Required Documents',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: checklist.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEFF2F5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF2563EB),
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  checklist[index],
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close Checklist',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSubsidyEstimator() {
    final costController = TextEditingController();
    final subsidyController = TextEditingController();
    double costVal = 0.0;
    double subsidyPercentVal = 0.0;
    double subsidyAmountVal = 0.0;
    double netCostVal = 0.0;
    String error = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Subsidy Estimator',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Estimate capital subsidies and net loan commitments for machinery.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Project / Machinery Cost (Lakhs)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '25',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixText: '₹ ',
                      suffixText: 'Lakhs',
                      helperText: 'Enter machinery or project cost in Lakhs',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      suffixStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Expected Subsidy Percentage (%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  TextField(
                    controller: subsidyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: '15',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      suffixText: '%',
                      helperText: 'Enter expected subsidy rate percentage',
                      helperStyle: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                      suffixStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else if (costVal > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Original Project Cost',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${costVal.toStringAsFixed(2)} Lakhs',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${CentralizedTranslator.instance.translate('Expected Subsidy')} (${subsidyPercentVal.toStringAsFixed(1)}%)',
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${subsidyAmountVal.toStringAsFixed(2)} Lakhs',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.tight),
                            child: Divider(color: Color(0xFFDBEAFE), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  CentralizedTranslator.instance.translate(
                                    'Net Cost to Business',
                                  ),
                                  softWrap: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: FitOneLine(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹ ${netCostVal.toStringAsFixed(2)} Lakhs',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final double cost =
                            double.tryParse(costController.text) ?? 0;
                        final double percent =
                            double.tryParse(subsidyController.text) ?? 0;

                        if (cost <= 0 || percent <= 0 || percent > 100) {
                          setModalState(() {
                            error =
                                'Please enter valid values (Subsidy % must be between 0 and 100)';
                            costVal = 0;
                          });
                          return;
                        }

                        final double subsidyAmount = cost * (percent / 100);
                        final double netAmount = cost - subsidyAmount;

                        setModalState(() {
                          error = '';
                          costVal = cost;
                          subsidyPercentVal = percent;
                          subsidyAmountVal = subsidyAmount;
                          netCostVal = netAmount;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Calculate Subsidy',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class StateMapPainter extends CustomPainter {
  final String stateName;
  StateMapPainter(this.stateName);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (stateName == 'Tamil Nadu') {
      path.moveTo(w * 0.2, h * 0.1);
      path.quadraticBezierTo(w * 0.6, h * 0.05, w * 0.85, h * 0.15);
      path.lineTo(w * 0.8, h * 0.55);
      path.quadraticBezierTo(w * 0.65, h * 0.85, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.35, h * 0.85, w * 0.25, h * 0.55);
      path.close();
    } else if (stateName == 'Maharashtra') {
      path.moveTo(w * 0.1, h * 0.4);
      path.lineTo(w * 0.3, h * 0.15);
      path.lineTo(w * 0.75, h * 0.2);
      path.lineTo(w * 0.9, h * 0.38);
      path.lineTo(w * 0.82, h * 0.78);
      path.lineTo(w * 0.48, h * 0.82);
      path.lineTo(w * 0.2, h * 0.65);
      path.close();
    } else if (stateName == 'Uttar Pradesh') {
      path.moveTo(w * 0.08, h * 0.35);
      path.lineTo(w * 0.35, h * 0.2);
      path.lineTo(w * 0.8, h * 0.25);
      path.lineTo(w * 0.92, h * 0.5);
      path.lineTo(w * 0.72, h * 0.78);
      path.lineTo(w * 0.52, h * 0.68);
      path.lineTo(w * 0.32, h * 0.78);
      path.lineTo(w * 0.18, h * 0.52);
      path.close();
    } else if (stateName == 'Karnataka') {
      path.moveTo(w * 0.35, h * 0.08);
      path.quadraticBezierTo(w * 0.75, h * 0.22, w * 0.6, h * 0.52);
      path.quadraticBezierTo(w * 0.8, h * 0.72, w * 0.65, h * 0.92);
      path.lineTo(w * 0.4, h * 0.88);
      path.quadraticBezierTo(w * 0.2, h * 0.58, w * 0.35, h * 0.32);
      path.close();
    } else if (stateName == 'Gujarat') {
      path.moveTo(w * 0.25, h * 0.22);
      path.lineTo(w * 0.52, h * 0.12);
      path.lineTo(w * 0.78, h * 0.22);
      path.lineTo(w * 0.82, h * 0.52);
      path.lineTo(w * 0.58, h * 0.82);
      path.lineTo(w * 0.42, h * 0.58);
      path.lineTo(w * 0.12, h * 0.48);
      path.lineTo(w * 0.22, h * 0.34);
      path.close();
    } else {
      // General map locator shape fallback
      path.moveTo(w * 0.5, h * 0.1);
      path.quadraticBezierTo(w * 0.8, h * 0.1, w * 0.8, h * 0.45);
      path.quadraticBezierTo(w * 0.8, h * 0.75, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.2, h * 0.75, w * 0.2, h * 0.45);
      path.quadraticBezierTo(w * 0.2, h * 0.1, w * 0.5, h * 0.1);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
