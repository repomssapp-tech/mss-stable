import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/analytics/app_analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/localized_scheme.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/share_text.dart';
import '../../widgets/common/app_icon_button.dart';
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
import '../../widgets/common/sign_in_required_sheet.dart';

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
  final String analyticsEntryPoint;
  final String? analyticsInteractionId;
  final int? analyticsRank;
  final String? analyticsFit;
  final Scheme scheme;

  /// Real match % from the results list (null = don't show a score).
  final int? matchPercentage;

  /// Eligibility engine marked the scheme "not applicable" for this user.
  final bool notApplicable;

  const SchemeDetailsScreen({
    super.key,
    required this.scheme,
    this.matchPercentage,
    this.analyticsEntryPoint = 'other',
    this.analyticsInteractionId,
    this.analyticsRank,
    this.analyticsFit,
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

  // Benefits starts open: what a scheme gives is the first question.
  bool _benefitsExpanded = true;
  bool _eligibilityExpanded = false;
  bool _documentsExpanded = false;
  bool _servicesExpanded = false;
  bool _processExpanded = false;

  // Enriched scheme loaded from the bundled catalog or repository fallback.
  Scheme? _detailedScheme;
  bool _detailsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    AppAnalytics.instance.track(
      AnalyticsEvent.schemeOpened,
      interactionId: widget.analyticsInteractionId,
      properties: {
        'scheme_id': widget.scheme.id,
        'entry_point': widget.analyticsEntryPoint,
        'rank': ?widget.analyticsRank,
        'fit': ?widget.analyticsFit,
      },
    );
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

  Future<void> _openOfficialUrl(String value, {bool isApply = false}) async {
    if (!isSafeWebUrl(value)) {
      if (!mounted) return;
      AppToast.showInfo(context, context.l10n.noVerifiedLink);
      return;
    }

    final opened = await launchUrl(
      Uri.parse(value),
      mode: LaunchMode.externalApplication,
    );
    if (opened) {
      AppAnalytics.instance.track(
        AnalyticsEvent.schemeAction,
        interactionId: widget.analyticsInteractionId,
        properties: {
          'scheme_id': widget.scheme.id,
          'action': isApply ? 'apply_link_opened' : 'info_link_opened',
        },
      );
    }
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
    final scheme = rawScheme.toLocalized(provider.selectedLanguage);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // 1. Custom App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  titleSpacing: 0,
                  leading: AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: context.l10n.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  title: Text(
                    context.l10n.schemeDetailsTitle,
                    style: context.text.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: context.l10n.shareSchemeDetailsTooltip,
                      icon: const Icon(
                        Icons.share_outlined,
                        color: AppColors.textPrimary,
                        size: AppSize.iconLg,
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
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border,
                            width: AppSize.borderWidth,
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
                            // The InkWell's own GestureDetector carries onTap.
                            return InkWell(
                              onTap: () => _onTabTapped(index),
                              child: Container(
                                margin: const EdgeInsets.only(
                                  right: AppSpacing.lg,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: AppSize.borderWidth * 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _getTabs(context)[index],
                                  style: context.text.button.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
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
                    bottom: AppSpacing.xxxl,
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
                            style: context.text.bodyLarge.copyWith(
                              color: AppColors.textBody,
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
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                        // Expandable Sections
                        SchemeExpandableSection(
                          key: _benefitsKey,
                          controller: _benefitsController,
                          title: context.l10n.benefitsDetails,
                          icon: Icons.redeem_outlined,
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
                          icon: Icons.how_to_reg_outlined,
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
              onBookmarkToggle: () async {
                if (!await requireAccount(
                  context,
                  feature: SignInFeature.save,
                )) {
                  return;
                }
                provider.toggleBookmark(widget.scheme.id);
              },
              onApply: () => _openOfficialUrl(
                _actionTarget(scheme).url,
                isApply: _actionTarget(scheme).kind == SchemeActionKind.apply,
              ),
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
