import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../screens/login_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Told to a guest on the Profile and Settings screens: their details live only on this phone,
/// so a different phone or cleared app data means the guest profile is gone. Sign in to keep it.
class GuestLocalNotice extends StatelessWidget {
  const GuestLocalNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warningOnSoft),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.guestLocalTitle,
                  style: context.text.cardTitle.copyWith(
                    color: AppColors.warningOnSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.guestLocalBody,
            style: context.text.body.copyWith(color: AppColors.warningOnSoft),
          ),
          const SizedBox(height: AppSpacing.md),
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
