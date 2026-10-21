import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/user_profile.dart';
import '../../models/user_profile_api_dto.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// Client service for Profile, Draft Saving, and ETag Version Concurrency.
///
/// Complies with MSS API Handoff rules:
/// - Reads GET /v1/me/profile and retains its quoted ETag, e.g. "profile-1".
/// - Sends `X-Profile-If-Match: "profile-1"` on all profile writes.
/// - Does NOT send standard `If-Match` alongside it (avoids Vercel precondition clashes).
/// - Replaces local aggregate and ETag on each successful response, including
///   the onboarding and legal-acceptance writes (see [adoptResponse]).
/// - Surfaces 412 PROFILE_VERSION_CONFLICT for deliberate user reconciliation.
/// - Runs profile writes one at a time ([runExclusive]) so two local
///   operations never send the same ETag.
class ProfileApiService {
  static ProfileApiService? _instance;
  static ProfileApiService get instance => _instance ??= ProfileApiService();
  @visibleForTesting
  static set testInstance(ProfileApiService? service) => _instance = service;

  final ApiClient _apiClient;
  String? _etag;
  ProfileAggregate? _currentProfile;
  Future<void> _tail = Future<void>.value();

  ProfileApiService({ApiClient? apiClient, String? initialEtag})
    : _apiClient = apiClient ?? ApiClient(),
      _etag = initialEtag;

  String? get currentEtag => _etag;
  ProfileAggregate? get currentProfile => _currentProfile;

  /// Runs [action] after every earlier exclusive operation has finished. A
  /// failure in one operation does not block the next.
  Future<T> runExclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Caches the profile aggregate and ETag carried by a successful profile,
  /// onboarding or legal-acceptance response, together.
  ProfileAggregate adoptResponse(ApiResponse<dynamic> response) {
    final profile = ProfileAggregate.fromJson(
      response.data as Map<String, dynamic>,
    );
    _updateEtagFromResponse(response);
    _currentProfile = profile;
    return profile;
  }

  /// Loads the profile from GET /v1/me/profile and updates the cached ETag.
  /// If absent on server, creates an empty owner draft and returns 200.
  Future<ProfileAggregate> loadProfile() => runExclusive(_loadLocked);

  Future<ProfileAggregate> _loadLocked() async {
    final response = await _apiClient.get('/me/profile');
    return adoptResponse(response);
  }

  /// Saves changed draft fields via PATCH /v1/me/profile with X-Profile-If-Match.
  /// Returns the complete updated ProfileAggregate and advances the ETag.
  Future<ProfileAggregate> saveDraft(Map<String, dynamic> changedFields) =>
      runExclusive(() => _saveDraftLocked(changedFields));

  /// Saves what differs between [profile] and the server's current profile.
  ///
  /// The comparison runs inside the write queue, against the latest server
  /// aggregate, so a queued older draft cannot undo a newer completed save.
  Future<ProfileAggregate> saveProfileChanges(UserProfile profile) =>
      runExclusive(() async {
        final baseline = _currentProfile ?? await _loadLocked();
        final patch = ProfileAggregate.buildPatchPayload(
          current: profile,
          baseline: baseline,
        );
        return _saveDraftLocked(patch);
      });

  Future<ProfileAggregate> _saveDraftLocked(
    Map<String, dynamic> changedFields,
  ) async {
    if (changedFields.isEmpty) {
      return _currentProfile ?? await _loadLocked();
    }

    if (_etag == null) {
      // Must have ETag before writing per HTTP 428 IF_MATCH_REQUIRED
      await _loadLocked();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Profile-If-Match': _etag!,
    };

    try {
      final response = await _apiClient.patch(
        '/me/profile',
        body: changedFields,
        headers: headers,
      );
      return adoptResponse(response);
    } on ApiException catch (e) {
      if (e.isStaleVersion) {
        debugPrint(
          '[ProfileApiService] 412 PROFILE_VERSION_CONFLICT encountered: ${_etag ?? "null"}',
        );
        // Take the server's current version so the caller's retry (which
        // still holds the user's unsaved edits) is built against it. The
        // edits themselves are not applied or dropped here.
        try {
          await _loadLocked();
        } catch (_) {}
      }
      // A server that does not store this interface language yet (hi / mr)
      // rejects the whole patch with a `language` validation error. Save
      // everything else rather than blocking the profile, once.
      if (_isLanguageRejected(e) && changedFields.containsKey('language')) {
        debugPrint(
          '[ProfileApiService] Server rejected language '
          '"${changedFields['language']}"; saving the rest without it.',
        );
        final rest = Map<String, dynamic>.of(changedFields)..remove('language');
        return _saveDraftLocked(rest);
      }
      rethrow;
    }
  }

  static bool _isLanguageRejected(ApiException e) =>
      e.statusCode == 400 &&
      e.errorCode == 'VALIDATION_ERROR' &&
      (e.details ?? const []).any(
        (d) => d is Map && d['field'] == 'language',
      );

  void _updateEtagFromResponse(ApiResponse<dynamic> response) {
    final newEtag = response.etag;
    if (newEtag != null && newEtag.isNotEmpty) {
      _etag = newEtag;
    }
  }

  /// Clears stored ETag and cached profile (called on logout/account switch).
  void clear() {
    _etag = null;
    _currentProfile = null;
  }
}
