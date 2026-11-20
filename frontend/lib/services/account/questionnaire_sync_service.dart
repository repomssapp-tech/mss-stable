import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import 'app_session.dart';
import 'eligibility_answers_store.dart';

/// Sends the questionnaire answers to the MSS API (profile + government
/// statistics): signed in -> `PUT /me/questionnaire`; guest -> `PUT
/// /questionnaire/guest` with a random id kept on this device. A failed send
/// leaves the answers marked pending and they go out on the next attempt.
class QuestionnaireSyncService {
  QuestionnaireSyncService({
    ApiClient? apiClient,
    this.store = const EligibilityAnswersStore(),
    bool Function()? isSignedIn,
  }) : _api = apiClient ?? ApiClient(),
       _isSignedIn = isSignedIn ?? (() => AppSession.instance.isSignedIn);

  static final QuestionnaireSyncService instance = QuestionnaireSyncService();

  final ApiClient _api;
  final EligibilityAnswersStore store;
  final bool Function() _isSignedIn;

  static const _guestKey = 'mss.eligibility.guestId';

  /// A random version-4 id for this device (the server wants a UUID).
  static String newGuestId([Random? random]) {
    final r = random ?? Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    final x = List.generate(16, h);
    return '${x.sublist(0, 4).join()}-${x.sublist(4, 6).join()}-'
        '${x.sublist(6, 8).join()}-${x.sublist(8, 10).join()}-${x.sublist(10).join()}';
  }

  Future<String> guestId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_guestKey);
    if (id == null || id.isEmpty) {
      id = newGuestId();
      await prefs.setString(_guestKey, id);
    }
    return id;
  }

  /// Sends the saved answers. True when the server has them.
  Future<bool> sync({String? language}) async {
    final answers = await store.load();
    if (answers.isEmpty) return true;
    final location = await store.loadLocation();
    final body = <String, Object?>{
      'answers': answers,
      'source': 'app',
      'language': ?language,
      'location': ?location?.toJson(),
    };
    try {
      if (_isSignedIn()) {
        await _api.put('/me/questionnaire', body: body);
      } else {
        body['guest_id'] = await guestId();
        await _api.put(
          '/questionnaire/guest',
          body: body,
          requiresAuth: false,
        );
      }
      await store.markSent();
      return true;
    } catch (e) {
      debugPrint('[QuestionnaireSyncService] send failed: $e');
      return false;
    }
  }

  /// A signed-in user on a phone with no saved answers (a new phone, or cleared data):
  /// read them from the account.
  Future<void> pullIfEmpty() async {
    try {
      if (!_isSignedIn() || (await store.load()).isNotEmpty) return;
      final data = (await _api.get('/me/questionnaire')).data;
      if (data is Map && data['answers'] is Map && (data['answers'] as Map).isNotEmpty) {
        await store.save(Map<String, dynamic>.from(data['answers'] as Map));
        await store.markSent();
      }
    } catch (e) {
      debugPrint('[QuestionnaireSyncService] pullIfEmpty failed: $e');
    }
  }

  /// Right after sign-in: the guest's answers join the account (the account's
  /// own answers win), and any answers still waiting to be sent go out.
  Future<void> afterSignIn({String? language}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guest = prefs.getString(_guestKey);
      if (guest != null && guest.isNotEmpty) {
        await _api.post('/me/questionnaire/claim', body: {'guest_id': guest});
        await prefs.remove(_guestKey);
      }
      if (await store.isPending()) {
        await sync(language: language);
        return;
      }
      final res = await _api.get('/me/questionnaire');
      final data = res.data;
      if (data is Map && data['answers'] is Map && (data['answers'] as Map).isNotEmpty) {
        await store.save(Map<String, dynamic>.from(data['answers'] as Map));
        await store.markSent();
      }
    } catch (e) {
      debugPrint('[QuestionnaireSyncService] afterSignIn failed: $e');
    }
  }
}
