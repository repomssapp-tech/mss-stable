import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../services/scheme_repository.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import '../../services/centralized_translator.dart';
import '../../utils/responsive.dart';
import '../../utils/emblem_helper.dart';
import '../../widgets/app_toast.dart';
import '../../utils/app_spacing.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailsScreen({super.key, required this.scheme});

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

  // Fix 3: GlobalKeys for each scrollable section (for sticky tab auto-scroll)
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

  // Fix 4: Accordions closed by default
  bool _benefitsExpanded = false;
  bool _eligibilityExpanded = false;
  bool _documentsExpanded = false;
  bool _servicesExpanded = false;
  bool _processExpanded = false;

  // Enriched scheme loaded from the bundled catalog or repository fallback.
  Scheme? _detailedScheme;
  bool _detailsLoading = true;

  // toLocalized() allocates a full LocalizedScheme wrapper on every call.
  // build() runs on each bookmark toggle / tab tap / provider notify, so cache
  // the result and only rebuild it when the source scheme or language changes.
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
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await SchemeRepository.instance.getSchemeById(
        widget.scheme.id,
      );
      // Deferred: this async load runs on initState, right as the screen's
      // own entrance/route transition is animating, which can trip
      // Flutter's re-entrant-layout assertion if the setState lands
      // mid-layout. See search_screen.dart's _triggerSearch for the same
      // fix applied to the same underlying race.
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

  /// Single authoritative handler for a tab tap. The selected-tab state
  /// (`_activeTabIndex`) and the section's expanded flag are set FIRST in a
  /// bare setState -- nothing that can throw runs before the rebuild, so
  /// the tab always visibly responds. The imperative
  /// `ExpansionTileController.expand()` (which throws when its tile is not
  /// currently mounted) is deferred to a post-frame callback and guarded;
  /// if it is skipped, `initiallyExpanded` opens the tile when
  /// `_scrollToSection` brings it on screen and it builds.
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
        // Tile not attached yet (still off-screen): initiallyExpanded opens
        // it when it builds. Safe to ignore.
      }
    });
  }

  /// Fix 3: Scrolls to the section matching the tapped tab index.
  ///
  /// Called in the same setState that expands the section's ExpansionTile,
  /// which animates open over ~200ms. Measuring position one frame later
  /// (the previous behaviour) catches the tile mid-collapse: for a section
  /// near the bottom of the list (Services, Process) the still-collapsed
  /// header can already fit on screen, so ensureVisible sees nothing to
  /// scroll and does nothing -- then the tile finishes expanding with no
  /// scroll tracking it, leaving the revealed content below the fold.
  /// Waiting out the expand animation before measuring fixes that for every
  /// section, not just the ones far enough up the list to mask it.
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

      // `Scrollable.ensureVisible` is a no-op once any part of the target is
      // already on screen, so for the lower sections (Services, Process)
      // whose collapsed header was visible it did nothing -- the tab looked
      // dead. Compute the offset that puts the section's top just under the
      // 48px pinned tab bar and animate there explicitly, clamped to the
      // scroll range (the trailing spacer sliver gives the last sections
      // enough room to actually reach the top).
      final position = Scrollable.of(ctx).position;
      final reveal = RenderAbstractViewport.of(
        box,
      ).getOffsetToReveal(box, 0.0).offset;
      final target = (reveal - _StickyTabBarDelegate.kHeight - 12.0).clamp(
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

  String _applicationDestination(LocalizedScheme scheme) {
    // catalog.scheme.scheme_url is the sole, authoritative "Apply Now"
    // destination -- every scheme has one, so there is no fallback chain.
    final url = scheme.schemeUrl.trim();
    return _isSafeWebUrl(url) ? url : '';
  }

  bool _isSafeWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Future<void> _openOfficialUrl(String value) async {
    if (!_isSafeWebUrl(value)) {
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
    final destination = _applicationDestination(scheme);
    final shareText = destination.isEmpty
        ? scheme.name
        : '${scheme.name}\n$destination';
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    AppToast.showSuccess(context, 'Scheme details copied to clipboard');
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
          // Bottom Layer: CustomScrollView withSticky Tabs
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
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  title: Text(
                    context.l10n.schemeDetailsTitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Share scheme details',
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
                  child: _HeroSection(
                    scheme: scheme,
                    imagePath: _getImageForCategory(scheme.category),
                  ),
                ),

                // 3. Sticky Tab Bar Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
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
                                  style: GoogleFonts.inter(
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
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Overview Paragraph
                      Container(
                        key: _overviewKey,
                        child: Text(
                          scheme.overview,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12.0,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Why this matches you card
                      _buildSchemeHighlightsCard(scheme),
                      const SizedBox(height: AppSpacing.md),
                      _buildOfficialSourceCard(scheme),
                      const SizedBox(height: AppSpacing.xxl),

                      // Show a loading indicator while enriched details load
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

                      // The five sections are ALWAYS mounted -- even during
                      // the details-load window -- so a tab tap always has a
                      // live ExpansionTile to target and never silently
                      // fails. Each content builder shows its own empty
                      // state when its data is missing.
                      ...[
                        // Benefits Expandable Section
                        _ExpandableSection(
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
                          child: _buildBenefitsContent(scheme),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Eligibility Expandable Section
                        _ExpandableSection(
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
                          child: _buildEligibilityContent(scheme),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Required Documents Expandable Section
                        _ExpandableSection(
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
                          child: _buildDocumentsContent(scheme),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Required Services Expandable Section
                        _ExpandableSection(
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
                          child: _buildServicesContent(scheme.requiredServices),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Process Expandable Section
                        _ExpandableSection(
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
                          child: _buildProcessContent(
                            scheme.applicationProcess,
                          ),
                        ),
                        // Scroll slack so the tab bar's lower sections
                        // (Services / Process) can be brought to the top by
                        // _scrollToSection instead of clamping short.
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                        ),
                      ],
                    ]),
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
            child: _BottomActionBar(
              isBookmarked:
                  provider.bookmarkedIds.contains(widget.scheme.id) ||
                  provider.bookmarkedIds.contains(widget.scheme.schemeCode),
              onBookmarkToggle: () {
                provider.toggleBookmark(widget.scheme.id);
              },
              onApply: () => _openOfficialUrl(_applicationDestination(scheme)),
              applyEnabled: _applicationDestination(scheme).isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeHighlightsCard(LocalizedScheme scheme) {
    final matches = [
      scheme.governmentLevel.isNotEmpty ? scheme.governmentLevel : '',
      scheme.state,
      scheme.sector,
      scheme.targetBeneficiary,
    ].where((value) => value.isNotEmpty).toSet().toList();
    matches.sort((a, b) => a.length.compareTo(b.length));

    final maxPillWidth = MediaQuery.of(context).size.width - 56;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes,
                color: Color(0xFF2563EB),
                size: 16,
              ),
              const SizedBox(width: AppSpacing.tight),
              Flexible(
                child: Text(
                  context.l10n.schemeAtAGlance,
                  softWrap: true,
                  style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: matches.map((match) {
              return Container(
                constraints: BoxConstraints(maxWidth: maxPillWidth),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2563EB),
                      size: 11,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        match,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialSourceCard(LocalizedScheme scheme) {
    final sourceUrl = [
      scheme.sourceUrl,
      scheme.guidelinesUrl,
      scheme.officialWebsite,
    ].firstWhere(_isSafeWebUrl, orElse: () => '');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Color(0xFF047857)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheme.verificationStatus.isEmpty
                      ? context.l10n.officialInformation
                      : scheme.verificationStatus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.0,
                  ),
                ),
                if (scheme.lastUpdated.isNotEmpty)
                  Text(
                    context.l10n.lastUpdatedFormat(scheme.lastUpdated),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: sourceUrl.isEmpty
                ? null
                : () => _openOfficialUrl(sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: Text(context.l10n.sourceButton),
          ),
        ],
      ),
    );
  }

  String _formatFunding(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} crore';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} lakh';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildBenefitsContent(LocalizedScheme scheme) {
    final benefitCards = <Map<String, Object>>[
      if (scheme.subsidyPercentage != null)
        {
          "icon": Icons.percent_rounded,
          "color": const Color(0xFF047857),
          "bg": const Color(0xFFECFDF5),
          "title": context.l10n.benefitSubsidy,
          "desc": "${scheme.subsidyPercentage!.toStringAsFixed(0)}%",
        },
      if (scheme.subsidyAmount.isNotEmpty &&
          scheme.subsidyAmount.toLowerCase() != 'not specified')
        {
          "icon": Icons.payments_outlined,
          "color": const Color(0xFF1D4ED8),
          "bg": const Color(0xFFEFF6FF),
          "title": context.l10n.benefitAmount,
          "desc": scheme.subsidyAmount,
        },
      if (scheme.maxFunding != null)
        {
          "icon": Icons.account_balance_wallet_outlined,
          "color": const Color(0xFF6D28D9),
          "bg": const Color(0xFFF5F3FF),
          "title": context.l10n.benefitMaximum,
          "desc": _formatFunding(scheme.maxFunding!),
        },
      if (scheme.schemeType.isNotEmpty)
        {
          "icon": Icons.category_outlined,
          "color": const Color(0xFFEA580C),
          "bg": const Color(0xFFFFEDD5),
          "title": context.l10n.benefitSupport,
          "desc": scheme.schemeType,
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scheme.benefits.isEmpty
              ? CentralizedTranslator.instance.translate(
                  'Benefit details are available from the official source.',
                )
              : scheme.benefits,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
        if (benefitCards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final cardWidth = (screenWidth - 32 - 12) / 2;
              final cardHeight = cardWidth / 2;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: benefitCards.map((card) {
                    return Container(
                      width: cardWidth,
                      height: cardHeight,
                      margin: const EdgeInsets.only(
                        right: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: card["bg"] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            card["icon"] as IconData,
                            color: card["color"] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card["title"] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.hairline),
                                Text(
                                  card["desc"] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEligibilityContent(LocalizedScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...scheme.eligibilityCriteria.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.hairline),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2563EB),
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rule,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (scheme.verificationNotes.isNotEmpty) ...[
          const Divider(height: 20),
          Text(
            context.l10n.verificationNote,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            scheme.verificationNotes,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsContent(LocalizedScheme scheme) {
    final documents = scheme.documents.isNotEmpty
        ? scheme.documents
        : scheme.requiredDocuments
              .map((name) => SchemeDocument(name: name))
              .toList();
    if (documents.isEmpty) {
      return Text(
        context.l10n.noDocumentsPublished,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11.5,
          height: 1.4,
        ),
      );
    }

    return Column(
      children: documents.map((document) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF2563EB),
                    size: 17,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      document.name,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (document.mandatory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: document.isMandatory
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        document.isMandatory
                            ? context.l10n.badgeRequired
                            : document.mandatory,
                        style: GoogleFonts.inter(
                          color: document.isMandatory
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF475569),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (document.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  document.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
              if (document.issuingAuthority.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  context.l10n.issuedByFormat(document.issuingAuthority),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (document.estimatedCost.isNotEmpty &&
                  document.estimatedCost.toLowerCase() != 'not specified')
                Text(
                  context.l10n.estimatedCostFormat(document.estimatedCost),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 9.0,
                  ),
                ),
              (() {
                final docEntry = AppConstants.documentLinks.entries.firstWhere((
                  entry,
                ) {
                  final key = entry.key.toLowerCase();
                  final name = document.name.toLowerCase();
                  return name.contains(key) || key.contains(name);
                }, orElse: () => const MapEntry('', ''));

                final docLink = docEntry.value;
                if (docLink.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _openOfficialUrl(docLink),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.tight,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 13,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: AppSpacing.tight),
                                Flexible(
                                  child: FitOneLine(
                                    child: Text(
                                      '${context.l10n.getDocumentOnline} (Official Portal)',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF2563EB),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 12,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              })(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesContent(List<SchemeService> services) {
    if (services.isEmpty) {
      return Text(
        context.l10n.noServicesRequiredMsg,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11.0,
        ),
      );
    }

    return Column(
      children: services.map((service) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFCCFBF1),
            child: Icon(
              Icons.support_agent_outlined,
              color: Color(0xFF0F766E),
              size: 18,
            ),
          ),
          title: Text(
            service.name,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            [
              service.category,
              service.description,
            ].where((value) => value.isNotEmpty).join(' • '),
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.0,
              height: 1.35,
            ),
          ),
          trailing: service.mandatory
              ? const Icon(Icons.check_circle, color: Color(0xFF0F766E))
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildProcessContent(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final bool isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: adaptiveSize(context, base: 24, min: 20, max: 24),
                  height: adaptiveSize(context, base: 24, min: 20, max: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FitOneLine(
                    child: Text(
                      "${index + 1}",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2563EB),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: const Color(0xFFDBEAFE),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index],
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    context.l10n.processStepSubtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 9.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// 2. Extracted Hero Section Widget
class _HeroSection extends StatelessWidget {
  final LocalizedScheme scheme;
  final String imagePath;

  const _HeroSection({required this.scheme, required this.imagePath});

  Widget _buildSchemeLogo(
    BuildContext context,
    LocalizedScheme scheme, {
    double size = 48,
  }) {
    final emblemAsset = EmblemHelper.getEmblemAsset(
      governmentLevel: scheme.governmentLevel,
      state: scheme.state,
      schemeCode: scheme.schemeCode,
      sponsoringBody: scheme.sponsoringBody,
      name: scheme.name,
    );

    // Emblem WebPs are ~900-1024px square; cap the decode to the physical
    // pixels shown (size dp x devicePixelRatio) instead of full resolution.
    final int decodePx = (size * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Image.asset(
      emblemAsset,
      fit: BoxFit.contain,
      width: size,
      height: size,
      cacheWidth: decodePx,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/States assets/Indian emblem.webp',
          fit: BoxFit.contain,
          width: size,
          height: size,
          cacheWidth: decodePx,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = scheme.name;
    final regex = RegExp(r'\(([^)]+)\)');
    final matchObj = regex.firstMatch(title);
    String shortForm = title;
    String fullName = '';

    final bracketText = matchObj?.group(1)?.trim() ?? '';
    if (bracketText.isNotEmpty) {
      final outsideText = title
          .replaceAll(regex, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final isBracketAcronym =
          bracketText.length <= 10 &&
          !bracketText.contains(' ') &&
          bracketText == bracketText.toUpperCase();
      if (isBracketAcronym) {
        shortForm = bracketText;
        fullName = outsideText;
      } else if (bracketText.length > outsideText.length) {
        shortForm = outsideText;
        fullName = bracketText;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image (Emblem Container)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  child: ClipOval(
                    child: _buildSchemeLogo(context, scheme, size: 120),
                  ),
                ),
              ),
            ),

            // Right Content Block
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.tight,
                            vertical: AppSpacing.hairline,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.levelSchemeFormat(
                              scheme.governmentLevel.isNotEmpty
                                  ? scheme.governmentLevel
                                  : 'Central',
                            ),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2563EB),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          shortForm,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fullName.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.hairline),
                          Text(
                            "($fullName)",
                            style: GoogleFonts.inter(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          scheme.sponsoringBody,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),

                    // Sponsoring theme tags
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (scheme.schemeType.isNotEmpty)
                          _buildMiniTag(
                            scheme.schemeType,
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                        if (scheme.sector.isNotEmpty)
                          _buildMiniTag(
                            scheme.sector,
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                          ),
                        if (scheme.schemeType.isEmpty &&
                            scheme.sector.isEmpty) ...[
                          _buildMiniTag(
                            "Loan",
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                          _buildMiniTag(
                            "Subsidy",
                            const Color(0xFFECFDF5),
                            const Color(0xFF047857),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),

                    // Match Banner (Single-row layout)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF2563EB),
                            size: 12,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 10),
                                children: [
                                  TextSpan(
                                    text: context.l10n.matchPercentageFormat(
                                      96,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  TextSpan(
                                    text: " • ${context.l10n.highlyRelevant}",
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tight,
        vertical: AppSpacing.hairline,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: text,
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 3. Custom SliverPersistentHeaderDelegate for Sticky Tab Bar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  static const double kHeight = 48.0;

  const _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => kHeight;

  @override
  double get maxExtent => kHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, height: kHeight, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

// 4. Reusable ExpandableSection Widget
class _ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isExpanded;
  // ignore: deprecated_member_use
  final ExpansionTileController controller;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isExpanded,
    required this.controller,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      // The ExpansionTile header is a ListTile; without a Material between it
      // and this coloured Container it asserts "background may be invisible"
      // once the section is mounted during loading. A transparency Material
      // gives it a compositing surface without changing appearance.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: controller,
            initiallyExpanded: isExpanded,
            onExpansionChanged: (_) => onToggle(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.hairline,
            ),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 16),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF2563EB),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  top: AppSpacing.xs,
                ),
                // The section's own opaque white Container above sits between
                // any ListTile in `child` (services/documents content) and the
                // nearest real Material ancestor, which trips Flutter's
                // ListTile._debugCheckBackgroundIsHidden assertion. A
                // transparency-type Material gives those tiles a proper
                // compositing surface without changing appearance.
                child: Material(type: MaterialType.transparency, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. Extracted Bottom Action Bar Widget
class _BottomActionBar extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onApply;
  final bool applyEnabled;

  const _BottomActionBar({
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onApply,
    required this.applyEnabled,
  });

  @override
  Widget build(BuildContext context) {
    // Tamil button labels are ~2x longer than English; size the text for the
    // active language (with a readable floor) instead of letting a FittedBox
    // shrink it to nothing.
    final bool isTamil = Localizations.localeOf(context).languageCode == 'ta';
    final double labelSize = isTamil ? 11.5 : 14.0;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Save Scheme Button — Fix 2: FittedBox prevents overflow
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: onBookmarkToggle,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: const Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        isBookmarked
                            ? context.l10n.savedSchemeButton
                            : context.l10n.saveSchemeButton,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: labelSize,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Apply Now Button — Fix 2: FittedBox prevents overflow
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: applyEnabled ? onApply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.applyNowButton,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: labelSize,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
