import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/filter_panel.dart';
import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import '../../services/scheme_repository.dart';
import 'scheme_details_screen.dart';
import 'search_results_screen.dart';
import '../../engine/recommendation_engine.dart';
import '../../l10n/l10n.dart';
import '../../services/centralized_translator.dart';
import '../../widgets/voice_assistant_overlay.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/scheme_card.dart';
import '../../utils/app_spacing.dart';
import '../../services/voice_recognition_controller.dart';

String _getLocalizedTagOrCategory(String text, String langCode) {
  if (langCode != 'ta') return text;
  return CentralizedTranslator.instance.translateTag(text);
}

enum SearchState { idle, loading, results }

/// Which empty state the "For Me" results view should render.
enum ForMeEmptyState {
  /// There are matches to show.
  none,

  /// Profile is too sparse to personalise — show "complete your profile".
  completeProfile,

  /// Profile is usable but nothing cleared the score gate / facet filters.
  noMatches,
}

/// Result of resolving the "For Me" view: the schemes to show plus which
/// empty state (if any) applies. Pure data, unit-tested.
class ForMeViewResult {
  const ForMeViewResult(this.schemes, this.emptyState);
  final List<Scheme> schemes;
  final ForMeEmptyState emptyState;
}

/// Applies the FilterPanel facet map (`provider.filters`) to [input]. Used in
/// EVERY mode, including "For Me", so the score gate and the facets combine
/// additively (intersection). Pure — no BuildContext, no provider.
List<Scheme> applyProviderFacetFilters(
  List<Scheme> input,
  Map<String, dynamic> filters,
) {
  var out = input;
  final state = filters['state'];
  if (state != null && state != 'All') {
    final st = state.toString().toLowerCase();
    out = out.where((s) {
      return s.state.toLowerCase() == 'all india' ||
          s.state.toLowerCase().contains(st);
    }).toList();
  }
  final category = filters['category'];
  if (category != null && category != 'All') {
    final words = category.toString().toLowerCase().split(RegExp(r'[\s&/,-]+'));
    out = out.where((s) {
      final schCat = s.category.toLowerCase();
      final schSec = s.sector.toLowerCase();
      for (final w in words) {
        if (w.length > 2 && (schCat.contains(w) || schSec.contains(w))) {
          return true;
        }
      }
      return false;
    }).toList();
  }
  final schemeType = filters['schemeType'];
  if (schemeType != null && schemeType != 'All') {
    final stType = schemeType.toString().toLowerCase();
    out = out.where((s) {
      return s.schemeType.toLowerCase().contains(stType) ||
          s.category.toLowerCase().contains(stType);
    }).toList();
  }
  final ministry = filters['ministry'];
  if (ministry != null &&
      ministry != 'All' &&
      ministry.toString().trim().isNotEmpty) {
    final mLower = ministry.toString().toLowerCase();
    out = out.where((s) {
      return s.sponsoringBody.toLowerCase().contains(mLower) ||
          s.issuingBody.toLowerCase().contains(mLower) ||
          s.category.toLowerCase().contains(mLower) ||
          s.name.toLowerCase().contains(mLower);
    }).toList();
  }
  final department = filters['department'];
  if (department != null &&
      department != 'All' &&
      department.toString().trim().isNotEmpty) {
    final dLower = department.toString().toLowerCase();
    out = out.where((s) {
      return s.sponsoringBody.toLowerCase().contains(dLower) ||
          s.issuingBody.toLowerCase().contains(dLower) ||
          s.category.toLowerCase().contains(dLower) ||
          s.name.toLowerCase().contains(dLower);
    }).toList();
  }
  return out;
}

/// Resolves the "For Me" results view from the master result set. Additive:
/// score gate (>= RecommendationEngine.forMeThreshold) INTERSECTED with the
/// FilterPanel facets. Returns an empty list — never the catalog — with a
/// [ForMeEmptyState] the caller renders:
///  - [ForMeEmptyState.completeProfile] when the profile is too sparse;
///  - [ForMeEmptyState.noMatches] when it is usable but nothing qualifies.
/// Pure — no BuildContext.
ForMeViewResult computeForMeView({
  required List<Scheme> master,
  required UserProfile profile,
  required Map<String, dynamic> filters,
}) {
  if (!RecommendationEngine.hasEnoughProfileForRecommendation(profile)) {
    return const ForMeViewResult(<Scheme>[], ForMeEmptyState.completeProfile);
  }
  final gated = master
      .where((s) =>
          RecommendationEngine.evaluate(profile, s).score >=
          RecommendationEngine.forMeThreshold)
      .toList();
  final filtered = applyProviderFacetFilters(gated, filters);
  return ForMeViewResult(
    filtered,
    filtered.isEmpty ? ForMeEmptyState.noMatches : ForMeEmptyState.none,
  );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final VoiceRecognitionController _dictationController =
      AutomaticVoiceRecognitionController();
  bool _isDictating = false;
  SearchState _currentState = SearchState.idle;
  String _activeFilter = "All";

  bool get isSearching =>
      _currentState != SearchState.idle ||
      _searchController.text.trim().isNotEmpty;

  // Data list of scheme results from Supabase
  List<Scheme> _searchResults = [];
  List<Scheme> _masterSearchResults = [];
  String _sortBy = 'Relevance';
  String _selectedType = 'All';
  String _selectedBenefit = 'All';
  String _selectedMinistry = 'All';
  Map<String, int> _categoryCounts = {};
  bool _isLoadingCounts = true;
  int _matchingProfileCount = 0;
  Map<String, List<String>> _activeSearchFilters = {};
  String _dynamicSearchHintText = "Search PMEGP, Startup India, MSME loans...";
  // Bumped on every _triggerSearch call; a stale request that resolves after
  // a newer one must not overwrite it (out-of-order async race -- the search
  // screen's state survives Home<->Search tab switches via IndexedStack, so
  // an in-flight request from a previous query can still land here).
  int _searchGeneration = 0;

  double _scaledFontSize(double baseSize) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta' ? baseSize * 0.92 : baseSize;
  }

  FontWeight _scaledFontWeight(FontWeight baseWeight) {
    return baseWeight;
  }

  // Which empty state the "For Me" results view should render (see
  // ForMeEmptyState). Kept current even when there is nothing to filter so
  // the view can explain *why* it is empty instead of silently showing the
  // whole catalog or a bare "no results".
  ForMeEmptyState _forMeEmptyState = ForMeEmptyState.none;

  List<Scheme> _computeEligibleSchemes(AppProvider provider, List<Scheme> all) {
    final list = all.isNotEmpty ? all : provider.allSchemes;
    // Single source of truth for the "For Me" set: an additive score gate at
    // RecommendationEngine.forMeThreshold, and an empty list when the profile
    // is not populated enough to personalise. Keeps the list and the
    // `_matchingProfileCount` badge in exact agreement.
    return RecommendationEngine.forMeSchemes(provider.profile, list);
  }

  void _applyFiltersAndSort() {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Keep the "For Me" empty-state classification current even when there is
    // nothing to filter (the early-return path below).
    if (_activeFilter == 'For Me' &&
        !RecommendationEngine.hasEnoughProfileForRecommendation(
          provider.profile,
        )) {
      _forMeEmptyState = ForMeEmptyState.completeProfile;
    } else if (_activeFilter != 'For Me') {
      _forMeEmptyState = ForMeEmptyState.none;
    }

    if (_masterSearchResults.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentState = SearchState.results;
      });
      return;
    }
    List<Scheme> filteredResults = List<Scheme>.from(_masterSearchResults);

    // 1. Dropdown Chips Filters: Type (Loan, Subsidy, etc.)
    if (_selectedType != 'All') {
      final typeKeyword = _selectedType.toLowerCase();
      filteredResults = filteredResults.where((scheme) {
        return scheme.schemeType.toLowerCase().contains(typeKeyword) ||
            scheme.name.toLowerCase().contains(typeKeyword) ||
            scheme.category.toLowerCase().contains(typeKeyword) ||
            scheme.overview.toLowerCase().contains(typeKeyword);
      }).toList();
    }

    // 2. Dropdown Chips Filters: Benefit Type
    if (_selectedBenefit != 'All') {
      final benefitLower = _selectedBenefit.toLowerCase();
      filteredResults = filteredResults.where((scheme) {
        if (benefitLower == 'financial') {
          return scheme.benefits.toLowerCase().contains('financial') ||
              scheme.benefits.toLowerCase().contains('subsidy') ||
              scheme.benefits.toLowerCase().contains('funding') ||
              scheme.benefits.toLowerCase().contains('grant') ||
              scheme.benefits.toLowerCase().contains('loan') ||
              scheme.benefits.toLowerCase().contains('pension') ||
              scheme.benefits.toLowerCase().contains('reimbursement') ||
              scheme.benefits.toLowerCase().contains('₹') ||
              scheme.benefits.toLowerCase().contains('rs.') ||
              scheme.schemeType.toLowerCase().contains('subsidy') ||
              scheme.schemeType.toLowerCase().contains('loan') ||
              scheme.schemeType.toLowerCase().contains('grant');
        } else if (benefitLower == 'skill training') {
          return scheme.benefits.toLowerCase().contains('skill') ||
              scheme.benefits.toLowerCase().contains('training') ||
              scheme.benefits.toLowerCase().contains('workshop') ||
              scheme.benefits.toLowerCase().contains('placement') ||
              scheme.benefits.toLowerCase().contains('capacity building') ||
              scheme.benefits.toLowerCase().contains('mentorship') ||
              scheme.overview.toLowerCase().contains('training') ||
              scheme.overview.toLowerCase().contains('skill');
        } else if (benefitLower == 'infrastructure') {
          return scheme.benefits.toLowerCase().contains('infrastructure') ||
              scheme.benefits.toLowerCase().contains('facility') ||
              scheme.benefits.toLowerCase().contains('technology') ||
              scheme.benefits.toLowerCase().contains('plant') ||
              scheme.benefits.toLowerCase().contains('machinery') ||
              scheme.benefits.toLowerCase().contains('incubation') ||
              scheme.overview.toLowerCase().contains('infrastructure') ||
              scheme.overview.toLowerCase().contains('technology');
        } else {
          return scheme.benefits.toLowerCase().contains(benefitLower) ||
              scheme.overview.toLowerCase().contains(benefitLower);
        }
      }).toList();
    }

    // 3. Dropdown Chips Filters: Ministry
    if (_selectedMinistry != 'All') {
      final ministryLower = _selectedMinistry.toLowerCase();
      filteredResults = filteredResults.where((scheme) {
        return scheme.sponsoringBody.toLowerCase().contains(ministryLower) ||
            scheme.issuingBody.toLowerCase().contains(ministryLower) ||
            scheme.category.toLowerCase().contains(ministryLower) ||
            scheme.name.toLowerCase().contains(ministryLower);
      }).toList();
    }

    // 4. Provider Filters (from FilterPanel) - applied in EVERY mode. In
    // "For Me" the score gate (step 6 below) folds these in via
    // computeForMeView, so only apply them here for the other modes to avoid
    // filtering twice.
    if (_activeFilter != 'For Me') {
      filteredResults =
          applyProviderFacetFilters(filteredResults, provider.filters);
    }

    // 5. Apply FilterBottomSheet selections if any
    if (_activeSearchFilters.isNotEmpty) {
      filteredResults = filteredResults.where((scheme) {
        final locs = _activeSearchFilters['Location'] ?? [];
        if (locs.isNotEmpty) {
          bool matchesLoc = false;
          for (final loc in locs) {
            if (loc == 'All India' &&
                scheme.state.toLowerCase() == 'all india') {
              matchesLoc = true;
            } else if (loc == 'Central' &&
                scheme.governmentLevel.toLowerCase() == 'central') {
              matchesLoc = true;
            } else if (loc == 'State' &&
                (scheme.governmentLevel.toLowerCase() == 'state' ||
                    (scheme.state.isNotEmpty &&
                        scheme.state.toLowerCase() != 'all india'))) {
              matchesLoc = true;
            }
          }
          if (!matchesLoc) return false;
        }

        final applicants = _activeSearchFilters['Applicant'] ?? [];
        if (applicants.isNotEmpty) {
          bool matchesApp = false;
          final target = scheme.targetBeneficiary.toLowerCase();
          for (final app in applicants) {
            if (target.contains(app.toLowerCase())) {
              matchesApp = true;
            }
          }
          if (!matchesApp) return false;
        }

        final stages = _activeSearchFilters['Stage'] ?? [];
        if (stages.isNotEmpty) {
          bool matchesStage = false;
          final kw = scheme.searchKeywords.toLowerCase();
          final name = scheme.name.toLowerCase();
          for (final stage in stages) {
            if (kw.contains(stage.toLowerCase()) ||
                name.contains(stage.toLowerCase())) {
              matchesStage = true;
            }
          }
          if (!matchesStage) return false;
        }

        final benefits = _activeSearchFilters['Benefits'] ?? [];
        if (benefits.isNotEmpty) {
          bool matchesBen = false;
          final type = scheme.schemeType.toLowerCase();
          final cat = scheme.category.toLowerCase();
          final ben = scheme.benefits.toLowerCase();
          for (final b in benefits) {
            if (type.contains(b.toLowerCase()) ||
                cat.contains(b.toLowerCase()) ||
                ben.contains(b.toLowerCase())) {
              matchesBen = true;
            }
          }
          if (!matchesBen) return false;
        }

        final sectors = _activeSearchFilters['Sector'] ?? [];
        if (sectors.isNotEmpty) {
          bool matchesSec = false;
          final sector = scheme.sector.toLowerCase();
          for (final sec in sectors) {
            if (sector.contains(sec.toLowerCase())) {
              matchesSec = true;
            }
          }
          if (!matchesSec) return false;
        }

        final authorities = _activeSearchFilters['Authority'] ?? [];
        if (authorities.isNotEmpty) {
          bool matchesAuth = false;
          final sponsor = scheme.sponsoringBody.toLowerCase();
          final issuer = scheme.issuingBody.toLowerCase();
          for (final auth in authorities) {
            if (sponsor.contains(auth.toLowerCase()) ||
                issuer.contains(auth.toLowerCase())) {
              matchesAuth = true;
            }
          }
          if (!matchesAuth) return false;
        }

        return true;
      }).toList();
    }

    // 6. If "For Me" filter is active, resolve the view through the pure
    // computeForMeView: score gate (>= forMeThreshold) INTERSECTED with the
    // FilterPanel facets, or an empty list + a ForMeEmptyState when the
    // profile is too sparse / nothing qualifies. Never the catalog.
    if (_activeFilter == 'For Me') {
      final view = computeForMeView(
        master: filteredResults,
        profile: provider.profile,
        filters: provider.filters,
      );
      filteredResults = List<Scheme>.from(view.schemes);
      _forMeEmptyState = view.emptyState;
    } else {
      _forMeEmptyState = ForMeEmptyState.none;
    }

    // 6. Sorting
    if (_sortBy == 'Benefits: High to Low') {
      filteredResults.sort((a, b) {
        final aBenefit = a.maxFunding ?? a.minFunding ?? 0.0;
        final bBenefit = b.maxFunding ?? b.minFunding ?? 0.0;
        return bBenefit.compareTo(aBenefit);
      });
    } else if (_sortBy == 'Match %' || _sortBy == 'Match') {
      filteredResults.sort((a, b) {
        final scoreA =
            RecommendationEngine.evaluate(provider.profile, a).percentage;
        final scoreB =
            RecommendationEngine.evaluate(provider.profile, b).percentage;
        return scoreB.compareTo(scoreA);
      });
    } else if (_sortBy == 'Scheme Name (A-Z)') {
      filteredResults.sort(
        (a, b) => a
            .getName(provider.selectedLanguage)
            .toLowerCase()
            .compareTo(b.getName(provider.selectedLanguage).toLowerCase()),
      );
    } else if (_sortBy == 'Scheme Name (Z-A)') {
      filteredResults.sort(
        (a, b) => b
            .getName(provider.selectedLanguage)
            .toLowerCase()
            .compareTo(a.getName(provider.selectedLanguage).toLowerCase()),
      );
    } else {
      // Relevance (Default score)
      filteredResults.sort((a, b) {
        final scoreA =
            RecommendationEngine.evaluate(provider.profile, a).score;
        final scoreB =
            RecommendationEngine.evaluate(provider.profile, b).score;
        return scoreB.compareTo(scoreA);
      });
    }

    setState(() {
      _searchResults = filteredResults;
      _currentState = SearchState.results;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies always fires once immediately after initState on
    // the very first build (in addition to firing on later InheritedWidget
    // changes, e.g. locale), so this alone covers both the initial load and
    // future recounts -- no separate initState call needed.
    _loadCategoryCounts();
  }

  bool _categoryCountsInFlight = false;

  Future<void> _loadCategoryCounts() async {
    if (_categoryCountsInFlight) return;
    _categoryCountsInFlight = true;
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      final allSchemes = provider.allSchemes.isNotEmpty
          ? provider.allSchemes
          : await SchemeRepository.instance.getAllSchemes();

      final counts = await SchemeRepository.instance.getCategoryCounts(
        provider.profile,
        activeFilter: _activeFilter,
      );

      final eligibleSchemes = _computeEligibleSchemes(provider, allSchemes);

      final hint = await SchemeRepository.instance.getDynamicSearchHint(
        provider.selectedLanguage,
      );

      // Deferred for the same reason as the results setState in
      // _triggerSearch: this can land mid-layout during a keyboard-dismiss
      // animation and trip the re-entrant-layout assertion.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _categoryCounts = counts;
          _matchingProfileCount = eligibleSchemes.length;
          _dynamicSearchHintText = hint;
          _isLoadingCounts = false;
        });
      });
    } catch (e) {
      debugPrint('[SearchScreen] error loading dynamic category counts: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isLoadingCounts = false;
        });
      });
    } finally {
      _categoryCountsInFlight = false;
    }
  }

  /// Direct search-bar dictation: transcribes speech straight into the
  /// search field via the device's speech recognizer (Android's
  /// SpeechRecognizer, Google-backed), distinct from the full "Ask IN AI"
  /// conversational overlay [_openVoiceAssistant] opens elsewhere.
  Future<void> _toggleDictation() async {
    if (_isDictating) {
      await _dictationController.stop();
      if (mounted) setState(() => _isDictating = false);
      return;
    }

    final capabilities = await _dictationController.initialize(
      onStatus: (_) {},
      onResult: (result) {
        if (!mounted) return;
        _searchController.text = result.transcript;
        _searchController.selection = TextSelection.collapsed(
          offset: result.transcript.length,
        );
        if (result.isFinal) {
          setState(() => _isDictating = false);
          if (result.transcript.trim().isNotEmpty) {
            _triggerSearch(result.transcript.trim());
          }
        }
      },
      onSoundLevel: (_) {},
      onLanguage: (_) {},
      onError: (error) {
        if (!mounted) return;
        setState(() => _isDictating = false);
        AppToast.showWarning(context, error.message);
      },
    );

    if (!capabilities.available) {
      if (mounted && capabilities.reason != null) {
        AppToast.showWarning(context, capabilities.reason!);
      }
      return;
    }

    setState(() => _isDictating = true);
    await _dictationController.listen();
  }

  @override
  void dispose() {
    _dictationController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Public reset method that can be triggered from external Shell controllers
  void resetToIdle() {
    if (_currentState != SearchState.idle) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      if (mounted) {
        setState(() {
          _sortBy = 'Relevance';
          _selectedType = 'All';
          _selectedBenefit = 'All';
          _selectedMinistry = 'All';
          _activeSearchFilters = {};
          _activeFilter = "All";
          _searchResults = [];
          _masterSearchResults = [];
          _currentState = SearchState.idle;
        });
      }
    }
  }

  void openFilterBottomSheet() {
    _openFilterPanel();
  }

  Future<void> openVoiceAssistant() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final schemes = provider.allSchemes.isNotEmpty
        ? provider.allSchemes
        : await SchemeRepository.instance.getAllSchemes();
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Voice assistant',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (overlayContext, animation, secondaryAnimation) {
        return VoiceAssistantOverlay(
          onClose: () =>
              Navigator.of(overlayContext, rootNavigator: true).pop(),
          schemes: schemes,
          profile: provider.profile,
          onProfileConfirmed: provider.updateProfile,
          onSearch: (query) =>
              SchemeRepository.instance.searchSchemeMatches(query, limit: 20),
          onSchemeSelected: (scheme) {
            Navigator.of(overlayContext, rootNavigator: true).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
          onSubmit: (query) {
            Navigator.of(overlayContext, rootNavigator: true).pop();
            submitVoiceQuery(query);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: Tween<double>(begin: 0.72, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void submitVoiceQuery(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;

    _searchController.value = TextEditingValue(
      text: normalizedQuery,
      selection: TextSelection.collapsed(offset: normalizedQuery.length),
    );
    _searchFocusNode.unfocus();
    _triggerSearch(normalizedQuery);
  }

  void _onSearchTextChanged() {
    // If text gets cleared, instantly revert to idle
    if (_searchController.text.isEmpty && _currentState != SearchState.idle) {
      setState(() {
        _searchResults = [];
        _masterSearchResults = [];
        _currentState = SearchState.idle;
      });
    }
  }

  void _triggerSearch(String query) async {
    // If query is empty and active filter is "For Me" or "All", go back to idle Categories screen
    if (query.isEmpty &&
        _selectedType == 'All' &&
        _selectedBenefit == 'All' &&
        _selectedMinistry == 'All' &&
        _activeFilter == 'All') {
      _searchGeneration++;
      setState(() {
        _currentState = SearchState.idle;
        _searchResults = [];
        _masterSearchResults = [];
      });
      return;
    }

    final int requestGeneration = ++_searchGeneration;

    setState(() {
      _currentState = SearchState.loading;
    });

    final normalized = query.toLowerCase().trim();
    final bool showAll =
        _activeFilter != 'For Me' ||
        normalized == 'all' ||
        normalized.startsWith('all ') ||
        normalized.endsWith(' all') ||
        normalized.contains(' all ');

    String searchTerm = query;
    if (showAll && normalized != 'all' && _activeFilter == 'For Me') {
      searchTerm = query
          .replaceAll(RegExp(r'\ball\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    try {
      List<Scheme> results;
      final String normalQuery = searchTerm.toLowerCase().trim();
      if (_activeFilter == 'For Me' ||
          normalQuery == 'suitable schemes' ||
          normalQuery == 'for me') {
        final all = provider.allSchemes.isNotEmpty
            ? provider.allSchemes
            : await SchemeRepository.instance.getAllSchemes();

        final eligible = _computeEligibleSchemes(provider, all);

        // Sort by match score descending
        eligible.sort((a, b) {
          final scoreA =
              RecommendationEngine.evaluate(provider.profile, a).score;
          final scoreB =
              RecommendationEngine.evaluate(provider.profile, b).score;
          return scoreB.compareTo(scoreA);
        });

        if (searchTerm.isNotEmpty &&
            normalQuery != 'suitable schemes' &&
            normalQuery != 'for me') {
          final q = searchTerm.toLowerCase();
          results = eligible.where((s) {
            return s.name.toLowerCase().contains(q) ||
                s.overview.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q) ||
                s.sponsoringBody.toLowerCase().contains(q) ||
                s.searchKeywords.toLowerCase().contains(q);
          }).toList();
        } else {
          results = eligible;
        }
      } else if (normalQuery.isEmpty || normalQuery == 'all') {
        results = await SchemeRepository.instance.getAllSchemes();
      } else {
        results = await SchemeRepository.instance.searchSchemes(searchTerm);
      }

      if (!mounted || requestGeneration != _searchGeneration) return;

      _masterSearchResults = results;
      _applyFiltersAndSort();
    } catch (e) {
      if (!mounted || requestGeneration != _searchGeneration) return;
      setState(() {
        _masterSearchResults = [];
        _searchResults = [];
        _currentState = SearchState.results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // List of categories matching mockup
    final List<Map<String, dynamic>> categories = [
      {
        "title": "MSME",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["MSME"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.bar_chart,
        "iconColor": const Color(0xFF6D28D9),
        "iconBg": const Color(0xFFF5F3FF),
      },
      {
        "title": "Startup",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Startup"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.rocket_launch,
        "iconColor": const Color(0xFF1D4ED8),
        "iconBg": const Color(0xFFEFF6FF),
      },
      {
        "title": "Women Entrepreneurs",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Women Entrepreneurs"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.person,
        "iconColor": const Color(0xFFE11D48),
        "iconBg": const Color(0xFFFFE4E6),
      },
      {
        "title": "Business Loans & Credit",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Business Loans & Credit"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.account_balance,
        "iconColor": const Color(0xFF047857),
        "iconBg": const Color(0xFFECFDF5),
      },
      {
        "title": "Export & Trade Promotion",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Export & Trade Promotion"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.import_export,
        "iconColor": const Color(0xFF16A34A),
        "iconBg": const Color(0xFFDCFCE7),
      },
      {
        "title": "SHG & Artisan",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["SHG & Artisan"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.groups,
        "iconColor": const Color(0xFFD97706),
        "iconBg": const Color(0xFFFEF3C7),
      },
      {
        "title": "Technology",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Technology"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.computer,
        "iconColor": const Color(0xFF2563EB),
        "iconBg": const Color(0xFFDBEAFE),
      },
      {
        "title": "Manufacturing",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Manufacturing"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.factory,
        "iconColor": const Color(0xFFEA580C),
        "iconBg": const Color(0xFFFFEDD5),
      },
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Crisp clean background without blue shade
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top header elements
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Custom App Bar matching Discover Header
                    _buildCustomAppBar(context, provider),

                    const SizedBox(height: AppSpacing.lg),

                    // 2. Search Input Container with dynamic trailing icon
                    _buildSearchInput(context),

                    const SizedBox(height: AppSpacing.sm),

                  if (isSearching) ...[
                    // Discover Filters Strip (Filter, Sort, Type, Benefit Type, Ministry, Clear All)
                    _buildDiscoverFiltersStrip(),
                  ] else ...[
                    // Try banner when idle
                    GestureDetector(
                      onTap: () {
                        _searchController.text = _dynamicSearchHintText;
                        _searchFocusNode.unfocus();
                        _triggerSearch(_dynamicSearchHintText);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                            size: 12,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "${context.l10n.trySearchPrefix} $_dynamicSearchHintText",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: _scaledFontSize(11),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildQuickPills(context),
                  ],
                ],
              ),
            ),
          ),

            const SizedBox(height: AppSpacing.tight),

            // 4. DYNAMIC AREA (AnimatedSwitcher)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildDynamicContent(categories),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPanel(
        onApplied: () {
          _applyFiltersAndSort();
        },
      ),
    );
  }

  void _clearAllFilters() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.clearFilters();
    setState(() {
      _sortBy = 'Relevance';
      _selectedType = 'All';
      _selectedBenefit = 'All';
      _selectedMinistry = 'All';
      _activeSearchFilters = {};
      _activeFilter = 'All';
    });
    _applyFiltersAndSort();
  }

  // 1. Custom App Bar (Styled like Discover page header)
  Widget _buildCustomAppBar(BuildContext context, AppProvider provider) {
    final isTa = provider.selectedLanguage == 'ta';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.searchTitle,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.hairline),
        Text(
          isTa
              ? 'அனைத்து அரசுத் திட்டங்களையும் எளிதாகத் தேடுங்கள்'
              : 'Find and explore all eligible government schemes',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // Quick Search Horizontal Pills
  Widget _buildQuickPills(BuildContext context) {
    final pills = [
      context.l10n.quickPillPmegp,
      context.l10n.quickPillStartup,
      context.l10n.quickPillLoans,
      context.l10n.quickPillWomen,
      context.l10n.quickPillAscend,
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pills.length,
        itemBuilder: (context, index) {
          final text = pills[index];
          return GestureDetector(
            onTap: () {
              final query = text
                  .replaceAll("Search ", "")
                  .replaceAll("தேடுக", "")
                  .trim();
              submitVoiceQuery(query);
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: AppSpacing.tight),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. Search Input Container
  Widget _buildSearchInput(BuildContext context) {
    final bool hasText = _searchController.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) {
          _triggerSearch(_searchController.text);
        },
        onChanged: (val) {
          setState(() {});
          if (val.trim().isEmpty && _currentState != SearchState.idle) {
            setState(() {
              _currentState = SearchState.idle;
              _searchResults = [];
              _masterSearchResults = [];
            });
          }
        },
        style: GoogleFonts.inter(
          fontSize: _scaledFontSize(13),
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: context.l10n.searchPlaceholder,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12.5,
          ),
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.search,
              color: Color(0xFF2563EB),
              size: 20,
            ),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                _searchFocusNode.unfocus();
                _triggerSearch(_searchController.text);
              }
            },
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _sortBy = 'Relevance';
                      _selectedType = 'All';
                      _selectedBenefit = 'All';
                      _selectedMinistry = 'All';
                      _activeSearchFilters = {};
                      _activeFilter = "All";
                      _currentState = SearchState.idle;
                      _searchResults = [];
                      _masterSearchResults = [];
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (hasText) const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: Icon(
                  _isDictating ? Icons.mic : Icons.mic_none,
                  color: _isDictating
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  size: 20,
                ),
                onPressed: _toggleDictation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }

  Widget _buildDropdownChip(
    String label,
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    final bool isActive = currentValue != 'All' && currentValue != 'Relevance';
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: PopupMenuButton<String>(
        onSelected: onChanged,
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        itemBuilder: (context) => options
            .map(
              (opt) => PopupMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentValue == 'All' ? label : '$label: $currentValue',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Filters Strip from Discover page (Filter button + Dropdown Chips + Clear All)
  Widget _buildDiscoverFiltersStrip() {
    final provider = Provider.of<AppProvider>(context);
    final isTa = provider.selectedLanguage == 'ta';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Filter Button
          OutlinedButton.icon(
            onPressed: _openFilterPanel,
            icon: const Icon(
              Icons.filter_list,
              size: 14,
              color: Color(0xFF2563EB),
            ),
            label: Text(
              isTa ? "வடிகட்டி" : "Filter",
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.tight),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Dropdowns
          _buildDropdownChip(
            isTa ? 'வரிசைப்படுத்து' : 'Sort',
            [
              'Relevance',
              'Benefits: High to Low',
              'Match %',
              'Scheme Name (A-Z)',
            ],
            _sortBy,
            (v) {
              setState(() => _sortBy = v);
              _applyFiltersAndSort();
            },
          ),
          _buildDropdownChip(
            isTa ? 'வகை' : 'Type',
            ['All', 'Loan', 'Subsidy', 'Scholarship', 'Pension'],
            _selectedType,
            (v) {
              setState(() => _selectedType = v);
              _applyFiltersAndSort();
            },
          ),
          _buildDropdownChip(
            isTa ? 'பயன் வகை' : 'Benefit Type',
            [
              'All',
              'Financial',
              'Skill training',
              'Infrastructure',
            ],
            _selectedBenefit,
            (v) {
              setState(() => _selectedBenefit = v);
              _applyFiltersAndSort();
            },
          ),
          _buildDropdownChip(
            isTa ? 'அமைச்சகம்' : 'Ministry',
            ['All', 'MSME', 'Education', 'Finance', 'Agriculture'],
            _selectedMinistry,
            (v) {
              setState(() => _selectedMinistry = v);
              _applyFiltersAndSort();
            },
          ),

          // Clear All
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              context.l10n.filterClearAll,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent(List<Map<String, dynamic>> categories) {
    switch (_currentState) {
      case SearchState.loading:
        return KeyedSubtree(
          key: const ValueKey('SearchLoadingState'),
          child: _buildLoadingSkeleton(),
        );
      case SearchState.results:
        return KeyedSubtree(
          key: const ValueKey('SearchResultsState'),
          child: _buildResultsList(),
        );
      case SearchState.idle:
        return KeyedSubtree(
          key: const ValueKey('SearchIdleState'),
          child: _buildIdleContent(categories),
        );
    }
  }

  Widget _buildIdleContent(List<Map<String, dynamic>> categories) {
    return ListView(
      key: const ValueKey("IdleContent"),
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHighlightSummaryCard(),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.browseCategories,
          style: GoogleFonts.poppins(
            fontSize: _scaledFontSize(16),
            fontWeight: _scaledFontWeight(FontWeight.bold),
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...categories.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  // State 2: Shimmer Skeleton List
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      key: const ValueKey("LoadingContent"),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _ShimmerSkeletonCard();
      },
    );
  }

  // State 3: Search Results List (Matching Discover Results Screen style)
  Widget _buildResultsList() {
    final provider = Provider.of<AppProvider>(context);
    final String queryText = _searchController.text.isNotEmpty
        ? _searchController.text
        : _activeFilter;

    if (_searchResults.isEmpty) {
      final isTa = provider.selectedLanguage == 'ta';
      final bool forMeNeedsProfile = _activeFilter == 'For Me' &&
          _forMeEmptyState == ForMeEmptyState.completeProfile;
      final bool forMeNoMatches = _activeFilter == 'For Me' &&
          _forMeEmptyState != ForMeEmptyState.completeProfile;

      final String title;
      final String subtitle;
      final IconData icon;
      if (forMeNeedsProfile) {
        icon = Icons.assignment_ind_outlined;
        title = isTa
            ? 'தனிப்பட்ட பரிந்துரைகளுக்கு உங்கள் சுயவிவரத்தை நிரப்பவும்'
            : 'Complete your profile to see personalised matches';
        subtitle = isTa
            ? 'வயது, பாலினம் மற்றும் மாநிலம் சேர்த்தால் "எனக்கானது" உங்களுக்கு ஏற்ற திட்டங்களைக் காட்டும்.'
            : 'Add your date of birth, gender and state so "For Me" can match schemes to you.';
      } else if (forMeNoMatches) {
        icon = Icons.search_off_rounded;
        title = isTa
            ? 'உங்கள் சுயவிவரத்திற்கு இப்போது பொருந்தும் திட்டங்கள் இல்லை'
            : 'No schemes match your profile yet';
        subtitle = isTa
            ? 'வடிகட்டிகளை மாற்றவும் அல்லது சுயவிவரத்தைப் புதுப்பிக்கவும்.'
            : 'Try adjusting the filters, or update your profile details.';
      } else {
        icon = Icons.search_off_rounded;
        title = context.l10n.noSchemesFound(queryText);
        subtitle = context.l10n.tryDifferentKeyword;
      }

      return ListView(
        key: const ValueKey('ResultsContent'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 48),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.grey[400]),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: _scaledFontSize(15),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: _scaledFontSize(12),
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: const ValueKey('ResultsContent'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final isForMe = _activeFilter == 'For Me';
          final titleText = isForMe
              ? (provider.selectedLanguage == 'ta'
                  ? "உங்களுக்கான திட்டங்கள் (${_searchResults.length})"
                  : "Eligible Schemes For You (${_searchResults.length})")
              : (provider.selectedLanguage == 'ta'
                  ? "பொருந்தும் திட்டங்கள் (${_searchResults.length})"
                  : "Matching Schemes (${_searchResults.length})");

          final subtitleText = isForMe
              ? (provider.selectedLanguage == 'ta'
                  ? "உங்கள் சுயவிவரத் தகவலின் அடிப்படையில் பொருந்தும் திட்டங்கள்"
                  : "Matched strictly against your profile data")
              : (_searchController.text.trim().isNotEmpty
                  ? "Best matches for \"${_searchController.text.trim()}\""
                  : "Best matches for your search criteria");

          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitleText,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        final scheme = _searchResults[index - 1];
        final recResult =
            RecommendationEngine.evaluate(provider.profile, scheme);

        return SchemeCard(
          scheme: scheme,
          result: recResult,
          isBookmarked: provider.bookmarkedIds.contains(scheme.id),
          onBookmarkToggle: () => provider.toggleBookmark(scheme.id),
          showActions: false,
          showMatchPercentage: _activeFilter == 'For Me',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
        );
      },
    );
  }

  // Highlight Card from Idle State
  Widget _buildHighlightSummaryCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = 'For Me';
          _sortBy = 'Relevance';
          _selectedType = 'All';
          _selectedBenefit = 'All';
          _selectedMinistry = 'All';
          _activeSearchFilters = {};
        });
        _searchController.clear();
        _triggerSearch('For Me');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFF6FF),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.forMe,
                          style: GoogleFonts.poppins(
                            fontSize: _scaledFontSize(14.5),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.tight,
                          vertical: AppSpacing.hairline,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.activeBadge,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF047857),
                            fontSize: _scaledFontSize(8.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isLoadingCounts
                        ? context.l10n.calculatingMatches
                        : context.l10n.schemesMatchProfile(
                            _matchingProfileCount,
                          ),
                    style: GoogleFonts.inter(
                      fontSize: _scaledFontSize(10.5),
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 32,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          left: AppSpacing.xs,
                          right: AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 16,
                              height: 2.5,
                              color: const Color(0xFF93C5FD),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 20,
                              height: 2.5,
                              color: const Color(0xFF93C5FD),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 12,
                              height: 2.5,
                              color: const Color(0xFF93C5FD),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF93C5FD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF2563EB),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Browse Category Card
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final categoryTitle = category["title"] as String;
            final schemes = await SchemeRepository.instance
                .getSchemesByCategory(categoryTitle);
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchResultsScreen(
                  title: categoryTitle,
                  type: 'category',
                  initialSchemes: schemes,
                ),
              ),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category["iconBg"] as Color,
              ),
              alignment: Alignment.center,
              child: Icon(
                category["icon"] as IconData,
                color: category["iconColor"] as Color,
                size: 20,
              ),
            ),
            title: Text(
              _getLocalizedTagOrCategory(
                category["title"] as String,
                provider.selectedLanguage,
              ),
              style: GoogleFonts.inter(
                fontSize: _scaledFontSize(12.5),
                fontWeight: _scaledFontWeight(FontWeight.bold),
                color: const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              category["count"] as String,
              style: GoogleFonts.inter(
                fontSize: _scaledFontSize(10),
                color: const Color(0xFF64748B),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// 5. self-contained Shimmer Skeleton Card Widget
class _ShimmerSkeletonCard extends StatefulWidget {
  const _ShimmerSkeletonCard();

  @override
  State<_ShimmerSkeletonCard> createState() => _ShimmerSkeletonCardState();
}

class _ShimmerSkeletonCardState extends State<_ShimmerSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer Logo Box
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Shimmer Content Lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
