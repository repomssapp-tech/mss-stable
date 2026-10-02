import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import '../services/recommendation/recommendation_engine.dart';
import '../services/account/auth_service.dart';
import '../services/account/google_identity.dart';
import '../services/catalog/scheme_repository.dart';
import '../services/catalog/scheme_catalog_sync_service.dart';
import '../services/account/session_cache_service.dart';
import '../screens/splash_screen.dart';
import '../widgets/common/app_toast.dart';
import 'app_state_seed_data.dart';
import 'controllers/language_reconciler.dart';
import 'controllers/library_controller.dart';
import 'controllers/navigation_mode_reconciler.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/profile_cloud_sync.dart' as profile_cloud_sync;
import 'controllers/profile_completion.dart' as profile_completion;
import 'controllers/promo_content_controller.dart';
import 'controllers/scheme_catalog_controller.dart';
import 'controllers/search_filter_controller.dart';
import 'controllers/tab_navigation_controller.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  AppProvider({SchemeCatalogSyncService? catalogSyncService})
    : _catalog = SchemeCatalogController(
        catalogSyncService: catalogSyncService,
      ) {
    WidgetsBinding.instance.addObserver(this);
    _tabs.addListener(notifyListeners);
    _library.addListener(notifyListeners);
    _searchFilter.addListener(notifyListeners);
    _notifications.addListener(notifyListeners);
    _promos.addListener(notifyListeners);
    _catalog.addListener(notifyListeners);
    _loadState();
    _setupAuthListener();
  }

  /// Loaded scheme catalog + ranked recommendations + catalog-sync state and
  /// the `loadSchemes` / `syncSchemeCatalog` flows, forwarded through this
  /// provider's own `notifyListeners` (frontend refactor C1.4). The current
  /// language + profile are passed in at each call site.
  final SchemeCatalogController _catalog;

  /// Bottom-navigation state (index + back-stack), forwarded through this
  /// provider's own `notifyListeners` (frontend refactor C1.4).
  final TabNavigationController _tabs = TabNavigationController();

  /// Saved-content lists (bookmarks, recently viewed, saved eligibility set)
  /// and their persistence, forwarded through this provider's own
  /// `notifyListeners` (frontend refactor C1.4).
  final LibraryController _library = LibraryController();

  /// Transient search query + active facet filters, forwarded through this
  /// provider's own `notifyListeners` (frontend refactor C1.4).
  final SearchFilterController _searchFilter = SearchFilterController();

  /// In-app notifications list + its Supabase realtime subscription and
  /// read/delete mutations, forwarded through this provider's own
  /// `notifyListeners` (frontend refactor C1.4).
  final NotificationsController _notifications = NotificationsController();

  /// Home-screen promo carousel source data (`promo_alerts` rows + in-progress
  /// draft sessions) and its fetch throttles, forwarded through this provider's
  /// own `notifyListeners` (frontend refactor C1.4). The profile-derived
  /// `carouselItems` getter stays here.
  final PromoContentController _promos = PromoContentController();
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;
  String _mobileNumber = '';
  String _selectedLanguage = 'en'; // 'en', 'ta'
  // Ignores a server language value that contradicts a just-made explicit
  // changeLanguage() choice for a short window (a realtime echo or a
  // not-yet-updated profile row can still carry the OLD language briefly).
  final LanguageReconciler _languageReconciler = LanguageReconciler();
  final NavigationModeReconciler _navigationModeReconciler =
      NavigationModeReconciler();
  String _navigationMode = 'regular'; // 'regular', 'companion'
  UserProfile _profile = UserProfile();

  List<Map<String, dynamic>> get notifications => _notifications.notifications;

  List<Map<String, dynamic>> get carouselItems {
    final filteredPromos = _promos.promoAlerts.where((promo) {
      if (promo['target_gender'] != null &&
          promo['target_gender'].toString().isNotEmpty &&
          _profile.gender.isNotEmpty) {
        if (promo['target_gender'].toString().toLowerCase() !=
            _profile.gender.toLowerCase()) {
          return false;
        }
      }
      if (promo['target_state'] != null &&
          promo['target_state'].toString().isNotEmpty &&
          _profile.state.isNotEmpty) {
        if (promo['target_state'].toString().toLowerCase() !=
            _profile.state.toLowerCase()) {
          return false;
        }
      }
      if (promo['target_community'] != null &&
          promo['target_community'].toString().isNotEmpty &&
          _profile.community.isNotEmpty) {
        if (promo['target_community'].toString().toLowerCase() !=
            _profile.community.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();

    final basePromos = filteredPromos.isNotEmpty
        ? filteredPromos
        : kDefaultPromoAlerts;
    return [...basePromos, ..._promos.draftSessions];
  }

  // Guards against redundant re-subscription. `_subscribeToProfile` (and
  // `NotificationsController.subscribe`) are each called from the auth-state
  // listener, `_loadState`, and `checkSessionAndFetchProfile`, which can all
  // run on a single launch. Every re-subscribe tears down the socket and
  // replays an initial full-table fetch, so the old unconditional version
  // paid for the same rows two or three times per launch.
  String? _subscribedProfileUserId;

  void _subscribeToProfile(String userId) {
    if (_profileSubscription != null && _subscribedProfileUserId == userId) {
      return;
    }
    _subscribedProfileUserId = userId;
    _profileSubscription?.cancel();
    _profileSubscription = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen(
          (data) async {
            if (data.isNotEmpty) {
              var dbProfile = UserProfile.fromJson(data.first);

              // Preserve local custom photo or Google OAuth photo if remote photo is empty
              if (dbProfile.profilePhoto.isEmpty ||
                  dbProfile.profilePhoto.contains('user_avatar.webp')) {
                final currentPhoto = _profile.profilePhoto;
                if (currentPhoto.isNotEmpty &&
                    !currentPhoto.contains('user_avatar.webp')) {
                  dbProfile = dbProfile.copyWith(profilePhoto: currentPhoto);
                } else {
                  final googlePhoto = extractGooglePhoto(
                    Supabase.instance.client.auth.currentUser,
                  );
                  if (googlePhoto.isNotEmpty) {
                    dbProfile = dbProfile.copyWith(profilePhoto: googlePhoto);
                  }
                }
              }

              final remoteUpdated =
                  dbProfile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final localUpdated =
                  _profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              if (remoteUpdated.isAfter(localUpdated) ||
                  dbProfile.name != _profile.name ||
                  dbProfile.profilePhoto != _profile.profilePhoto ||
                  dbProfile.language != _profile.language ||
                  dbProfile.navigationMode != _profile.navigationMode ||
                  dbProfile.state != _profile.state ||
                  dbProfile.district != _profile.district ||
                  dbProfile.pinCode != _profile.pinCode ||
                  dbProfile.gender != _profile.gender ||
                  dbProfile.employmentStatus != _profile.employmentStatus ||
                  dbProfile.profileCompleted != _profile.profileCompleted) {
                _profile = _profile.mergeFrom(dbProfile);
                _selectedLanguage = _languageReconciler.reconcile(
                  dbProfile.language,
                );
                _profile = _profile.copyWith(language: _selectedLanguage);
                _navigationMode = _navigationModeReconciler.reconcile(
                  dbProfile.navigationMode,
                );
                _profile = _profile.copyWith(navigationMode: _navigationMode);

                _catalog.recomputeRecommendations(_profile);
                fetchPromoAlerts();
                fetchDraftSessions();
                notifyListeners();

                await SessionCacheService.instance.saveProfile(_profile);
                await SessionCacheService.instance.saveLanguage(
                  _selectedLanguage,
                );
                await SessionCacheService.instance.saveNavigationMode(
                  _navigationMode,
                );
              }
            }
          },
          onError: (err) {
            debugPrint(
              '[AppProvider] Real-time profile subscription error: $err',
            );
          },
        );
  }

  void _unsubscribeFromProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _subscribedProfileUserId = null;
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      final AuthChangeEvent event = data.event;

      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        // Auth resolved -- retire the startup grace marker for OAuth redirects.
        unawaited(AuthService.clearOAuthPending());
        _isLoggedIn = true;
        final user = session.user;
        _mobileNumber = user.phone ?? '';
        final googlePhoto = extractGooglePhoto(user);
        final googleName = extractGoogleName(user);

        // Authentication is complete at this point. Notify immediately so the
        // login route can advance while profile hydration continues; a slow or
        // unavailable profile query must never leave the user on the sign-in
        // button after Google has already accepted them.
        notifyListeners();

        try {
          final dbProfile = await SchemeRepository.instance.getProfile(user.id);
          if (dbProfile != null) {
            _profile = _profile.mergeFrom(dbProfile);
            _selectedLanguage = _languageReconciler.reconcile(dbProfile.language);
            _profile = _profile.copyWith(language: _selectedLanguage);
            _navigationMode = dbProfile.navigationMode;
            // Persist the merged (most complete) profile locally, and push
            // back to Supabase any field the DB row was missing.
            unawaited(SessionCacheService.instance.saveProfile(_profile));
            if (!_profile.matchesStored(dbProfile)) {
              unawaited(SchemeRepository.instance.updateProfile(_profile));
            }

            if ((_profile.profilePhoto.isEmpty ||
                    _profile.profilePhoto.contains('user_avatar.webp')) &&
                googlePhoto.isNotEmpty) {
              _profile = _profile.copyWith(
                profilePhoto: googlePhoto,
                updatedAt: DateTime.now(),
              );
              unawaited(SessionCacheService.instance.saveProfile(_profile));
              unawaited(SchemeRepository.instance.updateProfile(_profile));
            }
          } else {
            _profile = UserProfile(
              googleUserId: user.id,
              name: googleName.isNotEmpty ? googleName : 'Google User',
              email: user.email ?? '',
              mobile: user.phone ?? '',
              profilePhoto: googlePhoto,
              language: _selectedLanguage,
              navigationMode: _navigationMode,
            );
            unawaited(_saveProfile());
            unawaited(SchemeRepository.instance.createProfile(_profile));
          }

          // Recompute immediately rather than relying solely on
          // _subscribeToProfile's realtime listener to catch up -- that
          // subscription is eventually-consistent (and does nothing at all
          // if Realtime isn't enabled for the profiles table), so without
          // this, "Recommended For You" keeps showing scores computed
          // against the pre-sign-in default profile until something else
          // happens to recompute it.
          if (_catalog.hasSchemes) {
            _catalog.recomputeRecommendations(_profile);
          }

          _subscribeToProfile(user.id);
          _notifications.subscribe(user.id);
          fetchPromoAlerts();
          fetchDraftSessions();
          await _saveProfile();
        } catch (error, stackTrace) {
          debugPrint(
            '[AppProvider] Signed in, but profile hydration failed: $error\n$stackTrace',
          );
        }
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        unawaited(AuthService.clearOAuthPending());
        _isLoggedIn = false;
        _mobileNumber = '';
        _profile = UserProfile();
        _library.reset();
        _tabs.resetIndexOnly();
        // reset() also clears the fetch-throttle stamps, or the next account to
        // sign in on this device would be served the previous user's empty
        // state until the throttle window expired.
        _promos.reset();
        _unsubscribeFromProfile();
        _notifications.reset();
        notifyListeners();
      }
    });
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;

  @visibleForTesting
  void setLoggedInForTesting(bool val) {
    _isLoggedIn = val;
    notifyListeners();
  }

  @visibleForTesting
  void setRecommendedSchemesForTesting(
    List<MapEntry<Scheme, RecommendationResult>> schemes,
  ) => _catalog.setRecommendedSchemesForTesting(schemes);

  @visibleForTesting
  void setAllSchemesForTesting(List<Scheme> schemes) =>
      _catalog.setAllSchemesForTesting(schemes);

  bool get isGuest => false;
  bool get isLoggingOut => _isLoggingOut;
  String get mobileNumber => _mobileNumber;
  String get selectedLanguage => _selectedLanguage;
  String get navigationMode => _navigationMode;
  int get currentTabIndex => _tabs.currentTabIndex;
  UserProfile get profile => _profile;

  /// Returns the effective profile photo URL or local file path.
  /// Priority:
  /// 1. Custom photo chosen by user (valid local file from gallery/camera or non-Google custom URL).
  /// 2. Google OAuth profile photo from current Supabase session.
  /// 3. Empty string (falls back to local avatar illustration asset).
  String get effectiveProfilePhoto {
    final photo = _profile.profilePhoto.trim();
    if (photo.isNotEmpty && !photo.contains('user_avatar.webp')) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return photo;
      }
      if (File(photo).existsSync()) {
        return photo;
      }
    }
    final googlePhoto = extractGooglePhoto(
      Supabase.instance.client.auth.currentUser,
    );
    if (googlePhoto.isNotEmpty) {
      return googlePhoto;
    }
    return '';
  }

  /// Returns true if the user has uploaded/picked a custom profile photo.
  bool get hasCustomPhoto {
    final photo = _profile.profilePhoto.trim();
    if (photo.isEmpty || photo.contains('user_avatar.webp')) return false;
    if (File(photo).existsSync()) return true;
    final google = extractGooglePhoto(
      Supabase.instance.client.auth.currentUser,
    );
    return google.isNotEmpty && photo != google;
  }

  List<String> get bookmarkedIds => _library.bookmarkedIds;
  List<String> get recentlyViewedIds => _library.recentlyViewedIds;
  List<String> get savedEligibilitySchemeIds =>
      _library.savedEligibilitySchemeIds;
  DateTime? get lastEligibilitySavedAt => _library.lastEligibilitySavedAt;
  bool get hasSavedEligibilityResults => _library.hasSavedEligibilityResults;

  // Saved eligibility schemes list
  List<Scheme> get savedEligibilitySchemes {
    final ids = _library.savedEligibilitySchemeIds;
    return _catalog.allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  String get searchQuery => _searchFilter.searchQuery;
  Map<String, dynamic> get filters => _searchFilter.filters;

  // Scheme loading state — delegate to SchemeCatalogController.
  bool get schemesLoading => _catalog.schemesLoading;
  String? get schemesError => _catalog.schemesError;
  List<Scheme> get allSchemes => _catalog.allSchemes;
  CatalogSyncResult? get catalogSyncResult => _catalog.catalogSyncResult;
  bool get catalogSyncing => _catalog.catalogSyncing;
  String get catalogStatusLabel => _catalog.catalogStatusLabel;

  // Recommended schemes (ranked by RecommendationEngine against cached list)
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes =>
      _catalog.recommendedSchemes;

  // Bookmarked schemes list
  List<Scheme> get bookmarkedSchemes {
    final ids = _library.bookmarkedIds;
    return _catalog.allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  // Recently viewed schemes list
  List<Scheme> get recentlyViewedSchemes {
    final ids = _library.recentlyViewedIds;
    return _catalog.allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  // Catalog load / sync — delegate to SchemeCatalogController, passing the
  // current language + profile (which stay on this facade).
  Future<void> loadSchemes({bool forceRefresh = false}) async {
    await _catalog.loadSchemes(
      langCode: _selectedLanguage,
      profile: _profile,
      forceRefresh: forceRefresh,
    );
    // Needs the just-loaded catalog to map schemeCode -> id (H7), so it runs
    // here rather than at _loadState's earlier cache hydration.
    _library.normalizeBookmarkKeys(_catalog.allSchemes);
    notifyListeners();
  }

  Future<CatalogSyncResult> syncSchemeCatalog({bool force = false}) =>
      _catalog.syncSchemeCatalog(
        langCode: _selectedLanguage,
        profile: _profile,
        force: force,
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncSchemeCatalog());
    }
  }

  // Load state from SharedPreferences (for session continue support)
  Future<void> _loadState() async {
    try {
      _selectedLanguage =
          await SessionCacheService.instance.getLanguage() ?? 'en';
      await _tabs.hydrate();

      final cachedProfile = await SessionCacheService.instance.loadProfile();
      if (cachedProfile != null) {
        _profile = cachedProfile;
        _navigationMode = _profile.navigationMode;
      }
      final cachedNavMode = await SessionCacheService.instance
          .getNavigationMode();
      if (cachedNavMode != null && cachedNavMode.isNotEmpty) {
        _navigationMode = cachedNavMode;
      }

      await _library.hydrate();

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint(
          '[AppProvider] Active Supabase session found during _loadState: user=${session.user.id}',
        );
        _isLoggedIn = true;
        _mobileNumber = session.user.phone ?? '';

        final googlePhoto = extractGooglePhoto(session.user);
        if ((_profile.profilePhoto.isEmpty ||
                _profile.profilePhoto.contains('user_avatar.webp')) &&
            googlePhoto.isNotEmpty) {
          _profile = _profile.copyWith(
            profilePhoto: googlePhoto,
            updatedAt: DateTime.now(),
          );
          unawaited(SessionCacheService.instance.saveProfile(_profile));
          unawaited(SchemeRepository.instance.updateProfile(_profile));
        }

        _subscribeToProfile(session.user.id);
        _notifications.subscribe(session.user.id);
        fetchPromoAlerts();
        fetchDraftSessions();
      } else {
        debugPrint(
          '[AppProvider] No active Supabase session found during _loadState.',
        );
      }

      notifyListeners();

      // Render local data first, then refresh the published snapshot silently.
      await loadSchemes();
      unawaited(syncSchemeCatalog());
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  // Save state helpers
  Future<void> _saveProfile() async {
    await SessionCacheService.instance.saveProfile(_profile);
  }

  Future<void> _syncProfileToSupabase(UserProfile profileToSync) =>
      profile_cloud_sync.syncProfileToSupabase(
        profileToSync,
        isLoggedIn: _isLoggedIn,
      );

  void _syncProfileToSupabaseInBackground(UserProfile profileToSync) {
    unawaited(
      _syncProfileToSupabase(profileToSync).catchError((Object error) {
        debugPrint('[AppProvider] Background Supabase sync failed: $error');
      }),
    );
  }

  @visibleForTesting
  void debugMarkLanguagePending(String lang) =>
      _languageReconciler.markPending(lang);

  @visibleForTesting
  String debugReconcileServerLanguage(String serverLang) =>
      _languageReconciler.reconcile(serverLang);

  // Setters & Actions
  Future<void> changeLanguage(String lang) async {
    _selectedLanguage = lang;
    _languageReconciler.markPending(lang);
    _profile = _profile.copyWith(language: lang, updatedAt: DateTime.now());
    await loadSchemes(forceRefresh: true);
    notifyListeners();
    await SessionCacheService.instance.saveLanguage(lang);
    await _saveProfile();

    _syncProfileToSupabaseInBackground(_profile);
  }

  Future<void> changeNavigationMode(String mode) async {
    _navigationMode = mode;
    _navigationModeReconciler.markPending(mode);
    _profile = _profile.copyWith(
      navigationMode: mode,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await SessionCacheService.instance.saveNavigationMode(mode);
    await SessionCacheService.instance.saveProfile(_profile);

    _syncProfileToSupabaseInBackground(_profile);
  }

  Future<bool> loginWithGoogle() async {
    try {
      return await AuthService.signInWithGoogle();
    } catch (e) {
      debugPrint('[AppProvider] Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<bool> checkSessionAndFetchProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _isLoggedIn = false;
      _unsubscribeFromProfile();
      notifyListeners();
      return false;
    }

    final user = session.user;
    _isLoggedIn = true;
    _mobileNumber = user.phone ?? '';
    final googlePhoto = extractGooglePhoto(user);
    final googleName = extractGoogleName(user);

    _subscribeToProfile(user.id);
    fetchPromoAlerts();
    fetchDraftSessions();

    final dbProfile = await SchemeRepository.instance.getProfile(user.id);
    if (dbProfile != null) {
      _profile = _profile.mergeFrom(dbProfile);
      _selectedLanguage = _languageReconciler.reconcile(dbProfile.language);
      _profile = _profile.copyWith(language: _selectedLanguage);
      _navigationMode = dbProfile.navigationMode;

      if ((_profile.profilePhoto.isEmpty ||
              _profile.profilePhoto.contains('user_avatar.webp')) &&
          googlePhoto.isNotEmpty) {
        _profile = _profile.copyWith(
          profilePhoto: googlePhoto,
          updatedAt: DateTime.now(),
        );
        unawaited(SchemeRepository.instance.updateProfile(_profile));
      }

      await SchemeRepository.instance.updateLastLogin(user.id);

      await SessionCacheService.instance.saveProfile(_profile);
      await SessionCacheService.instance.saveLanguage(_selectedLanguage);
      await SessionCacheService.instance.saveNavigationMode(_navigationMode);

      notifyListeners();
      return dbProfile.profileCompleted;
    } else {
      _profile = UserProfile(
        googleUserId: user.id,
        name: googleName.isNotEmpty ? googleName : 'Google User',
        email: user.email ?? '',
        mobile: user.phone ?? '',
        profilePhoto: googlePhoto,
        language: _selectedLanguage,
        navigationMode: _navigationMode,
        profileCompleted: false,
      );
      await _saveProfile();
      unawaited(SchemeRepository.instance.createProfile(_profile));
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    debugPrint('[AppProvider] logout initiated...');
    _isLoggingOut = true;
    notifyListeners();

    // 1. Perform cleanup and await asynchronous operations
    _isLoggedIn = false;
    _mobileNumber = '';
    _selectedLanguage = 'en';
    _languageReconciler.reset();
    _navigationMode = 'regular';
    _navigationModeReconciler.reset();
    _profile = UserProfile();
    _library.reset();
    _tabs.reset();
    _unsubscribeFromProfile();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    _isLoggingOut = false;
    notifyListeners();

    // 2. Navigate after cleanup is fully complete
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    debugPrint('[AppProvider] deleteAccount initiated...');
    _isLoggingOut = true;
    notifyListeners();

    // Account deletion must be confirmed by Supabase. Do not clear local
    // state after an offline failure: that would falsely claim success.
    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          debugPrint(
            '[AppProvider] Calling delete_user RPC for user: ${user.id}',
          );
          await Supabase.instance.client.rpc('delete_user');
          debugPrint(
            '[AppProvider] Supabase user account deleted successfully.',
          );
        } catch (e) {
          debugPrint('[AppProvider] Error calling delete_user RPC: $e');
          _isLoggingOut = false;
          notifyListeners();
          if (context.mounted) {
            AppToast.showWarning(
              context,
              'Account deletion needs an internet connection. Nothing was changed.',
            );
          }
          return;
        }
      }
    }

    // 2. Perform local state cleanup and await async operations
    _isLoggedIn = false;
    _mobileNumber = '';
    _selectedLanguage = 'en';
    _languageReconciler.reset();
    _navigationMode = 'regular';
    _navigationModeReconciler.reset();
    _profile = UserProfile();
    _library.reset();
    _tabs.reset();
    _unsubscribeFromProfile();
    _notifications.unsubscribe();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    _isLoggingOut = false;
    notifyListeners();

    // 3. Navigate after all cleanup is fully complete
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void updateTabIndex(int index, {bool addToHistory = true}) {
    _tabs.updateTabIndex(index, addToHistory: addToHistory);
  }

  Future<void> fetchLatestProfile() async {
    if (!_isLoggedIn) return;
    try {
      final lastSync = await SessionCacheService.instance.getLastProfileSync();
      final now = DateTime.now();

      if (lastSync != null && now.difference(lastSync).inMinutes < 10) {
        debugPrint(
          '[AppProvider] Silent profile sync skipped (interval threshold not met).',
        );
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      debugPrint('[AppProvider] Starting silent background sync...');
      final dbProfile = await SchemeRepository.instance.getProfile(user.id);

      if (dbProfile != null) {
        var syncProfile = dbProfile;
        if (syncProfile.profilePhoto.isEmpty ||
            syncProfile.profilePhoto.contains('user_avatar.webp')) {
          final currentPhoto = _profile.profilePhoto;
          if (currentPhoto.isNotEmpty &&
              !currentPhoto.contains('user_avatar.webp')) {
            syncProfile = syncProfile.copyWith(profilePhoto: currentPhoto);
          } else {
            final googlePhoto = extractGooglePhoto(user);
            if (googlePhoto.isNotEmpty) {
              syncProfile = syncProfile.copyWith(profilePhoto: googlePhoto);
            }
          }
        }

        final remoteUpdated =
            syncProfile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localUpdated =
            _profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        if (remoteUpdated.isAfter(localUpdated)) {
          _profile = syncProfile;
          _selectedLanguage = _languageReconciler.reconcile(
            syncProfile.language,
          );
          _profile = _profile.copyWith(language: _selectedLanguage);
          _navigationMode = syncProfile.navigationMode;
          await SessionCacheService.instance.saveProfile(_profile);
          notifyListeners();
          debugPrint(
            '[AppProvider] Silent background sync updated local profile.',
          );
        } else {
          debugPrint('[AppProvider] Stale remote profile skipped during sync.');
        }
      }
      await SessionCacheService.instance.updateLastProfileSync();
    } catch (e) {
      debugPrint('[AppProvider] Error during background sync: $e');
    }
  }

  bool get hasTabHistory => _tabs.hasTabHistory;

  bool popTabIndex() => _tabs.popTabIndex();

  void toggleBookmark(String id) => _library.toggleBookmark(id);

  void addToRecentlyViewed(String id) => _library.addToRecentlyViewed(id);

  Future<void> saveEligibilityResults(List<String> schemeIds) async {
    await _library.saveEligibilityResults(schemeIds);

    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        unawaited(
          Supabase.instance.client
              .from('profiles')
              .update({
                'saved_eligibility_schemes':
                    _library.savedEligibilitySchemeIds,
                'last_eligibility_saved_at': _library.lastEligibilitySavedAt!
                    .toIso8601String(),
              })
              .eq('id', user.id)
              .catchError((e) {
                debugPrint('[AppProvider] Remote eligibility sync notice: $e');
              }),
        );
      }
    }
  }

  // Search & Filter Operations — delegate to SearchFilterController.
  void updateSearchQuery(String query) => _searchFilter.updateSearchQuery(query);

  void updateFilter(String key, dynamic value) =>
      _searchFilter.updateFilter(key, value);

  void clearFilters() => _searchFilter.clearFilters();

  // Notification actions — delegate to NotificationsController.
  Future<void> markNotificationRead(String id) =>
      _notifications.markNotificationRead(id);

  Future<void> markAllNotificationsRead() =>
      _notifications.markAllNotificationsRead();

  Future<void> deleteAllNotifications() =>
      _notifications.deleteAllNotifications();

  Future<void> deleteNotifications(List<String> ids) =>
      _notifications.deleteNotifications(ids);

  Future<void> markNotificationsRead(List<String> ids) =>
      _notifications.markNotificationsRead(ids);

  // Completion calculation — delegates to pure functions in
  // controllers/profile_completion.dart.
  int get profileCompletionPercentage =>
      profile_completion.calculateProfileCompletionPercentage(_profile);

  List<String> get missingProfileSections =>
      profile_completion.calculateMissingProfileSections(_profile);

  Future<void> updateProfile(
    UserProfile updated, {
    bool requireCloudSync = false,
  }) async {
    final candidate = updated.copyWith(updatedAt: DateTime.now());

    // A completed onboarding submission is not committed locally until the
    // hosted database confirms both profile upserts. This prevents a restart
    // from bypassing onboarding after a failed or offline cloud write.
    if (requireCloudSync) {
      await _syncProfileToSupabase(candidate);
    }

    _profile = candidate;

    // Recalculate recommendations based on updated profile
    _catalog.recomputeRecommendations(_profile);

    notifyListeners();
    await _saveProfile();

    if (!requireCloudSync) {
      _syncProfileToSupabaseInBackground(_profile);
    }
  }

  Future<void> updateProfilePhoto(String path) async {
    final trimmed = path.trim();
    // If removing custom photo, reset back to Google account photo as default
    final newPhoto = trimmed.isEmpty
        ? extractGooglePhoto(Supabase.instance.client.auth.currentUser)
        : trimmed;
    _profile = _profile.copyWith(
      profilePhoto: newPhoto,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveProfile();

    _syncProfileToSupabaseInBackground(_profile);
  }

  // Promo carousel content — delegate to PromoContentController.
  Future<void> fetchPromoAlerts({bool force = false}) =>
      _promos.fetchPromoAlerts(force: force);

  Future<void> fetchDraftSessions({bool force = false}) =>
      _promos.fetchDraftSessions(force: force);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.removeListener(notifyListeners);
    _tabs.dispose();
    _library.removeListener(notifyListeners);
    _library.dispose();
    _searchFilter.removeListener(notifyListeners);
    _searchFilter.dispose();
    _notifications.removeListener(notifyListeners);
    _notifications.dispose();
    _promos.removeListener(notifyListeners);
    _promos.dispose();
    _catalog.removeListener(notifyListeners);
    _catalog.dispose();
    _unsubscribeFromProfile();
    super.dispose();
  }
}
