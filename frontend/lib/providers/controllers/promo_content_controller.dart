import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns the home-screen promo carousel source data: the `promo_alerts` rows
/// and the in-progress draft `questionnaire_sessions`, plus the fetch-throttle
/// stamps for each.
///
/// Extracted from `AppProvider` (frontend refactor C1.4, slice 6) and used
/// behind the `AppProvider` facade: `AppProvider` forwards this controller's
/// `notifyListeners`, so `provider.fetchPromoAlerts()` /
/// `provider.fetchDraftSessions()` keep working unchanged, and the
/// profile-derived `carouselItems` getter stays on `AppProvider` (it needs
/// `_profile` for the gender/state/community filter) reading [promoAlerts] /
/// [draftSessions] off this controller.
///
/// Both fetches are throttled — they are each called from up to four places
/// on a single launch (the realtime profile stream, the auth-state listener,
/// `_loadState`, `checkSessionAndFetchProfile`). Pass `force: true` after the
/// user actually edits a draft. Every fetch that changes state notifies once,
/// exactly as the pre-split code did. [reset] (auth `signedOut` branch) is
/// silent — that branch emits its own `AppProvider` notification.
class PromoContentController extends ChangeNotifier {
  List<Map<String, dynamic>> _promoAlerts = [];
  List<Map<String, dynamic>> _draftSessions = [];

  List<Map<String, dynamic>> get promoAlerts => _promoAlerts;
  List<Map<String, dynamic>> get draftSessions => _draftSessions;

  DateTime? _lastPromoFetch;
  static const Duration _promoFetchThrottle = Duration(minutes: 30);

  Future<void> fetchPromoAlerts({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastPromoFetch != null &&
        now.difference(_lastPromoFetch!) < _promoFetchThrottle) {
      return;
    }
    _lastPromoFetch = now;
    try {
      final res = await Supabase.instance.client.from('promo_alerts').select();

      final mapped = List<Map<String, dynamic>>.from(res).map((item) {
        final mutable = Map<String, dynamic>.from(item);
        if (mutable['bg_image'] == null ||
            mutable['bg_image'].toString().isEmpty) {
          final title = (mutable['title'] ?? '').toString().toLowerCase();
          final badge = (mutable['badge_text'] ?? '').toString().toLowerCase();
          if (badge.contains('alert') ||
              title.contains('closing') ||
              title.contains('deadline')) {
            mutable['bg_image'] = 'assets/images/Background/alert banner.webp';
            mutable['badge_text_color'] = '#EA580C';
            mutable['badge_bg_color'] = '#FFF7ED';
          } else if (badge.contains('new') ||
              title.contains('new scheme') ||
              title.contains('export')) {
            mutable['bg_image'] =
                'assets/images/Background/new scheme banner.webp';
            mutable['badge_text_color'] = '#16A34A';
            mutable['badge_bg_color'] = '#DCFCE7';
          } else if (badge.contains('notify') ||
              title.contains('update') ||
              title.contains('udyam')) {
            mutable['bg_image'] =
                'assets/images/Background/notification banner.webp';
            mutable['badge_text_color'] = '#2563EB';
            mutable['badge_bg_color'] = '#EFF6FF';
          } else {
            mutable['bg_image'] =
                'assets/images/Background/suggestion banner.webp';
            mutable['badge_text_color'] = '#7C3AED';
            mutable['badge_bg_color'] = '#F5F3FF';
          }
        }
        return mutable;
      }).toList();

      _promoAlerts = mapped;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Error fetching promo alerts: $e');
    }
  }

  DateTime? _lastDraftFetch;
  static const Duration _draftFetchThrottle = Duration(minutes: 5);

  /// Throttled like [fetchPromoAlerts]. This is called from four places --
  /// the realtime profile stream, the auth-state listener, `_loadState`, and
  /// `checkSessionAndFetchProfile` -- so an unthrottled version re-queried
  /// `questionnaire_sessions` on every profile row change and several times
  /// per app launch. Pass `force: true` after the user actually edits a draft.
  Future<void> fetchDraftSessions({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastDraftFetch != null &&
        now.difference(_lastDraftFetch!) < _draftFetchThrottle) {
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _draftSessions = [];
        _lastDraftFetch = null;
        notifyListeners();
        return;
      }
      _lastDraftFetch = now;

      final res = await Supabase.instance.client
          .from('questionnaire_sessions')
          .select(
            'id, completed_percentage, status, startup_profiles!inner(user_id, profile_name)',
          )
          .eq('status', 'IN_PROGRESS')
          .eq('startup_profiles.user_id', userId);

      _draftSessions = List<Map<String, dynamic>>.from(res).map((item) {
        final startup = item['startup_profiles'] as Map<String, dynamic>;
        final pct = (item['completed_percentage'] as num?)?.toDouble() ?? 0.0;
        return {
          'id': item['id'],
          'title': '${startup['profile_name']} Setup',
          'badge_text': 'Draft',
          'badge_text_color': '#2563EB',
          'badge_bg_color': '#EFF6FF',
          'bg_gradient_start': '#EFF6FF',
          'bg_gradient_end': '#DBEAFE',
          'btn_text': 'Continue',
          'btn_color': '#2563EB',
          'target_route': 'draft_session',
          'graphic_type': 'progress',
          'progress': pct,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[AppProvider] Error fetching draft sessions: $e');
    }
  }

  /// Clears both lists and their throttle stamps for the auth `signedOut`
  /// branch — otherwise the next account to sign in on this device is served
  /// the previous user's rows until the throttle window expires. Silent: the
  /// caller notifies.
  void reset() {
    _promoAlerts = [];
    _draftSessions = [];
    _lastPromoFetch = null;
    _lastDraftFetch = null;
  }
}
