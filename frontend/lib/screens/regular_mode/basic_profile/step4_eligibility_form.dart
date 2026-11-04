import 'package:flutter/material.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_colors.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class Step4EligibilityForm extends StatelessWidget {
  final String selectedEducation;
  final ValueChanged<String> onEducationChanged;
  final String selectedCommunity;
  final ValueChanged<String> onCommunityChanged;
  final double? selectedIncome;
  final ValueChanged<double?> onIncomeChanged;
  final bool isFirstGenGraduate;
  final ValueChanged<bool> onFirstGenGraduateChanged;
  final bool isDifferentlyAbled;
  final ValueChanged<bool> onDifferentlyAbledChanged;
  final bool isVeteran;
  final ValueChanged<bool> onVeteranChanged;
  final bool hasSubmitted;

  final List<Map<String, String>>? educationOptions;
  final List<Map<String, String>>? communityOptions;
  final List<Map<String, dynamic>>? incomeOptions;

  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate900 = AppColors.textPrimary;
  static const Color kSlate800 = AppColors.textPrimary;
  static const Color kSlate500 = AppColors.textMuted;
  static const Color kBorderGrey = AppColors.border;
  static const Color kInfoBlueBg = AppColors.primarySoft;

  static const List<Map<String, String>> defaultEducationOptions = [
    {'id': 'School', 'key': 'eduSchool'},
    {'id': 'Diploma', 'key': 'eduDiploma'},
    {'id': 'Undergraduate', 'key': 'eduUndergraduate'},
    {'id': 'Postgraduate', 'key': 'eduPostgraduate'},
    {'id': 'Ph.D.', 'key': 'eduPhd'},
  ];

  static const List<Map<String, String>> defaultCommunityOptions = [
    {'id': 'General', 'key': 'commGeneralOc'},
    {'id': 'OBC', 'key': 'commObcBcMbc'},
    {'id': 'SC', 'key': 'commScCategory'},
    {'id': 'ST', 'key': 'commStCategory'},
    {'id': 'EWS', 'key': 'commEwsCategory'},
    {'id': 'Minority', 'key': 'commMinority'},
  ];

  static const List<Map<String, dynamic>> defaultIncomeOptions = [
    {'value': 0.0, 'key': 'incomeNone'},
    {'value': 100000.0, 'key': 'incomeUnder15L'},
    {'value': 250000.0, 'key': 'income15to3L'},
    {'value': 450000.0, 'key': 'income3to6L'},
    {'value': 800000.0, 'key': 'income6to10L'},
    {'value': 1500000.0, 'key': 'incomeAbove10L'},
  ];

  const Step4EligibilityForm({
    super.key,
    required this.selectedEducation,
    required this.onEducationChanged,
    required this.selectedCommunity,
    required this.onCommunityChanged,
    required this.selectedIncome,
    required this.onIncomeChanged,
    required this.isFirstGenGraduate,
    required this.onFirstGenGraduateChanged,
    required this.isDifferentlyAbled,
    required this.onDifferentlyAbledChanged,
    required this.isVeteran,
    required this.onVeteranChanged,
    required this.hasSubmitted,
    this.educationOptions,
    this.communityOptions,
    this.incomeOptions,
  });

  // Maps a Step 4 option `key` to its localized label. Kept as an explicit
  // switch because gen-l10n getters can't be looked up dynamically by name.
  static String optionLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'eduSchool':
        return l10n.eduSchool;
      case 'eduDiploma':
        return l10n.eduDiploma;
      case 'eduUndergraduate':
        return l10n.eduUndergraduate;
      case 'eduPostgraduate':
        return l10n.eduPostgraduate;
      case 'eduPhd':
        return l10n.eduPhd;
      case 'commGeneralOc':
        return l10n.commGeneralOc;
      case 'commObcBcMbc':
        return l10n.commObcBcMbc;
      case 'commScCategory':
        return l10n.commScCategory;
      case 'commStCategory':
        return l10n.commStCategory;
      case 'commEwsCategory':
        return l10n.commEwsCategory;
      case 'commMinority':
        return l10n.commMinority;
      case 'incomeNone':
        return l10n.incomeNone;
      case 'incomeUnder15L':
        return l10n.incomeUnder15L;
      case 'income15to3L':
        return l10n.income15to3L;
      case 'income3to6L':
        return l10n.income3to6L;
      case 'income6to10L':
        return l10n.income6to10L;
      case 'incomeAbove10L':
        return l10n.incomeAbove10L;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedEduOptions = educationOptions ?? defaultEducationOptions;
    final resolvedCommOptions = communityOptions ?? defaultCommunityOptions;
    final resolvedIncOptions = incomeOptions ?? defaultIncomeOptions;

    Widget optionGrid({
      required List<Map<String, dynamic>> options,
      required bool Function(Map<String, dynamic> opt) isSelected,
      required void Function(Map<String, dynamic> opt) onSelect,
    }) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 52,
        ),
        itemBuilder: (context, index) {
          final opt = options[index];
          final text = optionLabel(l10n, opt['key'] as String);
          return _buildSelectCard(
            context,
            label: text,
            isSelected: isSelected(opt),
            onTap: () => onSelect(opt),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.checkEligibility,
          textAlign: TextAlign.center,
          style: context.text.titleSmall.copyWith(color: kSlate900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.eligibilitySubtitle,
          textAlign: TextAlign.center,
          style: context.text.body.copyWith(color: kSlate500),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Education level (required)
        _buildLabel(context, '${l10n.qualification} *'),
        const SizedBox(height: AppSpacing.sm),
        optionGrid(
          options: resolvedEduOptions,
          isSelected: (opt) =>
              selectedEducation.isNotEmpty &&
              selectedEducation.toLowerCase() ==
                  (opt['id'] as String).toLowerCase(),
          onSelect: (opt) {
            final id = opt['id'] as String;
            onEducationChanged(
              selectedEducation.toLowerCase() == id.toLowerCase() ? '' : id,
            );
          },
        ),
        if (hasSubmitted && selectedEducation.isEmpty)
          _buildFieldError(context, l10n.profileErrSelectEducation),
        const SizedBox(height: AppSpacing.lg),

        // 2. Community category (required)
        _buildLabel(context, '${l10n.community} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildPrivacyNote(context),
        const SizedBox(height: AppSpacing.sm),
        optionGrid(
          options: resolvedCommOptions,
          isSelected: (opt) =>
              selectedCommunity.isNotEmpty &&
              selectedCommunity.toLowerCase() ==
                  (opt['id'] as String).toLowerCase(),
          onSelect: (opt) {
            final id = opt['id'] as String;
            onCommunityChanged(
              selectedCommunity.toLowerCase() == id.toLowerCase() ? '' : id,
            );
          },
        ),
        if (hasSubmitted && selectedCommunity.isEmpty)
          _buildFieldError(context, l10n.profileErrSelectCommunity),
        const SizedBox(height: AppSpacing.lg),

        // 3. Annual household income (required)
        _buildLabel(context, '${l10n.income} *'),
        const SizedBox(height: AppSpacing.sm),
        optionGrid(
          options: resolvedIncOptions,
          isSelected: (opt) =>
              selectedIncome != null &&
              (selectedIncome! - (opt['value'] as double)).abs() < 1000,
          onSelect: (opt) {
            final val = opt['value'] as double;
            onIncomeChanged(
              (selectedIncome != null && (selectedIncome! - val).abs() < 1000)
                  ? null
                  : val,
            );
          },
        ),
        if (hasSubmitted && selectedIncome == null)
          _buildFieldError(context, l10n.profileErrSelectIncome),
        const SizedBox(height: AppSpacing.lg),

        // 4. Special categories (optional)
        _buildLabel(context, l10n.specialCategories),
        const SizedBox(height: AppSpacing.sm),
        _buildToggleCard(
          context,
          title: l10n.firstGenGraduate,
          value: isFirstGenGraduate,
          onChanged: onFirstGenGraduateChanged,
        ),
        const SizedBox(height: AppSpacing.tight),
        _buildToggleCard(
          context,
          title: l10n.disability,
          value: isDifferentlyAbled,
          onChanged: onDifferentlyAbledChanged,
        ),
        const SizedBox(height: AppSpacing.tight),
        _buildToggleCard(
          context,
          title: l10n.veteran,
          value: isVeteran,
          onChanged: onVeteranChanged,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final hasAsterisk = text.contains('*');
    final baseText = text.replaceAll('*', '').trim();
    return Text.rich(
      TextSpan(
        text: baseText,
        style: context.text.button.copyWith(color: kSlate800),
        children: hasAsterisk
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: kInfoBlueBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, size: 14, color: kPrimaryBlue),
          const SizedBox(width: AppSpacing.tight),
          Expanded(
            child: Text(
              context.l10n.profilePrivacyNoteDpdpa,
              style: context.text.bodySmall.copyWith(color: kSlate800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.text.bodySmall.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectCard(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? kPrimaryBlue : kSlate800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? kPrimaryBlue : Colors.white,
                border: Border.all(
                  color: isSelected ? kPrimaryBlue : kBorderGrey,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: value ? AppColors.background : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? kPrimaryBlue : kBorderGrey,
          width: 1.0,
        ),
      ),
      // One node for the title and its switch, so a screen reader announces
      // which setting the switch controls.
      child: MergeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: context.text.bodySmall.copyWith(color: kSlate800),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: kPrimaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
