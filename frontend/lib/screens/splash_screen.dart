import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'regular_mode/language_selection_screen.dart';
import 'login_screen.dart';
import 'navigation_mode_screen.dart';
import '../l10n/l10n.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';
import '../services/session_cache_service.dart';
import '../utils/constants.dart';
import '../main.dart';
import '../utils/app_spacing.dart';
import '../features/beta_gate/beta_config.dart';
import '../features/beta_gate/beta_gate_service.dart';
import '../features/beta_gate/beta_gate_screen.dart';

enum StartupDestination { home, navigationMode, language, login }

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
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Auto navigate after 3.2 seconds
    _navigationTimer = Timer(
      const Duration(milliseconds: 3200),
      _continueStartup,
    );
  }

  Future<void> _continueStartup() async {
    if (!mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final cache = SessionCacheService.instance;

    // Load preference details from cache
    final lang = await cache.getLanguage();
    final profile = await cache.loadProfile();

    // Validate Supabase session (instant offline check)
    var session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        // Perform a server-side validation to check if the user was deleted/disabled
        final userResponse = await Supabase.instance.client.auth.getUser();
        if (userResponse.user == null) {
          session = null;
        }
      } on AuthRetryableFetchException catch (netErr) {
        // Network-unreachable (offline, DNS failure, timeout) -- not a
        // rejection by the server. Trust the cached session rather than
        // signing the user out just because the app happened to start
        // offline; this is the online-only exception to the offline-first
        // policy (session validation), not scheme discovery, but it must
        // not destroy state that was working fine a moment ago.
        debugPrint(
          '[SplashScreen] Session validation unreachable (offline?), keeping cached session: $netErr',
        );
      } on AuthException catch (authErr) {
        debugPrint(
          '[SplashScreen] Auth exception during session validation: $authErr',
        );
        final statusStr = authErr.statusCode ?? '';
        if (statusStr == '400' ||
            statusStr == '403' ||
            statusStr == '404' ||
            authErr.message.toLowerCase().contains('user') ||
            authErr.message.toLowerCase().contains('invalid')) {
          session = null;
        }
      } catch (e) {
        debugPrint(
          '[SplashScreen] Non-auth exception during session validation: $e',
        );
      }
    }

    // A Google sign-in redirect can cold-start the app straight into this
    // screen while supabase_flutter is still exchanging the OAuth code for a
    // session. Give that exchange a bounded window to land before treating the
    // user as logged-out -- otherwise the cleanup on the login path below wipes
    // the in-flight PKCE verifier and the sign-in silently fails (name/email
    // never arrive because AuthChangeEvent.signedIn is never emitted).
    if (session == null && await AuthService.isOAuthPending()) {
      session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('[SplashScreen] OAuth redirect pending; awaiting signedIn.');
        try {
          final data = await Supabase.instance.client.auth.onAuthStateChange
              .firstWhere(
                (d) =>
                    d.session != null &&
                    (d.event == AuthChangeEvent.signedIn ||
                        d.event == AuthChangeEvent.initialSession ||
                        d.event == AuthChangeEvent.tokenRefreshed),
              )
              .timeout(const Duration(seconds: 12));
          session = data.session;
        } on TimeoutException {
          debugPrint('[SplashScreen] OAuth redirect did not complete in time.');
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
      hasSession: session != null,
      hasCachedLanguage: lang != null,
      profileCompleted: profile?.profileCompleted ?? false,
    );

    switch (destination) {
      case StartupDestination.home:
        provider.updateTabIndex(0);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainTabsContainer()),
        );
        return;
      case StartupDestination.navigationMode:
        // A valid OAuth session must survive first-run onboarding. Previously
        // this path signed new users out because their profile was incomplete,
        // creating an endless "Continue with Google" loop.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavigationModeScreen()),
        );
        return;
      case StartupDestination.language:
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
        if (Supabase.instance.client.auth.currentSession != null) {
          await cache.clearSession();
          try {
            await Supabase.instance.client.auth.signOut();
          } catch (_) {}
        }

        if (!mounted) return;
        if (destination == StartupDestination.language) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
    }
  }

  void _showNoNetworkDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFD97706),
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.splashNoInternetTitle,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.splashNoInternetBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFF64748B),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Stack(
        children: [
          // 1. Full screen background
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/splash_screen.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Animated Content
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: constraints.maxHeight < 560
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(flex: 3),
                            _BrandLogoSection(
                              fadeAnimation: _fadeAnimation,
                              scaleAnimation: _scaleAnimation,
                              screenWidth: size.width,
                              maxHeight: constraints.maxHeight * 0.24,
                            ),
                            const Spacer(flex: 4),
                            _SplashBottomSection(
                              fadeAnimation: _fadeAnimation,
                              screenWidth: size.width,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final double screenWidth;
  final double maxHeight;

  const _BrandLogoSection({
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.screenWidth,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (screenWidth * 0.58).clamp(160.0, 240.0),
            maxHeight: maxHeight > 60 ? maxHeight : 140,
          ),
          child: Image.asset(
            'assets/images/Logo/Logo.webp',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'MSS',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashBottomSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final double screenWidth;

  const _SplashBottomSection({
    required this.fadeAnimation,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linear Progress Indicator
          SizedBox(
            width: (screenWidth * 0.48).clamp(140.0, 220.0),
            child: const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: LinearProgressIndicator(
                minHeight: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Loading Title
          Text(
            context.l10n.loading,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.tight),

          // Subtitle
          Text(
            context.l10n.splashPreparingSubtitle,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xD9FFFFFF),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // "App developed by" section with divider lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: Color(0x59FFFFFF),
                    thickness: 0.8,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'App developed by',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xE6FFFFFF),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: Color(0x59FFFFFF),
                    thickness: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Developer Partner Logos Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rajalakshmi Institute of Technology (RIT) logo
                Flexible(
                  flex: 5,
                  child: Image.asset(
                    'assets/images/Logo/rit_logo.webp',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/Logo/TN Chapter_20260805_153104_0000.webp',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Vertical divider line
                Container(
                  height: 36,
                  width: 1,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  color: const Color(0x59FFFFFF),
                ),
                // Swadeshi Shodh Sansthan (SSS TN Chapter) logo
                Flexible(
                  flex: 3,
                  child: Image.asset(
                    'assets/images/Logo/sss_tn_chapter_logo.webp',
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/Logo/TN Chapter_20260805_153307_0000.webp',
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Version Footer
          Text(
            'v1.0.0',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xA6FFFFFF),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

