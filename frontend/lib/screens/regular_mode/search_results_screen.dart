import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../models/scheme_filter.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../widgets/scheme/scheme_card.dart';
import '../../widgets/scheme/filter_panel.dart';
import '../../widgets/common/standard_page_header.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/scheme/catalog_freshness_footer.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../l10n/l10n.dart';
import 'scheme_details_screen.dart';
import '../../utils/app_spacing.dart';

class SearchResultsScreen extends StatefulWidget {
  final String title;
  final String? type; // 'category', 'ministry', 'state', 'query'
  final List<Scheme>? initialSchemes;

  const SearchResultsScreen({
    super.key,
    required this.title,
    this.type,
    this.initialSchemes,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  String _sortBy = 'Relevance';

  List<Scheme>? _baseSchemes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.type == 'query' || widget.type == null ? widget.title : '',
    );
    if (widget.initialSchemes != null) {
      _baseSchemes = widget.initialSchemes;
    } else {
      _loadBaseSchemes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBaseSchemes() async {
    setState(() => _isLoading = true);
    List<Scheme> list;
    final type = widget.type?.toLowerCase();

    if (type == 'ministry') {
      list = await SchemeRepository.instance.getSchemesByMinistry(widget.title);
    } else if (type == 'state') {
      list = await SchemeRepository.instance.getSchemesByState(widget.title);
    } else if (type == 'category') {
      list = await SchemeRepository.instance.getSchemesByCategory(widget.title);
    } else {
      // General search query. A no-match query stays empty (the list shows
      // its "not available" state) -- no substring sweep of the catalog,
      // which would resurface loosely-related wrong schemes.
      final query = widget.title.trim();
      if (query.isNotEmpty) {
        list = await SchemeRepository.instance.searchSchemes(query);
      } else {
        list = await SchemeRepository.instance.getAllSchemes();
      }
    }

    if (!mounted) return;
    setState(() {
      _baseSchemes = list;
      _isLoading = false;
    });
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPanel(
        onApplied: () {
          setState(() {});
        },
      ),
    );
  }

  void _clearAllFilters() {
    Provider.of<AppProvider>(context, listen: false).clearFilters();
    setState(() {
      _sortBy = 'Relevance';
      _searchController.clear();
    });
  }

  List<MapEntry<Scheme, RecommendationResult>> _getFilteredSchemes(
    AppProvider provider,
  ) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    // Facet filters (from the Filter sheet), via the one shared matcher.
    var schemesToFilter =
        applySchemeFilters(_baseSchemes ?? const [], provider.filters);

    // Text refinement within an already-search-ranked base list.
    if (searchQuery.isNotEmpty) {
      schemesToFilter = schemesToFilter.where((scheme) {
        return scheme.name.toLowerCase().contains(searchQuery) ||
            scheme.overview.toLowerCase().contains(searchQuery) ||
            scheme.sponsoringBody.toLowerCase().contains(searchQuery) ||
            scheme.category.toLowerCase().contains(searchQuery) ||
            scheme.searchKeywords.toLowerCase().contains(searchQuery);
      }).toList();
    }

    final filtered = [
      for (final scheme in schemesToFilter)
        MapEntry(scheme, RecommendationEngine.evaluate(provider.profile, scheme)),
    ];

    // Sort. 'Relevance' keeps the base order (search-engine ranking, or
    // profile score when there is no text query). Profile fit only via the
    // explicit 'Best match for me' option.
    if (_sortBy == 'Best match for me' || _sortBy == 'Match %') {
      filtered.sort((a, b) => b.value.score.compareTo(a.value.score));
    } else if (_sortBy == 'Scheme name (A-Z)' ||
        _sortBy == 'Scheme Name (A-Z)') {
      filtered.sort((a, b) => a.key.name.compareTo(b.key.name));
    } else if (searchQuery.isEmpty) {
      filtered.sort((a, b) => b.value.score.compareTo(a.value.score));
    }

    return filtered;
  }

  /// Localized display for a sort value. `_sortBy` keeps the stable English
  /// key (compared in _getFilteredSchemes); only the label is translated.
  String _sortLabel(String value) {
    switch (value) {
      case 'Best match for me':
      case 'Match %':
        return context.l10n.sortBestMatch;
      case 'Scheme name (A-Z)':
      case 'Scheme Name (A-Z)':
        return context.l10n.sortSchemeNameAz;
      case 'Relevance':
      default:
        return context.l10n.sortRelevance;
    }
  }

  Widget _buildDropdownChip(
    String label,
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged, {
    String Function(String value)? displayOf,
  }) {
    String show(String v) => displayOf?.call(v) ?? v;
    final bool isActive = currentValue.isNotEmpty &&
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
                      show(opt),
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
                    : '$label: ${show(currentValue)}',
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

  Widget _buildFiltersStrip(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.tight, horizontal: AppSpacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
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
                context.l10n.filterButton,
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

            // Sort
            _buildDropdownChip(
              context.l10n.sortLabel,
              const [
                'Relevance',
                'Best match for me',
                'Scheme name (A-Z)',
              ],
              _sortBy,
              (v) => setState(() => _sortBy = v),
              displayOf: _sortLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.tight),
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: context.l10n.searchPlaceholder,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12.5,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  tooltip: context.l10n.clearSearchTooltip,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isTa = provider.selectedLanguage == 'ta';
    final displayedTitle = isTa
        ? CentralizedTranslator.instance.translate(widget.title)
        : widget.title;

    final filteredSchemes = _getFilteredSchemes(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: StandardPageHeader(
        title: displayedTitle,
        subtitle: context.l10n.schemesAvailableCount(filteredSchemes.length),
        elevation: 1,
        actions: [
          IconButton(
            tooltip: context.l10n.shareResultsTooltip,
            icon: const Icon(
              Icons.share_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            onPressed: () async {
              final shareText =
                  '${context.l10n.searchResultsShareHeader(displayedTitle)}\n'
                  '${filteredSchemes.take(5).map((e) => '• ${e.key.name}').join('\n')}';
              await Clipboard.setData(ClipboardData(text: shareText));
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  context.l10n.resultsCopiedToClipboard,
                );
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.tight),

            // Search bar for refining results
            _buildSearchInput(),

            // Discover filter strip (Sort, Type, Benefit, Ministry, Filter)
            _buildFiltersStrip(provider),

            const SizedBox(height: AppSpacing.xs),

            // Results Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : filteredSchemes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  () {
                                    final q = _searchController.text.trim();
                                    if (q.isNotEmpty) {
                                      return context.l10n.noSchemesFound(q);
                                    }
                                    if (widget.title.trim().isNotEmpty &&
                                        widget.title.toLowerCase() != 'all') {
                                      return context.l10n.noSchemesFound(widget.title);
                                    }
                                    return context.l10n.searchNoFilterMatchesTitle;
                                  }(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.tight),
                                Text(
                                  context.l10n.tryDifferentKeyword,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                OutlinedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                  label: Text(
                                    context.l10n.clearFiltersAndExplore,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF93C5FD),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm,
                                    ),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          itemCount: filteredSchemes.length,
                          itemBuilder: (context, index) {
                            final entry = filteredSchemes[index];
                            return SchemeCard(
                              scheme: entry.key,
                              result: entry.value,
                              isBookmarked: provider.bookmarkedIds.contains(
                                entry.key.id,
                              ),
                              onBookmarkToggle: () =>
                                  provider.toggleBookmark(entry.key.id),
                              showActions: false,
                              showMatchPercentage: false,
                              onTap: () {
                                provider.addToRecentlyViewed(entry.key.id);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SchemeDetailsScreen(
                                      scheme: entry.key,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
            CatalogFreshnessFooter(isTa: isTa),
          ],
        ),
      ),
    );
  }
}
