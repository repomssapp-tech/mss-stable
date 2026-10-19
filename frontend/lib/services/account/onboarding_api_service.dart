import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/onboarding_api_dto.dart';
import '../../models/user_profile_api_dto.dart';
import '../chat/chat_log_service.dart';
import '../network/api_client.dart';
import 'profile_api_service.dart';

/// The legal documents (type + version) this user explicitly accepted on this
/// device.
///
/// The server completes onboarding only with the user's own acceptance of the
/// four current documents (terms, privacy_policy, privacy_notice, consent).
/// The user sees three documents: Terms of Use and Privacy Policy, which they
/// read to the end and accept on the sign-in screen, and the data-use page
/// (the privacy notice and the consent in one), which counts as accepted when
/// the profile is completed. It belongs to one account, so it is cleared on
/// sign-out.
class LegalConsentStore {
  LegalConsentStore._();

  static const String _key = 'legal_consent_v1';

  static Future<List<LegalDocumentItem>> accepted() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const [];
      final list = jsonDecode(raw);
      return [
        if (list is List)
          for (final item in list)
            if (item is Map<String, dynamic>) LegalDocumentItem.fromJson(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Document types accepted on the sign-in screen.
  static const Set<String> loginTypes = {'terms', 'privacy_policy'};

  /// Document types covered by the data-use page, accepted with the profile.
  static const Set<String> profileTypes = {'privacy_notice', 'consent'};

  /// Adds [documents], replacing any earlier acceptance of the same type.
  static Future<void> record(List<LegalDocumentItem> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final merged = <String, LegalDocumentItem>{
      for (final d in await accepted()) d.documentType: d,
      for (final d in documents) d.documentType: d,
    };
    await prefs.setString(
      _key,
      jsonEncode([for (final d in merged.values) d.toJson()]),
    );
  }

  /// Whether every document type the server requires has been accepted.
  static Future<bool> isComplete() async {
    final types = {for (final d in await accepted()) d.documentType};
    return types.containsAll({...loginTypes, ...profileTypes});
  }

  static const String _loginKey = 'legal_login_agreement_v1';

  /// Notes that the user, on the sign-in screen, opened the legal documents,
  /// scrolled each to its end and accepted them. The documents' current
  /// versions are only known once signed in, so [recordFromLoginAgreement]
  /// turns this into the recorded consent afterwards.
  static Future<void> markLoginAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginKey, DateTime.now().toUtc().toIso8601String());
  }

  static Future<bool> hasLoginAgreement() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_loginKey) !=
          null;
    } catch (_) {
      return false;
    }
  }

  /// After sign-in: records the server's current Terms of Use and Privacy
  /// Policy versions as accepted, but only if the user agreed on the sign-in
  /// screen. When the server has not configured its documents yet the
  /// agreement is kept and the next sign-in-time check tries again.
  static Future<void> recordFromLoginAgreement(
    OnboardingApiService service,
  ) async {
    if (!await hasLoginAgreement()) {
      debugPrint('[LegalConsent] No sign-in agreement stored; nothing recorded.');
      return;
    }
    final documents = await service.getLegalDocuments();
    debugPrint(
      '[LegalConsent] Server legal documents: configured=${documents.configured}, '
      'types=${documents.items.map((d) => d.documentType).toList()}',
    );
    if (!documents.configured || documents.items.isEmpty) return;
    await record([
      for (final d in documents.items)
        if (loginTypes.contains(d.documentType)) d,
    ]);
    await (await SharedPreferences.getInstance()).remove(_loginKey);
  }

  /// When the profile is completed: records the data-use page (the privacy
  /// notice and the consent) as accepted. Only after the sign-in documents
  /// were accepted; the user can read the page at any time but is not asked.
  static Future<void> recordFromProfileCompletion(
    OnboardingApiService service,
  ) async {
    final types = {for (final d in await accepted()) d.documentType};
    if (!types.containsAll(loginTypes)) {
      debugPrint('[LegalConsent] Sign-in documents not recorded yet: $types');
      return;
    }
    final documents = await service.getLegalDocuments();
    debugPrint(
      '[LegalConsent] Server legal documents: configured=${documents.configured}, '
      'types=${documents.items.map((d) => d.documentType).toList()}',
    );
    if (!documents.configured || documents.items.isEmpty) return;
    await record([
      for (final d in documents.items)
        if (profileTypes.contains(d.documentType)) d,
    ]);
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_loginKey);
    } catch (_) {}
  }
}

/// Service implementing Business profiles, Legal Consent, and Atomic Onboarding (PUT /v1/me/onboarding).
class OnboardingApiService {
  static OnboardingApiService? _instance;
  static OnboardingApiService get instance =>
      _instance ??= OnboardingApiService();
  @visibleForTesting
  static set testInstance(OnboardingApiService? service) => _instance = service;

  final ApiClient _apiClient;
  final ProfileApiService? _profileApiService;

  OnboardingApiService({
    ApiClient? apiClient,
    ProfileApiService? profileApiService,
  }) : _apiClient = apiClient ?? ApiClient(),
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
      body: {'acceptances': acceptances.map((a) => a.toJson()).toList()},
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
    final effectiveEtag =
        etag ??
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
