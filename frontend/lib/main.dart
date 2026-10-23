// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'screens/notifications/push_message_presenter.dart';
import 'services/account/app_session.dart';
import 'services/notifications/firebase_push_gateway.dart';
import 'services/network/connectivity_service.dart';
import 'services/catalog/centralized_translator.dart';
import 'services/chat/chat_log_service.dart';
import 'utils/constants.dart';
import 'utils/app_theme.dart';
import 'utils/app_spacing.dart';
import 'widgets/common/app_bottom_nav_bar.dart';
import 'widgets/onboarding/home_tour.dart';
import 'widgets/onboarding/home_tour_targets.dart';
import 'widgets/common/haptic_touch_layer.dart';
import 'services/haptics/haptics_service.dart';
import 'services/notifications/local_notification_service.dart';

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

  // 2.2 (design system): Inter, Poppins and Noto Sans Tamil are now bundled
  // as local assets (pubspec.yaml `fonts:`) under the same family names
  // google_fonts' own helpers request, so AppGoogleFonts.inter()/.poppins()
  // resolve locally and never need the network. Disabling runtime fetching
  // outright removes the offline-first bug where a cold start with no
  // connectivity fell back to Roboto everywhere. google_fonts itself is
  // still used at ~108 existing call sites pending the Phase 3 AppText
  // codemod; this line is the one the spec calls for in the meantime.
  GoogleFonts.config.allowRuntimeFetching = false;

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

  // The backend origin is injected at build time (API_BASE_URL) and defaults to
  // production. When it is malformed, render a visible error instead of a blank
  // screen so the cause is obvious.
  final configError = AppConfig.validationError;
  if (configError != null) {
    debugPrint('[main] $configError ${AppConfig.setupHint}');
    runApp(_StartupErrorApp(message: '$configError\n\n${AppConfig.setupHint}'));
    return;
  }

  // These startup steps do not depend on each other, so they run together
  // instead of one after another (a cold start used to wait for each in turn):
  // the translation dictionary preloaded for synchronous catalog translations,
  // the signed-in account restored from secure storage so the rest of the app
  // can read it synchronously, the phone's network status, Firebase, the
  // haptics on/off setting and the phone-notification channel (a tap on a
  // notification that launched the app is opened once the shell is up).
  final startup = await Future.wait<Object?>([
    CentralizedTranslator.instance.ensureLoaded(),
    AppSession.instance.hydrate(),
    ConnectivityService.instance.start(),
    initializeFirebase(),
    HapticsService.instance.load(),
    LocalNotificationService.instance.init(),
  ]);
  final pushGateway = startup[3] == true ? FirebasePushGateway() : null;

  // App Startup Recovery: upload chat sessions that were saved locally while
  // offline.
  unawaited(ChatLogService.syncPendingOfflineQueue());

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(pushGateway: pushGateway),
      child: const MSSApp(),
    ),
  );
}

/// Shown in place of the app when startup cannot proceed (missing build-time
/// configuration). Replaces what would
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

class MSSApp extends StatelessWidget {
  const MSSApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Only the locale depends on AppProvider here. Selecting the single field
    // keeps the whole MaterialApp from rebuilding on unrelated notifyListeners().
    final selectedLanguage = context.select<AppProvider, String>(
      (p) => p.selectedLanguage,
    );
    // Static UI text that goes through CentralizedTranslator.localize() follows
    // the same language as the locale; set before any descendant builds.
    CentralizedTranslator.instance.activeLanguage = selectedLanguage;
    return MaterialApp(
      title: 'MSS',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      navigatorObservers: [appRouteObserver],
      locale: Locale(selectedLanguage),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Reverted from the Phase 3 group 1 (G2/G3) 1.0-1.6 symmetric clamp
        // (batch-1 review B1): that clamp is meant to ship together with
        // the Phase 3 screen-by-screen size sweep (spec_phase3.md §1a says
        // so explicitly) -- landing it ahead of the sweep makes the
        // interim app less readable, not more, since the old English 1.2x
        // floor is gone but the unswept screens' fixed-height containers
        // and sub-12sp literals aren't fixed yet. Restored the pre-Phase-3
        // per-language floor/ceiling until the sweep lands.
        final mediaQueryData = MediaQuery.of(context);
        // Respect the device's own accessibility text-scale setting
        // instead of discarding it, but keep an app design floor and a
        // ceiling so layouts stay intact. Tamil glyphs are taller and
        // denser than Latin, so the +20% floor made Tamil screens feel
        // cramped -- drop the floor (and lower the ceiling) for `ta`.
        //
        // The device setting multiplies the per-language base (so the default
        // size is unchanged) and is no longer capped at 1.12-1.30x: a user who
        // asks for 1.5x gets 1.5x, up to 2x (WCAG 1.4.4; test report BUG-11).
        final isTamil = selectedLanguage == 'ta';
        final base = isTamil ? 1.0 : 1.20;
        final deviceScale = mediaQueryData.textScaler.scale(1.0);
        final boundedScale = (deviceScale * base).clamp(base, 2.0);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(boundedScale),
          ),
          child: HapticTouchLayer(child: child!),
        );
      },
      // 2.3 (design system): the whole ThemeData moved to AppTheme.light.
      // The old dead textTheme here (never referenced by any screen, all of
      // which pass their own explicit GoogleFonts.X() styles) is gone;
      // AppTheme.light's textTheme is built from the new AppTextStyles
      // scale instead.
      theme: AppTheme.light,
      // Set initial screen based on login state
      home: const SplashScreen(),
      // The platform forwards incoming deep-link intents (e.g. the Google
      // OAuth callback "com.inschemes.app://login-callback/?code=...") as a
      // named-route push, even though DeepLinkService already exchanges the
      // code independently of the Navigator. This app has no named-route
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

  /// Tabs built so far. The first screen is built at once, the others one at a
  /// time shortly after start (or on first visit if that comes sooner); the
  /// IndexedStack then keeps them alive, so a cold start builds one tab, not
  /// five.
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // The other tabs are built one at a time once the first screen is up, so
    // the first switch to a tab does not build it in the same frames as the
    // nav bar's droplet animation (it showed as a stutter or a jump).
    unawaited(_warmUpTabs());
    unawaited(_showHomeTourWhenReady());
  }

  @override
  void dispose() {
    HomeTour.dismiss();
    super.dispose();
  }

  /// The first-time tour of the home screen: shown once per account, after the
  /// home screen and the bottom bar are on screen (retried a few times while
  /// their widgets are still being laid out).
  Future<void> _showHomeTourWhenReady() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      await Future<void>.delayed(
        Duration(milliseconds: attempt == 0 ? 1800 : 1000),
      );
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.currentTabIndex != 0 ||
          provider.navigationMode == 'companion') {
        continue;
      }
      final result = await HomeTour.maybeStart(context);
      if (result != HomeTourStart.notReady) return;
    }
  }

  Future<void> _warmUpTabs() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    for (var i = 1; i < 5; i++) {
      if (!mounted) return;
      setState(() => _visitedTabs.add(i));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
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
    _visitedTabs.add(currentTabIndex);
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
                  searchTabKey.currentState?.focusFreshSearch();
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
          // The floating bar sits over the tab content (blurred through the
          // glass). The body's bottom padding grows by the bar's height, so
          // scrollables and SafeAreas keep their last rows clear of it.
          extendBody: true,
          body: IndexedStack(
            index: currentTabIndex,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _visitedTabs.contains(i) ? tabs[i] : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: navigationMode == 'companion'
              ? null
              : AppBottomNavBar(
                  itemKeys: {
                    2: HomeTourTargets.discover,
                    4: HomeTourTargets.profile,
                  },
                  selectedIndex: currentTabIndex,
                  onSelected: (i) {
                    if (currentTabIndex == i && i == 1) {
                      searchTabKey.currentState?.resetToIdle();
                    }
                    provider.updateTabIndex(i);
                  },
                  labels: [
                    l10n.navHome,
                    l10n.navSearch,
                    l10n.navDiscover,
                    l10n.navSaved,
                    l10n.navProfile,
                  ],
                ),
        ),
      ),
    );
  }
}
