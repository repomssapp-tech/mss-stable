import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_elevation.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Fixed bottom action bar: a secondary "Save" button and the one primary
/// action, "Apply now" (or "Official information" without a direct link).
///
/// Extracted from `scheme_details_screen.dart` (frontend refactor C5, safe slice).
class SchemeBottomActionBar extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onApply;
  final bool applyEnabled;

  /// True for a confirmed direct application link ("Apply Now"); false for an
  /// official information page ("Official information").
  final bool isDirectApply;

  const SchemeBottomActionBar({
    super.key,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onApply,
    required this.applyEnabled,
    this.isDirectApply = true,
  });

  @override
  Widget build(BuildContext context) {
    // Labels keep the button text size in every language; a long Tamil label
    // wraps to two lines and both buttons grow to match.
    final labelStyle = context.text.button;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.topBar,
        border: Border(
          top: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
      ),
      // Side by side when both labels fit on a line or two; on a narrow
      // phone in Tamil or Hindi the primary action goes on top, full width,
      // so no label ever breaks inside a word.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final code = Localizations.localeOf(context).languageCode;
          final minHalf = code == 'ta' || code == 'hi' ? 200.0 : 130.0;
          final save = OutlinedButton(
            onPressed: onBookmarkToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: AppSize.icon,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    isBookmarked
                        ? context.l10n.savedSchemeButton
                        : context.l10n.saveSchemeButton,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          );
          final apply = ElevatedButton(
            onPressed: applyEnabled ? onApply : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isDirectApply
                        ? context.l10n.applyNowButton
                        : context.l10n.officialInfoButton,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.open_in_new_rounded, size: AppSize.iconSm),
              ],
            ),
          );
          if ((constraints.maxWidth - AppSpacing.md) / 2 < minHalf) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                apply,
                const SizedBox(height: AppSpacing.sm),
                save,
              ],
            );
          }
          // Both buttons grow to the taller label, so a two-line label is
          // never clipped.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: save),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: apply),
              ],
            ),
          );
        },
      ),
    );
  }
}
