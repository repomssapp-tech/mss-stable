import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AppConstants {
  // App Color Palette (New Light-Themed Premium Palette)
  static const Color primaryColor = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryColor = Color(0xFF1565C0); // Azure Blue
  static const Color accentColor = Color(0xFFFF9933); // Saffron Orange
  static const Color successColor = Color(0xFF2E7D32); // Emerald Green
  static const Color warningColor = Color(0xFFFB8C00); // Amber Orange
  static const Color errorColor = Color(0xFFD32F2F); // Crimson Red

  static const Color backgroundColor = Color(0xFFF8FAFC); // Ice White
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure White
  static const Color cardBorderColor = Color(0xFFE5E7EB); // Mist Gray

  static const Color primaryText = Color(0xFF111827); // Charcoal Black
  static const Color secondaryText = Color(0xFF6B7280); // Slate Gray

  // Adjusted soft light blue gradient for scaffold background
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
