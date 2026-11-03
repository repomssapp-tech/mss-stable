import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/l10n.dart';
import '../../models/localized_scheme.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../utils/app_spacing.dart';
import '../../utils/share_text.dart';
import '../../widgets/common/app_toast.dart';
import 'scheme_details/scheme_action_target.dart';
import 'scheme_details/scheme_benefits_section.dart';
import 'scheme_details/scheme_bottom_action_bar.dart';
import 'scheme_details/scheme_documents_section.dart';
import 'scheme_details/scheme_eligibility_section.dart';
import 'scheme_details/scheme_expandable_section.dart';
import 'scheme_details/scheme_extra_sections.dart';
import 'scheme_details/scheme_hero_section.dart';
import 'scheme_details/scheme_highlights_card.dart';
import 'scheme_details/scheme_process_section.dart';
import 'scheme_details/scheme_services_section.dart';
import 'scheme_details/sticky_tab_bar_delegate.dart';
import '../../utils/app_text.dart';
import '../../widgets/common/auto_translated_text.dart';

// Re-exports for clean modular access and backwards compatibility
export 'scheme_details/scheme_benefits_section.dart';
export 'scheme_details/scheme_bottom_action_bar.dart';
export 'scheme_details/scheme_documents_section.dart';
export 'scheme_details/scheme_eligibility_section.dart';
export 'scheme_details/scheme_expandable_section.dart';
export 'scheme_details/scheme_hero_section.dart';
export 'scheme_details/scheme_highlights_card.dart';
export 'scheme_details/scheme_process_section.dart';
export 'scheme_details/scheme_services_section.dart';
export 'scheme_details/sticky_tab_bar_delegate.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final Scheme scheme;

  /// Real match % from the results list (null = don't show a score).
  final int? matchPercentage;

  /// Eligibility engine marked the scheme "not applicable" for this user.
  final bool notApplicable;

  const SchemeDetailsScreen({
    super.key,
    required this.scheme,
    this.matchPercentage,
    this.notApplicable = false,
  });

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> {
  int _activeTabIndex = 0;

  List<String> _getTabs(BuildContext context) {
    return [
      context.l10n.tabOverview,
      context.l10n.tabBenefits,
      context.l10n.tabEligibility,
      context.l10n.tabDocuments,
      context.l10n.tabServices,
      context.l10n.tabProcess,
    ];
  }

  // GlobalKeys for each scrollable section (for sticky tab auto-scroll)
  final _overviewKey = GlobalKey();
  final _benefitsKey = GlobalKey();
  final _eligibilityKey = GlobalKey();
  final _documentsKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _processKey = GlobalKey();

  // ExpansionTileControllers to programmatically expand the accordions
  // ignore: deprecated_member_use
  final _benefitsController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _eligibilityController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _documentsController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _servicesController = ExpansionTileController();
  // ignore: deprecated_member_use
  final _processController = ExpansionTileController();

  // Accordions closed by default
  bool _benefitsExpanded = false;
  bool _eligibilityExpanded = false;
  bool _documentsExpanded = false;
  bool _servicesExpanded = false;
  bool _processExpanded = false;

  // Enriched scheme loaded from the bundled catalog or repository fallback.
  Scheme? _detailedScheme;
  bool _detailsLoading = true;

  LocalizedScheme? _localizedCache;
  Scheme? _localizedCacheSource;
  String? _localizedCacheLang;

  LocalizedScheme _localized(Scheme raw, String lang) {
    if (identical(_localizedCacheSource, raw) && _localizedCacheLang == lang) {
      return _localizedCache!;
    }
    final localized = raw.toLocalized(lang);
    _localizedCache = localized;
    _localizedCacheSource = raw;
    _localizedCacheLang = lang;
    return localized;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
    // Record every opened scheme, whichever screen it was opened from
    // (Recently viewed used to stay empty outside the eligibility results).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).addToRecentlyViewed(widget.scheme.id);
    });
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await SchemeRepository.instance.getSchemeById(
        widget.scheme.id,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _detailedScheme = detail ?? widget.scheme;
          _detailsLoading = false;
        });
      });
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _detailsLoading = false);
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _activeTabIndex = index;
      switch (index) {
        case 1:
          _benefitsExpanded = true;
          break;
        case 2:
          _eligibilityExpanded = true;
          break;
        case 3:
          _documentsExpanded = true;
          break;
        case 4:
          _servicesExpanded = true;
          break;
        case 5:
          _processExpanded = true;
          break;
      }
    });
    _expandSectionForTab(index);
    _scrollToSection(index);
  }

  void _expandSectionForTab(int index) {
    // ignore: deprecated_member_use
    final ExpansionTileController? controller = switch (index) {
      1 => _benefitsController,
      2 => _eligibilityController,
      3 => _documentsController,
      4 => _servicesController,
      5 => _processController,
      _ => null,
    };
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (!controller.isExpanded) controller.expand();
      } catch (_) {
        // Tile not attached yet: initiallyExpanded handles it when mounted.
      }
    });
  }

  void _scrollToSection(int index) {
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final keys = [
        _overviewKey,
        _benefitsKey,
        _eligibilityKey,
        _documentsKey,
        _servicesKey,
        _processKey,
      ];
      final ctx = keys[index].currentContext;
      if (ctx == null || !ctx.mounted) return;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) return;

      final position = Scrollable.of(ctx).position;
      final reveal = RenderAbstractViewport.of(
        box,
      ).getOffsetToReveal(box, 0.0).offset;
      final target = (reveal - StickyTabBarDelegate.kHeight - 12.0).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      position.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    });
  }

  SchemeActionTarget _actionTarget(LocalizedScheme scheme) =>
      resolveSchemeAction(
        applicationUrl: scheme.applicationUrl,
        schemeUrl: scheme.schemeUrl,
        officialWebsite: scheme.officialWebsite,
        applicationStatus: scheme.rawScheme.extras.applicationStatus,
      );

  Future<void> _openOfficialUrl(String value) async {
    if (!isSafeWebUrl(value)) {
      if (!mounted) return;
      AppToast.showInfo(context, context.l10n.noVerifiedLink);
      return;
    }

    final opened = await launchUrl(
      Uri.parse(value),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      AppToast.showWarning(context, context.l10n.couldNotOpenWebsite);
    }
  }

  Future<void> _copySchemeDetails(LocalizedScheme scheme) async {
    final destination = _actionTarget(scheme).url;
    final text = destination.isEmpty
        ? scheme.name
        : '${scheme.name}\n$destination';
    await shareText(
      context,
      text,
      copiedMessage: context.l10n.schemeCopiedToast,
    );
  }

  String _getImageForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("farmer") || cat.contains("agriculture")) {
      return 'assets/images/Background/new scheme banner.webp';
    } else if (cat.contains("student") || cat.contains("education")) {
      return 'assets/images/Background/suggestion banner.webp';
    } else {
      return 'assets/images/Background/profile process banner.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawScheme = _detailedScheme ?? widget.scheme;
    final provider = Provider.of<AppProvider>(context);
    final LocalizedScheme scheme = _localized(
      rawScheme,
      provider.selectedLanguage,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // 1. Custom App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    tooltip: context.l10n.back,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  title: Text(
                    context.l10n.schemeDetailsTitle,
                    style: AppGoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: context.l10n.shareSchemeDetailsTooltip,
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                      onPressed: () => _copySchemeDetails(scheme),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),

                // 2. Hero Section
                SliverToBoxAdapter(
                  child: SchemeHeroSection(
                    scheme: scheme,
                    imagePath: _getImageForCategory(scheme.category),
                    matchPercentage: widget.matchPercentage,
                    notApplicable: widget.notApplicable,
                  ),
                ),

                // 3. Sticky Tab Bar Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyTabBarDelegate(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          children: List.generate(_getTabs(context).length, (
                            index,
                          ) {
                            final bool isSelected = _activeTabIndex == index;
                            return GestureDetector(
                              onTap: () => _onTabTapped(index),
                              child: Container(
                                margin: const EdgeInsets.only(
                                  right: AppSpacing.xxl,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _getTabs(context)[index],
                                  style: AppGoogleFonts.inter(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Scrollable Content Body
                SliverPadding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom: 120,
                  ),
                  // Keep section anchors mounted so any tab can reveal its target.
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Overview Paragraph
                        Container(
                          key: _overviewKey,
                          child: AutoTranslatedText(
                            scheme.overview,
                            language: Localizations.localeOf(
                              context,
                            ).languageCode,
                            style: AppGoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 12.0,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Highlights and official source cards
                        SchemeHighlightsCard(scheme: scheme),
                        const SizedBox(height: AppSpacing.md),
                        SchemeOfficialSourceCard(
                          scheme: scheme,
                          onOpenUrl: _openOfficialUrl,
                          isSafeWebUrl: isSafeWebUrl,
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        if (_detailsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xxl,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),

                        // Expandable Sections
                        SchemeExpandableSection(
                          key: _benefitsKey,
                          controller: _benefitsController,
                          title: context.l10n.benefitsDetails,
                          icon: Icons.card_giftcard_outlined,
                          iconColor: const Color(0xFF047857),
                          iconBg: const Color(0xFFECFDF5),
                          isExpanded: _benefitsExpanded,
                          onToggle: () {
                            setState(() {
                              _benefitsExpanded = !_benefitsExpanded;
                            });
                          },
                          child: SchemeBenefitsContent(scheme: scheme),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        SchemeExpandableSection(
                          key: _eligibilityKey,
                          controller: _eligibilityController,
                          title: context.l10n.eligibilityCriteria,
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xFF1D4ED8),
                          iconBg: const Color(0xFFEFF6FF),
                          isExpanded: _eligibilityExpanded,
                          onToggle: () {
                            setState(() {
                              _eligibilityExpanded = !_eligibilityExpanded;
                            });
                          },
                          child: SchemeEligibilityContent(scheme: scheme),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        SchemeExpandableSection(
                          key: _documentsKey,
                          controller: _documentsController,
                          title: context.l10n.requiredDocuments,
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF6D28D9),
                          iconBg: const Color(0xFFF5F3FF),
                          isExpanded: _documentsExpanded,
                          onToggle: () {
                            setState(() {
                              _documentsExpanded = !_documentsExpanded;
                            });
                          },
                          child: SchemeDocumentsContent(
                            scheme: scheme,
                            onOpenUrl: _openOfficialUrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        SchemeExpandableSection(
                          key: _servicesKey,
                          controller: _servicesController,
                          title: context.l10n.requiredServices,
                          icon: Icons.support_agent_outlined,
                          iconColor: const Color(0xFF0F766E),
                          iconBg: const Color(0xFFCCFBF1),
                          isExpanded: _servicesExpanded,
                          onToggle: () {
                            setState(() {
                              _servicesExpanded = !_servicesExpanded;
                            });
                          },
                          child: SchemeServicesContent(
                            services: scheme.requiredServices,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        SchemeExpandableSection(
                          key: _processKey,
                          controller: _processController,
                          title: context.l10n.applicationProcessHeader,
                          icon: Icons.account_tree_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFEDD5),
                          isExpanded: _processExpanded,
                          onToggle: () {
                            setState(() {
                              _processExpanded = !_processExpanded;
                            });
                          },
                          child: SchemeProcessContent(
                            steps: scheme.applicationProcess,
                            showUnconfirmedNotice:
                                rawScheme.extras.hasUnconfirmedDetails,
                            officialUrl: rawScheme.extras.hasWrongLink
                                ? ''
                                : _actionTarget(scheme).url,
                            onOpenUrl: _openOfficialUrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SchemeExtraSections(
                          scheme: rawScheme,
                          lang: provider.selectedLanguage,
                          onOpenUrl: _openOfficialUrl,
                          resolveScheme: (id) {
                            for (final s in provider.allSchemes) {
                              if (s.id == id) return s;
                            }
                            return null;
                          },
                          onOpenScheme: (s) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SchemeDetailsScreen(scheme: s),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Layer: Fixed Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SchemeBottomActionBar(
              isBookmarked:
                  provider.bookmarkedIds.contains(widget.scheme.id) ||
                  provider.bookmarkedIds.contains(widget.scheme.schemeCode),
              onBookmarkToggle: () {
                provider.toggleBookmark(widget.scheme.id);
              },
              onApply: () => _openOfficialUrl(_actionTarget(scheme).url),
              applyEnabled: _actionTarget(scheme).isEnabled,
              isDirectApply:
                  _actionTarget(scheme).kind == SchemeActionKind.apply,
            ),
          ),
        ],
      ),
    );
  }
}
