import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Reusable accordion section: one quiet blue icon, the section title and a
/// chevron, over an ExpansionTile.
///
/// Extracted from `scheme_details_screen.dart` (frontend refactor C5, safe slice).
class SchemeExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  // ignore: deprecated_member_use
  final ExpansionTileController controller;
  final VoidCallback onToggle;
  final Widget child;

  const SchemeExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.controller,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      // The ExpansionTile header is a ListTile; without a Material between it
      // and this coloured Container it asserts "background may be invisible"
      // once the section is mounted during loading. A transparency Material
      // gives it a compositing surface without changing appearance.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: controller,
            initiallyExpanded: isExpanded,
            onExpansionChanged: (_) => onToggle(),
            expansionAnimationStyle: still
                ? AnimationStyle.noAnimation
                : const AnimationStyle(
                    curve: Curves.easeInOut,
                    duration: Duration(milliseconds: 300),
                  ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: AppSize.avatarSm,
              height: AppSize.avatarSm,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary, size: AppSize.icon),
            ),
            title: Text(
              title,
              style: context.text.cardTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.iconMuted,
              size: AppSize.iconLg,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  top: AppSpacing.xs,
                ),
                // The section's own opaque white Container above sits between
                // any ListTile in `child` (services/documents content) and the
                // nearest real Material ancestor, which trips Flutter's
                // ListTile._debugCheckBackgroundIsHidden assertion. A
                // transparency-type Material gives those tiles a proper
                // compositing surface without changing appearance.
                child: Material(type: MaterialType.transparency, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
