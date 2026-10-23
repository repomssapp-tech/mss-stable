import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../account/token_storage.dart';
import 'api_exception.dart';

/// Wraps successful HTTP response data and relevant metadata.
class ApiResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, String> headers;

  const ApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
  });

  String? get etag => headers['etag'] ?? headers['ETag'];
  String? get requestId => headers['x-request-id'] ?? headers['X-Request-ID'];
}

/// Central HTTP Client for MSS REST Backend APIs (`/v1`).
///
/// Features:
/// - Injects `Authorization: Bearer <token>` on protected routes.
/// - Injects standard JSON Content-Type and Accept headers.
/// - Single-flight token refresh mutex: parallel 401s share one `/auth/refresh` flight.
/// - Rate limit backoff (429 Retry-After) detection.
/// - Never logs sensitive authorization URLs, codes, tokens, or profile payloads.
class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient();
  @visibleForTesting
  static set testInstance(ApiClient? client) => _instance = client;

  final String _baseUrl;
  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  final VoidCallback? onSessionExpired;

  // Single-flight refresh mutex. Static on purpose: the app builds several
  // clients (auth, profile, onboarding, shared) over the same stored tokens.
  // The server rotates the refresh token on every use and revokes the whole
  // session if one is used twice, so concurrent 401s on different clients must
  // share one refresh flight or the user is signed out.
  static Future<String?>? _inFlightRefresh;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    this.onSessionExpired,
  }) : _baseUrl = baseUrl ?? AppConfig.apiV1Url,
       _httpClient = httpClient ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage.instance;

  String get baseUrl => _baseUrl;

  /// Native/browser voice sockets authenticate in their first frame. Reuse
  /// the shared refresh mutex so opening a voice turn cannot rotate twice.
  Future<String> validAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh || await _tokenStorage.isAccessTokenExpired()) {
      final refreshed = await _refreshTokensShared();
      if (refreshed == null) {
        throw const ApiException(
          statusCode: 401,
          errorCode: 'UNAUTHORIZED',
          message: 'Authentication required',
        );
      }
    }
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        errorCode: 'UNAUTHORIZED',
        message: 'Authentication required',
      );
    }
    return token;
  }

  Uri buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;

    String fullUrl;
    if (normalizedBase.endsWith('/v1')) {
      if (cleanPath.startsWith('/v1/')) {
        fullUrl = '$normalizedBase${cleanPath.substring(3)}';
      } else if (cleanPath == '/v1') {
        fullUrl = normalizedBase;
      } else {
        fullUrl = '$normalizedBase$cleanPath';
      }
    } else {
      fullUrl = '$normalizedBase$cleanPath';
    }

    final uri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final queryMap = <String, String>{};
    for (final entry in queryParameters.entries) {
      if (entry.value != null) {
        queryMap[entry.key] = entry.value.toString();
      }
    }
    return uri.replace(queryParameters: queryMap);
  }

  /// Sends a GET request expecting JSON.
  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// Sends a POST request with an optional JSON body.
  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// Sends a PATCH request with a JSON body.
  Future<ApiResponse<dynamic>> patch(
    String path, {
    required dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'PATCH',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// Sends a PUT request with a JSON body.
  Future<ApiResponse<dynamic>> put(
    String path, {
    required dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'PUT',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// Sends a DELETE request.
  Future<ApiResponse<dynamic>> delete(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(
      method: 'DELETE',
      path: path,
      body: body,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  /// Streams raw binary bytes (for gzip catalog bundles).
  Future<ApiResponse<Uint8List>> getBytes(
    String path, {
    Map<String, String>? headers,
    int? maxByteSize,
  }) async {
    final uri = buildUri(path);
    final requestHeaders = <String, String>{
      'Accept': 'application/gzip, application/octet-stream, */*',
      ...?headers,
    };

    final response = await _httpClient.get(uri, headers: requestHeaders);

    if (response.statusCode == 304) {
      return ApiResponse<Uint8List>(
        data: Uint8List(0),
        statusCode: 304,
        headers: response.headers,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }

    final bytes = response.bodyBytes;
    if (maxByteSize != null && bytes.length > maxByteSize) {
      throw ApiException(
        statusCode: 413,
        errorCode: 'PAYLOAD_TOO_LARGE',
        message:
            'Download exceeds maximum size of $maxByteSize bytes (${bytes.length} received)',
      );
    }

    return ApiResponse<Uint8List>(
      data: bytes,
      statusCode: response.statusCode,
      headers: response.headers,
    );
  }

  /// Executes request with automatic 401 token refresh retry (one-time).
  Future<ApiResponse<dynamic>> _sendWithRetry({
    required String method,
    required String path,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required bool requiresAuth,
  }) async {
    final uri = buildUri(path, queryParameters);
    final requestBody = _encodeBody(body);
    // A request without a body carries no Content-Type: several routes (account
    // deletion, logout, favorites) reject an absent body that is declared JSON.
    final hasBody = requestBody != null;
    final requestHeaders = await _buildHeaders(
      headers,
      requiresAuth,
      hasBody: hasBody,
    );

    http.Response response;
    try {
      response = await _sendRequest(method, uri, requestHeaders, requestBody);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
        message: 'Network request failed: $e',
      );
    }

    // Single-flight refresh on 401 Unauthorized for authenticated routes
    if (response.statusCode == 401 &&
        requiresAuth &&
        !path.contains('/auth/')) {
      final newToken = await _refreshTokensShared();
      if (newToken != null && newToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        response = await _sendRequest(method, uri, requestHeaders, requestBody);
      } else {
        // Refresh failed; notify session expiration
        onSessionExpired?.call();
      }
    }

    return _processResponse(response);
  }

  /// Shared single-flight refresh operation.
  Future<String?> _refreshTokensShared() async {
    final ongoing = _inFlightRefresh;
    if (ongoing != null) return ongoing;

    final refreshOperation = _executeTokenRefresh();
    _inFlightRefresh = refreshOperation;
    try {
      return await refreshOperation;
    } finally {
      _inFlightRefresh = null;
    }
  }

  /// Calls POST /v1/auth/refresh and updates TokenStorage atomically.
  Future<String?> _executeTokenRefresh() async {
    // The user signing out while this request is in flight must win: the
    // rotated tokens are then thrown away, not written back.
    final epoch = _tokenStorage.signOutEpoch;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _tokenStorage.clear();
        return null;
      }

      final uri = buildUri('/auth/refresh');
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['access_token']?.toString();
        final newRefresh = data['refresh_token']?.toString();
        final expiresIn = (data['expires_in'] as num?)?.toInt();
        final tokenType = data['token_type']?.toString() ?? 'Bearer';

        if (_tokenStorage.signOutEpoch != epoch) {
          debugPrint('[ApiClient] Signed out during refresh; dropping tokens.');
          return null;
        }
        if (newAccess != null && newRefresh != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
            tokenType: tokenType,
            expiresIn: expiresIn,
          );
          return newAccess;
        }
      }

      // Reusing a consumed token or invalid refresh revokes session
      await _tokenStorage.clear();
      return null;
    } catch (e) {
      debugPrint('[ApiClient] Token refresh failed: $e');
      return null;
    }
  }

  Future<http.Response> _sendRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: body);
      case 'PATCH':
        return _httpClient.patch(uri, headers: headers, body: body);
      case 'PUT':
        return _httpClient.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _httpClient.delete(uri, headers: headers, body: body);
      default:
        throw StateError('Unsupported HTTP method: $method');
    }
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? custom,
    bool requiresAuth, {
    bool hasBody = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json',
    };

    if (custom != null) {
      for (final entry in custom.entries) {
        if (entry.key.toLowerCase() == 'content-type') {
          headers.remove('Content-Type');
        }
        headers[entry.key] = entry.value;
      }
    }

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  String? _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  ApiResponse<dynamic> _processResponse(http.Response response) {
    final status = response.statusCode;

    // HTTP 204 No Content and HTTP 304 Not Modified have no body
    if (status == 204 || status == 304 || response.body.isEmpty) {
      return ApiResponse<dynamic>(
        data: null,
        statusCode: status,
        headers: response.headers,
      );
    }

    if (status >= 200 && status < 300) {
      try {
        final decoded = jsonDecode(response.body);
        return ApiResponse<dynamic>(
          data: decoded,
          statusCode: status,
          headers: response.headers,
        );
      } catch (_) {
        return ApiResponse<dynamic>(
          data: response.body,
          statusCode: status,
          headers: response.headers,
        );
      }
    }

    _throwError(response);
  }

  Never _throwError(http.Response response) {
    String errorCode = 'UNKNOWN_ERROR';
    String message = 'HTTP ${response.statusCode}';
    List<dynamic>? details;
    Map<String, dynamic>? fields;
    int? retryAfter;

    final retryHeader = response.headers['retry-after'];
    if (retryHeader != null) {
      retryAfter = int.tryParse(retryHeader);
    }

    final requestId =
        response.headers['x-request-id'] ?? response.headers['X-Request-ID'];

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] != null) errorCode = body['error'].toString();
        if (body['message'] != null) message = body['message'].toString();
        if (body['details'] is List) details = body['details'] as List<dynamic>;
        if (body['details'] is Map<String, dynamic>) {
          fields = body['details'] as Map<String, dynamic>;
        }
      }
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }

    throw ApiException(
      statusCode: response.statusCode,
      errorCode: errorCode,
      message: message,
      details: details,
      fields: fields,
      retryAfterSeconds: retryAfter,
      requestId: requestId,
    );
  }
}
