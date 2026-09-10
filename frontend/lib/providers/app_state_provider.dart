import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import '../engine/recommendation_engine.dart';
import '../services/account/auth_service.dart';
import '../services/catalog/scheme_repository.dart';
import '../services/catalog/scheme_catalog_sync_service.dart';
import '../services/account/session_cache_service.dart';
import '../screens/splash_screen.dart';
import '../widgets/common/app_toast.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  AppProvider({SchemeCatalogSyncService? catalogSyncService})
    : _catalogSyncService =
          catalogSyncService ?? SchemeCatalogSyncService.instance {
    WidgetsBinding.instance.addObserver(this);
    _loadState();
    _setupAuthListener();
  }

  final SchemeCatalogSyncService _catalogSyncService;
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
  int _currentTabIndex =
      0; // Bottom Navigation: 0: Home, 1: Search, 2: Categories, 3: Saved Schemes, 4: Profile
  final List<int> _tabHistory = [];
  UserProfile _profile = UserProfile();
  List<String> _bookmarkedIds = [];
  List<String> _recentlyViewedIds = [];
  List<String> _savedEligibilitySchemeIds = [];
  DateTime? _lastEligibilitySavedAt;
  List<Map<String, dynamic>> _downloadedDocs = [];
  String _searchQuery = '';

  // ── Scheme data (loaded from Supabase via SchemeRepository) ──────────
  List<Scheme> _allSchemes = [];
  List<MapEntry<Scheme, RecommendationResult>> _recommendedSchemes = [];
  bool _schemesLoading = false;
  String? _schemesError;
  CatalogSyncResult? _catalogSyncResult;
  bool _catalogSyncing = false;

  // Active scheme facet filters (see lib/models/scheme_filter.dart). Empty by
  // default -- regular search is never silently narrowed by the profile.
  Map<String, dynamic> _filters = {};

  // Temporary wizard answers during the "Find My Schemes" Assessment
  Map<String, dynamic> _wizardAnswers = {};
  int _wizardStep = 0;

  // Dynamic/Mock Announcements fallback
  List<Map<String, String>> _announcementsList = [];

  List<Map<String, String>> get announcements {
    if (_announcementsList.isNotEmpty) return _announcementsList;
    return _defaultAnnouncements;
  }

  static final List<Map<String, String>> _defaultAnnouncements = [
    {
      'title': 'National Entrepreneurs\' Day Celebration',
      'date': '16-Jan-2026',
      'content':
          'Prime Minister launches a new seed grant portal for tech startups and students.',
    },
    {
      'title': 'Tamil Nadu MSME Department Subsidy Hike',
      'date': '04-Jul-2026',
      'content':
          'NEEDS scheme subsidy ceiling raised to ₹75 Lakhs for women and minority entrepreneurs.',
    },
    {
      'title': 'Mudra Loan Shishu Limit Extended',
      'date': '29-May-2026',
      'content':
          'Collateral-free micro loans under Shishu category increased to ₹1 Lakh.',
    },
  ];

  // Notifications state (temporary seed; replaced by the Supabase stream).
  // TODO(review-seed-content): scheme title/body prose below is real-scheme
  // communication -- Tamil in app_ta.arb (notifSeed*) is best-effort, not final.
  List<Map<String, dynamic>> _notificationsList = [
    {
      'id': 'latest_fisheries_update',
      'title':
          'Fisheries and Aquaculture Infra Development Fund Scheme Launched',
      'body':
          'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.',
      'timeAgoCount': 2,
      'timeAgoUnit': 'd',
      'read': false,
      'category': 'updates',
      'iconType': 'emblem',
    },
    {
      'id': '1',
      'title': 'PM Vidyalaxmi Education Loan Scheme',
      'body':
          'A new scheme for students to provide collateral-free education loans for higher studies.',
      'timeAgoCount': 2,
      'timeAgoUnit': 'h',
      'read': false,
      'category': 'new_schemes',
      'tag': 'Education',
      'isNew': true,
    },
    {
      'id': '2',
      'title': 'PM Vishwakarma Yojana',
      'body':
          'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.',
      'timeAgoCount': 1,
      'timeAgoUnit': 'd',
      'read': false,
      'category': 'new_schemes',
      'tag': 'Skill Development',
      'isNew': true,
    },
    {
      'id': '3',
      'title': 'Post Matric Scholarship Scheme',
      'body': 'Last date to apply is approaching',
      'timeAgoCount': 10,
      'timeAgoUnit': 'm',
      'read': false,
      'category': 'reminders',
      'deadline': '31 May 2024',
      'daysLeftCount': 5,
    },
    {
      'id': '4',
      'title': 'PM Internship Scheme',
      'body': 'Application window will close soon',
      'timeAgoCount': 3,
      'timeAgoUnit': 'h',
      'read': false,
      'category': 'reminders',
      'deadline': '15 Jun 2024',
      'daysLeftCount': 20,
    },
    {
      'id': '5',
      'title': 'New Update on Ayushman Bharat Yojana',
      'body':
          'Changes in empanelment process for hospitals. Check full details.',
      'timeAgoCount': 1,
      'timeAgoUnit': 'd',
      'read': false,
      'category': 'updates',
      'iconType': 'emblem',
    },
    {
      'id': '6',
      'title': 'Income Limit Revised for Several Schemes',
      'body':
          'Revised income criteria effective from 1st April 2024 for multiple schemes.',
      'timeAgoCount': 2,
      'timeAgoUnit': 'd',
      'read': false,
      'category': 'updates',
      'iconType': 'bank',
    },
    {
      'id': '7',
      'title': 'Complete Your Profile',
      'body': 'Add your income details to find schemes you are eligible for.',
      'timeAgoCount': 5,
      'timeAgoUnit': 'h',
      'read': false,
      'category': 'profile',
      'progress': 70,
    },
  ];

  List<Map<String, dynamic>> get notifications => _notificationsList;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;

  List<Map<String, dynamic>> _promoAlerts = [];
  List<Map<String, dynamic>> _draftSessions = [];

  List<Map<String, dynamic>> get carouselItems {
    final filteredPromos = _promoAlerts.where((promo) {
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
        : _defaultPromoAlerts;
    return [...basePromos, ..._draftSessions];
  }

  static final List<Map<String, dynamic>> _defaultPromoAlerts = [
    {
      'title': 'Applications Closing Soon',
      'subtitle': 'PMEGP · 2 days left',
      'badge_text': 'Alert',
      'badge_text_color': '#EA580C',
      'badge_bg_color': '#FFF7ED',
      'target_route': 'notifications',
      'bg_image': 'assets/images/Background/alert banner.webp',
    },
    {
      'title': 'New Scheme',
      'subtitle': 'TN Export Promotion Scheme',
      'badge_text': 'New Scheme',
      'badge_text_color': '#16A34A',
      'badge_bg_color': '#DCFCE7',
      'target_route': 'discover_results',
      'bg_image': 'assets/images/Background/new scheme banner.webp',
    },
    {
      'title': 'Important Update',
      'subtitle': 'UDYAM registration process updated',
      'badge_text': 'Notify',
      'badge_text_color': '#2563EB',
      'badge_bg_color': '#EFF6FF',
      'target_route': 'discover_results',
      'bg_image': 'assets/images/Background/notification banner.webp',
    },
    {
      'title': 'For Women Entrepreneurs',
      'subtitle': 'Explore special funding schemes',
      'badge_text': 'Featured',
      'badge_text_color': '#7C3AED',
      'badge_bg_color': '#F5F3FF',
      'target_route': 'discover_results',
      'bg_image': 'assets/images/Background/suggestion banner.webp',
    },
  ];

  // Guards against redundant re-subscription. `_subscribeToProfile` /
  // `_subscribeToNotifications` are each called from the auth-state listener,
  // `_loadState`, and `checkSessionAndFetchProfile`, which can all run on a
  // single launch. Every re-subscribe tears down the socket and replays an
  // initial full-table fetch, so the old unconditional version paid for the
  // same rows two or three times per launch.
  String? _subscribedProfileUserId;
  String? _subscribedNotificationsUserId;

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

  void _subscribeToNotifications(String userId) {
    if (_notificationsSubscription != null &&
        _subscribedNotificationsUserId == userId) {
      return;
    }
    _subscribedNotificationsUserId = userId;
    _notificationsSubscription?.cancel();
    _notificationsSubscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (data) async {
            if (data.isEmpty) {
              _notificationsList = [];
              notifyListeners();
              return;
            }

            final sortedData = List<Map<String, dynamic>>.from(data);
            sortedData.sort((a, b) {
              final aTime =
                  DateTime.tryParse(a['created_at'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  DateTime.tryParse(b['created_at'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            _notificationsList = sortedData.map((n) {
              final createdAt =
                  DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
              final difference = DateTime.now().difference(createdAt);
              // Store a structured (count, unit) pair; the notifications screen
              // formats it via parameterized ARB keys so it renders in ta too.
              int? timeAgoCount;
              String timeAgoUnit = 'now';
              if (difference.inDays > 0) {
                timeAgoCount = difference.inDays;
                timeAgoUnit = 'd';
              } else if (difference.inHours > 0) {
                timeAgoCount = difference.inHours;
                timeAgoUnit = 'h';
              } else if (difference.inMinutes > 0) {
                timeAgoCount = difference.inMinutes;
                timeAgoUnit = 'm';
              }

              final type = n['notification_type'] ?? 'updates';

              final Map<String, dynamic> mapped = {
                'id': n['id'].toString(),
                'title': n['title'] ?? '',
                'body': n['message'] ?? '',
                'timeAgoCount': timeAgoCount,
                'timeAgoUnit': timeAgoUnit,
                'read': n['is_read'] ?? false,
                'category': type,
                'created_at': n['created_at'],
              };

              if (type == 'new_schemes') {
                mapped['tag'] = n['title'].toString().contains('Vidyalaxmi')
                    ? 'Education'
                    : 'Skill Development';
                mapped['isNew'] = true;
              } else if (type == 'reminders') {
                mapped['deadline'] = n['title'].toString().contains('Matric')
                    ? '31 May 2026'
                    : '15 Jun 2026';
                mapped['daysLeftCount'] =
                    n['title'].toString().contains('Matric') ? 5 : 20;
              } else if (type == 'updates') {
                mapped['iconType'] = n['title'].toString().contains('Ayushman')
                    ? 'emblem'
                    : 'bank';
              } else if (type == 'profile') {
                mapped['progress'] = 70;
              }

              return mapped;
            }).toList();

            notifyListeners();
          },
          onError: (err) {
            debugPrint(
              '[AppProvider] Real-time notifications subscription error: $err',
            );
          },
        );
  }

  void _unsubscribeFromNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _subscribedNotificationsUserId = null;
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
          _subscribeToNotifications(user.id);
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
        _bookmarkedIds.clear();
        _recentlyViewedIds.clear();
        _savedEligibilitySchemeIds.clear();
        _lastEligibilitySavedAt = null;
        _currentTabIndex = 0;
        _promoAlerts = [];
        _draftSessions = [];
        // Clear the throttle stamps too, or the next account to sign in on
        // this device would be served the previous user's empty state until
        // the throttle window expired.
        _lastPromoFetch = null;
        _lastDraftFetch = null;
        _unsubscribeFromProfile();
        _unsubscribeFromNotifications();
        _notificationsList = [];
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
  int get currentTabIndex => _currentTabIndex;
  UserProfile get profile => _profile;

  /// Extracts the Google account profile image URL from Supabase Auth user metadata or identities.
  static String extractGooglePhoto(User? user) {
    if (user == null) return '';
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in ['avatar_url', 'picture', 'photo_url', 'avatarUrl']) {
        final val = meta[key];
        if (val is String && val.trim().isNotEmpty) {
          return val.trim();
        }
      }
    }
    if (user.identities != null) {
      for (final identity in user.identities!) {
        final idData = identity.identityData;
        if (idData != null) {
          for (final key in [
            'avatar_url',
            'picture',
            'photo_url',
            'avatarUrl',
          ]) {
            final val = idData[key];
            if (val is String && val.trim().isNotEmpty) {
              return val.trim();
            }
          }
        }
      }
    }
    return '';
  }

  /// Extracts the Google account name from Supabase Auth user metadata or identities.
  static String extractGoogleName(User? user) {
    if (user == null) return '';
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in ['full_name', 'name', 'user_name']) {
        final val = meta[key];
        if (val is String && val.trim().isNotEmpty) {
          return val.trim();
        }
      }
    }
    if (user.identities != null) {
      for (final identity in user.identities!) {
        final idData = identity.identityData;
        if (idData != null) {
          for (final key in ['full_name', 'name', 'user_name']) {
            final val = idData[key];
            if (val is String && val.trim().isNotEmpty) {
              return val.trim();
            }
          }
        }
      }
    }
    return '';
  }

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

  List<String> get bookmarkedIds => _bookmarkedIds;
  List<String> get recentlyViewedIds => _recentlyViewedIds;
  List<String> get savedEligibilitySchemeIds => _savedEligibilitySchemeIds;
  DateTime? get lastEligibilitySavedAt => _lastEligibilitySavedAt;
  bool get hasSavedEligibilityResults => _savedEligibilitySchemeIds.isNotEmpty;

  // Saved eligibility schemes list
  List<Scheme> get savedEligibilitySchemes {
    return _allSchemes
        .where(
          (s) =>
              _savedEligibilitySchemeIds.contains(s.id) ||
              _savedEligibilitySchemeIds.contains(s.schemeCode),
        )
        .toList();
  }

  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;
  Map<String, dynamic> get wizardAnswers => _wizardAnswers;
  int get wizardStep => _wizardStep;

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
    return _allSchemes
        .where(
          (s) =>
              _bookmarkedIds.contains(s.id) ||
              _bookmarkedIds.contains(s.schemeCode),
        )
        .toList();
  }

  // Recently viewed schemes list
  List<Scheme> get recentlyViewedSchemes {
    return _allSchemes
        .where(
          (s) =>
              _recentlyViewedIds.contains(s.id) ||
              _recentlyViewedIds.contains(s.schemeCode),
        )
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

      // Update announcements dynamically based on latest central/state schemes
      if (_allSchemes.isNotEmpty) {
        final recent = List<Scheme>.from(_allSchemes)
          ..sort((a, b) => b.id.compareTo(a.id));
        _announcementsList = recent.take(3).map((s) {
          final isCentral = s.governmentLevel.toLowerCase() == 'central';
          final sponsor = s.sponsoringBody.isNotEmpty
              ? s.sponsoringBody
              : (isCentral ? 'Govt of India' : s.state);
          return {
            'title': 'Updated: ${s.name}',
            'date': 'Realtime Live Feed',
            'content':
                '${s.overview.length > 120 ? "${s.overview.substring(0, 117)}..." : s.overview} (Source: $sponsor)',
          };
        }).toList();
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
      _currentTabIndex = await SessionCacheService.instance
          .getCurrentTabIndex();

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

      _bookmarkedIds = await SessionCacheService.instance.getBookmarks() ?? [];
      _recentlyViewedIds =
          await SessionCacheService.instance.getRecentlyViewed() ?? [];
      _savedEligibilitySchemeIds =
          await SessionCacheService.instance.getSavedEligibilityResults() ?? [];
      _lastEligibilitySavedAt = await SessionCacheService.instance
          .getLastEligibilitySavedAt();

      final downloadedDocsStr = await SessionCacheService.instance
          .getDownloadedDocs();
      if (downloadedDocsStr != null) {
        _downloadedDocs = List<Map<String, dynamic>>.from(
          jsonDecode(downloadedDocsStr),
        );
      } else {
        _downloadedDocs = [];
      }

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
        _subscribeToNotifications(session.user.id);
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
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _savedEligibilitySchemeIds.clear();
    _lastEligibilitySavedAt = null;
    _currentTabIndex = 0;
    _tabHistory.clear();
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
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _savedEligibilitySchemeIds.clear();
    _lastEligibilitySavedAt = null;
    _currentTabIndex = 0;
    _tabHistory.clear();
    _unsubscribeFromProfile();
    _unsubscribeFromNotifications();

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

  void updateTabIndex(int index, {bool addToHistory = true}) async {
    if (_currentTabIndex == index) return;
    if (addToHistory) {
      if (_tabHistory.isEmpty || _tabHistory.last != _currentTabIndex) {
        _tabHistory.add(_currentTabIndex);
      }
    }
    _currentTabIndex = index;
    notifyListeners();
    await SessionCacheService.instance.saveCurrentTabIndex(index);
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

  bool get hasTabHistory => _tabHistory.isNotEmpty;

  bool popTabIndex() {
    if (_tabHistory.isNotEmpty) {
      final prevIndex = _tabHistory.removeLast();
      _currentTabIndex = prevIndex;
      notifyListeners();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('currentTabIndex', prevIndex);
      });
      return true;
    }
    return false;
  }

  void toggleBookmark(String id) async {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', _bookmarkedIds);
  }

  void addToRecentlyViewed(String id) async {
    _recentlyViewedIds.remove(id); // Move to front
    _recentlyViewedIds.insert(0, id);
    if (_recentlyViewedIds.length > 5) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, 5);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentlyViewed', _recentlyViewedIds);
  }

  Future<void> saveEligibilityResults(List<String> schemeIds) async {
    _savedEligibilitySchemeIds = List<String>.from(schemeIds);
    _lastEligibilitySavedAt = DateTime.now();
    notifyListeners();

    await SessionCacheService.instance.saveSavedEligibilityResults(
      _savedEligibilitySchemeIds,
      _lastEligibilitySavedAt!,
    );

    if (_isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        unawaited(
          Supabase.instance.client
              .from('profiles')
              .update({
                'saved_eligibility_schemes': _savedEligibilitySchemeIds,
                'last_eligibility_saved_at': _lastEligibilitySavedAt!
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

  // Search & Filter Operations
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateFilter(String key, dynamic value) {
    _filters[key] = value;
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
  }

  // Wizard state management
  void startWizard() {
    _wizardStep = 0;
    _wizardAnswers = {
      'name': _profile.name,
      'gender': _profile.gender,
      'dob': _profile.dob ?? DateTime(1998, 1, 1),
      'state': _profile.state,
      'district': _profile.district,
      'city': _profile.city,
      'pinCode': _profile.pinCode,
      'community': _profile.community,
      'religion': _profile.religion,
      'educationLevel': _profile.educationLevel,
      'firstGenGraduate': _profile.firstGenGraduate,
      'annualIncome': _profile.annualIncome,
    };
    notifyListeners();
  }

  void updateWizardAnswer(String key, dynamic value) {
    _wizardAnswers[key] = value;
    notifyListeners();
  }

  void nextWizardStep() {
    if (_wizardStep < 2) {
      _wizardStep++;
      notifyListeners();
    }
  }

  void previousWizardStep() {
    if (_wizardStep > 0) {
      _wizardStep--;
      notifyListeners();
    }
  }

  void submitWizard() {
    // Commit wizard answers to UserProfile
    _profile = UserProfile(
      name: _wizardAnswers['name'] ?? '',
      gender: _wizardAnswers['gender'] ?? '',
      dob: _wizardAnswers['dob'] as DateTime?,
      state: _wizardAnswers['state'] ?? '',
      district: _wizardAnswers['district'] ?? '',
      city: _wizardAnswers['city'] ?? '',
      pinCode: _wizardAnswers['pinCode'] ?? '',
      community: _wizardAnswers['community'] ?? '',
      religion: _wizardAnswers['religion'] ?? '',
      educationLevel: _wizardAnswers['educationLevel'] ?? '',
      firstGenGraduate: _wizardAnswers['firstGenGraduate'] ?? false,
      annualIncome: (_wizardAnswers['annualIncome'] ?? 0.0) as double,
      mobile: _mobileNumber,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _saveProfile();
  }

  // Notification action
  Future<void> markNotificationRead(String id) async {
    final index = _notificationsList.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notificationsList[index]['read'] = true;
      notifyListeners();
    }
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('[AppProvider] Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (var n in _notificationsList) {
      n['read'] = true;
    }
    notifyListeners();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AppProvider] Error marking all notifications read: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    _notificationsList.clear();
    notifyListeners();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AppProvider] Error deleting all notifications: $e');
    }
  }

  Future<void> deleteNotifications(List<String> ids) async {
    _notificationsList.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('[AppProvider] Error deleting notifications: $e');
    }
  }

  Future<void> markNotificationsRead(List<String> ids) async {
    for (var n in _notificationsList) {
      if (ids.contains(n['id'])) {
        n['read'] = true;
      }
    }
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('[AppProvider] Error marking notifications read: $e');
    }
  }

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

  Future<Map<String, dynamic>> _getFallbackLocation() async {
    final locData = {
      'house': 'Flat 402',
      'street': 'Royal Enclave',
      'area': 'Anna Nagar West',
      'village': '',
      'state': 'Tamil Nadu',
      'district': 'Chennai',
      'city': 'Chennai',
      'pinCode': '600040',
      'latitude': 13.0827,
      'longitude': 80.2707,
      'isFallback': true,
    };

    _profile = _profile.copyWith(
      area: locData['area'] as String,
      state: locData['state'] as String,
      district: locData['district'] as String,
      city: locData['city'] as String,
      pinCode: locData['pinCode'] as String,
    );

    notifyListeners();
    await _saveProfile();
    _syncProfileToSupabaseInBackground(_profile);
    return locData;
  }

  // Location/GPS Helper
  Future<Map<String, dynamic>?> fetchLocationAndPopulate() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Using Chennai fallback.');
        return await _getFallbackLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint(
            'Location permissions are denied. Using Chennai fallback.',
          );
          return await _getFallbackLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Location permissions are permanently denied. Using Chennai fallback.',
        );
        return await _getFallbackLocation();
      }

      Position? position;
      try {
        // Try getting current position with medium accuracy (faster, works indoors)
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 7),
        );
      } catch (e) {
        debugPrint(
          'getCurrentPosition failed: $e. Trying getLastKnownPosition as fallback...',
        );
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (err) {
          debugPrint('getLastKnownPosition failed: $err');
        }
      }

      if (position == null) {
        debugPrint('No position found. Using Chennai fallback.');
        return await _getFallbackLocation();
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        final locData = {
          'house': placemark.subThoroughfare ?? '',
          'street': placemark.thoroughfare ?? '',
          'area': placemark.subLocality ?? placemark.name ?? '',
          'village':
              placemark.subLocality != null &&
                  placemark.name != null &&
                  placemark.subLocality != placemark.name
              ? placemark.name
              : '',
          'state': placemark.administrativeArea ?? '',
          'district':
              (placemark.subAdministrativeArea != null &&
                  placemark.subAdministrativeArea!.isNotEmpty)
              ? placemark.subAdministrativeArea!
              : (placemark.locality ?? ''),
          'city': placemark.locality ?? placemark.subLocality ?? '',
          'pinCode': placemark.postalCode ?? '',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'isFallback': false,
        };

        _profile = _profile.copyWith(
          area: locData['area'] as String,
          state: locData['state'] as String,
          district: locData['district'] as String,
          city: locData['city'] as String,
          pinCode: locData['pinCode'] as String,
        );

        notifyListeners();
        await _saveProfile();
        _syncProfileToSupabaseInBackground(_profile);
        return locData;
      }
    } catch (e) {
      debugPrint('Error fetching location: $e. Using Chennai fallback.');
    }
    return await _getFallbackLocation();
  }

  List<Map<String, dynamic>> get downloadedDocs => _downloadedDocs;

  Future<void> _saveDownloadedDocs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadedDocs', jsonEncode(_downloadedDocs));
  }

  void downloadDoc(String id, String title, String size) {
    if (!_downloadedDocs.any((doc) => doc['id'] == id)) {
      final now = DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final dateStr =
          'Downloaded on ${now.day} ${months[now.month - 1]} ${now.year}';

      _downloadedDocs.add({
        'id': id,
        'title': title,
        'size': size,
        'date': dateStr,
        'fileType': 'PDF',
      });
      _saveDownloadedDocs();
      notifyListeners();
    }
  }

  void removeDownloadedDoc(String id) {
    _downloadedDocs.removeWhere((doc) => doc['id'] == id);
    _saveDownloadedDocs();
    notifyListeners();
  }

  DateTime? _lastPromoFetch;
  static const Duration _promoFetchThrottle = Duration(minutes: 30);

  Future<void> fetchPromoAlerts({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastPromoFetch != null &&
        now.difference(_lastPromoFetch!) < _promoFetchThrottle) {
      return;
    }
    _lastPromoFetch = now;
    try {
      final res = await Supabase.instance.client.from('promo_alerts').select();

      final mapped = List<Map<String, dynamic>>.from(res).map((item) {
        final mutable = Map<String, dynamic>.from(item);
        if (mutable['bg_image'] == null ||
            mutable['bg_image'].toString().isEmpty) {
          final title = (mutable['title'] ?? '').toString().toLowerCase();
          final badge = (mutable['badge_text'] ?? '').toString().toLowerCase();
          if (badge.contains('alert') ||
              title.contains('closing') ||
              title.contains('deadline')) {
            mutable['bg_image'] = 'assets/images/Background/alert banner.webp';
            mutable['badge_text_color'] = '#EA580C';
            mutable['badge_bg_color'] = '#FFF7ED';
          } else if (badge.contains('new') ||
              title.contains('new scheme') ||
              title.contains('export')) {
            mutable['bg_image'] =
                'assets/images/Background/new scheme banner.webp';
            mutable['badge_text_color'] = '#16A34A';
            mutable['badge_bg_color'] = '#DCFCE7';
          } else if (badge.contains('notify') ||
              title.contains('update') ||
              title.contains('udyam')) {
            mutable['bg_image'] =
                'assets/images/Background/notification banner.webp';
            mutable['badge_text_color'] = '#2563EB';
            mutable['badge_bg_color'] = '#EFF6FF';
          } else {
            mutable['bg_image'] =
                'assets/images/Background/suggestion banner.webp';
            mutable['badge_text_color'] = '#7C3AED';
            mutable['badge_bg_color'] = '#F5F3FF';
          }
        }
        return mutable;
      }).toList();

      _promoAlerts = mapped;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Error fetching promo alerts: $e');
    }
  }

  DateTime? _lastDraftFetch;
  static const Duration _draftFetchThrottle = Duration(minutes: 5);

  /// Throttled like [fetchPromoAlerts]. This is called from four places --
  /// the realtime profile stream, the auth-state listener, `_loadState`, and
  /// `checkSessionAndFetchProfile` -- so an unthrottled version re-queried
  /// `questionnaire_sessions` on every profile row change and several times
  /// per app launch. Pass `force: true` after the user actually edits a draft.
  Future<void> fetchDraftSessions({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastDraftFetch != null &&
        now.difference(_lastDraftFetch!) < _draftFetchThrottle) {
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _draftSessions = [];
        _lastDraftFetch = null;
        notifyListeners();
        return;
      }
      _lastDraftFetch = now;

      final res = await Supabase.instance.client
          .from('questionnaire_sessions')
          .select(
            'id, completed_percentage, status, startup_profiles!inner(user_id, profile_name)',
          )
          .eq('status', 'IN_PROGRESS')
          .eq('startup_profiles.user_id', userId);

      _draftSessions = List<Map<String, dynamic>>.from(res).map((item) {
        final startup = item['startup_profiles'] as Map<String, dynamic>;
        final pct = (item['completed_percentage'] as num?)?.toDouble() ?? 0.0;
        return {
          'id': item['id'],
          'title': '${startup['profile_name']} Setup',
          'badge_text': 'Draft',
          'badge_text_color': '#2563EB',
          'badge_bg_color': '#EFF6FF',
          'bg_gradient_start': '#EFF6FF',
          'bg_gradient_end': '#DBEAFE',
          'btn_text': 'Continue',
          'btn_color': '#2563EB',
          'target_route': 'draft_session',
          'graphic_type': 'progress',
          'progress': pct,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Error fetching draft sessions: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeFromProfile();
    _unsubscribeFromNotifications();
    super.dispose();
  }
}
