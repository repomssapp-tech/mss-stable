import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';

const List<Map<String, dynamic>> kNotificationCategories = [
  {'key': 'All', 'label': 'All', 'icon': Icons.notifications_none},
  {
    'key': 'new_schemes',
    'label': 'New Schemes',
    'icon': Icons.shopping_bag_outlined,
  },
  {
    'key': 'reminders',
    'label': 'Reminders',
    'icon': Icons.calendar_today_outlined,
  },
  {'key': 'updates', 'label': 'Updates', 'icon': Icons.campaign_outlined},
  {'key': 'profile', 'label': 'Profile', 'icon': Icons.person_outline},
];

class NotificationHelpers {
  const NotificationHelpers._();

  static Widget buildTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: textCol,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String categoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'All':
        return context.l10n.filterAll;
      case 'new_schemes':
        return context.l10n.notifCatNewSchemes;
      case 'reminders':
        return context.l10n.notifCatReminders;
      case 'updates':
        return context.l10n.notifCatUpdates;
      case 'profile':
        return context.l10n.notifCatProfile;
      default:
        return key;
    }
  }

  static String tagLabel(BuildContext context, dynamic raw) {
    switch (raw?.toString()) {
      case 'Education':
        return context.l10n.notifTagEducation;
      case 'Skill Development':
        return context.l10n.notifTagSkillDevelopment;
    }
    return raw?.toString() ?? '';
  }

  static String timeAgo(BuildContext context, Map<String, dynamic> item) {
    final count = item['timeAgoCount'];
    if (count is int) {
      switch (item['timeAgoUnit']) {
        case 'd':
          return context.l10n.timeAgoDays(count);
        case 'h':
          return context.l10n.timeAgoHours(count);
        case 'm':
          return context.l10n.timeAgoMinutes(count);
      }
    }
    final raw = item['time'];
    if (raw is String && raw.isNotEmpty && raw != 'Just now') return raw;
    return context.l10n.timeAgoJustNow;
  }

  static String daysLeft(BuildContext context, Map<String, dynamic> item) {
    final count = item['daysLeftCount'];
    if (count is int) return context.l10n.daysLeftFmt(count);
    return item['daysLeft']?.toString() ?? '';
  }

  static String deadline(BuildContext context, Map<String, dynamic> item) {
    final raw = item['deadline']?.toString() ?? '';
    final parts = raw.split(' ');
    if (parts.length != 3) return raw;
    const enMonths = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final idx = enMonths.indexOf(
      parts[1].toLowerCase().substring(
            0,
            parts[1].length < 3 ? parts[1].length : 3,
          ),
    );
    if (idx < 0) return raw;
    final localized = context.l10n.monthAbbrList.split(',');
    if (localized.length != 12) return raw;
    return '${parts[0]} ${localized[idx]} ${parts[2]}';
  }

  static String seedText(BuildContext context, dynamic raw) {
    final s = raw?.toString() ?? '';
    final l = context.l10n;
    switch (s) {
      case 'Fisheries and Aquaculture Infra Development Fund Scheme Launched':
        return l.fallbackLatestUpdateTitle;
      case 'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.':
        return l.notifSeed1Body;
      case 'PM Vidyalaxmi Education Loan Scheme':
        return l.notifSeed2Title;
      case 'A new scheme for students to provide collateral-free education loans for higher studies.':
        return l.notifSeed2Body;
      case 'PM Vishwakarma Yojana':
        return l.notifSeed3Title;
      case 'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.':
        return l.notifSeed3Body;
      case 'Post Matric Scholarship Scheme':
        return l.notifSeed4Title;
      case 'Last date to apply is approaching':
        return l.notifSeed4Body;
      case 'PM Internship Scheme':
        return l.notifSeed5Title;
      case 'Application window will close soon':
        return l.notifSeed5Body;
      case 'New Update on Ayushman Bharat Yojana':
        return l.notifSeed6Title;
      case 'Changes in empanelment process for hospitals. Check full details.':
        return l.notifSeed6Body;
      case 'Income Limit Revised for Several Schemes':
        return l.notifSeed7Title;
      case 'Revised income criteria effective from 1st April 2024 for multiple schemes.':
        return l.notifSeed7Body;
      case 'Complete Your Profile':
        return l.completeYourProfile;
      case 'Add your income details to find schemes you are eligible for.':
        return l.notifSeed8Body;
    }
    return s;
  }
}
