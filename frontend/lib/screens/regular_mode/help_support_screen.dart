import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_toast.dart';
import '../../utils/app_spacing.dart';
import '../../services/support_ticket_service.dart';

class HelpSupportScreen extends StatefulWidget {
  final String initialMode; // 'faq', 'contact', 'both'
  const HelpSupportScreen({super.key, this.initialMode = 'both'});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  // Backend category values are kept as stable English literals; only the
  // dropdown display labels are localized.
  String _issueCategory = 'General Inquiry';

  List<Map<String, String>> _faqs(AppLocalizations l10n) => [
    {
      'question': l10n.faqEligibilityQ,
      'answer': l10n.faqEligibilityA,
    },
    {
      'question': l10n.faqApplyQ,
      'answer': l10n.faqApplyA,
    },
    {
      'question': l10n.faqTrackQ,
      'answer': l10n.faqTrackA,
    },
    {
      'question': l10n.faqFreeQ,
      'answer': l10n.faqFreeA,
    },
    {
      'question': l10n.faqDataFreshnessQ,
      'answer': l10n.faqDataFreshnessA,
    },
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.showSuccess(context, message);
  }

  void _showFAQBottomSheet(String question, String answer) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icons.help_outline_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.helpFaqAnswerTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                question,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _showAllFAQsBottomSheet() {
    final l10n = context.l10n;
    final allFaqs = [
      ..._faqs(l10n),
      {
        'question': l10n.faqScoringQ,
        'answer': l10n.faqScoringA,
      },
      {
        'question': l10n.faqDataSharingQ,
        'answer': l10n.faqDataSharingA,
      },
      {
        'question': l10n.faqMissingDocsQ,
        'answer': l10n.faqMissingDocsA,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l10n.helpAllFaqsTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                        tooltip: l10n.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: allFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = allFaqs[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            faq['question']!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          iconColor: const Color(0xFF2563EB),
                          collapsedIconColor: const Color(0xFF64748B),
                          shape: const Border(),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.none,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          children: [
                            Text(
                              faq['answer']!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportIssueBottomSheet() {
    final l10n = context.l10n;
    if (_emailController.text.trim().isEmpty) {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail != null && userEmail.isNotEmpty) {
        _emailController.text = userEmail;
      }
    }
    // Kept local (like the Feedback sheet's `submittingFeedback`) so it always
    // starts false on each open. As a State field it could stick at `true` --
    // the success path pops the sheet before the `finally` runs, so the
    // `context.mounted` guard skipped the reset and every later open showed a
    // permanently disabled Submit button.
    bool submitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bug_report_outlined,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l10n.helpReportIssueTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                        tooltip: l10n.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.helpReportIssueBody,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DropdownButtonFormField<String>(
                    initialValue: _issueCategory,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.filterCategory,
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                    items:
                        <({String value, String label})>[
                          (value: 'General Inquiry', label: l10n.helpCatGeneralInquiry),
                          (value: 'Eligibility Matcher Bug', label: l10n.helpCatMatcherBug),
                          (value: 'Wrong Scheme Details', label: l10n.helpCatWrongDetails),
                          (value: 'Feature Request', label: l10n.helpCatFeatureRequest),
                        ].map((cat) {
                          return DropdownMenuItem(
                            value: cat.value,
                            child: Text(cat.label),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _issueCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpContactEmailLabel,
                      hintText: context.l10n.helpContactEmailHint,
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpDescriptionLabel,
                      hintText: context.l10n.helpDescriptionHint,
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              final email = _emailController.text.trim();
                              final text = _feedbackController.text.trim();

                              try {
                                SupportTicketService.instance.validateInputs(
                                  category: _issueCategory,
                                  email: email,
                                  description: text,
                                );
                              } on SupportTicketValidationException catch (e) {
                                AppToast.showWarning(context, e.message);
                                return;
                              }

                              setModalState(() => submitting = true);

                              try {
                                await SupportTicketService.instance.submitTicket(
                                  category: _issueCategory,
                                  email: email,
                                  description: text,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  AppToast.showSuccess(
                                    context,
                                    l10n.helpTicketSubmitted,
                                  );
                                  _feedbackController.clear();
                                }
                              } on SupportTicketRateLimitException catch (e) {
                                if (context.mounted) {
                                  AppToast.showWarning(context, e.message);
                                }
                              } on SupportTicketValidationException catch (e) {
                                if (context.mounted) {
                                  AppToast.showWarning(context, e.message);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.showError(
                                    context,
                                    l10n.helpTicketSubmitFailed,
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => submitting = false);
                                }
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l10n.helpSubmitTicket,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFeedbackBottomSheet() {
    final l10n = context.l10n;
    double rating = 5.0;
    final feedbackTextController = TextEditingController();
    final emailController = TextEditingController();
    bool submittingFeedback = false;

    if (emailController.text.trim().isEmpty) {
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail != null && userEmail.isNotEmpty) {
        emailController.text = userEmail;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l10n.helpShareFeedbackTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                        tooltip: l10n.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.helpFeedbackBody,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          l10n.helpRateExperience,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starRating = index + 1;
                            return IconButton(
                              icon: Icon(
                                starRating <= rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 36,
                              ),
                              tooltip: l10n.helpRateStars(starRating),
                              onPressed: () {
                                setModalState(() {
                                  rating = starRating.toDouble();
                                });
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpContactEmailLabel,
                      hintText: l10n.helpFeedbackEmailHint,
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: feedbackTextController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpSuggestionsLabel,
                      hintText: context.l10n.helpSuggestionsHint,
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: submittingFeedback
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final text = feedbackTextController.text.trim();

                              try {
                                SupportTicketService.instance.validateInputs(
                                  category: 'Feedback',
                                  email: email,
                                  description: text,
                                );
                              } on SupportTicketValidationException catch (e) {
                                AppToast.showWarning(context, e.message);
                                return;
                              }

                              setModalState(() => submittingFeedback = true);

                              try {
                                await SupportTicketService.instance.submitTicket(
                                  category: 'Feedback',
                                  email: email,
                                  description: 'Rating: ${rating.toInt()} Stars\n\n$text',
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  AppToast.showSuccess(
                                    context,
                                    l10n.helpFeedbackThanks,
                                  );
                                }
                              } on SupportTicketRateLimitException catch (e) {
                                if (context.mounted) {
                                  AppToast.showWarning(context, e.message);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.showError(
                                    context,
                                    l10n.helpFeedbackSubmitFailed,
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => submittingFeedback = false);
                                }
                              }
                            },
                      child: submittingFeedback
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l10n.helpSubmitFeedback,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    double size = 44,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Flexible(
                        child: Text(
                          widget.initialMode == 'faq'
                              ? l10n.helpFaqSetting
                              : widget.initialMode == 'contact'
                              ? l10n.helpHeaderContact
                              : l10n.helpHeaderSupport,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.helpHeaderSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Card 1: FAQs Group
            if (widget.initialMode == 'both' || widget.initialMode == 'faq')
              _buildGroupCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        _buildCircleIcon(
                          icon: Icons.help_outline_rounded,
                          bgColor: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.helpFaqsGroupTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.hairline),
                              Text(
                                l10n.helpFaqsGroupSubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  ..._faqs(l10n).map((faq) {
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.hairline,
                          ),
                          title: Text(
                            faq['question']!,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          onTap: () => _showFAQBottomSheet(
                            faq['question']!,
                            faq['answer']!,
                          ),
                        ),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                      ],
                    );
                  }),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.hairline,
                    ),
                    title: Text(
                      l10n.helpViewAllFaqs,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    onTap: _showAllFAQsBottomSheet,
                  ),
                ],
              ),

            // Card 2: Contact Support Group
            if (widget.initialMode == 'both' || widget.initialMode == 'contact')
              _buildGroupCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        _buildCircleIcon(
                          icon: Icons.headset_mic_outlined,
                          bgColor: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.helpContactGroupTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.hairline),
                              Text(
                                l10n.helpContactGroupSubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.none, AppSpacing.lg, AppSpacing.lg),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCircleIcon(
                            icon: Icons.mail_outline_rounded,
                            bgColor: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            size: 36,
                            iconSize: 18,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.helpEmailUs,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          GestureDetector(
                            onTap: () => _copyToClipboard(
                              'mssschemessearch@gmail.com',
                              l10n.helpSupportEmailCopied,
                            ),
                            child: Text(
                              'mssschemessearch@gmail.com',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2563EB),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.helpReplyWindow,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Card 3: Report & Feedback Group
            if (widget.initialMode == 'both' || widget.initialMode == 'contact')
              _buildGroupCard(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    leading: _buildCircleIcon(
                      icon: Icons.bug_report_outlined,
                      bgColor: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                    ),
                    title: Text(
                      l10n.helpReportIssueTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      l10n.helpReportIssueSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onTap: _showReportIssueBottomSheet,
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    leading: _buildCircleIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      bgColor: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                    ),
                    title: Text(
                      l10n.helpFeedbackTileTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      l10n.helpFeedbackTileSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onTap: _showFeedbackBottomSheet,
                  ),
                ],
              ),

            // Still need help Banner
            if (widget.initialMode == 'both' || widget.initialMode == 'contact')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, 110, AppSpacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCircleIcon(
                            icon: Icons.verified_user_outlined,
                            bgColor: Colors.white,
                            iconColor: const Color(0xFF16A34A),
                            size: 36,
                            iconSize: 18,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.helpStillNeedHelp,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.helpStillNeedHelpBody,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -10,
                      bottom: -5,
                      child: Image.asset(
                        'assets/images/supporting assets/support_agent.webp',
                        height: 85,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
