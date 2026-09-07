import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'regular_mode/language_selection_screen.dart';
import 'login_screen.dart';
import 'navigation_mode_screen.dart';
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
                'No internet connection',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connect to the internet to sign in or restore this app.',
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
                  child: const Text('Retry'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Image.asset(
                        'assets/images/Logo/Logo.webp',
                        width: size.width * 0.60,
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

                  const Spacer(flex: 5),

                  // Loading Section at the bottom overlaying the blue wave
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: size.width * 0.5,
                          child: const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Loading...',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Please wait while we prepare\nsomething amazing for you',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
