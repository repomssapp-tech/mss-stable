import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../services/network/api_exception.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
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
      AppToast.showWarning(context, 'Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      AppToast.showWarning(context, 'Please enter your password.');
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
          AppToast.showError(context, 'Login failed. Please check credentials.');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (e.statusCode == 401 || e.errorCode == 'INVALID_CREDENTIALS') {
          AppToast.showError(context, 'Invalid email or password.');
        } else if (e.isRateLimited) {
          AppToast.showWarning(context, 'Too many login attempts. Please wait.');
        } else {
          AppToast.showError(context, e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.showError(context, 'Unexpected error during login.');
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                      color: Color(0xFFEFF6FF),
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
                      'Sign in with Password',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'name@example.com',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox( // spacing-ok
                        height: AppSpacing.xl,
                        width: AppSpacing.xl,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
