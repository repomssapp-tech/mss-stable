import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_spacing.dart';

/// Full-page detailed Privacy Policy Screen for MSS App
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate700 = Color(0xFF334155);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kBgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kSlate900,
            size: 20,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            color: kSlate900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryBlue.withValues(alpha: 0.08),
                      const Color(0xFFEFF6FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryBlue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MSS App Privacy Commitment',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kSlate900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Effective Date: 1 September 2026 • DPDPA 2023',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kSlate500,
                              fontWeight: FontWeight.w500,
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
                'MSS App (“MSS”, “we”, “us”) respects your privacy and is committed to protecting your personal data in accordance with the Digital Personal Data Protection Act, 2023 and applicable rules.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: kSlate700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section 1: Personal Data We Collect
              _buildSectionCard(
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
                icon: Icons.family_restroom_rounded,
                title: '7. Children',
                content: [
                  '• Minimum Age: If MSS is not intended for persons below 18 years of age, they should not create an account or provide personal data through the App.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 8: Grievance Contact
              _buildSectionCard(
                icon: Icons.contact_mail_outlined,
                title: '8. Grievance Contact',
                intro: 'For privacy questions, grievances or requests concerning your personal data, contact:',
                content: [
                  '• Data Protection / Grievance Contact: MSS Grievance Officer',
                  '• Email: mssschemessearch@gmail.com',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 9: Changes
              _buildSectionCard(
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
                  borderRadius: BorderRadius.circular(14),
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
                        Text(
                          'Have Privacy Questions?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kSlate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      'If you have questions regarding data privacy, rights, or grievances, contact our Grievance Officer at mssschemessearch@gmail.com.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: kSlate500,
                        height: 1.45,
                      ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? intro,
    required List<String> content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: kSlate900,
                  ),
                ),
              ),
            ],
          ),
          if (intro != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              intro,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kSlate700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...content.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                point,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: kSlate700,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-page detailed Terms of Use Screen for MSS App
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate700 = Color(0xFF334155);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kBgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kSlate900,
            size: 20,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Use',
          style: GoogleFonts.poppins(
            color: kSlate900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryBlue.withValues(alpha: 0.08),
                      const Color(0xFFEFF6FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryBlue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MSS App Terms of Use',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kSlate900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Effective Date: 1 September 2026',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: kSlate500,
                              fontWeight: FontWeight.w500,
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
                'Welcome to MSS. MSS is a digital platform designed to help users discover, understand and explore Government schemes that may be relevant to them. By accessing or using the MSS application, you acknowledge that you have read, understood and agree to be bound by these Terms of Use.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: kSlate700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section 1: Use of the MSS App
              _buildSectionCard(
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
                icon: Icons.history_rounded,
                title: '9. Changes to the Terms',
                content: [
                  '• Updates: These Terms of Use may be updated from time to time. Updated terms will be made available through the MSS App.',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 10: Contact
              _buildSectionCard(
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
                  borderRadius: BorderRadius.circular(14),
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
                        Text(
                          'Terms Agreement',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kSlate900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      'Continued use of the MSS App signifies your acceptance of these Terms of Use.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: kSlate500,
                        height: 1.45,
                      ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? intro,
    required List<String> content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: kSlate900,
                  ),
                ),
              ),
            ],
          ),
          if (intro != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              intro,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kSlate700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...content.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                point,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: kSlate700,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
