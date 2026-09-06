import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/filter_panel.dart';
import '../../models/scheme_model.dart';
import '../../models/scheme_filter.dart';
export '../../models/scheme_filter.dart'
    show schemeIsNationwide, applySchemeFilters;
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

/// Legacy name kept for [computeForMeView] and existing tests. The one
/// matcher now lives in `models/scheme_filter.dart`.
List<Scheme> applyProviderFacetFilters(
  List<Scheme> input,
  Map<String, dynamic> filters,
) =>
    applySchemeFilters(input, filters);

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
      .where(
        (s) =>
            RecommendationEngine.evaluate(profile, s).score >=
            RecommendationEngine.forMeThreshold,
      )
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
    // Single source of truth for the "For Me" set: routes through the exact
    // same computeForMeView used to build the results list (score gate
    // INTERSECTED with provider.filters), so the `_matchingProfileCount`
    // badge can never drift from what the list actually shows. Previously
    // this called RecommendationEngine.forMeSchemes() directly, which
    // applied the score gate only and ignored provider.filters entirely --
    // whenever a facet (state/category/ministry/etc.) was active, the badge
    // showed the full score-gated count while the real list additionally
    // filtered by that facet, e.g. "5 schemes match your profile" opening to
    // a list of only 2.
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

  /// Requests focus (and, via the platform's normal focus->keyboard behavior,
  /// opens the keyboard) on the real search TextField. Called by HomeScreen
  /// via searchTabKey right after switching to this tab, the same
  /// GlobalKey-based pattern already used for submitVoiceQuery/
  /// openFilterBottomSheet -- so a single tap on the home search bar lands
  /// the user here with the keyboard already up, instead of the previous
  /// fake "tap once to reveal pills, tap again to navigate" two-step (which
  /// never actually opened a keyboard, because the home search bar was a
  /// plain Text widget, not a TextField).
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
      barrierLabel: 'Voice assistant',
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
    // Rebuild immediately so the clear-icon reflects the current text.
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // If text gets cleared, revert to idle if no filters are active; otherwise re-apply filters
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
    // If query is empty and no active filters, go back to idle Categories screen
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

    // Regular search is a pure relevance lookup -- never pre-filtered or
    // re-ranked by the user's profile. The profile-based "For Me" view is
    // applied afterwards, and only when the user has enabled its filter
    // chip (see _applyFiltersAndSort step 6).
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
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Crisp clean background without blue shade
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top header elements
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
        // Text-change handling (debounce + idle reset) lives solely in
        // _onSearchTextChanged via the controller listener, so there is
        // only one path reacting to keystrokes.
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
            tooltip: 'Search',
            icon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
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
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _sortBy = 'Relevance';
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
                tooltip: _isDictating ? 'Stop voice search' : 'Voice search',
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
    final bool isActive =
        currentValue.isNotEmpty &&
        currentValue != 'All' &&
        currentValue != 'Relevance';
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: opt == currentValue
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: opt == currentValue
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    if (opt == currentValue)
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
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
                (currentValue.isEmpty || currentValue == 'All')
                    ? label
                    : '$label: $currentValue',
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

  // 3. Filters strip: Filter · For Me · Sort  (nothing else).
  Widget _buildDiscoverFiltersStrip() {
    final provider = Provider.of<AppProvider>(context);
    final isTa = provider.selectedLanguage == 'ta';
    final int facetCount = activeSchemeFilterCount(provider.filters);

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
              facetCount > 0
                  ? '${isTa ? "வடிகட்டி" : "Filter"} · $facetCount'
                  : (isTa ? "வடிகட்டி" : "Filter"),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.tight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // "For Me" -- opt-in profile-eligibility filter. Off by default;
          // regular search results are never profile-weighted. Turning it
          // on drops schemes the user is not eligible for, keeping the
          // relevance order (see _applyFiltersAndSort step 6).
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _activeFilter = _activeFilter == 'For Me' ? 'All' : 'For Me';
              });
              _applyFiltersAndSort();
            },
            icon: Icon(
              Icons.auto_awesome,
              size: 14,
              color: _activeFilter == 'For Me'
                  ? Colors.white
                  : const Color(0xFF2563EB),
            ),
            label: Text(
              context.l10n.forMe,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _activeFilter == 'For Me'
                    ? Colors.white
                    : const Color(0xFF2563EB),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: _activeFilter == 'For Me'
                  ? const Color(0xFF2563EB)
                  : Colors.white,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.tight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Sort
          _buildDropdownChip(
            isTa ? 'வரிசைப்படுத்து' : 'Sort',
            const [
              'Relevance',
              'Best match for me',
              'Scheme name (A-Z)',
            ],
            _sortBy,
            (v) {
              setState(() => _sortBy = v);
              _applyFiltersAndSort();
            },
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
    final String queryText = _searchController.text.trim();

    if (_searchResults.isEmpty) {
      final isTa = provider.selectedLanguage == 'ta';
      final bool forMeNeedsProfile =
          _activeFilter == 'For Me' &&
          _forMeEmptyState == ForMeEmptyState.completeProfile;
      final bool forMeNoMatches =
          _activeFilter == 'For Me' &&
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
      } else if (queryText.isNotEmpty) {
        icon = Icons.search_off_rounded;
        title = context.l10n.noSchemesFound(queryText);
        subtitle = context.l10n.tryDifferentKeyword;
      } else {
        icon = Icons.filter_alt_off_outlined;
        title = isTa
            ? 'தேர்ந்தெடுக்கப்பட்ட வடிகட்டிகளுக்கு பொருந்தும் திட்டங்கள் எதுவும் இல்லை'
            : 'No schemes found matching your filters';
        subtitle = isTa
            ? 'வடிகட்டிகளை மாற்றவும் அல்லது மீட்டமைக்கவும்.'
            : 'Try adjusting or clearing your filters to see more results.';
      }

      return ListView(
        key: const ValueKey('ResultsContent'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 48,
        ),
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
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
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
        final recResult = RecommendationEngine.evaluate(
          provider.profile,
          scheme,
        );

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
        });
        _searchController.clear();
        _triggerSearch('For Me');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
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
            subtitle: _isLoadingCounts
                ? const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.hairline),
                    child: _SkeletonBar(width: 70, height: 10),
                  )
                : Text(
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

// A small reusable static skeleton bar, for inline loading placeholders
// (e.g. a category tile's count while getCategoryCounts() is still
// computing) that are too small to warrant a full _ShimmerSkeletonCard.
// Deliberately NOT animated, unlike _ShimmerSkeletonCard below: this shows
// during the idle Browse Categories view, which is on screen by default
// (not just during a transient results-loading state), so an indefinitely-
// repeating animation here would leave every widget test that pumps this
// screen unable to ever reach `pumpAndSettle()` -- there would always be a
// pending frame. A static box still reads as "loading" via its shape/color.
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
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
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
