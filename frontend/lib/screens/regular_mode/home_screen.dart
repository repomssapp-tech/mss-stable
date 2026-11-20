import 'package:flutter/material.dart';
import '../../widgets/onboarding/home_tour_targets.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_elevation.dart';
import '../../utils/app_size.dart';
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
import '../../design_v2/saarthi/saarthi_voice_screen.dart';
import '../../utils/app_text.dart';
import '../../widgets/common/sign_in_required_sheet.dart';

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
      // A guest browses home without an account and has no server profile.
      if (provider.isGuest) return;
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

  /// Opens Saarthi on its own home: the greeting, the mic and the keyboard.
  Future<void> _openChatbot() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SaarthiVoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.isLoggedIn && !provider.isGuest) {
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

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // The header art scrolls with the page, so it never shows through
          // the sections below it.
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _HeaderArt(height: _headerArtHeight + topInset),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: topInset,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                  ),
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
                        onNotificationTap: () async {
                          if (!await requireAccount(context)) return;
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),

                      // A guest always sees it, at 0%, as the way to sign in.
                      if (provider.isGuest ||
                          provider.profileCompletionPercentage < 100) ...[
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

                      // Clears the Ask Saarthi button above the nav bar.
                      const SizedBox(
                        height: AppSize.tapTarget + AppSpacing.xxxl * 2,
                      ),
                    ],
                  ),
                ),
              ],
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
      excludeSemantics: true,
      child: DecoratedBox(
        key: HomeTourTargets.askSaarthi,
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          shadows: AppShadows.raised,
        ),
        child: Material(
          color: AppColors.primary,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openChatbot,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.textOnPrimary,
                      size: AppSize.icon,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.homeAskSaarthi,
                      style: context.text.button.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How tall the header art is below the status bar.
const double _headerArtHeight = 290;

/// The sky-and-government-building art behind the header, fading into the
/// page colour at its foot.
class _HeaderArt extends StatelessWidget {
  const _HeaderArt({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/Background/Home_screen_bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              // Source is 2160x1260; only ever painted at screen width.
              cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withValues(alpha: 0.05),
                    AppColors.background.withValues(alpha: 0.65),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
