import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import 'help_support_data.dart';
import 'help_faq_bottom_sheets.dart';
import 'help_report_issue_bottom_sheet.dart';
import 'help_feedback_bottom_sheet.dart';
import '../../../utils/app_text.dart';
import '../../../utils/app_colors.dart';

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
                  initialMode == 'faq'
                      ? l10n.helpFaqSetting
                      : initialMode == 'contact'
                      ? l10n.helpHeaderContact
                      : l10n.helpHeaderSupport,
                  softWrap: true,
                  style: AppGoogleFonts.poppins(
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
            style: AppGoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
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
                bgColor: Color(0xFFEFF6FF),
                iconColor: Color(0xFF2563EB),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpFaqsGroupTitle,
                      style: AppGoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      l10n.helpFaqsGroupSubtitle,
                      style: AppGoogleFonts.inter(
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
                  style: AppGoogleFonts.inter(
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
                onTap: () => showFAQBottomSheet(
                  context,
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
            style: AppGoogleFonts.inter(
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
                bgColor: Color(0xFFEFF6FF),
                iconColor: Color(0xFF2563EB),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpContactGroupTitle,
                      style: AppGoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      l10n.helpContactGroupSubtitle,
                      style: AppGoogleFonts.inter(
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HelpCircleIcon(
                  icon: Icons.mail_outline_rounded,
                  bgColor: Color(0xFFEFF6FF),
                  iconColor: Color(0xFF2563EB),
                  size: 36,
                  iconSize: 18,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.helpEmailUs,
                  style: AppGoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: () => copyHelpTextToClipboard(
                    context,
                    kSupportEmail,
                    l10n.helpSupportEmailCopied,
                  ),
                  child: Text(
                    kSupportEmail,
                    style: AppGoogleFonts.inter(
                      color: const Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            bgColor: Color(0xFFF0FDF4),
            iconColor: Color(0xFF16A34A),
          ),
          title: Text(
            l10n.helpReportIssueTitle,
            style: AppGoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            l10n.helpReportIssueSubtitle,
            style: AppGoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
          onTap: () => showReportIssueBottomSheet(context),
        ),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: const HelpCircleIcon(
            icon: Icons.chat_bubble_outline_rounded,
            bgColor: Color(0xFFFFF7ED),
            iconColor: Color(0xFFEA580C),
          ),
          title: Text(
            l10n.helpFeedbackTileTitle,
            style: AppGoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            l10n.helpFeedbackTileSubtitle,
            style: AppGoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
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
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
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
                  bgColor: Colors.white,
                  iconColor: Color(0xFF16A34A),
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
                        style: AppGoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.helpStillNeedHelpBody,
                        style: AppGoogleFonts.inter(
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
    );
  }
}
