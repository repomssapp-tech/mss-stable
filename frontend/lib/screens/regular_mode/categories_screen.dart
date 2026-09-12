import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/assistant/smart_assessment_bottom_sheet.dart';
import 'categories/categories_business_utilities_section.dart';
import 'categories/categories_section_lists.dart';
import 'categories/categories_view_all_sheets.dart';
import 'categories/discover_counts.dart';
import 'search_results_screen.dart';

// Re-exports for backwards compatibility across tests and consumers
export 'categories/categories_business_utilities_section.dart';
export 'categories/categories_data.dart';
export 'categories/categories_section_lists.dart';
export 'categories/categories_view_all_sheets.dart';
export 'categories/discover_counts.dart';
export 'categories/state_map_painter.dart';

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

  void _onCategorySelected(String categoryName, AppProvider provider) {
    final count = _dynamicCategoryCounts[categoryName];
    if (count == 0) {
      showComingSoonInfo(context, categoryName, 'category');
      return;
    }

    SmartAssessmentBottomSheet.show(
      context,
      categoryName,
      'category',
      () async {
        final all = await SchemeRepository.instance.getAllSchemes();
        final schemes = DiscoverCounts.schemesFor(categoryName, 'category', all);
        if (!mounted) return;
        if (schemes.isEmpty) {
          showComingSoonInfo(context, categoryName, 'category');
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
      showComingSoonInfo(context, ministryName, 'ministry');
      return;
    }

    SmartAssessmentBottomSheet.show(
      context,
      ministryName,
      'ministry',
      () async {
        final all = await SchemeRepository.instance.getAllSchemes();
        final schemes = DiscoverCounts.schemesFor(ministryName, 'ministry', all);
        if (!mounted) return;
        if (schemes.isEmpty) {
          showComingSoonInfo(context, ministryName, 'ministry');
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
      showComingSoonInfo(context, stateName, 'state');
      return;
    }

    SmartAssessmentBottomSheet.show(context, stateName, 'state', () async {
      final all = await SchemeRepository.instance.getAllSchemes();
      final schemes = DiscoverCounts.schemesFor(stateName, 'state', all);
      if (!mounted) return;
      if (schemes.isEmpty) {
        showComingSoonInfo(context, stateName, 'state');
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header (Discover, AI collections)
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
                    CategoriesSectionHeader(
                      key: _categorySectionKey,
                      title: context.l10n.browseByCategories,
                      onViewAll: () => showAllCategoriesBottomSheet(
                        context: context,
                        provider: provider,
                        dynamicCategoryCounts: _dynamicCategoryCounts,
                        onCategorySelected: (category) =>
                            _onCategorySelected(category, provider),
                      ),
                    ),
                    CategoryHorizontalList(
                      provider: provider,
                      dynamicCategoryCounts: _dynamicCategoryCounts,
                      onCategorySelected: (category) =>
                          _onCategorySelected(category, provider),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: By Ministry
                    CategoriesSectionHeader(
                      key: _ministrySectionKey,
                      title: context.l10n.browseByMinistry,
                      onViewAll: () => showAllMinistriesBottomSheet(
                        context: context,
                        provider: provider,
                        dynamicCategoryCounts: _dynamicCategoryCounts,
                        onMinistrySelected: (ministry) =>
                            _onMinistrySelected(ministry, provider),
                      ),
                    ),
                    MinistryHorizontalList(
                      provider: provider,
                      dynamicCategoryCounts: _dynamicCategoryCounts,
                      onMinistrySelected: (ministry) =>
                          _onMinistrySelected(ministry, provider),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: By State
                    CategoriesSectionHeader(
                      key: _stateSectionKey,
                      title: context.l10n.browseByState,
                      onViewAll: () => showAllStatesBottomSheet(
                        context: context,
                        provider: provider,
                        dynamicCategoryCounts: _dynamicCategoryCounts,
                        onStateSelected: (state) =>
                            _onStateSelected(state, provider),
                      ),
                    ),
                    StateHorizontalList(
                      provider: provider,
                      dynamicCategoryCounts: _dynamicCategoryCounts,
                      onStateSelected: (state) =>
                          _onStateSelected(state, provider),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const CategoriesBusinessUtilitiesSection(),
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
}
