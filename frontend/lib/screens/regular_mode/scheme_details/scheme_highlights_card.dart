import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
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

    final maxPillWidth = MediaQuery.of(context).size.width - 56;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes,
                color: Color(0xFF2563EB),
                size: 16,
              ),
              const SizedBox(width: AppSpacing.tight),
              Flexible(
                child: Text(
                  context.l10n.schemeAtAGlance,
                  softWrap: true,
                  style: AppGoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: matches.map((match) {
              return Container(
                constraints: BoxConstraints(maxWidth: maxPillWidth),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2563EB),
                      size: 11,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        match.isEmpty
                            ? match
                            : '${match[0].toUpperCase()}${match.substring(1)}',
                        style: AppGoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // A green tick only for a verified scheme; "not independently
          // verified" gets a neutral info icon, not a contradicting tick.
          Icon(
            _isVerified(scheme.verificationStatus)
                ? Icons.verified_outlined
                : Icons.info_outline_rounded,
            color: _isVerified(scheme.verificationStatus)
                ? const Color(0xFF047857)
                : AppColors.textSecondary,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppGoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.0,
                  ),
                ),
                if (scheme.lastUpdated.isNotEmpty)
                  Text(
                    context.l10n.lastUpdatedFormat(
                      _formatUpdated(context, scheme.lastUpdated),
                    ),
                    style: AppGoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: sourceUrl.isEmpty ? null : () => onOpenUrl(sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
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
