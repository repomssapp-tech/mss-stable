/// Static fallback / seed content for [AppProvider].
///
/// These lists are the offline defaults shown before (or instead of) the
/// Supabase-backed streams. They were previously inline literals inside
/// `app_state_provider.dart`; extracting them keeps the provider focused on
/// behaviour. No logic lives here — data only.
///
/// TODO(review-seed-content): the notification title/body prose below is
/// real-scheme communication; the Tamil counterparts in app_ta.arb
/// (notifSeed*) are best-effort, not final.
library;

/// Home-screen announcement carousel fallback (used until the live scheme
/// feed populates `announcements`).
final List<Map<String, String>> kDefaultAnnouncements = [
  {
    'title': 'National Entrepreneurs\' Day Celebration',
    'date': '16-Jan-2026',
    'content':
        'Prime Minister launches a new seed grant portal for tech startups and students.',
  },
  {
    'title': 'Tamil Nadu MSME Department Subsidy Hike',
    'date': '04-Jul-2026',
    'content':
        'NEEDS scheme subsidy ceiling raised to ₹75 Lakhs for women and minority entrepreneurs.',
  },
  {
    'title': 'Mudra Loan Shishu Limit Extended',
    'date': '29-May-2026',
    'content':
        'Collateral-free micro loans under Shishu category increased to ₹1 Lakh.',
  },
];

/// Initial notification list, replaced wholesale by the Supabase
/// `notifications` stream once it emits. [AppProvider] deep-copies this so the
/// seed is never mutated by in-place `read` toggles.
final List<Map<String, dynamic>> kSeedNotifications = [
  {
    'id': 'latest_fisheries_update',
    'title': 'Fisheries and Aquaculture Infra Development Fund Scheme Launched',
    'body':
        'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.',
    'timeAgoCount': 2,
    'timeAgoUnit': 'd',
    'read': false,
    'category': 'updates',
    'iconType': 'emblem',
  },
  {
    'id': '1',
    'title': 'PM Vidyalaxmi Education Loan Scheme',
    'body':
        'A new scheme for students to provide collateral-free education loans for higher studies.',
    'timeAgoCount': 2,
    'timeAgoUnit': 'h',
    'read': false,
    'category': 'new_schemes',
    'tag': 'Education',
    'isNew': true,
  },
  {
    'id': '2',
    'title': 'PM Vishwakarma Yojana',
    'body':
        'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.',
    'timeAgoCount': 1,
    'timeAgoUnit': 'd',
    'read': false,
    'category': 'new_schemes',
    'tag': 'Skill Development',
    'isNew': true,
  },
  {
    'id': '3',
    'title': 'Post Matric Scholarship Scheme',
    'body': 'Last date to apply is approaching',
    'timeAgoCount': 10,
    'timeAgoUnit': 'm',
    'read': false,
    'category': 'reminders',
    'deadline': '31 May 2024',
    'daysLeftCount': 5,
  },
  {
    'id': '4',
    'title': 'PM Internship Scheme',
    'body': 'Application window will close soon',
    'timeAgoCount': 3,
    'timeAgoUnit': 'h',
    'read': false,
    'category': 'reminders',
    'deadline': '15 Jun 2024',
    'daysLeftCount': 20,
  },
  {
    'id': '5',
    'title': 'New Update on Ayushman Bharat Yojana',
    'body': 'Changes in empanelment process for hospitals. Check full details.',
    'timeAgoCount': 1,
    'timeAgoUnit': 'd',
    'read': false,
    'category': 'updates',
    'iconType': 'emblem',
  },
  {
    'id': '6',
    'title': 'Income Limit Revised for Several Schemes',
    'body':
        'Revised income criteria effective from 1st April 2024 for multiple schemes.',
    'timeAgoCount': 2,
    'timeAgoUnit': 'd',
    'read': false,
    'category': 'updates',
    'iconType': 'bank',
  },
  {
    'id': '7',
    'title': 'Complete Your Profile',
    'body': 'Add your income details to find schemes you are eligible for.',
    'timeAgoCount': 5,
    'timeAgoUnit': 'h',
    'read': false,
    'category': 'profile',
    'progress': 70,
  },
];

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
