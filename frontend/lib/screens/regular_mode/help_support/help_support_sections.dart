import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'help_support_data.dart';
import 'help_faq_bottom_sheets.dart';
import 'help_report_issue_bottom_sheet.dart';
import 'help_feedback_bottom_sheet.dart';
import '../../../utils/app_text.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_size.dart';

class HelpGroupCard extends StatelessWidget {
  final List<Widget> children;

  const HelpGroupCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
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
}

class HelpCircleIcon extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const HelpCircleIcon({
    super.key,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

class HelpHeaderSection extends StatelessWidget {
  final String initialMode;

  const HelpHeaderSection({super.key, required this.initialMode});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: l10n.back,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: AppSize.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  initialMode == 'faq'
                      ? l10n.helpFaqSetting
                      : initialMode == 'contact'
                      ? l10n.helpHeaderContact
                      : l10n.helpHeaderSupport,
                  softWrap: true,
                  style: context.text.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.helpHeaderSubtitle,
            style: context.text.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class HelpFaqSection extends StatelessWidget {
  const HelpFaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final faqs = getHelpFaqs(l10n);

    return HelpGroupCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const HelpCircleIcon(
                icon: Icons.help_outline_rounded,
                bgColor: AppColors.primarySoft,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpFaqsGroupTitle,
                      style: context.text.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      l10n.helpFaqsGroupSubtitle,
                      style: context.text.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconMuted,
                size: 18,
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.surfaceMuted, height: 1),
        ...faqs.map((faq) {
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.hairline,
                ),
                title: Text(
                  faq['question']!,
                  style: context.text.button.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.iconMuted,
                  size: 18,
                ),
                onTap: () => showFAQBottomSheet(
                  context,
                  faq['question']!,
                  faq['answer']!,
                ),
              ),
              const Divider(color: AppColors.surfaceMuted, height: 1),
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
            style: context.text.button.copyWith(color: AppColors.primary),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          onTap: () => showAllFAQsBottomSheet(context),
        ),
      ],
    );
  }
}

class HelpContactSection extends StatelessWidget {
  const HelpContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return HelpGroupCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const HelpCircleIcon(
                icon: Icons.headset_mic_outlined,
                bgColor: AppColors.primarySoft,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpContactGroupTitle,
                      style: context.text.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      l10n.helpContactGroupSubtitle,
                      style: context.text.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.none,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HelpCircleIcon(
                  icon: Icons.mail_outline_rounded,
                  bgColor: AppColors.primarySoft,
                  iconColor: AppColors.primary,
                  size: 36,
                  iconSize: 18,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.helpEmailUs,
                  style: context.text.button.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Tapping the address copies it.
                TextButton(
                  onPressed: () => copyHelpTextToClipboard(
                    context,
                    kSupportEmail,
                    l10n.helpSupportEmailCopied,
                  ),
                  child: Text(kSupportEmail),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.helpReplyWindow,
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HelpFeedbackSection extends StatelessWidget {
  const HelpFeedbackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return HelpGroupCard(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: const HelpCircleIcon(
            icon: Icons.bug_report_outlined,
            bgColor: AppColors.primarySoft,
            iconColor: AppColors.primary,
          ),
          title: Text(
            l10n.helpReportIssueTitle,
            style: context.text.button.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            l10n.helpReportIssueSubtitle,
            style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.iconMuted,
            size: 18,
          ),
          onTap: () => showReportIssueBottomSheet(context),
        ),
        const Divider(color: AppColors.surfaceMuted, height: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: const HelpCircleIcon(
            icon: Icons.chat_bubble_outline_rounded,
            bgColor: AppColors.primarySoft,
            iconColor: AppColors.primary,
          ),
          title: Text(
            l10n.helpFeedbackTileTitle,
            style: context.text.button.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            l10n.helpFeedbackTileSubtitle,
            style: context.text.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.iconMuted,
            size: 18,
          ),
          onTap: () => showFeedbackBottomSheet(context),
        ),
      ],
    );
  }
}

class HelpStillNeedHelpBanner extends StatelessWidget {
  const HelpStillNeedHelpBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successSoft, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              110,
              AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HelpCircleIcon(
                  icon: Icons.verified_user_outlined,
                  bgColor: AppColors.surface,
                  iconColor: AppColors.success,
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
                        style: context.text.button.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.helpStillNeedHelpBody,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textMuted,
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
    );
  }
}
