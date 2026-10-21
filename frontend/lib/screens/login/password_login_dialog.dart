import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../services/network/api_exception.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../widgets/common/app_toast.dart';

/// Dialog allowing email and password login for registered users.
class PasswordLoginDialog extends StatefulWidget {
  const PasswordLoginDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PasswordLoginDialog(),
    );
  }

  @override
  State<PasswordLoginDialog> createState() => _PasswordLoginDialogState();
}

class _PasswordLoginDialogState extends State<PasswordLoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      AppToast.showWarning(context, context.l10n.pwInvalidEmail);
      return;
    }

    if (password.isEmpty) {
      AppToast.showWarning(context, context.l10n.pwEnterPassword);
      return;
    }

    setState(() => _loading = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final success = await provider.loginWithPassword(email, password);
      if (mounted) {
        if (success || provider.isLoggedIn) {
          Navigator.of(context).pop();
        } else {
          setState(() => _loading = false);
          AppToast.showError(context, context.l10n.pwLoginFailed);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (e.statusCode == 401 || e.errorCode == 'INVALID_CREDENTIALS') {
          AppToast.showError(context, context.l10n.pwInvalidCredentials);
        } else if (e.isRateLimited) {
          AppToast.showWarning(context, context.l10n.pwTooManyAttempts);
        } else {
          AppToast.showError(context, e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.showError(context, context.l10n.pwLoginUnexpected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      context.l10n.signInWithPassword,
                      style: context.text.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.iconMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.l10n.emailAddress,
                  hintText: 'name@example.com',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: context.l10n.passwordSetting,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _loading ? null : _submitLogin,
                child: _loading
                    ? const SizedBox(
                        // spacing-ok
                        height: AppSpacing.xl,
                        width: AppSpacing.xl,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(context.l10n.pwSignInButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
