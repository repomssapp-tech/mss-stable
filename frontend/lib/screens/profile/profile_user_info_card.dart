import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import '../regular_mode/basic_profile_screen.dart';
import 'profile_value_formatters.dart';
import 'profile_widgets.dart';

/// Card displaying basic user identity information with Edit Profile action.
class ProfileUserInfoCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileUserInfoCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    final isTa = provider.selectedLanguage == 'ta';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Header with Edit Profile Action
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.userInformation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BasicProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2563EB),
                  size: 13,
                ),
                label: Text(
                  context.l10n.editProfile,
                  style: GoogleFonts.inter(
                    fontSize: isTa ? 9.5 : 10.5,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.tight,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color(0xFFBFDBFE),
                      width: 0.8,
                    ),
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
                isTamil: isTa,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelAge,
                value: profile.dob != null ? '${profile.age}' : '-',
                flex: 2,
                isTamil: isTa,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
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
                isTamil: isTa,
              ),
              const ProfileDividerCol(),
              ProfileInfoCol(
                label: context.l10n.labelLocation,
                value: profile.district.isNotEmpty
                    ? '${profile.district}, ${profile.state}'
                    : '-',
                flex: 5,
                isTamil: isTa,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
