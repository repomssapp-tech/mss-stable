import '../../services/catalog/centralized_translator.dart';
import '../../services/recommendation/indian_districts.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import '../regular_mode/basic_profile_screen.dart';
import 'profile_value_formatters.dart';
import 'profile_widgets.dart';
import '../../utils/app_text.dart';

/// Card displaying basic user identity information with Edit Profile action.
class ProfileUserInfoCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileUserInfoCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      child: Column(
        children: [
          // Icon, title and Edit button share one centre line; both labels
          // stay on a single line in every language (they shrink instead).
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: AppSize.icon,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.userInformation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Never wider than half the row, so the title keeps its room;
              // the short label fits in every language at 1.3x text.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.sizeOf(context).width / 2 - AppSpacing.xl,
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BasicProfileScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: AppSize.iconSm),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          context.l10n.profileEditAction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Information Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoCol(
                label: context.l10n.labelFullName,
                value: profile.name.isNotEmpty ? profile.name : '-',
                flex: 5,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelAge,
                value: profile.dob != null ? '${profile.age}' : '-',
                flex: 2,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoCol(
                label: context.l10n.labelGender,
                value: profile.gender.isNotEmpty
                    ? ProfileValueFormatters.getLocalizedProfileValue(
                        profile.gender,
                        context,
                      )
                    : '-',
                flex: 5,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelLocation,
                value: profile.district.isNotEmpty
                    ? '${IndianDistricts.displayName(_displayDistrict(profile.district), Localizations.localeOf(context).languageCode)}, ${CentralizedTranslator.instance.localizeTag(profile.state)}'
                    : '-',
                flex: 5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Districts are stored as typed or as lowercase ids; show them capitalised.
String _displayDistrict(String raw) {
  final d = raw.trim();
  if (d != d.toLowerCase()) return d;
  return d
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
