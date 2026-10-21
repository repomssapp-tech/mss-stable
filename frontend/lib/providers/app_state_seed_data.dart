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
///
/// Evergreen only: no deadlines, state-specific schemes or "updated" notices,
/// because a fallback card cannot know they are true for this user.
final List<Map<String, dynamic>> kDefaultPromoAlerts = [
  {
    'title': 'For Women Entrepreneurs',
    'subtitle': 'Explore special funding schemes',
    'badge_text': 'Featured',
    'badge_text_color': '#7C3AED',
    'badge_bg_color': '#F5F3FF',
    'target_route': 'discover_results',
    // Opens the Women Entrepreneurship list, not Business & MSME (NEW-04).
    'browse_title': 'Women Entrepreneurship',
    'browse_type': 'category',
    'bg_image': 'assets/images/Background/suggestion banner.webp',
  },
];
