import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive.dart';

/// Content section for scheme required documents with mandatory badges and portal links.
class SchemeDocumentsContent extends StatelessWidget {
  final LocalizedScheme scheme;
  final ValueChanged<String> onOpenUrl;

  const SchemeDocumentsContent({
    super.key,
    required this.scheme,
    required this.onOpenUrl,
  });

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
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11.5,
          height: 1.4,
        ),
      );
    }

    return Column(
      children: documents.map((document) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF2563EB),
                    size: 17,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      document.name,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (document.mandatory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: document.isMandatory
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        document.isMandatory
                            ? context.l10n.badgeRequired
                            : document.mandatory,
                        style: GoogleFonts.inter(
                          color: document.isMandatory
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF475569),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (document.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  document.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
              if (document.issuingAuthority.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  context.l10n.issuedByFormat(document.issuingAuthority),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (document.estimatedCost.isNotEmpty &&
                  document.estimatedCost.toLowerCase() != 'not specified')
                Text(
                  context.l10n.estimatedCostFormat(document.estimatedCost),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontSize: 9.0,
                  ),
                ),
              (() {
                final docEntry = AppConstants.documentLinks.entries.firstWhere((
                  entry,
                ) {
                  final key = entry.key.toLowerCase();
                  final name = document.name.toLowerCase();
                  return name.contains(key) || key.contains(name);
                }, orElse: () => const MapEntry('', ''));

                final docLink = docEntry.value;
                if (docLink.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => onOpenUrl(docLink),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.tight,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 13,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: AppSpacing.tight),
                                Flexible(
                                  child: FitOneLine(
                                    child: Text(
                                      '${context.l10n.getDocumentOnline} (Official Portal)',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF2563EB),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 12,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              })(),
            ],
          ),
        );
      }).toList(),
    );
  }
}
