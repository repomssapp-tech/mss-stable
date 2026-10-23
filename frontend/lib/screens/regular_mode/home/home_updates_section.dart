import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../notifications_screen.dart';
import '../../../utils/app_text.dart';

class HomeUpdatesSection extends StatelessWidget {
  final AppProvider? provider;

  const HomeUpdatesSection({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    final appProvider = provider ?? Provider.of<AppProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeLatestUpdatesCard(provider: appProvider),
        const SizedBox(height: AppSpacing.xxl),
        const HomeTipOfTheDayCard(),
      ],
    );
  }
}

class HomeLatestUpdatesCard extends StatelessWidget {
  final AppProvider? provider;

  const HomeLatestUpdatesCard({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    final appProvider = provider ?? Provider.of<AppProvider>(context);
    final updates = appProvider.notifications;
    final latestUpdate = updates.isNotEmpty ? updates.first : null;

    // With no notifications the card says so. It used to show a made-up
    // "New scheme" update ("Fisheries ... Launched", "2 days ago") that the
    // Notifications screen it opens could never list.
    final String? tagText;
    if (latestUpdate != null) {
      final category = latestUpdate['category'] as String?;
      if (category == 'new_schemes') {
        tagText = context.l10n.tagNewScheme;
      } else if (category == 'updates') {
        tagText = context.l10n.tagUpdate;
      } else if (category == 'reminders') {
        tagText = context.l10n.tagReminder;
      } else {
        tagText = context.l10n.tagAlert;
      }
    } else {
      tagText = null;
    }

    final String titleText = latestUpdate != null
        ? NotificationHelpers.seedText(
            context,
            latestUpdate['title'] as String? ?? '',
          )
        : context.l10n.notifEmptyBody;

    final String? timeText;
    if (latestUpdate != null) {
      final count = latestUpdate['timeAgoCount'];
      final unit = latestUpdate['timeAgoUnit'];
      if (count is int && unit == 'd') {
        timeText = context.l10n.timeAgoDays(count);
      } else if (count is int && unit == 'h') {
        timeText = context.l10n.timeAgoHours(count);
      } else if (count is int && unit == 'm') {
        timeText = context.l10n.timeAgoMinutes(count);
      } else {
        timeText = context.l10n.timeAgoJustNow;
      }
    } else {
      timeText = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.latestUpdates,
                style: AppGoogleFonts.poppins(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            // Opens the full inbox, every category.
            // An equal share of the row, at most its natural width: long Tamil
            // and Hindi labels wrap between words, never inside one.
            Flexible(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Text(context.l10n.viewAll, textAlign: TextAlign.end),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tagText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.hairline,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tagText,
                            style: AppGoogleFonts.inter(
                              color: const Color(0xFF2563EB),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.tight),
                      ],
                      Text(
                        titleText,
                        style: AppGoogleFonts.inter(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeText != null) ...[
                        const SizedBox(height: AppSpacing.tight),
                        Text(
                          timeText,
                          style: AppGoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The tips shown on Home, one per app launch, in order (index 0 is the
/// original single tip).
List<String> homeTips(AppLocalizations l10n) => [
  l10n.tipOfTheDayContent,
  l10n.homeTip2,
  l10n.homeTip3,
  l10n.homeTip4,
  l10n.homeTip5,
  l10n.homeTip6,
  l10n.homeTip7,
  l10n.homeTip8,
  l10n.homeTip9,
  l10n.homeTip10,
];

/// Which tip this app launch shows: read once per launch from local storage
/// and advanced for the next one, so every time the app is opened the user
/// sees the next tip.
class HomeTipRotation {
  HomeTipRotation._();

  static const String prefKey = 'home_tip_index';
  static Future<int>? _thisLaunch;

  static Future<int> index(int count) => _thisLaunch ??= () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getInt(prefKey) ?? 0) % count;
      await prefs.setInt(prefKey, (current + 1) % count);
      return current;
    } catch (_) {
      return 0;
    }
  }();

  @visibleForTesting
  static void resetForTesting() => _thisLaunch = null;
}

class HomeTipOfTheDayCard extends StatefulWidget {
  const HomeTipOfTheDayCard({super.key});

  @override
  State<HomeTipOfTheDayCard> createState() => _HomeTipOfTheDayCardState();
}

class _HomeTipOfTheDayCardState extends State<HomeTipOfTheDayCard> {
  int _tip = 0;

  @override
  void initState() {
    super.initState();
    HomeTipRotation.index(10).then((i) {
      if (mounted && i != _tip) setState(() => _tip = i);
    });
  }

  double _scaledFontSize(BuildContext context, double baseSize) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta' ? baseSize * 0.88 : baseSize;
  }

  double _scaledLineHeight(
    BuildContext context, [
    double defaultHeight = 1.28,
  ]) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta'
        ? defaultHeight * 1.06
        : defaultHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: ResizeImage(
            AssetImage('assets/images/Background/tip banner.webp'),
            width: 1080,
          ),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Expanded(
                      child: Text(
                        context.l10n.tipOfTheDay,
                        style: AppGoogleFonts.poppins(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  homeTips(context.l10n)[_tip],
                  style: AppGoogleFonts.inter(
                    fontSize: _scaledFontSize(context, 10.0),
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: _scaledLineHeight(context, 1.3),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Keeps the text clear of the bulb-and-note art on the banner's right.
          const SizedBox(width: 104),
        ],
      ),
    );
  }
}
