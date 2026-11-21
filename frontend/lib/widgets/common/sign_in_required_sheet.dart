import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/login_screen.dart';
import '../../services/analytics/app_analytics.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// What a guest tried to use, so the sign-in sheet can say what signing in
/// gets them instead of a generic "sign in".
enum SignInFeature { general, save, alerts, saarthi, forMe }

/// Guest mode gate for features that need an account (saving schemes,
/// notifications, Saarthi, profile sync).
///
/// Returns true when the user is signed in and the action may go ahead. For a
/// guest it shows [SignInRequiredSheet] for [feature] and returns false.
Future<bool> requireAccount(
  BuildContext context, {
  SignInFeature feature = SignInFeature.general,
}) async {
  final provider = Provider.of<AppProvider>(context, listen: false);
  if (!provider.isGuest) return true;
  await SignInRequiredSheet.show(context, feature: feature);
  return false;
}

/// Takes a guest to the login screen. Replaces the guest stack (after sign-in
/// the login screen moves on by itself) and clears nothing, so the answers
/// kept on this phone carry over (AppProvider._uploadGuestAnswers). The login
/// screen offers a way back to the guest session.
void openSignIn(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// "Sign in to …" bottom sheet shown to a guest.
///
/// Sign in opens the login screen without clearing anything on the phone, so
/// the guest's answers and saved state are still there after sign-in.
class SignInRequiredSheet extends StatelessWidget {
  const SignInRequiredSheet({super.key, this.feature = SignInFeature.general});

  final SignInFeature feature;

  static Future<void> show(
    BuildContext context, {
    SignInFeature feature = SignInFeature.general,
  }) async {
    final analytics = AppAnalytics.instance;
    final interactionId = analytics.interactionId();
    final featureKey = feature == SignInFeature.forMe ? 'for_me' : feature.name;
    analytics.track(
      AnalyticsEvent.signInPrompt,
      interactionId: interactionId,
      properties: {'feature': featureKey, 'action': 'shown'},
    );
    final selected = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SignInRequiredSheet(feature: feature),
    );
    analytics.track(
      AnalyticsEvent.signInPrompt,
      interactionId: interactionId,
      properties: {
        'feature': featureKey,
        'action': selected == true ? 'selected' : 'dismissed',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, body) = switch (feature) {
      SignInFeature.save => (
        l10n.guestSignInSaveTitle,
        l10n.guestSignInSaveBody,
      ),
      SignInFeature.alerts => (
        l10n.guestSignInAlertsTitle,
        l10n.guestSignInAlertsBody,
      ),
      SignInFeature.saarthi => (
        l10n.guestSignInSaarthiTitle,
        l10n.guestSignInSaarthiBody,
      ),
      SignInFeature.forMe => (
        l10n.guestSignInForMeTitle,
        l10n.guestSignInForMeBody,
      ),
      SignInFeature.general => (l10n.guestSignInTitle, l10n.guestSignInBody),
    };
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
              title,
              style: context.text.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: context.text.body.copyWith(color: AppColors.textMuted),
            ),
            if (feature != SignInFeature.general) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.guestSignInKeptNote,
                style: context.text.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop(true);
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
