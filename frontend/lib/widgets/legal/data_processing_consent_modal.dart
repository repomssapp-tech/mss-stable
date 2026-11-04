import '../../services/catalog/centralized_translator.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

class DataProcessingConsentModal extends StatelessWidget {
  const DataProcessingConsentModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DataProcessingConsentModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.88;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CentralizedTranslator.instance.localize(
                          'Consent to Processing of Personal Data',
                        ),
                        style: context.text.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CentralizedTranslator.instance.localize(
                          'Your consent helps MSS personalize your experience.',
                        ),
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textBody),
                  tooltip: context.l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CentralizedTranslator.instance.localize(
                      'By completing your profile, you voluntarily consent to MSS collecting and processing information from your Google Sign-In and the personal information you provide, including:',
                    ),
                    style: context.text.body.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Data fields card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _BulletItem('Name'),
                        _BulletItem('City / Town'),
                        _BulletItem('District'),
                        _BulletItem('State'),
                        _BulletItem('Age'),
                        _BulletItem('Gender'),
                        _BulletItem('Preferred Language'),
                        _BulletItem('Occupation / Business Type'),
                        _BulletItem('Income Range'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 1: WHY WE USE YOUR INFORMATION
                  Text(
                    CentralizedTranslator.instance.localize(
                      'WHY WE USE YOUR INFORMATION',
                    ),
                    style: context.text.cardTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CentralizedTranslator.instance.localize(
                      'Your information may be used for:',
                    ),
                    style: context.text.body.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _NumberedItem(
                    number: 1,
                    text: 'Creating and maintaining your MSS profile.',
                  ),
                  const _NumberedItem(
                    number: 2,
                    text: 'Authenticating your account.',
                  ),
                  const _NumberedItem(
                    number: 3,
                    text:
                        'Identifying and displaying Government schemes that may be relevant to your profile.',
                  ),
                  const _NumberedItem(
                    number: 4,
                    text: 'Operating and securing the MSS App.',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: PLEASE UNDERSTAND
                  Text(
                    CentralizedTranslator.instance.localize(
                      'PLEASE UNDERSTAND',
                    ),
                    style: context.text.cardTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _BulletItem(
                    'Providing your personal data is voluntary. However, MSS may not be able to provide personalized scheme matching without the information required for that purpose.',
                  ),
                  const _BulletItem('MSS will not sell your personal data.'),
                  const _BulletItem(
                    'When you select a Government scheme, you may be redirected to an external Government or official website.',
                  ),
                  const _BulletItem(
                    'Your MSS profile information will not automatically be transferred to that external website.',
                  ),
                  const _BulletItem(
                    'You can withdraw your consent through your Profile Privacy settings or by contacting MSS.',
                  ),
                  const _BulletItem(
                    'Withdrawal of consent will not affect processing that was lawfully completed before withdrawal.',
                  ),
                  const _BulletItem(
                    'You may request correction, updating or erasure of your personal data and raise a grievance as described in the Privacy Notice and Privacy Policy.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),

          // Sticky Bottom Actions & Links
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Read-only: the data-use consent is recorded when the
                  // profile is completed, so there is nothing to accept here.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        context.l10n.close,
                        style: context.text.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              CentralizedTranslator.instance.localize(text),
              style: context.text.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedItem extends StatelessWidget {
  final int number;
  final String text;
  const _NumberedItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: context.text.button.copyWith(color: AppColors.textBody),
          ),
          Expanded(
            child: Text(
              CentralizedTranslator.instance.localize(text),
              style: context.text.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
