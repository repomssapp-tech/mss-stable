import '../../../services/account/app_session.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../services/account/support_ticket_service.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/common/app_toast.dart';
import 'help_support_data.dart';
import '../../../utils/app_text.dart';

void showFeedbackBottomSheet(BuildContext context) {
  final l10n = context.l10n;
  double rating = 5.0;
  final feedbackTextController = TextEditingController();
  final emailController = TextEditingController();
  bool submittingFeedback = false;

  if (emailController.text.trim().isEmpty) {
    final userEmail = AppSession.instance.email;
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
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.helpShareFeedbackTitle,
                          style: context.text.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.iconMuted,
                        ),
                        tooltip: l10n.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.helpFeedbackBody,
                    style: context.text.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          l10n.helpRateExperience,
                          style: context.text.button.copyWith(
                            color: AppColors.textPrimary,
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
                                color: AppColors.warning,
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
                    style: context.text.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpContactEmailLabel,
                      hintText: l10n.helpFeedbackEmailHint,
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      hintStyle: const TextStyle(color: AppColors.iconMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: feedbackTextController,
                    maxLines: 3,
                    style: context.text.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpSuggestionsLabel,
                      hintText: context.l10n.helpSuggestionsHint,
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      hintStyle: const TextStyle(color: AppColors.iconMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                                AppToast.showWarning(
                                  context,
                                  supportTicketInputErrorText(l10n, e),
                                );
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
                                  AppToast.showWarning(
                                    context,
                                    supportTicketRateLimitText(l10n, e),
                                  );
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
                              style: context.text.label.copyWith(
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
