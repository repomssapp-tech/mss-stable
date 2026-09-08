import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_spacing.dart';

class LegalSectionItem {
  final int number;
  final String title;
  final String body;

  const LegalSectionItem({
    required this.number,
    required this.title,
    required this.body,
  });
}

class LegalDocumentModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final String effectiveDate;
  final String acknowledgmentText;
  final String introText;
  final List<LegalSectionItem> sections;

  const LegalDocumentModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.effectiveDate,
    required this.acknowledgmentText,
    required this.introText,
    required this.sections,
  });

  static Future<void> showTermsOfUse(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentModal.termsOfUse(),
    );
  }

  static Future<void> showPrivacyPolicy(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentModal.privacyPolicy(),
    );
  }

  factory LegalDocumentModal.termsOfUse() {
    return const LegalDocumentModal(
      title: 'Terms of Use',
      subtitle: 'Rules and guidelines for using the MSS App',
      effectiveDate: '1 September 2026',
      acknowledgmentText:
          'By accessing or using the MSS application, you acknowledge that you have read, understood and agree to be bound by these Terms of Use.',
      introText:
          'Welcome to MSS. MSS is a digital platform designed to help users discover, understand and explore Government schemes that may be relevant to them.',
      sections: [
        LegalSectionItem(
          number: 1,
          title: 'Use of the MSS App',
          body:
              'You agree to use MSS responsibly and only for lawful purposes. Information provided by you should be accurate and, where applicable, kept up to date.',
        ),
        LegalSectionItem(
          number: 2,
          title: 'Government Scheme Information',
          body:
              'MSS provides information about Government schemes for informational, discovery and awareness purposes. Scheme eligibility, benefits, application requirements, deadlines and other details may change.',
        ),
        LegalSectionItem(
          number: 3,
          title: 'Scheme Recommendations',
          body:
              'MSS may provide personalized scheme recommendations based on information provided by you. A recommendation or eligibility indication does not constitute a guarantee of eligibility, approval or receipt of benefits.\n\nFinal decisions regarding eligibility, applications and benefits are made by the respective Government authority.',
        ),
        LegalSectionItem(
          number: 4,
          title: 'Applications',
          body:
              'When you choose to apply for a scheme, MSS may redirect you to the relevant Government or official website.\n\nUnless expressly stated otherwise, MSS does not submit applications on your behalf or guarantee the outcome of an application.',
        ),
        LegalSectionItem(
          number: 5,
          title: 'External Websites',
          body:
              'Government and official websites accessed through MSS are independently operated and may have their own terms, privacy policies and application procedures. Users should review those policies before providing information on external websites.',
        ),
        LegalSectionItem(
          number: 6,
          title: 'AI Assistant',
          body:
              'MSS may provide an AI-powered assistant to help users navigate the application, understand scheme information and access relevant features.\n\nAI-generated responses are intended for assistance and should not be considered a final Government decision, legal advice or a guarantee of scheme eligibility.\n\nUsers should verify important information with the relevant official Government source.',
        ),
        LegalSectionItem(
          number: 7,
          title: 'User Responsibilities',
          body:
              'You agree not to:\n\n• Provide intentionally false or misleading information.\n• Misuse or interfere with the MSS App.\n• Attempt unauthorized access to the application or its systems.\n• Use MSS for unlawful or fraudulent purposes.\n• Attempt to disrupt or manipulate the application\'s services.',
        ),
        LegalSectionItem(
          number: 8,
          title: 'Service Availability',
          body:
              'We aim to provide a reliable service but do not guarantee that MSS will always be available, uninterrupted or error-free. Features may be modified, suspended or discontinued when necessary.',
        ),
        LegalSectionItem(
          number: 9,
          title: 'Changes to the Terms',
          body:
              'These Terms of Use may be updated from time to time. Updated terms will be made available through the MSS App.',
        ),
        LegalSectionItem(
          number: 10,
          title: 'Contact',
          body:
              'For questions regarding these Terms of Use, please contact MSS Support through the contact information provided within the application.\n\nLast Updated: 1 September 2026',
        ),
      ],
    );
  }

  factory LegalDocumentModal.privacyPolicy() {
    return const LegalDocumentModal(
      title: 'Privacy Policy',
      subtitle: 'How MSS collects, uses and protects your information',
      effectiveDate: '1 September 2026',
      acknowledgmentText:
          'By accessing or using the MSS application, you acknowledge that you have read, understood and agree to this Privacy Policy.',
      introText:
          'MSS respects your privacy and is committed to protecting the personal information you provide while using the MSS App.',
      sections: [
        LegalSectionItem(
          number: 1,
          title: 'Information We Collect',
          body:
              'Depending on how you use MSS, we may collect:\n\n• Name\n• Email address and basic information provided through Google Sign-In\n• Date of birth or age\n• Gender\n• State, district and city/village\n• Preferred language\n• Occupation or business type\n• Income information\n• Category or community information\n• Other eligibility-related information voluntarily provided by you\n• Limited technical, diagnostic, security or usage information required to operate and protect the application',
        ),
        LegalSectionItem(
          number: 2,
          title: 'How We Use Your Information',
          body:
              'Your information may be used to:\n\n• Authenticate and maintain your account.\n• Create and maintain your MSS profile.\n• Identify Government schemes that may be relevant to you.\n• Provide personalized scheme recommendations.\n• Provide language and application preferences.\n• Maintain application security.\n• Prevent misuse of the service.\n• Improve and maintain MSS.\n• Comply with applicable legal requirements.\n\nMSS does not sell your personal data.',
        ),
        LegalSectionItem(
          number: 3,
          title: 'Government Scheme Applications',
          body:
              'MSS may redirect you to a relevant Government or official website when you choose to apply for a scheme.\n\nYour MSS profile information is not automatically transferred to an external website unless such transfer is specifically disclosed and permitted.\n\nAny information you subsequently provide on an external website will be subject to that website\'s own privacy policy and terms.',
        ),
        LegalSectionItem(
          number: 4,
          title: 'Data Security',
          body:
              'MSS uses reasonable technical and organizational safeguards designed to protect personal information against unauthorized access, misuse, alteration, loss or disclosure.\n\nHowever, no digital service can guarantee absolute security.',
        ),
        LegalSectionItem(
          number: 5,
          title: 'Data Retention',
          body:
              'Personal information will be retained only for as long as necessary to provide MSS services, maintain your account and profile, fulfill legitimate operational requirements, or comply with applicable legal obligations.',
        ),
        LegalSectionItem(
          number: 6,
          title: 'Your Rights and Choices',
          body:
              'Subject to applicable law, you may have rights relating to your personal data, including:\n\n• Access to information about its processing\n• Correction or updating of inaccurate information\n• Erasure where applicable\n• Withdrawal of consent\n• Grievance redressal',
        ),
        LegalSectionItem(
          number: 7,
          title: 'External Services',
          body:
              'MSS may use authorized service providers for authentication, hosting, security, analytics or other operational purposes where required to provide and maintain the service.\n\nGoogle Sign-In and external Government websites may have their own applicable privacy policies.',
        ),
        LegalSectionItem(
          number: 8,
          title: 'Changes to This Privacy Policy',
          body:
              'This Privacy Policy may be updated when necessary. Updated versions will be made available through the MSS App.',
        ),
        LegalSectionItem(
          number: 9,
          title: 'Contact and Grievance Redressal',
          body:
              'For privacy-related requests, questions or grievances:\n\nData Protection / Grievance Contact:\nMSS Grievance Officer\n\nEmail:\nmssapp@gmail.com\n\nPhone:\n+91 44 2681 1999\n\nLast Updated:\n1 September 2026',
        ),
      ],
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
                color: const Color(0xFFCBD5E1),
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
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF334155)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Effective Date Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Effective Date: $effectiveDate',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          acknowledgmentText,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Intro Text
                  if (introText.isNotEmpty) ...[
                    Text(
                      introText,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Numbered Sections
                  for (final section in sections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${section.number}',
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  section.body,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF475569),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Sticky Bottom Close Button
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D53FC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
