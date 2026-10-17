import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/onboarding_api_dto.dart';
import '../../models/user_profile_api_dto.dart';
import '../chat/chat_log_service.dart';
import '../network/api_client.dart';
import 'profile_api_service.dart';

/// Service implementing Business profiles, Legal Consent, and Atomic Onboarding (PUT /v1/me/onboarding).
class OnboardingApiService {
  static OnboardingApiService? _instance;
  static OnboardingApiService get instance => _instance ??= OnboardingApiService();
  @visibleForTesting
  static set testInstance(OnboardingApiService? service) => _instance = service;

  final ApiClient _apiClient;
  final ProfileApiService? _profileApiService;

  OnboardingApiService({
    ApiClient? apiClient,
    ProfileApiService? profileApiService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _profileApiService = profileApiService ?? ProfileApiService.instance;

  /// Inspects current legal document registry versions from GET /v1/me/legal-documents.
  Future<LegalDocumentsResponse> getLegalDocuments() async {
    final response = await _apiClient.get('/me/legal-documents');
    final data = response.data as Map<String, dynamic>? ?? {};
    return LegalDocumentsResponse.fromJson(data);
  }

  /// Separately records acceptance of legal documents via POST /v1/me/legal-acceptances.
  Future<ProfileAggregate> acceptLegalDocuments(
    List<LegalDocumentItem> acceptances, {
    required String etag,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Profile-If-Match': etag,
    };

    final response = await _apiClient.post(
      '/me/legal-acceptances',
      headers: headers,
      body: {
        'acceptances': acceptances.map((a) => a.toJson()).toList(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final updated = ProfileAggregate.fromJson(data);
    return updated;
  }

  /// Submits profile, optional business, and legal acceptances in one transactional call.
  ///
  /// Requirements:
  /// - `X-Profile-If-Match`: latest quoted profile ETag (e.g. "profile-2").
  /// - `Idempotency-Key`: UUID string; keep identical on retry of the exact same body.
  /// - All three body keys (`profile`, `business`, `legal_acceptances`) are required.
  Future<ProfileAggregate> submitOnboarding(
    OnboardingSubmissionDto submission, {
    String? etag,
    String? idempotencyKey,
  }) async {
    final effectiveEtag = etag ??
        _profileApiService?.currentEtag ??
        ProfileApiService.instance.currentEtag ??
        '';
    final key = idempotencyKey ?? ChatLogService.generateUuidV4();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (effectiveEtag.isNotEmpty) 'X-Profile-If-Match': effectiveEtag,
      'Idempotency-Key': key,
    };

    final response = await _apiClient.put(
      '/me/onboarding',
      headers: headers,
      body: submission.toJson(),
    );

    final data = response.data as Map<String, dynamic>;
    final completed = ProfileAggregate.fromJson(data);
    return completed;
  }
}
