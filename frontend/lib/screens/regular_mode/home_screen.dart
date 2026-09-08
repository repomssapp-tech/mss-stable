import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../services/scheme_repository.dart';
import '../../services/centralized_translator.dart';
import '../../utils/responsive.dart';

import 'scheme_details_screen.dart';
import '../notifications_screen.dart';
import '../login_screen.dart';
import '../../widgets/smart_assessment_bottom_sheet.dart';
import 'search_results_screen.dart';
import 'basic_profile_screen.dart';
import 'msme_module_details_screen.dart';
import 'sarvam_chat_screen.dart';
import '../../utils/app_spacing.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onVoiceQuery,
    this.onFilterPressed,
    this.onSearchBarTap,
  });

  final ValueChanged<String>? onVoiceQuery;
  final VoidCallback? onFilterPressed;

  /// Called on a single tap of the search bar. The bar itself is not a real
  /// TextField (it can't be -- it lives on the Home tab, but typing needs to
  /// drive the Search tab's results/filters/voice-dictation machinery, all
  /// of which already lives in SearchScreen). So this switches to the
  /// Search tab and focuses its TextField in one motion, instead of the
  /// previous two-tap dance (tap once to reveal quick pills that did
  /// nothing useful, tap again to navigate) that never opened a keyboard.
  final VoidCallback? onSearchBarTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselPageController = PageController(
    viewportFraction: 0.88,
  );
  final ScrollController _recommendedScrollController = ScrollController();
  int _activeCarouselIndex = 0;
  Timer? _carouselTimer;
  bool _loggedOutRedirectScheduled = false;

  double _scaledFontSize(double baseSize) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta' ? baseSize * 0.88 : baseSize;
  }

  double _scaledLineHeight([double defaultHeight = 1.28]) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta'
        ? defaultHeight * 1.06
        : defaultHeight;
  }

  FontWeight _scaledFontWeight(FontWeight baseWeight) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedLanguage == 'ta') {
      if (baseWeight == FontWeight.bold || baseWeight == FontWeight.w700) {
        return FontWeight.w600;
      }
      if (baseWeight == FontWeight.w600) {
        return FontWeight.w500;
      }
    }
    return baseWeight;
  }

  String _getCarouselBadgeText(String raw) {
    if (raw == 'Alert') return context.l10n.carouselBadgeAlert;
    if (raw == 'New Scheme') return context.l10n.carouselBadgeNewScheme;
    if (raw == 'Notify') return context.l10n.carouselBadgeNotify;
    if (raw == 'Featured') return context.l10n.featured;
    return raw;
  }

  String _getCarouselTitle(String raw) {
    if (raw == 'Applications Closing Soon') {
      return context.l10n.carouselTitleApplicationsClosingSoon;
    }
    if (raw == 'New Scheme') return context.l10n.carouselTitleNewScheme;
    if (raw == 'Important Update') {
      return context.l10n.carouselTitleImportantUpdate;
    }
    if (raw == 'For Women Entrepreneurs') {
      return context.l10n.forWomenEntrepreneurs;
    }
    return raw;
  }

  String _getCarouselSubtitle(String raw) {
    if (raw == 'PMEGP · 2 days left') {
      return context.l10n.carouselSubPmegpDaysLeft;
    }
    if (raw == 'TN Export Promotion Scheme') {
      return context.l10n.carouselSubTnExport;
    }
    if (raw == 'UDYAM registration process updated') {
      return context.l10n.carouselSubUdyamProcess;
    }
    if (raw == 'Explore special funding schemes') {
      return context.l10n.exploreSpecialFundingSchemes;
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (!provider.isLoggedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      provider.fetchLatestProfile();
    });
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselPageController.hasClients) {
        final nextPage = (_activeCarouselIndex + 1) % itemCount;
        _carouselPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initCarouselTimer(int itemCount) {
    if (_carouselTimer != null) return;
    _startCarouselTimer(itemCount);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselPageController.dispose();
    _recommendedScrollController.dispose();
    super.dispose();
  }

  Future<void> _openChatbot() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SarvamChatScreen(
          profile: provider.profile,
          language: provider.selectedLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.isLoggedIn) {
      // Session was revoked (or refresh failed) while this screen was
      // already mounted -- initState()'s check only runs once, so without
      // this the user is stuck on a permanent spinner instead of being
      // routed back to login.
      if (!_loggedOutRedirectScheduled) {
        _loggedOutRedirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final recommendedScored = provider.recommendedSchemes
        .where((entry) => entry.value.score > 0)
        .toList();
    final recommended =
        (recommendedScored.isNotEmpty
                ? recommendedScored
                : provider.recommendedSchemes)
            .take(5)
            .map((entry) => entry.key)
            .toList();

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Slate 50 (Premium clean background)
      body: Stack(
        children: [
          // 1. Background image alignment (sky with building)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/Background/Home_screen_bg.webp',
                  width: MediaQuery.of(context).size.width,
                  height: 290,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                Container(
                  height: 290,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.65),
                        const Color(0xFFF8FAFC),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // Unified Header
                    _buildHeader(context, provider),

                    const SizedBox(height: AppSpacing.sm),

                    // Search Bar & Filter Button
                    _buildSearchAndFilter(context, provider),

                    const SizedBox(height: AppSpacing.sm),
                    // Quick search horizontal pills
                    _buildQuickPills(context, provider),

                    if (provider.profileCompletionPercentage < 100) ...[
                      const SizedBox(height: AppSpacing.xl),
                      // Profile Completion (Real & Compact)
                      _buildProfileCompleteCard(context, provider),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Carousel Cards (Alerts, New Scheme, AI Recommendation)
                    _buildCarouselSection(context),

                    const SizedBox(height: AppSpacing.xxl),

                    // Choose Your Journey (2x2 Grid)
                    _buildChooseYourJourney(context, provider),

                    const SizedBox(height: AppSpacing.xxl),

                    // Explore MSME Support (2x4 Grid)
                    _buildExploreMSMESupport(context),

                    const SizedBox(height: AppSpacing.xxl),

                    // Recommended For You (Horizontal List)
                    _buildRecommendedSection(context, recommended, provider),

                    const SizedBox(height: AppSpacing.xxl),

                    // Latest Updates Card
                    _buildLatestUpdates(context, provider),

                    const SizedBox(height: AppSpacing.xxl),

                    // Tip of the Day
                    _buildTipOfTheDay(context),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _buildChatButton(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(AppProvider provider) {
    return Semantics(
      button: true,
      label: context.l10n.openSaarthiAiChat,
      child: Material(
        color: const Color(0xFF2563EB),
        elevation: 5,
        shadowColor: const Color(0x552563EB),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: _openChatbot,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.askAi,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Unified Header Widget: Greeting on left, Notification/Avatar on right
  Widget _buildHeader(BuildContext context, AppProvider provider) {
    final displayName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ').first
        : context.l10n.commonUserFallback;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppConstants.getTimeGreeting(context.l10n),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text("👋", style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
            const SizedBox(height: AppSpacing.hairline),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: provider.isGuest ? 18.0 : 24.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!provider.isGuest) ...[
                  const SizedBox(width: AppSpacing.tight),
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                    if (provider.notifications.any((n) => n['read'] == false))
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Search & Filter Box
  Widget _buildSearchAndFilter(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSearchBarTap?.call(),
            child: const Icon(Icons.search, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onSearchBarTap?.call(),
              child: Text(
                context.l10n.searchPlaceholder,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              if (widget.onFilterPressed != null) {
                widget.onFilterPressed!();
              } else {
                provider.updateTabIndex(1);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.tight,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 14,
                    color: Color(0xFF1E293B),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.l10n.filter,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Horizontal Pills
  Widget _buildQuickPills(BuildContext context, AppProvider provider) {
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
        physics: const ClampingScrollPhysics(),
        itemCount: pills.length,
        itemBuilder: (context, index) {
          final text = pills[index];
          return GestureDetector(
            onTap: () {
              final query = text
                  .replaceAll("Search ", "")
                  .replaceAll("தேடுக", "")
                  .trim();
              if (widget.onVoiceQuery != null) {
                widget.onVoiceQuery!(query);
              } else {
                provider.updateSearchQuery(query);
                provider.updateTabIndex(1);
              }
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
                      color: const Color(0xFF475569),
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

  // Profile Completion Card (Mockup Style Redesign)
  Widget _buildProfileCompleteCard(BuildContext context, AppProvider provider) {
    final completion = provider.profileCompletionPercentage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BasicProfileScreen()));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage(
                'assets/images/Background/profile process banner.webp',
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Progress ring with percent text inside
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: completion / 100.0,
                      strokeWidth: 4.0,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(
                        0xFFEFF6FF,
                      ).withValues(alpha: 0.8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  Text(
                    "$completion%",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),

              // Vertical Divider Line
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.md),

              // Middle: Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.completeYourProfile,
                      style: GoogleFonts.poppins(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.unlockPersonalizedSchemeRecommendations,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Spacer to prevent text from overlapping the background banner image's built-in graphic
              const SizedBox(width: 84),
            ],
          ),
        ),
      ),
    );
  }

  // Promo Slider Carousel (Snapping PageView with dynamic Supabase integration)
  Widget _buildCarouselSection(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final items = provider.carouselItems;

    // Initialize timer on build once items are fetched
    if (items.isNotEmpty) {
      _initCarouselTimer(items.length);
    }

    return Column(
      children: [
        SizedBox(
          height: 154,
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (index) {
              setState(() {
                _activeCarouselIndex = index;
              });
              // Restart timer to avoid sliding immediately after manual swipe
              _startCarouselTimer(items.length);
            },
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final gradientColors = [
                _parseHexColor(item['bg_gradient_start'] ?? '#FFF7ED'),
                _parseHexColor(item['bg_gradient_end'] ?? '#FFFFEDD5'),
              ];

              // Always ensure a rich design banner background image is used
              String? bgImage = item['bg_image'] as String?;
              if (bgImage == null || bgImage.isEmpty) {
                final fallbackBanners = [
                  'assets/images/Background/alert banner.webp',
                  'assets/images/Background/new scheme banner.webp',
                  'assets/images/Background/notification banner.webp',
                  'assets/images/Background/suggestion banner.webp',
                ];
                bgImage = fallbackBanners[index % fallbackBanners.length];
              }

              // Since the 4 banner images have built-in illustrations on the right,
              // only render rightGraphic if it's a draft session progress or no bgImage
              Widget rightGraphic = const SizedBox();
              if (item['graphic_type'] == 'progress') {
                final double progress =
                    (item['progress'] as num?)?.toDouble() ?? 0.0;
                rightGraphic = _buildProgressGraphic(progress);
              }

              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.88,
                  child: _buildCarouselCard(
                    bgGradient: LinearGradient(colors: gradientColors),
                    borderColor: _parseHexColor(
                      item['badge_bg_color'] ?? '#E2E8F0',
                    ),
                    badgeText: _getCarouselBadgeText(item['badge_text'] ?? ''),
                    badgeTextColor: _parseHexColor(
                      item['badge_text_color'] ?? '#0F172A',
                    ),
                    badgeBgColor: _parseHexColor(
                      item['badge_bg_color'] ?? '#F1F5F9',
                    ),
                    title: _getCarouselTitle(item['title'] ?? ''),
                    subtitle: _getCarouselSubtitle(item['subtitle'] ?? ''),
                    titleColor: const Color(0xFF1E293B),
                    onTap: () {
                      _handleCarouselTap(context, item);
                    },
                    rightGraphic: rightGraphic,
                    bgImage: bgImage,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDotIndicator(
          items.length,
          _activeCarouselIndex,
          const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _handleCarouselTap(BuildContext context, Map<String, dynamic> item) {
    final route = item['target_route'] as String?;
    if (route == 'notifications') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    } else if (route == 'discover_results') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SearchResultsScreen(
            title: 'Business & MSME',
            type: 'category',
          ),
        ),
      );
    } else if (route == 'draft_session') {
      SmartAssessmentBottomSheet.show(
        context,
        'Business & MSME',
        'category',
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SearchResultsScreen(
                title: 'Business & MSME',
                type: 'category',
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildProgressGraphic(double progress) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard({
    required Gradient bgGradient,
    required Color borderColor,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required String title,
    String? subtitle,
    required Color titleColor,
    required VoidCallback onTap,
    required Widget rightGraphic,
    String? bgImage,
  }) {
    String displayTitle = title;
    String displaySubtitle = subtitle ?? '';
    if (displaySubtitle.isEmpty && title.contains(' — ')) {
      final parts = title.split(' — ');
      displayTitle = parts[0];
      displaySubtitle = parts[1];
    }

    final provider = Provider.of<AppProvider>(context);
    final isTa = provider.selectedLanguage == 'ta';
    final transTitle = isTa
        ? CentralizedTranslator.instance.translate(displayTitle)
        : displayTitle;
    final transSubtitle = isTa
        ? CentralizedTranslator.instance.translate(displaySubtitle)
        : displaySubtitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.tight,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: bgImage != null ? null : bgGradient,
            image: bgImage != null
                ? DecorationImage(image: AssetImage(bgImage), fit: BoxFit.cover)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bgImage != null ? Colors.transparent : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor.withValues(
                          alpha: bgImage != null ? 0.9 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isTa
                            ? CentralizedTranslator.instance.translateTag(
                                badgeText,
                              )
                            : badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      transTitle,
                      style: GoogleFonts.poppins(
                        fontSize: _scaledFontSize(13.5),
                        fontWeight: _scaledFontWeight(FontWeight.bold),
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transSubtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        transSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: _scaledFontSize(10.0),
                          color: const Color(0xFF475569),
                          fontWeight: _scaledFontWeight(FontWeight.w600),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (bgImage == null)
                rightGraphic
              else
                // Reserve spacer on the right so text doesn't overlap the background image's built-in icon
                const SizedBox(width: 85),
            ],
          ),
        ),
      ),
    );
  }

  // Choose Your Journey (What would you like to do today?)
  Widget _buildChooseYourJourney(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.whatWouldYouLikeToDoToday,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.exportSupport,
                icon: Icons.public_rounded,
                moduleId: 'export',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.growBusiness,
                icon: Icons.trending_up_rounded,
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.registerUdyam,
                icon: Icons.app_registration_rounded,
                moduleId: 'udyam',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.findFunding,
                icon: Icons.currency_rupee_rounded,
                categoryName: 'Business Loans & Credit',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.startABusiness,
                icon: Icons.rocket_launch_rounded,
                categoryName: 'Startup',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? moduleId,
    String? categoryName,
  }) {
    String formattedTitle = title;
    if (title.contains(' ')) {
      formattedTitle = title.replaceFirst(' ', '\n');
    }

    return GestureDetector(
      onTap: () async {
        // Route on the language-stable moduleId / categoryName, never the
        // localized `title` -- in Tamil a title like "உத்யம் பதிவு" contains
        // no "udyam"/"export" substring, so the old checks silently fell
        // through and every card returned the same generic fallback list.

        // 1. Register Udyam -> interactive Udyam Registration module
        if (moduleId == 'udyam') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MSMEModuleDetailsScreen(
                moduleId: 'udyam',
                title: 'Register UDYAM',
                description:
                    'Official MSME Registration Guide & Direct Portal Link',
                icon: Icons.app_registration_rounded,
                iconColor: Color(0xFF2563EB),
                themeColor: Color(0xFFEFF6FF),
              ),
            ),
          );
          return;
        }

        // 2. Export Support -> Export Readiness module
        if (moduleId == 'export') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MSMEModuleDetailsScreen(
                moduleId: 'export',
                title: 'Export Support',
                description: 'Global Trade Readiness & Export Incentives',
                icon: Icons.public_rounded,
                iconColor: Color(0xFF047857),
                themeColor: Color(0xFFECFDF5),
              ),
            ),
          );
          return;
        }

        final schemes = await SchemeRepository.instance.getSchemesByCategory(
          categoryName ?? title,
        );
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              title: title,
              type: 'category',
              initialSchemes: schemes,
            ),
          ),
        );
      },
      child: Container(
        width: 88,
        height: 112,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(height: AppSpacing.tight),
            Expanded(
              child: Center(
                child: Text(
                  formattedTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recommended For You section (horizontal lists)
  Widget _buildRecommendedSection(
    BuildContext context,
    List<Scheme> schemes,
    AppProvider provider,
  ) {
    final List<Map<String, dynamic>> items = [];

    if (schemes.isNotEmpty) {
      for (int i = 0; i < schemes.length; i++) {
        final sRaw = schemes[i];
        final s = sRaw.toLocalized(provider.selectedLanguage);
        final match = 95 - (i * 3);
        items.add({
          'id': sRaw.id,
          'title': s.name,
          'subtitle': s.overview.isNotEmpty ? s.overview : s.objectives,
          'match': context.l10n.matchPercentageFormat(match),
          'isBookmarked':
              provider.bookmarkedIds.contains(sRaw.id) ||
              provider.bookmarkedIds.contains(sRaw.schemeCode),
          'schemeCode': sRaw.schemeCode,
          'chips': s.glanceChips.take(3).toList(),
          'location': s.state.isNotEmpty ? s.state : 'All India',
          'scheme': sRaw,
        });
      }
    } else {
      items.addAll([
        {
          'id': 'pmegp_loan',
          'title': 'PMEGP Loan',
          'subtitle': "Prime Minister's Employment Generation Programme",
          'match': context.l10n.matchPercentageFormat(95),
          'isBookmarked': false,
          'schemeCode': 'PMEGP',
          'chips': ['Central Scheme', 'Loan', 'Subsidy'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'PMEGP',
          'logoColor': const Color(0xFF9A3412),
        },
        {
          'id': 'msme_loan',
          'title': 'MSME Loan',
          'subtitle': 'Credit Guarantee Fund Trust for MSEs',
          'match': context.l10n.matchPercentageFormat(92),
          'isBookmarked': true,
          'schemeCode': 'MSME',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'MSME',
          'logoColor': const Color(0xFF1E3A8A),
        },
        {
          'id': 'standup_india',
          'title': 'Stand Up India',
          'subtitle': 'Bank Loans for SC/ST & Women Entrepreneurs',
          'match': context.l10n.matchPercentageFormat(88),
          'isBookmarked': false,
          'schemeCode': 'SUI',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'UP India',
          'logoColor': const Color(0xFF15803D),
        },
        {
          'id': 'mudra_loan',
          'title': 'Mudra Loan',
          'subtitle': 'Loans up to ₹10 Lakhs Non-Corporate Business',
          'match': context.l10n.matchPercentageFormat(85),
          'isBookmarked': false,
          'schemeCode': 'Mudra',
          'chips': ['Central Scheme', 'Loan'],
          'location': 'All India',
          'scheme': null,
          'logoText': 'Mudra',
          'logoColor': const Color(0xFFB91C1C),
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.recommendedForYou,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 225,
          child: ListView.builder(
            controller: _recommendedScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final Scheme? schemeObj = item['scheme'] as Scheme?;
              final isBookmarked = item['isBookmarked'] as bool;
              final isTa = provider.selectedLanguage == 'ta';

              final double screenWidth = MediaQuery.of(context).size.width;
              final double spacing = 12.0;
              final double cardWidth = (screenWidth - 32 - spacing) / 1.08;

              final title = item['title'] as String;
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

              return GestureDetector(
                onTap: () {
                  if (schemeObj != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailsScreen(scheme: schemeObj),
                      ),
                    );
                  }
                },
                child: Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(
                    right: AppSpacing.md,
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match & Bookmark Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FitOneLine(
                              child: Text(
                                item['match'] as String,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF15803D),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.tight),
                          GestureDetector(
                            onTap: () {
                              final sCode = item['schemeCode'] as String;
                              provider.toggleBookmark(sCode);
                            },
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  shortForm,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (fullName.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    "($fullName)",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Chips Row
                      Builder(
                        builder: (context) {
                          final rawChipsList = List<String>.from(
                            item['chips'] as List<String>,
                          )..sort((a, b) => a.length.compareTo(b.length));
                          final chipsList = isTa
                              ? rawChipsList
                                    .map(
                                      (t) => CentralizedTranslator.instance
                                          .translateTag(t),
                                    )
                                    .toList()
                              : rawChipsList;
                          return Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: chipsList.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.tight,
                                  vertical: AppSpacing.hairline,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tip of the Day Card (Yellow theme with custom tip banner bg)
  Widget _buildTipOfTheDay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/Background/tip banner.webp'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Expanded(
                      child: Text(
                        context.l10n.tipOfTheDay,
                        style: GoogleFonts.poppins(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  context.l10n.tipOfTheDayContent,
                  style: GoogleFonts.inter(
                    fontSize: _scaledFontSize(10.0),
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: _scaledLineHeight(1.3),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Reserved right spacer to prevent text from overlapping the built-in image graphic
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  // Latest Updates Card
  Widget _buildLatestUpdates(BuildContext context, AppProvider provider) {
    final updates = provider.notifications;
    final latestUpdate = updates.isNotEmpty ? updates.first : null;

    final String tagText;
    if (latestUpdate != null) {
      final category = latestUpdate['category'] as String?;
      if (category == 'new_schemes') {
        tagText = context.l10n.tagNewScheme;
      } else if (category == 'updates') {
        tagText = context.l10n.tagUpdate;
      } else if (category == 'reminders') {
        tagText = context.l10n.tagReminder;
      } else {
        tagText = context.l10n.tagAlert;
      }
    } else {
      tagText = context.l10n.tagNewScheme;
    }

    final String titleText = latestUpdate != null
        ? (latestUpdate['title'] as String? ?? '')
        : context.l10n.fallbackLatestUpdateTitle;

    final String timeText;
    if (latestUpdate != null) {
      final count = latestUpdate['timeAgoCount'];
      final unit = latestUpdate['timeAgoUnit'];
      if (count is int && unit == 'd') {
        timeText = context.l10n.timeAgoDays(count);
      } else if (count is int && unit == 'h') {
        timeText = context.l10n.timeAgoHours(count);
      } else if (count is int && unit == 'm') {
        timeText = context.l10n.timeAgoMinutes(count);
      } else {
        timeText = context.l10n.timeAgoJustNow;
      }
    } else {
      timeText = context.l10n.time2DaysAgo;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.latestUpdates,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.hairline,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tagText,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.tight),
                      Text(
                        titleText,
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.tight),
                      Text(
                        timeText,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int count, int activeIndex, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 12 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.hairline),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? color : const Color(0xFFE2E8F0),
          ),
        );
      }),
    );
  }

  Widget _buildExploreMSMESupport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.exploreMsmeSupport,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 178,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.hairline),
            children: [
              _buildMSMESupportCard(
                context: context,
                id: 'schemes',
                title: context.l10n.schemes,
                subtitle: context.l10n.subsidiesGrantsGovtSchemes,
                icon: Icons.card_giftcard,
                iconColor: const Color(0xFF2E7D32),
                themeColor: Colors.green,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'finance',
                title: context.l10n.finance,
                subtitle: context.l10n.loansCreditSupportFundingOptions,
                icon: Icons.savings,
                iconColor: const Color(0xFF1565C0),
                themeColor: Colors.blue,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'tax_gst',
                title: context.l10n.taxGst,
                subtitle: context.l10n.taxBenefitsGstSupportCompliance,
                icon: Icons.percent,
                iconColor: const Color(0xFFEF6C00),
                themeColor: Colors.orange,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'export',
                title: context.l10n.export,
                subtitle: context.l10n.exportIncentivesFinanceMarketSupport,
                icon: Icons.language,
                iconColor: const Color(0xFF6A1B9A),
                themeColor: Colors.purple,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'treds',
                title: context.l10n.treds,
                subtitle: context.l10n.invoiceDiscountingWorkingCapital,
                icon: Icons.currency_exchange,
                iconColor: const Color(0xFFC62828),
                themeColor: Colors.red,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'csr',
                title: context.l10n.csrSupport,
                subtitle: context.l10n.csrProgramsIncubatorsClusterSupport,
                icon: Icons.handshake,
                iconColor: const Color(0xFF00695C),
                themeColor: Colors.teal,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'govt',
                title: context.l10n.govtAuthorities,
                subtitle: context.l10n.centralStateDistrictGovtStructure,
                icon: Icons.account_balance,
                iconColor: const Color(0xFF0277BD),
                themeColor: Colors.lightBlue,
              ),
              _buildMSMESupportCard(
                context: context,
                id: 'institutions',
                title: context.l10n.institutions,
                subtitle: context.l10n.sidbiNsicDicKvicMoreOrganizations,
                icon: Icons.business,
                iconColor: const Color(0xFF4527A0),
                themeColor: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMSMESupportCard({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color themeColor,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MSMEModuleDetailsScreen(
                  moduleId: id,
                  title: title,
                  description: subtitle,
                  icon: icon,
                  iconColor: iconColor,
                  themeColor: themeColor,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
