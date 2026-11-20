import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/login_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Guest mode gate for features that need an account (saving schemes,
/// notifications, profile sync).
///
/// Returns true when the user is signed in and the action may go ahead. For a
/// guest it shows [SignInRequiredSheet] and returns false.
Future<bool> requireAccount(BuildContext context) async {
  final provider = Provider.of<AppProvider>(context, listen: false);
  if (!provider.isGuest) return true;
  await SignInRequiredSheet.show(context);
  return false;
}

/// Takes a guest to the login screen. Replaces the guest stack (after sign-in
/// the login screen moves on by itself) and clears nothing, so the answers
/// kept on this phone carry over (AppProvider._uploadGuestAnswers).
void openSignIn(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// "Sign in to use this" bottom sheet shown to a guest.
///
/// Sign in opens the login screen without clearing anything on the phone, so
/// the guest's answers and saved state are still there after sign-in.
class SignInRequiredSheet extends StatelessWidget {
  const SignInRequiredSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const SignInRequiredSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        // The drag handle above already spaces the top.
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.guestSignInTitle,
              style: context.text.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.guestSignInBody,
              style: context.text.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                openSignIn(navigator.context);
              },
              child: Text(l10n.guestSignInAction),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.guestSignInNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
