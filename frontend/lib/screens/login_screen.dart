import '../services/account/onboarding_api_service.dart' show LegalConsentStore;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../l10n/l10n.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/legal/legal_consent_section.dart';
import '../widgets/legal/legal_document_modal.dart';
import 'navigation_mode_screen.dart';
import 'regular_mode/legal_screens.dart';
import '../utils/app_spacing.dart';
import '../utils/app_colors.dart';
import '../utils/app_radius.dart';
import '../utils/app_text.dart';
import '../utils/app_elevation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _navigationScheduled = false;
  bool _hasViewedTerms = false;
  bool _hasViewedPrivacy = false;

  Future<void> _openTermsModal() async {
    bool? accepted;
    var usedFallback = false;
    try {
      accepted = await LegalDocumentModal.showTermsOfUse(context);
    } catch (_) {
      usedFallback = true;
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
        );
      }
    }
    if (mounted) {
      setState(() {
        // A document counts as read only when it was scrolled to the end and
        // accepted (the modal enforces that); closing it early does not.
        if (accepted == true || usedFallback) _hasViewedTerms = true;
      });
    }
  }

  Future<void> _openPrivacyModal() async {
    bool? accepted;
    var usedFallback = false;
    try {
      accepted = await LegalDocumentModal.showPrivacyPolicy(context);
    } catch (_) {
      usedFallback = true;
      if (mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
      }
    }
    if (mounted) {
      setState(() {
        if (accepted == true || usedFallback) _hasViewedPrivacy = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AppProvider, bool>(
      (provider) => provider.isLoggedIn,
    );
    if (isLoggedIn && !_navigationScheduled) {
      _navigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavigationModeScreen()),
        );
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/splash_screen.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.scaffoldGradient,
                ),
              ),
            ),
          ),

          // 2. Content (Fit to page, scrollable only when keyboard is visible to prevent overflow)
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            children: [
                              const Spacer(flex: 1),

                              // Brand Logo
                              Image.asset(
                                'assets/images/Logo/Logo.webp',
                                height: 125,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.verified_user_rounded,
                                      size: 80,
                                      color: AppColors.primary,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Title + subtitle sit directly on the
                              // background photo, so they get a translucent
                              // surface backing for legibility.
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(
                                    alpha: .85,
                                  ),
                                  borderRadius: AppRadius.mdAll,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    children: [
                                      // Title
                                      Text(
                                        context.l10n.welcome,
                                        textAlign: TextAlign.center,
                                        style: context.text.titleMedium
                                            .copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),

                                      // Subtitle
                                      Text(
                                        context.l10n.loginSubtitle,
                                        textAlign: TextAlign.center,
                                        style: context.text.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(flex: 1),

                              // Main Card
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppRadius.lgAll,
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: AppShadows.card,
                                ),
                                child: _buildLoginForm(),
                              ),

                              const Spacer(flex: 2),

                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      // The Sign in button is only enabled after both documents were opened,
      // read to the end and accepted; remember that for onboarding.
      await LegalConsentStore.markLoginAgreement();
      final launched = await provider.loginWithGoogle();
      if (!launched && mounted) {
        throw StateError('Unable to open Google authentication.');
      }
    } catch (e, stack) {
      debugPrint('[LoginScreen] Sign-in error: $e\n$stack');
      if (mounted) {
        AppToast.showError(context, context.l10n.loginGoogleSignInFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoginForm() {
    final bool canConsent = _hasViewedTerms && _hasViewedPrivacy;
    // Does NOT include !_isLoading: the button must keep its "enabled" look
    // (not greyed out) while a sign-in is already in flight; onPressed below
    // separately swallows taps during loading.
    final bool isLoginEnabled = canConsent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.continueSecurely,
          textAlign: TextAlign.center,
          style: context.text.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.googleAccountContinue,
          textAlign: TextAlign.center,
          style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),

        // Legal & Privacy Consent Section
        LegalConsentSection(
          onOpenTerms: _openTermsModal,
          onOpenPrivacy: _openPrivacyModal,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Gate checklist: ticks each document once it was read and accepted
        // and stays visible, so the user sees both are done.
        _SignInChecklist(
          hasViewedTerms: _hasViewedTerms,
          hasViewedPrivacy: _hasViewedPrivacy,
          onOpenTerms: _openTermsModal,
          onOpenPrivacy: _openPrivacyModal,
        ),

        const SizedBox(height: AppSpacing.md),

        // Google Sign-In Button (strictly gated behind mandatory consent).
        // While it is disabled, a tap on it says why instead of doing
        // nothing, and screen readers hear the same reason as a hint.
        GestureDetector( // tap-ok: only explains taps on the disabled button
          onTap: isLoginEnabled || _isLoading
              ? null
              : () => AppToast.showWarning(
                  context,
                  context.l10n.loginReviewTermsNotice,
                ),
          child: Semantics(
            hint: isLoginEnabled ? null : context.l10n.loginReviewTermsNotice,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom( // style-ok: CTA height + explicit loading foreground colour
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: _isLoading ? AppColors.primary : null,
                ),
                // Swallow taps while loading (so a stray tap can't double-fire
                // sign-in) without visually disabling the button.
                onPressed: _isLoading
                    ? () {}
                    : (isLoginEnabled ? _signIn : null),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.loginOpeningGoogle,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleIcon(size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.continueWithGoogle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (!isLoginEnabled) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.loginReviewTermsNotice,
            textAlign: TextAlign.center,
            style: context.text.bodySmall.copyWith(
              color: AppColors.warningText,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.secureBrowserAuth,
          textAlign: TextAlign.center,
          style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SignInChecklist extends StatelessWidget {
  const _SignInChecklist({
    required this.hasViewedTerms,
    required this.hasViewedPrivacy,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool hasViewedTerms;
  final bool hasViewedPrivacy;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CheckRow(
          done: hasViewedTerms,
          label: context.l10n.loginChecklistTerms,
          linkText: context.l10n.legalTermsOfUseLink,
          onTap: onOpenTerms,
        ),
        _CheckRow(
          done: hasViewedPrivacy,
          label: context.l10n.loginChecklistPrivacy,
          linkText: context.l10n.privacyPolicy,
          onTap: onOpenPrivacy,
        ),
      ],
    );
  }
}

/// A "Read the Terms of Use" style row. The document name is the link; the
/// whole row is the tap target and opens the document.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.done,
    required this.label,
    required this.linkText,
    required this.onTap,
  });

  final bool done;
  final String label;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = context.text.bodySmall.copyWith(
      color: done ? AppColors.textBody : AppColors.textMuted,
    );
    final link = base.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );
    // The document name is the link. Where a language inflects the name inside
    // the sentence, the whole row is the link instead.
    final at = label.indexOf(linkText);
    final spans = at < 0
        ? [TextSpan(text: label, style: link)]
        : [
            TextSpan(text: label.substring(0, at)),
            TextSpan(text: linkText, style: link),
            TextSpan(text: label.substring(at + linkText.length)),
          ];
    return Semantics(
      checked: done,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 18,
                color: done ? AppColors.success : AppColors.iconMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(TextSpan(style: base, children: spans)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GoogleIconPainter());
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double s = w / 24.0; // scale factor based on 24x24 standard viewport

    final paint = Paint()..style = PaintingStyle.fill;

    // Red (Top Arc)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0 * s, 5.04 * s)
      ..cubicTo(13.94 * s, 5.04 * s, 15.73 * s, 5.71 * s, 17.12 * s, 7.01 * s)
      ..lineTo(20.94 * s, 3.19 * s)
      ..cubicTo(18.57 * s, 1.05 * s, 15.52 * s, 0, 12.0 * s, 0)
      ..cubicTo(7.35 * s, 0, 3.32 * s, 2.67 * s, 1.34 * s, 6.57 * s)
      ..lineTo(5.67 * s, 9.93 * s)
      ..cubicTo(6.7 * s, 7.04 * s, 9.11 * s, 5.04 * s, 12.0 * s, 5.04 * s)
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow (Left Arc)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.67 * s, 14.07 * s)
      ..cubicTo(5.41 * s, 13.3 * s, 5.26 * s, 12.47 * s, 5.26 * s, 11.5 * s)
      ..cubicTo(5.26 * s, 10.53 * s, 5.41 * s, 9.7 * s, 5.67 * s, 8.93 * s)
      ..lineTo(1.34 * s, 5.57 * s)
      ..cubicTo(0.48 * s, 7.29 * s, 0, 9.22 * s, 0, 11.5 * s)
      ..cubicTo(0, 13.78 * s, 0.48 * s, 15.71 * s, 1.34 * s, 17.43 * s)
      ..lineTo(5.67 * s, 14.07 * s)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green (Bottom Arc)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0 * s, 18.96 * s)
      ..cubicTo(9.11 * s, 18.96 * s, 6.7 * s, 16.96 * s, 5.67 * s, 14.07 * s)
      ..lineTo(1.34 * s, 17.43 * s)
      ..cubicTo(3.32 * s, 21.33 * s, 7.35 * s, 24.0 * s, 12.0 * s, 24.0 * s)
      ..cubicTo(15.19 * s, 24.0 * s, 18.07 * s, 22.95 * s, 20.16 * s, 21.14 * s)
      ..lineTo(16.15 * s, 18.03 * s)
      ..cubicTo(15.01 * s, 18.8 * s, 13.56 * s, 18.96 * s, 12.0 * s, 18.96 * s)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue (Right & Bar)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.49 * s, 12.27 * s)
      ..cubicTo(23.49 * s, 11.46 * s, 23.42 * s, 10.65 * s, 23.29 * s, 9.87 * s)
      ..lineTo(12.0 * s, 9.87 * s)
      ..lineTo(12.0 * s, 14.41 * s)
      ..lineTo(18.44 * s, 14.41 * s)
      ..cubicTo(
        18.16 * s,
        15.88 * s,
        17.33 * s,
        17.12 * s,
        16.08 * s,
        17.96 * s,
      )
      ..lineTo(20.09 * s, 21.07 * s)
      ..cubicTo(
        22.43 * s,
        18.91 * s,
        23.49 * s,
        15.73 * s,
        23.49 * s,
        12.27 * s,
      )
      ..close();
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
