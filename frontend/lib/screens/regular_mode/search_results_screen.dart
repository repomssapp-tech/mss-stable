import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../engine/recommendation_engine.dart';
import '../../services/scheme_repository.dart';
import '../../widgets/scheme_card.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/standard_page_header.dart';
import '../../widgets/app_toast.dart';
import '../../services/centralized_translator.dart';
import '../../l10n/l10n.dart';
import 'scheme_details_screen.dart';

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
  String _selectedType = 'All';
  String _selectedBenefit = 'All';
  String _selectedMinistry = 'All';

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
      // General search query
      final query = widget.title.trim();
      if (query.isNotEmpty) {
        list = await SchemeRepository.instance.searchSchemes(query);
        if (list.isEmpty) {
          list = await SchemeRepository.instance.getAllSchemes();
          final q = query.toLowerCase();
          list = list.where((s) {
            return s.name.toLowerCase().contains(q) ||
                s.overview.toLowerCase().contains(q) ||
                s.sponsoringBody.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q) ||
                s.searchKeywords.toLowerCase().contains(q);
          }).toList();
        }
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
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.clearFilters();
    setState(() {
      _sortBy = 'Relevance';
      _selectedType = 'All';
      _selectedBenefit = 'All';
      _selectedMinistry = 'All';
      _searchController.clear();
    });
  }

  List<MapEntry<Scheme, RecommendationResult>> _getFilteredSchemes(
    AppProvider provider,
  ) {
    final schemesToFilter = _baseSchemes ?? [];
    final List<MapEntry<Scheme, RecommendationResult>> filtered = [];
    final searchQuery = _searchController.text.trim().toLowerCase();

    for (final scheme in schemesToFilter) {
      final recResult = RecommendationEngine.evaluate(provider.profile, scheme);

      // Search Query refinement
      if (searchQuery.isNotEmpty) {
        final matchesQuery =
            scheme.name.toLowerCase().contains(searchQuery) ||
            scheme.overview.toLowerCase().contains(searchQuery) ||
            scheme.sponsoringBody.toLowerCase().contains(searchQuery) ||
            scheme.category.toLowerCase().contains(searchQuery) ||
            scheme.searchKeywords.toLowerCase().contains(searchQuery);
        if (!matchesQuery) continue;
      }

      // 1. Dropdown Chips Filters: Type (Loan, Subsidy, etc.)
      if (_selectedType != 'All') {
        final typeKeyword = _selectedType.toLowerCase();
        final matchesType =
            scheme.schemeType.toLowerCase().contains(typeKeyword) ||
            scheme.name.toLowerCase().contains(typeKeyword) ||
            scheme.category.toLowerCase().contains(typeKeyword) ||
            scheme.overview.toLowerCase().contains(typeKeyword);
        if (!matchesType) continue;
      }

      // 2. Dropdown Chips Filters: Benefit Type
      if (_selectedBenefit != 'All') {
        final benefitLower = _selectedBenefit.toLowerCase();
        bool matchesBenefit = false;
        if (benefitLower == 'financial') {
          matchesBenefit =
              scheme.benefits.toLowerCase().contains('financial') ||
              scheme.benefits.toLowerCase().contains('₹') ||
              scheme.benefits.toLowerCase().contains('rs') ||
              scheme.benefits.toLowerCase().contains('grant') ||
              scheme.benefits.toLowerCase().contains('subsidy') ||
              scheme.benefits.toLowerCase().contains('loan');
        } else if (benefitLower == 'skill training') {
          matchesBenefit =
              scheme.benefits.toLowerCase().contains('training') ||
              scheme.benefits.toLowerCase().contains('skill') ||
              scheme.category.toLowerCase().contains('skill');
        } else if (benefitLower == 'infrastructure') {
          matchesBenefit =
              scheme.benefits.toLowerCase().contains('infrastructure') ||
              scheme.benefits.toLowerCase().contains('land') ||
              scheme.benefits.toLowerCase().contains('cluster');
        }
        if (!matchesBenefit) continue;
      }

      // 3. Dropdown Chips Filters: Ministry
      if (_selectedMinistry != 'All') {
        final ministryLower = _selectedMinistry.toLowerCase();
        final matchesMinistry = scheme.sponsoringBody
            .toLowerCase()
            .contains(ministryLower);
        if (!matchesMinistry) continue;
      }

      // 4. AppProvider Global Filters
      final globalFilters = provider.filters;
      if (globalFilters['schemeType'] != null &&
          globalFilters['schemeType'] != 'All') {
        if (globalFilters['schemeType'] == 'Central Government' &&
            scheme.state.toLowerCase() != 'all india' &&
            scheme.sponsoringBody.toLowerCase().contains('state')) {
          continue;
        }
        if (globalFilters['schemeType'] == 'State Government' &&
            scheme.state.toLowerCase() == 'all india') {
          continue;
        }
      }

      filtered.add(MapEntry(scheme, recResult));
    }

    // 5. Sorting
    if (_sortBy == 'Benefits: High to Low') {
      filtered.sort((a, b) => b.key.name.compareTo(a.key.name));
    } else if (_sortBy == 'Match %') {
      filtered.sort((a, b) => b.value.score.compareTo(a.value.score));
    } else if (_sortBy == 'Scheme Name (A-Z)') {
      filtered.sort((a, b) => a.key.name.compareTo(b.key.name));
    } else {
      // Relevance (Profile match score descending)
      filtered.sort((a, b) => b.value.score.compareTo(a.value.score));
    }

    return filtered;
  }

  Widget _buildDropdownChip(
    String label,
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    final bool isActive = currentValue != 'All' && currentValue != 'Relevance';
    return Container(
      margin: const EdgeInsets.only(right: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
              const SizedBox(width: 4),
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
    final isTa = provider.selectedLanguage == 'ta';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: SingleChildScrollView(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Dropdown Chips
            _buildDropdownChip(
              isTa ? 'வரிசைப்படுத்து' : 'Sort',
              [
                'Relevance',
                'Benefits: High to Low',
                'Match %',
                'Scheme Name (A-Z)',
              ],
              _sortBy,
              (v) => setState(() => _sortBy = v),
            ),
            _buildDropdownChip(
              isTa ? 'வகை' : 'Type',
              ['All', 'Loan', 'Subsidy', 'Scholarship', 'Pension'],
              _selectedType,
              (v) => setState(() => _selectedType = v),
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
              (v) => setState(() => _selectedBenefit = v),
            ),
            _buildDropdownChip(
              isTa ? 'அமைச்சகம்' : 'Ministry',
              ['All', 'MSME', 'Education', 'Finance', 'Agriculture'],
              _selectedMinistry,
              (v) => setState(() => _selectedMinistry = v),
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
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
        subtitle: isTa
            ? 'அனைத்து திட்ட முடிவுகளும்'
            : '${filteredSchemes.length} schemes available',
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            onPressed: () async {
              final shareText =
                  'Explore $displayedTitle on MSME Scheme Sahayak:\n'
                  '${filteredSchemes.take(5).map((e) => '• ${e.key.name}').join('\n')}';
              await Clipboard.setData(ClipboardData(text: shareText));
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  isTa
                      ? 'முடிவுகள் நகலெடுக்கப்பட்டது'
                      : 'Results copied to clipboard',
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // Search bar for refining results
            _buildSearchInput(),

            // Discover filter strip (Sort, Type, Benefit, Ministry, Filter)
            _buildFiltersStrip(provider),

            const SizedBox(height: 4),

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
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.l10n.noSchemesFound(
                                    _searchController.text.isNotEmpty
                                        ? _searchController.text
                                        : widget.title,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.l10n.tryDifferentKeyword,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                  label: Text(
                                    isTa
                                        ? 'வடிகட்டிகளை அழித்து திட்டங்களைக் காண்க'
                                        : 'Clear Filters & Explore Schemes',
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
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
          ],
        ),
      ),
    );
  }
}
