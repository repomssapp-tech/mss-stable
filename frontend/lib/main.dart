// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;
import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/regular_mode/home_screen.dart';
import 'screens/regular_mode/categories_screen.dart';
import 'screens/regular_mode/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/regular_mode/saved_schemes_screen.dart';
import 'screens/companion_mode/saarthi_home_screen.dart';
import 'services/chat_log_service.dart';
import 'utils/constants.dart';
import 'utils/app_theme.dart';
import 'utils/app_spacing.dart';

/// App-wide scroll behavior: Android-style clamping (no iOS rubber-band).
/// The bounce read as "sticky and elastic" and let content be dragged well
/// past the last section. Widget-level `physics:` still overrides this, so
/// explicit `BouncingScrollPhysics()` call sites were switched to
/// `ClampingScrollPhysics()` as well.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Supabase connection config is injected at build time and never hard-coded.
  // Supply it with --dart-define-from-file=dart_defines.json (keys SUPABASE_URL
  // / SUPABASE_PUBLISHABLE_KEY). When absent, render a visible error instead of
  // a blank screen so the cause is obvious.
  final configError = AppConfig.validationError;
  if (configError != null) {
    debugPrint('[main] $configError ${AppConfig.setupHint}');
    runApp(_StartupErrorApp(message: '$configError\n\n${AppConfig.setupHint}'));
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  } catch (e) {
    debugPrint('[main] Supabase.initialize failed: $e');
    runApp(_StartupErrorApp(message: 'Could not connect to Supabase.\n\n$e'));
    return;
  }

  // App Startup Recovery: Check for unsynced chat sessions in local storage and batch upload to Supabase
  unawaited(ChatLogService.syncPendingOfflineQueue());

  // Warm WebRTC in the background while the user is on the app shell. This
  // also selects Android's communication audio path early, allowing supported
  // phones to use their hardware AEC/noise suppressor before voice connects.
  unawaited(
    livekit.LiveKitClient.initialize(
      bypassVoiceProcessing: false,
      // LiveKit marks this Android audio-session preset experimental, but it
      // is the supported API for priming communication mode before first use.
      initialAudioSessionOptions:
          const livekit.AudioSessionOptions.communication(),
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const InSchemesApp(),
    ),
  );
}

/// Shown in place of the app when startup cannot proceed (missing build-time
/// configuration, or Supabase failed to initialise). Replaces what would
/// otherwise be a blank screen with an actionable message.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'App configuration error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InSchemesApp extends StatelessWidget {
  const InSchemesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Only the locale depends on AppProvider here. Selecting the single field
    // keeps the whole MaterialApp from rebuilding on unrelated notifyListeners().
    final selectedLanguage = context.select<AppProvider, String>(
      (p) => p.selectedLanguage,
    );
    return MaterialApp(
      title: 'MSS',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      locale: Locale(selectedLanguage),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        // Respect the device's own accessibility text-scale setting
        // instead of discarding it, but keep an app design floor and a
        // ceiling so layouts stay intact. Tamil glyphs are taller and
        // denser than Latin, so the +20% floor made Tamil screens feel
        // cramped -- drop the floor (and lower the ceiling) for `ta`.
        final isTamil = selectedLanguage == 'ta';
        final deviceScale = mediaQueryData.textScaler.scale(1.0);
        final boundedScale = deviceScale.clamp(
          isTamil ? 1.0 : 1.20,
          isTamil ? 1.12 : 1.30,
        );
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(boundedScale),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          error: AppConstants.errorColor,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          // Poppins for App Logo & Titles
          headlineLarge: GoogleFonts.poppins(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryText,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryText,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryText,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryText,
          ),

          // Inter for Body and Form Elements (height >= 1.4 prevents Tamil diacritic clipping)
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: AppConstants.primaryText,
            height: 1.45,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: AppConstants.primaryText,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: AppConstants.secondaryText,
            height: 1.4,
          ),

          labelLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ), // Button
          labelMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.secondaryText,
          ), // Form Label
          labelSmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: AppConstants.secondaryText,
          ), // Small Info
        ),
        // Styling for premium light cards
        cardTheme: CardThemeData(
          color: AppConstants.surfaceColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.cardBorderColor),
          ),
        ),
        datePickerTheme: AppTheme.datePickerTheme,
      ),
      // Set initial screen based on login state
      home: const SplashScreen(),
      // The platform forwards incoming deep-link intents (e.g. the
      // Supabase OAuth callback "com.inschemes.app://login-callback/
      // ?code=...") as a named-route push, even though
      // supabase_flutter's own listener (registered in
      // Supabase.initialize) already completes the auth code exchange
      // independently of the Navigator. This app has no named-route
      // table (only `home:`), so without a route generator Flutter's
      // default onUnknownRoute throws "Could not find a generator for
      // route". Absorb it: push nothing visible and pop immediately.
      onGenerateRoute: (settings) => null,
      onUnknownRoute: (settings) => PageRouteBuilder(
        settings: settings,
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Wrapper for Persistent Bottom Navigation Tabs Container
class MainTabsContainer extends StatefulWidget {
  const MainTabsContainer({super.key});

  @override
  State<MainTabsContainer> createState() => _MainTabsContainerState();
}

class _MainTabsContainerState extends State<MainTabsContainer> {
  final GlobalKey<SearchScreenState> searchTabKey =
      GlobalKey<SearchScreenState>();

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int currentTabIndex,
    String selectedLanguage,
    AppProvider provider,
  ) {
    final isSelected = currentTabIndex == index;
    final color = isSelected
        ? const Color(0xFF2563EB)
        : const Color(0xFF64748B);

    Widget iconWidget = Icon(
      isSelected ? activeIcon : icon,
      color: color,
      size: 24,
    );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (currentTabIndex == index && index == 1) {
            searchTabKey.currentState?.resetToIdle();
          }
          provider.updateTabIndex(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: selectedLanguage == 'ta' ? 9.5 : 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen only to the fields this shell renders. Listening to the whole
    // AppProvider meant every notifyListeners() (profile sync, bookmarks,
    // search state, ...) rebuilt all five tabs in the IndexedStack. Callbacks
    // below use the non-listening reference.
    final provider = Provider.of<AppProvider>(context, listen: false);
    final navigationMode = context.select<AppProvider, String>(
      (p) => p.navigationMode,
    );
    final currentTabIndex = context.select<AppProvider, int>(
      (p) => p.currentTabIndex,
    );
    final selectedLanguage = context.select<AppProvider, String>(
      (p) => p.selectedLanguage,
    );
    final l10n = AppLocalizations.of(context)!;

    // List of screens matching tabs
    final List<Widget> tabs = [
      navigationMode == 'companion'
          ? const SaarthiHomeScreen()
          : HomeScreen(
              onVoiceQuery: (query) {
                provider.updateTabIndex(1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  searchTabKey.currentState?.submitVoiceQuery(query);
                });
              },
              onFilterPressed: () {
                provider.updateTabIndex(1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  searchTabKey.currentState?.openFilterBottomSheet();
                });
              },
              onSearchBarTap: () {
                provider.updateTabIndex(1);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  searchTabKey.currentState?.focusSearchField();
                });
              },
            ),
      SearchScreen(key: searchTabKey),
      CategoriesScreen(
        onCategorySelected: (category) {
          provider.updateTabIndex(1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            searchTabKey.currentState?.submitVoiceQuery(category);
          });
        },
      ),
      const SavedSchemesScreen(),
      const ProfileScreen(),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: AppConstants.blueGradient),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // 1. If searching, clear query first
          if (currentTabIndex == 1 &&
              searchTabKey.currentState != null &&
              searchTabKey.currentState!.isSearching) {
            searchTabKey.currentState!.resetToIdle();
            return;
          }

          // 2. Try popping tab history
          final popped = provider.popTabIndex();
          if (popped) {
            return;
          }

          // 3. Exit the app
          SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(index: currentTabIndex, children: tabs),
          bottomNavigationBar: navigationMode == 'companion'
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          0,
                          Icons.home_outlined,
                          Icons.home,
                          l10n.navHome,
                          currentTabIndex,
                          selectedLanguage,
                          provider,
                        ),
                        _buildNavItem(
                          1,
                          Icons.search,
                          Icons.search_sharp,
                          l10n.navSearch,
                          currentTabIndex,
                          selectedLanguage,
                          provider,
                        ),
                        _buildNavItem(
                          2,
                          Icons.explore_outlined,
                          Icons.explore,
                          l10n.navDiscover,
                          currentTabIndex,
                          selectedLanguage,
                          provider,
                        ),
                        _buildNavItem(
                          3,
                          Icons.bookmark_border,
                          Icons.bookmark,
                          l10n.navSaved,
                          currentTabIndex,
                          selectedLanguage,
                          provider,
                        ),
                        _buildNavItem(
                          4,
                          Icons.person_outline,
                          Icons.person,
                          l10n.navProfile,
                          currentTabIndex,
                          selectedLanguage,
                          provider,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
