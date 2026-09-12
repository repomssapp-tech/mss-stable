import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/constants.dart';

class HomeHeaderSection extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback? onSearchBarTap;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onVoiceQuery;
  final VoidCallback onNotificationTap;

  const HomeHeaderSection({
    super.key,
    required this.provider,
    this.onSearchBarTap,
    this.onFilterPressed,
    this.onVoiceQuery,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGreetingAndNotifications(context),
        const SizedBox(height: AppSpacing.md),
        _buildSearchAndFilter(context),
        const SizedBox(height: AppSpacing.sm),
        _buildQuickPills(context),
      ],
    );
  }

  Widget _buildGreetingAndNotifications(BuildContext context) {
    final displayName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ').first
        : context.l10n.commonUserFallback;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppConstants.getTimeGreeting(context.l10n),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text("👋", style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
            const SizedBox(height: AppSpacing.hairline),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: provider.isGuest ? 18.0 : 24.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!provider.isGuest) ...[
                  const SizedBox(width: AppSpacing.tight),
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onNotificationTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                    if (provider.notifications.any((n) => n['read'] == false))
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSearchBarTap?.call(),
            child: const Icon(Icons.search, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSearchBarTap?.call(),
              child: Text(
                context.l10n.searchPlaceholder,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              if (onFilterPressed != null) {
                onFilterPressed!();
              } else {
                provider.updateTabIndex(1);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.tight,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 14,
                    color: Color(0xFF1E293B),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.l10n.filter,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPills(BuildContext context) {
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
              if (onVoiceQuery != null) {
                onVoiceQuery!(query);
              } else {
                provider.updateSearchQuery(query);
                provider.updateTabIndex(1);
              }
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
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
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
