import '../../../services/catalog/centralized_translator.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../widgets/common/standard_page_header.dart';

/// Full-page detailed Terms of Use Screen for MSS App
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
      appBar: StandardPageHeader(title: context.l10n.legalTermsOfUseLink),
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
                        Icons.gavel_rounded,
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
                            context.l10n.termsOfUseHeading,
                            style: context.text.titleSmall.copyWith(
                              color: kSlate900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.l10n.termsEffectiveDate,
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
                context.l10n.termsIntroduction,
                style: context.text.body.copyWith(color: kSlate700),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section 1: Use of the MSS App
              _buildSectionCard(
                context,
                icon: Icons.apps_rounded,
                title: '1. Use of the MSS App',
                content: [
                  '• Lawful Purpose: You agree to use MSS responsibly and only for lawful purposes.',
                  '• Accurate Details: Information provided by you should be accurate and, where applicable, kept up to date.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 2: Government Scheme Information
              _buildSectionCard(
                context,
                icon: Icons.info_outline_rounded,
                title: '2. Government Scheme Information',
                content: [
                  '• Informational Purpose: MSS provides information about Government schemes for informational, discovery and awareness purposes.',
                  '• Scheme Changes: Scheme eligibility, benefits, application requirements, deadlines and other details may change over time.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 3: Scheme Recommendations
              _buildSectionCard(
                context,
                icon: Icons.recommend_outlined,
                title: '3. Scheme Recommendations',
                content: [
                  '• Personalized Recommendations: MSS may provide personalized scheme recommendations based on information provided by you.',
                  '• No Guarantee: A recommendation or eligibility indication does not constitute a guarantee of eligibility, approval or receipt of benefits.',
                  '• Final Authority: Final decisions regarding eligibility, applications and benefits are made by the respective Government authority.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 4: Applications
              _buildSectionCard(
                context,
                icon: Icons.open_in_browser_rounded,
                title: '4. Applications',
                content: [
                  '• Official Redirection: When you choose to apply for a scheme, MSS may redirect you to the relevant Government or official website.',
                  '• No Third-Party Submission: Unless expressly stated otherwise, MSS does not submit applications on your behalf or guarantee the outcome of an application.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 5: External Websites
              _buildSectionCard(
                context,
                icon: Icons.link_rounded,
                title: '5. External Websites',
                content: [
                  '• Independent Portals: Government and official websites accessed through MSS are independently operated and may have their own terms, privacy policies and application procedures.',
                  '• User Review: Users should review those policies before providing information on external websites.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 6: AI Assistant
              _buildSectionCard(
                context,
                icon: Icons.smart_toy_outlined,
                title: '6. AI Assistant',
                content: [
                  '• Navigation Guidance: MSS may provide an AI-powered assistant to help users navigate the application, understand scheme information and access relevant features.',
                  '• Non-Legal Assistance: AI-generated responses are intended for assistance and should not be considered a final Government decision, legal advice or a guarantee of scheme eligibility.',
                  '• Official Verification: Users should verify important information with the relevant official Government source.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 7: User Responsibilities
              _buildSectionCard(
                context,
                icon: Icons.assignment_ind_outlined,
                title: '7. User Responsibilities',
                intro: 'You agree not to:',
                content: [
                  '• Provide intentionally false or misleading information.',
                  '• Misuse or interfere with the MSS App.',
                  '• Attempt unauthorized access to the application or its systems.',
                  '• Use MSS for unlawful or fraudulent purposes.',
                  '• Attempt to disrupt or manipulate the application\'s services.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 8: Service Availability
              _buildSectionCard(
                context,
                icon: Icons.cloud_done_outlined,
                title: '8. Service Availability',
                content: [
                  '• Service Continuity: We aim to provide a reliable service but do not guarantee that MSS will always be available, uninterrupted or error-free.',
                  '• Modifications: Features may be modified, suspended or discontinued when necessary.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 9: Changes to the Terms
              _buildSectionCard(
                context,
                icon: Icons.history_rounded,
                title: '9. Changes to the Terms',
                content: [
                  '• Updates: These Terms of Use may be updated from time to time. Updated terms will be made available through the MSS App.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 10: Contact
              _buildSectionCard(
                context,
                icon: Icons.contact_support_outlined,
                title: '10. Contact',
                content: [
                  '• For questions regarding these Terms of Use, please contact MSS Support at mssschemessearch@gmail.com.',
                  '• Support Email: mssschemessearch@gmail.com',
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Agreement Footer Box
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
                          Icons.check_circle_outline_rounded,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.termsAgreementHeading,
                            style: context.text.cardTitle.copyWith(
                              color: kSlate900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      context.l10n.termsAgreementBody,
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
