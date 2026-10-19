import '../network/api_client.dart';

/// The owner's client-reported eligibility results as stored by the server.
///
/// This is persisted client output, not an eligibility decision
/// (`eligibility_verified` is always false).
class EligibilitySnapshot {
  const EligibilitySnapshot({
    required this.schemeIds,
    required this.savedAt,
    required this.version,
    required this.etag,
  });

  final List<String> schemeIds;
  final DateTime? savedAt;

  /// 0 when nothing was ever saved.
  final int version;

  /// Quoted ETag (for example `"eligibility-3"`), sent back as
  /// `X-Eligibility-If-Match` on the next write.
  final String? etag;
}

/// Client for the saved-library routes: favorites and eligibility results.
///
/// The owner always comes from the bearer token. Scheme ids are the canonical
/// ids of the catalog (`TN2026-001`); the server validates them against what the
/// account's saved profile state may see.
class LibraryApiService {
  LibraryApiService({ApiClient? client}) : _client = client;

  final ApiClient? _client;

  ApiClient get _api => _client ?? ApiClient.instance;

  /// A scheme id the library routes accept (1..80 ASCII letters, digits, `_`, `-`).
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$');

  static bool isValidId(String id) => _idPattern.hasMatch(id);

  /// Every favorite of the owner, following `next_cursor` (at most 500 exist).
  Future<List<String>> listAllFavorites({int maxPages = 12}) async {
    final ids = <String>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final response = await _api.get(
        '/v1/me/favorites',
        queryParameters: {'limit': 50, 'cursor': ?cursor},
      );
      final data = response.data;
      if (data is! Map) break;
      final items = data['items'];
      if (items is List) {
        for (final item in items) {
          if (item is Map && item['scheme_id'] != null) {
            ids.add(item['scheme_id'].toString());
          }
        }
      }
      final next = data['next_cursor'];
      cursor = next is String && next.isNotEmpty ? next : null;
      if (cursor == null) break;
    }
    return ids;
  }

  /// `PUT /v1/me/favorites/:id` with no body. Idempotent.
  Future<void> saveFavorite(String id) async {
    await _api.put('/v1/me/favorites/${Uri.encodeComponent(id)}', body: null);
  }

  /// `DELETE /v1/me/favorites/:id`. 204 even when already absent.
  Future<void> removeFavorite(String id) async {
    await _api.delete('/v1/me/favorites/${Uri.encodeComponent(id)}');
  }

  Future<EligibilitySnapshot> getEligibility() async {
    final response = await _api.get('/v1/me/eligibility-results');
    return _snapshot(response);
  }

  /// Replaces the whole set (`[]` clears it). [etag] is the quoted ETag of the
  /// last read; a stale one is answered with `412 ELIGIBILITY_VERSION_CONFLICT`.
  Future<EligibilitySnapshot> putEligibility(
    List<String> schemeIds, {
    required String etag,
  }) async {
    final response = await _api.put(
      '/v1/me/eligibility-results',
      body: {'scheme_ids': schemeIds},
      headers: {'X-Eligibility-If-Match': etag},
    );
    return _snapshot(response);
  }

  EligibilitySnapshot _snapshot(ApiResponse<dynamic> response) {
    final data = response.data;
    final map = data is Map ? data : const {};
    final ids = map['scheme_ids'];
    return EligibilitySnapshot(
      schemeIds: [
        if (ids is List)
          for (final id in ids) id.toString(),
      ],
      savedAt: DateTime.tryParse(map['saved_at']?.toString() ?? '')?.toUtc(),
      version: (map['version'] as num?)?.toInt() ?? 0,
      etag: response.etag,
    );
  }
}
