import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Interface strings for [code], or English when no ARB file ships for it (a
/// language can show catalogue content before its interface is translated).
AppLocalizations l10nFor(String code) {
  final locale = Locale(code);
  return lookupAppLocalizations(
    AppLocalizations.delegate.isSupported(locale) ? locale : const Locale('en'),
  );
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
