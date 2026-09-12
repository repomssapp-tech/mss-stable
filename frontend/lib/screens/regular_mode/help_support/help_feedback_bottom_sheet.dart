import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/l10n.dart';
import '../../../services/account/support_ticket_service.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/common/app_toast.dart';
import 'help_support_data.dart';

void showFeedbackBottomSheet(BuildContext context) {
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
              left: AppSpacing.xxl,
              right: AppSpacing.xxl,
              top: AppSpacing.xxl,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
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
                                  description:
                                      'Rating: ${rating.toInt()} Stars\n\n$text',
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
                                debugPrint(
                                  '[HelpSupport] feedback submit failed: $e',
                                );
                                if (context.mounted) {
                                  AppToast.showError(
                                    context,
                                    l10n.helpFeedbackSubmitFailed,
                                  );
                                  await emailSupportFallback(
                                    context,
                                    subject: 'MSS App Feedback',
                                    body:
                                        'Rating: ${rating.toInt()}/5\n\n$text\n\nReply to: $email',
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setModalState(
                                    () => submittingFeedback = false,
                                  );
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
