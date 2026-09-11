import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/app_spacing.dart';

/// Reusable accordion section widget with colored leading icon and ExpansionTile.
///
/// Extracted from `scheme_details_screen.dart` (frontend refactor C5, safe slice).
class SchemeExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isExpanded;
  // ignore: deprecated_member_use
  final ExpansionTileController controller;
  final VoidCallback onToggle;
  final Widget child;

  const SchemeExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isExpanded,
    required this.controller,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
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
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.hairline,
            ),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 16),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF2563EB),
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
