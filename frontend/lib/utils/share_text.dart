import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/common/app_toast.dart';

/// Opens the Android share sheet with [text] (test report BUG-10: the share
/// icons used to copy silently). Where no share sheet is available, the text
/// is copied instead and [copiedMessage] is shown, as before.
Future<void> shareText(
  BuildContext context,
  String text, {
  required String copiedMessage,
}) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text));
    return;
  } on MissingPluginException {
    // No share plugin (widget tests, unsupported platform): copy instead.
  } on PlatformException {
    // Share sheet unavailable: copy instead.
  }
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) AppToast.showSuccess(context, copiedMessage);
}
