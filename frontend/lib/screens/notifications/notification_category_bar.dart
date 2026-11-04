import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import 'notification_helpers.dart';
import '../../utils/app_text.dart';

class NotificationCategoryBar extends StatelessWidget {
  final String activeFilter;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<String> onSelectCategory;

  const NotificationCategoryBar({
    super.key,
    required this.activeFilter,
    required this.categories,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    const activeBgColor = AppColors.primarySoft;
    const activeTextColor = AppColors.primary;
    const inactiveBgColor = Colors.white;
    const inactiveTextColor = AppColors.textMuted;

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final catKey = cat['key'] as String;
          final isSelected = activeFilter == catKey;

          return InkWell(
            onTap: () => onSelectCategory(catKey),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? activeBgColor : inactiveBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primaryTint : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                    size: 15,
                  ),
                  const SizedBox(width: AppSpacing.tight),
                  Text(
                    NotificationHelpers.categoryLabel(context, catKey),
                    style: context.text.bodySmall.copyWith(
                      color: isSelected
                          ? activeTextColor
                          : AppColors.textPrimary,

                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
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
