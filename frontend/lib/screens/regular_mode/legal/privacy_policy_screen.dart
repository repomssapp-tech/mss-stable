import '../../../services/catalog/centralized_translator.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Full-page detailed Privacy Policy Screen for MSS App
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate900 = AppColors.textPrimary;
  static const Color kSlate700 = AppColors.textBody;
  static const Color kSlate500 = AppColors.textMuted;
  static const Color kBorderGrey = AppColors.border;
  static const Color kBgLight = AppColors.background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kSlate900,
            size: 20,
          ),
          tooltip: context.l10n.back,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          CentralizedTranslator.instance.localize('Privacy Policy'),
          style: context.text.titleMedium.copyWith(color: kSlate900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.textOnPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CentralizedTranslator.instance.localize(
                              'MSS App Privacy Commitment',
                            ),
                            style: context.text.titleSmall.copyWith(
                              color: kSlate900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            CentralizedTranslator.instance.localize(
                              'Effective Date: 1 September 2026 • DPDPA 2023',
                            ),
                            style: context.text.bodySmall.copyWith(
                              color: kSlate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                CentralizedTranslator.instance.localize(
                  'MSS App (“MSS”, “we”, “us”) respects your privacy and is committed to protecting your personal data in accordance with the Digital Personal Data Protection Act, 2023 and applicable rules.',
                ),
                style: context.text.body.copyWith(color: kSlate700),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section 1: Personal Data We Collect
              _buildSectionCard(
                context,
                icon: Icons.person_search_rounded,
                title: '1. Personal Data We Collect',
                intro: 'When you use MSS, we may collect:',
                content: [
                  '• Google Sign-In information: Name, email address and other basic information made available through Google Sign-In, as permitted by you.',
                  '• Profile information provided by you: Name, City/town, District, State, age, gender, preferred language, type of occupation/business and income range.',
                  '• Technical information: Limited device, security, diagnostic or usage information necessary for secure and reliable operation of the App, where applicable. We use cookies to save your preferences and related technical information.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 2: Why We Use Your Data
              _buildSectionCard(
                context,
                icon: Icons.tune_rounded,
                title: '2. Why We Use Your Data',
                intro: 'Your personal data is used to:',
                content: [
                  '• Authenticate you and maintain your account.',
                  '• Create and maintain your profile.',
                  '• Identify and display Government schemes that may be relevant to your profile.',
                  '• Provide the App in your preferred language.',
                  '• Improve security and prevent misuse.',
                  '• Meet applicable legal requirements.',
                  '• Zero Data Monetization: MSS does not sell your personal data.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 3: Government Scheme Applications
              _buildSectionCard(
                context,
                icon: Icons.open_in_browser_rounded,
                title: '3. Government Scheme Applications',
                content: [
                  '• Discovery & Guidance: MSS helps you discover Government schemes based on the information provided by you. If you select a scheme, MSS may direct you to the relevant Government or other official website to continue the application process.',
                  '• Consent-Gated Transfers: MSS does not submit your application or transfer your MSS profile information to such website unless this is specifically disclosed to you and permitted by you.',
                  '• External Portals: Once you leave MSS and access an external website, the collection and processing of information by that website will be governed by its own privacy practices and terms.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 4: Service Providers
              _buildSectionCard(
                context,
                icon: Icons.hub_outlined,
                title: '4. Service Providers',
                content: [
                  '• Authorised Providers: We may use authorised service providers, including technology, hosting, security or authentication providers, where necessary to operate MSS. They may process personal data only for providing such services and subject to appropriate safeguards.',
                  '• Third-Party Terms: Google Sign-In is also subject to Google\'s applicable privacy terms.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 5: Retention and Security
              _buildSectionCard(
                context,
                icon: Icons.lock_outline_rounded,
                title: '5. Retention and Security',
                content: [
                  '• Data Retention: We retain personal data only for as long as necessary for the purposes for which it was collected or as required by law.',
                  '• Technical Safeguards: We use reasonable technical and organisational security measures designed to protect personal data against unauthorised access, disclosure, alteration, loss or misuse.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 6: Your Rights
              _buildSectionCard(
                context,
                icon: Icons.account_circle_outlined,
                title: '6. Your Rights',
                content: [
                  '• Data Principal Rights: Subject to applicable law, you may exercise your rights relating to your personal data, including access to information about its processing, correction, completion or updating, erasure, withdrawal of consent, and grievance redressal.',
                  '• Prior Lawful Processing: Withdrawal of consent will not affect processing already lawfully undertaken before withdrawal.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 7: Children
              _buildSectionCard(
                context,
                icon: Icons.family_restroom_rounded,
                title: '7. Children',
                content: [
                  '• Minimum Age: If MSS is not intended for persons below 18 years of age, they should not create an account or provide personal data through the App.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 8: Grievance Contact
              _buildSectionCard(
                context,
                icon: Icons.contact_mail_outlined,
                title: '8. Grievance Contact',
                intro:
                    'For privacy questions, grievances or requests concerning your personal data, contact:',
                content: [
                  '• Data Protection / Grievance Contact: MSS Grievance Officer',
                  '• Email: mssschemessearch@gmail.com',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 9: Changes
              _buildSectionCard(
                context,
                icon: Icons.history_rounded,
                title: '9. Changes',
                content: [
                  '• Policy Updates: We may update this Privacy Policy from time to time. Material changes will be appropriately communicated through the App.',
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Contact Footer Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: kBgLight,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: kBorderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            CentralizedTranslator.instance.localize(
                              'Have Privacy Questions?',
                            ),
                            style: context.text.cardTitle.copyWith(
                              color: kSlate900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      CentralizedTranslator.instance.localize(
                        'If you have questions regarding data privacy, rights, or grievances, contact our Grievance Officer at mssschemessearch@gmail.com.',
                      ),
                      style: context.text.bodySmall.copyWith(color: kSlate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? intro,
    required List<String> content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: kBorderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimaryBlue, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  CentralizedTranslator.instance.localize(title),
                  style: context.text.cardTitle.copyWith(color: kSlate900),
                ),
              ),
            ],
          ),
          if (intro != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              CentralizedTranslator.instance.localize(intro),
              style: context.text.label.copyWith(color: kSlate700),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...content.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                CentralizedTranslator.instance.localize(point),
                style: context.text.body.copyWith(color: kSlate700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
