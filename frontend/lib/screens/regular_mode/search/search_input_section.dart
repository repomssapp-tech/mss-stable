import 'package:flutter/material.dart';
import 'listening_pulse.dart';
import '../../../utils/spell_check.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_elevation.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Top header bar for the search screen matching the Discover header style.
class SearchHeaderBar extends StatelessWidget {
  const SearchHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.searchTitle,
          style: context.text.headline.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.hairline),
        Text(
          context.l10n.searchDiscoverSubtitle,
          style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Dynamic search input container with search icon, clear button, and speech dictation.
class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDictating;
  final VoidCallback onToggleDictation;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onSubmitTap;

  const SearchInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isDictating,
    required this.onToggleDictation,
    required this.onSubmitted,
    required this.onClear,
    required this.onSubmitTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasText = controller.text.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.controlHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillAll,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        // The platform's own spell checker, where there is one (Android /
        // iOS): underlines a misspelt word and offers corrections in the
        // app's language, where the device has that dictionary.
        spellCheckConfiguration: platformSpellCheck(),
        onSubmitted: onSubmitted,
        style: context.text.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: isDictating
              ? context.l10n.voiceStatusListening
              : context.l10n.homeSearchHint,
          hintStyle: context.text.body.copyWith(color: AppColors.textMuted),
          prefixIcon: IconButton(
            tooltip: context.l10n.search,
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: AppSize.iconLg,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                focusNode.unfocus();
                onSubmitTap();
              }
            },
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  tooltip: context.l10n.clearSearchTooltip,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.iconMuted,
                    size: AppSize.icon,
                  ),
                  onPressed: onClear,
                ),
              IconButton(
                tooltip: isDictating
                    ? context.l10n.stopVoiceSearchTooltip
                    : context.l10n.voiceSearchTooltip,
                icon: isDictating
                    ? const ListeningPulse(
                        child: Icon(
                          Icons.mic_rounded,
                          color: AppColors.danger,
                          size: AppSize.icon,
                        ),
                      )
                    : const Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.primary,
                        size: AppSize.icon,
                      ),
                onPressed: onToggleDictation,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

/// A tappable "Try: ..." line under the search bar on the idle Search tab.
class SearchTryBanner extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;

  const SearchTryBanner({
    super.key,
    required this.hintText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.iconMuted,
              size: AppSize.iconSm,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Wraps to a second line instead of shrinking to a tiny size.
            Expanded(
              child: Text(
                "${context.l10n.trySearchPrefix} $hintText",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
