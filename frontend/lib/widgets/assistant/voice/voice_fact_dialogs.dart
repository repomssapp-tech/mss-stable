import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../services/search/scheme_understanding_models.dart';
import 'voice_interactive_widgets.dart';

/// Shows the "edit a single eligibility fact" dialog and returns the edited
/// value, or `null` if the user cancelled. Callers are responsible for the
/// `mounted` check and applying the result to their session controller.
Future<String?> showVoiceEditFactDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required EligibilityFact fact,
}) {
  final controller = TextEditingController(text: fact.value);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      title: Text(
        l10n.voiceEditFact(factLabel(context, fact.key)),
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        key: const Key('voice-fact-editor'),
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: Text(context.l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(CentralizedTranslator.instance.translate('Use value')),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Shows the "review facts learned this session before saving to profile"
/// dialog and returns whether the user confirmed. Callers are responsible for
/// the `mounted` check and applying confirmed facts to their session
/// controller.
Future<bool?> showVoiceProfileReviewDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<EligibilityFact> candidates,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('voice-profile-review'),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      title: Text(
        l10n.voiceReviewProfileUpdates,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: candidates
              .map(
                (fact) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(factLabel(context, fact.key)),
                  subtitle: Text(fact.value),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF16A34A),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: Text(l10n.voiceKeepSessionOnly),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(l10n.voiceSaveConfirmed),
        ),
      ],
    ),
  );
}
