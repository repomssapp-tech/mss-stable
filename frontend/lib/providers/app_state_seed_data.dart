/// Static fallback / seed content for [AppProvider].
///
/// These lists are the offline defaults shown before (or instead of) the
/// promotions feed from the backend. They were previously inline literals
/// inside `app_state_provider.dart`; extracting them keeps the provider focused
/// on behaviour. No logic lives here — data only.
///
/// The notifications inbox has no seed content: it shows only what the server
/// returns, and an empty inbox is a valid state.
library;

/// Promo-alert carousel fallback, used when `promo_alerts` returns no
/// profile-matching rows.
final List<Map<String, dynamic>> kDefaultPromoAlerts = [
  {
    'title': 'Applications Closing Soon',
    'subtitle': 'PMEGP · 2 days left',
    'badge_text': 'Alert',
    'badge_text_color': '#EA580C',
    'badge_bg_color': '#FFF7ED',
    'target_route': 'notifications',
    'bg_image': 'assets/images/Background/alert banner.webp',
  },
  {
    'title': 'New Scheme',
    'subtitle': 'TN Export Promotion Scheme',
    'badge_text': 'New Scheme',
    'badge_text_color': '#16A34A',
    'badge_bg_color': '#DCFCE7',
    'target_route': 'discover_results',
    'bg_image': 'assets/images/Background/new scheme banner.webp',
  },
  {
    'title': 'Important Update',
    'subtitle': 'UDYAM registration process updated',
    'badge_text': 'Notify',
    'badge_text_color': '#2563EB',
    'badge_bg_color': '#EFF6FF',
    'target_route': 'discover_results',
    'bg_image': 'assets/images/Background/notification banner.webp',
  },
  {
    'title': 'For Women Entrepreneurs',
    'subtitle': 'Explore special funding schemes',
    'badge_text': 'Featured',
    'badge_text_color': '#7C3AED',
    'badge_bg_color': '#F5F3FF',
    'target_route': 'discover_results',
    'bg_image': 'assets/images/Background/suggestion banner.webp',
  },
];
