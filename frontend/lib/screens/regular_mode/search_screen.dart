import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../services/voice/voice_recognition_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/share_text.dart';
import '../../widgets/common/app_bottom_nav_bar.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/quick_pills.dart';
import '../../widgets/common/standard_page_header.dart';
import '../../widgets/scheme/filter_panel.dart';
import 'search/browse_scope.dart';
import 'search/search_filter_strip.dart';
import 'search/search_idle_content.dart';
import 'search/search_input_section.dart';
import 'search/search_models.dart';
import 'search/search_results_view.dart';
import '../../widgets/common/sign_in_required_sheet.dart';

// Re-exports for backwards compatibility and tests
export '../../models/scheme_filter.dart'
    show schemeIsNationwide, applySchemeFilters;
export 'search/search_filter_strip.dart';
export 'search/search_idle_content.dart';
export 'search/search_input_section.dart';
export 'search/search_models.dart';
export 'search/search_results_view.dart';
export 'search/shimmer_skeleton_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.scope,
    this.initialQuery,
    this.showBack = false,
    this.keepFilters = false,
  });

  /// Opens the screen as a browse page on this base set (Discover category,
  /// ministry, state, home tile, eligible list). Null for the Search tab.
  final BrowseScope? scope;

  /// Opens the screen as a results page for this already-chosen query.
  final String? initialQuery;

  /// A pushed page (browse / results) rather than the Search tab: shows a back
  /// button and the page title instead of the tab header.
  final bool showBack;

  /// Keep the global filters the caller just set (the browse questionnaire's
  /// answers). Otherwise a pushed page starts clean, so a filter left over from
  /// another screen cannot silently narrow it.
  final bool keepFilters;

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final VoiceRecognitionController _dictationController =
      AutomaticVoiceRecognitionController();
  Timer? _searchDebounce;
  bool _isDictating = false;
  SearchState _currentState = SearchState.idle;
  String _activeFilter = "All";

  bool get isSearching =>
      _currentState != SearchState.idle ||
      _searchController.text.trim().isNotEmpty;

  // Data list of scheme results from the catalog
  List<Scheme> _searchResults = [];
  List<Scheme> _masterSearchResults = [];
  String _sortBy = 'Relevance';
  Map<String, int> _categoryCounts = {};
  bool _isLoadingCounts = true;
  int _matchingProfileCount = 0;
  // True when [_matchingProfileCount] counts partial matches (nothing
  // cleared the For Me threshold), see pickForYou.
  bool _matchingProfileIsPartial = false;
  // Null until the catalog-derived hint loads; render sites fall back to the
  // localized `searchHintFallback` string so the placeholder is correct in ta too.
  String? _dynamicSearchHintText;
  // Bumped on every _triggerSearch call; a stale request that resolves after
  // a newer one must not overwrite it (out-of-order async race -- the search
  // screen's state survives Home<->Search tab switches via IndexedStack, so
  // an in-flight request from a previous query can still land here).
  int _searchGeneration = 0;
  // A corrected spelling of the last query ("laon" -> "loan"), offered as a
  // tappable "Did you mean ...?"; null when the query needed no correction.
  String? _didYouMean;

  // Results the user typed by name that "For Me" or a filter dropped; they stay
  // in the list, last, flagged "not applicable".
  Set<String> _notApplicableIds = {};

  /// The subset of [_notApplicableIds] hidden only by the Filter sheet.
  Set<String> _filterMismatchIds = {};

  // The base set when this is a browse page (see [BrowseScope]); null on the
  // Search tab, and once the user types a query (a search leaves the browse).
  BrowseScope? _scope;
  AppProvider? _provider;

  // Which empty state the "For Me" results view should render (see
  // ForMeEmptyState). Kept current even when there is nothing to filter so
  // the view can explain *why* it is empty instead of silently showing the
  // whole catalog or a bare "no results".
  ForMeEmptyState _forMeEmptyState = ForMeEmptyState.none;

  ForMeViewResult _computeEligibleSchemes(
    AppProvider provider,
    List<Scheme> all,
  ) {
    final list = all.isNotEmpty ? all : provider.allSchemes;
    return computeForMeView(
      master: list,
      profile: provider.profile,
      filters: provider.filters,
    );
  }

  Future<void> _applyFiltersAndSort() async {
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

    final bool hasTextQuery = _searchController.text.trim().isNotEmpty;

    // Only fall back to the whole catalog for a filter-only / browse view.
    // A text query that matched nothing must stay empty so the results view
    // can show its "no scheme found" state -- not silently list every scheme.
    // A browse page with an empty base set stays empty (never the catalog).
    if (_masterSearchResults.isEmpty && !hasTextQuery && _scope == null) {
      final catalog = provider.allSchemes.isNotEmpty
          ? provider.allSchemes
          : await SchemeRepository.instance.getAllSchemes();
      _masterSearchResults = catalog;
    }
    List<Scheme> filteredResults = List<Scheme>.from(_masterSearchResults);

    // 1. Facet filters (from the Filter sheet). Skipped in "For Me" mode --
    //    computeForMeView folds them in below so they aren't applied twice.
    if (_activeFilter != 'For Me') {
      filteredResults = applySchemeFilters(filteredResults, provider.filters);
    }

    // 2. "For Me": opt-in profile-eligibility gate. Never the catalog.
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

    // 3. Sort. 'Relevance' (default) keeps the incoming order -- the search
    //    engine's ranking for a text query, catalog order when browsing.
    //    Profile fit is applied ONLY here via 'Best match for me' (or the
    //    'For Me' chip), never for plain 'Relevance'.
    if (_sortBy == 'Best match for me' ||
        _sortBy == 'Match %' ||
        _sortBy == 'Match') {
      filteredResults.sort((a, b) {
        final sa = RecommendationEngine.evaluate(
          provider.profile,
          a,
        ).percentage;
        final sb = RecommendationEngine.evaluate(
          provider.profile,
          b,
        ).percentage;
        return sb.compareTo(sa);
      });
    } else if (_sortBy == 'Scheme name (A-Z)' ||
        _sortBy == 'Scheme Name (A-Z)') {
      filteredResults.sort(
        (a, b) => a
            .getName(provider.selectedLanguage)
            .toLowerCase()
            .compareTo(b.getName(provider.selectedLanguage).toLowerCase()),
      );
    }

    // A scheme typed by name must not vanish because of "For Me" or a facet
    // filter: list it last, flagged "not applicable".
    final hiddenExact = hasTextQuery
        ? exactMatchesHidden(
            query: _searchController.text,
            candidates: _masterSearchResults,
            shown: filteredResults,
          )
        : <Scheme>[];
    final notApplicableIds = {for (final s in hiddenExact) s.id};
    // Outside "For Me" only the Filter sheet can hide a scheme. In "For Me",
    // one that passes the Filter sheet was hidden by eligibility instead.
    final filterMismatchIds = {
      for (final s in hiddenExact)
        if (_activeFilter != 'For Me' ||
            applySchemeFilters([s], provider.filters).isEmpty)
          s.id,
    };
    filteredResults = [...filteredResults, ...hiddenExact];

    final bool hasActiveFilter =
        _activeFilter == 'For Me' || hasActiveSchemeFilters(provider.filters);

    if (_searchController.text.trim().isEmpty &&
        !hasActiveFilter &&
        _scope == null) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _masterSearchResults = [];
          _currentState = SearchState.idle;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _searchResults = filteredResults;
        _notApplicableIds = notApplicableIds;
        _filterMismatchIds = filterMismatchIds;
        _currentState = SearchState.results;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scope = widget.scope;
    _searchController.addListener(_onSearchTextChanged);
    if (widget.showBack) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _provider = provider;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!widget.keepFilters) provider.clearFilters();
        final query = widget.initialQuery?.trim() ?? '';
        if (_scope != null) {
          _loadScope();
        } else if (query.isNotEmpty) {
          submitVoiceQuery(query);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _categoryCounts = counts;
          _matchingProfileCount = eligibleSchemes.schemes.length;
          _matchingProfileIsPartial =
              eligibleSchemes.emptyState == ForMeEmptyState.partialMatches;
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

  /// Direct search-bar dictation.
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

    if (!mounted) return;
    setState(() => _isDictating = true);
    // Listen in the app's language (issue #128: Tamil speech was recognised
    // as English). English keeps automatic English/Tamil detection.
    final lang = Provider.of<AppProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    const speechLocales = {'ta': 'ta-IN', 'hi': 'hi-IN', 'mr': 'mr-IN'};
    await _dictationController.listen(localeId: speechLocales[lang]);
  }

  @override
  void dispose() {
    if (widget.showBack) {
      // A pushed page must not leave its filters behind for the Search tab.
      final provider = _provider;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          provider?.clearFilters();
        } on FlutterError {
          // The provider was disposed with the whole tree (app teardown).
        }
      });
    }
    _searchDebounce?.cancel();
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

  void focusSearchField() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  /// The Home search bar: start a new search. It must never reopen the last
  /// results (or a filter left from another screen) -- results appear only
  /// once a query is actually run.
  void focusFreshSearch() {
    if (!mounted) return;
    Provider.of<AppProvider>(context, listen: false).clearFilters();
    resetToIdle();
    if (_searchController.text.isNotEmpty) _searchController.clear();
    focusSearchField();
  }

  Future<List<Scheme>> _fetchScope(BrowseScope scope) {
    final repo = SchemeRepository.instance;
    switch (scope.type?.toLowerCase()) {
      case 'ministry':
        return repo.getSchemesByMinistry(scope.title);
      case 'state':
        return repo.getSchemesByState(scope.title);
      case 'category':
        return repo.getSchemesByCategory(scope.title);
      default:
        return repo.getAllSchemes();
    }
  }

  /// Loads a browse page's base set and shows it through the normal
  /// filter / For Me / sort pipeline.
  Future<void> _loadScope() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _currentState = SearchState.loading;
      _didYouMean = null;
    });
    final base = scope.schemes ?? await _fetchScope(scope);
    if (!mounted || !identical(_scope, scope)) return;
    _masterSearchResults = List<Scheme>.from(base);
    await _applyFiltersAndSort();
  }

  void _clearFiltersAndReload() {
    Provider.of<AppProvider>(context, listen: false).clearFilters();
    setState(() {
      _activeFilter = 'All';
      _sortBy = 'Relevance';
    });
    _applyFiltersAndSort();
  }

  Future<void> _shareResults(String title) async {
    final lang = Provider.of<AppProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    final names = _searchResults
        .take(5)
        .map((s) => '• ${s.getName(lang)}')
        .join('\n');
    await shareText(
      context,
      '${context.l10n.searchResultsShareHeader(title)}\n$names',
      copiedMessage: context.l10n.resultsCopiedToClipboard,
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
    _searchGeneration++;
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _triggerSearch(query);
        return;
      }
      if (query.isEmpty &&
          _currentState != SearchState.idle &&
          _scope == null) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        final bool hasActiveFilter =
            _activeFilter == 'For Me' ||
            hasActiveSchemeFilters(provider.filters);
        if (!hasActiveFilter) {
          setState(() {
            _searchResults = [];
            _masterSearchResults = [];
            _currentState = SearchState.idle;
          });
        } else {
          _applyFiltersAndSort();
        }
      }
    });
  }

  void _triggerSearch(String query) async {
    _searchDebounce?.cancel();
    if (_scope != null) {
      if (query.trim().isEmpty) {
        _applyFiltersAndSort();
        return;
      }
      // A typed query is a catalog search, not a browse: leave the base set.
      setState(() => _scope = null);
    }
    final provider0 = Provider.of<AppProvider>(context, listen: false);
    if (query.isEmpty &&
        _activeFilter == 'All' &&
        !hasActiveSchemeFilters(provider0.filters)) {
      _searchGeneration++;
      setState(() {
        _currentState = SearchState.idle;
        _searchResults = [];
        _masterSearchResults = [];
      });
      return;
    }

    final int requestGeneration = ++_searchGeneration;

    // Refining a search that is already showing results keeps them on screen
    // until the new ones arrive; swapping to the skeleton on every keystroke
    // made the list flash.
    setState(() {
      if (_currentState != SearchState.results) {
        _currentState = SearchState.loading;
      }
      _didYouMean = null;
    });

    final String normalQuery = query.toLowerCase().trim();

    try {
      List<Scheme> results;
      String? suggestion;
      if (normalQuery.isEmpty ||
          normalQuery == 'all' ||
          normalQuery == 'suitable schemes' ||
          normalQuery == 'for me') {
        results = await SchemeRepository.instance.getAllSchemes();
      } else {
        results = await SchemeRepository.instance.searchSchemes(query);
        // A failed suggestion must never cost the user their results.
        try {
          suggestion = await SchemeRepository.instance.suggestQueryCorrection(
            query,
          );
        } catch (e) {
          debugPrint('[SearchScreen] spelling suggestion failed: $e');
        }
      }

      if (!mounted || requestGeneration != _searchGeneration) return;

      _masterSearchResults = results;
      _didYouMean = suggestion;
      _applyFiltersAndSort();
    } catch (e, st) {
      debugPrint('[SearchScreen] search failed for "$query": $e\n$st');
      if (!mounted || requestGeneration != _searchGeneration) return;
      setState(() {
        _masterSearchResults = [];
        _searchResults = [];
        _currentState = SearchState.results;
      });
    }
  }

  /// Runs the search again with the corrected spelling the user tapped.
  void _applyDidYouMean(String suggestion) {
    _searchController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    _searchFocusNode.unfocus();
    _triggerSearch(suggestion);
  }

  /// The list the Filter sheet counts over: the current results' base set
  /// when a query or browse page defines one, else null so the sheet counts
  /// over the live catalog. On the idle Search tab [_masterSearchResults] is
  /// an empty placeholder, not "no schemes": passing it made every count and
  /// "Show N schemes" read 0 until a search had run.
  List<Scheme>? get _filterPanelBase {
    final idle =
        _scope == null &&
        _searchController.text.trim().isEmpty &&
        _currentState != SearchState.results;
    return idle ? null : _masterSearchResults;
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPanel(
        baseSchemes: _filterPanelBase,
        onApplied: () {
          _applyFiltersAndSort();
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getCategories(BuildContext context) {
    return [
      {
        "title": "MSME",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["MSME"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.storefront_outlined,
      },
      {
        "title": "Startup",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Startup"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.lightbulb_outline_rounded,
      },
      {
        "title": "Women Entrepreneurs",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Women Entrepreneurs"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.woman_outlined,
      },
      {
        "title": "Business Loans & Credit",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Business Loans & Credit"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.account_balance_outlined,
      },
      {
        "title": "Export & Trade Promotion",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Export & Trade Promotion"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.local_shipping_outlined,
      },
      {
        "title": "SHG & Artisan",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["SHG & Artisan"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.groups_outlined,
      },
      {
        "title": "Technology",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Technology"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.computer_outlined,
      },
      {
        "title": "Manufacturing",
        "count": _isLoadingCounts
            ? "..."
            : "${_categoryCounts["Manufacturing"] ?? 0} ${context.l10n.schemes}",
        "icon": Icons.factory_outlined,
      },
    ];
  }

  Widget _buildDynamicContent(List<Map<String, dynamic>> categories) {
    switch (_currentState) {
      case SearchState.loading:
        return const KeyedSubtree(
          key: ValueKey('SearchLoadingState'),
          child: SearchLoadingSkeleton(),
        );
      case SearchState.results:
        final provider = Provider.of<AppProvider>(context);
        return KeyedSubtree(
          key: const ValueKey('SearchResultsState'),
          child: SearchResultsList(
            searchResults: _searchResults,
            queryText: _searchController.text.trim(),
            isForMe: _activeFilter == 'For Me',
            forMeEmptyState: _forMeEmptyState,
            provider: provider,
            didYouMean: _didYouMean,
            onDidYouMeanTap: _applyDidYouMean,
            notApplicableIds: _notApplicableIds,
            filterMismatchIds: _filterMismatchIds,
            onClearFilters:
                (_scope != null || hasActiveSchemeFilters(provider.filters))
                ? _clearFiltersAndReload
                : null,
          ),
        );
      case SearchState.idle:
        return KeyedSubtree(
          key: const ValueKey('SearchIdleState'),
          child: SearchIdleContent(
            categories: categories,
            isLoadingCounts: _isLoadingCounts,
            matchingProfileCount: _matchingProfileCount,
            matchingProfileIsPartial: _matchingProfileIsPartial,
            showForMe: !Provider.of<AppProvider>(context).isGuest,
            onHighlightTap: () {
              setState(() {
                _activeFilter = 'For Me';
                _sortBy = 'Relevance';
              });
              _searchController.clear();
              _triggerSearch('For Me');
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final categories = _getCategories(context);
    final pageTitle = CentralizedTranslator.instance.localize(
      widget.scope?.title ?? widget.initialQuery ?? '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // A pushed browse / results page sits above the tab shell and hid its
      // bar; show it again so the user can switch tab from here.
      bottomNavigationBar:
          widget.showBack && provider.navigationMode != 'companion'
          ? AppBottomNavBar(
              selectedIndex: provider.currentTabIndex,
              onSelected: (i) {
                provider.updateTabIndex(i);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              labels: [
                context.l10n.navHome,
                context.l10n.navSearch,
                context.l10n.navDiscover,
                context.l10n.navSaved,
                context.l10n.navProfile,
              ],
            )
          : null,
      appBar: widget.showBack
          ? StandardPageHeader(
              title: pageTitle,
              subtitle: _currentState == SearchState.results
                  ? context.l10n.schemesAvailableCount(_searchResults.length)
                  : null,
              actions: [
                IconButton(
                  tooltip: context.l10n.shareResultsTooltip,
                  icon: const Icon(
                    Icons.share_outlined,
                    size: AppSize.icon,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _shareResults(pageTitle),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.showBack) ...[
                      const SearchHeaderBar(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    SearchInputField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      isDictating: _isDictating,
                      onToggleDictation: _toggleDictation,
                      onSubmitted: (val) =>
                          _triggerSearch(_searchController.text),
                      onClear: () {
                        _searchController.clear();
                        if (widget.scope != null) {
                          // Back to the browse page the user came from.
                          setState(() {
                            _scope = widget.scope;
                            _sortBy = 'Relevance';
                            _activeFilter = 'All';
                          });
                          _loadScope();
                          return;
                        }
                        setState(() {
                          _sortBy = 'Relevance';
                          _activeFilter = "All";
                          _currentState = SearchState.idle;
                          _searchResults = [];
                          _masterSearchResults = [];
                        });
                      },
                      onSubmitTap: () => _triggerSearch(_searchController.text),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (isSearching) ...[
                      SearchFilterStrip(
                        facetCount: activeSchemeFilterCount(provider.filters),
                        isForMeActive: _activeFilter == 'For Me',
                        // A guest sees For me with a lock: tapping it says
                        // what signing in unlocks. Best match stays hidden.
                        forMeLocked: provider.isGuest,
                        sortBy: _sortBy,
                        onOpenFilterPanel: _openFilterPanel,
                        onToggleForMe: () async {
                          if (!await requireAccount(
                            context,
                            feature: SignInFeature.forMe,
                          )) {
                            return;
                          }
                          if (!mounted) return;
                          setState(() {
                            _activeFilter = _activeFilter == 'For Me'
                                ? 'All'
                                : 'For Me';
                          });
                          _applyFiltersAndSort();
                        },
                        onSortChanged: (v) {
                          setState(() => _sortBy = v);
                          _applyFiltersAndSort();
                        },
                      ),
                    ] else ...[
                      SearchTryBanner(
                        hintText:
                            _dynamicSearchHintText ??
                            context.l10n.searchHintFallback,
                        onTap: () {
                          final hint =
                              _dynamicSearchHintText ??
                              context.l10n.searchHintFallback;
                          _searchController.text = hint;
                          _searchFocusNode.unfocus();
                          _triggerSearch(hint);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      QuickPills(onSelected: submitVoiceQuery),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOut,
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
}
