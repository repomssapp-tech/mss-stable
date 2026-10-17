import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/user_profile_api_dto.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// Client service for Profile, Draft Saving, and ETag Version Concurrency.
///
/// Complies with MSS API Handoff rules:
/// - Reads GET /v1/me/profile and retains its quoted ETag, e.g. "profile-1".
/// - Sends `X-Profile-If-Match: "profile-1"` on all profile writes.
/// - Does NOT send standard `If-Match` alongside it (avoids Vercel precondition clashes).
/// - Replaces local aggregate and ETag on each successful response.
/// - Surfaces 412 PROFILE_VERSION_CONFLICT for deliberate user reconciliation.
class ProfileApiService {
  static ProfileApiService? _instance;
  static ProfileApiService get instance => _instance ??= ProfileApiService();
  @visibleForTesting
  static set testInstance(ProfileApiService? service) => _instance = service;

  final ApiClient _apiClient;
  String? _etag;
  ProfileAggregate? _currentProfile;

  ProfileApiService({
    ApiClient? apiClient,
    String? initialEtag,
  })  : _apiClient = apiClient ?? ApiClient(),
        _etag = initialEtag;

  String? get currentEtag => _etag;
  ProfileAggregate? get currentProfile => _currentProfile;

  /// Loads the profile from GET /v1/me/profile and updates the cached ETag.
  /// If absent on server, creates an empty owner draft and returns 200.
  Future<ProfileAggregate> loadProfile() async {
    final response = await _apiClient.get('/me/profile');
    _updateEtagFromResponse(response);

    final data = response.data as Map<String, dynamic>;
    final profile = ProfileAggregate.fromJson(data);
    _currentProfile = profile;
    return profile;
  }

  /// Saves changed draft fields via PATCH /v1/me/profile with X-Profile-If-Match.
  /// Returns the complete updated ProfileAggregate and advances the ETag.
  Future<ProfileAggregate> saveDraft(Map<String, dynamic> changedFields) async {
    if (changedFields.isEmpty) {
      if (_currentProfile != null) return _currentProfile!;
      return loadProfile();
    }

    if (_etag == null) {
      // Must have ETag before writing per HTTP 428 IF_MATCH_REQUIRED
      await loadProfile();
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

      _updateEtagFromResponse(response);
      final data = response.data as Map<String, dynamic>;
      final updated = ProfileAggregate.fromJson(data);
      _currentProfile = updated;
      return updated;
    } on ApiException catch (e) {
      if (e.isStaleVersion) {
        debugPrint(
          '[ProfileApiService] 412 PROFILE_VERSION_CONFLICT encountered: ${_etag ?? "null"}',
        );
      }
      rethrow;
    }
  }

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
