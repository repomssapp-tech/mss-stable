import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import '../services/recommendation/recommendation_engine.dart';
import '../services/account/account_api_service.dart';
import '../services/account/app_session.dart';
import '../services/account/auth_service.dart';
import '../services/account/google_identity.dart';
import '../services/catalog/scheme_id_migration.dart';
import '../services/catalog/catalog_refresh_scheduler.dart';
import '../services/library/library_sync_service.dart';
import '../services/chat/chat_log_service.dart';
import '../services/network/connectivity_service.dart';
import '../services/network/debouncer.dart';
import '../services/network/request_manager.dart';
import '../services/catalog/content_language_resolver.dart';
import '../services/catalog/scheme_catalog_sync_service.dart';
import '../services/account/session_cache_service.dart';
import '../services/catalog/centralized_translator.dart';
import '../services/catalog/language_pack_manager.dart';
import '../screens/splash_screen.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/account_deletion_dialogs.dart';
import '../l10n/l10n.dart';
import '../screens/notifications/push_message_presenter.dart'
    show appNavigatorKey;
import '../services/account/account_pending_deletion.dart';
import 'app_state_seed_data.dart';
import 'controllers/language_reconciler.dart';
import 'controllers/library_controller.dart';
import 'controllers/navigation_mode_reconciler.dart';
import 'controllers/notification_translation_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/profile_cloud_sync.dart' as profile_cloud_sync;
import 'controllers/push_controller.dart';
import 'controllers/profile_completion.dart' as profile_completion;
import 'controllers/promo_content_controller.dart';
import 'controllers/scheme_catalog_controller.dart';
import 'controllers/search_filter_controller.dart';
import 'controllers/tab_navigation_controller.dart';
import '../services/account/deep_link_service.dart';
import '../services/notifications/push_models.dart' show PushMessagingGateway;
import '../models/user_profile_api_dto.dart'
    show ProfileAggregate, serverLanguages;
import '../services/analytics/app_analytics.dart';
import '../services/account/onboarding_api_service.dart'
    show LegalConsentStore, OnboardingApiService;
import '../services/account/profile_api_service.dart';
import '../services/account/rest_auth_service.dart';
import '../services/account/token_storage.dart';
import '../config/edition.dart';
import '../services/location_lock/location_lock.dart';

bool _runningUnderTest() {
  try {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  /// [startBackgroundSchedulers] runs the 30-minute catalog timer. It is off by
  /// default under `flutter test` (a pending timer fails widget tests); a test
  /// of the scheduling itself turns it on.
  AppProvider({
    SchemeCatalogSyncService? catalogSyncService,
    bool? startBackgroundSchedulers,
    PushMessagingGateway? pushGateway,
  }) : _startSchedulers = startBackgroundSchedulers ?? !_runningUnderTest(),
       _catalog = SchemeCatalogController(
         catalogSyncService: catalogSyncService,
       ) {
    WidgetsBinding.instance.addObserver(this);
    // _tabs is deliberately not forwarded: a tab tap would rebuild every
    // screen that listens to AppProvider (all five tabs stay mounted). The
    // shell listens to [tabChanges] instead.
    _library.addListener(notifyListeners);
    _searchFilter.addListener(notifyListeners);
    _notifications.addListener(notifyListeners);
    _notificationTranslation.addListener(notifyListeners);
    _promos.addListener(notifyListeners);
    _catalog.addListener(notifyListeners);
    _lockedStateCode = LocationScope.current.value?.stateCode;
    LocationScope.current.addListener(_onLocationLockChanged);
    DeepLinkService.instance.initialize(this);
    _loadState();
    _setupAuthListener();
    if (pushGateway != null) {
      _push = PushController(
        gateway: pushGateway,
        refreshInbox: () => _notifications.refresh(force: true),
        languageCode: () => _selectedLanguage,
      );
      unawaited(_push!.start());
    }
    _connectivitySubscription = ConnectivityService.instance.onChanged.listen((
      online,
    ) {
      if (online) _reconnectCatchUp.run(_catchUpAfterReconnect);
    });
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

  /// In-app notifications list (REST inbox) and its
  /// read/delete mutations, forwarded through this provider's own
  /// `notifyListeners` (frontend refactor C1.4).
  final NotificationsController _notifications = NotificationsController();
  final NotificationTranslationController _notificationTranslation =
      NotificationTranslationController();

  /// Push notifications (FCM registration + display); null where the platform
  /// has no messaging SDK.
  PushController? _push;

  /// Home-screen promo carousel source data (`/v1/promotions` cards + in-progress
  /// draft sessions) and its fetch throttles, forwarded through this provider's
  /// own `notifyListeners` (frontend refactor C1.4). The profile-derived
  /// `carouselItems` getter stays here.
  final PromoContentController _promos = PromoContentController();
  final bool _startSchedulers;
  StreamSubscription<AuthChange>? _authSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  /// Looks for a newer scheme catalog: at every start, every 30 minutes of
  /// active use, and on foreground / reconnect (at most once a minute).
  late final CatalogRefreshScheduler _catalogScheduler =
      CatalogRefreshScheduler(check: () => syncSchemeCatalog(force: true));

  /// Keeps bookmarks and saved eligibility results in step with the server
  /// (queued, batched, pulled rarely); the device copy always works offline.
  late final LibrarySyncService _librarySync = LibrarySyncService(
    host: _library,
  );

  // Profile edits are coalesced: a burst of changes becomes one request.
  final Debouncer _profileSync = Debouncer(const Duration(seconds: 2));
  UserProfile? _pendingProfile;
  String? _pendingProfileOwner;

  // A flapping network triggers one catch-up, not one per flip.
  final Debouncer _reconnectCatchUp = Debouncer(const Duration(seconds: 3));
  bool _isLoggedIn = false;
  // Guest mode (DEV 1 task 1.5): browsing without an account. Persisted with
  // SessionCacheService.saveIsGuest; a real session always wins over it.
  bool _isGuest = false;
  bool _uploadingGuestProfile = false;
  bool _isLoggingOut = false;
  String _mobileNumber = '';
  String _selectedLanguageValue = kEdition.defaultLanguage;
  String get _selectedLanguage => _selectedLanguageValue;
  // Every language change also tells CentralizedTranslator which language the
  // static UI text (localize()/localizeTag()) should be shown in.
  set _selectedLanguage(String value) {
    // Location lock: a language the GPS state does not offer (cache, server
    // profile, deep link) falls back to English.
    value = LocationScope.clampLanguage(value);
    _selectedLanguageValue = value;
    CentralizedTranslator.instance.activeLanguage = value;
  }

  // Ignores a server language value that contradicts a just-made explicit
  // changeLanguage() choice for a short window (a realtime echo or a
  // not-yet-updated profile row can still carry the OLD language briefly).
  final LanguageReconciler _languageReconciler = LanguageReconciler();
  final NavigationModeReconciler _navigationModeReconciler =
      NavigationModeReconciler();
  String _navigationMode = 'regular'; // 'regular', 'companion'
  UserProfile _profile = UserProfile();

  /// The inbox in the user's language (Google ML Kit on-device translation);
  /// a notification shows its original text until its translation is ready.
  List<Map<String, dynamic>> get notifications => _notificationTranslation.view(
    _notifications.notifications,
    _selectedLanguage,
  );

  int get unreadNotificationCount => _notifications.unreadCount;
  bool get notificationReadSyncPending => _notifications.readSyncPending;

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

  /// Follows sign-in / sign-out of the backend session. Profile hydration after
  /// sign-in is done by [checkSessionAndFetchProfile], which the login flows
  /// (deep-link code exchange, password login) call once the tokens are saved.
  void _setupAuthListener() {
    _authSubscription = AppSession.instance.changes.listen((change) {
      switch (change) {
        case AuthChange.signedIn:
          // Auth resolved -- retire the startup grace marker for OAuth redirects.
          unawaited(AuthService.clearOAuthPending());
          final fromGuest = _isGuest;
          _isLoggedIn = true;
          AppAnalytics.instance.endSession();
          AppAnalytics.instance.track(
            AnalyticsEvent.signInCompleted,
            properties: {'from_guest': fromGuest},
          );
          if (_isGuest) unawaited(_endGuestSession(upgradedToAccount: true));
          final user = AppSession.instance.currentUser;
          if (user != null) _notifications.subscribe(user.id);
          notifyListeners();
        case AuthChange.signedOut:
          AppAnalytics.instance.endSession();
          unawaited(AuthService.clearOAuthPending());
          _isLoggedIn = false;
          _isGuest = false;
          _mobileNumber = '';
          _profile = UserProfile();
          _library.reset();
          _tabs.resetIndexOnly();
          // reset() also clears the fetch-throttle stamps, or the next account to
          // sign in on this device would be served the previous user's empty
          // state until the throttle window expired.
          _promos.reset();
          _notifications.reset();
          ProfileApiService.instance.clear();
          _profileSync.cancel();
          _pendingProfile = null;
          _pendingProfileOwner = null;
          unawaited(_librarySync.reset());
          unawaited(LegalConsentStore.clear());
          unawaited(SessionCacheService.instance.saveGuestUploadPending(false));
          RequestManager.instance.reset();
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

  /// Sets the profile without syncing it or recomputing recommendations, so a
  /// test can pair it with [setRecommendedSchemesForTesting].
  @visibleForTesting
  void setProfileForTesting(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  @visibleForTesting
  void setRecommendedSchemesForTesting(
    List<MapEntry<Scheme, RecommendationResult>> schemes,
  ) => _catalog.setRecommendedSchemesForTesting(schemes);

  @visibleForTesting
  void setAllSchemesForTesting(List<Scheme> schemes) =>
      _catalog.setAllSchemesForTesting(schemes);

  /// Browsing without an account. Never true while a session exists.
  bool get isGuest => _isGuest && !_isLoggedIn;

  /// Enters guest mode: schemes, search and eligibility work from the on-device
  /// catalog, answers stay on this phone, and saving, notifications and profile
  /// sync ask the user to sign in (see `requireAccount`).
  Future<void> continueAsGuest() async {
    if (_isLoggedIn) return;
    _isGuest = true;
    notifyListeners();
    await SessionCacheService.instance.saveIsGuest(true);
  }

  /// Leaves guest mode. After sign-in the merged guest profile is
  /// marked for one upload to the new account (see [_uploadGuestProfile]).
  Future<void> _endGuestSession({required bool upgradedToAccount}) async {
    _isGuest = false;
    final cache = SessionCacheService.instance;
    // Marker first, so a crash between the two writes can only retry the
    // upload, never lose it.
    if (upgradedToAccount) await cache.saveGuestUploadPending(true);
    await cache.saveIsGuest(false);
  }

  /// Syncs the merged guest profile once after sign-in. Questionnaire
  /// answers remain on the device until a separate transfer is implemented.
  Future<void> _uploadGuestProfile() async {
    final owner = AppSession.instance.userId;
    if (owner == null || _uploadingGuestProfile) return;
    _uploadingGuestProfile = true;
    final cache = SessionCacheService.instance;
    try {
      if (!await cache.getGuestUploadPending() ||
          AppSession.instance.userId != owner) {
        return;
      }
      await _syncProfileToServer(_profile);
      if (AppSession.instance.userId == owner) {
        await cache.saveGuestUploadPending(false);
      }
    } catch (error) {
      debugPrint('[AppProvider] Guest profile upload deferred: $error');
    } finally {
      _uploadingGuestProfile = false;
    }
  }

  bool get isLoggingOut => _isLoggingOut;
  String get mobileNumber => _mobileNumber;
  String get selectedLanguage => _selectedLanguage;
  String get navigationMode => _navigationMode;
  int get currentTabIndex => _tabs.currentTabIndex;

  /// Notifies on [updateTabIndex] / [popTabIndex]. Those do not notify
  /// AppProvider listeners.
  Listenable get tabChanges => _tabs;
  UserProfile get profile => _profile;

  /// Returns the effective profile photo URL or local file path.
  /// Priority:
  /// 1. Custom photo chosen by user (valid local file from gallery/camera or non-Google custom URL).
  /// 2. Google OAuth profile photo of the signed-in account.
  /// 3. Empty string (falls back to local avatar illustration asset).
  String get effectiveProfilePhoto {
    final photo = _profile.profilePhoto.trim();
    if (photo.isNotEmpty && !photo.contains('user_avatar.webp')) {
      if ((photo.startsWith('http://') || photo.startsWith('https://')) &&
          hasCustomPhoto) {
        return photo;
      }
      if (File(photo).existsSync()) {
        return photo;
      }
    }
    // No custom photo: show the Google account picture, unless it is Google's
    // generated placeholder (an old "J" letter avatar, issue #145) -- then the
    // profile name's initial is shown instead.
    final google = extractGooglePhoto(AppSession.instance.currentUser);
    final fromProfile = photo.startsWith('https://') ? photo : '';
    final candidate = google.startsWith('https://') ? google : fromProfile;
    if (candidate.isEmpty || candidate.contains('/default-user')) return '';
    return candidate;
  }

  /// Returns true if the user has uploaded/picked a custom profile photo.
  bool get hasCustomPhoto {
    final photo = _profile.profilePhoto.trim();
    if (photo.isEmpty || photo.contains('user_avatar.webp')) return false;
    if (File(photo).existsSync()) return true;
    final google = extractGooglePhoto(AppSession.instance.currentUser);
    return photo.startsWith('http') && photo != google;
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
  // A guest gets no recommendations or match scores, even with their own details filled in.
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes =>
      isGuest ? const [] : _catalog.recommendedSchemes;

  // Bookmarked schemes list
  List<Scheme> get bookmarkedSchemes {
    final ids = _library.bookmarkedIds;
    return _catalog.allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  // Recently viewed schemes list
  /// Most recently viewed first (the stored id order), not catalog order.
  List<Scheme> get recentlyViewedSchemes {
    final all = _catalog.allSchemes;
    final out = <Scheme>[];
    for (final id in _library.recentlyViewedIds) {
      for (final s in all) {
        if ((s.id == id || s.schemeCode == id) && !out.contains(s)) {
          out.add(s);
          break;
        }
      }
    }
    return out;
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
    // Pre-2026 ids (SCH######, TN001...) -> 2026 ids, and drop saved items whose
    // scheme left the catalog.
    _library.migrateLegacyIds(await SchemeIdMigration.load(), {
      for (final s in _catalog.allSchemes) s.id,
    });
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
    // The one lifecycle observer: schedulers and pollers are driven from here.
    _catalogScheduler.didChangeAppLifecycleState(state);
    _notifications.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) unawaited(_push?.onAppResumed());
    if (state == AppLifecycleState.paused) {
      unawaited(_profileSync.flush());
      unawaited(_librarySync.flush());
    } else if (state == AppLifecycleState.resumed) {
      // Each is guarded by its own freshness window: usually a no-op.
      unawaited(fetchPromoAlerts());
      unawaited(_librarySync.pull());
    }
  }

  /// Work that was waiting for a network: queued chat sessions and any profile
  /// edit that could not be sent. Notifications and the catalog catch up on
  /// their own (their pollers react to the reconnect).
  Future<void> _catchUpAfterReconnect() async {
    unawaited(ChatLogService.syncPendingOfflineQueue());
    unawaited(_librarySync.flush());
    unawaited(_librarySync.pull());
    await _profileSync.flush();
  }

  // Load state from SharedPreferences (for session continue support)
  Future<void> _loadState() async {
    try {
      _selectedLanguage =
          await SessionCacheService.instance.getLanguage() ??
          kEdition.defaultLanguage;
      // Started now (it overlaps the other hydration) but awaited before the
      // first scheme load below, so a cold start in Hindi/Tamil adapts the
      // catalog with the pack already indexed instead of showing English.
      final startupPack = _selectedLanguage != 'en'
          ? LanguagePackManager.instance.loadPack(_selectedLanguage)
          : Future<void>.value();
      await _tabs.hydrate();

      final cachedProfile = await SessionCacheService.instance.loadProfile();
      if (cachedProfile != null) {
        _profile = withLockedState(cachedProfile);
        _navigationMode = _profile.navigationMode;
      }
      final cachedNavMode = await SessionCacheService.instance
          .getNavigationMode();
      if (cachedNavMode != null && cachedNavMode.isNotEmpty) {
        _navigationMode = cachedNavMode;
      }

      await _library.hydrate();

      // Restore the signed-in account (the stored backend session).
      await AppSession.instance.hydrate();
      final sessionUser = AppSession.instance.currentUser;
      if (sessionUser != null) {
        debugPrint('[AppProvider] Active MSS session found during _loadState');
        _isLoggedIn = true;
        // A session beats a guest flag left behind (e.g. killed mid sign-in).
        if (_isGuest || await SessionCacheService.instance.getIsGuest()) {
          await _endGuestSession(upgradedToAccount: true);
        }
        _notifications.subscribe(sessionUser.id);
        fetchPromoAlerts();
        fetchDraftSessions();
        unawaited(_librarySync.pull());
        unawaited(_uploadGuestProfile());
      } else {
        debugPrint('[AppProvider] No active session found during _loadState.');
        _isGuest = await SessionCacheService.instance.getIsGuest();
      }

      notifyListeners();

      // Render local data first, then refresh the published snapshot silently.
      await startupPack;
      await loadSchemes();
      // The local catalog is already in use; now look for a newer one.
      if (_startSchedulers) _catalogScheduler.start();
      unawaited(_catalogScheduler.checkOnStart());
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  // Save state helpers
  Future<void> _saveProfile() async {
    await SessionCacheService.instance.saveProfile(_profile);
  }

  Future<void> _syncProfileToServer(
    UserProfile profileToSync, {
    bool requireOnboardingCompletion = false,
  }) => profile_cloud_sync.syncProfileToServer(
    profileToSync,
    isLoggedIn: _isLoggedIn,
    requireOnboardingCompletion: requireOnboardingCompletion,
  );

  /// Sends the latest profile in the background, [Debouncer] seconds after the
  /// last edit. A failed send is kept and retried when the network returns.
  void _syncProfileToServerInBackground(UserProfile profileToSync) {
    // Signed out: there is no account to send it to, so nothing is queued.
    if (!_isLoggedIn) return;
    _pendingProfile = profileToSync;
    _pendingProfileOwner = AppSession.instance.userId;
    _profileSync.run(_flushProfileSync);
  }

  Future<void> _flushProfileSync() async {
    final profile = _pendingProfile;
    final owner = _pendingProfileOwner;
    if (profile == null) return;
    _pendingProfile = null;
    // An edit made under another account (or after sign-out) is never sent.
    if (owner == null || owner != AppSession.instance.userId) return;
    try {
      await _syncProfileToServer(profile);
      // The server now holds this mode, so it is the source of truth again.
      if (profile.navigationMode == _navigationMode) {
        await SessionCacheService.instance.setNavigationModePending(false);
      }
    } catch (error) {
      debugPrint('[AppProvider] Background profile sync failed: $error');
      _pendingProfile ??= profile;
      _pendingProfileOwner ??= owner;
    }
  }

  /// The language to use after reading the server profile. A language the
  /// profile API cannot hold is never replaced by what the server reports;
  /// otherwise the usual reconciliation applies.
  ///
  /// A profile that is not complete yet (a brand-new account) only carries the
  /// server's default language, not a choice the user made, so the language
  /// picked before signing in stays.
  String _languageFromServer(
    String serverLang, {
    required bool serverProfileCompleted,
  }) {
    if (!serverLanguages.contains(_selectedLanguage)) return _selectedLanguage;
    if (!serverProfileCompleted) {
      _languageReconciler.markPending(_selectedLanguage);
      return _selectedLanguage;
    }
    final resolved = _languageReconciler.reconcile(serverLang);
    // A code the app has no interface for only counts while the release has it
    // switched on; otherwise the server value must not change scheme content.
    return LanguagePackManager.hasUiStrings(resolved) ||
            LanguagePackManager.instance.isLanguageActiveInRelease(resolved)
        ? resolved
        : _selectedLanguage;
  }

  @visibleForTesting
  void debugMarkLanguagePending(String lang) =>
      _languageReconciler.markPending(lang);

  @visibleForTesting
  String debugReconcileServerLanguage(String serverLang) =>
      _languageReconciler.reconcile(serverLang);

  String? _lockedStateCode;

  /// Location lock: the profile's state always comes from GPS. Address,
  /// city, district and pincode stay the user's to edit.
  static UserProfile withLockedState(UserProfile p) {
    final state = LocationScope.stateName;
    if (state == null || p.state == state) return p;
    return p.copyWith(state: state);
  }

  /// A new GPS state: reload schemes for it, drop a language it does not
  /// offer and put the state in the profile. A re-check that finds the same
  /// state changes nothing.
  void _onLocationLockChanged() {
    final code = LocationScope.current.value?.stateCode;
    if (code == _lockedStateCode) return;
    _lockedStateCode = code;
    unawaited(_applyLocationLock());
  }

  Future<void> _applyLocationLock() async {
    final clamped = LocationScope.clampLanguage(_selectedLanguage);
    if (clamped != _selectedLanguage) {
      _selectedLanguage = clamped;
      await SessionCacheService.instance.saveLanguage(clamped);
    }
    final locked = withLockedState(_profile);
    if (!identical(locked, _profile)) {
      _profile = locked.copyWith(
        language: _selectedLanguage,
        updatedAt: DateTime.now(),
      );
      await _saveProfile();
      if (_isLoggedIn) _syncProfileToServerInBackground(_profile);
    }
    notifyListeners();
    await loadSchemes(forceRefresh: true);
  }

  // Setters & Actions
  int _languageChangeGeneration = 0;

  Future<void> changeLanguage(String requested) async {
    // A language needs ARB resources or an offer from the catalogue release. One
    // that only the catalogue offers shows its scheme content with an English
    // interface (MaterialApp resolves its locale to English). Any other code
    // (e.g. `mr` from a server profile, while the release keeps it off) is
    // ignored.
    final lang = ContentLanguageResolver.normalizeCode(requested);
    if (LocationScope.clampLanguage(lang) != lang) {
      debugPrint('[AppProvider] "$lang" is not offered in this state');
      return;
    }
    if (!LanguagePackManager.hasUiStrings(lang) &&
        !(await LanguagePackManager.instance.offeredLanguages()).contains(
          lang,
        )) {
      debugPrint('[AppProvider] ignoring unsupported language "$requested"');
      return;
    }
    final generation = ++_languageChangeGeneration;
    _selectedLanguage = lang;
    _languageReconciler.markPending(lang);
    _profile = _profile.copyWith(language: lang, updatedAt: DateTime.now());
    notifyListeners();
    await SessionCacheService.instance.saveLanguage(lang);
    if (lang != 'en') {
      await LanguagePackManager.instance.loadPack(lang);
    }
    if (generation != _languageChangeGeneration) return;
    await loadSchemes();
    notifyListeners();
    await _saveProfile();

    _syncProfileToServerInBackground(_profile);
    // Promo card text is served in the chosen language.
    unawaited(fetchPromoAlerts(force: true));
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
    await SessionCacheService.instance.setNavigationModePending(true);
    await SessionCacheService.instance.saveProfile(_profile);

    _syncProfileToServerInBackground(_profile);
  }

  Future<bool> loginWithGoogle() async {
    try {
      return await AuthService.signInWithGoogle();
    } catch (e) {
      debugPrint('[AppProvider] Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<bool> loginWithPassword(String email, String password) async {
    try {
      await RestAuthService.instance.loginWithPassword(
        email: email,
        password: password,
      );
      return await checkSessionAndFetchProfile();
    } on AccountPendingDeletion catch (pending) {
      return offerAccountRestore(pending);
    } catch (e) {
      debugPrint('[AppProvider] Error signing in with password: $e');
      rethrow;
    }
  }

  /// Tells the user the Google sign-in could not be completed (the code
  /// exchange failed), so they are not left on the login screen without a word.
  void reportSignInFailed() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      AppToast.showWarning(ctx, ctx.l10n.loginGoogleSignInFailed);
    }
  }

  /// A sign-in reached an account deleted within the last 30 days. Asks the
  /// user whether to reactivate it and, only on their yes, restores it and
  /// loads the session. Returns true when the user ends up signed in.
  Future<bool> offerAccountRestore(AccountPendingDeletion pending) async {
    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) return false;
    if (!await confirmAccountRestore(context, pending)) return false;
    try {
      await RestAuthService.instance.restoreAccount(pending.restoreToken);
    } catch (e) {
      debugPrint('[AppProvider] Account restore failed: $e');
      final ctx = appNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        AppToast.showWarning(ctx, ctx.l10n.accountRestoreFailed);
      }
      return false;
    }
    final signedIn = await checkSessionAndFetchProfile();
    final ctx = appNavigatorKey.currentContext;
    if (signedIn && ctx != null && ctx.mounted) {
      AppToast.showSuccess(ctx, ctx.l10n.accountRestoredToast);
    }
    return signedIn;
  }

  /// Issue #123: the server marks a profile complete only once onboarding is
  /// submitted with the four legal acceptances. When those cannot be recorded
  /// (e.g. the server's LEGAL_DOCUMENT_VERSIONS is not configured) the profile
  /// fields are saved but the flag stays false, so every launch used to send
  /// the user back through onboarding. If the server lists no missing profile
  /// field (only consent is pending) and this copy has every required field,
  /// the profile counts as complete here and onboarding is retried in the
  /// background.
  UserProfile _withServerCompletion(
    UserProfile merged,
    ProfileAggregate server,
  ) {
    if (!completedPendingConsent(merged, server.missingFields)) return merged;
    final completed = merged.copyWith(profileCompleted: true);
    _syncProfileToServerInBackground(completed);
    return completed;
  }

  /// True when [profile] is not marked complete, yet the server's
  /// [serverMissingFields] name only legal consent and [profile] has every
  /// field onboarding requires.
  @visibleForTesting
  static bool completedPendingConsent(
    UserProfile profile,
    List<String> serverMissingFields,
  ) {
    if (profile.profileCompleted) return false;
    if (!profileFieldsCompleteOnServer(serverMissingFields)) return false;
    final fields = profile_cloud_sync.buildOnboardingProfile(profile);
    return profile_cloud_sync.missingOnboardingFields(fields).isEmpty;
  }

  /// True when [missingFields] names nothing but legal consent.
  @visibleForTesting
  static bool profileFieldsCompleteOnServer(List<String> missingFields) =>
      missingFields.every((f) {
        final k = f.toLowerCase();
        return k.contains('legal') ||
            k.contains('consent') ||
            k.contains('terms') ||
            k.contains('privacy');
      });

  Future<bool> checkSessionAndFetchProfile() async {
    await AppSession.instance.hydrate();
    if (!AppSession.instance.isSignedIn) {
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }

    try {
      final profileAggregate = await ProfileApiService.instance.loadProfile();
      final mappedProfile = profileAggregate.toUserProfile();
      _isLoggedIn = true;
      _profile = _withServerCompletion(
        _profile.mergeFrom(mappedProfile),
        profileAggregate,
      );
      _selectedLanguage = _languageFromServer(
        mappedProfile.language,
        serverProfileCompleted: mappedProfile.profileCompleted,
      );
      _profile = _profile.copyWith(language: _selectedLanguage);
      // A mode chosen on this device that the server hasn't confirmed yet wins
      // over the server copy; otherwise the server is the source of truth.
      final serverMode = mappedProfile.navigationMode;
      final localModePending = await SessionCacheService.instance
          .isNavigationModePending();
      if (localModePending &&
          _navigationMode.isNotEmpty &&
          serverMode != _navigationMode) {
        _profile = _profile.copyWith(navigationMode: _navigationMode);
        _syncProfileToServerInBackground(_profile);
      } else {
        _navigationMode = serverMode;
        if (localModePending) {
          await SessionCacheService.instance.setNavigationModePending(false);
        }
      }

      // Fall back to the Google account's name and photo while the server
      // profile does not have them yet.
      final account = AppSession.instance.currentUser;
      final googlePhoto = extractGooglePhoto(account);
      if ((_profile.profilePhoto.isEmpty ||
              _profile.profilePhoto.contains('user_avatar.webp')) &&
          googlePhoto.isNotEmpty) {
        _profile = _profile.copyWith(profilePhoto: googlePhoto);
      }
      if (_profile.name.trim().isEmpty &&
          extractGoogleName(account).isNotEmpty) {
        _profile = _profile.copyWith(name: extractGoogleName(account));
      }

      await SessionCacheService.instance.saveProfile(_profile);
      await SessionCacheService.instance.saveLanguage(_selectedLanguage);
      await SessionCacheService.instance.saveNavigationMode(_navigationMode);

      fetchPromoAlerts();
      fetchDraftSessions();
      unawaited(_librarySync.pull(force: true));
      // The merge above fills empty server fields from the local profile.
      unawaited(_uploadGuestProfile());
      // Turn the agreement given on the sign-in screen into recorded consent.
      unawaited(
        LegalConsentStore.recordFromLoginAgreement(
          OnboardingApiService.instance,
        ).catchError((Object e) {
          debugPrint('[AppProvider] Could not record consent: $e');
        }),
      );
      notifyListeners();
      return _profile.profileCompleted;
    } catch (e) {
      debugPrint('[AppProvider] checkSessionAndFetchProfile notice: $e');
      _isLoggedIn = AppSession.instance.isSignedIn;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    debugPrint('[AppProvider] logout initiated...');
    _isLoggingOut = true;
    notifyListeners();

    // 1. Perform cleanup and await asynchronous operations
    // The interface language is a choice about this device, not the account:
    // signing out must not flip a Tamil or Hindi user back to English on the
    // login screen.
    final keptLanguage = _selectedLanguage;
    _isLoggedIn = false;
    // clearSession() below wipes the stored flag; this clears the in-memory
    // one, so sign-out always lands on the login screen, never in guest mode.
    _isGuest = false;
    _mobileNumber = '';
    _languageReconciler.reset();
    _navigationMode = 'regular';
    _navigationModeReconciler.reset();
    _profile = UserProfile(language: keptLanguage);
    _library.reset();
    _tabs.reset();

    // Revoke the session on the server first: POST /auth/logout needs the
    // bearer token, so clearing local tokens before it sent an anonymous
    // request and left the session (and its tokens) valid on the server.
    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }

    await SessionCacheService.instance.clearSession(
      preserveQuestionnaireAnswers: true,
    );
    await SessionCacheService.instance.saveLanguage(keptLanguage);
    await TokenStorage.instance.clearTokens();

    _isLoggingOut = false;
    notifyListeners();

    // 2. Navigate after cleanup is fully complete
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  /// Step 1 of deleting the account: the server deletes it and then confirms
  /// that it no longer knows it. Nothing on this phone is touched, so a refusal
  /// (offline, session too old, rate limit) leaves the account exactly as it
  /// was and the user can try again.
  Future<AccountDeletionOutcome> requestAccountDeletion({
    VoidCallback? onVerifying,
  }) async {
    debugPrint('[AppProvider] requestAccountDeletion...');
    if (!(_isLoggedIn && AppSession.instance.isSignedIn)) {
      return AccountDeletionOutcome.reauthRequired;
    }
    _isLoggingOut = true;
    notifyListeners();
    try {
      return await AccountApiService.instance.deleteAndVerify(
        onVerifying: onVerifying,
      );
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Step 2, after the server confirmed the deletion: forget the account on
  /// this phone.
  Future<void> completeAccountDeletion() async {
    debugPrint('[AppProvider] completeAccountDeletion...');
    _isLoggingOut = true;
    notifyListeners();

    // Local state cleanup (the account is already gone on the server).
    _isLoggedIn = false;
    _isGuest = false;
    _mobileNumber = '';
    _selectedLanguage = kEdition.defaultLanguage;
    _languageReconciler.reset();
    _navigationMode = 'regular';
    _navigationModeReconciler.reset();
    _profile = UserProfile();
    _library.reset();
    _tabs.reset();
    _notifications.unsubscribe();

    await SessionCacheService.instance.clearSession();

    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[AppProvider] Error during AuthService.signOut(): $e');
    }
    // Whatever the call above did, no token may stay on this phone.
    await TokenStorage.instance.clearTokens();

    _isLoggingOut = false;
    notifyListeners();
    // The deleting screen then shows its result and moves to the login screen.
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

      final user = AppSession.instance.currentUser;
      if (user == null) return;

      debugPrint('[AppProvider] Starting silent background sync...');
      final syncAggregate = await ProfileApiService.instance.loadProfile();
      var syncProfile = syncAggregate.toUserProfile();

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
        _profile = withLockedState(
          _withServerCompletion(_profile.mergeFrom(syncProfile), syncAggregate),
        );
        _selectedLanguage = _languageFromServer(
          syncProfile.language,
          serverProfileCompleted: syncProfile.profileCompleted,
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
      await SessionCacheService.instance.updateLastProfileSync();
    } catch (e) {
      debugPrint('[AppProvider] Error during background sync: $e');
    }
  }

  bool get hasTabHistory => _tabs.hasTabHistory;

  bool popTabIndex() => _tabs.popTabIndex();

  void toggleBookmark(String id) {
    final wasSaved = bookmarkedIds.contains(id);
    _library.toggleBookmark(id);
    final isSaved = bookmarkedIds.contains(id);
    if (wasSaved != isSaved) {
      AppAnalytics.instance.track(
        AnalyticsEvent.schemeAction,
        properties: {'scheme_id': id, 'action': isSaved ? 'saved' : 'unsaved'},
      );
    }
    unawaited(
      _librarySync.recordFavorite(
        id,
        saved: _library.bookmarkedIds.contains(id),
      ),
    );
  }

  void addToRecentlyViewed(String id) => _library.addToRecentlyViewed(id);

  void removeFromRecentlyViewed(String id) =>
      _library.removeFromRecentlyViewed(id);

  Future<void> saveEligibilityResults(List<String> schemeIds) async {
    // Kept on the device. The REST profile API has no field for saved
    // eligibility results yet (see lib/services/backend/pending_endpoints.dart).
    await _library.saveEligibilityResults(schemeIds);
    unawaited(_librarySync.recordEligibility(schemeIds));
  }

  // Search & Filter Operations — delegate to SearchFilterController.
  void updateSearchQuery(String query) =>
      _searchFilter.updateSearchQuery(query);

  void updateFilter(String key, dynamic value) {
    final previous = filters[key];
    _searchFilter.updateFilter(key, value);
    if (previous == value ||
        (previous is List && value is List && listEquals(previous, value))) {
      return;
    }
    if (const {
      'category',
      'ministry',
      'state',
      'schemeTypes',
      'beneficiaries',
      'coverage',
    }.contains(key)) {
      AppAnalytics.instance.track(
        AnalyticsEvent.filterChanged,
        properties: {
          'filter_key': switch (key) {
            'schemeTypes' => 'scheme_types',
            _ => key,
          },
          'enabled': switch (value) {
            List items => items.isNotEmpty,
            String text => text.isNotEmpty && text != 'All',
            bool flag => flag,
            _ => false,
          },
        },
      );
    }
  }

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
    final candidate = withLockedState(
      updated,
    ).copyWith(updatedAt: DateTime.now());

    // A completed onboarding submission is not committed locally until the
    // hosted database confirms both profile upserts. This prevents a restart
    // from bypassing onboarding after a failed or offline cloud write.
    // A guest's profile stays on this phone until they sign in; it is sent
    // then by _uploadGuestProfile.
    if (requireCloudSync && !isGuest) {
      await _syncProfileToServer(
        candidate,
        requireOnboardingCompletion:
            candidate.profileCompleted && !_profile.profileCompleted,
      );
      // This save is newer than any queued background draft, which must not
      // be sent after it.
      _pendingProfile = null;
    }

    _profile = candidate;

    // Recalculate recommendations based on updated profile
    _catalog.recomputeRecommendations(_profile);

    notifyListeners();
    await _saveProfile();

    if (!requireCloudSync) {
      _syncProfileToServerInBackground(_profile);
    }
  }

  Future<void> updateProfilePhoto(String path) async {
    final trimmed = path.trim();
    // If removing custom photo, reset back to Google account photo as default
    final newPhoto = trimmed.isEmpty
        ? extractGooglePhoto(AppSession.instance.currentUser)
        : trimmed;
    _profile = _profile.copyWith(
      profilePhoto: newPhoto,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _saveProfile();

    _syncProfileToServerInBackground(_profile);
  }

  // Promo carousel content — delegate to PromoContentController.
  Future<void> fetchPromoAlerts({bool force = false}) =>
      _promos.fetchPromoAlerts(force: force, language: _selectedLanguage);

  Future<void> fetchDraftSessions({bool force = false}) =>
      _promos.fetchDraftSessions(force: force);

  @override
  void dispose() {
    LocationScope.current.removeListener(_onLocationLockChanged);
    unawaited(_push?.dispose());
    WidgetsBinding.instance.removeObserver(this);
    _tabs.removeListener(notifyListeners);
    _tabs.dispose();
    _library.removeListener(notifyListeners);
    _library.dispose();
    _searchFilter.removeListener(notifyListeners);
    _searchFilter.dispose();
    _notifications.removeListener(notifyListeners);
    _notifications.dispose();
    _notificationTranslation.dispose();
    _promos.removeListener(notifyListeners);
    _promos.dispose();
    _catalog.removeListener(notifyListeners);
    _catalog.dispose();
    _authSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _catalogScheduler.stop();
    _profileSync.cancel();
    _librarySync.dispose();
    _reconnectCatchUp.cancel();
    DeepLinkService.instance.dispose();
    super.dispose();
  }
}
