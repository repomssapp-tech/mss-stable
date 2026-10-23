import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import 'categories_data.dart';
import 'discover_counts.dart';
import 'state_map_painter.dart';
import '../../../utils/app_text.dart';

void showComingSoonInfo(BuildContext context, String name, String type) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.update_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.updatingSoon,
              style: AppGoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        context.l10n.comingSoonSchemesBody(name),
        style: AppGoogleFonts.inter(
          fontSize: 13.5,
          color: const Color(0xFF475569),
          height: 1.4,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
          ),
          child: Text(
            context.l10n.gotIt,
            style: AppGoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

String formatSchemeCount(BuildContext context, int? cnt, AppProvider provider) {
  if (cnt == null) return '...';
  if (cnt == 0) {
    return context.l10n.updatingSoonCount;
  }
  return context.l10n.schemeCountFormat(cnt);
}

/// Height of a Discover horizontal card row (categories, ministries, states).
/// The icon and padding are fixed; the text allowance grows with the user's
/// font size so larger text reflows instead of overflowing (issue #144).
double discoverRowHeight(BuildContext context, AppProvider provider) {
  const chrome = 56.0;
  final textAllowance = provider.selectedLanguage == 'ta' ? 82.0 : 70.0;
  return chrome + MediaQuery.textScalerOf(context).scale(textAllowance);
}

class CategoriesSectionHeader extends StatelessWidget {
  const CategoriesSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final isTa = context.l10n.localeName == 'ta';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FlexText(
            child: Text(
              title,
              style: AppGoogleFonts.poppins(
                fontSize: isTa ? 15.0 : 16.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.viewAll,
                      style: AppGoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.hairline),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryHorizontalList extends StatelessWidget {
  const CategoryHorizontalList({
    super.key,
    required this.provider,
    required this.dynamicCategoryCounts,
    required this.onCategorySelected,
  });

  final AppProvider provider;
  final Map<String, int> dynamicCategoryCounts;
  final void Function(String categoryName) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: discoverRowHeight(context, provider),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final item = displayCategories[index];
          final String title = item['title'] as String;
          final int? cnt = dynamicCategoryCounts[title];
          final String countStr = formatSchemeCount(context, cnt, provider);
          final String localizedTitle = localizedCategoryLabel(context, title);
          final IconData icon = item['icon'] as IconData;

          return Container(
            width: 134,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => onCategorySelected(title),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.tight),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      localizedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppGoogleFonts.poppins(
                        fontSize: provider.selectedLanguage == 'ta'
                            ? 10.0
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        height: provider.selectedLanguage == 'ta' ? 1.3 : 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      countStr,
                      style: AppGoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: cnt == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MinistryHorizontalList extends StatelessWidget {
  const MinistryHorizontalList({
    super.key,
    required this.provider,
    required this.dynamicCategoryCounts,
    required this.onMinistrySelected,
  });

  final AppProvider provider;
  final Map<String, int> dynamicCategoryCounts;
  final void Function(String ministryName) onMinistrySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: discoverRowHeight(context, provider),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: displayMinistries.length,
        itemBuilder: (context, index) {
          final item = displayMinistries[index];
          final String title = item['title'] as String;
          final int? cnt = dynamicCategoryCounts[title];
          final String countStr = formatSchemeCount(context, cnt, provider);
          final String localizedTitle = localizedProperName(title, provider);

          return Container(
            width: 134,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => onMinistrySelected(title),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: Color(0xFF2563EB),
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      localizedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppGoogleFonts.poppins(
                        fontSize: provider.selectedLanguage == 'ta'
                            ? 10.0
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        height: provider.selectedLanguage == 'ta' ? 1.3 : 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      countStr,
                      style: AppGoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: cnt == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StateHorizontalList extends StatelessWidget {
  const StateHorizontalList({
    super.key,
    required this.provider,
    required this.dynamicCategoryCounts,
    required this.onStateSelected,
  });

  final AppProvider provider;
  final Map<String, int> dynamicCategoryCounts;
  final void Function(String stateName) onStateSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: discoverRowHeight(context, provider),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: displayStates.length,
        itemBuilder: (context, index) {
          final item = displayStates[index];
          final String title = item['title'] as String;
          final int? cnt = dynamicCategoryCounts[title];
          final String countStr = formatSchemeCount(context, cnt, provider);
          final String localizedTitle = localizedProperName(title, provider);

          return Container(
            width: 134,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: InkWell(
              onTap: () => onStateSelected(title),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      getStateMapAsset(title),
                      width: 36,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(
                          size: const Size(36, 32),
                          painter: StateMapPainter(title),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      localizedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppGoogleFonts.poppins(
                        fontSize: provider.selectedLanguage == 'ta'
                            ? 10.0
                            : 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      countStr,
                      style: AppGoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: cnt == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
