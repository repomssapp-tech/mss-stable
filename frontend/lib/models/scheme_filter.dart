import '../services/recommendation/indian_states.dart';
import 'scheme_model.dart';

/// Single source of truth for scheme facet filtering.
///
/// Filters live in `AppProvider.filters` as a plain string-keyed map (kept
/// for the smart-assessment / category-browse flows that write a few keys
/// directly). Only the keys below are meaningful; everything else the old
/// 18-field panel wrote is ignored.
///
///  - `coverage`      : '' | 'nationwide'      (state-specific implied by `state`)
///  - `state`         : a state name, or '' / 'All'
///  - `schemeTypes`   : `List` of [SchemeTypeGroup.id] strings
///  - `beneficiaries` : `List` of special-category codes (women, sc, ...)
///  - `category`      : free text  (set by category-card browse)
///  - `ministry`      : free text  (set by ministry-card browse)
///
/// [applySchemeFilters] is the ONE matcher; both the search screen and the
/// search-results screen call it. Matching is normalized set-membership /
/// tolerant substring -- never a brittle `== 'All India'` literal.

/// True when a scheme's [Scheme.state] denotes nationwide scope, so a state
/// facet must not hide it. The catalog labels this inconsistently
/// ("Pan-India", "All India", "India", "Nationwide", ...). Only the state
/// string is consulted -- `Scheme.governmentLevel` defaults to "Central" on
/// the model, so it cannot distinguish national from state schemes.
bool schemeIsNationwide(Scheme s) {
  final st = s.state.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  const exact = {
    'india',
    'national',
    'nationwide',
    'acrossindia',
    'allstates',
    'allstatesut',
    'central',
  };
  if (exact.contains(st)) return true;
  // Catches "Pan-India / coir sector", "All India (framework)", etc.
  return st.startsWith('allindia') ||
      st.startsWith('panindia') ||
      st.startsWith('panindian');
}

/// True when [s] applies in every state: the catalog's structured
/// `appliesNationally` when the record has it, else its state text.
bool schemeAppliesNationally(Scheme s) =>
    s.appliesNationally ?? schemeIsNationwide(s);

/// Whether [s] is available in [state], given as a name in any supported
/// language or as a code (`tn`, `IN-TN`). Decided from the structured
/// coverage only, never from the government level, the scheme's name or its
/// id: nationwide schemes match every state, state-limited ones match their
/// own states, and a scheme whose coverage is unknown matches none (it still
/// appears in unfiltered lists).
bool schemeAppliesInState(Scheme s, String state) {
  if (schemeAppliesNationally(s)) return true;
  final code = IndianStates.code(state);
  if (code == null) return false;
  if (s.stateCodes.isNotEmpty) return s.stateCodes.contains(code);
  if (s.appliesNationally != null) return false; // known, but no states given
  // A record without structured coverage: its state text is all there is.
  return IndianStates.code(s.state) == code;
}

/// A human-facing grouping of the catalog's raw `schemeType` values.
class SchemeTypeGroup {
  const SchemeTypeGroup(this.id, this.label, this._needles);

  final String id;
  final String label;
  final List<String> _needles;

  bool matches(Scheme s) {
    final hay =
        '${s.schemeType} ${s.category} ${s.benefitTypesList.join(' ')} '
                '${s.supportTypes.join(' ')} ${s.glanceChips.join(' ')}'
            .toLowerCase();
    return _needles.any(hay.contains);
  }
}

const List<SchemeTypeGroup> kSchemeTypeGroups = [
  SchemeTypeGroup('loans', 'Loans & credit', [
    'loan',
    'credit',
    'working capital',
    'refinance',
    'cash credit',
  ]),
  SchemeTypeGroup('subsidies', 'Subsidies', [
    'subsid',
    'subvention',
    'reimbursement',
    'incentive',
    'margin money',
  ]),
  SchemeTypeGroup('grants', 'Grants & equity', [
    'grant',
    'equity',
    'seed fund',
    'corpus',
    'venture',
  ]),
  SchemeTypeGroup('guarantee', 'Guarantee', ['guarantee']),
  SchemeTypeGroup('training', 'Training', [
    'training',
    'capacity',
    'mentor',
    'skill',
    'workshop',
    'incubat',
    'entrepreneurship development',
  ]),
  SchemeTypeGroup('market', 'Market & export', [
    'market',
    'export',
    'procurement',
    'trade fair',
    'event',
    'fair',
  ]),
  SchemeTypeGroup('infra', 'Infrastructure', [
    'infrastructure',
    'cluster',
    'technology',
    'certification',
    'energy',
    'plant',
  ]),
];

/// Special-category codes the catalog uses, most-populous first, with a
/// display label. The filter sheet hides any option with too few schemes.
const List<(String code, String label)> kBeneficiaryOptions = [
  ('women', 'Women'),
  ('sc', 'SC'),
  ('st', 'ST'),
  ('differently_abled', 'Differently-abled'),
  ('transgender', 'Transgender'),
  ('minority', 'Minority'),
  ('ex_servicemen', 'Ex-servicemen'),
];

List<String> _asStrList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String && v.trim().isNotEmpty) return [v];
  return const [];
}

String _clean(dynamic v) => (v ?? '').toString().trim();

/// How many facet groups are currently active (for the "Filter · N" badge).
int activeSchemeFilterCount(Map<String, dynamic> f) {
  var n = 0;
  if (_clean(f['coverage']).isNotEmpty) n++;
  final st = _clean(f['state']);
  if (st.isNotEmpty && st.toLowerCase() != 'all') n++;
  if (_asStrList(f['schemeTypes']).isNotEmpty) n++;
  if (_asStrList(f['beneficiaries']).isNotEmpty) n++;
  final cat = _clean(f['category']);
  if (cat.isNotEmpty && cat.toLowerCase() != 'all') n++;
  final min = _clean(f['ministry']);
  if (min.isNotEmpty && min.toLowerCase() != 'all') n++;
  return n;
}

bool hasActiveSchemeFilters(Map<String, dynamic> f) =>
    activeSchemeFilterCount(f) > 0;

/// The one matcher. Order-preserving; every clause is an intersection.
List<Scheme> applySchemeFilters(List<Scheme> input, Map<String, dynamic> f) {
  var out = input;

  final coverage = _clean(f['coverage']).toLowerCase();
  final state = _clean(f['state']);
  if (coverage == 'nationwide') {
    out = out.where(schemeAppliesNationally).toList();
  } else if (state.isNotEmpty && state.toLowerCase() != 'all') {
    out = out.where((s) => schemeAppliesInState(s, state)).toList();
  }

  final typeIds = _asStrList(f['schemeTypes']).toSet();
  if (typeIds.isNotEmpty) {
    final groups = kSchemeTypeGroups
        .where((g) => typeIds.contains(g.id))
        .toList();
    out = out.where((s) => groups.any((g) => g.matches(s))).toList();
  }

  final bens = _asStrList(
    f['beneficiaries'],
  ).map((e) => e.toLowerCase()).toSet();
  if (bens.isNotEmpty) {
    out = out.where((s) {
      final sc = s.specialCategories.map((e) => e.toLowerCase()).toSet();
      return sc.intersection(bens).isNotEmpty;
    }).toList();
  }

  final category = _clean(f['category']);
  if (category.isNotEmpty && category.toLowerCase() != 'all') {
    final words = category.toLowerCase().split(RegExp(r'[\s&/,\-]+'));
    out = out.where((s) {
      final hay = '${s.category} ${s.sector} ${s.searchKeywords}'.toLowerCase();
      return words.any((w) => w.length > 2 && hay.contains(w));
    }).toList();
  }

  final ministry = _clean(f['ministry']);
  if (ministry.isNotEmpty && ministry.toLowerCase() != 'all') {
    final m = ministry.toLowerCase();
    out = out.where((s) {
      return s.sponsoringBody.toLowerCase().contains(m) ||
          s.issuingBody.toLowerCase().contains(m) ||
          s.name.toLowerCase().contains(m);
    }).toList();
  }

  return out;
}

/// Result count if [dim]=[value] were toggled on, keeping the other active
/// facets -- what the filter sheet shows next to each chip.
int schemeFacetCount(
  List<Scheme> catalog,
  Map<String, dynamic> current,
  String dim,
  String value,
) {
  final probe = Map<String, dynamic>.from(current);
  if (dim == 'schemeTypes' || dim == 'beneficiaries') {
    probe[dim] = [value];
  } else {
    probe[dim] = value;
  }
  return applySchemeFilters(catalog, probe).length;
}
