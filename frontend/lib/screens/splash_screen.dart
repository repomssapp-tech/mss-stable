import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'regular_mode/language_selection_screen.dart';
import 'login_screen.dart';
import 'navigation_mode_screen.dart';
import '../l10n/l10n.dart';
import '../providers/app_state_provider.dart';
import '../services/account/app_session.dart';
import '../services/account/auth_service.dart';
import '../services/account/rest_auth_service.dart';
import '../services/account/session_cache_service.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import '../utils/app_radius.dart';
import '../utils/app_size.dart';
import '../utils/app_spacing.dart';
import '../utils/app_system_ui_style.dart';
import '../services/beta_gate/beta_config.dart';
import '../services/beta_gate/beta_gate_service.dart';
import 'beta_gate_screen.dart';
import '../design_v2/onboarding/onboarding_screen.dart';
import '../services/onboarding/onboarding_store.dart';
import 'permissions/app_permissions_screen.dart';
import '../utils/app_text.dart';

enum StartupDestination { home, navigationMode, language, login }

/// Hairlines and the progress track on the splash art's blue footer.
final Color _faintOnBlue = AppColors.textOnPrimary.withValues(alpha: 0.25);

StartupDestination resolveStartupDestination({
  required bool hasSession,
  required bool hasCachedLanguage,
  required bool profileCompleted,
}) {
  if (hasSession) {
    return profileCompleted
        ? StartupDestination.home
        : StartupDestination.navigationMode;
  }
  return hasCachedLanguage
      ? StartupDestination.login
      : StartupDestination.language;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto navigate after 3.2 seconds
    _navigationTimer = Timer(
      const Duration(milliseconds: 3200),
      _continueStartup,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: show the logo and text at rest, no fade or scale.
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  Future<void> _continueStartup() async {
    if (!mounted) return;

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final cache = SessionCacheService.instance;

      // Load preference details from cache
      final lang = await cache.getLanguage();
      final profile = await cache.loadProfile();

      // The stored session is read instantly (works offline); the server is then
      // asked whether it is still valid so a deleted or disabled account does
      // not stay signed in.
      await AppSession.instance.hydrate();
      var hasSession = AppSession.instance.isSignedIn;

      if (hasSession) {
        // true = valid, false = rejected by the server, null = could not tell
        // (offline). Offline starts trust the cached session rather than
        // signing the user out of state that was working a moment ago.
        final valid = await RestAuthService.instance.validateSession();
        if (valid == false) {
          hasSession = false;
        } else if (valid == null) {
          debugPrint(
            '[SplashScreen] Session validation inconclusive, keeping cached session.',
          );
        }
      }

      // A Google sign-in redirect can cold-start the app straight into this
      // screen while the deep link is still being exchanged for a session. Give
      // that exchange a bounded window to land before treating the user as
      // logged-out -- otherwise the cleanup on the login path below wipes the
      // in-flight PKCE verifier and the sign-in silently fails.
      if (!hasSession && await AuthService.isOAuthPending()) {
        hasSession = AppSession.instance.isSignedIn;
        if (!hasSession) {
          debugPrint(
            '[SplashScreen] OAuth redirect pending; awaiting signedIn.',
          );
          try {
            await AppSession.instance.changes
                .firstWhere((change) => change == AuthChange.signedIn)
                .timeout(const Duration(seconds: 12));
            hasSession = AppSession.instance.isSignedIn;
          } on TimeoutException {
            debugPrint(
              '[SplashScreen] OAuth redirect did not complete in time.',
            );
          }
        }
        await AuthService.clearOAuthPending();
        if (!mounted) return;
      }

      if (!mounted) return;

      // Beta Tester Gate Interception
      if (isBetaModeEnabled) {
        final hasUnlockedBeta = await BetaGateService.hasUnlockedBeta();
        if (!hasUnlockedBeta) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BetaGateScreen()),
          );
          return;
        }
      }

      if (!mounted) return;

      final destination = resolveStartupDestination(
        hasSession: hasSession,
        hasCachedLanguage: lang != null,
        profileCompleted: profile?.profileCompleted ?? false,
      );

      switch (destination) {
        case StartupDestination.home:
          provider.updateTabIndex(0);
          await replaceWithPermissionsFirst(context, const MainTabsContainer());
          return;
        case StartupDestination.navigationMode:
          // A valid OAuth session must survive first-run onboarding. Previously
          // this path signed new users out because their profile was incomplete,
          // creating an endless "Continue with Google" loop.
          await replaceWithPermissionsFirst(
            context,
            const NavigationModeScreen(),
          );
          return;
        case StartupDestination.language:
          if (!mounted) return;
          await _replaceAfterOnboarding(const LanguageSelectionScreen());
          return;
        case StartupDestination.login:
          // Without a saved session/profile, sign-in is the only next step.
          // Keep the user out of an unusable sign-in screen while offline.
          if (!await AuthService.canReachAuthenticationService()) {
            if (mounted) _showNoNetworkDialog();
            return;
          }

          // Only tear down auth state when a real (stale/invalid) session is
          // lingering. When we're already signed out, prefs.clear() + signOut()
          // is redundant -- and it can wipe the OAuth code verifier for a
          // redirect that is still being processed.
          if (AppSession.instance.isSignedIn) {
            await cache.clearSession();
            await AuthService.signOut();
          }

          if (!mounted) return;
          await _replaceAfterOnboarding(const LoginScreen());
          return;
      }
    } catch (e, st) {
      debugPrint('[SplashScreen] Unexpected bootstrap error: $e\n$st');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      );
    }
  }

  /// First launch only: the onboarding pages, then [next] (language or
  /// sign-in). Later launches go straight to [next].
  Future<void> _replaceAfterOnboarding(Widget next) async {
    const store = OnboardingStore();
    final seen = await store.isSeen();
    if (!mounted) return;
    if (seen) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => next));
      return;
    }
    final provider = Provider.of<AppProvider>(context, listen: false);
    final count = provider.allSchemes.length;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (onboardingContext) => OnboardingScreen(
          schemeCount: count >= 100 ? (count ~/ 10) * 10 : 400,
          onDone: () {
            store.markSeen();
            Navigator.of(
              onboardingContext,
            ).pushReplacement(MaterialPageRoute(builder: (_) => next));
          },
        ),
      ),
    );
  }

  void _showNoNetworkDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.warningOnSoft,
                  size: AppSize.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.splashNoInternetTitle,
                textAlign: TextAlign.center,
                style: context.text.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.splashNoInternetBody,
                textAlign: TextAlign.center,
                style: context.text.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _continueStartup();
                  },
                  child: Text(context.l10n.retry),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mediaQuery = MediaQuery.of(context);
    final minContentHeight =
        size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full screen background
          Positioned.fill(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: appBlueFooterSystemUiStyle,
              child: Image.asset(
                'assets/images/Background/splash_screen.webp',
                fit: BoxFit.cover,
                // Keep the wave and blue footer (where the loading text sits)
                // anchored to the bottom whatever the screen's aspect ratio.
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Animated Content
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minContentHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Brand Logo centered
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxxl,
                            ),
                            child: Image.asset(
                              'assets/images/Logo/Logo.webp',
                              width: size.width * 0.60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'MSS',
                                      style: context.text.display.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        const Spacer(flex: 5),

                        // Loading Section
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: size.width * 0.45,
                                child: ClipRRect(
                                  borderRadius: AppRadius.pillAll,
                                  child: LinearProgressIndicator(
                                    minHeight: 3.5,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.textOnPrimary,
                                        ),
                                    backgroundColor: _faintOnBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                context.l10n.loading,
                                style: context.text.label.copyWith(
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                context.l10n.splashPreparingSubtitle,
                                style: context.text.bodySmall.copyWith(
                                  color: AppColors.textOnPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Developer Partner Logos Section ("App developed by")
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxxl,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: _faintOnBlue,
                                        thickness: 0.8,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: Text(
                                        context.l10n.splashDevelopedBy,
                                        style: context.text.bodySmall.copyWith(
                                          color: AppColors.textOnPrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: _faintOnBlue,
                                        thickness: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Rajalakshmi Institute of Technology (RIT) White Logo
                                    Flexible(
                                      flex: 5,
                                      child: Image.asset(
                                        'assets/images/Logo/rit_logo_white.png',
                                        height: 32,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Image.asset(
                                              'assets/images/Logo/rit_logo.webp',
                                              height: 32,
                                              fit: BoxFit.contain,
                                              color: Colors.white,
                                              colorBlendMode: BlendMode.srcIn,
                                            ),
                                      ),
                                    ),
                                    // Divider line
                                    Container(
                                      height: 32,
                                      width: 1,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      color: _faintOnBlue,
                                    ),
                                    // Swadeshi Shodh Sansthan (SSS TN Chapter) logo
                                    Flexible(
                                      flex: 3,
                                      child: Image.asset(
                                        'assets/images/Logo/sss_tn_chapter_logo.webp',
                                        height: 44,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Image.asset(
                                              'assets/images/Logo/TN Chapter_20260805_153307_0000.webp',
                                              height: 44,
                                              fit: BoxFit.contain,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
