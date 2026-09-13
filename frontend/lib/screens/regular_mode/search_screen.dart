import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../services/voice/voice_recognition_controller.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/assistant/voice_assistant_overlay.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/scheme/filter_panel.dart';
import 'scheme_details_screen.dart';
import 'search/search_filter_strip.dart';
import 'search/search_idle_content.dart';
import 'search/search_input_section.dart';
import 'search/search_models.dart';
import 'search/search_results_view.dart';

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
  const SearchScreen({super.key});

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

  // Data list of scheme results from Supabase
  List<Scheme> _searchResults = [];
  List<Scheme> _masterSearchResults = [];
  String _sortBy = 'Relevance';
  Map<String, int> _categoryCounts = {};
  bool _isLoadingCounts = true;
  int _matchingProfileCount = 0;
  // Null until the catalog-derived hint loads; render sites fall back to the
  // localized `searchHintFallback` string so the placeholder is correct in ta too.
  String? _dynamicSearchHintText;
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
    return computeForMeView(
      master: list,
      profile: provider.profile,
      filters: provider.filters,
    ).schemes;
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
    // can show its "no scheme found" state -- not silently list all 219.
    if (_masterSearchResults.isEmpty && !hasTextQuery) {
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
        final sa = RecommendationEngine.evaluate(provider.profile, a).percentage;
        final sb = RecommendationEngine.evaluate(provider.profile, b).percentage;
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

    final bool hasActiveFilter = _activeFilter == 'For Me' ||
        hasActiveSchemeFilters(provider.filters);

    if (_searchController.text.trim().isEmpty && !hasActiveFilter) {
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
        _currentState = SearchState.results;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
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

    setState(() => _isDictating = true);
    await _dictationController.listen();
  }

  @override
  void dispose() {
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

  Future<void> openVoiceAssistant() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final schemes = provider.allSchemes.isNotEmpty
        ? provider.allSchemes
        : await SchemeRepository.instance.getAllSchemes();
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: context.l10n.voiceAssistantLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
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
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
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
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_searchController.text.isEmpty && _currentState != SearchState.idle) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        final bool hasActiveFilter = _activeFilter == 'For Me' ||
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

    setState(() {
      _currentState = SearchState.loading;
    });

    final String normalQuery = query.toLowerCase().trim();

    try {
      List<Scheme> results;
      if (normalQuery.isEmpty ||
          normalQuery == 'all' ||
          normalQuery == 'suitable schemes' ||
          normalQuery == 'for me') {
        results = await SchemeRepository.instance.getAllSchemes();
      } else {
        results = await SchemeRepository.instance.searchSchemes(query);
      }

      if (!mounted || requestGeneration != _searchGeneration) return;

      _masterSearchResults = results;
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

  List<Map<String, dynamic>> _getCategories(BuildContext context) {
    return [
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
            scaledFontSize: _scaledFontSize,
          ),
        );
      case SearchState.idle:
        return KeyedSubtree(
          key: const ValueKey('SearchIdleState'),
          child: SearchIdleContent(
            categories: categories,
            isLoadingCounts: _isLoadingCounts,
            matchingProfileCount: _matchingProfileCount,
            onHighlightTap: () {
              setState(() {
                _activeFilter = 'For Me';
                _sortBy = 'Relevance';
              });
              _searchController.clear();
              _triggerSearch('For Me');
            },
            scaledFontSize: _scaledFontSize,
            scaledFontWeight: _scaledFontWeight,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final categories = _getCategories(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    const SearchHeaderBar(),
                    const SizedBox(height: AppSpacing.lg),
                    SearchInputField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      isDictating: _isDictating,
                      onToggleDictation: _toggleDictation,
                      onSubmitted: (val) => _triggerSearch(_searchController.text),
                      onClear: () {
                        _searchController.clear();
                        setState(() {
                          _sortBy = 'Relevance';
                          _activeFilter = "All";
                          _currentState = SearchState.idle;
                          _searchResults = [];
                          _masterSearchResults = [];
                        });
                      },
                      onSubmitTap: () => _triggerSearch(_searchController.text),
                      scaledFontSize: _scaledFontSize,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (isSearching) ...[
                      SearchFilterStrip(
                        facetCount: activeSchemeFilterCount(provider.filters),
                        isForMeActive: _activeFilter == 'For Me',
                        sortBy: _sortBy,
                        onOpenFilterPanel: _openFilterPanel,
                        onToggleForMe: () {
                          setState(() {
                            _activeFilter =
                                _activeFilter == 'For Me' ? 'All' : 'For Me';
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
                        hintText: _dynamicSearchHintText ??
                            context.l10n.searchHintFallback,
                        onTap: () {
                          final hint = _dynamicSearchHintText ??
                              context.l10n.searchHintFallback;
                          _searchController.text = hint;
                          _searchFocusNode.unfocus();
                          _triggerSearch(hint);
                        },
                        scaledFontSize: _scaledFontSize,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SearchQuickPills(
                        onPillSelected: (query) => submitVoiceQuery(query),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.tight),
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
}
