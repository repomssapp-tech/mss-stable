import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when an MSS API call fails or returns an error payload.
@immutable
class MssApiException implements Exception {
  const MssApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.field,
    this.detail,
    this.isRetryable = false,
  });

  final int statusCode;
  final String code;
  final String message;
  final String? field;
  final String? detail;
  final bool isRetryable;

  @override
  String toString() {
    final buffer = StringBuffer('MssApiException($statusCode, $code): $message');
    if (field != null) buffer.write(' [field: $field]');
    if (detail != null) buffer.write(' ($detail)');
    return buffer.toString();
  }
}

/// Standalone REST API Client for the MSS Backend.
///
/// Implements endpoints documented in `API_ENDPOINT_REFERENCE.md`.
/// Follows the established HTTP client pattern:
/// - Accepts injectable [http.Client]
/// - Tracks client ownership via [_ownsClient]
/// - Implements [close] method
/// - Handles [TimeoutException], [http.ClientException], and [FormatException]
class MssApiClient {
  MssApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
    String Function()? authTokenProvider,
  })  : _providedClient = client,
        _ownsClient = client == null,
        _authTokenProvider = authTokenProvider,
        baseUrl = baseUrl ?? defaultBaseUrl;

  /// Project key sent as the `apikey` header and used as the fallback bearer
  /// token for guests. This is the publishable key -- safe to ship in the
  /// binary by design, and verified to satisfy the Edge Function gateway's
  /// `verify_jwt` check. Overridable via
  /// `--dart-define-from-file=dart_defines.json` (key `SUPABASE_PUBLISHABLE_KEY`,
  /// unified with main.dart); the compiled default is the production
  /// publishable key so the app runs with no build flags.
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_GnJpz6ZxuGeeroG92VkbBA_b3_pyTvN',
  );

  final String Function()? _authTokenProvider;

  /// Bearer token for `/v1` calls: the signed-in user's access token when a
  /// session exists, otherwise [supabaseKey] so guests -- who never get a
  /// Supabase session, since the app has no anonymous sign-in -- still pass
  /// the gateway once the function runs with `verify_jwt: true`.
  String _authToken() {
    final provided = _authTokenProvider;
    if (provided != null) return provided();
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {
      // Supabase not initialised (unit tests, isolates) -- fall back below.
    }
    return supabaseKey;
  }

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer ${_authToken()}',
      };

  /// Default Base URL configuration point.
  /// Overridden via `--dart-define=MSS_API_BASE_URL=...` or constructor argument.
  ///
  /// Points at the deployed Supabase Edge Function named "v1"
  /// (backend/supabase/functions/v1/index.ts), which currently implements
  /// GET /v1/meta and GET /v1/health only -- the rest of the /v1/* contract
  /// intentionally has no live backend yet and relies on the offline catalog
  /// bundle fallback already built into SchemeRepository.
  static const String defaultBaseUrl = String.fromEnvironment(
    'MSS_API_BASE_URL',
    defaultValue: 'https://houpzsxmwemoztpuigmo.supabase.co/functions/v1',
  );

  final http.Client? _providedClient;
  http.Client? _lazyClient;
  http.Client get _client => _providedClient ?? (_lazyClient ??= http.Client());
  final bool _ownsClient;
  final String baseUrl;
  final Duration timeout;

  /// Closes the HTTP client if this instance owns it.
  void close() {
    if (_ownsClient) {
      _lazyClient?.close();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Search (POST /v1/search)
  // ---------------------------------------------------------------------------
  /// Search schemes by free-text query, optionally filtered/scoped by profile.
  ///
  /// Note: The request field name is `language` (e.g. 'en', 'ta').
  Future<Map<String, dynamic>> search({
    required String query,
    String language = 'en',
    Map<String, dynamic>? profile,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? sort,
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final page = <String, dynamic>{};
    if (cursor != null && cursor.isNotEmpty) {
      page['cursor'] = cursor;
    } else {
      if (limit != null) page['limit'] = limit;
      if (offset != null) page['offset'] = offset;
    }

    final body = <String, dynamic>{
      'query': query,
      'language': language,
    };
    if (profile != null) body['profile'] = profile;
    if (filters != null) body['filters'] = filters;
    if (sort != null) body['sort'] = sort;
    if (page.isNotEmpty) body['page'] = page;

    return _post('/v1/search', body);
  }

  // ---------------------------------------------------------------------------
  // 2. Scheme Detail (GET /v1/schemes/{schemeId})
  // ---------------------------------------------------------------------------
  /// Full relationship neighbourhood for one scheme.
  Future<Map<String, dynamic>> getSchemeDetail(
    String schemeId, {
    String? lang,
  }) async {
    final queryParams = <String, String>{};
    if (lang != null && lang.isNotEmpty) {
      queryParams['lang'] = lang;
    }
    return _get('/v1/schemes/$schemeId', queryParams);
  }

  // ---------------------------------------------------------------------------
  // 3. Eligibility / Applicability (POST /v1/eligibility)
  // ---------------------------------------------------------------------------
  /// Profile-based structured eligibility match across all schemes.
  Future<Map<String, dynamic>> checkEligibility({
    required Map<String, dynamic> profile,
    bool onlyEligible = false,
    int? limit,
    String? cursor,
  }) async {
    final body = <String, dynamic>{
      'profile': profile,
      'onlyEligible': onlyEligible,
    };
    if (limit != null) body['limit'] = limit;
    if (cursor != null && cursor.isNotEmpty) body['cursor'] = cursor;

    return _post('/v1/eligibility', body);
  }

  // ---------------------------------------------------------------------------
  // 4. Finance Products
  // ---------------------------------------------------------------------------
  /// List all finance products.
  Future<Map<String, dynamic>> getFinanceProducts({
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final queryParams = _buildPaginationParams(limit: limit, offset: offset, cursor: cursor);
    return _get('/v1/finance-products', queryParams);
  }

  /// Get single finance product by ID.
  Future<Map<String, dynamic>> getFinanceProductDetail(String financeId) async {
    return _get('/v1/finance-products/$financeId');
  }

  /// Get all finance products linked to a specific scheme.
  Future<Map<String, dynamic>> getFinanceProductsByScheme(String schemeId) async {
    return _get('/v1/schemes/$schemeId/finance');
  }

  // ---------------------------------------------------------------------------
  // 5. Clusters / Tax / Privileges
  // ---------------------------------------------------------------------------
  /// List clusters.
  Future<Map<String, dynamic>> getClusters({
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final queryParams = _buildPaginationParams(limit: limit, offset: offset, cursor: cursor);
    return _get('/v1/clusters', queryParams);
  }

  /// Get single cluster detail by ID.
  Future<Map<String, dynamic>> getClusterDetail(String clusterId) async {
    return _get('/v1/clusters/$clusterId');
  }

  /// List tax provisions.
  Future<Map<String, dynamic>> getTaxProvisions({
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final queryParams = _buildPaginationParams(limit: limit, offset: offset, cursor: cursor);
    return _get('/v1/tax', queryParams);
  }

  /// Get single tax provision detail by ID.
  Future<Map<String, dynamic>> getTaxProvisionDetail(String taxId) async {
    return _get('/v1/tax/$taxId');
  }

  /// List privileges.
  Future<Map<String, dynamic>> getPrivileges({
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final queryParams = _buildPaginationParams(limit: limit, offset: offset, cursor: cursor);
    return _get('/v1/privileges', queryParams);
  }

  /// Get single privilege detail by ID.
  Future<Map<String, dynamic>> getPrivilegeDetail(String privilegeId) async {
    return _get('/v1/privileges/$privilegeId');
  }

  // ---------------------------------------------------------------------------
  // 6. Relationships (GET /v1/relationships/{entityId})
  // ---------------------------------------------------------------------------
  /// Full edge list for any entity (not just schemes).
  Future<Map<String, dynamic>> getRelationships(String entityId) async {
    return _get('/v1/relationships/$entityId');
  }

  // ---------------------------------------------------------------------------
  // 7. Localization (GET /v1/localization/{entityId}?lang=ta)
  // ---------------------------------------------------------------------------
  /// Field-level translation status and content for one entity.
  ///
  /// Note: The query parameter name is `lang` (e.g. 'ta').
  Future<Map<String, dynamic>> getLocalization(
    String entityId, {
    String lang = 'ta',
  }) async {
    return _get('/v1/localization/$entityId', {'lang': lang});
  }

  // ---------------------------------------------------------------------------
  // 8. Meta / Metadata (GET /v1/meta)
  // ---------------------------------------------------------------------------
  /// Catalog version, entity counts, coverage stats.
  Future<Map<String, dynamic>> getMetadata() async {
    return _get('/v1/meta');
  }

  // ---------------------------------------------------------------------------
  // 9. Health (GET /v1/health)
  // ---------------------------------------------------------------------------
  /// Liveness/diagnostic check.
  Future<Map<String, dynamic>> getHealth() async {
    return _get('/v1/health');
  }

  // ---------------------------------------------------------------------------
  // Private Helper Methods
  // ---------------------------------------------------------------------------
  Map<String, String> _buildPaginationParams({
    int? limit,
    int? offset,
    String? cursor,
  }) {
    final params = <String, String>{};
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    } else {
      if (limit != null) params['limit'] = limit.toString();
      if (offset != null) params['offset'] = offset.toString();
    }
    return params;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? queryParameters,
  ]) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.isNotEmpty == true ? queryParameters : null,
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: _headers(),
          )
          .timeout(timeout);

      return _processResponse(response);
    } on TimeoutException catch (e) {
      throw MssApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'Request timed out after ${timeout.inSeconds} seconds: $e',
        isRetryable: true,
      );
    } on http.ClientException catch (e) {
      throw MssApiException(
        statusCode: 503,
        code: 'NETWORK_ERROR',
        message: 'Network request failed: ${e.message}',
        isRetryable: true,
      );
    } on FormatException catch (e) {
      throw MssApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Failed to parse response JSON: ${e.message}',
        isRetryable: true,
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await _client
          .post(
            uri,
            headers: _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _processResponse(response);
    } on TimeoutException catch (e) {
      throw MssApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'Request timed out after ${timeout.inSeconds} seconds: $e',
        isRetryable: true,
      );
    } on http.ClientException catch (e) {
      throw MssApiException(
        statusCode: 503,
        code: 'NETWORK_ERROR',
        message: 'Network request failed: ${e.message}',
        isRetryable: true,
      );
    } on FormatException catch (e) {
      throw MssApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Failed to parse response JSON: ${e.message}',
        isRetryable: true,
      );
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (response.statusCode >= 400) {
        throw MssApiException(
          statusCode: response.statusCode,
          code: 'HTTP_ERROR_${response.statusCode}',
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Error"}',
          isRetryable: response.statusCode == 500 || response.statusCode == 503,
        );
      }
      rethrow;
    }

    final isErrorPayload = decoded['contract'] == 'error' || decoded.containsKey('error');

    if (response.statusCode >= 400 || isErrorPayload) {
      // The Edge Function's error shape is flat -- `error` is itself the
      // code/short-message string (e.g. "INVALID_REQUEST" or "Route not
      // found"), with `message`/`field`/`detail` as sibling keys, never
      // nested under `error`. See backend/supabase/functions/v1/index.ts's
      // json({ error: ... }) call sites.
      final code = decoded['error'] is String
          ? decoded['error'] as String
          : 'UNKNOWN_ERROR';
      final message = (decoded['message'] as String?) ?? code;
      final field = decoded['field'] as String?;
      final detail = decoded['detail'] as String?;

      final isRetryable = code == 'CATALOG_UNAVAILABLE' ||
          code == 'INTERNAL_ERROR' ||
          response.statusCode == 500 ||
          response.statusCode == 503;

      throw MssApiException(
        statusCode: response.statusCode >= 400 ? response.statusCode : 400,
        code: code,
        message: message,
        field: field,
        detail: detail,
        isRetryable: isRetryable,
      );
    }

    return decoded;
  }
}
