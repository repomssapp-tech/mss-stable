import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../services/account/rest_auth_service.dart';
import '../../../services/network/api_exception.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/common/app_toast.dart';
import '../../splash_screen.dart';

/// Modal dialog for managing account password (Set, Change, Remove).
class PasswordManagementDialog extends StatefulWidget {
  const PasswordManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PasswordManagementDialog(),
    );
  }

  @override
  State<PasswordManagementDialog> createState() =>
      _PasswordManagementDialogState();
}

class _PasswordManagementDialogState extends State<PasswordManagementDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  bool _hasPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkPasswordStatus() async {
    try {
      final hasPass = await RestAuthService.instance.hasPassword();
      if (mounted) {
        setState(() {
          _hasPassword = hasPass;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitSetOrChange() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final currentPass = _currentPasswordController.text;

    if (newPass.length < 15 || newPass.length > 128) {
      AppToast.showWarning(
        context,
        'Password must be between 15 and 128 characters.',
      );
      return;
    }

    if (newPass != confirmPass) {
      AppToast.showWarning(
        context,
        'New password and confirmation do not match.',
      );
      return;
    }

    if (_hasPassword && currentPass.isEmpty) {
      AppToast.showWarning(
        context,
        'Please enter your current password.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await RestAuthService.instance.setPassword(
        newPassword: newPass,
        currentPassword: _hasPassword ? currentPass : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        AppToast.showSuccess(
          context,
          context.l10n.passwordChangedNotice,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        if (e.statusCode == 403 || e.errorCode == 'REAUTHENTICATION_REQUIRED') {
          AppToast.showWarning(
            context,
            'Recent authentication required. Please sign in again.',
          );
        } else if (e.errorCode == 'PASSWORD_POLICY_FAILED') {
          AppToast.showWarning(
            context,
            'Password does not meet complexity requirements.',
          );
        } else if (e.statusCode == 401 || e.errorCode == 'INVALID_CREDENTIALS') {
          AppToast.showWarning(
            context,
            'Current password is incorrect.',
          );
        } else if (e.isRateLimited) {
          AppToast.showWarning(
            context,
            'Too many attempts. Please try again later.',
          );
        } else {
          AppToast.showWarning(
            context,
            e.message.isNotEmpty ? e.message : 'Failed to update password.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.showWarning(context, 'Unexpected error updating password.');
      }
    }
  }

  Future<void> _removePassword() async {
    final currentPass = _currentPasswordController.text;
    if (currentPass.isEmpty) {
      AppToast.showWarning(
        context,
        'Enter current password to remove it.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await RestAuthService.instance.deletePassword(currentPass);
      if (mounted) {
        Navigator.of(context).pop();
        AppToast.showSuccess(
          context,
          context.l10n.passwordRemovedNotice,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        if (e.statusCode == 401 || e.errorCode == 'INVALID_CREDENTIALS') {
          AppToast.showWarning(context, 'Current password is incorrect.');
        } else {
          AppToast.showWarning(context, 'Failed to remove password.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.showWarning(context, 'Failed to remove password.');
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
        child: _loading
            ? const SizedBox(
                height: 120, // spacing-ok
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
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
                            Icons.lock_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _hasPassword
                                ? context.l10n.changePasswordTitle
                                : context.l10n.setPasswordTitle,
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
                    if (_hasPassword) ...[
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: context.l10n.currentPasswordLabel,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: context.l10n.newPasswordLabel,
                        hintText: 'Min 15 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: context.l10n.confirmPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitSetOrChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox( // spacing-ok
                              height: AppSpacing.xl,
                              width: AppSpacing.xl,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _hasPassword
                                  ? context.l10n.changePasswordTitle
                                  : context.l10n.setPasswordTitle,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    if (_hasPassword) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _submitting ? null : _removePassword,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        child: Text(
                          context.l10n.removePasswordTitle,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
