import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/language_pack_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_text.dart';
import '../../../utils/language_names.dart';

/// Language switcher for the home header, listing what the catalogue offers.
///
/// Switching goes through [AppProvider.changeLanguage], which loads the
/// language pack and re-resolves scheme text. Schemes that have no text in the
/// chosen language for a field keep showing the English text for that field,
/// so choosing a language here never leaves a blank card.
class HomeLanguageButton extends StatefulWidget {
  final AppProvider provider;

  const HomeLanguageButton({super.key, required this.provider});

  @override
  State<HomeLanguageButton> createState() => _HomeLanguageButtonState();
}

class _HomeLanguageButtonState extends State<HomeLanguageButton> {
  // Same gate as the language picker: a language is offered only when the
  // release manifest has it on and a valid pack exists (the D10 kill switch).
  List<String> _offered = LanguagePackManager.baseLanguages;

  @override
  void initState() {
    super.initState();
    _loadOffered();
  }

  Future<void> _loadOffered() async {
    final offered = await LanguagePackManager.instance.offeredLanguages();
    if (mounted) setState(() => _offered = offered);
  }

  // Language names are shown in their own script regardless of the active
  // locale, so people can always find their language. A user already on a
  // language keeps seeing it ticked even if the kill switch is flipped, so the
  // menu never hides the language they are using.
  List<({String code, String label})> _visibleOptions(String current) => [
    for (final code in inDisplayOrder({..._offered, current}))
      (code: code, label: languageEndonym(code)),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final current = provider.selectedLanguage;
    final label = context.l10n.languageSetting;

    return Semantics(
      label: label,
      button: true,
      child: PopupMenuButton<String>(
        tooltip: label,
        initialValue: current,
        position: PopupMenuPosition.under,
        color: AppColors.surface,
        onSelected: (code) {
          if (code != current) provider.changeLanguage(code);
        },
        itemBuilder: (_) => [
          for (final option in _visibleOptions(current))
            PopupMenuItem<String>(
              value: option.code,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppSize.iconLg,
                    child: option.code == current
                        ? const Icon(
                            Icons.check,
                            size: AppSize.icon,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  Text(
                    option.label,
                    style: context.text.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: option.code == current
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const ExcludeSemantics(
            child: Icon(
              Icons.translate_rounded,
              size: AppSize.iconLg,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
