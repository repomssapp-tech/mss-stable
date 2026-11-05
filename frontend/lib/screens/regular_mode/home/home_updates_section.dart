import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
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
        // When the heading and the button don't fit side by side (Tamil and
        // Hindi on a narrow phone), the button moves to its own line, so
        // neither ever breaks inside a word.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            Text(
              context.l10n.latestUpdates,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            // Opens the full inbox, every category.
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Text(context.l10n.viewAll, textAlign: TextAlign.end),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: BorderSide(
              color: AppColors.border,
              width: AppSize.borderWidth,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => latestUpdate == null
                      ? const NotificationsScreen()
                      : NotificationDetailScreen(item: latestUpdate),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppSize.avatarSm,
                    height: AppSize.avatarSm,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.primary,
                      size: AppSize.icon,
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
                              color: AppTagStyle.level.background,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              tagText,
                              style: context.text.label.copyWith(
                                color: AppTagStyle.level.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.tight),
                        ],
                        Text(
                          titleText,
                          style: context.text.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeText != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            timeText,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.iconMuted,
                    size: AppSize.icon,
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(
            AssetImage('assets/images/Background/tip banner.webp'),
            width: 1080,
          ),
          fit: BoxFit.cover,
          // The art sits on the right; keep it in view on tall cards.
          alignment: Alignment.centerRight,
        ),
        borderRadius: AppRadius.lgAll,
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
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.textSecondary,
                      size: AppSize.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Expanded(
                      child: Text(
                        context.l10n.tipOfTheDay,
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.tight),
                // The whole tip, however long it runs in Tamil or Hindi.
                Text(
                  homeTips(context.l10n)[_tip],
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          // Keeps the text clear of the bulb-and-note art on the banner's right.
          const SizedBox(width: 112), // spacing-ok: banner art width
        ],
      ),
    );
  }
}
