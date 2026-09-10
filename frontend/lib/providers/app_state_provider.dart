import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import '../engine/recommendation_engine.dart';
import '../services/account/auth_service.dart';
import '../services/account/google_identity.dart';
import '../services/catalog/scheme_repository.dart';
import '../services/catalog/scheme_catalog_sync_service.dart';
import '../services/account/session_cache_service.dart';
import '../screens/splash_screen.dart';
import '../widgets/common/app_toast.dart';
import 'app_state_seed_data.dart';
import 'controllers/library_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/promo_content_controller.dart';
import 'controllers/search_filter_controller.dart';
import 'controllers/tab_navigation_controller.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  AppProvider({SchemeCatalogSyncService? catalogSyncService})
    : _catalogSyncService =
          catalogSyncService ?? SchemeCatalogSyncService.instance {
    WidgetsBinding.instance.addObserver(this);
    _tabs.addListener(notifyListeners);
    _library.addListener(notifyListeners);
    _searchFilter.addListener(notifyListeners);
    _notifications.addListener(notifyListeners);
    _promos.addListener(notifyListeners);
    _loadState();
    _setupAuthListener();
  }

  final SchemeCatalogSyncService _catalogSyncService;

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
  // After an explicit changeLanguage(), the just-chosen value and when it was
  // set. A realtime echo or a not-yet-updated profile row can still carry the
  // OLD language for a moment; _reconcileServerLanguage() ignores a server
  // value that contradicts this choice within a short window.
  String? _pendingLanguage;
  DateTime? _pendingLanguageSince;
  String _navigationMode = 'regular'; // 'regular', 'companion'
  UserProfile _profile = UserProfile();

  // ── Scheme data (loaded from Supabase via SchemeRepository) ──────────
  List<Scheme> _allSchemes = [];
  List<MapEntry<Scheme, RecommendationResult>> _recommendedSchemes = [];
  bool _schemesLoading = false;
  String? _schemesError;
  CatalogSyncResult? _catalogSyncResult;
  bool _catalogSyncing = false;

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
                _selectedLanguage = _reconcileServerLanguage(
                  dbProfile.language,
                );
                _profile = _profile.copyWith(language: _selectedLanguage);
                _navigationMode = dbProfile.navigationMode;

                _recommendedSchemes = RecommendationEngine.getRecommendations(
                  _profile,
                  _allSchemes,
                );
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
            _selectedLanguage = _reconcileServerLanguage(dbProfile.language);
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
          if (_allSchemes.isNotEmpty) {
            _recommendedSchemes = RecommendationEngine.getRecommendations(
              _profile,
              _allSchemes,
            );
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

  bool _recommendationsOverriddenForTesting = false;

  @visibleForTesting
  void setRecommendedSchemesForTesting(
    List<MapEntry<Scheme, RecommendationResult>> schemes,
  ) {
    _recommendationsOverriddenForTesting = true;
    _recommendedSchemes = schemes;
    notifyListeners();
  }

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
    return _allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  String get searchQuery => _searchFilter.searchQuery;
  Map<String, dynamic> get filters => _searchFilter.filters;

  // Scheme loading state
  bool get schemesLoading => _schemesLoading;
  String? get schemesError => _schemesError;
  List<Scheme> get allSchemes => _allSchemes;
  CatalogSyncResult? get catalogSyncResult => _catalogSyncResult;
  bool get catalogSyncing => _catalogSyncing;
  String get catalogStatusLabel {
    final manifest = _catalogSyncResult?.manifest;
    if (manifest == null) return 'Bundled · ${_allSchemes.length} schemes';
    final date = manifest.publishedAt.toLocal();
    return 'v${manifest.version} · ${date.day}/${date.month}/${date.year}';
  }

  // Recommended schemes (ranked by RecommendationEngine against cached list)
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes =>
      _recommendedSchemes;

  // Bookmarked schemes list
  List<Scheme> get bookmarkedSchemes {
    final ids = _library.bookmarkedIds;
    return _allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  // Recently viewed schemes list
  List<Scheme> get recentlyViewedSchemes {
    final ids = _library.recentlyViewedIds;
    return _allSchemes
        .where((s) => ids.contains(s.id) || ids.contains(s.schemeCode))
        .toList();
  }

  // Load (or reload) all schemes and recompute recommendations
  Future<void> loadSchemes({bool forceRefresh = false}) async {
    if (_schemesLoading) return;
    if (forceRefresh) SchemeRepository.instance.clearCache();

    _schemesLoading = true;
    _schemesError = null;
    notifyListeners();

    try {
      _allSchemes = await SchemeRepository.instance.getAllSchemes(
        langCode: _selectedLanguage,
      );
      if (!_recommendationsOverriddenForTesting) {
        _recommendedSchemes = RecommendationEngine.getRecommendations(
          _profile,
          _allSchemes,
        );
      }
    } catch (e) {
      _schemesError = e.toString();
      debugPrint('[AppProvider] loadSchemes error: $e');
    } finally {
      _schemesLoading = false;
      notifyListeners();
    }
  }

  Future<CatalogSyncResult> syncSchemeCatalog({bool force = false}) async {
    if (_catalogSyncing) {
      return _catalogSyncResult ??
          const CatalogSyncResult(CatalogSyncOutcome.throttled);
    }
    _catalogSyncing = true;
    notifyListeners();
    CatalogSyncResult result;
    try {
      result = await _catalogSyncService.syncIfNeeded(force: force);
    } catch (error) {
      result = CatalogSyncResult(
        CatalogSyncOutcome.rejected,
        manifest: _catalogSyncResult?.manifest,
        message: error.toString(),
      );
    }
    _catalogSyncResult = result;
    _catalogSyncing = false;
    if (result.changed) {
      await loadSchemes(forceRefresh: true);
    } else {
      notifyListeners();
    }
    return result;
  }

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

  Future<void> _syncProfileToSupabase(UserProfile profileToSync) async {
    if (!_isLoggedIn) {
      throw StateError('Sign in is required before saving profile data.');
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw StateError('Your session expired. Please sign in again.');
    }

    final cloudProfile = profileToSync.copyWith(googleUserId: user.id);
    debugPrint('[AppProvider] Syncing profile to Supabase...');
    // Keep the completion flag false until every related cloud write succeeds.
    // The initial upsert also guarantees the startup_profiles foreign-key
    // parent exists for first-time users.
    final stagedProfile = cloudProfile.profileCompleted
        ? cloudProfile.copyWith(profileCompleted: false)
        : cloudProfile;
    await SchemeRepository.instance.createProfile(stagedProfile);

    // Sync startup_profiles table so the collected applicant/business fields
    // are committed in the same submission before the UI moves forward.
    final existingStartups = await Supabase.instance.client
        .from('startup_profiles')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    // Only touch startup_profiles when the user has actually given business
    // data -- no more writing 'Technology' / 'Idea' / 'Student' placeholders
    // that then round-trip back as if they were real answers.
    final hasBusinessData =
        cloudProfile.businessIndustry.trim().isNotEmpty ||
        cloudProfile.businessStage.trim().isNotEmpty ||
        cloudProfile.existingBusiness ||
        cloudProfile.fundingRequired > 0 ||
        cloudProfile.registrationNumbers.trim().isNotEmpty;

    if (hasBusinessData) {
      final Map<String, dynamic> startupData = {
        'user_id': user.id,
        'profile_name': '${cloudProfile.name} Business',
        'industry': cloudProfile.businessIndustry.trim().isNotEmpty
            ? cloudProfile.businessIndustry
            : 'Unspecified',
        'applicant_type': cloudProfile.employmentStatus.trim().isNotEmpty
            ? cloudProfile.employmentStatus
            : 'Unspecified',
        'business_stage': cloudProfile.businessStage.trim().isNotEmpty
            ? cloudProfile.businessStage
            : 'Unspecified',
        'business_registered': cloudProfile.existingBusiness,
        'funding_required_amount': cloudProfile.fundingRequired,
        'registration_numbers': cloudProfile.registrationNumbers,
        'is_first_generation_entrepreneur': cloudProfile.firstGenGraduate,
        'is_active': true,
      };
      if (existingStartups.isNotEmpty) {
        startupData['id'] = existingStartups.first['id'];
      }
      await Supabase.instance.client
          .from('startup_profiles')
          .upsert(startupData);
    }

    if (cloudProfile.profileCompleted) {
      await SchemeRepository.instance.createProfile(cloudProfile);
    }
    debugPrint('[AppProvider] Supabase profile sync completed.');
  }

  void _syncProfileToSupabaseInBackground(UserProfile profileToSync) {
    unawaited(
      _syncProfileToSupabase(profileToSync).catchError((Object error) {
        debugPrint('[AppProvider] Background Supabase sync failed: $error');
      }),
    );
  }

  /// Resolve the language to apply when a server profile row / realtime echo
  /// arrives. If the user just switched language explicitly, a server value
  /// that still shows the OLD language is a stale echo — keep the user's
  /// choice for a short window. Once the server agrees (or the window lapses)
  /// go back to trusting it.
  String _reconcileServerLanguage(String serverLang) {
    final pending = _pendingLanguage;
    final since = _pendingLanguageSince;
    if (pending == null || since == null) return serverLang;
    if (serverLang == pending) {
      _pendingLanguage = null;
      _pendingLanguageSince = null;
      return serverLang;
    }
    if (DateTime.now().difference(since) < const Duration(seconds: 20)) {
      return pending;
    }
    _pendingLanguage = null;
    _pendingLanguageSince = null;
    return serverLang;
  }

  @visibleForTesting
  void debugMarkLanguagePending(String lang) {
    _pendingLanguage = lang;
    _pendingLanguageSince = DateTime.now();
  }

  @visibleForTesting
  String debugReconcileServerLanguage(String serverLang) =>
      _reconcileServerLanguage(serverLang);

  // Setters & Actions
  Future<void> changeLanguage(String lang) async {
    _selectedLanguage = lang;
    _pendingLanguage = lang;
    _pendingLanguageSince = DateTime.now();
    _profile = _profile.copyWith(language: lang, updatedAt: DateTime.now());
    await loadSchemes(forceRefresh: true);
    notifyListeners();
    await SessionCacheService.instance.saveLanguage(lang);
    await _saveProfile();

    _syncProfileToSupabaseInBackground(_profile);
  }

  Future<void> changeNavigationMode(String mode) async {
    _navigationMode = mode;
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
      _selectedLanguage = _reconcileServerLanguage(dbProfile.language);
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
    _pendingLanguage = null;
    _pendingLanguageSince = null;
    _navigationMode = 'regular';
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
    _pendingLanguage = null;
    _pendingLanguageSince = null;
    _navigationMode = 'regular';
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
          _selectedLanguage = _reconcileServerLanguage(syncProfile.language);
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

  // Completion calculation
  int get profileCompletionPercentage {
    final List<bool> checks = [];

    // Personal Info (5)
    // Onboarding collects age (persisted as `dob`), not a photo. A profile
    // photo is optional and never requested in the onboarding flow, so it is
    // deliberately excluded — including it capped completion at ~95% forever
    // for anyone who never set one.
    checks.add(_profile.name.trim().isNotEmpty);
    checks.add(_profile.mobile.trim().isNotEmpty);
    checks.add(_profile.email.trim().isNotEmpty);
    checks.add(_profile.dob != null);
    checks.add(_profile.gender.trim().isNotEmpty);

    // Address Info (6)
    checks.add(_profile.house.trim().isNotEmpty);
    checks.add(_profile.area.trim().isNotEmpty);
    checks.add(_profile.city.trim().isNotEmpty);
    checks.add(_profile.district.trim().isNotEmpty);
    checks.add(_profile.state.trim().isNotEmpty);
    checks.add(_profile.pinCode.trim().isNotEmpty);

    // Role / Employment (1)
    checks.add(_profile.employmentStatus.trim().isNotEmpty);

    // Eligibility & Social (Step 4) (4)
    checks.add(
      _profile.qualification.trim().isNotEmpty ||
          _profile.educationLevel.trim().isNotEmpty,
    );
    checks.add(_profile.community.trim().isNotEmpty);
    checks.add(_profile.disability == 'Yes' || _profile.disability == 'No');

    // Eligibility Booleans (Income, Veteran, First Gen)
    // Counted as filled if they completed Step 4
    final completedStep4 =
        _profile.qualification.trim().isNotEmpty ||
        _profile.educationLevel.trim().isNotEmpty;
    checks.add(completedStep4);

    // Preferences (2)
    checks.add(_profile.language.trim().isNotEmpty);
    checks.add(_profile.navigationMode.trim().isNotEmpty);

    // Business (conditional)
    if (_profile.existingBusiness) {
      checks.add(_profile.businessStage.trim().isNotEmpty);
      checks.add(_profile.businessIndustry.trim().isNotEmpty);
    }

    final total = checks.length;
    final filled = checks.where((c) => c).length;

    return total == 0 ? 0 : ((filled / total) * 100).round();
  }

  List<String> get missingProfileSections {
    final missing = <String>[];

    // Check Basic Details
    if (_profile.name.trim().isEmpty ||
        _profile.mobile.trim().isEmpty ||
        _profile.email.trim().isEmpty ||
        _profile.dob == null ||
        _profile.gender.trim().isEmpty) {
      missing.add('Basic Details');
    }

    // Address
    if (_profile.house.trim().isEmpty ||
        _profile.area.trim().isEmpty ||
        _profile.state.trim().isEmpty ||
        _profile.district.trim().isEmpty ||
        _profile.city.trim().isEmpty ||
        _profile.pinCode.trim().isEmpty) {
      missing.add('Address Details');
    }

    if (_profile.employmentStatus.trim().isEmpty) missing.add('Employment');

    // Eligibility
    if ((_profile.qualification.trim().isEmpty &&
            _profile.educationLevel.trim().isEmpty) ||
        _profile.community.trim().isEmpty ||
        (_profile.disability != 'Yes' && _profile.disability != 'No')) {
      missing.add('Eligibility');
    }

    if (_profile.existingBusiness) {
      if (_profile.businessStage.trim().isEmpty ||
          _profile.businessIndustry.trim().isEmpty) {
        missing.add('Business Details');
      }
    }
    return missing;
  }

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
    _recommendedSchemes = RecommendationEngine.getRecommendations(
      _profile,
      _allSchemes,
    );

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
    _unsubscribeFromProfile();
    super.dispose();
  }
}
