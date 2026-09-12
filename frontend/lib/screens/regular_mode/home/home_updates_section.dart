import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../notifications_screen.dart';

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

    final String tagText;
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
      tagText = context.l10n.tagNewScheme;
    }

    final String titleText = latestUpdate != null
        ? (latestUpdate['title'] as String? ?? '')
        : context.l10n.fallbackLatestUpdateTitle;

    final String timeText;
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
      timeText = context.l10n.time2DaysAgo;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.latestUpdates,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
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
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.tight),
                      Text(
                        titleText,
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.tight),
                      Text(
                        timeText,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
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

class HomeTipOfTheDayCard extends StatelessWidget {
  const HomeTipOfTheDayCard({super.key});

  double _scaledFontSize(BuildContext context, double baseSize) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.selectedLanguage == 'ta' ? baseSize * 0.88 : baseSize;
  }

  double _scaledLineHeight(BuildContext context, [double defaultHeight = 1.28]) {
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
                        style: GoogleFonts.poppins(
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
                  context.l10n.tipOfTheDayContent,
                  style: GoogleFonts.inter(
                    fontSize: _scaledFontSize(context, 10.0),
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: _scaledLineHeight(context, 1.3),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Reserved right spacer to prevent text from overlapping the built-in image graphic
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}
