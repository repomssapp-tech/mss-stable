import '../../services/catalog/centralized_translator.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

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

/// A legal document shown in a bottom sheet.
///
/// "Accept" works only after the user has scrolled to the end of the document:
/// before that a hint says so, and tapping Accept shows an alert (in the app's
/// language) instead of accepting. A document short enough to be fully visible
/// counts as read.
class LegalDocumentModal extends StatefulWidget {
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

  @override
  State<LegalDocumentModal> createState() => _LegalDocumentModalState();

  /// Returns `true` when the user tapped "Accept", otherwise `null`
  /// (dismissed via the X icon, drag, or back gesture).
  static Future<bool?> showTermsOfUse(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentModal.termsOfUse(),
    );
  }

  static Future<bool?> showPrivacyNotice(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentModal.privacyNotice(),
    );
  }

  static Future<bool?> showPrivacyPolicy(BuildContext context) {
    return showModalBottomSheet<bool>(
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

  factory LegalDocumentModal.privacyNotice() {
    return const LegalDocumentModal(
      title: 'Privacy Notice',
      subtitle: 'Personal data processing notice under DPDPA 2023',
      effectiveDate: '1 September 2026',
      acknowledgmentText:
          'MSS uses your personal information to create your profile and identify Government schemes that may be relevant to you.',
      introText:
          'This Privacy Notice outlines how your personal data is collected, used, and protected while using the MSS App.',
      sections: [
        LegalSectionItem(
          number: 1,
          title: 'What We Collect',
          body:
              'We collect: your Google Sign-In details and information provided by you, including name, City/town, District, State, date of birth / age, gender, preferred language, occupation/business type and income range.',
        ),
        LegalSectionItem(
          number: 2,
          title: 'Why We Use This Information',
          body:
              'We use this information to: authenticate you, maintain your profile, match your profile with potentially relevant Government schemes, provide language preferences, maintain security and operate the MSS App.\n\nMSS does not sell your personal data.',
        ),
        LegalSectionItem(
          number: 3,
          title: 'External Government Schemes',
          body:
              'When you choose to apply for a scheme, MSS redirects you to the relevant Government or official website. Your MSS profile information is not automatically transferred to that website. Information subsequently provided by you on the external website is governed by that website\'s privacy practices.',
        ),
        LegalSectionItem(
          number: 4,
          title: 'Data Retention & Security',
          body:
              'Your data will be retained only for as long as necessary for these purposes or as required by applicable law and will be protected using reasonable security safeguards.',
        ),
        LegalSectionItem(
          number: 5,
          title: 'Your Rights & Grievances',
          body:
              'You may exercise applicable rights regarding your personal data, including correction, updating, erasure, withdrawal of consent and grievance redressal.\n\nFor privacy requests or grievances, contact: MSS Grievance Officer at mssschemessearch@gmail.com.\n\nPlease read our full Privacy Policy for further information.',
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
          'MSS App (“MSS”, “we”, “us”) respects your privacy and is committed to protecting your personal data in accordance with the Digital Personal Data Protection Act, 2023 and applicable rules.',
      introText:
          'MSS respects your privacy and is committed to protecting the personal information you provide while using the MSS App.',
      sections: [
        LegalSectionItem(
          number: 1,
          title: 'Personal Data We Collect',
          body:
              'When you use MSS, we may collect:\n\n• Google Sign-In information: name, email address and other basic information made available through Google Sign-In, as permitted by you.\n• Profile information provided by you: name, City/town, District, State, age, gender, preferred language, type of occupation/business and income range.\n• Technical information: limited device, security, diagnostic or usage information necessary for secure and reliable operation of the App, where applicable. We use cookies to save your preferences and related technical information.',
        ),
        LegalSectionItem(
          number: 2,
          title: 'Why We Use Your Data',
          body:
              'Your personal data is used to:\n\n• Authenticate you and maintain your account;\n• Create and maintain your profile;\n• Identify and display Government schemes that may be relevant to your profile;\n• Provide the App in your preferred language;\n• Improve security and prevent misuse; and\n• Meet applicable legal requirements.\n\nMSS does not sell your personal data.',
        ),
        LegalSectionItem(
          number: 3,
          title: 'Government Scheme Applications',
          body:
              'MSS helps you discover Government schemes based on the information provided by you. If you select a scheme, MSS may direct you to the relevant Government or other official website to continue the application process.\n\nMSS does not submit your application or transfer your MSS profile information to such website unless this is specifically disclosed to you and permitted by you.\n\nOnce you leave MSS and access an external website, the collection and processing of information by that website will be governed by its own privacy practices and terms.',
        ),
        LegalSectionItem(
          number: 4,
          title: 'Service Providers',
          body:
              'We may use authorised service providers, including technology, hosting, security or authentication providers, where necessary to operate MSS. They may process personal data only for providing such services and subject to appropriate safeguards.\n\nGoogle Sign-In is also subject to Google\'s applicable privacy terms.',
        ),
        LegalSectionItem(
          number: 5,
          title: 'Retention and Security',
          body:
              'We retain personal data only for as long as necessary for the purposes for which it was collected or as required by law.\n\nWe use reasonable technical and organisational security measures designed to protect personal data against unauthorised access, disclosure, alteration, loss or misuse.',
        ),
        LegalSectionItem(
          number: 6,
          title: 'Your Rights',
          body:
              'Subject to applicable law, you may exercise your rights relating to your personal data, including access to information about its processing, correction, completion or updating, erasure, withdrawal of consent, and grievance redressal.\n\nWithdrawal of consent will not affect processing already lawfully undertaken before withdrawal.',
        ),
        LegalSectionItem(
          number: 7,
          title: 'Children',
          body:
              'If MSS is not intended for persons below 18 years of age, they should not create an account or provide personal data through the App.',
        ),
        LegalSectionItem(
          number: 8,
          title: 'Grievance Contact',
          body:
              'For privacy questions, grievances or requests concerning your personal data, contact:\n\nData Protection / Grievance Contact:\nMSS Grievance Officer\n\nEmail:\nmssschemessearch@gmail.com',
        ),
        LegalSectionItem(
          number: 9,
          title: 'Changes',
          body:
              'We may update this Privacy Policy from time to time. Material changes will be appropriately communicated through the App.\n\nLast Updated: 1 September 2026',
        ),
      ],
    );
  }
}

class _LegalDocumentModalState extends State<LegalDocumentModal> {
  final ScrollController _scroll = ScrollController();
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkEnd);
    // A document that fits on screen has nothing to scroll: it counts as read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
  }

  void _checkEnd() {
    if (!mounted || _reachedEnd || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _reachedEnd = true);
    }
  }

  Future<void> _explainScrollRequirement() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(dialogContext.l10n.legalScrollToEndNotice),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.ok),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
                        CentralizedTranslator.instance.localize(widget.title),
                        style: AppGoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        CentralizedTranslator.instance.localize(
                          widget.subtitle,
                        ),
                        style: AppGoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF334155)),
                  tooltip: context.l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
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
                          CentralizedTranslator.instance.localize(
                            'Effective Date: ${widget.effectiveDate}',
                          ),
                          style: AppGoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          CentralizedTranslator.instance.localize(
                            widget.acknowledgmentText,
                          ),
                          style: AppGoogleFonts.inter(
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
                  if (widget.introText.isNotEmpty) ...[
                    Text(
                      CentralizedTranslator.instance.localize(widget.introText),
                      style: AppGoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Numbered Sections
                  for (final section in widget.sections)
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
                                  CentralizedTranslator.instance.localize(
                                    section.title,
                                  ),
                                  style: AppGoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  CentralizedTranslator.instance.localize(
                                    section.body,
                                  ),
                                  style: AppGoogleFonts.inter(
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
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_reachedEnd)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        context.l10n.legalScrollToEndHint,
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _reachedEnd
                            ? const Color(0xFF0D53FC)
                            : AppColors.disabledFg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _reachedEnd
                          ? () => Navigator.of(context).pop(true)
                          : _explainScrollRequirement,
                      child: Text(
                        context.l10n.legalAccept,
                        style: AppGoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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
