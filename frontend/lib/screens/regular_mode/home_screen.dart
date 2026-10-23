import 'package:flutter/material.dart';
import '../../widgets/onboarding/home_tour_targets.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import '../login_screen.dart';
import '../notifications_screen.dart';
import 'home/home_featured_section.dart';
import 'home/home_header_section.dart';
import 'home/home_journey_section.dart';
import 'home/home_msme_support_section.dart';
import 'home/home_profile_completion_card.dart';
import 'home/home_recommended_section.dart';
import 'home/home_updates_section.dart';
import 'sarvam_chat_screen.dart';
import '../../utils/app_text.dart';

export 'home/home_featured_section.dart';
export 'home/home_header_section.dart';
export 'home/home_journey_section.dart';
export 'home/home_msme_support_section.dart';
export 'home/home_profile_completion_card.dart';
export 'home/home_promo_carousel_section.dart';
export 'home/home_recommended_section.dart';
export 'home/home_updates_section.dart';

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
  bool _loggedOutRedirectScheduled = false;

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
                  // Source is 2160x1260; only ever painted at screen width.
                  cacheWidth:
                      (MediaQuery.of(context).size.width *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
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

                    // Unified Header (Greeting, Notification bell, Search bar & Quick pills)
                    HomeHeaderSection(
                      provider: provider,
                      onSearchBarTap: widget.onSearchBarTap,
                      onFilterPressed: widget.onFilterPressed,
                      onVoiceQuery: widget.onVoiceQuery,
                      onNotificationTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),

                    if (provider.profileCompletionPercentage < 100) ...[
                      const SizedBox(height: AppSpacing.xl),
                      // Profile Completion (Real & Compact)
                      HomeProfileCompletionCard(provider: provider),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Featured: best matches and newest schemes for the user,
                    // falling back to the promo cards.
                    const HomeFeaturedSection(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Choose Your Journey (Horizontal Action Cards)
                    const HomeJourneySection(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Explore MSME Support (Horizontal Cards)
                    const HomeMsmeSupportSection(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Recommended For You (Horizontal List)
                    HomeRecommendedSection(provider: provider),

                    const SizedBox(height: AppSpacing.xxl),

                    // Latest Updates & Tip of the Day
                    HomeUpdatesSection(provider: provider),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            // Above the floating nav bar: the shell's body padding includes
            // the bar's height.
            bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
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
        key: HomeTourTargets.askSaarthi,
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
                  style: AppGoogleFonts.inter(
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
}
