import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_toast.dart';

const String kSupportEmail = 'mssschemessearch@gmail.com';

List<Map<String, String>> getHelpFaqs(AppLocalizations l10n) => [
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

List<Map<String, String>> getAllHelpFaqs(AppLocalizations l10n) => [
      ...getHelpFaqs(l10n),
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

Future<void> emailSupportFallback(
  BuildContext context, {
  required String subject,
  required String body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: kSupportEmail,
    query:
        'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('no mail client');
  } catch (_) {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (context.mounted) {
      AppToast.showInfo(
        context,
        '$kSupportEmail copied — please email us directly.',
      );
    }
  }
}

void copyHelpTextToClipboard(
  BuildContext context,
  String text,
  String message,
) {
  Clipboard.setData(ClipboardData(text: text));
  AppToast.showSuccess(context, message);
}
