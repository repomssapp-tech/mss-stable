import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/eligibility_questionnaire.dart';

/// Where the phone was when the user tapped "Use my current location".
class QuestionnaireLocation {
  const QuestionnaireLocation(this.latitude, this.longitude, this.accuracyM);
  final double latitude;
  final double longitude;
  final int accuracyM;

  Map<String, Object> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_m': accuracyM,
  };

  static QuestionnaireLocation? fromJson(Object? j) {
    if (j is! Map) return null;
    final lat = j['latitude'], lng = j['longitude'], acc = j['accuracy_m'];
    if (lat is! num || lng is! num) return null;
    return QuestionnaireLocation(
      lat.toDouble(),
      lng.toDouble(),
      acc is num ? acc.round() : 0,
    );
  }
}

/// Keeps the questionnaire answers on this device (and the bits needed to send
/// them: pending flag, location). Sending is [QuestionnaireSyncService]'s job.
/// Same shape as the website's `mss.answers`.
class EligibilityAnswersStore {
  const EligibilityAnswersStore();

  static const _key = 'mss.eligibility.answers';
  static const _locationKey = 'mss.eligibility.location';
  static const _pendingKey = 'mss.eligibility.pending';

  Future<QuestionnaireAnswers> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final j = jsonDecode(raw);
      return j is Map<String, dynamic> ? j : {};
    } catch (e) {
      debugPrint('[EligibilityAnswersStore] load failed: $e');
      return {};
    }
  }

  /// Saves the answers and marks them as not yet sent.
  Future<void> save(QuestionnaireAnswers answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(answers));
      await prefs.setBool(_pendingKey, true);
    } catch (e) {
      debugPrint('[EligibilityAnswersStore] save failed: $e');
    }
  }

  Future<QuestionnaireLocation?> loadLocation() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _locationKey,
      );
      return raw == null ? null : QuestionnaireLocation.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocation(QuestionnaireLocation location) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _locationKey,
        jsonEncode(location.toJson()),
      );
    } catch (e) {
      debugPrint('[EligibilityAnswersStore] saveLocation failed: $e');
    }
  }

  Future<bool> isPending() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_pendingKey) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSent() async {
    try {
      await (await SharedPreferences.getInstance()).remove(_pendingKey);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_locationKey);
      await prefs.remove(_pendingKey);
    } catch (e) {
      debugPrint('[EligibilityAnswersStore] clear failed: $e');
    }
  }
}
