import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../utils/app_colors.dart';

/// Card presenting key scheme metadata pills (government level, state, sector, target).
class SchemeHighlightsCard extends StatelessWidget {
  final LocalizedScheme scheme;

  const SchemeHighlightsCard({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final matches = [
      scheme.governmentLevel.isNotEmpty ? scheme.governmentLevel : '',
      scheme.state,
      scheme.sector,
      scheme.targetBeneficiary,
    ].where((value) => value.isNotEmpty).toSet().toList();
    matches.sort((a, b) => a.length.compareTo(b.length));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.schemeAtAGlance,
            style: context.text.cardTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final match in matches)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTagStyle.level.background,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    '${match[0].toUpperCase()}${match.substring(1)}',
                    style: context.text.label.copyWith(
                      color: AppTagStyle.level.text,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card showing scheme verification status, last updated stamp, and official source link.
class SchemeOfficialSourceCard extends StatelessWidget {
  final LocalizedScheme scheme;
  final ValueChanged<String> onOpenUrl;
  final bool Function(String) isSafeWebUrl;

  const SchemeOfficialSourceCard({
    super.key,
    required this.scheme,
    required this.onOpenUrl,
    required this.isSafeWebUrl,
  });

  @override
  Widget build(BuildContext context) {
    final sourceUrl = [
      scheme.sourceUrl,
      scheme.guidelinesUrl,
      scheme.officialWebsite,
    ].firstWhere(isSafeWebUrl, orElse: () => '');
    final verified = _isVerified(scheme.verificationStatus);

    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.md,
        right: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          // A green tick only for a verified scheme; "not independently
          // verified" gets a neutral info icon, not a contradicting tick.
          Icon(
            verified ? Icons.verified_outlined : Icons.info_outline_rounded,
            size: AppSize.icon,
            color: verified ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheme.verificationStatus.isEmpty
                      ? context.l10n.officialInformation
                      : _verificationText(context, scheme.verificationStatus),
                  style: context.text.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (scheme.lastUpdated.isNotEmpty)
                  Text(
                    context.l10n.lastUpdatedFormat(
                      _formatUpdated(context, scheme.lastUpdated),
                    ),
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: sourceUrl.isEmpty ? null : () => onOpenUrl(sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: AppSize.iconSm),
            label: Text(context.l10n.sourceButton),
          ),
        ],
      ),
    );
  }
}

/// ISO timestamps from the catalog become a readable date in the app language.
String _formatUpdated(BuildContext context, String raw) {
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  final months = context.l10n.monthAbbrList
      .split(',')
      .map((m) => m.trim())
      .toList();
  if (months.length != 12) return raw;
  final local = d.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// A readable form of a catalog verification status. The catalog stores codes
/// such as `NOT_INDEPENDENTLY_VERIFIED`; those are shown in the user's language
/// (or, for a code with no translation, as plain lower-case words).
String _verificationText(BuildContext context, String raw) {
  final l10n = context.l10n;
  final code = raw.trim();
  switch (code.toUpperCase()) {
    case 'VERIFIED':
      return l10n.verificationStatusVerified;
    case 'NOT_INDEPENDENTLY_VERIFIED':
      return l10n.verificationStatusNotIndependentlyVerified;
  }
  if (RegExp(r'^[A-Z0-9_ ]+$').hasMatch(code) && code.contains('_')) {
    final words = code.toLowerCase().replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
  return code;
}

bool _isVerified(String raw) => raw.trim().toUpperCase() == 'VERIFIED';
