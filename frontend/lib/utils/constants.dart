import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_colors.dart';

class AppConstants {
  // Deprecated (2.3): forwards to AppColors so the 118-file sweep (Phase 3+)
  // can land screen by screen instead of all at once. New code should use
  // AppColors directly. Values differ very slightly from the old hardcoded
  // hex (e.g. primaryText 111827 -> textPrimary 0F172A) -- that's the new
  // token's value, per spec_design_system.md §3.2/§3.3.
  @Deprecated('Use AppColors.primary')
  static const Color primaryColor = AppColors.primary;
  @Deprecated('Use AppColors.primaryStrong')
  static const Color secondaryColor = AppColors.primaryStrong;
  @Deprecated('Use AppColors.accent')
  static const Color accentColor = AppColors.accent;
  @Deprecated('Use AppColors.success')
  static const Color successColor = AppColors.success;
  @Deprecated('Use AppColors.warning')
  static const Color warningColor = AppColors.warning;
  @Deprecated('Use AppColors.danger')
  static const Color errorColor = AppColors.danger;

  @Deprecated('Use AppColors.background')
  static const Color backgroundColor = AppColors.background;
  @Deprecated('Use AppColors.surface')
  static const Color surfaceColor = AppColors.surface;
  @Deprecated('Use AppColors.border')
  static const Color cardBorderColor = AppColors.border;

  @Deprecated('Use AppColors.textPrimary')
  static const Color primaryText = AppColors.textPrimary;
  @Deprecated('Use AppColors.textMuted')
  static const Color secondaryText = AppColors.textMuted;

  @Deprecated('Use AppColors.scaffoldGradient')
  static const LinearGradient blueGradient = AppColors.scaffoldGradient;

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white70, Colors.white60],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Missing Document Assistance External Links (Official Portals)
  static const Map<String, String> documentLinks = {
    'PAN Card': 'https://www.protean-tinpan.com/',
    'Aadhaar Card': 'https://myaadhaar.uidai.gov.in/',
    'Udyam Registration Certificate': 'https://udyamregistration.gov.in/',
    'Nativity Certificate (TN)': 'https://www.tnesevai.tn.gov.in/',
    'Community Certificate': 'https://www.tnesevai.tn.gov.in/',
    'Artisan Identity Card (DC Handicrafts)': 'https://www.handicrafts.nic.in/',
    'DPIIT Certificate of Recognition': 'https://www.startupindia.gov.in/',
    'Certificate of Incorporation (Pvt Ltd / LLP / Registered Partnership)':
        'https://www.mca.gov.in/',
    'Project Report / Business Plan': 'https://dcmsme.gov.in/',
    'Project Report / DPR': 'https://dcmsme.gov.in/',
    'Project Report': 'https://dcmsme.gov.in/',
    'Quotations for machinery/equipment': 'https://www.nsic.co.in/',
    'Price Quotation of machinery/equipment or items to be purchased':
        'https://www.nsic.co.in/',
  };


  /// Returns the localized greeting matching the actual time of day:
  /// - Morning (05:00 - 11:59): goodMorning
  /// - Afternoon (12:00 - 16:59): goodAfternoon
  /// - Evening / Night (17:00 - 04:59): goodEvening
  ///
  /// The ARB values already carry the trailing comma (e.g. "Good Morning,").
  static String getTimeGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return l10n.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }
}
