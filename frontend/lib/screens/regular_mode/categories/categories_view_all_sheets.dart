import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import 'categories_data.dart';
import 'categories_section_lists.dart';
import 'discover_counts.dart';
import 'state_map_painter.dart';
import '../../../utils/app_text.dart';

/// Shared frame for the three "View all" sheets: drag handle, title, close
/// button, an optional field under the title, and the list.
class _ViewAllSheet extends StatelessWidget {
  const _ViewAllSheet({
    required this.title,
    required this.heightFactor,
    required this.list,
    this.header,
  });

  final String title;
  final double heightFactor;
  final Widget? header;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * heightFactor,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              width: AppSpacing.xxxl,
              height: AppSpacing.xs,
              decoration: const BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
          Padding(
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
                    style: context.text.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.iconMuted,
                    size: AppSize.iconLg,
                  ),
                  tooltip: context.l10n.close,
                ),
              ],
            ),
          ),
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: header,
            ),
          Expanded(child: list),
        ],
      ),
    );
  }
}

/// One row in a "View all" sheet: a leading mark, the name, its scheme count
/// and a chevron.
class _ViewAllRow extends StatelessWidget {
  const _ViewAllRow({
    required this.leading,
    required this.title,
    required this.count,
    required this.isEmpty,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String count;
  final bool isEmpty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.cardTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconMuted,
              size: AppSize.icon,
            ),
          ],
        ),
      ),
    );
  }
}

/// The round blue icon mark used on category and ministry rows.
class _RowMark extends StatelessWidget {
  const _RowMark(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.avatarSm,
      height: AppSize.avatarSm,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primary, size: AppSize.icon),
    );
  }
}

void showAllCategoriesBottomSheet({
  required BuildContext context,
  required AppProvider provider,
  required Map<String, int> dynamicCategoryCounts,
  required ValueChanged<String> onCategorySelected,
}) {
  String modalSearchQuery = '';
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = allCategoriesList.where((cat) {
            return cat.title.toLowerCase().contains(
              modalSearchQuery.toLowerCase(),
            );
          }).toList();

          return _ViewAllSheet(
            title: context.l10n.allCategories,
            heightFactor: 0.85,
            header: TextField(
              onChanged: (val) => setModalState(() => modalSearchQuery = val),
              style: context.text.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.searchCategoriesHint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.iconMuted,
                ),
              ),
            ),
            list: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final category = filtered[index];
                final int? cnt = dynamicCategoryCounts[category.title];
                return _ViewAllRow(
                  leading: _RowMark(category.icon),
                  title: localizedCategoryLabel(context, category.title),
                  count: formatSchemeCount(context, cnt, provider),
                  isEmpty: cnt == 0,
                  onTap: () {
                    Navigator.pop(context); // Close sheet
                    onCategorySelected(category.title);
                  },
                );
              },
            ),
          );
        },
      );
    },
  );
}

void showAllMinistriesBottomSheet({
  required BuildContext context,
  required AppProvider provider,
  required Map<String, int> dynamicCategoryCounts,
  required ValueChanged<String> onMinistrySelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ViewAllSheet(
        title: context.l10n.allMinistries,
        heightFactor: 0.7,
        list: ListView.builder(
          itemCount: allMinistriesList.length,
          itemBuilder: (context, index) {
            final title = allMinistriesList[index];
            final int? cnt = dynamicCategoryCounts[title];
            return _ViewAllRow(
              leading: const _RowMark(Icons.account_balance_outlined),
              title: localizedProperName(title, provider),
              count: formatSchemeCount(context, cnt, provider),
              isEmpty: cnt == 0,
              onTap: () {
                Navigator.pop(context);
                onMinistrySelected(title);
              },
            );
          },
        ),
      );
    },
  );
}

void showAllStatesBottomSheet({
  required BuildContext context,
  required AppProvider provider,
  required Map<String, int> dynamicCategoryCounts,
  required ValueChanged<String> onStateSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ViewAllSheet(
        title: context.l10n.allStatesAndUts,
        heightFactor: 0.7,
        list: ListView.builder(
          itemCount: allStatesList.length,
          itemBuilder: (context, index) {
            final title = allStatesList[index];
            final int? cnt = dynamicCategoryCounts[title];
            return _ViewAllRow(
              leading: Image.asset(
                getStateMapAsset(title),
                width: AppSize.avatarSm,
                height: AppSize.avatarSm,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(
                    size: const Size.square(AppSize.avatarSm),
                    painter: StateMapPainter(title),
                  );
                },
              ),
              title: localizedProperName(title, provider),
              count: formatSchemeCount(context, cnt, provider),
              isEmpty: cnt == 0,
              onTap: () {
                Navigator.pop(context);
                onStateSelected(title);
              },
            );
          },
        ),
      );
    },
  );
}
