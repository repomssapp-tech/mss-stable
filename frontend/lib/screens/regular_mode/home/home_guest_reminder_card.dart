import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../login_screen.dart';

/// Shown to guests at the top of Home: sign in to complete the profile. It is
/// not shown once the user is signed in.
class HomeGuestReminderCard extends StatelessWidget {
  const HomeGuestReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.warningOnSoft),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.guestReminderText,
              style: context.text.body.copyWith(
                color: AppColors.warningOnSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Text(l10n.guestSignInAction),
          ),
        ],
      ),
    );
  }
}
