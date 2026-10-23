import 'package:flutter/material.dart';
import 'listening_pulse.dart';
import '../../../utils/spell_check.dart';
import '../../../l10n/l10n.dart';
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
          style: AppGoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.hairline),
        Text(
          context.l10n.searchDiscoverSubtitle,
          style: AppGoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
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
  final double Function(double) scaledFontSize;

  const SearchInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isDictating,
    required this.onToggleDictation,
    required this.onSubmitted,
    required this.onClear,
    required this.onSubmitTap,
    required this.scaledFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasText = controller.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        style: AppGoogleFonts.inter(
          fontSize: scaledFontSize(13),
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: isDictating
              ? context.l10n.voiceStatusListening
              : context.l10n.searchPlaceholder,
          hintStyle: AppGoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12.5,
          ),
          prefixIcon: IconButton(
            tooltip: context.l10n.search,
            icon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
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
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (hasText) const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: isDictating
                    ? context.l10n.stopVoiceSearchTooltip
                    : context.l10n.voiceSearchTooltip,
                icon: isDictating
                    ? const ListeningPulse(
                        child: Icon(
                          Icons.mic,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      )
                    : const Icon(
                        Icons.mic_none,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                onPressed: onToggleDictation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }
}

/// Horizontal list of quick suggested scheme search pills.
class SearchQuickPills extends StatelessWidget {
  final ValueChanged<String> onPillSelected;

  const SearchQuickPills({super.key, required this.onPillSelected});

  @override
  Widget build(BuildContext context) {
    final pills = [
      context.l10n.quickPillPmegp,
      context.l10n.quickPillStartup,
      context.l10n.quickPillLoans,
      context.l10n.quickPillWomen,
      context.l10n.quickPillAscend,
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: pills.length,
        itemBuilder: (context, index) {
          final text = pills[index];
          return GestureDetector(
            onTap: () {
              final query = text
                  .replaceAll("Search ", "")
                  .replaceAll("தேடுக", "")
                  .trim();
              onPillSelected(query);
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: AppSpacing.tight),
                  Text(
                    text,
                    style: AppGoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Banner shown when idle suggesting a search hint.
class SearchTryBanner extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;
  final double Function(double) scaledFontSize;

  const SearchTryBanner({
    super.key,
    required this.hintText,
    required this.onTap,
    required this.scaledFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF64748B), size: 14),
          const SizedBox(width: AppSpacing.xs),
          // Wraps to a second line instead of shrinking to a tiny size.
          Expanded(
            child: Text(
              "${context.l10n.trySearchPrefix} $hintText",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppGoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: scaledFontSize(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
