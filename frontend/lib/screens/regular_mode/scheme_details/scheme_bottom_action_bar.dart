import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Fixed bottom action bar with "Save Scheme" bookmark button and "Apply Now" CTA.
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
    // Tamil button labels are ~2x longer than English; size the text for the
    // active language (with a readable floor) instead of letting a FittedBox
    // shrink it to nothing.
    final String code = Localizations.localeOf(context).languageCode;
    final bool isTamil = code == 'ta';
    final bool isIndic = code != 'en';
    final double labelSize = isTamil ? 11.5 : 14.0;
    // Devanagari and Tamil lines need more leading than Latin, or the second
    // line of a wrapped label is clipped by the button.
    final double labelHeight = isIndic ? 1.4 : 1.15;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      // Both buttons grow to the taller label, so a two-line label is never
      // clipped.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Save Scheme Button — Fix 2: FittedBox prevents overflow
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: OutlinedButton(
                  onPressed: onBookmarkToggle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.only(
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: const Color(0xFF2563EB),
                        size: 20,
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
                          style: AppGoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: labelSize,
                            height: labelHeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Apply Now Button — Fix 2: FittedBox prevents overflow
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: ElevatedButton(
                  onPressed: applyEnabled ? onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
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
                          style: AppGoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: labelSize,
                            height: labelHeight,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
