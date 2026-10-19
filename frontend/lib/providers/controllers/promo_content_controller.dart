import 'package:flutter/foundation.dart';

import '../../services/network/request_manager.dart';
import '../../services/promotions/promotions_api_service.dart';

/// Owns the home-screen promo carousel source data: the banner cards from the
/// promotions API and the in-progress draft cards, plus the fetch-throttle
/// stamps for each.
///
/// Used behind the `AppProvider` facade: `AppProvider` forwards this
/// controller's `notifyListeners`, so `provider.fetchPromoAlerts()` /
/// `provider.fetchDraftSessions()` keep working unchanged, and the
/// profile-derived `carouselItems` getter stays on `AppProvider` reading
/// [promoAlerts] / [draftSessions] off this controller.
///
/// Fetches go through [RequestManager]: a successful load is reused for
/// [freshFor] (30 minutes), so seeing the home screen never refetches, and a
/// failure backs off instead of retrying on every trigger. Pass `force: true`
/// after the language, the account or the profile changes. [reset] (sign-out)
/// is silent — that branch emits its own `AppProvider` notification.
class PromoContentController extends ChangeNotifier {
  PromoContentController({
    PromotionsApiService? apiService,
    RequestManager? requests,
  }) : _apiService = apiService ?? PromotionsApiService(),
       _requests = requests ?? RequestManager.instance;

  final PromotionsApiService _apiService;
  final RequestManager _requests;

  /// A loaded set of cards is reused for this long.
  static const Duration freshFor = Duration(minutes: 30);

  List<Map<String, dynamic>> _promoAlerts = [];
  List<Map<String, dynamic>> _draftSessions = [];

  List<Map<String, dynamic>> get promoAlerts => _promoAlerts;
  List<Map<String, dynamic>> get draftSessions => _draftSessions;

  String? _loadedLanguage;
  static const String _requestKey = 'promotions';

  /// Loads the cards visible to the current account in [language]. The server
  /// applies publication windows and audience targeting, so nothing is
  /// filtered or invented here. A different language bypasses the freshness
  /// window (the text is served in that language).
  Future<void> fetchPromoAlerts({
    bool force = false,
    String language = 'en',
  }) async {
    final apiLanguage = PromotionsApiService.apiLanguage(language);
    await _requests.run<void>(
      _requestKey,
      () async {
        _promoAlerts = await _apiService.getAllPromotions(
          language: apiLanguage,
        );
        _loadedLanguage = apiLanguage;
        notifyListeners();
      },
      minInterval: freshFor,
      force:
          force || (_loadedLanguage != null && _loadedLanguage != apiLanguage),
    );
  }

  /// Draft-progress cards.
  ///
  /// STUB: the backend reference has no endpoint for in-progress questionnaire
  /// drafts (they used to live in the old `questionnaire_sessions` table), so there are no
  /// draft cards until one exists. See `PendingEndpoints`.
  Future<void> fetchDraftSessions({bool force = false}) async {
    if (_draftSessions.isEmpty) return;
    _draftSessions = [];
    notifyListeners();
  }

  /// Clears both lists and their throttle stamps for sign-out — otherwise the
  /// next account to sign in on this device is served the previous user's cards
  /// until the throttle window expires. Silent: the caller notifies.
  void reset() {
    _promoAlerts = [];
    _draftSessions = [];
    _loadedLanguage = null;
    _requests.invalidate(_requestKey);
  }
}
