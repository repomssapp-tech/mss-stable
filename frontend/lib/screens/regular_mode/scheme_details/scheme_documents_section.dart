import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/constants.dart';
import '../../../utils/app_text.dart';

/// Content section for scheme required documents with mandatory badges and portal links.
class SchemeDocumentsContent extends StatelessWidget {
  final LocalizedScheme scheme;
  final ValueChanged<String> onOpenUrl;

  const SchemeDocumentsContent({
    super.key,
    required this.scheme,
    required this.onOpenUrl,
  });

  /// The official portal for a document, matched on its catalog name
  /// (independent of the display language); empty when there is none.
  String _portalFor(String catalogName) {
    final name = catalogName.toLowerCase();
    return AppConstants.documentLinks.entries.firstWhere((entry) {
      final key = entry.key.toLowerCase();
      return name.contains(key) || key.contains(name);
    }, orElse: () => const MapEntry('', '')).value;
  }

  @override
  Widget build(BuildContext context) {
    final documents = scheme.documents.isNotEmpty
        ? scheme.documents
        : scheme.requiredDocuments
              .map((name) => SchemeDocument(name: name))
              .toList();

    if (documents.isEmpty) {
      return Text(
        context.l10n.noDocumentsPublished,
        style: context.text.body.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        for (final entry in documents.asMap().entries)
          _DocumentRow(
            document: entry.value,
            portal: _portalFor(
              scheme.rawScheme.documents.isNotEmpty
                  ? scheme.rawScheme.documents[entry.key].name
                  : scheme.rawScheme.requiredDocuments[entry.key],
            ),
            onOpenUrl: onOpenUrl,
            last: entry.key == documents.length - 1,
          ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.portal,
    required this.onOpenUrl,
    required this.last,
  });

  final SchemeDocument document;
  final String portal;
  final ValueChanged<String> onOpenUrl;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meta = <String>[
      if (document.issuingAuthority.isNotEmpty)
        l10n.issuedByFormat(document.issuingAuthority),
      if (document.estimatedCost.isNotEmpty &&
          document.estimatedCost.toLowerCase() != 'not specified')
        l10n.estimatedCostFormat(document.estimatedCost),
    ];
    final badge = document.mandatory.isEmpty
        ? null
        : document.isMandatory
        ? (l10n.badgeRequired, AppColors.dangerStrong, AppColors.dangerSoft)
        : (
            document.mandatory.toLowerCase() == 'conditional'
                ? l10n.badgeConditional
                : document.mandatory,
            AppTagStyle.neutral.text,
            AppTagStyle.neutral.background,
          );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: AppSize.borderWidth,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.hairline),
            child: Icon(
              Icons.description_outlined,
              color: AppColors.iconMuted,
              size: AppSize.icon,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: context.text.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.hairline,
                    ),
                    decoration: BoxDecoration(
                      color: badge.$3,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      badge.$1,
                      style: context.text.label.copyWith(color: badge.$2),
                    ),
                  ),
                ],
                if (document.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    document.description,
                    style: context.text.body.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ],
                for (final line in meta) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    line,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (portal.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => onOpenUrl(portal),
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: AppSize.iconSm,
                      ),
                      label: Text(l10n.getDocumentOnline),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
