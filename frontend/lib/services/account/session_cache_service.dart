import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../utils/app_languages.dart';

class SessionCacheService {
  SessionCacheService._privateConstructor();
  static final SessionCacheService instance =
      SessionCacheService._privateConstructor();

  // Cache keys
  static const String _keyProfile = 'userProfile';
  static const String _keyLanguage = 'language';
  static const String _keyNavigationMode = 'navigationMode';
  static const String _keyNavigationModePending = 'navigationModePending';
  static const String _keyOnboardingCompleted = 'onboardingCompleted';
  static const String _keyLastProfileSync = 'last_profile_sync';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyIsGuest = 'isGuest';
  static const String _keyGuestUploadPending = 'guestAnswersUploadPending';
  static const String _keySavedEligibilitySchemeIds =
      'savedEligibilitySchemeIds';
  static const String _keyLastEligibilitySavedAt = 'lastEligibilitySavedAt';

  /// Loads the cached user profile.
  Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString(_keyProfile);
      if (profileStr != null) {
        return UserProfile.fromJson(jsonDecode(profileStr));
      }
    } catch (e) {
      debugPrint('[SessionCacheService] Error loading profile: $e');
    }
    return null;
  }

  /// Saves the user profile.
  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
      // Keep other sync fields updated
      await prefs.setString(_keyNavigationMode, profile.navigationMode);
      await prefs.setBool(_keyOnboardingCompleted, profile.profileCompleted);
      await prefs.setBool(_keyIsLoggedIn, profile.profileCompleted);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving profile: $e');
    }
  }

  /// Saves the language preference.
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, language);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving language: $e');
    }
  }

  /// Saves the navigation mode preference.
  Future<void> saveNavigationMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNavigationMode, mode);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving navigation mode: $e');
    }
  }

  /// Clears all SharedPreferences keys to completely reset the application like a fresh install.
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint(
        '[SessionCacheService] All session and preference data cleared.',
      );
    } catch (e) {
      debugPrint('[SessionCacheService] Error clearing session: $e');
    }
  }

  /// Retrieves the last profile sync timestamp.
  Future<DateTime?> getLastProfileSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncStr = prefs.getString(_keyLastProfileSync);
      if (syncStr != null) {
        return DateTime.tryParse(syncStr);
      }
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting last sync time: $e');
    }
    return null;
  }

  /// Updates the last profile sync timestamp to the current time.
  Future<void> updateLastProfileSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyLastProfileSync,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('[SessionCacheService] Error updating last sync time: $e');
    }
  }

  Future<String?> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyLanguage);
      if (stored == null) return null;
      // A language the app does not offer reads as English, and is stored so.
      final lang = appLanguageOrEnglish(stored);
      if (lang != stored) await prefs.setString(_keyLanguage, lang);
      return lang;
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting language: $e');
      return null;
    }
  }

  /// True while a navigation-mode change made on this device has not yet been
  /// confirmed by the server (issue #127: the server copy used to overwrite it).
  Future<void> setNavigationModePending(bool pending) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNavigationModePending, pending);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving nav-mode flag: $e');
    }
  }

  Future<bool> isNavigationModePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyNavigationModePending) ?? false;
    } catch (e) {
      debugPrint('[SessionCacheService] Error reading nav-mode flag: $e');
      return false;
    }
  }

  Future<String?> getNavigationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyNavigationMode);
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting navigation mode: $e');
      return null;
    }
  }

  Future<bool> getIsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsGuest) ?? false;
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting isGuest: $e');
      return false;
    }
  }

  Future<void> saveIsGuest(bool isGuest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsGuest, isGuest);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving isGuest: $e');
    }
  }

  /// True after a guest signed in and their on-device answers have not yet
  /// reached the new account. Kept apart from [getIsGuest] so a failed upload
  /// is retried on the next sign-in hydrate and a done one never repeats.
  Future<bool> getGuestUploadPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyGuestUploadPending) ?? false;
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting guest upload flag: $e');
      return false;
    }
  }

  Future<void> saveGuestUploadPending(bool pending) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pending) {
        await prefs.setBool(_keyGuestUploadPending, true);
      } else {
        await prefs.remove(_keyGuestUploadPending);
      }
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving guest upload flag: $e');
    }
  }

  Future<int> getCurrentTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('currentTabIndex') ?? 0;
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting current tab index: $e');
      return 0;
    }
  }

  Future<void> saveCurrentTabIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentTabIndex', index);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving current tab index: $e');
    }
  }

  Future<List<String>?> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('bookmarks');
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting bookmarks: $e');
      return null;
    }
  }

  Future<void> saveBookmarks(List<String> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bookmarks', bookmarks);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving bookmarks: $e');
    }
  }

  Future<List<String>?> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('recentlyViewed');
    } catch (e) {
      debugPrint('[SessionCacheService] Error getting recently viewed: $e');
      return null;
    }
  }

  Future<void> saveRecentlyViewed(List<String> recentlyViewed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recentlyViewed', recentlyViewed);
    } catch (e) {
      debugPrint('[SessionCacheService] Error saving recently viewed: $e');
    }
  }

  Future<List<String>?> getSavedEligibilityResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keySavedEligibilitySchemeIds);
    } catch (e) {
      debugPrint(
        '[SessionCacheService] Error getting saved eligibility results: $e',
      );
      return null;
    }
  }

  Future<void> saveSavedEligibilityResults(
    List<String> schemeIds,
    DateTime timestamp,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keySavedEligibilitySchemeIds, schemeIds);
      await prefs.setString(
        _keyLastEligibilitySavedAt,
        timestamp.toIso8601String(),
      );
    } catch (e) {
      debugPrint(
        '[SessionCacheService] Error saving saved eligibility results: $e',
      );
    }
  }

  Future<DateTime?> getLastEligibilitySavedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyLastEligibilitySavedAt);
      if (str != null) {
        return DateTime.tryParse(str);
      }
    } catch (e) {
      debugPrint(
        '[SessionCacheService] Error getting last eligibility saved at: $e',
      );
    }
    return null;
  }

  Future<void> clearSavedEligibilityResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySavedEligibilitySchemeIds);
      await prefs.remove(_keyLastEligibilitySavedAt);
    } catch (e) {
      debugPrint(
        '[SessionCacheService] Error clearing saved eligibility results: $e',
      );
    }
  }
}
