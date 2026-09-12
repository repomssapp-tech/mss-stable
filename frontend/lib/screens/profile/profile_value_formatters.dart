import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

class ProfileValueFormatters {
  const ProfileValueFormatters._();

  static String getLocalizedIncomeRange(double income, BuildContext context) {
    if (income <= 0) {
      return context.l10n.incomeNoIncome;
    }
    if (income <= 150000) return context.l10n.incUnder1_5;
    if (income <= 300000) return context.l10n.inc1_5To3;
    if (income <= 500000) return context.l10n.inc3To5;
    if (income <= 800000) return context.l10n.inc5To8;
    return context.l10n.incAbove8;
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

    if (lower == 'general') return context.l10n.commGeneral;
    if (lower == 'obc') return context.l10n.commObc;
    if (lower == 'ews') return context.l10n.commEws;
    if (lower == 'sc') return context.l10n.commSc;
    if (lower == 'st') return context.l10n.commSt;

    if (lower == 'yes') return context.l10n.valYes;
    if (lower == 'no' || lower == 'none') return context.l10n.valNo;
    if (lower == 'tamil' || lower == 'ta') return 'தமிழ்';
    if (lower == 'english' || lower == 'en') return 'English';

    return val;
  }
}
