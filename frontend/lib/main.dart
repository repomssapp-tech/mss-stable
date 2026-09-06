// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;
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

  // Supabase connection config. Overridable at build time via
  // --dart-define-from-file=dart_defines.json (keys SUPABASE_URL /
  // SUPABASE_PUBLISHABLE_KEY); the compiled-in defaults are the production
  // project URL + publishable key, both public by design so the app runs
  // with no build flags.
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://houpzsxmwemoztpuigmo.supabase.co',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_GnJpz6ZxuGeeroG92VkbBA_b3_pyTvN',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

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

class InSchemesApp extends StatelessWidget {
  const InSchemesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'MSS',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          locale: Locale(provider.selectedLanguage),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            // Respect the device's own accessibility text-scale setting
            // instead of discarding it, but keep an app design floor and a
            // ceiling so layouts stay intact. Tamil glyphs are taller and
            // denser than Latin, so the +20% floor made Tamil screens feel
            // cramped -- drop the floor (and lower the ceiling) for `ta`.
            final isTamil = provider.selectedLanguage == 'ta';
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
      },
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
    AppProvider provider,
  ) {
    final isSelected = provider.currentTabIndex == index;
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
          if (provider.currentTabIndex == index && index == 1) {
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
                  fontSize: provider.selectedLanguage == 'ta' ? 9.5 : 10.5,
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
    final provider = Provider.of<AppProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // List of screens matching tabs
    final List<Widget> tabs = [
      provider.navigationMode == 'companion'
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
          if (provider.currentTabIndex == 1 &&
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
          body: IndexedStack(index: provider.currentTabIndex, children: tabs),
          bottomNavigationBar: provider.navigationMode == 'companion'
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
                          provider,
                        ),
                        _buildNavItem(
                          1,
                          Icons.search,
                          Icons.search_sharp,
                          l10n.navSearch,
                          provider,
                        ),
                        _buildNavItem(
                          2,
                          Icons.explore_outlined,
                          Icons.explore,
                          l10n.navDiscover,
                          provider,
                        ),
                        _buildNavItem(
                          3,
                          Icons.bookmark_border,
                          Icons.bookmark,
                          l10n.navSaved,
                          provider,
                        ),
                        _buildNavItem(
                          4,
                          Icons.person_outline,
                          Icons.person,
                          l10n.navProfile,
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
