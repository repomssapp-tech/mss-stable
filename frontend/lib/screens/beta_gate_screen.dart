import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'login_screen.dart';
import 'regular_mode/language_selection_screen.dart';
import '../services/account/session_cache_service.dart';
import '../utils/app_size.dart';
import '../utils/app_spacing.dart';
import '../widgets/common/app_toast.dart';
import '../utils/constants.dart';
import '../services/beta_gate/beta_gate_service.dart';
import '../utils/app_text.dart';

/// Screen displayed immediately following the splash screen when [isBetaModeEnabled]
/// is true and the device has not yet entered the valid beta password.
class BetaGateScreen extends StatefulWidget {
  final BetaGateService? service;

  const BetaGateScreen({super.key, this.service});

  @override
  State<BetaGateScreen> createState() => _BetaGateScreenState();
}

class _BetaGateScreenState extends State<BetaGateScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  late final BetaGateService _gateService;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _gateService = widget.service ?? BetaGateService();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final input = _passwordController.text.trim();
    if (input.isEmpty) {
      AppToast.showWarning(context, context.l10n.betaGateEnterPassword);
      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _gateService.verifyPassword(input);

      if (!mounted) return;

      if (success) {
        await _routeToNextScreen();
      } else {
        _showError(context.l10n.betaGateInvalidPassword);
        _passwordController.clear();
        _passwordFocusNode.requestFocus();
      }
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.betaGateVerifyFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _routeToNextScreen() async {
    final cache = SessionCacheService.instance;
    final lang = await cache.getLanguage();

    if (!mounted) return;

    if (lang == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  /// Errors use the app's shared toast, like every other screen.
  void _showError(String message) {
    if (!mounted) return;
    AppToast.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background layer
          const _BetaGateBackground(),

          // Foreground scrollable content
          SafeArea(
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
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            const Spacer(flex: 1),

                            // Brand Logo
                            Image.asset(
                              'assets/images/Logo/Logo.webp',
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 80,
                                    color: AppConstants.primaryColor,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Main Auth Card
                            _BetaGateCard(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              isLoading: _isLoading,
                              isPasswordVisible: _isPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              onSubmitted: _isLoading ? null : _handleVerify,
                            ),

                            const Spacer(flex: 2),

                            // Subtext disclaimer
                            Text(
                              context.l10n.betaGateAuthorizedTestersOnly,
                              textAlign: TextAlign.center,
                              style: AppGoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8), // Slate 400
                                letterSpacing: 0.4,
                              ),
                            ),
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
        ],
      ),
    );
  }
}

/// Decorative full-screen background matching the splash and login aesthetics.
class _BetaGateBackground extends StatelessWidget {
  const _BetaGateBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/Background/splash_screen.webp',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: const BoxDecoration(gradient: AppConstants.blueGradient),
        ),
      ),
    );
  }
}

/// Elevated Card containing the beta gate header, text input, and verify button.
class _BetaGateCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onSubmitted;

  const _BetaGateCard({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Slate 200
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // ~4% opacity
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock Badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF), // Blue 50
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            context.l10n.betaGateAccess,
            style: AppGoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A), // Slate 900
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Subtitle
          Text(
            context.l10n.betaGateEnterPasswordToContinue,
            textAlign: TextAlign.center,
            style: AppGoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B), // Slate 500
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Password Input Field
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !isLoading,
            obscureText: !isPasswordVisible,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted?.call(),
            style: AppGoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: context.l10n.betaGatePasswordHint,
              hintStyle: AppGoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8), // Slate 400
              ),
              prefixIcon: const Icon(
                Icons.key_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
                onPressed: isLoading ? null : onToggleVisibility,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC), // Slate 50
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppConstants.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Verify & Enter Button
          ConstrainedBox(
            // The design system's control height; grows with the text scale.
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: AppSize.controlHeight,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading ? null : onSubmitted,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.betaGateVerifyAndEnter,
                          style: AppGoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
