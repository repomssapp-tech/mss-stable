import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';

void showAboutAppDialog(BuildContext context) {
  final provider = Provider.of<AppProvider>(context, listen: false);
  final isTa = provider.selectedLanguage == 'ta';

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/Logo/Logo.webp',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.account_balance,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'MSS',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isTa
                      ? 'அரசு திட்டங்கள் & வழிகாட்டி தளம்'
                      : 'Government Scheme Discovery & Eligibility Platform',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(color: Color(0xFFF1F5F9), height: 1),
                ),
                Text(
                  isTa
                      ? 'MSS என்பது இந்திய தொழில்முனைவோர், பெண்கள், விவசாயிகள் மற்றும் மாணவர்களுக்கான மத்திய மற்றும் மாநில அரசு திட்டங்களை எளிதாகக் கண்டறிந்து, தகுதிகளை சரிபார்த்து பயன்பெற உதவும் ஒரு அறிவார்ந்த டிஜிட்டல் தளமாகும்.'
                      : 'MSS is an intelligent digital platform designed to bridge the awareness gap and simplify the discovery, eligibility matching, and application process for Central and State Government schemes for Indian entrepreneurs, women, farmers, and students.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.handshake_outlined,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              isTa
                                  ? 'உருவாக்கியவர்கள்:'
                                  : 'Developed in collaboration with:',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Flexible(
                            child: Image.asset(
                              'assets/images/Logo/rit_logo.webp',
                              height: 26,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          Container(
                            height: 22,
                            width: 1,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            color: const Color(0xFFCBD5E1),
                          ),
                          Flexible(
                            child: Image.asset(
                              'assets/images/Logo/sss_tn_chapter_logo.webp',
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '• Rajalakshmi Institute of Technology (RIT)\n• Swadeshi Shodh Sansthan (SSS TN Chapter)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Support: mssschemessearch@gmail.com',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      context.l10n.close,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
