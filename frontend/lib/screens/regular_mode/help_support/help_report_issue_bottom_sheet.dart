import '../../../services/account/app_session.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../services/account/support_ticket_service.dart';
import '../../../utils/app_spacing.dart';
import '../../../widgets/common/app_toast.dart';
import 'help_support_data.dart';
import '../../../utils/app_text.dart';

void showReportIssueBottomSheet(
  BuildContext context, {
  TextEditingController? externalEmailController,
  TextEditingController? externalFeedbackController,
}) {
  final l10n = context.l10n;
  final emailController = externalEmailController ?? TextEditingController();
  final feedbackController =
      externalFeedbackController ?? TextEditingController();

  if (emailController.text.trim().isEmpty) {
    final userEmail = AppSession.instance.email;
    if (userEmail != null && userEmail.isNotEmpty) {
      emailController.text = userEmail;
    }
  }

  String issueCategory = 'General Inquiry';
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
                          color: AppColors.successSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bug_report_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.helpReportIssueTitle,
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
                    l10n.helpReportIssueBody,
                    style: context.text.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DropdownButtonFormField<String>(
                    initialValue: issueCategory,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: context.text.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.filterCategory,
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    items:
                        <({String value, String label})>[
                          (
                            value: 'General Inquiry',
                            label: l10n.helpCatGeneralInquiry,
                          ),
                          (
                            value: 'Eligibility Matcher Bug',
                            label: l10n.helpCatMatcherBug,
                          ),
                          (
                            value: 'Wrong Scheme Details',
                            label: l10n.helpCatWrongDetails,
                          ),
                          (
                            value: 'Feature Request',
                            label: l10n.helpCatFeatureRequest,
                          ),
                        ].map((cat) {
                          return DropdownMenuItem(
                            value: cat.value,
                            child: Text(cat.label),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => issueCategory = val);
                      }
                    },
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
                      hintText: context.l10n.helpContactEmailHint,
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
                    controller: feedbackController,
                    maxLines: 4,
                    style: context.text.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.helpDescriptionLabel,
                      hintText: context.l10n.helpDescriptionHint,
                      alignLabelWithHint: true,
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
                      onPressed: submitting
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              final text = feedbackController.text.trim();

                              try {
                                SupportTicketService.instance.validateInputs(
                                  category: issueCategory,
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

                              setModalState(() => submitting = true);

                              try {
                                await SupportTicketService.instance
                                    .submitTicket(
                                      category: issueCategory,
                                      email: email,
                                      description: text,
                                    );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  AppToast.showSuccess(
                                    context,
                                    l10n.helpTicketSubmitted,
                                  );
                                  feedbackController.clear();
                                }
                              } on SupportTicketRateLimitException catch (e) {
                                if (context.mounted) {
                                  AppToast.showWarning(
                                    context,
                                    supportTicketRateLimitText(l10n, e),
                                  );
                                }
                              } on SupportTicketValidationException catch (e) {
                                if (context.mounted) {
                                  AppToast.showWarning(
                                    context,
                                    supportTicketInputErrorText(l10n, e),
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  '[HelpSupport] ticket submit failed: $e',
                                );
                                if (context.mounted) {
                                  AppToast.showError(
                                    context,
                                    l10n.helpTicketSubmitFailed,
                                  );
                                  await emailSupportFallback(
                                    context,
                                    subject:
                                        'MSS App — Issue Report: $issueCategory',
                                    body: '$text\n\nReply to: $email',
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
