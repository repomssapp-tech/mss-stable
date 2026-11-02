import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../utils/language_names.dart';

class ProfileValueFormatters {
  const ProfileValueFormatters._();

  // Onboarding stores the *label* the user tapped, so a profile created in
  // Hindi holds "पुरुष" and one created in Tamil holds "ஆண்". Showing such a
  // value in another language means recognising it by its label in any
  // supported language and re-rendering it in the current one.
  static final List<String Function(AppLocalizations)> _labelKeys = [
    (l) => l.genderMale,
    (l) => l.genderFemale,
    (l) => l.genderOther,
    (l) => l.empStudent,
    (l) => l.empFarmer,
    (l) => l.empSalaried,
    (l) => l.empSelfEmployed,
    (l) => l.empUnemployed,
    (l) => l.empRetired,
    (l) => l.aspiringEntrepreneur,
    (l) => l.existingBusiness,
    (l) => l.msmeOwner,
    (l) => l.artisanShg,
    (l) => l.commGeneral,
    (l) => l.commObc,
    (l) => l.commEws,
    (l) => l.commSc,
    (l) => l.commSt,
    (l) => l.commMinority,
    (l) => l.commOthers,
    (l) => l.eduSchool,
    (l) => l.eduDiploma,
    (l) => l.eduUndergraduate,
    (l) => l.eduPostgraduate,
    (l) => l.eduPhd,
    (l) => l.valYes,
    (l) => l.valNo,
  ];

  /// Re-renders a stored option label (gender, community, ...) in the language
  /// of [current], so forms can pre-select it even if it was saved in another
  /// language. Unrecognised text is returned unchanged.
  static String inLanguageOf(String value, AppLocalizations current) =>
      _fromOtherLanguage(value, current) ?? value;

  static String? _fromOtherLanguage(String value, AppLocalizations current) {
    for (final code in const ['en', 'ta', 'hi']) {
      final other = lookupAppLocalizations(Locale(code));
      for (final label in _labelKeys) {
        if (label(other) == value) return label(current);
      }
    }
    return null;
  }

  // Brackets match the options offered in the profile form (step 4), so the
  // value a user picked is shown back with the same label.
  static String getLocalizedIncomeRange(double income, BuildContext context) {
    final l10n = context.l10n;
    if (income <= 0) return l10n.incomeNone;
    if (income <= 150000) return l10n.incomeUnder15L;
    if (income <= 300000) return l10n.income15to3L;
    if (income <= 600000) return l10n.income3to6L;
    if (income <= 1000000) return l10n.income6to10L;
    return l10n.incomeAbove10L;
  }

  static String getLocalizedProfileValue(String val, BuildContext context) {
    final lower = val.trim().toLowerCase();
    if (lower == 'male') return context.l10n.genderMale;
    if (lower == 'female') return context.l10n.genderFemale;
    if (lower == 'other' || lower == 'others') return context.l10n.genderOther;

    if (lower == 'student') return context.l10n.empStudent;
    if (lower == 'farmer') return context.l10n.empFarmer;
    if (lower == 'salaried') return context.l10n.empSalaried;
    if (lower == 'self-employed' || lower == 'self employed') {
      return context.l10n.empSelfEmployed;
    }
    if (lower == 'unemployed') return context.l10n.empUnemployed;
    if (lower == 'retired') return context.l10n.empRetired;
    if (lower == 'entrepreneur') return context.l10n.aspiringEntrepreneur;

    // The role picked on the "About you" step is stored by its English title.
    if (lower == 'entrepreneur' || lower == 'aspiring entrepreneur') {
      return context.l10n.aspiringEntrepreneur;
    }
    if (lower == 'business' || lower == 'existing business') {
      return context.l10n.existingBusiness;
    }
    if (lower == 'msme owner' || lower == 'msme') return context.l10n.msmeOwner;
    if (lower == 'artisan / shg member' || lower == 'artisan') {
      return context.l10n.artisanShg;
    }

    if (lower == 'school') return context.l10n.eduSchool;
    if (lower == 'diploma') return context.l10n.eduDiploma;
    if (lower == 'undergraduate') return context.l10n.eduUndergraduate;
    if (lower == 'postgraduate') return context.l10n.eduPostgraduate;
    if (lower == 'ph.d.' || lower == 'phd') return context.l10n.eduPhd;

    if (lower == 'minority') return context.l10n.commMinority;
    if (lower == 'general') return context.l10n.commGeneral;
    if (lower == 'obc') return context.l10n.commObc;
    if (lower == 'ews') return context.l10n.commEws;
    if (lower == 'sc') return context.l10n.commSc;
    if (lower == 'st') return context.l10n.commSt;

    if (lower == 'yes') return context.l10n.valYes;
    if (lower == 'no' || lower == 'none') return context.l10n.valNo;
    final languageCode = languageCodeOf(lower);
    if (languageCode != null) return languageEndonym(languageCode);

    return _fromOtherLanguage(val.trim(), context.l10n) ?? val;
  }
}
