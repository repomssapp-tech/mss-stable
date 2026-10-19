import '../network/api_client.dart';

/// One page of `GET /v1/promotions`.
class PromotionsPage {
  const PromotionsPage({required this.items, required this.nextCursor});

  /// Home-carousel cards, in the exact shape the carousel reads (`title`,
  /// `subtitle`, `badge_text`, `btn_text`, the five colour fields,
  /// `target_route`, `graphic_type`, `bg_image`, the `target_*` audience fields
  /// and `created_at`).
  final List<Map<String, dynamic>> items;
  final String? nextCursor;
}

/// Client for the promotions (home banner) API.
///
/// Anonymous requests get only broad cards; a signed-in request also gets the
/// cards targeted at the account's saved profile. Targeting is decided by the
/// server, so no gender/state/community is ever sent.
class PromotionsApiService {
  PromotionsApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// The API serves English and Tamil only; any other app language gets English
  /// (an unsupported value is a 400).
  static String apiLanguage(String appLanguage) =>
      appLanguage == 'ta' ? 'ta' : 'en';

  Future<PromotionsPage> getPromotions({
    required String language,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get(
      '/v1/promotions',
      queryParameters: {
        'language': apiLanguage(language),
        'limit': limit.clamp(1, 50),
        'cursor': ?cursor,
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const PromotionsPage(items: [], nextCursor: null);
    }
    final raw = data['items'];
    final cursorValue = data['next_cursor'];
    return PromotionsPage(
      items: [
        if (raw is List)
          for (final item in raw)
            if (item is Map) Map<String, dynamic>.from(item),
      ],
      nextCursor: cursorValue is String && cursorValue.isNotEmpty
          ? cursorValue
          : null,
    );
  }

  /// Every visible card, following `next_cursor` (bounded to [maxPages]).
  Future<List<Map<String, dynamic>>> getAllPromotions({
    required String language,
    int maxPages = 4,
  }) async {
    final all = <Map<String, dynamic>>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final result = await getPromotions(
        language: language,
        limit: 50,
        cursor: cursor,
      );
      all.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return all;
  }
}
