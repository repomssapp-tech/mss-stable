import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import 'categories_data.dart';
import 'discover_counts.dart';
import 'state_map_painter.dart';
import '../../../utils/app_text.dart';

void showComingSoonInfo(BuildContext context, String name, String type) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        context.l10n.updatingSoon,
        style: context.text.titleSmall.copyWith(color: AppColors.textPrimary),
      ),
      content: Text(
        context.l10n.comingSoonSchemesBody(name),
        style: context.text.body.copyWith(color: AppColors.textBody),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.gotIt),
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

const double _markSize = AppSize.iconLg + AppSpacing.sm;

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
    // The heading wraps between words; "View all" keeps its natural width,
    // so its label never breaks inside a word.
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.xs,
        top: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(onPressed: onViewAll, child: Text(context.l10n.viewAll)),
        ],
      ),
    );
  }
}

/// One Discover card: a leading mark, the name and its scheme count. Every
/// row of cards uses this, so the three rows line up.
class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.leading,
    required this.title,
    required this.titleLines,
    required this.count,
    required this.isEmpty,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final int titleLines;
  final String count;
  final bool isEmpty;
  final VoidCallback onTap;

  /// Every card's width in the horizontal rows.
  static const double width = 134;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: width),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const Spacer(),
                  Text(
                    title,
                    maxLines: titleLines,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    count,
                    style: context.text.bodySmall.copyWith(
                      color: isEmpty
                          ? AppColors.warningText
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The round blue mark used on category and ministry cards.
class _IconMark extends StatelessWidget {
  const _IconMark(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _markSize,
      height: _markSize,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primary, size: AppSize.iconSm),
    );
  }
}

class _DiscoverRow extends StatelessWidget {
  const _DiscoverRow({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(
            itemCount,
            (index) => itemBuilder(context, index),
          ),
        ),
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
    return _DiscoverRow(
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        final item = displayCategories[index];
        final String title = item['title'] as String;
        final int? cnt = dynamicCategoryCounts[title];
        return _DiscoverCard(
          leading: _IconMark(item['icon'] as IconData),
          title: localizedCategoryLabel(context, title),
          titleLines: 2,
          count: formatSchemeCount(context, cnt, provider),
          isEmpty: cnt == 0,
          onTap: () => onCategorySelected(title),
        );
      },
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
    return _DiscoverRow(
      itemCount: displayMinistries.length,
      itemBuilder: (context, index) {
        final item = displayMinistries[index];
        final String title = item['title'] as String;
        final int? cnt = dynamicCategoryCounts[title];
        return _DiscoverCard(
          leading: const _IconMark(Icons.account_balance_outlined),
          title: localizedProperName(title, provider),
          titleLines: 2,
          count: formatSchemeCount(context, cnt, provider),
          isEmpty: cnt == 0,
          onTap: () => onMinistrySelected(title),
        );
      },
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
    return _DiscoverRow(
      itemCount: displayStates.length,
      itemBuilder: (context, index) {
        final item = displayStates[index];
        final String title = item['title'] as String;
        final int? cnt = dynamicCategoryCounts[title];
        return _DiscoverCard(
          // The state's own outline: this row's signature, not decoration.
          leading: Image.asset(
            getStateMapAsset(title),
            width: _markSize,
            height: _markSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                size: const Size.square(_markSize),
                painter: StateMapPainter(title),
              );
            },
          ),
          title: localizedProperName(title, provider),
          titleLines: 2,
          count: formatSchemeCount(context, cnt, provider),
          isEmpty: cnt == 0,
          onTap: () => onStateSelected(title),
        );
      },
    );
  }
}
